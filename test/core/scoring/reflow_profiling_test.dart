// ignore_for_file: avoid_print
@Tags(['profiling'])
library;

import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Phase 2B — Profiling benchmark harness.
// Run separately: flutter test --tags profiling

/// Seed [sessionCount] closed sessions distributed across system drills,
/// with [instancesPerSession] instances each.
Future<void> seedLargeDataset(
  AppDatabase db,
  String userId, {
  required int sessionCount,
  required int instancesPerSession,
}) async {
  // System drill IDs that have scorable output.
  const scorableDrillIds = [
    'a0000002-0000-4000-8000-000000000001', // Driving Direction
    'a0000002-0000-4000-8000-000000000002', // Irons Direction
    'a0000002-0000-4000-8000-000000000003', // Woods Direction
    'a0000002-0000-4000-8000-000000000004', // Pitching Direction
    'a0000002-0000-4000-8000-000000000005', // Putting Direction
    'a0000002-0000-4000-8000-000000000006', // Chipping Direction
    'a0000002-0000-4000-8000-000000000007', // Bunkers Direction
    'a0000003-0000-4000-8000-000000000001', // Irons Distance
    'a0000003-0000-4000-8000-000000000002', // Woods Distance
    'a0000003-0000-4000-8000-000000000003', // Pitching Distance
    'a0000003-0000-4000-8000-000000000004', // Putting Distance
    'a0000003-0000-4000-8000-000000000005', // Chipping Distance
    'a0000003-0000-4000-8000-000000000006', // Bunkers Distance
    'a0000005-0000-4000-8000-000000000001', // Irons Shape
    'a0000005-0000-4000-8000-000000000002', // Driving Shape
    'a0000005-0000-4000-8000-000000000003', // Woods Shape
    'a0000005-0000-4000-8000-000000000004', // Pitching Flight
    'a0000005-0000-4000-8000-000000000005', // Chipping Flight
  ];

  // Create practice block.
  await db.into(db.practiceBlocks).insertOnConflictUpdate(
        PracticeBlocksCompanion.insert(
          practiceBlockId: 'pb-perf',
          userId: userId,
        ),
      );

  // Pre-generate hit/miss metrics.
  final hitMetrics = jsonEncode({'hit': true});
  final missMetrics = jsonEncode({'hit': false});

  // Batch insert for performance.
  await db.batch((batch) {
    for (var s = 0; s < sessionCount; s++) {
      final drillId = scorableDrillIds[s % scorableDrillIds.length];
      final sessionId = 'perf-session-$s';
      final setId = 'perf-set-$s';
      final ts =
          DateTime(2026, 1, 1, 0, 0).add(Duration(minutes: s));

      batch.insert(
        db.sessions,
        SessionsCompanion.insert(
          sessionId: sessionId,
          drillId: drillId,
          practiceBlockId: 'pb-perf',
          status: const Value(SessionStatus.closed),
          completionTimestamp: Value(ts),
        ),
      );

      batch.insert(
        db.sets,
        SetsCompanion.insert(
          setId: setId,
          sessionId: sessionId,
          setIndex: 0,
        ),
      );

      for (var i = 0; i < instancesPerSession; i++) {
        final isHit = (s * instancesPerSession + i) % 3 != 0; // ~67% hit rate
        batch.insert(
          db.instances,
          InstancesCompanion.insert(
            instanceId: 'perf-inst-$s-$i',
            setId: setId,
            selectedClub: 'i7',
            rawMetrics: isHit ? hitMetrics : missMetrics,
          ),
        );
      }
    }
  });
}

/// Run [iterations] reflow cycles, measure each, and return sorted durations.
List<Duration> _sortedDurations(List<Duration> durations) {
  final sorted = List<Duration>.from(durations)
    ..sort((a, b) => a.compareTo(b));
  return sorted;
}

