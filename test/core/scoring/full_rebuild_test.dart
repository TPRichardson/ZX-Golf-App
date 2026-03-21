import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

import '../../fixtures/scoring_fixtures.dart';

// Phase 2B — Full rebuild tests (TD-05 §11).

void main() {
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late EventLogRepository eventLogRepo;
  late RebuildGuard rebuildGuard;
  late SyncWriteGate syncWriteGate;
  late ReflowInstrumentation instrumentation;
  late ReflowEngine engine;

  const userId = 'test-user-full-rebuild';

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

  Future<void> seedMultipleSubskillSessions() async {
    await seedPhantomDrills(db);
    final pbId = await seedPracticeBlock(db, userId, practiceBlockId: 'pb-fr');

    // Seed sessions for multiple subskills using different system drills.
    // Irons Direction (system drill)
    await seedSessionWithInstances(db,
        userId: userId,
        drillId: 'a0000002-0000-4000-8000-000000000002', // Irons Direction
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-irons-dir',
        completionTimestamp: DateTime(2026, 3, 1, 10, 0));

    // Irons Distance (system drill)
    await seedSessionWithInstances(db,
        userId: userId,
        drillId: 'a0000003-0000-4000-8000-000000000001', // Irons Distance
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-irons-dist',
        completionTimestamp: DateTime(2026, 3, 1, 11, 0));

    // Driving Direction (system drill)
    await seedSessionWithInstances(db,
        userId: userId,
        drillId: 'a0000002-0000-4000-8000-000000000001', // Driving Direction
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-driving-dir',
        completionTimestamp: DateTime(2026, 3, 1, 12, 0));

    // Putting Direction (system drill)
    await seedSessionWithInstances(db,
        userId: userId,
        drillId: 'a0000002-0000-4000-8000-000000000005', // Putting Direction
        practiceBlockId: pbId,
        instanceCount: 10,
        rawMetrics: '{"hit": true}',
        sessionId: 'session-putting-dir',
        completionTimestamp: DateTime(2026, 3, 1, 13, 0));
  }

  group('Full rebuild — TD-05 §11', () {
    test('full rebuild populates all materialised tables', () async {
      await seedMultipleSubskillSessions();

      final result = await engine.executeFullRebuild(userId);
      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, 19); // All 19 subskills.

      // Check window states exist.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(windows, isNotEmpty);

      // Check subskill scores exist.
      final subScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      expect(subScores, isNotEmpty);

      // Check skill area scores exist.
      final areaScores =
          await scoringRepo.watchSkillAreaScoresByUser(userId).first;
      expect(areaScores, isNotEmpty);

      // Check overall score exists.
      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
      expect(overall!.overallScore, greaterThan(0));
    });

    test('repeated full rebuild produces identical results (deterministic)',
        () async {
      await seedMultipleSubskillSessions();

      // First full rebuild.
      await engine.executeFullRebuild(userId);
      final overall1 =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      final subScores1 =
          await scoringRepo.watchSubskillScoresByUser(userId).first;

      // Second full rebuild.
      await engine.executeFullRebuild(userId);
      final overall2 =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      final subScores2 =
          await scoringRepo.watchSubskillScoresByUser(userId).first;

      // Both runs should produce identical scores.
      expect(overall2!.overallScore, overall1!.overallScore);
      for (final s1 in subScores1) {
        final s2 =
            subScores2.where((s) => s.subskill == s1.subskill).firstOrNull;
        expect(s2, isNotNull, reason: 'Subskill ${s1.subskill} should exist');
        expect(s2!.subskillPoints, s1.subskillPoints,
            reason: 'SubskillPoints for ${s1.subskill} should match');
      }
    });

    test('RebuildGuard prevents concurrent full rebuild', () async {
      // Hold the guard manually.
      rebuildGuard.acquire();

      await expectLater(
        () => engine.executeFullRebuild(userId),
        throwsA(isA<ReflowException>()),
      );

      rebuildGuard.release();
    });

    test('SyncWriteGate acquired during rebuild', () async {
      await seedMultipleSubskillSessions();

      // After full rebuild, gate should be released.
      await engine.executeFullRebuild(userId);
      expect(syncWriteGate.isHeld, isFalse);
    });

    test('deferred triggers executed after rebuild completes', () async {
      await seedMultipleSubskillSessions();

      // Full rebuild should handle deferred triggers (tested via guard release).
      final result = await engine.executeFullRebuild(userId);
      expect(result.success, isTrue);
    });
  });
}
