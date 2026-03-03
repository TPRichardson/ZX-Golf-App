import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// S08 §8.2.2 — Routine application: apply a Routine to a CalendarDay.

class RoutineApplicator {
  final PlanningRepository _planningRepo;

  static const _uuid = Uuid();

  RoutineApplicator(this._planningRepo);

  /// S08 §8.2.2 — Preview applying a routine to a calendar day.
  /// Returns the list of slots that would be filled (only empty slots used).
  List<int> previewApplication(
    List<String> resolvedDrillIds,
    List<Slot> existingSlots,
  ) {
    final emptyIndices = <int>[];
    for (var i = 0; i < existingSlots.length; i++) {
      if (existingSlots[i].isEmpty) {
        emptyIndices.add(i);
      }
    }

    // Only fill as many as we have drills, limited by empty slots.
    final fillCount =
        resolvedDrillIds.length < emptyIndices.length
            ? resolvedDrillIds.length
            : emptyIndices.length;

    return emptyIndices.sublist(0, fillCount);
  }

  /// S08 §8.2.2 — Confirm application: fill empty slots, create RoutineInstance.
  Future<RoutineInstance> confirmApplication(
    String userId,
    String routineId,
    DateTime date,
    List<String> resolvedDrillIds,
  ) async {
    // S09 §9.3 — Bag gate: validate all resolved drills have eligible clubs.
    for (final drillId in resolvedDrillIds) {
      await _planningRepo.validateDrillClubEligibility(userId, drillId);
    }

    final day = await _planningRepo.getOrCreateCalendarDay(userId, date);
    final slots = _planningRepo.parseSlots(day.slots);

    final slotIndices = previewApplication(resolvedDrillIds, slots);
    final instanceId = _uuid.v4();
    final ownedSlots = <int>[];

    // Fill empty slots with resolved drills.
    for (var i = 0; i < slotIndices.length; i++) {
      final slotIndex = slotIndices[i];
      slots[slotIndex] = Slot(
        drillId: resolvedDrillIds[i],
        ownerType: SlotOwnerType.routineInstance,
        ownerId: instanceId,
        completionState: CompletionState.incomplete,
        planned: true,
      );
      ownedSlots.add(slotIndex);
    }

    await _planningRepo.updateSlots(day.calendarDayId, slots);

    return _planningRepo.createRoutineInstance(RoutineInstancesCompanion(
      routineInstanceId: Value(instanceId),
      routineId: Value(routineId),
      userId: Value(userId),
      calendarDayDate: Value(DateTime(date.year, date.month, date.day)),
      ownedSlots: Value(jsonEncode(ownedSlots)),
    ));
  }

  /// S08 §8.2.2 — Unapply a routine instance: clear owned slots, delete instance.
  /// Only clears slots that still have this instance as owner (manual edits break ownership).
  Future<void> unapplyRoutineInstance(String routineInstanceId) async {
    final instance =
        await _planningRepo.getRoutineInstanceById(routineInstanceId);
    if (instance == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Routine instance not found',
        context: {'routineInstanceId': routineInstanceId},
      );
    }

    final day = await _planningRepo.getCalendarDayByDate(
      instance.userId,
      instance.calendarDayDate,
    );

    if (day != null) {
      final slots = _planningRepo.parseSlots(day.slots);
      final ownedSlots =
          (jsonDecode(instance.ownedSlots) as List<dynamic>)
              .cast<int>();

      for (final slotIndex in ownedSlots) {
        if (slotIndex < slots.length &&
            slots[slotIndex].ownerId == routineInstanceId) {
          slots[slotIndex] = const Slot();
        }
      }

      await _planningRepo.updateSlots(day.calendarDayId, slots);
    }

    await _planningRepo.hardDeleteRoutineInstance(routineInstanceId);
  }
}
