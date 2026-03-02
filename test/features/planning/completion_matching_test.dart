import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/completion_matching.dart';

// Phase 5 — CompletionMatcher tests.
// S08 §8.3.2 — Auto-match closed sessions to CalendarDay slots.

void main() {
  late AppDatabase db;
  late PlanningRepository repo;
  late CompletionMatcher matcher;

  const userId = 'test-user-matching';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db, SyncWriteGate());
    matcher = CompletionMatcher(repo);
  });

  tearDown(() async {
    await db.close();
  });

  group('CompletionMatcher (S08 §8.3.2)', () {
    test('basic match: drill matches first incomplete slot', () async {
      final date = DateTime(2026, 3, 1);
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await repo.assignDrillToSlot(userId, date, 1, 'drill-2');

      await matcher.executeCompletionMatching(
        'session-1', 'drill-1', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].completionState, CompletionState.completedLinked);
      expect(slots[0].completingSessionId, 'session-1');
      expect(slots[1].completionState, CompletionState.incomplete);
    });

    test('duplicate drill: second session matches second slot', () async {
      final date = DateTime(2026, 3, 2);
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await repo.assignDrillToSlot(userId, date, 1, 'drill-1');

      await matcher.executeCompletionMatching(
        'session-1', 'drill-1', userId, date);
      await matcher.executeCompletionMatching(
        'session-2', 'drill-1', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].completionState, CompletionState.completedLinked);
      expect(slots[0].completingSessionId, 'session-1');
      expect(slots[1].completionState, CompletionState.completedLinked);
      expect(slots[1].completingSessionId, 'session-2');
    });

    test('no match + no empty slot → overflow (new slot, capacity +1, planned=false)',
        () async {
      final date = DateTime(2026, 3, 3);
      // Create day with drill-1 and drill-2 assigned.
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');

      // Complete a session for drill-3 (not in any slot).
      await matcher.executeCompletionMatching(
        'session-1', 'drill-3', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      // Original 5 slots + 1 overflow.
      expect(slots.length, 6);
      expect(day.slotCapacity, 6);
      expect(slots[5].drillId, 'drill-3');
      expect(slots[5].completionState, CompletionState.completedLinked);
      expect(slots[5].planned, isFalse);
    });

    test('no match + empty slot exists → no overflow (empty slot unrelated)',
        () async {
      final date = DateTime(2026, 3, 4);
      await repo.getOrCreateCalendarDay(userId, date);

      // Complete a session for drill-1 (not in any slot, but empty slots exist).
      await matcher.executeCompletionMatching(
        'session-1', 'drill-1', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      // Should have 6 slots: 5 original + 1 overflow.
      expect(slots.length, 6);
      expect(slots[5].drillId, 'drill-1');
      expect(slots[5].planned, isFalse);
    });

    test('already-complete slots skipped', () async {
      final date = DateTime(2026, 3, 5);
      final created = await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await repo.assignDrillToSlot(userId, date, 1, 'drill-1');
      await repo.markSlotComplete(created.calendarDayId, 0, 'session-old');

      // Match should skip slot 0 (already complete) and match slot 1.
      await matcher.executeCompletionMatching(
        'session-1', 'drill-1', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].completingSessionId, 'session-old');
      expect(slots[1].completingSessionId, 'session-1');
    });

    test('no CalendarDay entity → creates default day + overflow slot', () async {
      final date = DateTime(2026, 3, 6);

      await matcher.executeCompletionMatching(
        'session-1', 'drill-1', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      expect(day, isNotNull);
      // Default 5 empty slots + 1 overflow = 6.
      expect(day!.slotCapacity, 6);
      final slots = repo.parseSlots(day.slots);
      expect(slots.length, 6);
      expect(slots[5].drillId, 'drill-1');
      expect(slots[5].planned, isFalse);
      expect(slots[5].completionState, CompletionState.completedLinked);
    });

    test('revertCompletionForSession reverts matched slot', () async {
      final date = DateTime(2026, 3, 7);
      await repo.assignDrillToSlot(userId, date, 0, 'drill-1');
      await matcher.executeCompletionMatching(
        'session-1', 'drill-1', userId, date);

      await matcher.revertCompletionForSession('session-1', userId, date);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].completionState, CompletionState.incomplete);
      expect(slots[0].completingSessionId, isNull);
    });
  });
}
