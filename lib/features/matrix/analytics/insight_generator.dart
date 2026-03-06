import 'package:zx_golf_app/features/matrix/analytics/analytics_types.dart';

// Phase M10 — Automated insight generation (§9.10).
//
// Insights are lightweight observations ranked by magnitude. A maximum of 3
// are returned per invocation (§9.10.4).

/// Maximum insights returned per page (§9.10.4).
const kMaxInsightsPerPage = 3;

// Default thresholds for gapping insights.
const _kDefaultMinGap = 6.0;
const _kDefaultMaxGap = 20.0;
const _kHighInconsistencyThreshold = 5.0;

// Wedge coverage thresholds.
const _kCoverageGapThreshold = 10.0; // yards with no coverage.
const _kOverlapThreshold = 3.0; // yards apart to count as overlap.

// Chipping thresholds.
const _kShortBiasThreshold = 0.60; // 60% short → insight.
const _kHighErrorMultiplier = 1.5; // error > 1.5× group average.
// Rollout variance threshold reserved for green-condition segmentation.
// const _kRolloutVarianceThreshold = 1.5;

// ---------------------------------------------------------------------------
// §9.10.3 — Gapping Chart Insights
// ---------------------------------------------------------------------------

/// Generates insights from gapping club distance results.
///
/// Triggers:
/// - Gap below minimum threshold
/// - Gap above maximum threshold
/// - High carry inconsistency (StdDev > threshold)
List<Insight> generateGappingInsights(
  List<ClubDistanceResult> results, {
  double minGap = _kDefaultMinGap,
  double maxGap = _kDefaultMaxGap,
  double inconsistencyThreshold = _kHighInconsistencyThreshold,
}) {
  final insights = <Insight>[];

  for (var i = 0; i < results.length; i++) {
    final r = results[i];

    // Gap warnings.
    if (r.distanceGap != null && i < results.length - 1) {
      final nextClub = results[i + 1].clubLabel;
      if (r.distanceGap! < minGap) {
        insights.add(Insight(
          type: InsightType.smallGap,
          category: InsightCategory.gapping,
          message:
              'Your ${r.clubLabel}-$nextClub gap is '
              '${r.distanceGap!.toStringAsFixed(0)}y '
              '-- below your minimum of ${minGap.toStringAsFixed(0)}y.',
          magnitude: minGap - r.distanceGap!,
        ));
      } else if (r.distanceGap! > maxGap) {
        insights.add(Insight(
          type: InsightType.largeGap,
          category: InsightCategory.gapping,
          message:
              'Your ${r.clubLabel}-$nextClub gap is '
              '${r.distanceGap!.toStringAsFixed(0)}y '
              '-- above your maximum of ${maxGap.toStringAsFixed(0)}y.',
          magnitude: r.distanceGap! - maxGap,
        ));
      }
    }

    // High inconsistency.
    if (r.carryConsistency > inconsistencyThreshold) {
      insights.add(Insight(
        type: InsightType.highInconsistency,
        category: InsightCategory.gapping,
        message:
            'Your ${r.clubLabel} carry varies by '
            '\u00b1${r.carryConsistency.toStringAsFixed(1)}y. '
            'More data may improve reliability.',
        magnitude: r.carryConsistency - inconsistencyThreshold,
      ));
    }
  }

  return _rankAndLimit(insights);
}

// ---------------------------------------------------------------------------
// §9.10.3 — Wedge Matrix Insights
// ---------------------------------------------------------------------------

/// Generates insights from wedge coverage results.
///
/// Triggers:
/// - Coverage gap: distance range not covered by any shot type
/// - Distance overlap: two cells produce similar avg carry
List<Insight> generateWedgeInsights(
  List<WedgeCoverageResult> results, {
  double gapThreshold = _kCoverageGapThreshold,
  double overlapThreshold = _kOverlapThreshold,
}) {
  if (results.isEmpty) return [];
  final insights = <Insight>[];

  // Coverage gap detection (§9.7.4).
  final sorted = List.of(results)
    ..sort((a, b) => a.avgCarry.compareTo(b.avgCarry));
  for (var i = 0; i < sorted.length - 1; i++) {
    final gap = sorted[i + 1].avgCarry - sorted[i].avgCarry;
    if (gap > gapThreshold) {
      final low = sorted[i].avgCarry.toStringAsFixed(0);
      final high = sorted[i + 1].avgCarry.toStringAsFixed(0);
      insights.add(Insight(
        type: InsightType.coverageGap,
        category: InsightCategory.wedge,
        message:
            'No shot type reliably covers '
            '${low}y-${high}y in your current wedge system.',
        magnitude: gap,
      ));
    }
  }

  // Overlap detection.
  for (var i = 0; i < sorted.length; i++) {
    for (var j = i + 1; j < sorted.length; j++) {
      final diff = (sorted[j].avgCarry - sorted[i].avgCarry).abs();
      if (diff <= overlapThreshold && sorted[i].cellKey != sorted[j].cellKey) {
        insights.add(Insight(
          type: InsightType.distanceOverlap,
          category: InsightCategory.wedge,
          message:
              'Your ${sorted[i].cellLabel} and ${sorted[j].cellLabel} '
              'produce similar distances '
              '(${sorted[i].avgCarry.toStringAsFixed(0)}y / '
              '${sorted[j].avgCarry.toStringAsFixed(0)}y).',
          magnitude: overlapThreshold - diff,
        ));
      }
    }
  }

  return _rankAndLimit(insights);
}

// ---------------------------------------------------------------------------
// §9.10.3 — Chipping Matrix Insights
// ---------------------------------------------------------------------------

/// Generates insights from chipping accuracy results.
///
/// Triggers:
/// - Consistent short bias (> threshold %)
/// - High average error at a distance (> multiplier × group average)
/// - Rollout variance by condition (not implemented — requires green-segmented data)
List<Insight> generateChippingInsights(
  List<ChippingAccuracyResult> results, {
  double shortBiasThreshold = _kShortBiasThreshold,
  double errorMultiplier = _kHighErrorMultiplier,
}) {
  if (results.isEmpty) return [];
  final insights = <Insight>[];

  // Overall average error for comparison.
  final totalError =
      results.map((r) => r.avgError).reduce((a, b) => a + b) / results.length;

  for (final r in results) {
    // Short bias.
    if (r.shortBias > shortBiasThreshold) {
      insights.add(Insight(
        type: InsightType.shortBias,
        category: InsightCategory.chipping,
        message:
            'Your ${r.targetDistance.toStringAsFixed(0)}y chips land short '
            'on average. Check carry target alignment.',
        magnitude: r.shortBias - shortBiasThreshold,
      ));
    }

    // High error at a distance.
    if (totalError > 0 && r.avgError > totalError * errorMultiplier) {
      insights.add(Insight(
        type: InsightType.highError,
        category: InsightCategory.chipping,
        message:
            'Your ${r.targetDistance.toStringAsFixed(0)}y chip accuracy '
            '(avg error ${r.avgError.toStringAsFixed(1)}y) is significantly '
            'lower than shorter distances.',
        magnitude: r.avgError - totalError,
      ));
    }
  }

  return _rankAndLimit(insights);
}

// ---------------------------------------------------------------------------
// Ranking
// ---------------------------------------------------------------------------

/// Ranks insights by descending magnitude and limits to [kMaxInsightsPerPage].
List<Insight> _rankAndLimit(List<Insight> insights) {
  if (insights.isEmpty) return insights;
  final sorted = List.of(insights)
    ..sort((a, b) => b.magnitude.compareTo(a.magnitude));
  return sorted.take(kMaxInsightsPerPage).toList();
}
