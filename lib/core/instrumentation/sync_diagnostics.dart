// Phase 7A — Sync diagnostics and instrumentation.
// TD-03 §5.1, TD-06 §12 — Performance and diagnostic logging for sync cycles.

import 'package:zx_golf_app/core/sync/sync_types.dart';

/// A single diagnostic event emitted during a sync cycle.
class SyncDiagnostic {
  final DateTime timestamp;
  final String event;
  final Duration elapsed;
  final Map<String, dynamic> data;

  const SyncDiagnostic({
    required this.timestamp,
    required this.event,
    required this.elapsed,
    this.data = const {},
  });

  @override
  String toString() =>
      '[${elapsed.inMilliseconds}ms] $event${data.isNotEmpty ? ' $data' : ''}';
}

/// In-memory collector for sync diagnostic events.
/// Follows the ReflowInstrumentation pattern.
class SyncInstrumentation {
  bool enabled;
  final List<SyncDiagnostic> _diagnostics = [];

  SyncInstrumentation({this.enabled = false});

  /// All collected diagnostics (unmodifiable view).
  List<SyncDiagnostic> get diagnostics =>
      List.unmodifiable(_diagnostics);

  /// Record a diagnostic event.
  void record(SyncDiagnostic diagnostic) {
    _diagnostics.add(diagnostic);
    // Debug-only console print.
    assert(() {
      if (enabled) {
        // ignore: avoid_print
        print('[SyncDiag] $diagnostic');
      }
      return true;
    }());
  }

  /// Convenience: record from components.
  void emit(String event, Duration elapsed,
      [Map<String, dynamic> data = const {}]) {
    record(SyncDiagnostic(
      timestamp: DateTime.now(),
      event: event,
      elapsed: elapsed,
      data: data,
    ));
  }

  /// Convenience: record a full sync cycle summary.
  void emitCycleSummary({
    required SyncTrigger trigger,
    required Duration totalDuration,
    required bool success,
    int uploadedCount = 0,
    int downloadedCount = 0,
    int payloadBytes = 0,
    int batchCount = 1,
    int consecutiveFailures = 0,
    String? errorCode,
  }) {
    emit('sync_cycle_complete', totalDuration, {
      'trigger': trigger.name,
      'success': success,
      'uploadedCount': uploadedCount,
      'downloadedCount': downloadedCount,
      'payloadBytes': payloadBytes,
      'batchCount': batchCount,
      'consecutiveFailures': consecutiveFailures,
      // ignore: use_null_aware_elements
      if (errorCode != null) 'errorCode': errorCode,
    });
  }

  /// Clear all collected diagnostics.
  void clear() => _diagnostics.clear();
}
