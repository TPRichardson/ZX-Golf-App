// Phase 2A — Overall SkillScore.
// Spec: S01 §1.13 — Sum of all Skill Area scores, hard cap at 1000.

import 'dart:math';

import '../constants.dart';

/// Spec: S01 §1.13 — OverallScore = sum of all SkillAreaScores.
/// Hard cap at [kTotalAllocation] (1000).
double scoreOverall(List<double> skillAreaScores) {
  final sum = skillAreaScores.fold<double>(0.0, (acc, s) => acc + s);
  return min(sum, kTotalAllocation.toDouble());
}
