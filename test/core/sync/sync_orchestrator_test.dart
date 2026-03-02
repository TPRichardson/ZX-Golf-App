import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/sync/auth_service.dart';
import 'package:zx_golf_app/core/sync/connectivity_monitor.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/sync/sync_orchestrator.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';

// Phase 7A — SyncOrchestrator tests.
// Uses fakes to avoid real Supabase/DB dependencies.

/// Fake SyncEngine that records trigger calls.
class FakeSyncEngine implements SyncEngine {
  final List<SyncTrigger> triggeredReasons = [];
  bool _syncEnabled = true;
  int _consecutiveFailures = 0;
  final SyncStatus _currentStatus = SyncStatus.idle;
  bool _isOffline = false;

  @override
  bool get syncEnabled => _syncEnabled;
  set syncEnabled(bool v) => _syncEnabled = v;

  @override
  int get consecutiveFailures => _consecutiveFailures;

  @override
  SyncStatus get currentStatus => _currentStatus;

  @override
  Future<SyncResult> triggerSync({required SyncTrigger reason}) async {
    triggeredReasons.add(reason);
    return SyncResult.success(
      serverTimestamp: DateTime.now(),
      uploadedCount: 0,
      downloadedCount: 0,
    );
  }

  @override
  void setOffline(bool offline) => _isOffline = offline;
  bool get isOffline => _isOffline;

  @override
  Future<SyncResult> forceFullSync() =>
      triggerSync(reason: SyncTrigger.forceFullSync);

  @override
  Stream<SyncStatus> getSyncStatus() => const Stream.empty();

  @override
  Future<DateTime?> getLastSyncTimestamp() async => null;

  @override
  Future<void> setSyncEnabled(bool enabled) async => _syncEnabled = enabled;

  @override
  Future<void> resetFailureCounter() async {
    _consecutiveFailures = 0;
    _syncEnabled = true;
  }

  @override
  void dispose() {}

  // Unused interface methods.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake AuthService.
class FakeAuthService implements AuthService {
  bool _authenticated = true;

  @override
  bool get isAuthenticated => _authenticated;
  set isAuthenticated(bool v) => _authenticated = v;

  @override
  String? get currentUserId => _authenticated ? 'test-user' : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSyncEngine fakeEngine;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late ConnectivityMonitor monitor;
  late SyncInstrumentation diagnostics;
  late FakeAuthService fakeAuth;
  late SyncOrchestrator orchestrator;

  setUp(() {
    fakeEngine = FakeSyncEngine();
    connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    monitor = ConnectivityMonitor.withStream(connectivityController.stream);
    diagnostics = SyncInstrumentation();
    fakeAuth = FakeAuthService();
    orchestrator = SyncOrchestrator(
      fakeEngine,
      monitor,
      diagnostics,
      fakeAuth,
    );
  });

  tearDown(() {
    orchestrator.dispose();
    connectivityController.close();
  });

  group('SyncOrchestrator lifecycle', () {
    test('isStarted is false initially', () {
      expect(orchestrator.isStarted, isFalse);
    });

    test('start sets isStarted to true', () {
      orchestrator.start();
      expect(orchestrator.isStarted, isTrue);
    });

    test('stop sets isStarted to false', () {
      orchestrator.start();
      orchestrator.stop();
      expect(orchestrator.isStarted, isFalse);
    });

    test('double start is no-op', () {
      orchestrator.start();
      orchestrator.start();
      expect(orchestrator.isStarted, isTrue);
    });

    test('stop without start is safe', () {
      orchestrator.stop();
      expect(orchestrator.isStarted, isFalse);
    });
  });

  group('SyncOrchestrator debouncing', () {
    test('requestSync triggers after debounce window', () {
      fakeAsync((async) {
        orchestrator.start();
        orchestrator.requestSync(SyncTrigger.manual);

        // Not yet triggered.
        expect(fakeEngine.triggeredReasons, isEmpty);

        // Advance past debounce window.
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.manual));
      });
    });

