// Phase M10 — Outlier trimming (§9.3.3).
//
// Spec: §9.3.3 — Remove the top 10% and bottom 10% of attempts by carry
// distance. For small datasets, trimming is applied proportionally.
// Cells with < 3 attempts are excluded from analytics (§9.3.1).

/// Returns a trimmed copy of [values] with the top and bottom [trimPercent]
/// removed by magnitude. Values are sorted ascending in the result.
///
/// If [values] has fewer than 3 elements, returns the input sorted (no trim).
/// If [trimCount] rounds to 0, returns the full sorted list.
List<double> trimOutliers(
  List<double> values, {
  double trimPercent = 0.10,
}) {
  if (values.length < 3) return List.of(values)..sort();

  final sorted = List.of(values)..sort();
  final trimCount = (sorted.length * trimPercent).round();

  if (trimCount == 0) return sorted;

  // Guard: don't trim more than half the list.
  if (trimCount * 2 >= sorted.length) return sorted;

  return sorted.sublist(trimCount, sorted.length - trimCount);
}
