// Phase 2A — Subskill scoring.
// Accumulation model: each drill contributes fixed points up to window capacity.

import '../constants.dart';
import 'scoring_types.dart';

/// Accumulation scoring model.
/// SubskillPoints = (allocation / (5 × windowSize)) × (0.65 × P_weightedSum + 0.35 × T_weightedSum)
///
/// Each drill contributes fixed points. The score grows as more drills are
/// completed up to the window capacity (windowSize).
SubskillScore scoreSubskill({
  required WindowState transition,
  required WindowState pressure,
  required int allocation,
  required int windowSize,
}) {
  final transitionAverage = transition.windowAverage;
  final pressureAverage = pressure.windowAverage;

  // Accumulation: combine weighted sums (not averages).
  // weightedSum = Σ(score_i × occupancy_i) — already computed by composeWindow().
  final combinedWeightedSum =
      (transition.weightedSum * kTransitionWeight) +
      (pressure.weightedSum * kPressureWeight);

  final effectiveWindowSize = windowSize > 0 ? windowSize : 1;
  final subskillPoints =
      (allocation / (kMaxScore * effectiveWindowSize)) * combinedWeightedSum;

  // Weighted average for display (normalised by windowSize).
  final weightedAverage = combinedWeightedSum / effectiveWindowSize;

  return SubskillScore(
    transitionAverage: transitionAverage,
    pressureAverage: pressureAverage,
    weightedAverage: weightedAverage,
    subskillPoints: subskillPoints,
    allocation: allocation,
  );
}
