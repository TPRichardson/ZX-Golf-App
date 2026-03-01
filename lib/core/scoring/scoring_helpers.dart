// Phase 2A — Shared scoring helper functions.
// Pure functions, no DB dependency.

import '../constants.dart';
import '../error_types.dart';
import 'scoring_types.dart';

/// TD-07 §2.3 — Validates that anchors satisfy min < scratch < pro
/// and all values are finite.
void validateAnchors(Anchors anchors) {
  if (!anchors.min.isFinite ||
      !anchors.scratch.isFinite ||
      !anchors.pro.isFinite) {
    throw ValidationException(
      code: ValidationException.invalidAnchors,
      message:
          'Anchor values must be finite: min=${anchors.min}, scratch=${anchors.scratch}, pro=${anchors.pro}',
    );
  }
  if (!(anchors.min < anchors.scratch && anchors.scratch < anchors.pro)) {
    throw ValidationException(
      code: ValidationException.invalidAnchors,
      message:
          'Anchors must satisfy min < scratch < pro: min=${anchors.min}, scratch=${anchors.scratch}, pro=${anchors.pro}',
    );
  }
}

/// TD-06 §5.1.2 — Parses a scoring adapter binding string to enum.
ScoringAdapterType parseScoringAdapterBinding(String binding) {
  switch (binding) {
    case 'hitRateInterpolation':
      return ScoringAdapterType.hitRateInterpolation;
    case 'linearInterpolation':
      return ScoringAdapterType.linearInterpolation;
    case 'none':
      return ScoringAdapterType.none;
    default:
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Unknown scoring adapter binding: $binding',
      );
  }
}

/// Spec: S01 §1.4 — Two-segment piecewise linear interpolation clamped to [0.0, 5.0].
///
/// Case 1: value < min → 0.0
/// Case 2: min ≤ value ≤ scratch → kScratchScore × (value − min) / (scratch − min)
/// Case 3: scratch < value ≤ pro → kScratchScore + (kMaxScore − kScratchScore) × (value − scratch) / (pro − scratch)
/// Case 4: value > pro → 5.0
double interpolate(double value, Anchors anchors) {
  if (value < anchors.min) {
    // Case 1 — Below minimum.
    return 0.0;
  } else if (value <= anchors.scratch) {
    // Case 2 — Between min and scratch.
    return kScratchScore *
        (value - anchors.min) /
        (anchors.scratch - anchors.min);
  } else if (value <= anchors.pro) {
    // Case 3 — Between scratch and pro.
    return kScratchScore +
        (kMaxScore - kScratchScore) *
            (value - anchors.scratch) /
            (anchors.pro - anchors.scratch);
  } else {
    // Case 4 — Above pro, hard cap.
    return kMaxScore;
  }
}
