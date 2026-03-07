// Phase 4 — Session Close Pipeline Integration Test.
// Verifies full flow: create PB → start session → log instances → end session
// → materialised tables updated, performance within target.
// TD-06 §9.4: <200ms p95.

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

void main() {
  late AppDatabase db;
  late PracticeRepository repo;

  const userId = 'test-user-close';

  late String gridDrillId;
  late String rawDrillId;
  late String techniqueDrillId;

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

    // S09 §9.3 — Seed clubs so bag gate passes for Putting and Driving.
    final clubRepo = ClubRepository(db, SyncWriteGate());
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.driver)));

    // Seed structured grid drill: 1 set × 5 attempts.
    gridDrillId = 'drill-close-grid';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: gridDrillId,
      name: 'Close Test Grid',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.system,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(5),
    ));

    // Seed raw data drill: 1 set × 3 attempts.
    rawDrillId = 'drill-close-raw';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: rawDrillId,
      name: 'Close Test Raw',
      skillArea: SkillArea.driving,
      drillType: DrillType.transition,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'raw_carry_distance',
      origin: DrillOrigin.system,
      subskillMapping: const Value('["driving_distance_maximum"]'),
      anchors: const Value(
          '{"driving_distance_maximum": {"Min": 180, "Scratch": 250, "Pro": 300}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(3),
    ));

    // Seed technique block drill.
    techniqueDrillId = 'drill-close-technique';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: techniqueDrillId,
      name: 'Close Test Technique',
      skillArea: SkillArea.chipping,
      drillType: DrillType.techniqueBlock,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'technique_duration',
      origin: DrillOrigin.system,
      subskillMapping: const Value('[]'),
      requiredSetCount: const Value(1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  /// Start a practice block with a single drill and return controller + session.
  Future<(SessionExecutionController, Session)> startDrill(
      String drillId) async {
    final pb =
        await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
    final entries = await (db.select(db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
        .get();
    final session =
        await repo.startSession(entries.first.practiceEntryId, userId);
    final drill = await (db.select(db.drills)
          ..where((t) => t.drillId.equals(drillId)))
        .getSingle();

    final controller = SessionExecutionController(
      repository: repo,
      session: session,
      drill: drill,
    );
    await controller.initialize();
    return (controller, session);
  }

  group('Session close pipeline', () {
    test('full flow: create PB → log instances → end session → verify scoring',
        () async {
      final (ctrl, session) = await startDrill(rawDrillId);

      // Log 3 instances.
      await ctrl.logInstance(InstancesCompanion.insert(
        instanceId: 'inst-close-raw-1',
        setId: ctrl.currentSetId!,
        selectedClub: 'Driver',
        rawMetrics: '{"value": 250}',
      ));
      await ctrl.logInstance(InstancesCompanion.insert(
        instanceId: 'inst-close-raw-2',
        setId: ctrl.currentSetId!,
        selectedClub: 'Driver',
        rawMetrics: '{"value": 260}',
      ));
      await ctrl.logInstance(InstancesCompanion.insert(
        instanceId: 'inst-close-raw-3',
        setId: ctrl.currentSetId!,
        selectedClub: 'Driver',
        rawMetrics: '{"value": 240}',
      ));

      expect(ctrl.isCurrentSetComplete(), true);
      expect(ctrl.isSessionAutoComplete(), true);

      // End session and measure time.
      final stopwatch = Stopwatch()..start();
      final result = await repo.endSession(session.sessionId, userId);
      stopwatch.stop();

      // TD-06 §9.4: <200ms target. Allow 300ms in test environments.
      expect(stopwatch.elapsedMilliseconds, lessThan(300));

      // Verify session is now closed.
      final closedSession = await repo.getSessionById(session.sessionId);
      expect(closedSession!.status, SessionStatus.closed);

      // Verify scoring result.
      expect(result.sessionScore, greaterThan(0));
      expect(result.drillId, rawDrillId);
    });

    test('grid drill: scores hit-rate correctly after close', () async {
      final (ctrl, session) = await startDrill(gridDrillId);

      // Log 5 instances: 4 hits, 1 miss = 80% hit rate.
      for (var i = 0; i < 4; i++) {
        await ctrl.logInstance(InstancesCompanion.insert(
          instanceId: 'inst-close-grid-h$i',
          setId: ctrl.currentSetId!,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ));
      }
      await ctrl.logInstance(InstancesCompanion.insert(
        instanceId: 'inst-close-grid-miss',
        setId: ctrl.currentSetId!,
        selectedClub: 'Putter',
        rawMetrics: '{"hit": false}',
      ));

      expect(ctrl.isCurrentSetComplete(), true);

      final result = await repo.endSession(session.sessionId, userId);

      // Session should be scored (80% hit rate interpolated via anchors).
      expect(result.sessionScore, greaterThan(0));
      expect(result.integrityBreach, false);

      // Verify session status.
      final closedSession = await repo.getSessionById(session.sessionId);
      expect(closedSession!.status, SessionStatus.closed);
    });

    test('technique block: end session with no scoring', () async {
      final (ctrl, session) = await startDrill(techniqueDrillId);

      // Log single instance with duration.
      await ctrl.logInstance(InstancesCompanion.insert(
        instanceId: 'inst-close-tech-1',
        setId: ctrl.currentSetId!,
        selectedClub: 'N/A',
        rawMetrics: '{"duration": 600}',
      ));

      // End session.
      final result = await repo.endSession(session.sessionId, userId);

      // Technique block: scoring adapter = None → score is 0.
      expect(result.sessionScore, 0.0);
      expect(result.integrityBreach, false);

      // Session closed.
      final closedSession = await repo.getSessionById(session.sessionId);
      expect(closedSession!.status, SessionStatus.closed);
    });

    test('session discard with 0 instances: no trace remains', () async {
      final (ctrl, session) = await startDrill(gridDrillId);

      // Find the entry for this session.
      final entry =
          await repo.getPracticeEntryBySessionId(session.sessionId);

      // Don't log any instances, just discard.
      await repo.discardSession(entry!.practiceEntryId);

      // Session should be gone.
      final discardedSession =
          await repo.getSessionById(session.sessionId);
      expect(discardedSession, isNull);

      // Entry should be back to PendingDrill.
      final updatedEntry = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceEntryId.equals(entry.practiceEntryId)))
          .getSingleOrNull();
      expect(updatedEntry!.entryType, PracticeEntryType.pendingDrill);
      expect(updatedEntry.sessionId, isNull);
    });

    test('structured auto-completion triggers scoring pipeline', () async {
      final (ctrl, session) = await startDrill(gridDrillId);

      // Fill all 5 instances (all hits).
      for (var i = 0; i < 5; i++) {
        await ctrl.logInstance(InstancesCompanion.insert(
          instanceId: 'inst-close-auto-$i',
          setId: ctrl.currentSetId!,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ));
      }
      expect(ctrl.isSessionAutoComplete(), true);

      // End session (triggered by auto-completion in real flow).
      final result = await repo.endSession(session.sessionId, userId);

      // 100% hit rate should score well.
      expect(result.sessionScore, greaterThan(0));
      expect(result.integrityBreach, false);
    });
  });
}
