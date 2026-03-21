import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

import '../../fixtures/scoring_fixtures.dart';

// Phase 7B — Tests for executeFullRebuildInternal extracted method.
// Verifies that the internal method works without gate acquisition,
// that executeFullRebuild properly acquires/releases the gate, and
// that both produce equivalent results.

void main() {
  // Suppress Drift warning for multiple DB instances (test 2 intentionally
  // creates a separate in-memory DB for gate isolation).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late EventLogRepository eventLogRepo;
  late RebuildGuard rebuildGuard;
  late SyncWriteGate syncWriteGate;
  late ReflowInstrumentation instrumentation;
  late ReflowEngine engine;

  const userId = 'test-user-internal';

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

  Future<void> seedMultipleSubskillSessions(AppDatabase targetDb) async {
    await seedPhantomDrills(targetDb);
    final pbId =
        await seedPracticeBlock(targetDb, userId, practiceBlockId: 'pb-int');

    // Irons Direction (system drill)
    await seedSessionWithInstances(targetDb,
        userId: userId,
        drillId: 'a0000002-0000-4000-8000-000000000002',
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-irons-dir',
        completionTimestamp: DateTime(2026, 3, 1, 10, 0));

    // Irons Distance (system drill)
    await seedSessionWithInstances(targetDb,
        userId: userId,
        drillId: 'a0000003-0000-4000-8000-000000000001',
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-irons-dist',
        completionTimestamp: DateTime(2026, 3, 1, 11, 0));

    // Driving Direction (system drill)
    await seedSessionWithInstances(targetDb,
        userId: userId,
        drillId: 'a0000002-0000-4000-8000-000000000001',
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-driving-dir',
        completionTimestamp: DateTime(2026, 3, 1, 12, 0));

    // Putting Direction (system drill)
    await seedSessionWithInstances(targetDb,
        userId: userId,
        drillId: 'a0000002-0000-4000-8000-000000000005',
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-putting-dir',
        completionTimestamp: DateTime(2026, 3, 1, 13, 0));
  }

  group('executeFullRebuildInternal — Phase 7B', () {
    test('executeFullRebuildInternal produces valid result', () async {
      await seedMultipleSubskillSessions(db);

      final result = await engine.executeFullRebuildInternal(userId);

      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, greaterThan(0));
      // All 19 subskills should be rebuilt.
      expect(result.subskillsRebuilt, 19);

      // Verify materialised data was written.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(windows, isNotEmpty);

      final subScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      expect(subScores, isNotEmpty);

      final areaScores =
          await scoringRepo.watchSkillAreaScoresByUser(userId).first;
      expect(areaScores, isNotEmpty);

      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
      expect(overall!.overallScore, greaterThan(0));
    });

    test('executeFullRebuildInternal does NOT acquire gate', () async {
      // Use a separate gate for the engine so we can hold the "main" gate
      // without blocking the EventLogRepository's awaitGateRelease call.
      // The engine's syncWriteGate is the one checked for acquireExclusive;
      // the EventLogRepository uses its own gate instance.
      final engineGate = SyncWriteGate();
      final eventLogGate = SyncWriteGate();
      final localDb = AppDatabase.forTesting(NativeDatabase.memory());
      final localScoringRepo = ScoringRepository(localDb);
      final localRebuildGuard = RebuildGuard();
      final localEventLogRepo = EventLogRepository(localDb, eventLogGate);
      final localInstrumentation = ReflowInstrumentation();
      final localEngine = ReflowEngine(
        scoringRepository: localScoringRepo,
        eventLogRepository: localEventLogRepo,
        rebuildGuard: localRebuildGuard,
        syncWriteGate: engineGate,
        database: localDb,
        instrumentation: localInstrumentation,
      );

      await seedMultipleSubskillSessions(localDb);

      // Acquire the engine's gate to simulate a caller holding it.
      final acquired = engineGate.acquireExclusive();
      expect(acquired, isTrue);
      expect(engineGate.isHeld, isTrue);

      // If executeFullRebuildInternal tried to call acquireExclusive on
      // the engine gate, it would fail (returns false since already held).
      // The method should complete successfully because it does not touch
      // the gate at all.
      final result = await localEngine.executeFullRebuildInternal(userId);
      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, 19);

      // Gate should still be held by us (not released by the internal method).
      expect(engineGate.isHeld, isTrue);

      // Clean up.
      engineGate.release();
      localRebuildGuard.dispose();
      engineGate.dispose();
      eventLogGate.dispose();
      await localDb.close();
    });

    test('executeFullRebuild acquires and releases gate', () async {
      await seedMultipleSubskillSessions(db);

      // Gate should not be held before the call.
      expect(syncWriteGate.isHeld, isFalse);

      final result = await engine.executeFullRebuild(userId);
      expect(result.success, isTrue);

      // After executeFullRebuild completes, the gate must be released.
      expect(syncWriteGate.isHeld, isFalse);

      // Verify we can acquire the gate again (proves it was properly released).
      final acquired = syncWriteGate.acquireExclusive();
      expect(acquired, isTrue);
      syncWriteGate.release();
    });

    test('executeFullRebuildInternal matches executeFullRebuild results',
        () async {
      await seedMultipleSubskillSessions(db);

      // Run executeFullRebuildInternal first.
      final internalResult =
          await engine.executeFullRebuildInternal(userId);

      final internalOverall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      final internalSubScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;

      // Run executeFullRebuild on the same DB (it truncates and rebuilds,
      // so running sequentially on the same data is valid).
      final fullResult = await engine.executeFullRebuild(userId);

      final fullOverall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      final fullSubScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;

      // Both should rebuild the same number of subskills.
      expect(internalResult.subskillsRebuilt, fullResult.subskillsRebuilt);

      // Both should produce the same overall score.
      expect(fullOverall!.overallScore, internalOverall!.overallScore);

      // Both should produce the same subskill scores.
      for (final internalScore in internalSubScores) {
        final matching = fullSubScores
            .where((s) => s.subskill == internalScore.subskill)
            .firstOrNull;
        expect(matching, isNotNull,
            reason:
                'Subskill ${internalScore.subskill} should exist in both');
        expect(matching!.subskillPoints, internalScore.subskillPoints,
            reason:
                'SubskillPoints for ${internalScore.subskill} should match');
        expect(matching.weightedAverage, internalScore.weightedAverage,
            reason:
                'WeightedAverage for ${internalScore.subskill} should match');
      }
    });

    test('existing full rebuild tests still pass (regression)', () async {
      await seedMultipleSubskillSessions(db);

      // Verify executeFullRebuild still works end-to-end after the
      // internal method extraction.
      final result = await engine.executeFullRebuild(userId);
      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, 19);

      // Verify all materialised tables were populated.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(windows, isNotEmpty);

      final subScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      expect(subScores, isNotEmpty);

      final areaScores =
          await scoringRepo.watchSkillAreaScoresByUser(userId).first;
      expect(areaScores, isNotEmpty);

      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
      expect(overall!.overallScore, greaterThan(0));

      // Verify the gate is released after completion.
      expect(syncWriteGate.isHeld, isFalse);
    });
  });
}
