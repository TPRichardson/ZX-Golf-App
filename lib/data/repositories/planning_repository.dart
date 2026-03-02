import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// TD-03 §3.2 — Practice planning repository.
// Manages: Routine, RoutineInstance, Schedule, ScheduleInstance, CalendarDay.
// Spec: S08 — Practice Planning Layer.
// Phase 5: Full business methods with state machine guards,
// slot management, routine/schedule lifecycle, cascade deletions.
class PlanningRepository {
  final AppDatabase _db;
  final SyncWriteGate _gate;

  static const _uuid = Uuid();

  PlanningRepository(this._db, this._gate);

  // ===========================================================================
  // Slot Helpers — S08 §8.13.2
  // ===========================================================================

  /// Parse slots JSON from CalendarDay TEXT column.
  List<Slot> parseSlots(String slotsJson) {
    final list = jsonDecode(slotsJson) as List<dynamic>;
    return list.map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Serialize slots to JSON for CalendarDay TEXT column.
  String serializeSlots(List<Slot> slots) {
    return jsonEncode(slots.map((s) => s.toJson()).toList());
  }

  // ===========================================================================
  // CalendarDay Business Methods — S08 §8.13, TD-04 §2.6
  // ===========================================================================

  // S08 §8.13.1 — Lookup CalendarDay by user + date.
  Future<CalendarDay?> getCalendarDayByDate(String userId, DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return (_db.select(_db.calendarDays)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.date.equals(dateOnly)))
        .getSingleOrNull();
  }

  // S08 §8.13.1 — Get or create CalendarDay with default slot capacity.
  Future<CalendarDay> getOrCreateCalendarDay(String userId, DateTime date) async {
    await _gate.awaitGateRelease();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final existing = await getCalendarDayByDate(userId, dateOnly);
    if (existing != null) return existing;

    // Create with default capacity and empty slots.
    final slots = List<Slot>.generate(
        kDefaultSlotCapacity, (_) => const Slot());
    return createCalendarDay(CalendarDaysCompanion(
      calendarDayId: Value(_uuid.v4()),
      userId: Value(userId),
      date: Value(dateOnly),
      slotCapacity: const Value(kDefaultSlotCapacity),
      slots: Value(serializeSlots(slots)),
    ));
  }

  // S08 §8.13.2 — Update all slots for a CalendarDay.
  Future<CalendarDay> updateSlots(
      String calendarDayId, List<Slot> slots) async {
    await _gate.awaitGateRelease();
    return updateCalendarDay(calendarDayId, CalendarDaysCompanion(
      slots: Value(serializeSlots(slots)),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // S08 §8.13.2 — Manual drill assignment to a specific slot.
  // Guard: slot must be empty, index < capacity.
  Future<CalendarDay> assignDrillToSlot(
    String userId,
    DateTime date,
    int slotIndex,
    String drillId,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final day = await getOrCreateCalendarDay(userId, date);
        final slots = parseSlots(day.slots);

        if (slotIndex < 0 || slotIndex >= slots.length) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message: 'Slot index out of range',
            context: {'slotIndex': slotIndex, 'capacity': slots.length},
          );
        }

        if (slots[slotIndex].isFilled) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Slot is already filled',
            context: {'slotIndex': slotIndex},
          );
        }

        // TD-04 §2.6 — Manual assignment: set drill, break any ownership.
        // Phase 7B — Set updatedAt for per-slot LWW merge.
        slots[slotIndex] = Slot(
          drillId: drillId,
          ownerType: SlotOwnerType.manual,
          completionState: CompletionState.incomplete,
          planned: true,
          updatedAt: DateTime.now(),
        );

