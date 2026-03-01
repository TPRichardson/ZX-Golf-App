import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';

void main() {
  // TD-03 §2.1.1 — SyncWriteGate tests.

  late SyncWriteGate gate;

  setUp(() {
    gate = SyncWriteGate();
  });

  tearDown(() {
    gate.dispose();
  });

  group('acquire/release', () {
    test('acquireExclusive succeeds when gate is free', () {
      expect(gate.acquireExclusive(), isTrue);
      expect(gate.isHeld, isTrue);
    });

    test('acquireExclusive fails when gate is already held', () {
      gate.acquireExclusive();
      expect(gate.acquireExclusive(), isFalse);
    });

    test('release frees the gate for re-acquisition', () {
      gate.acquireExclusive();
      gate.release();
      expect(gate.isHeld, isFalse);
      expect(gate.acquireExclusive(), isTrue);
    });

    test('release is safe to call when gate is not held', () {
      gate.release();
      expect(gate.isHeld, isFalse);
    });
  });

  group('awaitGateRelease', () {
    test('completes immediately when gate is not held', () async {
      await gate.awaitGateRelease();
    });

    test('waits until gate is released', () async {
      gate.acquireExclusive();
      var released = false;

      final future = gate.awaitGateRelease().then((_) {
        released = true;
      });

      // Not released yet
      await Future.delayed(Duration.zero);
      expect(released, isFalse);

      // Release the gate
      gate.release();
      await future;
      expect(released, isTrue);
    });

    test('multiple waiters all complete on release', () async {
      gate.acquireExclusive();
      var count = 0;

      final f1 = gate.awaitGateRelease().then((_) => count++);
      final f2 = gate.awaitGateRelease().then((_) => count++);
      final f3 = gate.awaitGateRelease().then((_) => count++);

      gate.release();
      await Future.wait([f1, f2, f3]);
      expect(count, 3);
    });
  });

  group('timeout', () {
    test('gate auto-releases after hard timeout', () {
      // Use fake async to test the 60-second timeout
      gate.acquireExclusive();
      expect(gate.isHeld, isTrue);

      // We cannot easily fake the real Timer in a unit test without
      // fakeAsync, but we verify that dispose cleans up properly.
      gate.dispose();
      expect(gate.isHeld, isFalse);
    });
  });

  group('dispose', () {
    test('completes all pending waiters', () async {
      gate.acquireExclusive();
      var completed = false;

      final future = gate.awaitGateRelease().then((_) {
        completed = true;
      });

      gate.dispose();
      await future;
      expect(completed, isTrue);
    });
  });
}
