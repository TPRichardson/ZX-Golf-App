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

  /// Create orchestrator — call inside fakeAsync so clock.now() aligns.
  SyncOrchestrator makeOrchestrator() => SyncOrchestrator(
        fakeEngine, monitor, diagnostics, fakeAuth);

  setUp(() {
    fakeEngine = FakeSyncEngine();
    connectivityController = StreamController<List<ConnectivityResult>>.broadcast();
    monitor = ConnectivityMonitor.withStream(connectivityController.stream);
    diagnostics = SyncInstrumentation();
    fakeAuth = FakeAuthService();
  });

  tearDown(() {
    connectivityController.close();
  });

  group('SyncOrchestrator lifecycle', () {
    test('isStarted is false initially', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        expect(o.isStarted, isFalse);
        o.dispose();
      });
    });

    test('start sets isStarted to true', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        expect(o.isStarted, isTrue);
        o.dispose();
      });
    });

    test('stop sets isStarted to false', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        o.stop();
        expect(o.isStarted, isFalse);
        o.dispose();
      });
    });

    test('double start is no-op', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        o.start();
        expect(o.isStarted, isTrue);
        o.dispose();
      });
    });

    test('stop without start is safe', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.stop();
        expect(o.isStarted, isFalse);
        o.dispose();
      });
    });
  });

  group('SyncOrchestrator debouncing', () {
    test('requestSync triggers after debounce window', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        o.requestSync(SyncTrigger.manual);

        // Not yet triggered.
        expect(fakeEngine.triggeredReasons, isEmpty);

        // Advance past debounce window.
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.manual));
        o.dispose();
      });
    });

    test('rapid triggers coalesce to single sync', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        // Fire 5 rapid triggers.
        for (var i = 0; i < 5; i++) {
          o.requestSync(SyncTrigger.postSession);
          async.elapse(const Duration(milliseconds: 100));
        }

        // Advance past debounce window from last trigger.
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        // Only one sync should have fired (the last one after debounce).
        // The first 4 were cancelled by subsequent calls within 500ms.
        expect(fakeEngine.triggeredReasons.length, 1);
        o.dispose();
      });
    });

    test('requestSync does nothing when not started', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.requestSync(SyncTrigger.manual);
        async.elapse(const Duration(seconds: 1));
        expect(fakeEngine.triggeredReasons, isEmpty);
        o.dispose();
      });
    });
  });

  group('SyncOrchestrator periodic timer', () {
    test('periodic timer fires after kSyncPeriodicInterval', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        o.recordUserActivity();

        // Advance to just after the periodic interval.
        async.elapse(kSyncPeriodicInterval + const Duration(seconds: 1));

        // Should have triggered periodic + debounce window.
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.periodic));
        o.dispose();
      });
    });

    test('periodic timer fires multiple times', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        // Advance through 3 periodic intervals, recording activity each time.
        for (var i = 0; i < 3; i++) {
          o.recordUserActivity();
          async.elapse(kSyncPeriodicInterval);
          async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));
        }

        final periodicCount = fakeEngine.triggeredReasons
            .where((r) => r == SyncTrigger.periodic)
            .length;
        expect(periodicCount, greaterThanOrEqualTo(3));
        o.dispose();
      });
    });

    test('periodic timer skipped when user is idle', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        // Advance past idle threshold so user is considered inactive.
        async.elapse(kSyncIdleThreshold + const Duration(minutes: 1));

        // Clear any triggers that happened before idle.
        fakeEngine.triggeredReasons.clear();

        // Advance through a periodic interval — should be skipped.
        async.elapse(kSyncPeriodicInterval + const Duration(seconds: 1));
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        final periodicCount = fakeEngine.triggeredReasons
            .where((r) => r == SyncTrigger.periodic)
            .length;
        expect(periodicCount, 0);
        o.dispose();
      });
    });

    test('periodic timer resumes after user activity', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        // Go idle.
        async.elapse(kSyncIdleThreshold + const Duration(minutes: 1));
        fakeEngine.triggeredReasons.clear();

        // Record activity, then wait for periodic tick.
        o.recordUserActivity();
        async.elapse(kSyncPeriodicInterval + const Duration(seconds: 1));
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.periodic));
        o.dispose();
      });
    });
  });

  group('SyncOrchestrator connectivity', () {
    test('connectivity restored triggers sync when user active', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        o.recordUserActivity();

        // Simulate going offline then online.
        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        connectivityController.add([ConnectivityResult.wifi]);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.connectivity));
        o.dispose();
      });
    });

    test('connectivity restored skipped when user idle', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        // Go idle.
        async.elapse(kSyncIdleThreshold + const Duration(minutes: 1));
        fakeEngine.triggeredReasons.clear();

        // Simulate offline then online while idle.
        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        connectivityController.add([ConnectivityResult.wifi]);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        final connectivityTriggers = fakeEngine.triggeredReasons
            .where((r) => r == SyncTrigger.connectivity)
            .length;
        expect(connectivityTriggers, 0);
        o.dispose();
      });
    });

    test('connectivity lost sets engine offline', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        expect(fakeEngine.isOffline, isTrue);
        o.dispose();
      });
    });

    test('connectivity restored clears offline status', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));
        expect(fakeEngine.isOffline, isTrue);

        connectivityController.add([ConnectivityResult.wifi]);
        async.elapse(const Duration(milliseconds: 50));
        expect(fakeEngine.isOffline, isFalse);
        o.dispose();
      });
    });
  });

  group('SyncOrchestrator guards', () {
    test('sync skipped when not authenticated', () {
      fakeAsync((async) {
        fakeAuth.isAuthenticated = false;
        final o = makeOrchestrator();
        o.start();
        o.requestSync(SyncTrigger.manual);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, isEmpty);
        expect(
          diagnostics.diagnostics.any(
            (d) => d.event == 'sync_skipped' &&
                d.data['reason'] == 'not_authenticated',
          ),
          isTrue,
        );
        o.dispose();
      });
    });

    test('sync skipped when sync disabled', () {
      fakeAsync((async) {
        fakeEngine.syncEnabled = false;
        final o = makeOrchestrator();
        o.start();
        o.requestSync(SyncTrigger.manual);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, isEmpty);
        expect(
          diagnostics.diagnostics.any(
            (d) => d.event == 'sync_skipped' &&
                d.data['reason'] == 'sync_disabled',
          ),
          isTrue,
        );
        o.dispose();
      });
    });

    test('sync skipped when offline', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();

        // Go offline.
        connectivityController.add([ConnectivityResult.none]);
        async.elapse(const Duration(milliseconds: 50));

        // Try manual sync while offline.
        diagnostics.clear();
        o.requestSync(SyncTrigger.manual);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        // Should not trigger engine (manual sync while offline is skipped).
        final manualTriggers = fakeEngine.triggeredReasons
            .where((r) => r == SyncTrigger.manual)
            .length;
        expect(manualTriggers, 0);
        o.dispose();
      });
    });
  });

  group('SyncOrchestrator post-session trigger', () {
    test('postSession trigger fires sync', () {
      fakeAsync((async) {
        final o = makeOrchestrator();
        o.start();
        o.requestSync(SyncTrigger.postSession);
        async.elapse(kSyncDebounceWindow + const Duration(milliseconds: 50));

        expect(fakeEngine.triggeredReasons, contains(SyncTrigger.postSession));
        o.dispose();
      });
    });
  });
}
