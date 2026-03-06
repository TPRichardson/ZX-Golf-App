import 'dart:convert';

import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/analytics/analytics_types.dart';
import 'package:zx_golf_app/features/matrix/analytics/outlier_trimmer.dart';
import 'package:zx_golf_app/features/matrix/analytics/weighted_aggregator.dart';

// Phase M10 — Matrix analytics engine (§9.5–9.9).
// Pure functions — no database or provider dependencies.

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// A single attempt tagged with its parent run's weight.
class _TaggedAttempt {
  final double carry;
  final double? total;
  final double? rollout;
  final double weight;
  final String matrixRunId;

  const _TaggedAttempt({
    required this.carry,
    this.total,
    this.rollout,
    required this.weight,
    required this.matrixRunId,
  });
}

/// Canonical cell key from the cell's axisValueIds JSON.
String _cellKey(MatrixCellWithAttempts cwa) => cwa.cell.axisValueIds;

/// Builds a value-id → label lookup map across all axes in a run.
Map<String, String> _valueLabelMap(MatrixRunWithDetails run) {
  final map = <String, String>{};
  for (final aw in run.axes) {
    for (final v in aw.values) {
      map[v.axisValueId] = v.label;
    }
  }
  return map;
}

/// Collects all tagged attempts for cells matching [matchKey] across [runs].
///
/// If [weighted] is true, each attempt gets the weight of its parent run
/// based on age relative to [referenceDate]. If false, all weights are 1.0.
///
/// Spec: §9.3.2 — Cells with excludedFromRun are skipped.
/// Spec: §9.3.1 — Minimum 3 attempts enforced by caller.
List<_TaggedAttempt> _collectAttempts(
  List<MatrixRunWithDetails> runs,
  String matchKey,
  DateTime referenceDate,
  bool weighted,
) {
  final tagged = <_TaggedAttempt>[];
  for (final run in runs) {
    final ageDays =
        referenceDate.difference(run.run.startTimestamp).inDays;
    final w = weighted ? computeWeight(ageDays) : 1.0;
    for (final cwa in run.cells) {
      if (cwa.cell.excludedFromRun) continue;
      if (_cellKey(cwa) != matchKey) continue;
      for (final a in cwa.attempts) {
        tagged.add(_TaggedAttempt(
          carry: a.carryDistanceMeters ?? 0.0,
          total: a.totalDistanceMeters,
          rollout: a.rolloutDistanceMeters,
          weight: w,
          matrixRunId: run.run.matrixRunId,
        ));
      }
    }
  }
  return tagged;
}

/// Trims tagged attempts by carry distance and returns surviving attempts.
List<_TaggedAttempt> _trimTagged(List<_TaggedAttempt> attempts) {
  if (attempts.length < 3) return attempts;
  final sorted = List.of(attempts)..sort((a, b) => a.carry.compareTo(b.carry));
  final trimCount = (sorted.length * 0.10).round();
  if (trimCount == 0) return sorted;
  if (trimCount * 2 >= sorted.length) return sorted;
  return sorted.sublist(trimCount, sorted.length - trimCount);
}

/// Counts distinct run IDs in a list of tagged attempts.
int _distinctRuns(List<_TaggedAttempt> attempts) {
  return attempts.map((a) => a.matrixRunId).toSet().length;
}

/// Computes weighted or raw average of a double field from tagged attempts.
double _avg(List<_TaggedAttempt> attempts, double Function(_TaggedAttempt) f) {
  if (attempts.isEmpty) return 0.0;
  final values = attempts.map(f).toList();
  final weights = attempts.map((a) => a.weight).toList();
  return weightedAverage(values, weights);
}

// ---------------------------------------------------------------------------
// §9.6 — Club Distance Analytics (Gapping)
// ---------------------------------------------------------------------------

