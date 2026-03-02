import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/completion_matching.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/planning/routine_application.dart';

// Integration tests for completion matching + routine application flow.
// Covers S08 §8.3.2 completion matching with routine-applied slots.

void main() {
  late AppDatabase db;
  late PlanningRepository repo;
  late CompletionMatcher matcher;
  late RoutineApplicator applicator;

  const userId = 'test-user-integration';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db);
    matcher = CompletionMatcher(repo);
    applicator = RoutineApplicator(repo);
  });

  tearDown(() async {
    await db.close();
  });

  group('Full flow: routine → apply → complete → match', () {
    test('create routine, apply to day, match session to slot', () async {
      // 1. Create routine with 2 fixed entries.
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Test Routine',
        [
          const RoutineEntry.fixed('drill-a'),
          const RoutineEntry.fixed('drill-b'),
        ],
      );

      // 2. Apply routine to today.
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final instance = await applicator.confirmApplication(
        userId,
        routine.routineId,
        todayDate,
        ['drill-a', 'drill-b'],
      );

      expect(instance.routineId, routine.routineId);

      // 3. Verify slots are filled.
      final day = await repo.getOrCreateCalendarDay(userId, todayDate);
      final slots = repo.parseSlots(day.slots);
      final filledSlots = slots.where((s) => s.isFilled).toList();
      expect(filledSlots.length, 2);
      expect(filledSlots[0].drillId, 'drill-a');
      expect(filledSlots[1].drillId, 'drill-b');

      // 4. Complete a session for drill-a.
      await matcher.executeCompletionMatching(
        'session-1',
        'drill-a',
        userId,
        todayDate,
      );

      // 5. Verify first matching slot is now CompletedLinked.
      final dayAfter =
          await repo.getCalendarDayByDate(userId, todayDate);
      final slotsAfter = repo.parseSlots(dayAfter!.slots);
      final completedSlot = slotsAfter.firstWhere(
        (s) => s.drillId == 'drill-a' && s.isCompleted,
      );
      expect(completedSlot.completionState,
          CompletionState.completedLinked);
      expect(completedSlot.completingSessionId, 'session-1');
    });

    test('completion overflow creates new slot when no match', () async {
      // 1. Create a day with 2 slots, both filled with drill-a.
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final day =
          await repo.getOrCreateCalendarDay(userId, todayDate);
      final slots = repo.parseSlots(day.slots);
      // Fill first two with drill-a.
      slots[0] = const Slot(drillId: 'drill-a');
      slots[1] = const Slot(drillId: 'drill-a');
      await repo.updateSlots(day.calendarDayId, slots);

      // 2. Complete two sessions for drill-a (matches both slots).
      await matcher.executeCompletionMatching(
        'session-1', 'drill-a', userId, todayDate);
      await matcher.executeCompletionMatching(
        'session-2', 'drill-a', userId, todayDate);

      // 3. Complete a third session for drill-c (not in any slot).
      // This should trigger overflow.
      await matcher.executeCompletionMatching(
        'session-3', 'drill-c', userId, todayDate);

      // 4. Verify overflow slot was created.
      final dayAfter =
          await repo.getCalendarDayByDate(userId, todayDate);
      final slotsAfter = repo.parseSlots(dayAfter!.slots);
      // Should have original 5 + 1 overflow = 6 total.
      expect(dayAfter.slotCapacity, 6);
      final overflowSlot =
          slotsAfter.firstWhere((s) => s.drillId == 'drill-c');
      expect(overflowSlot.isCompleted, true);
      expect(overflowSlot.planned, false);
    });

    test('session revert undoes completion matching', () async {
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Setup: day with drill-a in slot 0.
      await repo.getOrCreateCalendarDay(userId, todayDate);
      await repo.assignDrillToSlot(userId, todayDate, 0, 'drill-a');

      // Complete session for drill-a.
      await matcher.executeCompletionMatching(
        'session-x', 'drill-a', userId, todayDate);

      // Verify completed.
      var dayNow =
          await repo.getCalendarDayByDate(userId, todayDate);
      var slotsNow = repo.parseSlots(dayNow!.slots);
      expect(slotsNow[0].isCompleted, true);

      // Revert.
      await matcher.revertCompletionForSession(
          'session-x', userId, todayDate);

      // Verify reverted.
      dayNow = await repo.getCalendarDayByDate(userId, todayDate);
      slotsNow = repo.parseSlots(dayNow!.slots);
      expect(slotsNow[0].completionState,
          CompletionState.incomplete);
      expect(slotsNow[0].completingSessionId, null);
    });
  });

  group('Routine unapply clears owned slots', () {
    test('unapply routine instance clears owned slots', () async {
      // 1. Create routine + apply.
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Unapply Test',
        [
          const RoutineEntry.fixed('drill-x'),
          const RoutineEntry.fixed('drill-y'),
        ],
      );

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final instance = await applicator.confirmApplication(
        userId,
        routine.routineId,
        todayDate,
        ['drill-x', 'drill-y'],
      );

      // 2. Verify slots are filled.
      var day =
          await repo.getCalendarDayByDate(userId, todayDate);
      var slots = repo.parseSlots(day!.slots);
      expect(
          slots.where((s) => s.isFilled).length, greaterThanOrEqualTo(2));

      // 3. Unapply.
      await applicator.unapplyRoutineInstance(
          instance.routineInstanceId);

      // 4. Verify slots cleared.
      day = await repo.getCalendarDayByDate(userId, todayDate);
      slots = repo.parseSlots(day!.slots);
      final owned = slots.where(
          (s) => s.ownerId == instance.routineInstanceId).toList();
      expect(owned, isEmpty);
    });
  });
}