        return await updateCalendarDay(day.calendarDayId, CalendarDaysCompanion(
          slots: Value(serializeSlots(slots)),
          updatedAt: Value(DateTime.now()),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to assign drill to slot',
        context: {'error': e.toString()},
      );
    }
  }

  // S08 §8.13.2 — Clear a slot, break ownership.
  Future<CalendarDay> clearSlot(
    String userId,
    DateTime date,
    int slotIndex,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final day = await getCalendarDayByDate(userId, date);
        if (day == null) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found',
            context: {'userId': userId, 'date': date.toString()},
          );
        }

        final slots = parseSlots(day.slots);

        if (slotIndex < 0 || slotIndex >= slots.length) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message: 'Slot index out of range',
            context: {'slotIndex': slotIndex, 'capacity': slots.length},
          );
        }

        // TD-04 §2.6 — Clear: reset to empty, break ownership.
        // Phase 7B — Set updatedAt for per-slot LWW merge.
        slots[slotIndex] = Slot(updatedAt: DateTime.now());

        return await updateCalendarDay(day.calendarDayId, CalendarDaysCompanion(
          slots: Value(serializeSlots(slots)),
          updatedAt: Value(DateTime.now()),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to clear slot',
        context: {'error': e.toString()},
      );
    }
  }

  // S08 §8.13.1 — Update slot capacity.
  // Guard: capacity >= filled slot count.
  Future<CalendarDay> updateSlotCapacity(
    String userId,
    DateTime date,
    int newCapacity,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final day = await getOrCreateCalendarDay(userId, date);
        final slots = parseSlots(day.slots);
        final filledCount = slots.where((s) => s.isFilled).length;

        if (newCapacity < filledCount) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Cannot reduce capacity below filled slot count',
            context: {'newCapacity': newCapacity, 'filledCount': filledCount},
          );
        }

        if (newCapacity < 0) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message: 'Capacity cannot be negative',
            context: {'newCapacity': newCapacity},
          );
        }

        // Adjust slots list: add empty slots or trim empty from end.
        final newSlots = <Slot>[];
        for (var i = 0; i < newCapacity; i++) {
          if (i < slots.length) {
            newSlots.add(slots[i]);
          } else {
            newSlots.add(const Slot());
          }
        }

        return await updateCalendarDay(day.calendarDayId, CalendarDaysCompanion(
          slotCapacity: Value(newCapacity),
          slots: Value(serializeSlots(newSlots)),
          updatedAt: Value(DateTime.now()),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update slot capacity',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-04 §2.6 — Mark slot as CompletedLinked with session reference.
  // Transition: Incomplete → CompletedLinked.
  Future<CalendarDay> markSlotComplete(
    String calendarDayId,
    int slotIndex,
    String sessionId,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final day = await getCalendarDayById(calendarDayId);
        if (day == null) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found',
            context: {'calendarDayId': calendarDayId},
          );
        }

        final slots = parseSlots(day.slots);

        if (slotIndex < 0 || slotIndex >= slots.length) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message: 'Slot index out of range',
            context: {'slotIndex': slotIndex, 'capacity': slots.length},
          );
        }

        if (slots[slotIndex].completionState != CompletionState.incomplete) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Slot is not in Incomplete state',
            context: {
              'slotIndex': slotIndex,
              'currentState': slots[slotIndex].completionState.dbValue,
            },
          );
        }

        // Phase 7B — Set updatedAt for per-slot LWW merge.
        slots[slotIndex] = slots[slotIndex].copyWith(
          completionState: CompletionState.completedLinked,
          completingSessionId: () => sessionId,
          updatedAt: () => DateTime.now(),
        );

        return await updateCalendarDay(calendarDayId, CalendarDaysCompanion(
          slots: Value(serializeSlots(slots)),
          updatedAt: Value(DateTime.now()),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to mark slot complete',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-04 §2.6 — Mark slot as CompletedManual.
  // Transition: Incomplete → CompletedManual.
  Future<CalendarDay> markSlotManualComplete(
    String calendarDayId,
    int slotIndex,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final day = await getCalendarDayById(calendarDayId);
        if (day == null) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found',
            context: {'calendarDayId': calendarDayId},
          );
        }

        final slots = parseSlots(day.slots);

        if (slotIndex < 0 || slotIndex >= slots.length) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message: 'Slot index out of range',
            context: {'slotIndex': slotIndex, 'capacity': slots.length},
          );
        }

        if (slots[slotIndex].completionState != CompletionState.incomplete) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Slot is not in Incomplete state',
            context: {
              'slotIndex': slotIndex,
              'currentState': slots[slotIndex].completionState.dbValue,
            },
          );
        }

        // Phase 7B — Set updatedAt for per-slot LWW merge.
        slots[slotIndex] = slots[slotIndex].copyWith(
          completionState: CompletionState.completedManual,
          updatedAt: () => DateTime.now(),
        );

        return await updateCalendarDay(calendarDayId, CalendarDaysCompanion(
          slots: Value(serializeSlots(slots)),
          updatedAt: Value(DateTime.now()),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to mark slot manual complete',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-04 §2.6 — Revert slot completion.
  // Transition: CompletedLinked/CompletedManual → Incomplete.
  Future<CalendarDay> revertSlotCompletion(
    String calendarDayId,
    int slotIndex,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final day = await getCalendarDayById(calendarDayId);
        if (day == null) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found',
            context: {'calendarDayId': calendarDayId},
          );
        }

        final slots = parseSlots(day.slots);

        if (slotIndex < 0 || slotIndex >= slots.length) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message: 'Slot index out of range',
            context: {'slotIndex': slotIndex, 'capacity': slots.length},
          );
        }

        final currentState = slots[slotIndex].completionState;
        if (currentState != CompletionState.completedLinked &&
            currentState != CompletionState.completedManual) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Slot is not in a completed state',
            context: {
              'slotIndex': slotIndex,
              'currentState': currentState.dbValue,
            },
          );
        }

        // Phase 7B — Set updatedAt for per-slot LWW merge.
        slots[slotIndex] = slots[slotIndex].copyWith(
          completionState: CompletionState.incomplete,
          completingSessionId: () => null,
          updatedAt: () => DateTime.now(),
        );

        return await updateCalendarDay(calendarDayId, CalendarDaysCompanion(
          slots: Value(serializeSlots(slots)),
          updatedAt: Value(DateTime.now()),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to revert slot completion',
        context: {'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // Routine Business Methods — S08 §8.1.2, TD-04 §2.8
  // ===========================================================================

  // S08 §8.1.2 — Create routine with validated entries.
  // Guard: must have ≥1 entry.
  Future<Routine> createRoutineWithEntries(
    String userId,
    String name,
    List<RoutineEntry> entries,
  ) async {
    await _gate.awaitGateRelease();
    if (entries.isEmpty) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Routine must have at least one entry',
        context: {'name': name},
      );
    }

    return createRoutine(RoutinesCompanion(
      routineId: Value(_uuid.v4()),
      userId: Value(userId),
      name: Value(name),
      entries: Value(jsonEncode(entries.map((e) => e.toJson()).toList())),
      status: const Value(RoutineStatus.active),
    ));
  }

  // S08 §8.1.2 — Update routine entries.
  // Guard: must be Active (TD-04 §2.8).
  Future<Routine> updateRoutineEntries(
    String routineId,
    List<RoutineEntry> entries,
  ) async {
    await _gate.awaitGateRelease();
    final routine = await getRoutineById(routineId);
    if (routine == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Routine not found',
        context: {'routineId': routineId},
      );
    }

    if (routine.status != RoutineStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only update entries on Active routines',
        context: {'routineId': routineId, 'status': routine.status.dbValue},
      );
    }

    if (entries.isEmpty) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Routine must have at least one entry',
        context: {'routineId': routineId},
      );
    }

    return updateRoutine(routineId, RoutinesCompanion(
      entries: Value(jsonEncode(entries.map((e) => e.toJson()).toList())),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // TD-04 §2.8 — Retire routine: Active → Retired.
  Future<Routine> retireRoutine(String routineId) async {
    await _gate.awaitGateRelease();
    final routine = await getRoutineById(routineId);
    if (routine == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Routine not found',
        context: {'routineId': routineId},
      );
    }

    if (routine.status != RoutineStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only retire Active routines',
        context: {'routineId': routineId, 'status': routine.status.dbValue},
      );
    }

    return updateRoutine(routineId, RoutinesCompanion(
      status: const Value(RoutineStatus.retired),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // TD-04 §2.8 — Reactivate routine: Retired → Active.
  Future<Routine> reactivateRoutine(String routineId) async {
    await _gate.awaitGateRelease();
    final routine = await getRoutineById(routineId);
    if (routine == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Routine not found',
        context: {'routineId': routineId},
      );
    }

    if (routine.status != RoutineStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only reactivate Retired routines',
        context: {'routineId': routineId, 'status': routine.status.dbValue},
      );
    }

    return updateRoutine(routineId, RoutinesCompanion(
      status: const Value(RoutineStatus.active),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // TD-04 §2.8 — Delete routine: Active/Retired → Deleted (soft delete).
  Future<void> deleteRoutine(String routineId) async {
    await _gate.awaitGateRelease();
    final routine = await getRoutineById(routineId);
    if (routine == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Routine not found',
        context: {'routineId': routineId},
      );
    }

    if (routine.status != RoutineStatus.active &&
        routine.status != RoutineStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only delete Active or Retired routines',
        context: {'routineId': routineId, 'status': routine.status.dbValue},
      );
    }

    await updateRoutine(routineId, RoutinesCompanion(
      status: const Value(RoutineStatus.deleted),
      isDeleted: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // S08 §8.1.2 — Remove fixed entries referencing a specific drill from all active routines.
  // Auto-deletes routines that become empty.
  Future<void> removeRoutineEntriesForDrill(String drillId) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        // Get all non-deleted routines.
        final routines = await (_db.select(_db.routines)
              ..where((t) => t.isDeleted.equals(false)))
            .get();

        for (final routine in routines) {
          final entries = _parseRoutineEntries(routine.entries);
          final filtered = entries
              .where((e) =>
                  !(e.type == RoutineEntryType.fixed && e.drillId == drillId))
              .toList();

          if (filtered.length != entries.length) {
            if (filtered.isEmpty) {
              // Auto-delete empty routine.
              await (_db.update(_db.routines)
                    ..where((t) => t.routineId.equals(routine.routineId)))
                  .write(RoutinesCompanion(
                status: const Value(RoutineStatus.deleted),
                isDeleted: const Value(true),
                updatedAt: Value(DateTime.now()),
              ));
            } else {
              await (_db.update(_db.routines)
                    ..where((t) => t.routineId.equals(routine.routineId)))
                  .write(RoutinesCompanion(
                entries: Value(
                    jsonEncode(filtered.map((e) => e.toJson()).toList())),
                updatedAt: Value(DateTime.now()),
              ));
            }
          }
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to remove routine entries for drill',
        context: {'drillId': drillId, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.6 — Filtered stream of routines.
  Stream<List<Routine>> watchRoutines(
    String userId, {
    RoutineStatus? status,
  }) {
    final query = _db.select(_db.routines)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (status != null) {
      query.where((t) => t.status.equalsValue(status));
    }
    return query.watch();
  }

  // ===========================================================================
  // Schedule Business Methods — S08 §8.1.3, TD-04 §2.9
  // ===========================================================================

  // S08 §8.1.3 — Create schedule with entries.
  Future<Schedule> createScheduleWithEntries(
    String userId,
    String name,
    ScheduleAppMode appMode,
    String entriesJson,
  ) async {
    await _gate.awaitGateRelease();
    // Validate entries are non-empty JSON array.
    final parsed = jsonDecode(entriesJson) as List<dynamic>;
    if (parsed.isEmpty) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Schedule must have at least one entry',
        context: {'name': name},
      );
    }

    return createSchedule(SchedulesCompanion(
      scheduleId: Value(_uuid.v4()),
      userId: Value(userId),
      name: Value(name),
      applicationMode: Value(appMode),
      entries: Value(entriesJson),
      status: const Value(ScheduleStatus.active),
    ));
  }

  // S08 §8.1.3 — Update schedule entries.
  // Guard: must be Active (TD-04 §2.9).
  Future<Schedule> updateScheduleEntries(
    String scheduleId,
    String entriesJson,
  ) async {
    await _gate.awaitGateRelease();
    final schedule = await getScheduleById(scheduleId);
    if (schedule == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Schedule not found',
        context: {'scheduleId': scheduleId},
      );
    }

    if (schedule.status != ScheduleStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only update entries on Active schedules',
        context: {'scheduleId': scheduleId, 'status': schedule.status.dbValue},
      );
    }

    final parsed = jsonDecode(entriesJson) as List<dynamic>;
    if (parsed.isEmpty) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Schedule must have at least one entry',
        context: {'scheduleId': scheduleId},
      );
    }

    return updateSchedule(scheduleId, SchedulesCompanion(
      entries: Value(entriesJson),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // TD-04 §2.9 — Retire schedule: Active → Retired.
  Future<Schedule> retireSchedule(String scheduleId) async {
    await _gate.awaitGateRelease();
    final schedule = await getScheduleById(scheduleId);
    if (schedule == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Schedule not found',
        context: {'scheduleId': scheduleId},
      );
    }

    if (schedule.status != ScheduleStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only retire Active schedules',
        context: {'scheduleId': scheduleId, 'status': schedule.status.dbValue},
      );
    }

    return updateSchedule(scheduleId, SchedulesCompanion(
      status: const Value(ScheduleStatus.retired),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // TD-04 §2.9 — Reactivate schedule: Retired → Active.
  Future<Schedule> reactivateSchedule(String scheduleId) async {
    await _gate.awaitGateRelease();
    final schedule = await getScheduleById(scheduleId);
    if (schedule == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Schedule not found',
        context: {'scheduleId': scheduleId},
      );
    }

    if (schedule.status != ScheduleStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only reactivate Retired schedules',
        context: {'scheduleId': scheduleId, 'status': schedule.status.dbValue},
      );
    }

    return updateSchedule(scheduleId, SchedulesCompanion(
      status: const Value(ScheduleStatus.active),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // TD-04 §2.9 — Delete schedule: Active/Retired → Deleted (soft delete).
  Future<void> deleteSchedule(String scheduleId) async {
    await _gate.awaitGateRelease();
    final schedule = await getScheduleById(scheduleId);
    if (schedule == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Schedule not found',
        context: {'scheduleId': scheduleId},
      );
    }

    if (schedule.status != ScheduleStatus.active &&
        schedule.status != ScheduleStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only delete Active or Retired schedules',
        context: {'scheduleId': scheduleId, 'status': schedule.status.dbValue},
      );
    }

    await updateSchedule(scheduleId, SchedulesCompanion(
      status: const Value(ScheduleStatus.deleted),
      isDeleted: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // S08 §8.1.3 — Remove entries referencing a specific drill from all active schedules.
  // Auto-deletes schedules that become empty.
  Future<void> removeScheduleEntriesForDrill(String drillId) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final schedules = await (_db.select(_db.schedules)
              ..where((t) => t.isDeleted.equals(false)))
            .get();

        for (final schedule in schedules) {
          final updated = _removeEntriesFromScheduleJson(
              schedule.entries, drillId, 'drillId');
          if (updated != null) {
            if (updated.isEmpty) {
              await (_db.update(_db.schedules)
                    ..where((t) => t.scheduleId.equals(schedule.scheduleId)))
                  .write(SchedulesCompanion(
                status: const Value(ScheduleStatus.deleted),
                isDeleted: const Value(true),
                updatedAt: Value(DateTime.now()),
              ));
            } else {
              await (_db.update(_db.schedules)
                    ..where((t) => t.scheduleId.equals(schedule.scheduleId)))
                  .write(SchedulesCompanion(
                entries: Value(updated),
                updatedAt: Value(DateTime.now()),
              ));
            }
          }
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to remove schedule entries for drill',
        context: {'drillId': drillId, 'error': e.toString()},
      );
    }
  }

  // S08 §8.1.3 — Remove entries referencing a specific routine from schedules.
  // Auto-deletes schedules that become empty.
  Future<void> removeScheduleEntriesForRoutine(String routineId) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final schedules = await (_db.select(_db.schedules)
              ..where((t) => t.isDeleted.equals(false)))
            .get();

        for (final schedule in schedules) {
          final updated = _removeEntriesFromScheduleJson(
              schedule.entries, routineId, 'routineId');
          if (updated != null) {
            if (updated.isEmpty) {
              await (_db.update(_db.schedules)
                    ..where((t) => t.scheduleId.equals(schedule.scheduleId)))
                  .write(SchedulesCompanion(
                status: const Value(ScheduleStatus.deleted),
                isDeleted: const Value(true),
                updatedAt: Value(DateTime.now()),
              ));
            } else {
              await (_db.update(_db.schedules)
                    ..where((t) => t.scheduleId.equals(schedule.scheduleId)))
                  .write(SchedulesCompanion(
                entries: Value(updated),
                updatedAt: Value(DateTime.now()),
              ));
            }
          }
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to remove schedule entries for routine',
        context: {'routineId': routineId, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.6 — Filtered stream of schedules.
  Stream<List<Schedule>> watchSchedules(
    String userId, {
    ScheduleStatus? status,
  }) {
    final query = _db.select(_db.schedules)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.isDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    if (status != null) {
      query.where((t) => t.status.equalsValue(status));
    }
    return query.watch();
  }

  // ===========================================================================
  // Routine CRUD (base methods from Phase 1)
  // ===========================================================================

  // Spec: S08 §8.1.2 — Create routine definition.
  Future<Routine> createRoutine(RoutinesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.routines).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create routine',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve routine by primary key. Filters IsDeleted = false.
  Future<Routine?> getRoutineById(String id) {
    return (_db.select(_db.routines)
          ..where((t) => t.routineId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of non-deleted routines for a user.
  Stream<List<Routine>> watchRoutinesByUser(String userId) {
    return (_db.select(_db.routines)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update routine fields.
  // Spec: TD-03 §2.1.1 — SyncWriteGate compatible: writes through transaction.
  Future<Routine> updateRoutine(String id, RoutinesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.routines)
              ..where((t) => t.routineId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine not found after update',
            context: {'routineId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update routine',
        context: {'routineId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete routine.
  Future<void> softDeleteRoutine(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.routines)
              ..where((t) => t.routineId.equals(id)))
            .write(const RoutinesCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine not found for soft delete',
            context: {'routineId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete routine',
        context: {'routineId': id, 'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // RoutineInstance CRUD
  // ===========================================================================

  // Spec: S08 §8.2.4 — Create routine instance applied to a calendar day.
  Future<RoutineInstance> createRoutineInstance(
      RoutineInstancesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.routineInstances).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create routine instance',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve routine instance by primary key.
  Future<RoutineInstance?> getRoutineInstanceById(String id) {
    return (_db.select(_db.routineInstances)
          ..where((t) => t.routineInstanceId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Routine instances for a user.
  Stream<List<RoutineInstance>> watchRoutineInstancesByUser(String userId) {
    return (_db.select(_db.routineInstances)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.2 — Update routine instance fields.
  Future<RoutineInstance> updateRoutineInstance(
      String id, RoutineInstancesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.routineInstances)
              ..where((t) => t.routineInstanceId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine instance not found after update',
            context: {'routineInstanceId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update routine instance',
        context: {'routineInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete routine instance.
  Future<void> hardDeleteRoutineInstance(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.routineInstances)
              ..where((t) => t.routineInstanceId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine instance not found for hard delete',
            context: {'routineInstanceId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete routine instance',
        context: {'routineInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // Schedule CRUD (base methods from Phase 1)
  // ===========================================================================

  // Spec: S08 §8.1.3 — Create schedule definition.
  Future<Schedule> createSchedule(SchedulesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.schedules).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create schedule',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve schedule by primary key. Filters IsDeleted = false.
  Future<Schedule?> getScheduleById(String id) {
    return (_db.select(_db.schedules)
          ..where((t) => t.scheduleId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of non-deleted schedules for a user.
  Stream<List<Schedule>> watchSchedulesByUser(String userId) {
    return (_db.select(_db.schedules)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update schedule fields.
  Future<Schedule> updateSchedule(String id, SchedulesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.schedules)
              ..where((t) => t.scheduleId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule not found after update',
            context: {'scheduleId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update schedule',
        context: {'scheduleId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete schedule.
  Future<void> softDeleteSchedule(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.schedules)
              ..where((t) => t.scheduleId.equals(id)))
            .write(const SchedulesCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule not found for soft delete',
            context: {'scheduleId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete schedule',
        context: {'scheduleId': id, 'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // ScheduleInstance CRUD
  // ===========================================================================

  // Spec: S08 §8.2.5 — Create schedule instance applied to a date range.
  Future<ScheduleInstance> createScheduleInstance(
      ScheduleInstancesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.scheduleInstances).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create schedule instance',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve schedule instance by primary key.
  Future<ScheduleInstance?> getScheduleInstanceById(String id) {
    return (_db.select(_db.scheduleInstances)
          ..where((t) => t.scheduleInstanceId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Schedule instances for a user.
  Stream<List<ScheduleInstance>> watchScheduleInstancesByUser(String userId) {
    return (_db.select(_db.scheduleInstances)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.2 — Update schedule instance fields.
  Future<ScheduleInstance> updateScheduleInstance(
      String id, ScheduleInstancesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.scheduleInstances)
              ..where((t) => t.scheduleInstanceId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule instance not found after update',
            context: {'scheduleInstanceId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update schedule instance',
        context: {'scheduleInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete schedule instance.
  Future<void> hardDeleteScheduleInstance(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.scheduleInstances)
              ..where((t) => t.scheduleInstanceId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule instance not found for hard delete',
            context: {'scheduleInstanceId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete schedule instance',
        context: {'scheduleInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // CalendarDay CRUD (base methods from Phase 1)
  // ===========================================================================

  // Spec: S08 §8.13.1 — Create calendar day slot container.
  Future<CalendarDay> createCalendarDay(CalendarDaysCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.calendarDays).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create calendar day',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve calendar day by primary key.
  Future<CalendarDay?> getCalendarDayById(String id) {
    return (_db.select(_db.calendarDays)
          ..where((t) => t.calendarDayId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Calendar days for a user within a date range.
  Stream<List<CalendarDay>> watchCalendarDaysByUser(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) {
    final query = _db.select(_db.calendarDays)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
    if (from != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(to));
    }
    return query.watch();
  }

  // TD-03 §3.2 — Calendar days for a user within a date range (Future, not Stream).
  Future<List<CalendarDay>> getCalendarDaysByUser(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) {
    final query = _db.select(_db.calendarDays)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
    if (from != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(to));
    }
    return query.get();
  }

  // TD-03 §3.2 — Update calendar day fields.
  Future<CalendarDay> updateCalendarDay(
      String id, CalendarDaysCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.calendarDays)
              ..where((t) => t.calendarDayId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found after update',
            context: {'calendarDayId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update calendar day',
        context: {'calendarDayId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete calendar day.
  Future<void> hardDeleteCalendarDay(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.calendarDays)
              ..where((t) => t.calendarDayId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found for hard delete',
            context: {'calendarDayId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete calendar day',
        context: {'calendarDayId': id, 'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // Private Helpers
  // ===========================================================================

  List<RoutineEntry> _parseRoutineEntries(String entriesJson) {
    final list = jsonDecode(entriesJson) as List<dynamic>;
    return list
        .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Removes entries from schedule JSON that reference a specific ID in the given field.
  /// For List mode: entries is a flat array of RoutineEntry.
  /// For DayPlanning mode: entries is an array of TemplateDay objects.
  /// Returns null if no changes, empty string if all entries removed, or new JSON.
  String? _removeEntriesFromScheduleJson(
    String entriesJson,
    String targetId,
    String fieldName,
  ) {
    final parsed = jsonDecode(entriesJson) as List<dynamic>;
    var changed = false;

    // Try List mode (flat array of entries).
    if (parsed.isNotEmpty && parsed.first is Map<String, dynamic>) {
      final first = parsed.first as Map<String, dynamic>;

      if (first.containsKey('type')) {
        // List mode: flat RoutineEntry array.
        final filtered = parsed.where((e) {
          final entry = e as Map<String, dynamic>;
          if (entry['type'] == 'Fixed' && entry[fieldName] == targetId) {
            changed = true;
            return false;
          }
          return true;
        }).toList();

        if (!changed) return null;
        if (filtered.isEmpty) return '';
        return jsonEncode(filtered);
      }

      if (first.containsKey('entries')) {
        // DayPlanning mode: array of TemplateDay.
        final newDays = <Map<String, dynamic>>[];
        for (final dayRaw in parsed) {
          final day = dayRaw as Map<String, dynamic>;
          final dayEntries = day['entries'] as List<dynamic>;
          final filtered = dayEntries.where((e) {
            final entry = e as Map<String, dynamic>;
            if (entry['type'] == 'Fixed' && entry[fieldName] == targetId) {
              changed = true;
              return false;
            }
            return true;
          }).toList();
          newDays.add({'entries': filtered});
        }

        if (!changed) return null;
        // Check if all template days are now empty.
        final allEmpty = newDays.every(
            (d) => (d['entries'] as List<dynamic>).isEmpty);
        if (allEmpty) return '';
        return jsonEncode(newDays);
      }
    }

    return null;
  }
}
