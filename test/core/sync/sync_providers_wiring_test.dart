import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/sync/connectivity_monitor.dart';
import 'package:zx_golf_app/core/sync/storage_monitor.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/database_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';

// Phase 7C — Provider wiring tests.
// Verifies that the replaced and new providers read from engine/monitor.

void main() {
  late AppDatabase db;
  late SyncWriteGate gate;
  late SyncEngine engine;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = SyncWriteGate();
    engine = SyncEngine(
      SupabaseClient('https://test.supabase.co', 'test-key'),
      db,
      gate,
      SyncInstrumentation(),
    );

    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        syncWriteGateProvider.overrideWithValue(gate),
        syncEngineProvider.overrideWithValue(engine),
        connectivityMonitorProvider.overrideWithValue(
          ConnectivityMonitor.withStream(
            const Stream<List<ConnectivityResult>>.empty(),
          ),
        ),
        storageMonitorProvider.overrideWithValue(
          StorageMonitor.withCheck(() async => false),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    engine.dispose();
    gate.dispose();
    await db.close();
  });

  group('Replaced providers', () {
    test('syncEnabledProvider is Provider<bool> (not StateProvider)', () {
      // Reading should return the engine's value, not a separate state.
      final enabled = container.read(syncEnabledProvider);
      expect(enabled, isA<bool>());
      expect(enabled, false); // Default engine state (sync off by default).
    });

    test('syncFailureCountProvider is Provider<int> (not StateProvider)', () {
      final count = container.read(syncFailureCountProvider);
      expect(count, isA<int>());
      expect(count, 0); // Default engine state.
    });
  });

  group('New Phase 7C providers', () {
    test('consecutiveMergeTimeoutsProvider reads from engine', () {
      final timeouts = container.read(consecutiveMergeTimeoutsProvider);
      expect(timeouts, 0);
    });

    test('schemaMismatchDetectedProvider reads from engine', () {
      final mismatch = container.read(schemaMismatchDetectedProvider);
      expect(mismatch, false);
    });

    test('lastSyncTimestampProvider returns null initially', () async {
      final timestamp = await container.read(lastSyncTimestampProvider.future);
      expect(timestamp, isNull);
    });

    test('isStorageLowProvider reads from monitor', () async {
      final isLow = await container.read(isStorageLowProvider.future);
      expect(isLow, false);
    });

    test('isStorageLowProvider with override returning true', () async {
      final lowContainer = ProviderContainer(
        overrides: [
          storageMonitorProvider.overrideWithValue(
            StorageMonitor.withCheck(() async => true),
          ),
        ],
      );
      addTearDown(lowContainer.dispose);

      final isLow = await lowContainer.read(isStorageLowProvider.future);
      expect(isLow, true);
    });

    test('connectivityStatusProvider is StreamProvider<bool>', () {
      // Accessing the provider should not throw.
      final connectivity = container.read(connectivityStatusProvider);
      expect(connectivity, isA<AsyncValue<bool>>());
    });

    test('dualActiveSessionProvider is StreamProvider<String>', () {
      final dual = container.read(dualActiveSessionProvider);
      expect(dual, isA<AsyncValue<String>>());
    });

    test('storageMonitorProvider returns StorageMonitor', () {
      final monitor = container.read(storageMonitorProvider);
      expect(monitor, isA<StorageMonitor>());
    });
  });
}
