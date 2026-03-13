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
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

// Phase 4 — SessionExecutionController tests.
// S13 §13.6–13.9 — Structured completion, set advancement, real-time scoring.

void main() {
  late AppDatabase db;
  late PracticeRepository repo;

  const userId = 'test-user-exec';

  // Drill IDs.
  late String structuredDrillId;
  late String unstructuredDrillId;
  late String techniqueDrillId;
  late String rawDataDrillId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final eventLogRepo = EventLogRepository(db, SyncWriteGate());
    final scoringRepo = ScoringRepository(db);
    final reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: SyncWriteGate(),
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    repo = PracticeRepository(db, reflowEngine, eventLogRepo, SyncWriteGate());

    // S09 §9.3 — Seed clubs so bag gate passes for Putting, Irons, Driving.
    final clubRepo = ClubRepository(db, SyncWriteGate());
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.i7)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.driver)));

    // Seed structured drill: 2 sets × 3 attempts.
    structuredDrillId = 'drill-structured';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: structuredDrillId,
      name: 'Structured Grid',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(2),
      requiredAttemptsPerSet: const Value(3),
    ));

    // Seed unstructured drill: 1 set, no requiredAttemptsPerSet.
    unstructuredDrillId = 'drill-unstructured';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: unstructuredDrillId,
      name: 'Unstructured Grid',
      skillArea: SkillArea.irons,
      drillType: DrillType.transition,
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["irons_direction_control"]'),
      anchors: const Value(
          '{"irons_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
      requiredSetCount: const Value(1),
    ));

    // Seed technique block drill.
    techniqueDrillId = 'drill-technique';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: techniqueDrillId,
      name: 'Technique Block',
      skillArea: SkillArea.chipping,
      drillType: DrillType.techniqueBlock,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'technique_duration',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('[]'),
      requiredSetCount: const Value(1),
    ));

    // Seed raw data drill for real-time scoring test.
    rawDataDrillId = 'drill-raw-data';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: rawDataDrillId,
      name: 'Carry Distance',
      skillArea: SkillArea.driving,
      drillType: DrillType.transition,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'raw_carry_distance',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["driving_distance_maximum"]'),
      anchors: const Value(
          '{"driving_distance_maximum": {"Min": 180, "Scratch": 250, "Pro": 300}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(5),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<SessionExecutionController> startController(
      String drillId) async {
    final pb = await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
    final entries = await (db.select(db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
        .get();
    final session = await repo.startSession(entries.first.practiceEntryId, userId);
    final drill = await (db.select(db.drills)
          ..where((t) => t.drillId.equals(drillId)))
        .getSingle();

    final controller = SessionExecutionController(
      repository: repo,
      session: session,
      drill: drill,
    );
    await controller.initialize();
    return controller;
  }

  InstancesCompanion gridInstance(String setId, bool hit) =>
      InstancesCompanion.insert(
        instanceId: 'inst-${DateTime.now().microsecondsSinceEpoch}',
        setId: setId,
        selectedClub: 'Putter',
        rawMetrics: '{"hit": $hit}',
      );

  InstancesCompanion rawInstance(String setId, double value) =>
      InstancesCompanion.insert(
        instanceId: 'inst-${DateTime.now().microsecondsSinceEpoch}',
        setId: setId,
        selectedClub: 'Driver',
        rawMetrics: '{"value": $value}',
      );

  group('Structured completion', () {
    test('auto-completes after final instance of final set', () async {
      final ctrl = await startController(structuredDrillId);
      expect(ctrl.isStructured, true);
      expect(ctrl.requiredSetCount, 2);
      expect(ctrl.requiredAttemptsPerSet, 3);

      // Set 1: log 3 instances.
      for (var i = 0; i < 3; i++) {
        await ctrl.logInstance(gridInstance(ctrl.currentSetId!, true));
      }
      expect(ctrl.isCurrentSetComplete(), true);
      expect(ctrl.isSessionAutoComplete(), false); // Need 2 sets.

      // Advance to set 2.
      await ctrl.advanceSet();
      expect(ctrl.currentSetIndex, 1);
      expect(ctrl.currentSetInstanceCount, 0);

      // Set 2: log 3 instances.
      for (var i = 0; i < 3; i++) {
        await ctrl.logInstance(gridInstance(ctrl.currentSetId!, true));
      }
      expect(ctrl.isCurrentSetComplete(), true);
      expect(ctrl.isSessionAutoComplete(), true);
    });

    test('set advances when instance count reaches requiredAttemptsPerSet',
        () async {
      final ctrl = await startController(structuredDrillId);

      for (var i = 0; i < 3; i++) {
        await ctrl.logInstance(gridInstance(ctrl.currentSetId!, true));
      }
      expect(ctrl.isCurrentSetComplete(), true);
      expect(ctrl.completedSetCount, 0);

      await ctrl.advanceSet();
      expect(ctrl.completedSetCount, 1);
      expect(ctrl.currentSetInstanceCount, 0);
    });
  });

  group('Unstructured drill', () {
    test('does NOT auto-complete', () async {
      final ctrl = await startController(unstructuredDrillId);
      expect(ctrl.isStructured, false);

      // Log many instances — never auto-complete.
      for (var i = 0; i < 20; i++) {
        await ctrl.logInstance(gridInstance(ctrl.currentSetId!, true));
      }
      expect(ctrl.isCurrentSetComplete(), false);
      expect(ctrl.isSessionAutoComplete(), false);
    });
  });

  group('Technique block', () {
    test('creates single instance with duration, no scoring', () async {
      final ctrl = await startController(techniqueDrillId);
      expect(ctrl.isTechniqueBlock, true);

      final result = await ctrl.logInstance(
        InstancesCompanion.insert(
          instanceId: 'inst-tech-1',
          setId: ctrl.currentSetId!,
          selectedClub: 'N/A',
          rawMetrics: '{"duration": 1800}',
        ),
      );

      expect(result.instance, isNotNull);
      expect(result.realtimeScore, isNull); // No scoring for technique.
    });
  });

  group('Real-time scoring', () {
    test('returns correct 0–5 value for raw data drill', () async {
      final ctrl = await startController(rawDataDrillId);

      // Score at scratch (250) should be ~3.5.
      final result = await ctrl.logInstance(
        rawInstance(ctrl.currentSetId!, 250),
      );
      expect(result.realtimeScore, isNotNull);
      expect(result.realtimeScore, closeTo(3.5, 0.01));

      // Score at min (180) should be 0.
      final result2 = await ctrl.logInstance(
        rawInstance(ctrl.currentSetId!, 180),
      );
      expect(result2.realtimeScore, closeTo(0.0, 0.01));

      // Score at pro (300) should be 5.0.
      final result3 = await ctrl.logInstance(
        rawInstance(ctrl.currentSetId!, 300),
      );
      expect(result3.realtimeScore, closeTo(5.0, 0.01));
    });
  });
}
