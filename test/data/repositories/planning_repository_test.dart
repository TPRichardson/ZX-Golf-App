import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// Phase 5 — PlanningRepository tests.
// Covers: CalendarDay slot management (TD-04 §2.6),
// Routine state machine (TD-04 §2.8), Schedule state machine (TD-04 §2.9),
// cascade deletions (S08 §8.1.2, S08 §8.1.3).

void main() {
  late AppDatabase db;
  late PlanningRepository repo;

  const userId = 'test-user-planning';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ===========================================================================
  // CalendarDay Slot Management — TD-04 §2.6
  // ===========================================================================
  group('CalendarDay slot management (TD-04 §2.6)', () {
    test('getOrCreateCalendarDay creates with default capacity', () async {
      final date = DateTime(2026, 3, 1);
      final day = await repo.getOrCreateCalendarDay(userId, date);

      expect(day.userId, userId);
      expect(day.slotCapacity, 5);
      final slots = repo.parseSlots(day.slots);
      expect(slots.length, 5);
      expect(slots.every((s) => s.isEmpty), isTrue);
    });

    test('getOrCreateCalendarDay returns existing on second call', () async {
      final date = DateTime(2026, 3, 1);
      final day1 = await repo.getOrCreateCalendarDay(userId, date);
      final day2 = await repo.getOrCreateCalendarDay(userId, date);

      expect(day1.calendarDayId, day2.calendarDayId);
    });

    test('assignDrillToSlot fills empty slot', () async {
      final date = DateTime(2026, 3, 2);
      final day = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      final slots = repo.parseSlots(day.slots);

      expect(slots[0].drillId, 'drill-1');
      expect(slots[0].ownerType, SlotOwnerType.manual);
      expect(slots[0].completionState, CompletionState.incomplete);
      expect(slots[1].isEmpty, isTrue);
    });

    test('assignDrillToSlot rejects filled slot', () async {
      final date = DateTime(2026, 3, 3);
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');

      expect(
        () => repo.assignDrillToSlot(userId, date, 0, 'drill-2'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('assignDrillToSlot rejects out-of-range index', () async {
      final date = DateTime(2026, 3, 4);
      await repo.getOrCreateCalendarDay(userId, date);

      expect(
        () => repo.assignDrillToSlot(userId, date, 10, 'drill-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('clearSlot resets filled slot to empty', () async {
      final date = DateTime(2026, 3, 5);
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      final day = await repo.clearSlot(userId, date, 0);
      final slots = repo.parseSlots(day.slots);

      expect(slots[0].isEmpty, isTrue);
      expect(slots[0].ownerId, isNull);
    });

    test('updateSlotCapacity rejects below filled count', () async {
      final date = DateTime(2026, 3, 6);
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await repo.assignDrillToSlot(userId, date, 1, 'drill-2');
      await repo.assignDrillToSlot(userId, date, 2, 'drill-3');

      expect(
        () => repo.updateSlotCapacity(userId, date, 2),
        throwsA(isA<ValidationException>()),
      );
    });

    test('updateSlotCapacity increases capacity', () async {
      final date = DateTime(2026, 3, 7);
      await repo.getOrCreateCalendarDay(userId, date);
      final day = await repo.updateSlotCapacity(userId, date, 8);

      expect(day.slotCapacity, 8);
      final slots = repo.parseSlots(day.slots);
      expect(slots.length, 8);
    });

    test('markSlotComplete: Incomplete → CompletedLinked', () async {
      final date = DateTime(2026, 3, 8);
      final created = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      final day = await repo.markSlotComplete(
          created.calendarDayId, 0, 'session-1');
      final slots = repo.parseSlots(day.slots);

      expect(slots[0].completionState, CompletionState.completedLinked);
      expect(slots[0].completingSessionId, 'session-1');
    });

    test('markSlotComplete rejects already-completed slot', () async {
      final date = DateTime(2026, 3, 9);
      final created = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await repo.markSlotComplete(created.calendarDayId, 0, 'session-1');

      expect(
        () => repo.markSlotComplete(created.calendarDayId, 0, 'session-2'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('markSlotManualComplete: Incomplete → CompletedManual', () async {
      final date = DateTime(2026, 3, 10);
      final created = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      final day = await repo.markSlotManualComplete(
          created.calendarDayId, 0);
      final slots = repo.parseSlots(day.slots);

      expect(slots[0].completionState, CompletionState.completedManual);
    });

    test('revertSlotCompletion: CompletedLinked → Incomplete', () async {
      final date = DateTime(2026, 3, 11);
      final created = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await repo.markSlotComplete(created.calendarDayId, 0, 'session-1');
      final day = await repo.revertSlotCompletion(created.calendarDayId, 0);
      final slots = repo.parseSlots(day.slots);

      expect(slots[0].completionState, CompletionState.incomplete);
      expect(slots[0].completingSessionId, isNull);
    });

    test('revertSlotCompletion rejects Incomplete slot', () async {
      final date = DateTime(2026, 3, 12);
      final created = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');

      expect(
        () => repo.revertSlotCompletion(created.calendarDayId, 0),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ===========================================================================
  // Routine State Machine — TD-04 §2.8
  // ===========================================================================
  group('Routine state machine (TD-04 §2.8)', () {
    test('createRoutineWithEntries creates Active routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Morning Routine',
        [const RoutineEntry.fixed('drill-1')],
      );

      expect(routine.status, RoutineStatus.active);
      expect(routine.name, 'Morning Routine');

      final entries = (jsonDecode(routine.entries) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(entries.length, 1);
      expect(entries[0].type, RoutineEntryType.fixed);
      expect(entries[0].drillId, 'drill-1');
    });

    test('createRoutineWithEntries rejects empty entry list', () async {
      expect(
        () => repo.createRoutineWithEntries(userId, 'Empty', []),
        throwsA(isA<ValidationException>()),
      );
    });

    test('createRoutineWithEntries with mixed fixed + criterion entries',
        () async {
      final entries = [
        const RoutineEntry.fixed('drill-1'),
        RoutineEntry.criterion(const GenerationCriterion(
          skillArea: SkillArea.putting,
          mode: GenerationMode.weakest,
        )),
        const RoutineEntry.fixed('drill-2'),
      ];

      final routine = await repo.createRoutineWithEntries(
        userId,
        'Mixed Routine',
        entries,
      );

      final parsed = (jsonDecode(routine.entries) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(parsed.length, 3);
      expect(parsed[0].type, RoutineEntryType.fixed);
      expect(parsed[1].type, RoutineEntryType.criterion);
      expect(parsed[1].criterion!.skillArea, SkillArea.putting);
      expect(parsed[2].type, RoutineEntryType.fixed);
    });

    test('retireRoutine: Active → Retired', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'To Retire',
        [const RoutineEntry.fixed('drill-1')],
      );

      final retired = await repo.retireRoutine(routine.routineId);
      expect(retired.status, RoutineStatus.retired);
    });

    test('reactivateRoutine: Retired → Active', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'To Reactivate',
        [const RoutineEntry.fixed('drill-1')],
      );
      await repo.retireRoutine(routine.routineId);

      final reactivated = await repo.reactivateRoutine(routine.routineId);
      expect(reactivated.status, RoutineStatus.active);
    });

    test('deleteRoutine: Active → Deleted', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'To Delete',
        [const RoutineEntry.fixed('drill-1')],
      );

      await repo.deleteRoutine(routine.routineId);

      // Should not be found (filtered by isDeleted).
      final found = await repo.getRoutineById(routine.routineId);
      expect(found, isNull);
    });

    test('cannot update entries on Retired routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Retired',
        [const RoutineEntry.fixed('drill-1')],
      );
      await repo.retireRoutine(routine.routineId);

      expect(
        () => repo.updateRoutineEntries(
            routine.routineId, [const RoutineEntry.fixed('drill-2')]),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cannot retire already Retired routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Already Retired',
        [const RoutineEntry.fixed('drill-1')],
      );
      await repo.retireRoutine(routine.routineId);

      expect(
        () => repo.retireRoutine(routine.routineId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cannot reactivate Active routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Already Active',
        [const RoutineEntry.fixed('drill-1')],
      );

      expect(
        () => repo.reactivateRoutine(routine.routineId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('removeRoutineEntriesForDrill cascades', () async {
      await repo.createRoutineWithEntries(
        userId,
        'Has drill-1',
        [
          const RoutineEntry.fixed('drill-1'),
          const RoutineEntry.fixed('drill-2'),
        ],
      );

      await repo.removeRoutineEntriesForDrill('drill-1');

      final routines = await repo.watchRoutinesByUser(userId).first;
      expect(routines.length, 1);
      final entries = (jsonDecode(routines[0].entries) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(entries.length, 1);
      expect(entries[0].drillId, 'drill-2');
    });

    test('removeRoutineEntriesForDrill auto-deletes empty routine', () async {
      await repo.createRoutineWithEntries(
        userId,
        'Only drill-1',
        [const RoutineEntry.fixed('drill-1')],
      );

      await repo.removeRoutineEntriesForDrill('drill-1');

      final routines = await repo.watchRoutinesByUser(userId).first;
      expect(routines, isEmpty);
    });
  });

  // ===========================================================================
  // Schedule State Machine — TD-04 §2.9
  // ===========================================================================
  group('Schedule state machine (TD-04 §2.9)', () {
    test('createScheduleWithEntries creates List mode schedule', () async {
      final entries = [
        const RoutineEntry.fixed('drill-1'),
        const RoutineEntry.fixed('drill-2'),
      ];
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Week Plan',
        ScheduleAppMode.list,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );

      expect(schedule.status, ScheduleStatus.active);
      expect(schedule.applicationMode, ScheduleAppMode.list);
    });

    test('createScheduleWithEntries creates DayPlanning mode', () async {
      final templateDays = [
        TemplateDay(entries: [const RoutineEntry.fixed('drill-1')]),
        TemplateDay(entries: [const RoutineEntry.fixed('drill-2')]),
      ];
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Day Plan',
        ScheduleAppMode.dayPlanning,
        jsonEncode(templateDays.map((d) => d.toJson()).toList()),
      );

      expect(schedule.applicationMode, ScheduleAppMode.dayPlanning);
    });

    test('createScheduleWithEntries rejects empty entries', () async {
      expect(
        () => repo.createScheduleWithEntries(
          userId,
          'Empty',
          ScheduleAppMode.list,
          '[]',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('retireSchedule: Active → Retired', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'To Retire',
        ScheduleAppMode.list,
        jsonEncode([const RoutineEntry.fixed('drill-1').toJson()]),
      );

      final retired = await repo.retireSchedule(schedule.scheduleId);
      expect(retired.status, ScheduleStatus.retired);
    });

    test('reactivateSchedule: Retired → Active', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'To Reactivate',
        ScheduleAppMode.list,
        jsonEncode([const RoutineEntry.fixed('drill-1').toJson()]),
      );
      await repo.retireSchedule(schedule.scheduleId);

      final reactivated = await repo.reactivateSchedule(schedule.scheduleId);
      expect(reactivated.status, ScheduleStatus.active);
    });

    test('deleteSchedule: Active → Deleted', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'To Delete',
        ScheduleAppMode.list,
        jsonEncode([const RoutineEntry.fixed('drill-1').toJson()]),
      );

      await repo.deleteSchedule(schedule.scheduleId);
      final found = await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNull);
    });

    test('cannot update entries on Retired schedule', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Retired',
        ScheduleAppMode.list,
        jsonEncode([const RoutineEntry.fixed('drill-1').toJson()]),
      );
      await repo.retireSchedule(schedule.scheduleId);

      expect(
        () => repo.updateScheduleEntries(
          schedule.scheduleId,
          jsonEncode([const RoutineEntry.fixed('drill-2').toJson()]),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('removeScheduleEntriesForDrill cascades', () async {
      final entries = [
        const RoutineEntry.fixed('drill-1'),
        const RoutineEntry.fixed('drill-2'),
      ];
      await repo.createScheduleWithEntries(
        userId,
        'Has drill-1',
        ScheduleAppMode.list,
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );

      await repo.removeScheduleEntriesForDrill('drill-1');

      final schedules = await repo.watchSchedulesByUser(userId).first;
      expect(schedules.length, 1);
      final parsed = (jsonDecode(schedules[0].entries) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(parsed.length, 1);
      expect(parsed[0].drillId, 'drill-2');
    });

    test('removeScheduleEntriesForDrill auto-deletes empty schedule',
        () async {
      await repo.createScheduleWithEntries(
        userId,
        'Only drill-1',
        ScheduleAppMode.list,
        jsonEncode([const RoutineEntry.fixed('drill-1').toJson()]),
      );

      await repo.removeScheduleEntriesForDrill('drill-1');

      final schedules = await repo.watchSchedulesByUser(userId).first;
      expect(schedules, isEmpty);
    });
  });
}