/// Computes per-club distance analytics from gapping chart runs.
///
/// Spec: §9.6.1 — Average Carry, Average Total, Carry Consistency, Distance
/// Gap, Data Sources per club.
///
/// Returns results sorted by ascending avgCarry with gaps computed between
/// adjacent clubs (§9.6.4).
List<ClubDistanceResult> clubDistanceAnalytics(
  List<MatrixRunWithDetails> runs, {
  bool weighted = true,
  DateTime? referenceDate,
}) {
  if (runs.isEmpty) return [];
  final refDate = referenceDate ?? DateTime.now();

  // Build unified value-label map from all runs.
  final labelMap = <String, String>{};
  for (final run in runs) {
    labelMap.addAll(_valueLabelMap(run));
  }

  // Discover all unique cell keys (one per club in gapping).
  final cellKeys = <String>{};
  for (final run in runs) {
    for (final cwa in run.cells) {
      if (!cwa.cell.excludedFromRun) {
        cellKeys.add(_cellKey(cwa));
      }
    }
  }

  // Build per-club results.
  final results = <ClubDistanceResult>[];
  for (final key in cellKeys) {
    final attempts = _collectAttempts(runs, key, refDate, weighted);
    if (attempts.length < 3) continue; // §9.3.1
    final trimmed = _trimTagged(attempts);
    if (trimmed.isEmpty) continue;

    final carries = trimmed.map((a) => a.carry).toList();
    final totals = trimmed
        .where((a) => a.total != null)
        .map((a) => a.total!)
        .toList();

    // Resolve club label from axisValueIds.
    final ids = (jsonDecode(key) as List).cast<String>();
    final label = ids.map((id) => labelMap[id] ?? id).join(' ');

    results.add(ClubDistanceResult(
      clubLabel: label,
      axisValueId: ids.isNotEmpty ? ids.first : key,
      avgCarry: _avg(trimmed, (a) => a.carry),
      avgTotal: totals.isEmpty
          ? 0.0
          : _avg(
              trimmed.where((a) => a.total != null).toList(),
              (a) => a.total!,
            ),
      carryConsistency: standardDeviation(carries),
      distanceGap: null, // Filled below after sorting.
      dataSources: _distinctRuns(trimmed),
      attemptCount: trimmed.length,
    ));
  }

  // Sort by avgCarry ascending.
  results.sort((a, b) => a.avgCarry.compareTo(b.avgCarry));

  // Compute gaps between adjacent clubs (§9.6.4).
  final withGaps = <ClubDistanceResult>[];
  for (var i = 0; i < results.length; i++) {
    final gap =
        i < results.length - 1 ? results[i + 1].avgCarry - results[i].avgCarry : null;
    withGaps.add(ClubDistanceResult(
      clubLabel: results[i].clubLabel,
      axisValueId: results[i].axisValueId,
      avgCarry: results[i].avgCarry,
      avgTotal: results[i].avgTotal,
      carryConsistency: results[i].carryConsistency,
      distanceGap: gap,
      dataSources: results[i].dataSources,
      attemptCount: results[i].attemptCount,
    ));
  }

  return withGaps;
}

// ---------------------------------------------------------------------------
// §9.7 — Wedge Coverage Analytics
// ---------------------------------------------------------------------------

