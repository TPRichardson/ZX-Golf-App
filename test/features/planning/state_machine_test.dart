import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// TD-04 §2.6 (Slot), §2.8 (Routine), §2.9 (Schedule) state machine tests.

void main() {
  late AppDatabase db;
  late PlanningRepository repo;

  const userId = 'test-user-sm';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TD-04 §2.6 — Slot state transitions', () {
    test('Empty → Filled via assignDrillToSlot', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      await repo.getOrCreateCalendarDay(userId, todayDate);

      final day = await repo.assignDrillToSlot(
          userId, todayDate, 0, 'drill-1');
      final slots = repo.parseSlots(day.slots);
      expect(slots[0].drillId, 'drill-1');
      expect(slots[0].isFilled, true);
    });

    test('Filled → Empty via clearSlot', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-1');

      final day = await repo.clearSlot(userId, todayDate, 0);
      final slots = repo.parseSlots(day.slots);
      expect(slots[0].isEmpty, true);
    });

    test('Incomplete → CompletedLinked via markSlotComplete', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final day =
          await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-1');

      final reloaded =
          await repo.getCalendarDayById(day.calendarDayId);
      final dayAfter = await repo.markSlotComplete(
          reloaded!.calendarDayId, 0, 'session-1');
      final slots = repo.parseSlots(dayAfter.slots);
      expect(slots[0].completionState,
          CompletionState.completedLinked);
      expect(slots[0].completingSessionId, 'session-1');
    });

    test('Incomplete → CompletedManual via markSlotManualComplete',
        () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final day =
          await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-1');

      final reloaded =
          await repo.getCalendarDayById(day.calendarDayId);
      final dayAfter = await repo.markSlotManualComplete(
          reloaded!.calendarDayId, 0);
      final slots = repo.parseSlots(dayAfter.slots);
      expect(slots[0].completionState,
          CompletionState.completedManual);
    });

    test('CompletedLinked → Incomplete via revertSlotCompletion',
        () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final day =
          await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-1');

      var reloaded =
          await repo.getCalendarDayById(day.calendarDayId);
      await repo.markSlotComplete(
          reloaded!.calendarDayId, 0, 'session-1');

      reloaded =
          await repo.getCalendarDayById(day.calendarDayId);
      final dayAfter = await repo.revertSlotCompletion(
          reloaded!.calendarDayId, 0);
      final slots = repo.parseSlots(dayAfter.slots);
      expect(slots[0].completionState,
          CompletionState.incomplete);
      expect(slots[0].completingSessionId, null);
    });

    test('Cannot mark already-completed slot as complete', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final day =
          await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-1');

      final reloaded =
          await repo.getCalendarDayById(day.calendarDayId);
      await repo.markSlotManualComplete(
          reloaded!.calendarDayId, 0);

      final reloaded2 =
          await repo.getCalendarDayById(day.calendarDayId);
      expect(
        () => repo.markSlotManualComplete(
            reloaded2!.calendarDayId, 0),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Cannot revert non-completed slot', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final day =
          await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-1');

      final reloaded =
          await repo.getCalendarDayById(day.calendarDayId);
      expect(
        () => repo.revertSlotCompletion(
            reloaded!.calendarDayId, 0),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('TD-04 §2.8 — Routine state machine', () {
    test('Active → Retired → Active lifecycle', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Lifecycle Test',
        [const RoutineEntry.fixed('drill-1')],
      );
      expect(routine.status, RoutineStatus.active);

      final retired = await repo.retireRoutine(routine.routineId);
      expect(retired.status, RoutineStatus.retired);

      final reactivated =
          await repo.reactivateRoutine(routine.routineId);
      expect(reactivated.status, RoutineStatus.active);
    });

    test('Active → Deleted', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Delete Test',
        [const RoutineEntry.fixed('drill-1')],
      );

      await repo.deleteRoutine(routine.routineId);
      final found = await repo.getRoutineById(routine.routineId);
      expect(found, isNull); // Filtered by isDeleted = false.
    });

    test('Retired → Deleted', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Retire Then Delete',
        [const RoutineEntry.fixed('drill-1')],
      );

      await repo.retireRoutine(routine.routineId);
      await repo.deleteRoutine(routine.routineId);
      final found = await repo.getRoutineById(routine.routineId);
      expect(found, isNull);
    });

    test('Cannot retire a Retired routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Double Retire',
        [const RoutineEntry.fixed('drill-1')],
      );
      await repo.retireRoutine(routine.routineId);

      expect(
        () => repo.retireRoutine(routine.routineId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Cannot reactivate an Active routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Active Reactivate',
        [const RoutineEntry.fixed('drill-1')],
      );

      expect(
        () => repo.reactivateRoutine(routine.routineId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Cannot update entries on Retired routine', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Retired Update',
        [const RoutineEntry.fixed('drill-1')],
      );
      await repo.retireRoutine(routine.routineId);

      expect(
        () => repo.updateRoutineEntries(
          routine.routineId,
          [const RoutineEntry.fixed('drill-2')],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('TD-04 §2.9 — Schedule state machine', () {
    test('Active → Retired → Active lifecycle', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Schedule Lifecycle',
        ScheduleAppMode.list,
        '[{"type":"Fixed","drillId":"drill-1","criterion":null}]',
      );
      expect(schedule.status, ScheduleStatus.active);

      final retired =
          await repo.retireSchedule(schedule.scheduleId);
      expect(retired.status, ScheduleStatus.retired);

      final reactivated =
          await repo.reactivateSchedule(schedule.scheduleId);
      expect(reactivated.status, ScheduleStatus.active);
    });

    test('Active → Deleted', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Schedule Delete',
        ScheduleAppMode.list,
        '[{"type":"Fixed","drillId":"drill-1","criterion":null}]',
      );

      await repo.deleteSchedule(schedule.scheduleId);
      final found =
          await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNull);
    });

    test('Cannot retire a Retired schedule', () async {
      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Double Retire Schedule',
        ScheduleAppMode.list,
        '[{"type":"Fixed","drillId":"drill-1","criterion":null}]',
      );
      await repo.retireSchedule(schedule.scheduleId);

      expect(
        () => repo.retireSchedule(schedule.scheduleId),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
