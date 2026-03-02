import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/connectivity_monitor.dart';

// Phase 7A — ConnectivityMonitor tests.

void main() {
  group('ConnectivityMonitor', () {
    test('onConnectivityChanged maps wifi to true', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final monitor = ConnectivityMonitor.withStream(controller.stream);

      final future = monitor.onConnectivityChanged.first;
      controller.add([ConnectivityResult.wifi]);

      expect(await future, isTrue);
      await controller.close();
    });

    test('onConnectivityChanged maps none to false', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final monitor = ConnectivityMonitor.withStream(controller.stream);

      final future = monitor.onConnectivityChanged.first;
      controller.add([ConnectivityResult.none]);

      expect(await future, isFalse);
      await controller.close();
    });

    test('onConnectivityChanged maps mobile to true', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final monitor = ConnectivityMonitor.withStream(controller.stream);

      final future = monitor.onConnectivityChanged.first;
      controller.add([ConnectivityResult.mobile]);

      expect(await future, isTrue);
      await controller.close();
    });

    test('mixed results with any non-none returns true', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final monitor = ConnectivityMonitor.withStream(controller.stream);

      final future = monitor.onConnectivityChanged.first;
      controller.add([ConnectivityResult.none, ConnectivityResult.wifi]);

      expect(await future, isTrue);
      await controller.close();
    });

    test('isConnected uses injected check function', () async {
      final monitor = ConnectivityMonitor.withStream(
        const Stream.empty(),
        checkConnectivity: () async => [ConnectivityResult.wifi],
      );

      expect(await monitor.isConnected, isTrue);
    });

    test('isConnected returns false when no connectivity', () async {
      final monitor = ConnectivityMonitor.withStream(
        const Stream.empty(),
        checkConnectivity: () async => [ConnectivityResult.none],
      );

      expect(await monitor.isConnected, isFalse);
    });

    test('stream emits multiple connectivity changes', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      final monitor = ConnectivityMonitor.withStream(controller.stream);

      final values = <bool>[];
      final sub = monitor.onConnectivityChanged.listen(values.add);

      controller.add([ConnectivityResult.wifi]);
      controller.add([ConnectivityResult.none]);
      controller.add([ConnectivityResult.mobile]);

      // Allow microtasks to process.
      await Future.delayed(Duration.zero);

      expect(values, [true, false, true]);

      await sub.cancel();
      await controller.close();
    });
  });
}