/// Computes per-cell coverage analytics from wedge matrix runs.
///
/// Spec: §9.7.1 — Each cell with sufficient data contributes one coverage
/// point at its average carry distance.
List<WedgeCoverageResult> wedgeCoverageAnalytics(
  List<MatrixRunWithDetails> runs, {
  bool weighted = true,
  DateTime? referenceDate,
}) {
  if (runs.isEmpty) return [];
  final refDate = referenceDate ?? DateTime.now();

  final labelMap = <String, String>{};
  for (final run in runs) {
    labelMap.addAll(_valueLabelMap(run));
  }

  // Discover flight axis value IDs across all runs.
  final flightValueIds = <String>{};
  for (final run in runs) {
    for (final aw in run.axes) {
      if (aw.axis.axisType == AxisType.flight) {
        for (final v in aw.values) {
          flightValueIds.add(v.axisValueId);
        }
      }
    }
  }

  final cellKeys = <String>{};
  for (final run in runs) {
    for (final cwa in run.cells) {
      if (!cwa.cell.excludedFromRun) cellKeys.add(_cellKey(cwa));
    }
  }

  final results = <WedgeCoverageResult>[];
  for (final key in cellKeys) {
    final attempts = _collectAttempts(runs, key, refDate, weighted);
    if (attempts.length < 3) continue;
    final trimmed = _trimTagged(attempts);
    if (trimmed.isEmpty) continue;

    final carries = trimmed.map((a) => a.carry).toList();
    final ids = (jsonDecode(key) as List).cast<String>();
    final label = ids.map((id) => labelMap[id] ?? id).join(' — ');

    // Determine flight label.
    var flightLabel = '';
    for (final id in ids) {
      if (flightValueIds.contains(id)) {
        flightLabel = labelMap[id] ?? id;
        break;
      }
    }

    results.add(WedgeCoverageResult(
      cellLabel: label,
      cellKey: key,
      flightLabel: flightLabel,
      avgCarry: _avg(trimmed, (a) => a.carry),
      carryConsistency: standardDeviation(carries),
      dataSources: _distinctRuns(trimmed),
      attemptCount: trimmed.length,
    ));
  }

  results.sort((a, b) => a.avgCarry.compareTo(b.avgCarry));
  return results;
}

// ---------------------------------------------------------------------------
// §9.8 — Chipping Accuracy Analytics
// ---------------------------------------------------------------------------

/// Computes per-cell accuracy analytics from chipping matrix runs.
///
/// Spec: §9.8.1 — Average Carry, Average Error, Average Rollout, Average
/// Total, Short Bias, Carry Consistency, Data Sources per cell.
List<ChippingAccuracyResult> chippingAccuracyAnalytics(
  List<MatrixRunWithDetails> runs, {
  bool weighted = true,
  DateTime? referenceDate,
}) {
  if (runs.isEmpty) return [];
  final refDate = referenceDate ?? DateTime.now();

  final labelMap = <String, String>{};
  for (final run in runs) {
    labelMap.addAll(_valueLabelMap(run));
  }

  // Discover carryDistance axis values for target resolution.
  final distanceValueLabels = <String, String>{};
  final clubValueIds = <String>{};
  for (final run in runs) {
    for (final aw in run.axes) {
      if (aw.axis.axisType == AxisType.carryDistance) {
        for (final v in aw.values) {
          distanceValueLabels[v.axisValueId] = v.label;
        }
      }
      if (aw.axis.axisType == AxisType.club) {
        for (final v in aw.values) {
          clubValueIds.add(v.axisValueId);
        }
      }
    }
  }

  final cellKeys = <String>{};
  for (final run in runs) {
    for (final cwa in run.cells) {
      if (!cwa.cell.excludedFromRun) cellKeys.add(_cellKey(cwa));
    }
  }

  final results = <ChippingAccuracyResult>[];
  for (final key in cellKeys) {
    final attempts = _collectAttempts(runs, key, refDate, weighted);
    if (attempts.length < 3) continue;
    final trimmed = _trimTagged(attempts);
    if (trimmed.isEmpty) continue;

    final ids = (jsonDecode(key) as List).cast<String>();
    final label = ids.map((id) => labelMap[id] ?? id).join(' — ');

    // Resolve target distance from carryDistance axis value.
    double targetDist = 0;
    String clubLabel = '';
    for (final id in ids) {
      if (distanceValueLabels.containsKey(id)) {
        targetDist = double.tryParse(distanceValueLabels[id]!) ?? 0;
      }
      if (clubValueIds.contains(id)) {
        clubLabel = labelMap[id] ?? id;
      }
    }

    final carries = trimmed.map((a) => a.carry).toList();
    final errors = trimmed.map((a) => (a.carry - targetDist).abs()).toList();
    final errorWeights = trimmed.map((a) => a.weight).toList();

    final rolloutAttempts = trimmed.where((a) => a.rollout != null).toList();
    final shortCount = trimmed.where((a) => a.carry < targetDist).length;

    results.add(ChippingAccuracyResult(
      cellLabel: label,
      cellKey: key,
      clubLabel: clubLabel,
      targetDistance: targetDist,
      avgCarry: _avg(trimmed, (a) => a.carry),
      avgError: weightedAverage(errors, errorWeights),
      avgRollout: rolloutAttempts.isEmpty
          ? 0.0
          : _avg(rolloutAttempts, (a) => a.rollout!),
      avgTotal: _avg(
        trimmed.where((a) => a.total != null).toList(),
        (a) => a.total!,
      ),
      shortBias: trimmed.isEmpty ? 0.0 : shortCount / trimmed.length,
      carryConsistency: standardDeviation(carries),
      dataSources: _distinctRuns(trimmed),
      attemptCount: trimmed.length,
    ));
  }

  results.sort((a, b) => a.targetDistance.compareTo(b.targetDistance));
  return results;
}

