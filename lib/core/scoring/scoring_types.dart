// Phase 2A — Pure scoring data types.
// No Drift dependency. All types are plain immutable Dart classes.

/// Spec: S01 §1.4 — Min/Scratch/Pro anchor triple for two-segment interpolation.
class Anchors {
  final double min;
  final double scratch;
  final double pro;

  const Anchors({
    required this.min,
    required this.scratch,
    required this.pro,
  });
}

/// TD-06 §5.1.2 — Adapter type determines how raw metrics become a 0–5 score.
enum ScoringAdapterType {
  /// Grid and binary drills: score from hit-rate % at session level.
  hitRateInterpolation,

  /// Raw data drills: score from per-instance numeric value.
  linearInterpolation,

  /// Technique blocks: no scoring.
  none,
}

/// S01 §1.4 — Single raw numeric value for per-instance scoring.
class RawInstanceInput {
  final double value;

  const RawInstanceInput(this.value);
}

/// S01 §1.4 — Aggregate hit/attempt counts for session-level hit-rate scoring.
class HitRateSessionInput {
  final int totalHits;
  final int totalAttempts;

  const HitRateSessionInput({
    required this.totalHits,
    required this.totalAttempts,
  });
}

/// S01 §1.9 — A single entry in a subskill window.
class WindowEntry {
  final String sessionId;
  final String drillId;
  final DateTime completionTimestamp;
  final double score;
  final double occupancy;
  final bool isDualMapped;

  const WindowEntry({
    required this.sessionId,
    this.drillId = '',
    required this.completionTimestamp,
    required this.score,
    required this.occupancy,
    required this.isDualMapped,
  });

  /// Returns a copy with updated occupancy.
  WindowEntry copyWith({double? occupancy}) => WindowEntry(
        sessionId: sessionId,
        drillId: drillId,
        completionTimestamp: completionTimestamp,
        score: score,
        occupancy: occupancy ?? this.occupancy,
        isDualMapped: isDualMapped,
      );
}

/// S01 §1.9 — Computed state of a subskill window after composition.
class WindowState {
  final List<WindowEntry> entries;
  final double totalOccupancy;
  final double weightedSum;
  final double windowAverage;

  const WindowState({
    required this.entries,
    required this.totalOccupancy,
    required this.weightedSum,
    required this.windowAverage,
  });
}

/// S01 §1.11, S02 §2.5 — Computed subskill score with components.
class SubskillScore {
  final double transitionAverage;
  final double pressureAverage;
  final double weightedAverage;
  final double subskillPoints;
  final int allocation;

  const SubskillScore({
    required this.transitionAverage,
    required this.pressureAverage,
    required this.weightedAverage,
    required this.subskillPoints,
    required this.allocation,
  });
}

/// S11 — Input for integrity bounds evaluation.
class IntegrityInput {
  final double value;
  final double? hardMinInput;
  final double? hardMaxInput;
  final ScoringAdapterType adapterType;

  const IntegrityInput({
    required this.value,
    this.hardMinInput,
    this.hardMaxInput,
    required this.adapterType,
  });
}
