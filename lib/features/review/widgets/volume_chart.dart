import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';

// S12 §12.6.2 — Volume chart: stacked bar, segmented by SkillArea.
// Shade variation: lighter=Transition, darker=Pressure, neutral=Technique.

class VolumeChart extends StatelessWidget {
  final List<SessionWithDrill> sessions;
  final TimeResolution resolution;

  const VolumeChart({
    super.key,
    required this.sessions,
    required this.resolution,
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

    // Build bar groups.
    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      final rodStacks = <BarChartRodStackItem>[];
      var cumulative = 0.0;

      // Stack by SkillArea (7 areas).
      for (final area in SkillArea.values) {
        final count =
            (bucket.bySkillArea[area] ?? 0).toDouble();
        if (count > 0) {
          rodStacks.add(BarChartRodStackItem(
            cumulative,
            cumulative + count,
            _colorForArea(area),
          ));
          cumulative += count;
        }
      }

      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: cumulative,
            rodStackItems: rodStacks,
            width: 12,
            borderRadius:
                BorderRadius.circular(ShapeTokens.radiusGrid / 2),
          ),
        ],
      ));
    }

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Column(
          children: [
        BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
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
                getTitlesWidget: (value, meta) {
                  if (value == value.roundToDouble()) {
                    return Text(
                      value.toInt().toString(),
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
        ),
      ),
            // 7D — Volume chart legend.
            const SizedBox(height: SpacingTokens.sm),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// 7D — Legend mapping each SkillArea colour to its label.
  Widget _buildLegend() {
    return Wrap(
      spacing: SpacingTokens.md,
      runSpacing: SpacingTokens.xs,
      children: [
        for (final area in SkillArea.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _colorForArea(area),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                area.dbValue,
                style: TextStyle(
                  fontSize: TypographyTokens.microSize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<_VolumeBucket> _bucketSessions() {
    if (sessions.isEmpty) return [];

    final sorted = List.of(sessions)
      ..sort((a, b) => (a.session.completionTimestamp ?? DateTime(1970))
          .compareTo(b.session.completionTimestamp ?? DateTime(1970)));

    final buckets = <DateTime, Map<SkillArea, int>>{};

    for (final s in sorted) {
      final ts = s.session.completionTimestamp;
      if (ts == null) continue;
      final key = _bucketKey(ts);
      final area = s.drill.skillArea;
      buckets.putIfAbsent(key, () => {});
      buckets[key]![area] = (buckets[key]![area] ?? 0) + 1;
    }

    final sortedKeys = buckets.keys.toList()..sort();
    return sortedKeys
        .map((k) => _VolumeBucket(date: k, bySkillArea: buckets[k]!))
        .toList();
  }

  DateTime _bucketKey(DateTime ts) {
    switch (resolution) {
      case TimeResolution.daily:
        return DateTime(ts.year, ts.month, ts.day);
      case TimeResolution.weekly:
        final weekday = ts.weekday;
        final monday = ts.subtract(Duration(days: weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case TimeResolution.monthly:
        return DateTime(ts.year, ts.month);
    }
  }

  // S15 — Base colour per SkillArea for volume chart segmentation.
  Color _colorForArea(SkillArea area) {
    return switch (area) {
      SkillArea.driving => const Color(0xFF00B3C6),
      SkillArea.irons => const Color(0xFF1FA463),
      SkillArea.putting => const Color(0xFFF5A623),
      SkillArea.pitching => const Color(0xFF7C4DFF),
      SkillArea.chipping => const Color(0xFFFF6B6B),
      SkillArea.woods => const Color(0xFF4ECDC4),
      SkillArea.bunkers => const Color(0xFFC88719),
    };
  }
}

class _VolumeBucket {
  final DateTime date;
  final Map<SkillArea, int> bySkillArea;

  const _VolumeBucket({
    required this.date,
    required this.bySkillArea,
  });
}