/// Computes aggregated accuracy overview rows (§9.8.2).
///
/// Groups [results] by target distance and averages error / short bias.
List<AccuracyOverviewRow> chippingAccuracyOverview(
  List<ChippingAccuracyResult> results,
) {
  final byTarget = <double, List<ChippingAccuracyResult>>{};
  for (final r in results) {
    byTarget.putIfAbsent(r.targetDistance, () => []).add(r);
  }

  final rows = <AccuracyOverviewRow>[];
  for (final entry in byTarget.entries) {
    final group = entry.value;
    final avgErr =
        group.map((r) => r.avgError).reduce((a, b) => a + b) / group.length;
    final avgBias =
        group.map((r) => r.shortBias).reduce((a, b) => a + b) / group.length;
    rows.add(AccuracyOverviewRow(
      targetDistance: entry.key,
      avgError: avgErr,
      shortBias: avgBias,
    ));
  }
  rows.sort((a, b) => a.targetDistance.compareTo(b.targetDistance));
  return rows;
}

// ---------------------------------------------------------------------------
// §9.9 — Distance Trend Analytics
// ---------------------------------------------------------------------------

/// Computes per-run trend points for a specific cell across runs.
///
/// Spec: §9.9.2 — Each point is the per-run average carry for that cell,
/// calculated from the trimmed attempt dataset for that run only.
///
/// If [weighted] is true, the per-run average uses the run's weight. In raw
/// mode (§9.4.4), each run's average is unweighted.
List<TrendPoint> distanceTrend(
  List<MatrixRunWithDetails> runs,
  String cellKey, {
  bool weighted = true,
  DateTime? referenceDate,
}) {
  final points = <TrendPoint>[];

  for (final run in runs) {
    for (final cwa in run.cells) {
      if (cwa.cell.excludedFromRun) continue;
      if (_cellKey(cwa) != cellKey) continue;
      if (cwa.attempts.length < 3) continue; // §9.3.1 / §9.9.1

      final carries =
          cwa.attempts.map((a) => a.carryDistanceMeters ?? 0.0).toList();
      final trimmed = trimOutliers(carries);
      if (trimmed.isEmpty) continue;

      final avgCarry = rawAverage(trimmed);

      // Rollout average for chipping trends (§9.9.3).
      double? avgRollout;
      final rollouts = cwa.attempts
          .where((a) => a.rolloutDistanceMeters != null)
          .map((a) => a.rolloutDistanceMeters!)
          .toList();
      if (rollouts.length >= 3) {
        avgRollout = rawAverage(trimOutliers(rollouts));
      }

      points.add(TrendPoint(
        matrixRunId: run.run.matrixRunId,
        timestamp: run.run.startTimestamp,
        avgCarry: avgCarry,
        avgRollout: avgRollout,
      ));
    }
  }

  points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return points;
}
