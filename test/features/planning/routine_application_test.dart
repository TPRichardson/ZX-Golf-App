import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/planning/routine_application.dart';

// Phase 5 — RoutineApplicator tests.
// S08 §8.2.2 — Apply routine to CalendarDay.

void main() {
  late AppDatabase db;
  late PlanningRepository repo;
  late RoutineApplicator applicator;

  const userId = 'test-user-routine-app';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db, SyncWriteGate());
    applicator = RoutineApplicator(repo);
  });

  tearDown(() async {
    await db.close();
  });

  group('RoutineApplicator (S08 §8.2.2)', () {
    test('apply 3-entry routine to day with 5 empty slots → 3 filled',
        () async {
      final date = DateTime(2026, 3, 1);

      final instance = await applicator.confirmApplication(
        userId,
        'routine-1',
        date,
        ['drill-1', 'drill-2', 'drill-3'],
      );

      expect(instance.routineId, 'routine-1');
      final ownedSlots =
          (jsonDecode(instance.ownedSlots) as List<dynamic>).cast<int>();
      expect(ownedSlots, [0, 1, 2]);

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].drillId, 'drill-1');
      expect(slots[0].ownerType, SlotOwnerType.routineInstance);
      expect(slots[1].drillId, 'drill-2');
      expect(slots[2].drillId, 'drill-3');
      expect(slots[3].isEmpty, isTrue);
      expect(slots[4].isEmpty, isTrue);
    });

    test('apply to day with 2 available slots → only 2 used', () async {
      final date = DateTime(2026, 3, 2);
      // Pre-fill 3 of 5 slots.
      await repo.assignDrillToSlot(userId, date, 0, 'existing-1');
      await repo.assignDrillToSlot(userId, date, 1, 'existing-2');
      await repo.assignDrillToSlot(userId, date, 2, 'existing-3');

      final instance = await applicator.confirmApplication(
        userId,
        'routine-1',
        date,
        ['drill-a', 'drill-b', 'drill-c'],
      );

      final ownedSlots =
          (jsonDecode(instance.ownedSlots) as List<dynamic>).cast<int>();
      expect(ownedSlots, [3, 4]); // Only 2 empty slots available.

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[3].drillId, 'drill-a');
      expect(slots[4].drillId, 'drill-b');
    });

    test('unapply clears owned slots', () async {
      final date = DateTime(2026, 3, 3);
      final instance = await applicator.confirmApplication(
        userId,
        'routine-1',
        date,
        ['drill-1', 'drill-2'],
      );

      await applicator.unapplyRoutineInstance(instance.routineInstanceId);

      // Instance should be deleted.
      final found =
          await repo.getRoutineInstanceById(instance.routineInstanceId);
      expect(found, isNull);

      // Slots should be cleared.
      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].isEmpty, isTrue);
      expect(slots[1].isEmpty, isTrue);
    });

    test('unapply preserves manually-edited slots', () async {
      final date = DateTime(2026, 3, 4);
      final instance = await applicator.confirmApplication(
        userId,
        'routine-1',
        date,
        ['drill-1', 'drill-2'],
      );

      // Manually edit slot 0 (break ownership).
      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      slots[0] = const Slot(
        drillId: 'manual-drill',
        ownerType: SlotOwnerType.manual,
      );
      await repo.updateSlots(day.calendarDayId, slots);

      await applicator.unapplyRoutineInstance(instance.routineInstanceId);

      // Slot 0 should be preserved (different owner), slot 1 should be cleared.
      final dayAfter = await repo.getCalendarDayByDate(userId, date);
      final slotsAfter = repo.parseSlots(dayAfter!.slots);
      expect(slotsAfter[0].drillId, 'manual-drill');
      expect(slotsAfter[1].isEmpty, isTrue);
    });

    test('slot ownership tracking correct', () async {
      final date = DateTime(2026, 3, 5);
      final instance = await applicator.confirmApplication(
        userId,
        'routine-1',
        date,
        ['drill-1'],
      );

      final day = await repo.getCalendarDayByDate(userId, date);
      final slots = repo.parseSlots(day!.slots);
      expect(slots[0].ownerId, instance.routineInstanceId);
      expect(slots[0].ownerType, SlotOwnerType.routineInstance);
    });

    test('previewApplication returns correct indices', () {
      final slots = [
        const Slot(drillId: 'existing-1'),
        const Slot(),
        const Slot(drillId: 'existing-2'),
        const Slot(),
        const Slot(),
      ];

      final indices = applicator.previewApplication(
        ['drill-a', 'drill-b'],
        slots,
      );

      expect(indices, [1, 3]);
    });
  });
}
