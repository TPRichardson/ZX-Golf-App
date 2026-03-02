// Phase 4 — TimerService for session inactivity and practice block auto-end.
// S13 §13.5.3 — 2-hour session inactivity timer.
// S13 §13.10.2 — 4-hour practice block auto-end timer.
// TD-04 §2.3.4 — Lock suspension: suspendAll / resumeAll.

import 'dart:async';

/// Injectable clock for deterministic testing.
/// Production uses [DateTime.now]; tests inject a controllable clock.
abstract class Clock {
  DateTime now();
}

/// Default clock using system time.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Tracks a single managed timer with suspend/resume support.
class _ManagedTimer {
  final String id;
  final void Function() onExpired;
  Duration _remaining;
  Timer? _timer;
  DateTime? _startedAt;
  final Clock _clock;

  _ManagedTimer({
    required this.id,
    required Duration duration,
    required this.onExpired,
    required Clock clock,
  })  : _remaining = duration,
        _clock = clock;

  bool get isActive => _timer?.isActive ?? false;

  void start() {
    _timer?.cancel();
    _startedAt = _clock.now();
    _timer = Timer(_remaining, onExpired);
  }

  void suspend() {
    if (_timer == null || !_timer!.isActive) return;
    _timer!.cancel();
    _timer = null;
    if (_startedAt != null) {
      final elapsed = _clock.now().difference(_startedAt!);
      _remaining = _remaining - elapsed;
      if (_remaining.isNegative) _remaining = Duration.zero;
    }
  }

  void resume() {
    if (_timer?.isActive ?? false) return;
    start();
  }

  /// Reset with a new full duration.
  void reset(Duration duration) {
    _timer?.cancel();
    _remaining = duration;
    start();
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

/// S13 §13.5.3, S13 §13.10.2 — Manages inactivity and auto-end timers.
/// Injectable clock for testing. Supports suspend/resume for scoring lock.
class TimerService {
  final Clock _clock;
  final Map<String, _ManagedTimer> _timers = {};
  bool _suspended = false;
  bool _disposed = false;

  TimerService({Clock? clock}) : _clock = clock ?? const SystemClock();

  bool get isSuspended => _suspended;
  bool get isDisposed => _disposed;

  /// S13 §13.5.3 — Start a 2-hour inactivity timer for a session.
  void startSessionInactivityTimer(
    String sessionId,
    Duration timeout,
    void Function() onExpired,
  ) {
    _checkDisposed();
    final id = 'session:$sessionId';
    _timers[id]?.cancel();
    final timer = _ManagedTimer(
      id: id,
      duration: timeout,
      onExpired: onExpired,
      clock: _clock,
    );
    _timers[id] = timer;
    if (!_suspended) timer.start();
  }

  /// S13 §13.10.2 — Start a 4-hour auto-end timer for a practice block.
  void startPracticeBlockAutoEndTimer(
    String practiceBlockId,
    Duration timeout,
    void Function() onExpired,
  ) {
    _checkDisposed();
    final id = 'block:$practiceBlockId';
    _timers[id]?.cancel();
    final timer = _ManagedTimer(
      id: id,
      duration: timeout,
      onExpired: onExpired,
      clock: _clock,
    );
    _timers[id] = timer;
    if (!_suspended) timer.start();
  }

  /// S13 §13.5.3 — Reset session inactivity timer on new Instance.
  void resetSessionInactivityTimer(String sessionId, Duration timeout) {
    _checkDisposed();
    final id = 'session:$sessionId';
    final timer = _timers[id];
    if (timer == null) return;
    timer.reset(timeout);
  }

  /// TD-04 §2.3.4 — Suspend all timers during scoring lock.
  void suspendAll() {
    _checkDisposed();
    if (_suspended) return;
    _suspended = true;
    for (final timer in _timers.values) {
      timer.suspend();
    }
  }

  /// TD-04 §2.3.4 — Resume all timers after scoring lock released.
  void resumeAll() {
    _checkDisposed();
    if (!_suspended) return;
    _suspended = false;
    for (final timer in _timers.values) {
      timer.resume();
    }
  }

  /// Cancel a specific timer by its logical ID.
  void cancel(String timerId) {
    _checkDisposed();
    _timers[timerId]?.cancel();
    _timers.remove(timerId);
  }

  /// Cancel a session inactivity timer.
  void cancelSessionTimer(String sessionId) {
    cancel('session:$sessionId');
  }

  /// Cancel a practice block auto-end timer.
  void cancelBlockTimer(String practiceBlockId) {
    cancel('block:$practiceBlockId');
  }

  /// Cancel all active timers.
  void cancelAll() {
    _checkDisposed();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Dispose and prevent future use.
  void dispose() {
    if (_disposed) return;
    cancelAll();
    _disposed = true;
  }

  /// Number of active timers.
  int get activeTimerCount =>
      _timers.values.where((t) => t.isActive).length;

  /// Total managed timers (active + suspended).
  int get totalTimerCount => _timers.length;

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('TimerService has been disposed');
    }
  }
}
