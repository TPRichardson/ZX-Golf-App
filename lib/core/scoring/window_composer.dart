// Phase 2A — Window composition.
// Spec: S01 §1.6–§1.10 — Composes a subskill window from session entries.
// Pure function: takes pre-sorted entries with their occupancy values,
// returns computed window state.

import '../constants.dart';
import 'scoring_types.dart';

/// Spec: S01 §1.9–§1.10 — Composes a window from entries sorted by
/// CompletionTimestamp DESC, SessionID DESC.
///
/// Walks forward accumulating occupancy. Includes entries while
/// totalOccupancy + entry.occupancy ≤ [maxOccupancy].
///
/// Callers handle roll-off (reducing 1.0 → 0.5, evicting 0.5 entries)
/// before calling this function. This keeps the composer stateless.
WindowState composeWindow(
  List<WindowEntry> entries, {
  double maxOccupancy = kMaxWindowOccupancy,
}) {
  // S01 §1.9 — Sort by CompletionTimestamp DESC, then SessionID DESC.
  final sorted = List<WindowEntry>.from(entries)
    ..sort((a, b) {
      final tsCompare = b.completionTimestamp.compareTo(a.completionTimestamp);
      if (tsCompare != 0) return tsCompare;
      return b.sessionId.compareTo(a.sessionId);
    });

  final included = <WindowEntry>[];
  var totalOccupancy = 0.0;
  var weightedSum = 0.0;

  for (final entry in sorted) {
    if (totalOccupancy + entry.occupancy <= maxOccupancy) {
      included.add(entry);
      totalOccupancy += entry.occupancy;
      weightedSum += entry.score * entry.occupancy;
    }
  }

  final windowAverage = totalOccupancy > 0 ? weightedSum / totalOccupancy : 0.0;

  return WindowState(
    entries: included,
    totalOccupancy: totalOccupancy,
    weightedSum: weightedSum,
    windowAverage: windowAverage,
  );
}
