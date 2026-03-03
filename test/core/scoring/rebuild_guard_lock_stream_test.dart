// Phase 4 — RebuildGuard lockStream tests.
// Gaps 39–42: verify lockStream emits correct state changes.

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';

void main() {
  group('RebuildGuard lockStream', () {
    late RebuildGuard guard;

    setUp(() {
      guard = RebuildGuard();
    });

    tearDown(() {
      guard.dispose();
    });

    test('emits true on acquire, false on release', () async {
      final events = <bool>[];
      final sub = guard.lockStream.listen(events.add);

      guard.acquire();
      guard.release();

      // Allow stream to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(events, [true, false]);

      await sub.cancel();
    });

    test('does not emit on failed acquire (already held)', () async {
      final events = <bool>[];
      final sub = guard.lockStream.listen(events.add);

      expect(guard.acquire(), true);
      expect(guard.acquire(), false); // Should not emit.

      await Future<void>.delayed(Duration.zero);

      // Only one true from the first acquire.
      expect(events, [true]);

      guard.release();
      await Future<void>.delayed(Duration.zero);
      expect(events, [true, false]);

      await sub.cancel();
    });
  });
}