    test('rapid triggers coalesce to single sync', () {
      fakeAsync((async) {
        orchestrator.start();

        // Fire 5 rapid triggers.
        for (var i = 0; i < 5; i++) {
          orchestrator.requestSync(SyncTrigger.postSession);
          async.elapse(const Duration(milliseconds: 100));
        }

        // Advance past debounce window from last trigger.
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        // Only one sync should have fired (the last one after debounce).
        // The first 4 were cancelled by subsequent calls within 500ms.
        expect(fakeEngine.triggeredReasons.length, 1);
      });
    });

    test('requestSync does nothing when not started', () {
      fakeAsync((async) {
        orchestrator.requestSync(SyncTrigger.manual);
        async.elapse(const Duration(seconds: 1));
        expect(fakeEngine.triggeredReasons, isEmpty);
      });
    });
  });

  group('SyncOrchestrator periodic timer', () {
    test('periodic timer fires after kSyncPeriodicInterval', () {
      fakeAsync((async) {
        orchestrator.start();

        // Advance to just after the periodic interval.
        async.elapse(kSyncPeriodicInterval + const Duration(seconds: 1));

        // Should have triggered periodic + debounce window.
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.periodic));
      });
    });

    test('periodic timer fires multiple times', () {
      fakeAsync((async) {
        orchestrator.start();

        // Advance through 3 periodic intervals.
        for (var i = 0; i < 3; i++) {
          async.elapse(kSyncPeriodicInterval);
          async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));
        }

        final periodicCount = fakeEngine.triggeredReasons
            .where((r) => r == SyncTrigger.periodic)
            .length;
        expect(periodicCount, greaterThanOrEqualTo(3));
      });
    });
  });

  group('SyncOrchestrator connectivity', () {
    test('connectivity restored triggers sync', () {
      fakeAsync((async) {
        orchestrator.start();

        // Simulate going offline then online.
        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        connectivityController.add([ConnectivityResult.wifi]);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.connectivity));
      });
    });

    test('connectivity lost sets engine offline', () {
      fakeAsync((async) {
        orchestrator.start();

        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        expect(fakeEngine.isOffline, isTrue);
      });
    });

    test('connectivity restored clears offline status', () {
      fakeAsync((async) {
        orchestrator.start();

        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));
        expect(fakeEngine.isOffline, isTrue);

        connectivityController.add([ConnectivityResult.wifi]);
        async.elapse(const Duration(milliseconds: 50));
        expect(fakeEngine.isOffline, isFalse);
      });
    });
  });

  group('SyncOrchestrator guards', () {
    test('sync skipped when not authenticated', () {
      fakeAsync((async) {
        fakeAuth.isAuthenticated = false;
        orchestrator.start();
        orchestrator.requestSync(SyncTrigger.manual);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, isEmpty);
        expect(
          diagnostics.diagnostics.any(
            (d) => d.event == 'sync_skipped' &&
                d.data['reason'] == 'not_authenticated',
          ),
          isTrue,
        );
      });
    });

    test('sync skipped when sync disabled', () {
      fakeAsync((async) {
        fakeEngine.syncEnabled = false;
        orchestrator.start();
        orchestrator.requestSync(SyncTrigger.manual);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, isEmpty);
        expect(
          diagnostics.diagnostics.any(
            (d) => d.event == 'sync_skipped' &&
                d.data['reason'] == 'sync_disabled',
          ),
          isTrue,
        );
      });
    });

    test('sync skipped when offline', () {
      fakeAsync((async) {
        orchestrator.start();

        // Go offline.
        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        // Try manual sync while offline.
        diagnostics.clear();
        orchestrator.requestSync(SyncTrigger.manual);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        // Should not trigger engine (manual sync while offline is skipped).
        final manualTriggers = fakeEngine.triggeredReasons
            .where((r) => r == SyncTrigger.manual)
            .length;
        expect(manualTriggers, 0);
      });
    });
  });

  group('SyncOrchestrator post-session trigger', () {
    test('postSession trigger fires sync', () {
      fakeAsync((async) {
        orchestrator.start();
        orchestrator.requestSync(SyncTrigger.postSession);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.postSession));
      });
    });
  });
}
