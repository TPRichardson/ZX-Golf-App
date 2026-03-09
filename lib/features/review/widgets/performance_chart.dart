import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';

// S05 §5.2 — Performance chart: line chart, 0–5 Y-axis.
// Rolling overlay: Daily=7-bucket, Weekly=4-bucket, Monthly=none.

class PerformanceChart extends StatelessWidget {
  final List<SessionWithDrill> sessions;
  final TimeResolution resolution;
  /// Session score lookup — sessionId → 0–5 score from window entries.
  final Map<String, double> sessionScoreMap;

  const PerformanceChart({
    super.key,
    required this.sessions,
    required this.resolution,
    this.sessionScoreMap = const {},
  });

  @override
  Widget build(BuildContext context) {
    final buckets = _bucketSessions();
    if (buckets.isEmpty) {
      return Center(
        child: Text(
          'No data for chart',
          style: TextStyle(
            fontSize: TypographyTokens.bodySize,
            color: ColorTokens.textTertiary,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < buckets.length; i++) {
      spots.add(FlSpot(i.toDouble(), scoreToStars(buckets[i].averageScore)));
    }

    // Rolling average overlay.
    final rollingSpots = _computeRolling(buckets);

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: LineChart(
        LineChartData(
          minY: 1,
          maxY: 5,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(
              color: ColorTokens.surfaceBorder,
              strokeWidth: 0.5,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value == value.roundToDouble() &&
                      value >= 1 &&
                      value <= 5) {
                    return Text(
                      '${value.toInt()}\u2605',
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.textTertiary,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            // Raw data line.
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: ColorTokens.primaryDefault.withValues(alpha: 0.4),
              dotData: const FlDotData(show: false),
              barWidth: 1,
              belowBarData: BarAreaData(show: false),
            ),
            // Rolling average overlay.
            if (rollingSpots.isNotEmpty)
              LineChartBarData(
                spots: rollingSpots,
                isCurved: true,
                color: ColorTokens.primaryDefault,
                dotData: const FlDotData(show: false),
                barWidth: 2,
                belowBarData: BarAreaData(show: false),
              ),
          ],
        ),
      ),
    ),
    );
  }

  List<_Bucket> _bucketSessions() {
    if (sessions.isEmpty) return [];

    // Sort by completion timestamp.
    final sorted = List.of(sessions)
      ..sort((a, b) => (a.session.completionTimestamp ?? DateTime(1970))
          .compareTo(b.session.completionTimestamp ?? DateTime(1970)));

    final buckets = <DateTime, List<double>>{};

    for (final s in sorted) {
      final ts = s.session.completionTimestamp;
      if (ts == null) continue;
      final key = _bucketKey(ts);
      final score = sessionScoreMap[s.session.sessionId] ?? 0.0;
      buckets.putIfAbsent(key, () => []).add(score);
    }

    final sortedKeys = buckets.keys.toList()..sort();
    return sortedKeys.map((k) {
      final scores = buckets[k]!;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return _Bucket(date: k, averageScore: avg, count: scores.length);
    }).toList();
  }

  DateTime _bucketKey(DateTime ts) {
    switch (resolution) {
      case TimeResolution.daily:
        return DateTime(ts.year, ts.month, ts.day);
      case TimeResolution.weekly:
        // ISO week: Monday-based.
        final weekday = ts.weekday;
        final monday = ts.subtract(Duration(days: weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case TimeResolution.monthly:
        return DateTime(ts.year, ts.month);
    }
  }

  List<FlSpot> _computeRolling(List<_Bucket> buckets) {
    final window = switch (resolution) {
      TimeResolution.daily => 7,
      TimeResolution.weekly => 4,
      TimeResolution.monthly => 0,
    };

    if (window == 0 || buckets.length < window) return [];

    final spots = <FlSpot>[];
    for (var i = window - 1; i < buckets.length; i++) {
      var sum = 0.0;
      for (var j = i - window + 1; j <= i; j++) {
        sum += buckets[j].averageScore;
      }
      spots.add(FlSpot(i.toDouble(), scoreToStars(sum / window)));
    }
    return spots;
  }
}

class _Bucket {
  final DateTime date;
  final double averageScore;
  final int count;

  const _Bucket({
    required this.date,
    required this.averageScore,
    required this.count,
  });
}
