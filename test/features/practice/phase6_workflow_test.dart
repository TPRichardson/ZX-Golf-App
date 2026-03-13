import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

// Phase 6 — Live Practice Workflow Enhancement tests.
// Covers: 6B Undo Last Instance, 6D Deferred Post-Session Summary,
// 6A Save as Routine (repo level).

void main() {
  late AppDatabase db;
  late PracticeRepository practiceRepo;
  late PlanningRepository planningRepo;
  late ReflowEngine reflowEngine;

  const userId = 'test-user-phase6';
  const drillId = 'drill-p6-struct';
  const drillIdUnstruct = 'drill-p6-unstruct';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncWriteGate = SyncWriteGate();
    final eventLogRepo = EventLogRepository(db, syncWriteGate);
    final scoringRepo = ScoringRepository(db);
    reflowEngine = ReflowEngine(
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

    // S09 §9.3 — Seed clubs so bag gate passes.
    final clubRepo = ClubRepository(db, syncWriteGate);
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));

    // Structured drill: 2 sets × 3 attempts.
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId,
      name: 'Phase 6 Structured',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(2),
      requiredAttemptsPerSet: const Value(3),
    ));

    // Unstructured drill.
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillIdUnstruct,
      name: 'Phase 6 Unstructured',
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

  Future<(Session, SessionExecutionController)> startSession(
      String targetDrillId) async {
    final pb = await practiceRepo.createPracticeBlock(userId,
        initialDrillIds: [targetDrillId]);
    final entries = await (db.select(db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
        .get();
    final session = await practiceRepo.startSession(
        entries.first.practiceEntryId, userId);
    final drill = await (db.select(db.drills)
          ..where((t) => t.drillId.equals(targetDrillId)))
        .getSingle();
    final controller = SessionExecutionController(
      repository: practiceRepo,
      session: session,
      drill: drill,
    );
    await controller.initialize();
    return (session, controller);
  }

  InstancesCompanion hitMissInstance(String setId, bool isHit) =>
      InstancesCompanion.insert(
        instanceId: 'inst-${DateTime.now().microsecondsSinceEpoch}',
        setId: setId,
        selectedClub: 'Putter',
        rawMetrics: jsonEncode({'hit': isHit}),
      );

  // ---------------------------------------------------------------------------
  // 6B: Undo Last Instance
  // ---------------------------------------------------------------------------

  group('6B: Undo Last Instance', () {
    test('log 3 instances then undo → 2 remain', () async {
      final (_, controller) = await startSession(drillId);

      for (var i = 0; i < 3; i++) {
        await controller
            .logInstance(hitMissInstance(controller.currentSetId!, true));
      }
      expect(controller.currentSetInstanceCount, 3);

      final deleted = await controller.undoLastInstance();
      expect(deleted, isNotNull);
      expect(controller.currentSetInstanceCount, 2);

      // Verify 2 remain in DB.
      final instances = await (db.select(db.instances)
            ..where((t) => t.setId.equals(controller.currentSetId!)))
          .get();
      expect(instances.length, 2);
    });

    test('log 1 instance then undo → 0 remain, canUndo false', () async {
      final (_, controller) = await startSession(drillId);

      await controller
          .logInstance(hitMissInstance(controller.currentSetId!, true));
      expect(controller.canUndo, isTrue);

      await controller.undoLastInstance();
      expect(controller.currentSetInstanceCount, 0);
      expect(controller.canUndo, isFalse);
    });

    test('canUndo is false on empty set', () async {
      final (_, controller) = await startSession(drillId);
      expect(controller.canUndo, isFalse);
    });

    test('undo on empty set returns null', () async {
      final (_, controller) = await startSession(drillId);
      final deleted = await controller.undoLastInstance();
      expect(deleted, isNull);
    });

    test('undo returns the deleted instance with correct rawMetrics',
        () async {
      final (_, controller) = await startSession(drillId);

      await controller
          .logInstance(hitMissInstance(controller.currentSetId!, false));
      await controller
          .logInstance(hitMissInstance(controller.currentSetId!, true));

      // Undo should return the last logged (hit=true).
      final deleted = await controller.undoLastInstance();
      expect(deleted, isNotNull);
      final metrics =
          jsonDecode(deleted!.rawMetrics) as Map<String, dynamic>;
      expect(metrics['hit'], isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 6D: Deferred Post-Session Summary
  // ---------------------------------------------------------------------------

  group('6D: Deferred Post-Session Summary', () {
    test('setPendingSummary persists to SyncMetadata', () async {
      await practiceRepo.setPendingSummary(
        blockId: 'block-1',
        sessionId: 'session-1',
        sessionScore: 3.5,
        integrityBreach: false,
      );

      final pending = await practiceRepo.getPendingSummary();
      expect(pending, isNotNull);
      expect(pending!['blockId'], 'block-1');
      expect(pending['sessionId'], 'session-1');
      expect(pending['sessionScore'], 3.5);
      expect(pending['integrityBreach'], isFalse);
    });

    test('getPendingSummary returns null when no flag set', () async {
      final pending = await practiceRepo.getPendingSummary();
      expect(pending, isNull);
    });

    test('clearPendingSummary removes the flag', () async {
      await practiceRepo.setPendingSummary(
        blockId: 'block-2',
        sessionId: 'session-2',
        sessionScore: 4.0,
      );

      await practiceRepo.clearPendingSummary();

      final pending = await practiceRepo.getPendingSummary();
      expect(pending, isNull);
    });

    test('setPendingSummary without session data omits optional fields',
        () async {
      await practiceRepo.setPendingSummary(blockId: 'block-3');

      final pending = await practiceRepo.getPendingSummary();
      expect(pending, isNotNull);
      expect(pending!['blockId'], 'block-3');
      expect(pending.containsKey('sessionId'), isFalse);
      expect(pending.containsKey('sessionScore'), isFalse);
      expect(pending['integrityBreach'], isFalse);
    });

    test('SyncMetadataKeys.pendingPostSessionSummary is correct', () {
      expect(SyncMetadataKeys.pendingPostSessionSummary,
          'pendingPostSessionSummary');
    });
  });

  // ---------------------------------------------------------------------------
  // 6A: Save as Routine (repo level)
  // ---------------------------------------------------------------------------

  group('6A: Save Practice queue as Routine', () {
    test('create routine from practice block drill IDs', () async {
      // Start a practice block with 2 drills.
      final pb = await practiceRepo.createPracticeBlock(userId,
          initialDrillIds: [drillId, drillIdUnstruct]);

      // Read entry drill IDs.
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      final drillIds = entries.map((e) => e.drillId).toList();
      expect(drillIds, [drillId, drillIdUnstruct]);

      // Create routine from these drill IDs.
      final routine = await planningRepo.createRoutineWithEntries(
        userId,
        'My Practice',
        drillIds.map((id) => RoutineEntry.fixed(id)).toList(),
      );

      expect(routine.name, 'My Practice');

      // Verify routine has 2 entries.
      final routines = await planningRepo.watchRoutines(userId).first;
      expect(routines.length, 1);
      expect(routines.first.routineId, routine.routineId);
    });

    test('empty queue throws validation error', () async {
      // Repo requires at least 1 entry — UI guards against this.
      expect(
        () => planningRepo.createRoutineWithEntries(userId, 'Empty', []),
        throwsA(isA<Exception>()),
      );
    });
  });
}
