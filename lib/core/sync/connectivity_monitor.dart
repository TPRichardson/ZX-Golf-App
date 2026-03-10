import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

// S17 §17.4 — Connectivity monitoring for offline-first sync.
// Wraps connectivity_plus with injectable stream for testing.

class ConnectivityMonitor {
  final Stream<List<ConnectivityResult>> _connectivityStream;
  final Future<List<ConnectivityResult>> Function() _checkConnectivity;

  /// Production constructor: uses Connectivity().onConnectivityChanged.
  /// On Windows desktop, connectivity_plus throws PlatformException —
  /// fall back to assuming always-connected.
  ConnectivityMonitor()
      : _connectivityStream = _platformStream(),
        _checkConnectivity = _platformCheck();

  static Stream<List<ConnectivityResult>> _platformStream() {
    if (!kIsWeb && Platform.isWindows) {
      // Use a broadcast StreamController so multiple listeners work.
      final controller =
          StreamController<List<ConnectivityResult>>.broadcast();
      controller.add([ConnectivityResult.wifi]);
      return controller.stream;
    }
    return Connectivity().onConnectivityChanged;
  }

  static Future<List<ConnectivityResult>> Function() _platformCheck() {
    if (!kIsWeb && Platform.isWindows) {
      return () async => [ConnectivityResult.wifi];
    }
    return Connectivity().checkConnectivity;
  }

  /// Test constructor: inject stream and one-shot check.
  ConnectivityMonitor.withStream(
    this._connectivityStream, {
    Future<List<ConnectivityResult>> Function()? checkConnectivity,
  }) : _checkConnectivity = (checkConnectivity ??
            () async => [ConnectivityResult.wifi]);

  /// Stream that emits true when connection restored, false when lost.
  Stream<bool> get onConnectivityChanged => _connectivityStream.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  /// One-shot connectivity check.
  Future<bool> get isConnected async {
    final results = await _checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