Duration _percentile(List<Duration> sorted, int p) {
  final index = (p / 100 * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

void main() {
  group('Scoped reflow benchmark (500 sessions / 5K instances)', () {
    test('p95 < kScopedReflowTarget', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final scoringRepo = ScoringRepository(db);
      final eventLogRepo = EventLogRepository(db);
      final rebuildGuard = RebuildGuard();
      final syncWriteGate = SyncWriteGate();
      final instrumentation = ReflowInstrumentation();
      final engine = ReflowEngine(
        scoringRepository: scoringRepo,
        eventLogRepository: eventLogRepo,
        rebuildGuard: rebuildGuard,
        syncWriteGate: syncWriteGate,
        database: db,
        instrumentation: instrumentation,
      );

      const userId = 'perf-user-scoped';
      print('\n--- Seeding 500 sessions / 5K instances ---');
      final seedWatch = Stopwatch()..start();
      await seedLargeDataset(db, userId,
          sessionCount: 500, instancesPerSession: 10);
      print('Seeding took: ${seedWatch.elapsed.inMilliseconds}ms');

      // Run 20 consecutive scoped reflows targeting a single subskill.
      final durations = <Duration>[];
      for (var i = 0; i < 20; i++) {
        final sw = Stopwatch()..start();
        await engine.executeReflow(ReflowTrigger(
          type: ReflowTriggerType.sessionClose,
          userId: userId,
          affectedSubskillIds: {'irons_direction_control'},
        ));
        sw.stop();
        durations.add(sw.elapsed);
      }

      final sorted = _sortedDurations(durations);
      final p50 = _percentile(sorted, 50);
      final p95 = _percentile(sorted, 95);
      final p99 = _percentile(sorted, 99);

      print('--- Scoped Reflow Benchmark ---');
      print('p50: ${p50.inMilliseconds}ms');
      print('p95: ${p95.inMilliseconds}ms');
      print('p99: ${p99.inMilliseconds}ms');
      print('Target: ${kScopedReflowTarget.inMilliseconds}ms');

      expect(p95.inMilliseconds, lessThan(kScopedReflowTarget.inMilliseconds),
          reason:
              'Scoped reflow p95 (${p95.inMilliseconds}ms) must be < ${kScopedReflowTarget.inMilliseconds}ms');

      rebuildGuard.dispose();
      syncWriteGate.dispose();
      await db.close();
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  group('Full rebuild benchmark (5K sessions / 50K instances)', () {
    test('p95 < kFullRebuildTarget', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final scoringRepo = ScoringRepository(db);
      final eventLogRepo = EventLogRepository(db);
      final rebuildGuard = RebuildGuard();
      final syncWriteGate = SyncWriteGate();
      final instrumentation = ReflowInstrumentation();
      final engine = ReflowEngine(
        scoringRepository: scoringRepo,
        eventLogRepository: eventLogRepo,
        rebuildGuard: rebuildGuard,
        syncWriteGate: syncWriteGate,
        database: db,
        instrumentation: instrumentation,
      );

      const userId = 'perf-user-full';
      print('\n--- Seeding 5K sessions / 50K instances ---');
      final seedWatch = Stopwatch()..start();
      await seedLargeDataset(db, userId,
          sessionCount: 5000, instancesPerSession: 10);
      print('Seeding took: ${seedWatch.elapsed.inMilliseconds}ms');

      // Run 20 consecutive full rebuilds.
      final durations = <Duration>[];
      for (var i = 0; i < 20; i++) {
        instrumentation.clear();
        final sw = Stopwatch()..start();
        await engine.executeFullRebuild(userId);
        sw.stop();
        durations.add(sw.elapsed);
      }

      final sorted = _sortedDurations(durations);
      final p50 = _percentile(sorted, 50);
      final p95 = _percentile(sorted, 95);
      final p99 = _percentile(sorted, 99);

      print('--- Full Rebuild Benchmark ---');
      print('p50: ${p50.inMilliseconds}ms');
      print('p95: ${p95.inMilliseconds}ms');
      print('p99: ${p99.inMilliseconds}ms');
      print('Target: ${kFullRebuildTarget.inMilliseconds}ms');

      expect(p95.inMilliseconds, lessThan(kFullRebuildTarget.inMilliseconds),
          reason:
              'Full rebuild p95 (${p95.inMilliseconds}ms) must be < ${kFullRebuildTarget.inMilliseconds}ms');

      rebuildGuard.dispose();
      syncWriteGate.dispose();
      await db.close();
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
