import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// S17 §17.4 — Connectivity monitoring for offline-first sync.
// Wraps connectivity_plus with injectable stream for testing.

class ConnectivityMonitor {
  final Stream<List<ConnectivityResult>> _connectivityStream;
  final Future<List<ConnectivityResult>> Function() _checkConnectivity;

  /// Production constructor: uses Connectivity().onConnectivityChanged.
  ConnectivityMonitor()
      : _connectivityStream = Connectivity().onConnectivityChanged,
        _checkConnectivity = Connectivity().checkConnectivity;

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
