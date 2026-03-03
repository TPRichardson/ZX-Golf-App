// Phase 2B — RebuildGuard: in-memory mutex for full rebuild serialisation.
// TD-03 §4.5, TD-04 §3.3 — Prevents concurrent full rebuilds,
// coalesces deferred triggers via mergeWith.

import 'dart:async';

import '../constants.dart';
import 'reflow_types.dart';

class RebuildGuard {
  bool _held = false;
  final List<ReflowTrigger> _deferredTriggers = [];
  final List<Completer<void>> _waiters = [];
  Timer? _timeoutTimer;
  final _lockController = StreamController<bool>.broadcast();

  /// Whether the guard is currently held.
  bool get isHeld => _held;

  /// Reactive stream of lock state changes.
  Stream<bool> get lockStream => _lockController.stream;

  /// TD-04 §3.3 — Acquire the rebuild guard.
  /// Returns false if the guard is already held.
  bool acquire() {
    if (_held) return false;
    _held = true;
    _lockController.add(true);
    _timeoutTimer = Timer(kRebuildGuardTimeout, () {
      // TD-03 §4.5 — Auto-release after timeout.
      release();
    });
    return true;
  }

  /// TD-04 §3.3 — Release the guard and return coalesced deferred triggers.
  /// Returns null if no triggers were deferred during the hold period.
  ReflowTrigger? release() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _held = false;
    _lockController.add(false);

    // Coalesce all deferred triggers into one via mergeWith.
    ReflowTrigger? coalesced;
    for (final trigger in _deferredTriggers) {
      coalesced = coalesced == null ? trigger : coalesced.mergeWith(trigger);
    }
    _deferredTriggers.clear();

    // Notify all waiters.
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
    _waiters.clear();

    return coalesced;
  }

  /// TD-04 §3.3.3 — Enqueue a trigger for deferred execution.
  /// Called when a reflow is requested while the guard is held.
  void defer(ReflowTrigger trigger) {
    _deferredTriggers.add(trigger);
  }

  /// TD-03 §4.5 — Wait for the guard to be released.
  Future<void> awaitRelease() {
    if (!_held) return Future.value();
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  /// Clean up resources.
  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _held = false;
    _deferredTriggers.clear();
    _lockController.close();
    for (final waiter in _waiters) {
      if (!waiter.isCompleted) {
        waiter.complete();
      }
    }
    _waiters.clear();
  }
}
