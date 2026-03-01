import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';

// Phase 2B — RebuildGuard tests.

void main() {
  late RebuildGuard guard;

  setUp(() {
    guard = RebuildGuard();
  });

  tearDown(() {
    guard.dispose();
  });

  group('acquire/release cycle', () {
    test('acquire succeeds on fresh guard', () {
      expect(guard.acquire(), isTrue);
      expect(guard.isHeld, isTrue);
    });

    test('acquire fails when already held', () {
      guard.acquire();
      expect(guard.acquire(), isFalse);
    });

    test('release allows re-acquisition', () {
      guard.acquire();
      guard.release();
      expect(guard.isHeld, isFalse);
      expect(guard.acquire(), isTrue);
    });

    test('release returns null when no triggers deferred', () {
      guard.acquire();
      expect(guard.release(), isNull);
    });
  });

  group('defer + coalesce', () {
    test('single deferred trigger returned on release', () {
      guard.acquire();
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: 'user-1',
        affectedSubskillIds: {'irons_distance_control'},
      ));
      final coalesced = guard.release();
      expect(coalesced, isNotNull);
      expect(coalesced!.affectedSubskillIds, {'irons_distance_control'});
      expect(coalesced.type, ReflowTriggerType.sessionClose);
    });

    test('3 triggers coalesce into 1 with unioned subskillIds', () {
      guard.acquire();
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: 'user-1',
        affectedSubskillIds: {'a'},
      ));
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.anchorEdit,
        userId: 'user-1',
        affectedSubskillIds: {'b'},
      ));
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.instanceDeletion,
        userId: 'user-1',
        affectedSubskillIds: {'c'},
      ));
      final coalesced = guard.release();
      expect(coalesced, isNotNull);
      expect(coalesced!.affectedSubskillIds, {'a', 'b', 'c'});
    });

    test('fullRebuild trigger wins during coalescing', () {
      guard.acquire();
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: 'user-1',
        affectedSubskillIds: {'a'},
      ));
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.fullRebuild,
        userId: 'user-1',
        affectedSubskillIds: {'b'},
      ));
      final coalesced = guard.release();
      expect(coalesced!.type, ReflowTriggerType.fullRebuild);
    });

    test('deferred triggers cleared after release', () {
      guard.acquire();
      guard.defer(ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: 'user-1',
        affectedSubskillIds: {'a'},
      ));
      guard.release();
      // Re-acquire and release: should have no deferred triggers.
      guard.acquire();
      expect(guard.release(), isNull);
    });
  });

  group('timeout auto-release', () {
    test('auto-releases after kRebuildGuardTimeout', () {
      fakeAsync((async) {
        guard.acquire();
        expect(guard.isHeld, isTrue);
        async.elapse(kRebuildGuardTimeout);
        expect(guard.isHeld, isFalse);
      });
    });

    test('auto-release returns deferred triggers', () {
      fakeAsync((async) {
        guard.acquire();
        guard.defer(ReflowTrigger(
          type: ReflowTriggerType.sessionClose,
          userId: 'user-1',
          affectedSubskillIds: {'a'},
        ));
        // We can't capture auto-release return, but guard should be released.
        async.elapse(kRebuildGuardTimeout);
        expect(guard.isHeld, isFalse);
        // Verify acquisition works after timeout.
        expect(guard.acquire(), isTrue);
      });
    });
  });

  group('awaitRelease', () {
    test('returns immediately when guard is not held', () async {
      await guard.awaitRelease();
      // If we get here, it returned immediately.
    });

    test('waiters notified on release', () {
      fakeAsync((async) {
        guard.acquire();
        var notified = false;
        guard.awaitRelease().then((_) => notified = true);
        expect(notified, isFalse);
        guard.release();
        async.flushMicrotasks();
        expect(notified, isTrue);
      });
    });

    test('multiple waiters notified on release', () {
      fakeAsync((async) {
        guard.acquire();
        var count = 0;
        guard.awaitRelease().then((_) => count++);
        guard.awaitRelease().then((_) => count++);
        guard.awaitRelease().then((_) => count++);
        guard.release();
        async.flushMicrotasks();
        expect(count, 3);
      });
    });

    test('waiters notified on timeout auto-release', () {
      fakeAsync((async) {
        guard.acquire();
        var notified = false;
        guard.awaitRelease().then((_) => notified = true);
        async.elapse(kRebuildGuardTimeout);
        async.flushMicrotasks();
        expect(notified, isTrue);
      });
    });
  });

  group('dispose', () {
    test('releases guard and completes waiters', () {
      fakeAsync((async) {
        guard.acquire();
        var notified = false;
        guard.awaitRelease().then((_) => notified = true);
        guard.dispose();
        async.flushMicrotasks();
        expect(guard.isHeld, isFalse);
        expect(notified, isTrue);
      });
    });
  });
}
