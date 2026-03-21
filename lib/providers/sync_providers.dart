import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/sync/auth_service.dart';
import 'package:zx_golf_app/core/sync/connectivity_monitor.dart';
import 'package:zx_golf_app/core/sync/storage_monitor.dart';
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

/// Factory: sync-engine derived provider that recomputes on status change.
Provider<T> _syncDerived<T>(T Function(SyncEngine) selector) {
  return Provider<T>((ref) {
    ref.watch(syncStatusProvider);
    return selector(ref.read(syncEngineProvider));
  });
}

/// Phase 7C — Whether sync is enabled (reads from engine). TD-07 §6.2.
final syncEnabledProvider = _syncDerived<bool>((e) => e.syncEnabled);

/// Phase 7C — Consecutive failure count (reads from engine). TD-07 §6.2.
final syncFailureCountProvider =
    _syncDerived<int>((e) => e.consecutiveFailures);

/// Phase 7C — Consecutive merge timeout count. TD-07 §6.2.
final consecutiveMergeTimeoutsProvider =
    _syncDerived<int>((e) => e.consecutiveMergeTimeouts);

/// Phase 7C — Connectivity status stream.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityMonitorProvider).onConnectivityChanged;
});

/// Phase 7C — Last sync timestamp from engine.
/// Re-reads after each sync status change so the display stays current.
final lastSyncTimestampProvider = FutureProvider<DateTime?>((ref) {
  ref.watch(syncStatusProvider);
  return ref.watch(syncEngineProvider).getLastSyncTimestamp();
});

/// Phase 7C — Schema mismatch detection flag. TD-07 §6.4.
final schemaMismatchDetectedProvider =
    _syncDerived<bool>((e) => e.schemaMismatchDetected);

/// Phase 7C — Dual active session detection stream.
final dualActiveSessionProvider = StreamProvider<String>((ref) {
  return ref.watch(syncEngineProvider).onDualActiveSessionDetected;
});

/// Phase 7C — StorageMonitor singleton.
final storageMonitorProvider = Provider<StorageMonitor>((ref) {
  return StorageMonitor();
});

/// Phase 7C — Whether device storage is low.
final isStorageLowProvider = FutureProvider<bool>((ref) {
  return ref.watch(storageMonitorProvider).isStorageLow();
});

/// Consolidated sync banner input — single provider watched by SyncStatusBanner
/// instead of 8 separate watches, reducing rebuild triggers.
final syncBannerInputProvider = Provider<
    ({
      bool syncEnabled,
      int failureCount,
      int mergeTimeouts,
      bool schemaMismatch,
      bool isConnected,
      bool isSyncing,
      bool isStorageLow,
      bool isAuthenticated,
    })>((ref) {
  final syncStatus = ref.watch(syncStatusProvider);
  final syncEnabled = ref.watch(syncEnabledProvider);
  final failureCount = ref.watch(syncFailureCountProvider);
  final mergeTimeouts = ref.watch(consecutiveMergeTimeoutsProvider);
  final schemaMismatch = ref.watch(schemaMismatchDetectedProvider);
  final connectivity = ref.watch(connectivityStatusProvider);
  final storageLow = ref.watch(isStorageLowProvider);
  final authState = ref.watch(authStateProvider);

  // TD-07 §9 — Derive auth status from Supabase session.
  final isAuthenticated = authState.whenOrNull(data: (_) {
    return Supabase.instance.client.auth.currentSession != null;
  }) ?? false;

  return (
    syncEnabled: syncEnabled,
    failureCount: failureCount,
    mergeTimeouts: mergeTimeouts,
    schemaMismatch: schemaMismatch,
    isConnected: connectivity.whenOrNull(data: (c) => c) ?? true,
    isSyncing:
        syncStatus.whenOrNull(data: (s) => s) == SyncStatus.inProgress,
    isStorageLow: storageLow.whenOrNull(data: (s) => s) ?? false,
    isAuthenticated: isAuthenticated,
  );
});
