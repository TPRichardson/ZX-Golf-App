import 'dart:async';
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

  /// Whether the orchestrator is currently running.
  bool get isStarted => _started;

  SyncOrchestrator(
    this._engine,
    this._connectivity,
    this._diagnostics,
    this._authService,
  );

  /// Start orchestrator: begin periodic timer + connectivity listener.
  void start() {
    if (_started) return;
    _started = true;

    _startPeriodicTimer();
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    debugPrint('[SyncOrchestrator] Started');
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
      _diagnostics.emit('sync_skipped', Duration.zero, {
        'reason': 'sync_disabled',
        'trigger': reason.name,
      });
      return;
    }

    // Auth guard: only sync when authenticated.
    if (!_authService.isAuthenticated) {
      _diagnostics.emit('sync_skipped', Duration.zero, {
        'reason': 'not_authenticated',
        'trigger': reason.name,
      });
      return;
    }

    // Connectivity guard.
    if (!_isOnline) {
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
      await _engine.triggerSync(reason: reason);
    } catch (e) {
      debugPrint('[SyncOrchestrator] Sync failed: $e');
    }
  }

  /// Periodic callback: check if online, then trigger.
  void _onPeriodicTick() {
    if (!_started || !_isOnline) return;
    _debouncedTrigger(SyncTrigger.periodic);
  }

  /// Connectivity change callback: if restored, trigger sync.
  void _onConnectivityChanged(bool isConnected) {
    final wasOffline = !_isOnline;
    _isOnline = isConnected;

    if (isConnected) {
      _engine.setOffline(false);
      _startPeriodicTimer();

      // TD-03 §5.1 — Trigger sync when connectivity restored.
      if (wasOffline) {
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
