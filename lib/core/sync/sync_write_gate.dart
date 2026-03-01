import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:zx_golf_app/core/constants.dart';

// TD-03 §2.1.1 — SyncWriteGate: mutual exclusion for sync writes.
// Phase 2.5: functional class with acquire/release/timeout.
// Repositories don't check the gate until Phase 7B.

class SyncWriteGate {
  bool _held = false;
  final List<Completer<void>> _waiters = [];
  Timer? _timeoutTimer;

  /// Whether the gate is currently held by a sync cycle.
  bool get isHeld => _held;

  /// TD-03 §2.1.1 — Acquire exclusive write access.
  /// Returns false if the gate is already held.
  bool acquireExclusive() {
    if (_held) return false;
    _held = true;
    _timeoutTimer = Timer(kSyncWriteGateHardTimeout, () {
      // TD-03 §2.1.1 — Hard timeout: auto-release after 60s.
      debugPrint('[SyncWriteGate] Hard timeout reached, forcing release');
      release();
    });
    return true;
  }

  /// TD-03 §2.1.1 — Release the gate and notify all waiters.
  void release() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _held = false;
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
    _waiters.clear();
  }

  /// TD-03 §2.1.1 — Wait for the gate to be released.
  /// Phase 2.5: returns immediately if gate is not held.
  Future<void> awaitGateRelease() {
    if (!_held) return Future.value();
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Clean up resources. Releases the gate and completes all waiters.
  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _held = false;
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
    _waiters.clear();
  }
}
