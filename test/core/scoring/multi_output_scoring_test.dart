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
import 'package:zx_golf_app/providers/review_providers.dart';

import '../../fixtures/scoring_fixtures.dart';

// Fix 1 — Multi-Output scoring: dual-mapped drills score each subskill
// against its own anchors independently.

void main() {
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late EventLogRepository eventLogRepo;
  late RebuildGuard rebuildGuard;
  late SyncWriteGate syncWriteGate;
  late ReflowEngine engine;

  const userId = 'test-user-multi-output';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scoringRepo = ScoringRepository(db);
    rebuildGuard = RebuildGuard();
    syncWriteGate = SyncWriteGate();
    eventLogRepo = EventLogRepository(db, syncWriteGate);
    engine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: rebuildGuard,
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
  });

  tearDown(() async {
    rebuildGuard.dispose();
    syncWriteGate.dispose();
    await db.close();
  });

  group('Fix 1: Multi-Output scoring', () {
    test(
        'dual-mapped drill with different anchors produces different subskill scores',
        () async {
      // Create a dual-mapped drill with different anchors per subskill.
      // Subskill A: Min=20, Scratch=60, Pro=80 (easy to score high on)
      // Subskill B: Min=100, Scratch=250, Pro=400 (hard to score high on with same data)
      await seedTestDrill(db,
          drillId: 'drill-multi-output',
          skillArea: SkillArea.approach,
          drillType: DrillType.transition,
          metricSchemaId: 'raw_carry_distance',
          inputMode: InputMode.rawDataEntry,
          subskillMapping: [
            'approach_direction_control',
            'approach_distance_control',
          ],
          anchors: {
            'approach_direction_control': {
              'Min': 20,
              'Scratch': 60,
              'Pro': 80,
            },
            'approach_distance_control': {
              'Min': 100,
              'Scratch': 250,
              'Pro': 400,
            },
          });

      final pbId = await seedPracticeBlock(db, userId);

      // Raw value = 50: high relative to subskill A anchors, low relative to B.
      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'drill-multi-output',
          practiceBlockId: pbId,
          instanceCount: 5,
          rawMetrics: '{"value": 50}',
          sessionId: 'session-multi-1',
          status: SessionStatus.active);

      await engine.closeSession('session-multi-1', userId);

      // Both subskill windows should exist.
      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;

      final windowA = windows
          .where((w) =>
              w.subskill == 'approach_direction_control' &&
              w.practiceType == DrillType.transition)
          .toList();
      final windowB = windows
          .where((w) =>
              w.subskill == 'approach_distance_control' &&
              w.practiceType == DrillType.transition)
          .toList();

      expect(windowA, isNotEmpty, reason: 'Window for subskill A should exist');
      expect(windowB, isNotEmpty, reason: 'Window for subskill B should exist');

      // Parse scores from window entries.
      final entriesA = parseWindowEntries(windowA.first.entries);
      final entriesB = parseWindowEntries(windowB.first.entries);

      expect(entriesA, isNotEmpty);
      expect(entriesB, isNotEmpty);

      final scoreA = entriesA.first.score;
      final scoreB = entriesB.first.score;

      // Score A should be higher than B because 50 is closer to subskill A's
      // Pro anchor (80) than to subskill B's Pro anchor (400).
      expect(scoreA, greaterThan(scoreB),
          reason:
              'Same raw data should produce different scores against different anchors');

      // Both should have 0.5 occupancy (dual-mapped).
      expect(entriesA.first.occupancy, 0.5);
      expect(entriesB.first.occupancy, 0.5);
      expect(entriesA.first.isDualMapped, isTrue);
      expect(entriesB.first.isDualMapped, isTrue);
    });

    test('Multi-Output via full rebuild also uses per-subskill anchors',
        () async {
      await seedTestDrill(db,
          drillId: 'drill-multi-rebuild',
          skillArea: SkillArea.approach,
          drillType: DrillType.transition,
          metricSchemaId: 'raw_carry_distance',
          inputMode: InputMode.rawDataEntry,
          subskillMapping: [
            'approach_direction_control',
            'approach_distance_control',
          ],
          anchors: {
            'approach_direction_control': {
              'Min': 20,
              'Scratch': 60,
              'Pro': 80,
            },
            'approach_distance_control': {
              'Min': 100,
              'Scratch': 250,
              'Pro': 400,
            },
          });

      final pbId = await seedPracticeBlock(db, userId);

      // Seed a closed session directly (bypass closeSession to test rebuild path).
      await seedSessionWithInstances(db,
          userId: userId,
          drillId: 'drill-multi-rebuild',
          practiceBlockId: pbId,
          instanceCount: 5,
          rawMetrics: '{"value": 50}',
          sessionId: 'session-multi-rebuild',
          status: SessionStatus.closed);

      // Run full rebuild.
      await engine.executeFullRebuild(userId);

      final windows =
          await scoringRepo.watchWindowStatesByUser(userId).first;

      final entriesA = parseWindowEntries(windows
          .firstWhere((w) =>
              w.subskill == 'approach_direction_control' &&
              w.practiceType == DrillType.transition)
          .entries);
      final entriesB = parseWindowEntries(windows
          .firstWhere((w) =>
              w.subskill == 'approach_distance_control' &&
              w.practiceType == DrillType.transition)
          .entries);

      // Same raw data, different anchors → different scores.
      expect(entriesA.first.score, isNot(equals(entriesB.first.score)),
          reason: 'Full rebuild should also use per-subskill anchors');
    });
  });
}
