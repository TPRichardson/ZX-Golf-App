import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/sync/auth_service.dart';
import 'package:zx_golf_app/core/sync/connectivity_monitor.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';

// TD-03 §5.1 — Sync orchestrator.
// Coordinates sync triggers: periodic, connectivity restored, post-session.
// TD-07 §6.1.1 — Debouncing within 500ms window.

class SyncOrchestrator {
  final SyncEngine _engine;
  final ConnectivityMonitor _connectivity;
  final SyncInstrumentation _diagnostics;
  final AuthService _authService;

  Timer? _periodicTimer;
  Timer? _debounceTimer;
  StreamSubscription<bool>? _connectivitySub;
  bool _started = false;
  bool _isOnline = true;

  /// Last time the user interacted with the app.
  DateTime _lastUserActivity = clock.now();

  /// Whether the orchestrator is currently running.
  bool get isStarted => _started;

  SyncOrchestrator(
    this._engine,
    this._connectivity,
    this._diagnostics,
    this._authService,
  );

  /// Record that the user has actively interacted with the app.
  /// Called from navigation events, screen taps, session actions, etc.
  void recordUserActivity() {
    _lastUserActivity = clock.now();
  }

  /// Whether the user has been active within the sync idle threshold.
  bool get _isUserActive {
    return clock.now().difference(_lastUserActivity) < kSyncIdleThreshold;
  }

  /// Start orchestrator: begin periodic timer + connectivity listener.
  void start() {
    if (_started) return;
    _started = true;

    _startPeriodicTimer();
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    debugPrint('[SyncOrchestrator] Started');

    // Trigger an immediate sync on start (e.g. after login).
    _debouncedTrigger(SyncTrigger.manual);
  }

  /// Stop orchestrator: cancel all timers and subscriptions.
  void stop() {
    if (!_started) return;
    _started = false;

    _periodicTimer?.cancel();
    _periodicTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;

    debugPrint('[SyncOrchestrator] Stopped');
  }

  /// Trigger from external source (postSession, manual, etc).
  /// TD-07 §6.1.1 — Debounces within 500ms window.
  void requestSync(SyncTrigger reason) {
    if (!_started) return;
    debugPrint('[SyncOrchestrator] Sync requested: ${reason.name}');
    _debouncedTrigger(reason);
  }

  /// Internal: debounced trigger execution.
  void _debouncedTrigger(SyncTrigger reason) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(kSyncDebounceWindow, () {
      _executeTrigger(reason);
    });
  }

  /// Execute a sync trigger after guards pass.
  Future<void> _executeTrigger(SyncTrigger reason) async {
    if (!_started) return;

    // TD-03 §5.1 — Feature flag guard.
    if (!_engine.syncEnabled) {
      debugPrint('[SyncOrchestrator] Skipped (sync_disabled) trigger=${reason.name}');
      _diagnostics.emit('sync_skipped', Duration.zero, {
        'reason': 'sync_disabled',
        'trigger': reason.name,
      });
      return;
    }

    // Auth guard: only sync when authenticated.
    if (!_authService.isAuthenticated) {
      debugPrint('[SyncOrchestrator] Skipped (not_authenticated) trigger=${reason.name}');
      _diagnostics.emit('sync_skipped', Duration.zero, {
        'reason': 'not_authenticated',
        'trigger': reason.name,
      });
      return;
    }

    // Connectivity guard.
    if (!_isOnline) {
      debugPrint('[SyncOrchestrator] Skipped (offline) trigger=${reason.name}');
      _diagnostics.emit('sync_skipped', Duration.zero, {
        'reason': 'offline',
        'trigger': reason.name,
      });
      return;
    }

    _diagnostics.emit('sync_trigger', Duration.zero, {
      'trigger': reason.name,
    });

    try {
      final result = await _engine.triggerSync(reason: reason);
      if (!result.success) {
        debugPrint('[SyncOrchestrator] Sync failed: ${result.errorCode} — ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('[SyncOrchestrator] Sync failed: $e');
    }
  }

  /// Periodic callback: check if online and user is active, then trigger.
  void _onPeriodicTick() {
    if (!_started || !_isOnline) return;
    if (!_isUserActive) {
      debugPrint('[SyncOrchestrator] Skipped periodic (user idle)');
      return;
    }
    _debouncedTrigger(SyncTrigger.periodic);
  }

  /// Connectivity change callback: if restored, trigger sync.
  void _onConnectivityChanged(bool isConnected) {
    final wasOffline = !_isOnline;
    _isOnline = isConnected;

    if (isConnected) {
      _engine.setOffline(false);
      _startPeriodicTimer();

      // TD-03 §5.1 — Trigger sync when connectivity restored (only if user active).
      if (wasOffline && _isUserActive) {
        _debouncedTrigger(SyncTrigger.connectivity);
      }
    } else {
      _engine.setOffline(true);
      _periodicTimer?.cancel();
      _periodicTimer = null;
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      kSyncPeriodicInterval,
      (_) => _onPeriodicTick(),
    );
  }

  void dispose() {
    stop();
  }
}
