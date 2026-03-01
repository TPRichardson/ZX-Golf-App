// Phase 2A — Skill area scoring.
// Spec: S01 §1.12 — Sum of subskill points for a skill area.

import 'scoring_types.dart';

/// Spec: S01 §1.12 — SkillAreaScore = sum of SubskillPoints.
double scoreSkillArea(List<SubskillScore> subskillScores) {
  return subskillScores.fold<double>(
    0.0,
    (sum, s) => sum + s.subskillPoints,
  );
}
