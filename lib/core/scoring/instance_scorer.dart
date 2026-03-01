// Phase 2A — Per-instance scoring.
// Spec: S01 §1.4 — Converts a single raw numeric value to a 0–5 score.
// Used for LinearInterpolation adapter drills (raw_carry_distance,
// raw_ball_speed, raw_club_head_speed).

import 'scoring_helpers.dart';
import 'scoring_types.dart';

/// Spec: S01 §1.4 — Scores a single raw data instance through two-segment
/// linear interpolation. Validates anchors, then delegates to [interpolate].
double scoreInstance(RawInstanceInput input, Anchors anchors) {
  validateAnchors(anchors);
  return interpolate(input.value, anchors);
}
