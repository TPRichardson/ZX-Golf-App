// Phase 2B — Scoring Riverpod providers.
// TD-03 §3.1 — One provider per scoring domain object.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/data/database.dart';

import 'database_providers.dart';
import 'repository_providers.dart';
import 'sync_providers.dart';

/// TD-04 §3.3 — Singleton RebuildGuard.
final rebuildGuardProvider = Provider<RebuildGuard>((ref) {
  final guard = RebuildGuard();
  ref.onDispose(() => guard.dispose());
  return guard;
});

/// Phase 2B — Singleton ReflowInstrumentation.
final reflowInstrumentationProvider = Provider<ReflowInstrumentation>((ref) {
  return ReflowInstrumentation();
});

/// TD-04 §3.2 — ReflowEngine with all dependencies injected.
final reflowEngineProvider = Provider<ReflowEngine>((ref) {
  return ReflowEngine(
    scoringRepository: ref.watch(scoringRepositoryProvider),
    eventLogRepository: ref.watch(eventLogRepositoryProvider),
    rebuildGuard: ref.watch(rebuildGuardProvider),
    syncWriteGate: ref.watch(syncWriteGateProvider),
    database: ref.watch(databaseProvider),
    instrumentation: ref.watch(reflowInstrumentationProvider),
  );
});

/// Gap 39–42 — Scoring lock state observable by UI.
/// Emits true when the rebuild guard is held, false otherwise.
final scoringLockActiveProvider = StreamProvider<bool>((ref) {
  final guard = ref.watch(rebuildGuardProvider);
  return guard.lockStream;
});

/// Gap 43 — System maintenance flag (defaults to false, trigger deferred).
final systemMaintenanceActiveProvider = StateProvider<bool>((ref) => false);

/// S16 §16.1.6 — Reactive stream of materialised window states by userId.
final windowStatesProvider =
    StreamProvider.family<List<MaterialisedWindowState>, String>((ref, userId) {
  return ref.watch(scoringRepositoryProvider).watchWindowStatesByUser(userId);
});

/// S16 §16.1.6 — Reactive stream of materialised subskill scores by userId.
final subskillScoresProvider =
    StreamProvider.family<List<MaterialisedSubskillScore>, String>(
        (ref, userId) {
  return ref
      .watch(scoringRepositoryProvider)
      .watchSubskillScoresByUser(userId);
});

/// S16 §16.1.6 — Reactive stream of materialised skill area scores by userId.
final skillAreaScoresProvider =
    StreamProvider.family<List<MaterialisedSkillAreaScore>, String>(
        (ref, userId) {
  return ref
      .watch(scoringRepositoryProvider)
      .watchSkillAreaScoresByUser(userId);
});

/// S16 §16.1.6 — Reactive stream of materialised overall score by userId.
final overallScoreProvider =
    StreamProvider.family<MaterialisedOverallScore?, String>((ref, userId) {
  return ref.watch(scoringRepositoryProvider).watchOverallScoreByUser(userId);
});
