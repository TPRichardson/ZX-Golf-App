import 'dart:math';

// Phase M10 — Weighted aggregation model (§9.4).

/// Computes the time-decay weight for a run based on its age in days.
///
/// Spec: §9.4.2 — weight = exp(−2.25 × √(age_days / 365))
double computeWeight(int ageDays) {
  if (ageDays <= 0) return 1.0;
  return exp(-2.25 * sqrt(ageDays / 365.0));
}

/// Computes the weighted average of [values] using [weights].
///
/// Spec: §9.4.3 — WeightedAverage = Σ(value × weight) / Σ(weight)
///
/// Returns 0.0 if [values] is empty or total weight is 0.
double weightedAverage(List<double> values, List<double> weights) {
  assert(values.length == weights.length);
  if (values.isEmpty) return 0.0;

  var sumVW = 0.0;
  var sumW = 0.0;
  for (var i = 0; i < values.length; i++) {
    sumVW += values[i] * weights[i];
    sumW += weights[i];
  }

  if (sumW == 0.0) return 0.0;
  return sumVW / sumW;
}

/// Computes the unweighted arithmetic mean of [values].
///
/// Used when the Raw toggle is active (§9.4.4).
double rawAverage(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Computes the standard deviation of [values].
///
/// Spec: §9.6.2 — CarryConsistency = StdDev(trimmed carry distances).
double standardDeviation(List<double> values) {
  if (values.length < 2) return 0.0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  final sumSqDiff =
      values.fold<double>(0.0, (sum, v) => sum + (v - mean) * (v - mean));
  return sqrt(sumSqDiff / values.length);
}
