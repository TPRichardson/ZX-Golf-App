// Phase 2A — Session-level scoring.
// Spec: S01 §1.4, TD-05 §5 — Two distinct functions because input types differ.
// Grid/binary drills score at session level from aggregate hit-rate.
// Raw data drills score per-instance then average.

import 'scoring_helpers.dart';
import 'scoring_types.dart';

/// Spec: S01 §1.4 — Scores a raw data session by averaging per-instance scores.
/// Each instance is individually scored through interpolation, then a simple
/// average is taken across all instances (flat across all sets).
/// Returns 0.0 if [instances] is empty.
double scoreRawDataSession(List<RawInstanceInput> instances, Anchors anchors) {
  if (instances.isEmpty) return 0.0;
  validateAnchors(anchors);
  final sum = instances.fold<double>(
    0.0,
    (acc, input) => acc + interpolate(input.value, anchors),
  );
  return sum / instances.length;
}

/// Best-of-set scoring: groups instances by set, takes max value per set,
/// averages the maxes, then interpolates. Returns 0.0 if empty.
/// [instancesBySet] maps setId → list of raw numeric values.
double scoreBestOfSetSession(
    Map<String, List<double>> instancesBySet, Anchors anchors) {
  if (instancesBySet.isEmpty) return 0.0;
  validateAnchors(anchors);

  final bestPerSet = <double>[];
  for (final values in instancesBySet.values) {
    if (values.isEmpty) continue;
    bestPerSet.add(values.reduce((a, b) => a > b ? a : b));
  }
  if (bestPerSet.isEmpty) return 0.0;

  final avg = bestPerSet.reduce((a, b) => a + b) / bestPerSet.length;
  return interpolate(avg, anchors);
}

/// Spec: S01 §1.4 — Scores a grid/binary session from aggregate hit-rate %.
/// Computes hit-rate = (totalHits / totalAttempts) × 100, then interpolates.
/// Returns 0.0 if totalAttempts == 0.
double scoreHitRateSession(HitRateSessionInput input, Anchors anchors) {
  if (input.totalAttempts == 0) return 0.0;
  validateAnchors(anchors);
  final hitRate = (input.totalHits / input.totalAttempts) * 100.0;
  return interpolate(hitRate, anchors);
}
