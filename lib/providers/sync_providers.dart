import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/sync/auth_service.dart';
import 'package:zx_golf_app/core/sync/connectivity_monitor.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/sync/sync_orchestrator.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'database_providers.dart';
import 'scoring_providers.dart';

// TD-03 §5.1 — Sync Riverpod providers.

/// TD-03 §2.1.1 — SyncWriteGate singleton.
final syncWriteGateProvider = Provider<SyncWriteGate>((ref) {
  final gate = SyncWriteGate();
  ref.onDispose(() => gate.dispose());
  return gate;
});

/// TD-03 §5 — Auth service wrapping Supabase Auth.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

/// Phase 7A — SyncInstrumentation singleton.
final syncInstrumentationProvider = Provider<SyncInstrumentation>((ref) {
  return SyncInstrumentation();
});

/// TD-03 §5.1 — Sync engine instance.
/// Phase 7B — ReflowEngine injected for post-merge full rebuild.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    ref.watch(supabaseClientProvider),
    ref.watch(databaseProvider),
    ref.watch(syncWriteGateProvider),
    ref.watch(syncInstrumentationProvider),
    ref.watch(reflowEngineProvider),
  );
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Phase 7A — ConnectivityMonitor singleton.
final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  return ConnectivityMonitor();
});

/// Phase 7A — SyncOrchestrator singleton.
final syncOrchestratorProvider = Provider<SyncOrchestrator>((ref) {
  final orchestrator = SyncOrchestrator(
    ref.watch(syncEngineProvider),
    ref.watch(connectivityMonitorProvider),
    ref.watch(syncInstrumentationProvider),
    ref.watch(authServiceProvider),
  );
  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});

/// TD-03 §5.1 — Stream of sync status changes.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncEngineProvider).getSyncStatus();
});

/// TD-07 §9 — Stream of auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).watchAuthState();
});

/// Phase 7A — Whether sync is enabled (reactive).
final syncEnabledProvider = StateProvider<bool>((ref) => true);

/// Phase 7A — Consecutive failure count (reactive).
final syncFailureCountProvider = StateProvider<int>((ref) => 0);
