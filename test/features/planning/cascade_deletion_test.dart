import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// S08 §8.1.2, §8.1.3 — Drill deletion cascade tests.
// Verifies removeRoutineEntriesForDrill and removeScheduleEntriesForDrill
// correctly cascade and auto-delete empty routines/schedules.

void main() {
  late AppDatabase db;
  late PlanningRepository repo;

  const userId = 'test-user-cascade';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PlanningRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Drill deletion cascade to Routines', () {
    test('removes fixed entries referencing deleted drill', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Mixed Routine',
        [
          const RoutineEntry.fixed('drill-a'),
          const RoutineEntry.fixed('drill-b'),
          const RoutineEntry.criterion(GenerationCriterion()),
        ],
      );

      // Delete drill-a.
      await repo.removeRoutineEntriesForDrill('drill-a');

      // Verify entry removed but routine survives.
      final updated = await repo.getRoutineById(routine.routineId);
      expect(updated, isNotNull);
      final entries = (jsonDecode(updated!.entries) as List<dynamic>)
          .map(
              (e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(entries.length, 2);
      expect(
          entries.any((e) =>
              e.type == RoutineEntryType.fixed &&
              e.drillId == 'drill-a'),
          false);
      expect(
          entries.any((e) =>
              e.type == RoutineEntryType.fixed &&
              e.drillId == 'drill-b'),
          true);
    });

    test('auto-deletes routine when all entries removed', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Single Entry Routine',
        [const RoutineEntry.fixed('drill-a')],
      );

      await repo.removeRoutineEntriesForDrill('drill-a');

      // Routine should be soft-deleted.
      final found = await repo.getRoutineById(routine.routineId);
      expect(found, isNull);
    });

    test('does nothing when drill ID not found in entries', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Unaffected Routine',
        [const RoutineEntry.fixed('drill-x')],
      );

      await repo.removeRoutineEntriesForDrill('drill-nonexistent');

      final found = await repo.getRoutineById(routine.routineId);
      expect(found, isNotNull);
      final entries = (jsonDecode(found!.entries) as List<dynamic>)
          .map(
              (e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(entries.length, 1);
    });
  });

  group('Drill deletion cascade to Schedules', () {
    test('removes entries from List mode schedule', () async {
      final entriesJson = jsonEncode([
        const RoutineEntry.fixed('drill-a').toJson(),
        const RoutineEntry.fixed('drill-b').toJson(),
      ]);

      final schedule = await repo.createScheduleWithEntries(
        userId,
        'List Schedule',
        ScheduleAppMode.list,
        entriesJson,
      );

      await repo.removeScheduleEntriesForDrill('drill-a');

      final found =
          await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNotNull);
      final entries = (jsonDecode(found!.entries) as List<dynamic>)
          .map(
              (e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(entries.length, 1);
      expect(entries[0].drillId, 'drill-b');
    });

    test('auto-deletes schedule when all entries removed',
        () async {
      final entriesJson = jsonEncode([
        const RoutineEntry.fixed('drill-a').toJson(),
      ]);

      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Single Entry Schedule',
        ScheduleAppMode.list,
        entriesJson,
      );

      await repo.removeScheduleEntriesForDrill('drill-a');

      final found =
          await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNull);
    });

    test('removes entries from DayPlanning mode schedule',
        () async {
      final entriesJson = jsonEncode([
        {
          'entries': [
            const RoutineEntry.fixed('drill-a').toJson(),
            const RoutineEntry.fixed('drill-b').toJson(),
          ]
        },
        {
          'entries': [
            const RoutineEntry.fixed('drill-a').toJson(),
          ]
        },
      ]);

      final schedule = await repo.createScheduleWithEntries(
        userId,
        'DayPlanning Schedule',
        ScheduleAppMode.dayPlanning,
        entriesJson,
      );

      await repo.removeScheduleEntriesForDrill('drill-a');

      final found =
          await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNotNull);
      // Day 1 should have drill-b only, Day 2 should be empty.
      final days = jsonDecode(found!.entries) as List<dynamic>;
      final day1 = TemplateDay.fromJson(
          days[0] as Map<String, dynamic>);
      final day2 = TemplateDay.fromJson(
          days[1] as Map<String, dynamic>);
      expect(day1.entries.length, 1);
      expect(day1.entries[0].drillId, 'drill-b');
      expect(day2.entries.length, 0);
    });

    test(
        'auto-deletes DayPlanning schedule when all template days empty',
        () async {
      final entriesJson = jsonEncode([
        {
          'entries': [
            const RoutineEntry.fixed('drill-a').toJson(),
          ]
        },
      ]);

      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Empty DayPlanning',
        ScheduleAppMode.dayPlanning,
        entriesJson,
      );

      await repo.removeScheduleEntriesForDrill('drill-a');

      final found =
          await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNull);
    });
  });

  group('Routine deletion cascade to Schedules', () {
    test('removeScheduleEntriesForRoutine removes routine references',
        () async {
      // This tests the routine → schedule cascade path.
      // Schedules don't directly reference routineIds in the current model,
      // so this verifies the method exists and handles gracefully.
      final entriesJson = jsonEncode([
        const RoutineEntry.fixed('drill-a').toJson(),
      ]);

      final schedule = await repo.createScheduleWithEntries(
        userId,
        'Schedule with no routine refs',
        ScheduleAppMode.list,
        entriesJson,
      );

      // This should not affect the schedule (no routineId entries).
      await repo.removeScheduleEntriesForRoutine('routine-xyz');

      final found =
          await repo.getScheduleById(schedule.scheduleId);
      expect(found, isNotNull);
    });
  });
}
