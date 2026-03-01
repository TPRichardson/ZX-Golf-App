// Phase 2A — Subskill scoring.
// Spec: S01 §1.11, S02 §2.5 — Combines Transition and Pressure windows
// into a weighted subskill score.

import '../constants.dart';
import 'scoring_types.dart';

/// Spec: S01 §1.11 — Computes subskill points from Transition and Pressure
/// window averages.
///
/// WeightedAverage = (transitionAvg × kTransitionWeight) + (pressureAvg × kPressureWeight)
/// SubskillPoints = allocation × (WeightedAverage / kMaxScore)
SubskillScore scoreSubskill({
  required WindowState transition,
  required WindowState pressure,
  required int allocation,
}) {
  final transitionAverage = transition.windowAverage;
  final pressureAverage = pressure.windowAverage;

  // S02 §2.5 — 65/35 Pressure/Transition weighting.
  final weightedAverage =
      (transitionAverage * kTransitionWeight) +
      (pressureAverage * kPressureWeight);

  // S01 §1.11 — SubskillPoints = Allocation × (WeightedAverage / 5).
  final subskillPoints = allocation * (weightedAverage / kMaxScore);

  return SubskillScore(
    transitionAverage: transitionAverage,
    pressureAverage: pressureAverage,
    weightedAverage: weightedAverage,
    subskillPoints: subskillPoints,
    allocation: allocation,
  );
}
