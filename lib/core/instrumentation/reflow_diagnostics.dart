// Phase 2B — Reflow diagnostics and instrumentation.
// TD-04 §3.2 Step 9, TD-06 §7.1.2 — Performance and diagnostic logging.

/// A single diagnostic event emitted during a reflow cycle.
class ReflowDiagnostic {
  final DateTime timestamp;
  final String event;
  final Duration elapsed;
  final Map<String, dynamic> data;

  const ReflowDiagnostic({
    required this.timestamp,
    required this.event,
    required this.elapsed,
    this.data = const {},
  });

  @override
  String toString() =>
      '[${elapsed.inMilliseconds}ms] $event${data.isNotEmpty ? ' $data' : ''}';
}

/// In-memory collector for reflow diagnostic events.
/// Debug-only console output via assert().
class ReflowInstrumentation {
  bool enabled;
  final List<ReflowDiagnostic> _diagnostics = [];

  ReflowInstrumentation({this.enabled = false});

  /// All collected diagnostics (unmodifiable view).
  List<ReflowDiagnostic> get diagnostics =>
      List.unmodifiable(_diagnostics);

  /// Record a diagnostic event.
  void record(ReflowDiagnostic diagnostic) {
    _diagnostics.add(diagnostic);
    // Debug-only console print.
    assert(() {
      if (enabled) {
        // ignore: avoid_print
        print('[ReflowDiag] $diagnostic');
      }
      return true;
    }());
  }

  /// Convenience: record from components.
  void emit(String event, Duration elapsed, [Map<String, dynamic> data = const {}]) {
    record(ReflowDiagnostic(
      timestamp: DateTime.now(),
      event: event,
      elapsed: elapsed,
      data: data,
    ));
  }

  /// Clear all collected diagnostics.
  void clear() => _diagnostics.clear();
}
