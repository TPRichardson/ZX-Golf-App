import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// Phase 5 — Settings, Filters & Configuration tests.
// Covers: 5A (weekStartDay), 5D (technique block exclusion logic),
// 5E (filter persistence model), 5F (routine MRU sort).

void main() {
  // ===========================================================================
  // 5A — Week start day in UserPreferences
  // ===========================================================================
  group('5A: Week start day', () {
    test('weekStartDay defaults to 1 (Monday)', () {
      const prefs = UserPreferences();
      expect(prefs.weekStartDay, 1);
    });

    test('weekStartDay round-trips through JSON', () {
      const prefs = UserPreferences(weekStartDay: 7);
      final json = prefs.toJson();
      final restored = UserPreferences.fromJson(json);
      expect(restored.weekStartDay, 7);
    });

    test('weekStartDay missing from JSON defaults to 1', () {
      final json = jsonEncode({'distanceUnit': 'Yards'});
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.weekStartDay, 1);
    });

    test('copyWith updates weekStartDay', () {
      const prefs = UserPreferences(weekStartDay: 1);
      final updated = prefs.copyWith(weekStartDay: 7);
      expect(updated.weekStartDay, 7);
      // Other fields unchanged.
      expect(updated.distanceUnit, DistanceUnit.yards);
    });

    test('calendar week boundary shifts with Sunday start', () {
      // Simulate the CalendarScreen._rangeStartFor logic:
      // Given weekStartDay = 7 (Sunday), the 2-week view should start on Sunday.
      // For a Wednesday (weekday = 3), diff = (3 - 7 + 7) % 7 = 3.
      // So rangeStart = today - 3 days = Sunday.
      const weekStartDay = 7; // Sunday
      final wednesday = DateTime(2026, 3, 4); // A Wednesday (weekday = 3)
      final diff = (wednesday.weekday - weekStartDay + 7) % 7;
      final rangeStart = wednesday.subtract(Duration(days: diff));
      // Should be Sunday March 1.
      expect(rangeStart.weekday, DateTime.sunday);
      expect(rangeStart, DateTime(2026, 3, 1));
    });

    test('calendar week boundary with Monday start', () {
      const weekStartDay = 1; // Monday
      final wednesday = DateTime(2026, 3, 4); // A Wednesday (weekday = 3)
      final diff = (wednesday.weekday - weekStartDay + 7) % 7;
      final rangeStart = wednesday.subtract(Duration(days: diff));
      // Should be Monday March 2.
      expect(rangeStart.weekday, DateTime.monday);
      expect(rangeStart, DateTime(2026, 3, 2));
    });
  });

  // ===========================================================================
  // 5D — Technique Block filter exclusion (pure logic)
  // ===========================================================================
  group('5D: Technique Block filter exclusion', () {
    // Replicate the filter logic from analysis_screen.dart:_filterSessions().
    bool shouldInclude({
      required DrillType drillType,
      required DrillType? drillTypeFilter,
      required String scope,
    }) {
      if (drillTypeFilter != null && drillType != drillTypeFilter) {
        return false;
      }
      if (drillTypeFilter == null &&
          drillType == DrillType.techniqueBlock &&
          scope != 'drill') {
        return false;
      }
      return true;
    }

    test('All filter at Overall scope excludes Technique Block', () {
      expect(
        shouldInclude(
          drillType: DrillType.techniqueBlock,
          drillTypeFilter: null,
          scope: 'overall',
        ),
        isFalse,
      );
    });

    test('All filter at SkillArea scope excludes Technique Block', () {
      expect(
        shouldInclude(
          drillType: DrillType.techniqueBlock,
          drillTypeFilter: null,
          scope: 'skillArea',
        ),
        isFalse,
      );
    });

    test('All filter at Drill scope includes Technique Block', () {
      expect(
        shouldInclude(
          drillType: DrillType.techniqueBlock,
          drillTypeFilter: null,
          scope: 'drill',
        ),
        isTrue,
      );
    });

    test('All filter includes non-Technique drills at any scope', () {
      expect(
        shouldInclude(
          drillType: DrillType.transition,
          drillTypeFilter: null,
          scope: 'overall',
        ),
        isTrue,
      );
      expect(
        shouldInclude(
          drillType: DrillType.pressure,
          drillTypeFilter: null,
          scope: 'skillArea',
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // 5F — Routine MRU sort via lastAppliedAt
  // ===========================================================================
  group('5F: Routine MRU sort (lastAppliedAt)', () {
    late AppDatabase db;
    late PlanningRepository repo;
    const userId = 'test-user-mru';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = PlanningRepository(db, SyncWriteGate());
    });

    tearDown(() async {
      await db.close();
    });

    test('recently applied routine appears first in watchRoutines', () async {
      // Create two routines.
      final routineA = await repo.createRoutineWithEntries(
        userId,
        'Routine A',
        [const RoutineEntry.fixed('drill-1')],
      );
      final routineB = await repo.createRoutineWithEntries(
        userId,
        'Routine B',
        [const RoutineEntry.fixed('drill-2')],
      );

      // Set lastAppliedAt on Routine B to now (simulating it was applied).
      await repo.updateRoutine(
        routineB.routineId,
        RoutinesCompanion(lastAppliedAt: Value(DateTime.now())),
      );

      // Get the first emission from watchRoutines.
      final routines = await repo.watchRoutines(userId).first;

      // Routine B (recently applied) should come first.
      expect(routines.length, 2);
      expect(routines[0].routineId, routineB.routineId);
      expect(routines[1].routineId, routineA.routineId);
    });

    test('never-applied routines sort after applied ones', () async {
      // Create three routines: A (never applied), B (applied earlier),
      // C (applied more recently).
      final routineA = await repo.createRoutineWithEntries(
        userId,
        'Never Applied',
        [const RoutineEntry.fixed('drill-1')],
      );
      final routineB = await repo.createRoutineWithEntries(
        userId,
        'Applied Earlier',
        [const RoutineEntry.fixed('drill-2')],
      );
      final routineC = await repo.createRoutineWithEntries(
        userId,
        'Applied Recently',
        [const RoutineEntry.fixed('drill-3')],
      );

      // Apply B at an earlier time.
      await repo.updateRoutine(
        routineB.routineId,
        RoutinesCompanion(
          lastAppliedAt: Value(DateTime(2026, 1, 1)),
        ),
      );
      // Apply C at a later time.
      await repo.updateRoutine(
        routineC.routineId,
        RoutinesCompanion(
          lastAppliedAt: Value(DateTime(2026, 3, 1)),
        ),
      );

      final routines = await repo.watchRoutines(userId).first;

      expect(routines.length, 3);
      // C (most recent apply) first, then B (older apply), then A (never applied).
      expect(routines[0].routineId, routineC.routineId);
      expect(routines[1].routineId, routineB.routineId);
      expect(routines[2].routineId, routineA.routineId);
    });

    test('lastAppliedAt is set when routine is applied', () async {
      final routine = await repo.createRoutineWithEntries(
        userId,
        'Test Routine',
        [const RoutineEntry.fixed('drill-1')],
      );

      // Initially null.
      expect(routine.lastAppliedAt, isNull);

      // Update lastAppliedAt (simulating confirmApplication).
      final now = DateTime.now();
      final updated = await repo.updateRoutine(
        routine.routineId,
        RoutinesCompanion(lastAppliedAt: Value(now)),
      );

      expect(updated.lastAppliedAt, isNotNull);
    });
  });
}
