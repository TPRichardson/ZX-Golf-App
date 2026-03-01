import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/sync/auth_service.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'database_providers.dart';

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

/// TD-03 §5.1 — Sync engine instance.
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    ref.watch(supabaseClientProvider),
    ref.watch(databaseProvider),
    ref.watch(syncWriteGateProvider),
  );
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// TD-03 §5.1 — Stream of sync status changes.
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncEngineProvider).getSyncStatus();
});

/// TD-07 §9 — Stream of auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).watchAuthState();
});
