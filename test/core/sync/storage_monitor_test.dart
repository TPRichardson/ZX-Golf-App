import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/storage_monitor.dart';

// Phase 7C — StorageMonitor tests.

void main() {
  group('StorageMonitor', () {
    test('default constructor returns false (stub)', () async {
      final monitor = StorageMonitor();
      expect(await monitor.isStorageLow(), false);
    });

    test('injectable constructor with custom check returning true', () async {
      final monitor = StorageMonitor.withCheck(() async => true);
      expect(await monitor.isStorageLow(), true);
    });

    test('injectable constructor with custom check returning false', () async {
      final monitor = StorageMonitor.withCheck(() async => false);
      expect(await monitor.isStorageLow(), false);
    });

    test('exception in check returns false (safe default)', () async {
      final monitor = StorageMonitor.withCheck(
          () async => throw Exception('disk error'));
      expect(await monitor.isStorageLow(), false);
    });

    test('multiple calls return consistent results', () async {
      var callCount = 0;
      final monitor = StorageMonitor.withCheck(() async {
        callCount++;
        return callCount >= 2; // First call false, subsequent true.
      });

      expect(await monitor.isStorageLow(), false);
      expect(await monitor.isStorageLow(), true);
      expect(await monitor.isStorageLow(), true);
      expect(callCount, 3);
    });
  });
}
