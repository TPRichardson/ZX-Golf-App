import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/schedule_application.dart';

// Phase 5 — ScheduleApplicator tests.
// S08 §8.2.3, S08 §8.10.3 — Schedule application across date ranges.

void main() {
  late AppDatabase db;
  late PlanningRepository repo;
  late ScheduleApplicator applicator;

  const userId = 'test-user-schedule-app';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db, SyncWriteGate());
    applicator = ScheduleApplicator(repo);
  });

  tearDown(() async {
    await db.close();
  });

  group('ScheduleApplicator — List mode (S08 §8.10.3)', () {
    test('6 entries across 3 days (2 slots each)', () {
      final dates = [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 3),
      ];
      final capacities = {
        for (final d in dates) d: 2,
      };

      final preview = applicator.previewListMode(
        ['d1', 'd2', 'd3', 'd4', 'd5', 'd6'],
        dates,
        capacities,
      );

      expect(preview[dates[0]], ['d1', 'd2']);
      expect(preview[dates[1]], ['d3', 'd4']);
      expect(preview[dates[2]], ['d5', 'd6']);
    });

    test('wraps when entries exhausted', () {
      final dates = [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
      ];
      final capacities = {
        dates[0]: 2,
        dates[1]: 2,
      };

      final preview = applicator.previewListMode(
        ['d1', 'd2', 'd3'],
        dates,
        capacities,
      );

      expect(preview[dates[0]], ['d1', 'd2']);
      expect(preview[dates[1]], ['d3', 'd1']); // Wraps.
    });

    test('skips capacity=0 days', () {
      final dates = [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 3),
      ];
      final capacities = {
        dates[0]: 2,
        dates[1]: 0,
        dates[2]: 2,
      };

      final preview = applicator.previewListMode(
        ['d1', 'd2', 'd3', 'd4'],
        dates,
        capacities,
      );

      expect(preview.containsKey(dates[1]), isFalse);
      expect(preview[dates[0]], ['d1', 'd2']);
      expect(preview[dates[2]], ['d3', 'd4']);
    });
  });

  group('ScheduleApplicator — DayPlanning mode (S08 §8.10.3)', () {
    test('3 template days across 7 real days (wrapping)', () {
      final dates = List.generate(
        7,
        (i) => DateTime(2026, 3, 1 + i),
      );
      final capacities = {for (final d in dates) d: 2};

      final preview = applicator.previewDayPlanningMode(
        [
          ['putting-1', 'putting-2'],
          ['irons-1', 'irons-2'],
          ['driving-1'],
        ],
        dates,
        capacities,
      );

      // Day 0 → template 0, Day 1 → template 1, Day 2 → template 2
      // Day 3 → template 0, Day 4 → template 1, Day 5 → template 2
      // Day 6 → template 0
      expect(preview[dates[0]], ['putting-1', 'putting-2']);
      expect(preview[dates[1]], ['irons-1', 'irons-2']);
      expect(preview[dates[2]], ['driving-1']);
      expect(preview[dates[3]], ['putting-1', 'putting-2']);
      expect(preview[dates[6]], ['putting-1', 'putting-2']);
    });

    test('capacity=0 days consume template position', () {
      final dates = [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 3),
      ];
      final capacities = {
        dates[0]: 2,
        dates[1]: 0, // Skips but consumes template 1.
        dates[2]: 2,
      };

      final preview = applicator.previewDayPlanningMode(
        [
          ['putting-1'],
          ['irons-1'],
          ['driving-1'],
        ],
        dates,
        capacities,
      );

      expect(preview[dates[0]], ['putting-1']); // Template 0.
      expect(preview.containsKey(dates[1]), isFalse); // Skipped (capacity=0).
      expect(preview[dates[2]], ['driving-1']); // Template 2 (not 1).
    });
  });

  group('ScheduleApplicator — confirmApplication + unapply', () {
    test('confirmApplication fills slots across multiple days', () async {
      final dates = [
        DateTime(2026, 3, 1),
        DateTime(2026, 3, 2),
      ];

      final resolvedMap = <DateTime, List<String>>{
        dates[0]: ['drill-1', 'drill-2'],
        dates[1]: ['drill-3'],
      };

      final instance = await applicator.confirmApplication(
        userId,
        'schedule-1',
        dates[0],
        dates[1],
        resolvedMap,
      );

      expect(instance.scheduleId, 'schedule-1');

      final day1 = await repo.getCalendarDayByDate(userId, dates[0]);
      final slots1 = repo.parseSlots(day1!.slots);
      expect(slots1[0].drillId, 'drill-1');
      expect(slots1[0].ownerType, SlotOwnerType.scheduleInstance);
      expect(slots1[1].drillId, 'drill-2');

      final day2 = await repo.getCalendarDayByDate(userId, dates[1]);
      final slots2 = repo.parseSlots(day2!.slots);
      expect(slots2[0].drillId, 'drill-3');
    });

    test('unapply clears across multiple days', () async {
      final dates = [
        DateTime(2026, 3, 3),
        DateTime(2026, 3, 4),
      ];

      final resolvedMap = <DateTime, List<String>>{
        dates[0]: ['drill-a'],
        dates[1]: ['drill-b'],
      };

      final instance = await applicator.confirmApplication(
        userId,
        'schedule-1',
        dates[0],
        dates[1],
        resolvedMap,
      );

      await applicator.unapplyScheduleInstance(instance.scheduleInstanceId);

      final day1 = await repo.getCalendarDayByDate(userId, dates[0]);
      final slots1 = repo.parseSlots(day1!.slots);
      expect(slots1[0].isEmpty, isTrue);

      final day2 = await repo.getCalendarDayByDate(userId, dates[1]);
      final slots2 = repo.parseSlots(day2!.slots);
      expect(slots2[0].isEmpty, isTrue);

      final found =
          await repo.getScheduleInstanceById(instance.scheduleInstanceId);
      expect(found, isNull);
    });
  });
}
