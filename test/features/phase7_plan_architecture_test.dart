import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// Phase 7 — Plan Architecture Enhancement tests.
// Covers: 7A Save & Practice (repo level), 7B Clone Routine, 7D Volume chart legend (pure logic).

void main() {
  late AppDatabase db;
  late PracticeRepository practiceRepo;
  late PlanningRepository planningRepo;

  const userId = 'test-user-phase7';
  const drillId1 = 'drill-p7-1';
  const drillId2 = 'drill-p7-2';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncWriteGate = SyncWriteGate();
    final eventLogRepo = EventLogRepository(db, syncWriteGate);
    final scoringRepo = ScoringRepository(db);
    final reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    practiceRepo =
        PracticeRepository(db, reflowEngine, eventLogRepo, syncWriteGate);
    planningRepo = PlanningRepository(db, syncWriteGate);

    // S09 §9.3 — Seed clubs.
    final clubRepo = ClubRepository(db, syncWriteGate);
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));

    // Seed drills.
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId1,
      name: 'Phase 7 Drill A',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(5),
    ));

    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId2,
      name: 'Phase 7 Drill B',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // 7A: Save & Practice (repo-level verification)
  // ---------------------------------------------------------------------------

  group('7A: Save & Practice', () {
    test('create drill then PracticeBlock with that drill', () async {
      // Simulate: custom drill is created, then PB is started with it.
      final pb = await practiceRepo.createPracticeBlock(userId,
          initialDrillIds: [drillId1]);

      // Verify PB exists with 1 entry.
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      expect(entries.length, 1);
      expect(entries.first.drillId, drillId1);
    });
  });

  // ---------------------------------------------------------------------------
  // 7B: Clone Routine
  // ---------------------------------------------------------------------------

  group('7B: Clone Routine', () {
    test('duplicate routine with 2 entries creates new routine', () async {
      // Create original routine with 2 entries.
      final original = await planningRepo.createRoutineWithEntries(
        userId,
        'Morning Practice',
        [RoutineEntry.fixed(drillId1), RoutineEntry.fixed(drillId2)],
      );

      // Parse original entries.
      final originalEntries =
          (jsonDecode(original.entries) as List<dynamic>)
              .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
              .toList();

      // Clone: create new routine with same entries.
      final cloned = await planningRepo.createRoutineWithEntries(
        userId,
        '${original.name} (Copy)',
        originalEntries,
      );

      // Verify different IDs.
      expect(cloned.routineId, isNot(original.routineId));
      expect(cloned.name, 'Morning Practice (Copy)');

      // Verify same number of entries.
      final clonedEntries =
          (jsonDecode(cloned.entries) as List<dynamic>)
              .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
              .toList();
      expect(clonedEntries.length, 2);
    });

    test('cloned routine is independent of original', () async {
      final original = await planningRepo.createRoutineWithEntries(
        userId,
        'Test Routine',
        [RoutineEntry.fixed(drillId1)],
      );

      // Clone it.
      final originalEntries =
          (jsonDecode(original.entries) as List<dynamic>)
              .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
              .toList();
      final cloned = await planningRepo.createRoutineWithEntries(
        userId,
        '${original.name} (Copy)',
        originalEntries,
      );

      // Delete original.
      await planningRepo.deleteRoutine(original.routineId);

      // Clone still exists.
      final remaining = await planningRepo.watchRoutines(userId).first;
      expect(remaining.length, 1);
      expect(remaining.first.routineId, cloned.routineId);
    });
  });

  // ---------------------------------------------------------------------------
  // 7C: Edit Drill cross-nav (data-level: origin detection)
  // ---------------------------------------------------------------------------

  group('7C: Edit Drill cross-nav', () {
    test('standard drill has DrillOrigin.standard', () async {
      final drill = await (db.select(db.drills)
            ..where((t) => t.drillId.equals(drillId1)))
          .getSingle();
      expect(drill.origin, DrillOrigin.standard);
    });

    test('custom drill has DrillOrigin.custom', () async {
      await db.into(db.drills).insert(DrillsCompanion.insert(
        drillId: 'drill-custom',
        name: 'Custom Drill',
        skillArea: SkillArea.putting,
        drillType: DrillType.transition,
        inputMode: InputMode.rawDataEntry,
        metricSchemaId: 'raw_carry_distance',
        origin: DrillOrigin.custom,
        subskillMapping: const Value('["putting_direction_control"]'),
        anchors: const Value(
            '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
        requiredSetCount: const Value(1),
      ));

      final drill = await (db.select(db.drills)
            ..where((t) => t.drillId.equals('drill-custom')))
          .getSingle();
      expect(drill.origin, DrillOrigin.custom);
    });
  });

  // ---------------------------------------------------------------------------
  // 7D: Volume chart legend (pure logic)
  // ---------------------------------------------------------------------------

  group('7D: Volume chart legend', () {
    test('SkillArea enum has exactly 7 values for legend', () {
      expect(SkillArea.values.length, 7);
    });

    test('all SkillArea values have non-empty dbValue', () {
      for (final area in SkillArea.values) {
        expect(area.dbValue, isNotEmpty);
      }
    });
  });
}
