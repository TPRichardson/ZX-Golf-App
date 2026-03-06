// Phase M10 — Analytics result data classes (§9.5–9.10).

/// Result for a single club in Gapping distance analytics (§9.6).
class ClubDistanceResult {
  final String clubLabel;
  final String axisValueId;
  final double avgCarry;
  final double avgTotal;
  final double carryConsistency; // StdDev of trimmed carry distances.
  final double? distanceGap; // Gap to next club (null for last).
  final int dataSources; // Number of contributing runs.
  final int attemptCount; // Total trimmed attempts.

  const ClubDistanceResult({
    required this.clubLabel,
    required this.axisValueId,
    required this.avgCarry,
    required this.avgTotal,
    required this.carryConsistency,
    required this.distanceGap,
    required this.dataSources,
    required this.attemptCount,
  });
}

/// Result for a single cell in Wedge Coverage analytics (§9.7).
class WedgeCoverageResult {
  final String cellLabel; // e.g. "52° 50% Low"
  final String cellKey; // Sorted axisValueIds joined.
  final String flightLabel;
  final double avgCarry;
  final double carryConsistency;
  final int dataSources;
  final int attemptCount;

  const WedgeCoverageResult({
    required this.cellLabel,
    required this.cellKey,
    required this.flightLabel,
    required this.avgCarry,
    required this.carryConsistency,
    required this.dataSources,
    required this.attemptCount,
  });
}

/// Result for a single cell in Chipping Accuracy analytics (§9.8).
class ChippingAccuracyResult {
  final String cellLabel;
  final String cellKey;
  final String clubLabel;
  final double targetDistance;
  final double avgCarry;
  final double avgError; // Mean of |carry − target|.
  final double avgRollout;
  final double avgTotal;
  final double shortBias; // 0.0–1.0 fraction of attempts short of target.
  final double carryConsistency;
  final int dataSources;
  final int attemptCount;

  const ChippingAccuracyResult({
    required this.cellLabel,
    required this.cellKey,
    required this.clubLabel,
    required this.targetDistance,
    required this.avgCarry,
    required this.avgError,
    required this.avgRollout,
    required this.avgTotal,
    required this.shortBias,
    required this.carryConsistency,
    required this.dataSources,
    required this.attemptCount,
  });
}

/// Aggregated accuracy overview row for chipping (§9.8.2).
class AccuracyOverviewRow {
  final double targetDistance;
  final double avgError;
  final double shortBias;

  const AccuracyOverviewRow({
    required this.targetDistance,
    required this.avgError,
    required this.shortBias,
  });
}

/// A single data point in a distance trend chart (§9.9).
class TrendPoint {
  final String matrixRunId;
  final DateTime timestamp;
  final double avgCarry;
  final double? avgRollout; // For chipping trends.

  const TrendPoint({
    required this.matrixRunId,
    required this.timestamp,
    required this.avgCarry,
    this.avgRollout,
  });
}

/// An automated insight observation (§9.10).
class Insight {
  final InsightType type;
  final InsightCategory category;
  final String message;
  final double magnitude; // For ranking — higher = more significant.

  const Insight({
    required this.type,
    required this.category,
    required this.message,
    required this.magnitude,
  });
}

/// Insight trigger types (§9.10.3).
enum InsightType {
  smallGap,
  largeGap,
  highInconsistency,
  coverageGap,
  distanceOverlap,
  shortBias,
  highError,
  rolloutVariance,
}

/// Insight category matching matrix type.
enum InsightCategory {
  gapping,
  wedge,
  chipping,
}
