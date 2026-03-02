// Phase 4 — TimerService unit tests.
// TD-06 §9 — TimerService tested in complete isolation before UI integration.

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/services/timer_service.dart';

/// Controllable clock for deterministic testing.
class FakeClock implements Clock {
  DateTime _now;

  FakeClock([DateTime? initial]) : _now = initial ?? DateTime(2026, 3, 1);

  @override
  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}

void main() {
  group('TimerService', () {
    late TimerService service;
    late FakeClock clock;

    setUp(() {
      clock = FakeClock();
      service = TimerService(clock: clock);
    });

    tearDown(() {
      service.dispose();
    });

    test('session inactivity timer fires at correct duration', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var fired = false;

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => fired = true,
        );

        expect(svc.activeTimerCount, 1);

        // Advance to just before expiry.
        fakeClock.advance(const Duration(hours: 1, minutes: 59));
        async.elapse(const Duration(hours: 1, minutes: 59));
        expect(fired, false);

        // Advance past expiry.
        fakeClock.advance(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 1));
        expect(fired, true);

        svc.dispose();
      });
    });

    test('practice block auto-end timer fires at correct duration', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var fired = false;

        svc.startPracticeBlockAutoEndTimer(
          'pb-1',
          const Duration(hours: 4),
          () => fired = true,
        );

        expect(svc.activeTimerCount, 1);

        fakeClock.advance(const Duration(hours: 3, minutes: 59));
        async.elapse(const Duration(hours: 3, minutes: 59));
        expect(fired, false);

        fakeClock.advance(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 1));
        expect(fired, true);

        svc.dispose();
      });
    });

    test('reset restarts with full duration', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var fireCount = 0;

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => fireCount++,
        );

        // Advance 1.5 hours, then reset.
        fakeClock.advance(const Duration(hours: 1, minutes: 30));
        async.elapse(const Duration(hours: 1, minutes: 30));
        expect(fireCount, 0);

        svc.resetSessionInactivityTimer(
            'sess-1', const Duration(hours: 2));

        // Another 1.5 hours — should NOT fire (only 1.5h after reset).
        fakeClock.advance(const Duration(hours: 1, minutes: 30));
        async.elapse(const Duration(hours: 1, minutes: 30));
        expect(fireCount, 0);

        // 30 more minutes — now 2h after reset → fires.
        fakeClock.advance(const Duration(minutes: 30));
        async.elapse(const Duration(minutes: 30));
        expect(fireCount, 1);

        svc.dispose();
      });
    });

    test('suspendAll preserves remaining duration', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var fired = false;

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => fired = true,
        );

        // Run for 1 hour, then suspend.
        fakeClock.advance(const Duration(hours: 1));
        async.elapse(const Duration(hours: 1));
        svc.suspendAll();
        expect(svc.isSuspended, true);

        // Wait 5 hours while suspended — should NOT fire.
        fakeClock.advance(const Duration(hours: 5));
        async.elapse(const Duration(hours: 5));
        expect(fired, false);

        // Resume — should fire after remaining 1 hour.
        svc.resumeAll();
        expect(svc.isSuspended, false);

        fakeClock.advance(const Duration(minutes: 59));
        async.elapse(const Duration(minutes: 59));
        expect(fired, false);

        fakeClock.advance(const Duration(minutes: 1));
        async.elapse(const Duration(minutes: 1));
        expect(fired, true);

        svc.dispose();
      });
    });

    test('resumeAll resumes correctly after suspend', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var firedSession = false;
        var firedBlock = false;

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => firedSession = true,
        );
        svc.startPracticeBlockAutoEndTimer(
          'pb-1',
          const Duration(hours: 4),
          () => firedBlock = true,
        );

        // Run 30min, suspend, resume.
        fakeClock.advance(const Duration(minutes: 30));
        async.elapse(const Duration(minutes: 30));
        svc.suspendAll();
        svc.resumeAll();

        // Session fires at 1.5h more (total 2h).
        fakeClock.advance(const Duration(hours: 1, minutes: 30));
        async.elapse(const Duration(hours: 1, minutes: 30));
        expect(firedSession, true);
        expect(firedBlock, false);

        // Block fires at 2h more (total 4h).
        fakeClock.advance(const Duration(hours: 2));
        async.elapse(const Duration(hours: 2));
        expect(firedBlock, true);

        svc.dispose();
      });
    });

    test('multiple concurrent timers do not interfere', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        final firedIds = <String>[];

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 1),
          () => firedIds.add('sess-1'),
        );
        svc.startSessionInactivityTimer(
          'sess-2',
          const Duration(hours: 2),
          () => firedIds.add('sess-2'),
        );
        svc.startPracticeBlockAutoEndTimer(
          'pb-1',
          const Duration(hours: 3),
          () => firedIds.add('pb-1'),
        );

        expect(svc.totalTimerCount, 3);

        fakeClock.advance(const Duration(hours: 1));
        async.elapse(const Duration(hours: 1));
        expect(firedIds, ['sess-1']);

        fakeClock.advance(const Duration(hours: 1));
        async.elapse(const Duration(hours: 1));
        expect(firedIds, ['sess-1', 'sess-2']);

        fakeClock.advance(const Duration(hours: 1));
        async.elapse(const Duration(hours: 1));
        expect(firedIds, ['sess-1', 'sess-2', 'pb-1']);

        svc.dispose();
      });
    });

    test('cancel removes a specific timer', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var fired = false;

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => fired = true,
        );

        svc.cancelSessionTimer('sess-1');
        expect(svc.totalTimerCount, 0);

        fakeClock.advance(const Duration(hours: 3));
        async.elapse(const Duration(hours: 3));
        expect(fired, false);

        svc.dispose();
      });
    });

    test('cancelAll removes all timers', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var sessionFired = false;
        var blockFired = false;

        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => sessionFired = true,
        );
        svc.startPracticeBlockAutoEndTimer(
          'pb-1',
          const Duration(hours: 4),
          () => blockFired = true,
        );

        expect(svc.totalTimerCount, 2);
        svc.cancelAll();
        expect(svc.totalTimerCount, 0);

        fakeClock.advance(const Duration(hours: 5));
        async.elapse(const Duration(hours: 5));
        expect(sessionFired, false);
        expect(blockFired, false);

        svc.dispose();
      });
    });

    test('dispose prevents future operations', () {
      service.dispose();
      expect(service.isDisposed, true);

      expect(
        () => service.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () {},
        ),
        throwsStateError,
      );
      expect(
        () => service.suspendAll(),
        throwsStateError,
      );
    });

    test('dispose is idempotent', () {
      service.dispose();
      service.dispose(); // Should not throw.
      expect(service.isDisposed, true);
    });

    test('suspend when no timers is a no-op', () {
      service.suspendAll();
      expect(service.isSuspended, true);
      service.resumeAll();
      expect(service.isSuspended, false);
    });

    test('resume when not suspended is a no-op', () {
      service.resumeAll(); // Should not throw.
      expect(service.isSuspended, false);
    });

    test('starting timer while suspended defers start until resume', () {
      fakeAsync((async) {
        final fakeClock = FakeClock();
        final svc = TimerService(clock: fakeClock);
        var fired = false;

        svc.suspendAll();
        svc.startSessionInactivityTimer(
          'sess-1',
          const Duration(hours: 2),
          () => fired = true,
        );

        // Timer created but not running.
        expect(svc.totalTimerCount, 1);
        expect(svc.activeTimerCount, 0);

        fakeClock.advance(const Duration(hours: 3));
        async.elapse(const Duration(hours: 3));
        expect(fired, false);

        // Resume starts the deferred timer.
        svc.resumeAll();
        fakeClock.advance(const Duration(hours: 2));
        async.elapse(const Duration(hours: 2));
        expect(fired, true);

        svc.dispose();
      });
    });
  });
}
