// Phase 2A — Integrity bounds evaluation.
// Spec: S11 — Checks HardMinInput/HardMaxInput bounds.
// Returns true if value is IN BREACH.

import 'scoring_types.dart';

/// Spec: S11 — Evaluates whether a metric value breaches hard bounds.
///
/// Returns `true` if the value is IN BREACH.
/// - hitRateInterpolation adapter (grid/binary): always returns false
///   (excluded from integrity detection per S11, S14 §14.5).
/// - Values at boundary are NOT in breach.
/// - If no bounds are defined, returns false.
bool evaluateIntegrity(IntegrityInput input) {
  // S11 — Grid Cell Selection and Binary Hit/Miss excluded.
  if (input.adapterType == ScoringAdapterType.hitRateInterpolation) {
    return false;
  }

  // S11 — Technique blocks have no scoring; no integrity check.
  if (input.adapterType == ScoringAdapterType.none) {
    return false;
  }

  // Check hard bounds. Values at boundary are NOT in breach.
  if (input.hardMinInput != null && input.value < input.hardMinInput!) {
    return true;
  }
  if (input.hardMaxInput != null && input.value > input.hardMaxInput!) {
    return true;
  }

  return false;
}
