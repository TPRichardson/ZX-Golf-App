import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

import '../../fixtures/scoring_fixtures.dart';

// Phase 2B — Session close pipeline tests (TD-03 §4.4).

void main() {
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late EventLogRepository eventLogRepo;
  late RebuildGuard rebuildGuard;
  late SyncWriteGate syncWriteGate;
  late ReflowInstrumentation instrumentation;
  late ReflowEngine engine;

  const userId = 'test-user-close';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scoringRepo = ScoringRepository(db);
    rebuildGuard = RebuildGuard();
    syncWriteGate = SyncWriteGate();
    eventLogRepo = EventLogRepository(db, syncWriteGate);
    instrumentation = ReflowInstrumentation();
    engine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: rebuildGuard,
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: instrumentation,
    );
  });

  tearDown(() async {
    rebuildGuard.dispose();
    syncWriteGate.dispose();
    await db.close();
  });

  group('Session close pipeline — TD-03 §4.4', () {
    test('grid session close: scores session and triggers reflow', () async {
      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-grid');

      // Use system drill: Irons Direction (grid 1x3).
      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000002-0000-4000-8000-000000000002',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-grid',
          status: SessionStatus.active);

      final result = await engine.closeSession('session-grid', userId);
      expect(result.sessionScore, greaterThan(0));
      expect(result.integrityBreach, isFalse);
      expect(result.subskillIds, {'irons_direction_control'});
      expect(result.drillType, 'Transition');
      expect(result.isDualMapped, isFalse);

      // Session should now be Closed.
      final session = await scoringRepo.getSessionById('session-grid');
      expect(session!.status, SessionStatus.closed);
      expect(session.completionTimestamp, isNotNull);

      // Materialised state should be populated.
      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
    });

    test('binary session close: hit/miss scoring works', () async {
      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-binary');

      // Use system drill: Irons Shape (binary hit/miss).
      final hitMissList = <String>[];
      for (var i = 0; i < 10; i++) {
        hitMissList
            .add(i < 7 ? '{"hit": true}' : '{"hit": false}');
      }

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000005-0000-4000-8000-000000000001',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: hitMissList,
          sessionId: 'session-binary',
          status: SessionStatus.active);

      final result = await engine.closeSession('session-binary', userId);
      expect(result.sessionScore, greaterThan(0));
      expect(result.subskillIds, {'irons_shape_control'});
    });

    test('raw-data session close: per-instance scoring', () async {
      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-raw');

      // Use system drill: Driving Carry (raw data entry, LinearInterpolation).
      final rawMetrics = List.generate(
          10, (i) => '{"value": ${230 + i * 3}}'); // 230, 233, ..., 257

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000004-0000-4000-8000-000000000001',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: rawMetrics,
          sessionId: 'session-raw',
          status: SessionStatus.active);

      final result = await engine.closeSession('session-raw', userId);
      expect(result.sessionScore, greaterThan(0));
      expect(result.subskillIds, {'driving_distance_maximum'});
    });

    test('raw-data session with integrity breach flags session', () async {
      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-breach');

      // Driving Carry: hardMinInput=0, hardMaxInput=500.
      // Send values outside bounds.
      final rawMetrics = List.generate(10, (i) => '{"value": 600}');

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000004-0000-4000-8000-000000000001',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: rawMetrics,
          sessionId: 'session-breach',
          status: SessionStatus.active);

      final result = await engine.closeSession('session-breach', userId);
      expect(result.integrityBreach, isTrue);

      // Session should have integrity flag set.
      final session = await scoringRepo.getSessionById('session-breach');
      expect(session!.integrityFlag, isTrue);
    });

    test('technique block produces no window entry or reflow', () async {
      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-tech');

      // Use system drill: Irons Technique (technique block).
      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000001-0000-4000-8000-000000000002',
          practiceBlockId: pbId,
          instanceCount: 3,
          rawMetrics: '{"value": 300}',
          sessionId: 'session-tech',
          status: SessionStatus.active);

      final result = await engine.closeSession('session-tech', userId);
      expect(result.sessionScore, 0.0);
      expect(result.drillType, 'TechniqueBlock');

      // No materialised state should be created from this alone.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(windows, isEmpty);
    });

    test('session close emits SessionCompletion event log', () async {
      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-log');

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000002-0000-4000-8000-000000000002',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-log',
          status: SessionStatus.active);

      await engine.closeSession('session-log', userId);

      final logs = await eventLogRepo.watchByUser(userId).first;
      final completionLogs =
          logs.where((l) => l.eventTypeId == 'SessionCompletion').toList();
      expect(completionLogs, isNotEmpty);
    });

    // Fix 8 — Session close emits SessionCloseComplete, not ReflowComplete.
    test('session close emits SessionCloseComplete, not ReflowComplete',
        () async {
      final pbId = await seedPracticeBlock(db, userId,
          practiceBlockId: 'pb-fix8');

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000002-0000-4000-8000-000000000002',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-fix8',
          status: SessionStatus.active);

      await engine.closeSession('session-fix8', userId);

      final logs = await eventLogRepo.watchByUser(userId).first;

      // Should have SessionCloseComplete (from the pipeline).
      final closeCompleteLogs = logs
          .where((l) => l.eventTypeId == 'SessionCloseComplete')
          .toList();
      expect(closeCompleteLogs, isNotEmpty,
          reason: 'Session close pipeline should emit SessionCloseComplete');

      // Should NOT have ReflowComplete from session close.
      final reflowCompleteLogs = logs
          .where((l) => l.eventTypeId == 'ReflowComplete')
          .toList();
      expect(reflowCompleteLogs, isEmpty,
          reason: 'Session close should not emit ReflowComplete');
    });

    test('session close pipeline still updates materialised tables', () async {
      final pbId = await seedPracticeBlock(db, userId,
          practiceBlockId: 'pb-fix8-mat');

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000002-0000-4000-8000-000000000002',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-fix8-mat',
          status: SessionStatus.active);

      // No materialised state before close.
      final windowsBefore =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(windowsBefore, isEmpty);

      await engine.closeSession('session-fix8-mat', userId);

      // Materialised state should exist after close.
      final windowsAfter =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(windowsAfter, isNotEmpty,
          reason: 'Session close pipeline should update materialised tables');

      // Overall score should be computed.
      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
    });

    test('session close pipeline clears rebuildNeeded flag', () async {
      final pbId = await seedPracticeBlock(db, userId,
          practiceBlockId: 'pb-fix8-rebuild');

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'a0000002-0000-4000-8000-000000000002',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-fix8-rebuild',
          status: SessionStatus.active);

      await engine.closeSession('session-fix8-rebuild', userId);

      // rebuildNeeded should be false after successful pipeline.
      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals('rebuildNeeded')))
          .getSingleOrNull();
      // Either null (never set) or 'false'.
      expect(row == null || row.value == 'false', isTrue,
          reason: 'rebuildNeeded should be cleared after session close');
    });

    test('dual-mapped session close contributes to 2 windows at 0.5 occupancy',
        () async {
      // Create a dual-mapped user drill.
      await seedTestDrill(db,
          drillId: 'drill-dual-close',
          skillArea: SkillArea.irons,
          drillType: DrillType.transition,
          metricSchemaId: 'grid_1x3_direction',
          subskillMapping: [
            'irons_distance_control',
            'irons_direction_control'
          ],
          anchors: {
            'irons_distance_control': {'Min': 30, 'Scratch': 70, 'Pro': 90},
            'irons_direction_control': {'Min': 30, 'Scratch': 70, 'Pro': 90},
          });

      final pbId =
          await seedPracticeBlock(db, userId, practiceBlockId: 'pb-dual');

      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'drill-dual-close',
          practiceBlockId: pbId,
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-dual',
          status: SessionStatus.active);

      final result = await engine.closeSession('session-dual', userId);
      expect(result.isDualMapped, isTrue);
      expect(result.subskillIds, hasLength(2));

      // Check that window entries have 0.5 occupancy.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      for (final subskill in [
        'irons_distance_control',
        'irons_direction_control'
      ]) {
        final matching = windows.where((w) =>
            w.subskill == subskill &&
            w.practiceType == DrillType.transition);
        expect(matching, isNotEmpty,
            reason: 'Window for $subskill should exist');
        // The total occupancy should reflect the dual mapping.
        expect(matching.first.totalOccupancy, 0.5,
            reason: 'Dual-mapped session contributes 0.5 occupancy');
      }
    });
  });
}
