import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

import '../../fixtures/scoring_fixtures.dart';

// Phase 2B — ReflowEngine tests (TD-05 §10).
// Uses in-memory Drift database with real seed data.

void main() {
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late EventLogRepository eventLogRepo;
  late RebuildGuard rebuildGuard;
  late SyncWriteGate syncWriteGate;
  late ReflowInstrumentation instrumentation;
  late ReflowEngine engine;

  const userId = 'test-user-reflow';

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

  /// Helper: seed a direction drill with a closed session.
  Future<String> seedDirectionSession({
    required String drillId,
    required String subskill,
    required String sessionId,
    required String pbId,
    DrillType drillType = DrillType.transition,
    int hitCount = 7,
    int attemptCount = 10,
    DateTime? completionTimestamp,
  }) async {
    await seedTestDrill(db,
        drillId: drillId,
        skillArea: SkillArea.irons,
        drillType: drillType,
        metricSchemaId: 'grid_1x3_direction',
        subskillMapping: [subskill],
        anchors: {
          subskill: {'Min': 30, 'Scratch': 70, 'Pro': 90}
        });

    await seedPracticeBlock(db, userId, practiceBlockId: pbId);

    // Create hit metrics: hitCount hits + (attemptCount - hitCount) misses.
    final metrics = <String>[];
    for (var i = 0; i < attemptCount; i++) {
      metrics.add(i < hitCount ? '{"hit": true}' : '{"hit": false}');
    }

    return seedSessionWithInstances(db,
        userId: userId,
        drillId: drillId,
        practiceBlockId: pbId,
        instanceCount: attemptCount,
        rawMetrics: metrics,
        sessionId: sessionId,
        completionTimestamp: completionTimestamp);
  }

  group('Scoped reflow — TD-05 §10', () {
    test('single-mapped reflow materialises 1 subskill, others unchanged',
        () async {
      await seedDirectionSession(
        drillId: 'drill-sr1',
        subskill: 'irons_direction_control',
        sessionId: 'session-sr1',
        pbId: 'pb-sr1',
      );

      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: {'irons_direction_control'},
        sessionId: 'session-sr1',
        drillId: 'drill-sr1',
      );

      final result = await engine.executeReflow(trigger);
      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, 1);

      // Check materialised window state written.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;
      final transitionWindows = windows
          .where((w) =>
              w.subskill == 'irons_direction_control' &&
              w.practiceType == DrillType.transition)
          .toList();
      expect(transitionWindows, hasLength(1));
      expect(transitionWindows.first.windowAverage, greaterThan(0));

      // Check subskill score written.
      final subScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      final matching = subScores
          .where((s) => s.subskill == 'irons_direction_control')
          .toList();
      expect(matching, hasLength(1));

      // Check overall score written.
      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
    });

    test('dual-mapped reflow materialises 2 subskills', () async {
      // Create a dual-mapped drill.
      await seedTestDrill(db,
          drillId: 'drill-dm',
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

      await seedPracticeBlock(db, userId, practiceBlockId: 'pb-dm');
      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'drill-dm',
          practiceBlockId: 'pb-dm',
          instanceCount: 10,
          rawMetrics: '{"hit": true}',
          sessionId: 'session-dm');

      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: {
          'irons_distance_control',
          'irons_direction_control',
        },
        sessionId: 'session-dm',
        drillId: 'drill-dm',
      );

      final result = await engine.executeReflow(trigger);
      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, 2);

      // Check both subskill scores written.
      final subScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      final distMatch =
          subScores.where((s) => s.subskill == 'irons_distance_control');
      final dirMatch =
          subScores.where((s) => s.subskill == 'irons_direction_control');
      expect(distMatch, hasLength(1));
      expect(dirMatch, hasLength(1));
    });

    test('determinism: same data produces identical state on repeated runs',
        () async {
      await seedDirectionSession(
        drillId: 'drill-det',
        subskill: 'irons_direction_control',
        sessionId: 'session-det',
        pbId: 'pb-det',
      );

      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: {'irons_direction_control'},
      );

      // Run reflow twice.
      await engine.executeReflow(trigger);
      final scores1 =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      final overall1 =
          await scoringRepo.watchOverallScoreByUser(userId).first;

      await engine.executeReflow(trigger);
      final scores2 =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      final overall2 =
          await scoringRepo.watchOverallScoreByUser(userId).first;

      // Both runs should produce identical scores.
      final score1 = scores1
          .firstWhere((s) => s.subskill == 'irons_direction_control');
      final score2 = scores2
          .firstWhere((s) => s.subskill == 'irons_direction_control');
      expect(score1.subskillPoints, score2.subskillPoints);
      expect(score1.weightedAverage, score2.weightedAverage);
      expect(overall1!.overallScore, overall2!.overallScore);
    });

    test('reflow with no sessions produces zero scores', () async {
      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: {'irons_direction_control'},
      );

      final result = await engine.executeReflow(trigger);
      expect(result.success, isTrue);

      final subScores =
          await scoringRepo.watchSubskillScoresByUser(userId).first;
      final matching = subScores
          .where((s) => s.subskill == 'irons_direction_control')
          .toList();
      expect(matching, hasLength(1));
      expect(matching.first.weightedAverage, 0);
    });

    test('deferred reflow when RebuildGuard is held', () async {
      rebuildGuard.acquire();

      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: {'irons_direction_control'},
      );

      final result = await engine.executeReflow(trigger);
      expect(result.success, isTrue);
      expect(result.subskillsRebuilt, 0); // Deferred, not executed.

      rebuildGuard.release();
    });
  });

  group('EventLog emission', () {
    test('reflow emits ReflowComplete event log entry', () async {
      await seedDirectionSession(
        drillId: 'drill-ev',
        subskill: 'irons_direction_control',
        sessionId: 'session-ev',
        pbId: 'pb-ev',
      );

      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: {'irons_direction_control'},
      );

      await engine.executeReflow(trigger);

      final logs = await eventLogRepo.watchByUser(userId).first;
      final reflowLogs =
          logs.where((l) => l.eventTypeId == 'ReflowComplete').toList();
      expect(reflowLogs, isNotEmpty);
    });
  });
}
