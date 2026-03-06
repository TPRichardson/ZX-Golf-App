// Phase M9 — Gapping comparison screen.
// Overlay up to 3 runs with comparison ladder and table.
// Spec §7.6.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Per-run averages for a club.
class _RunClubData {
  final String runLabel;
  final double avgCarry;
  final double? avgTotal;

  const _RunClubData({
    required this.runLabel,
    required this.avgCarry,
    this.avgTotal,
  });
}

class GappingComparisonScreen extends ConsumerWidget {
  /// IDs of runs to compare (max 3). Most recent first.
  final List<String> runIds;

  const GappingComparisonScreen({super.key, required this.runIds});

  static const _runColors = [
    ColorTokens.primaryDefault,
    ColorTokens.successDefault,
    ColorTokens.warningIntegrity,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch details for each run.
    final detailsList = runIds
        .map((id) => ref.watch(matrixRunDetailsProvider(id)))
        .toList();

    final allLoaded = detailsList.every((d) => d.hasValue);
    final anyError = detailsList.any((d) => d.hasError);
    final anyLoading = detailsList.any((d) => d.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gapping Comparison'),
        backgroundColor: ColorTokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: ColorTokens.surfaceBase,
      body: anyLoading
          ? const Center(child: CircularProgressIndicator())
          : anyError
              ? const Center(child: Text('Error loading runs'))
              : !allLoaded
                  ? const Center(child: CircularProgressIndicator())
                  : _buildComparison(
                      context,
                      detailsList
                          .map((d) => d.value!)
                          .toList(),
                    ),
    );
  }

  Widget _buildComparison(
      BuildContext context, List<MatrixRunWithDetails> runs) {
    // Build club → list of run data.
    final clubMap = <String, List<_RunClubData>>{};
    final allClubs = <String>[]; // Ordered by first run's carry distance.

    for (int runIdx = 0; runIdx < runs.length; runIdx++) {
      final details = runs[runIdx];
      final valueLabels = <String, String>{};
      for (final a in details.axes) {
        for (final v in a.values) {
          valueLabels[v.axisValueId] = v.label;
        }
      }

      final runLabel = 'Run #${details.run.runNumber}';

      for (final cellData in details.cells) {
        if (cellData.cell.excludedFromRun) continue;
        final attempts = cellData.attempts;
        if (attempts.isEmpty) continue;

        final carryValues = attempts
            .where((a) => a.carryDistanceMeters != null)
            .map((a) => a.carryDistanceMeters!)
            .toList();
        if (carryValues.isEmpty) continue;

        final totalValues = attempts
            .where((a) => a.totalDistanceMeters != null)
            .map((a) => a.totalDistanceMeters!)
            .toList();

        final axisValueIds =
            (jsonDecode(cellData.cell.axisValueIds) as List).cast<String>();
        final label =
            axisValueIds.map((id) => valueLabels[id] ?? id).join(' × ');

        clubMap.putIfAbsent(label, () => []);
        // Ensure list has slots for all runs.
        while (clubMap[label]!.length < runIdx) {
          clubMap[label]!.add(_RunClubData(
            runLabel: 'Run #${runs[clubMap[label]!.length].run.runNumber}',
            avgCarry: 0,
          ));
        }

        clubMap[label]!.add(_RunClubData(
          runLabel: runLabel,
          avgCarry:
              carryValues.reduce((a, b) => a + b) / carryValues.length,
          avgTotal: totalValues.isNotEmpty
              ? totalValues.reduce((a, b) => a + b) / totalValues.length
              : null,
        ));

        if (!allClubs.contains(label)) {
          allClubs.add(label);
        }
      }
    }

    // Sort clubs by first run's carry distance.
    allClubs.sort((a, b) {
      final aCarry = clubMap[a]?.firstOrNull?.avgCarry ?? 0;
      final bCarry = clubMap[b]?.firstOrNull?.avgCarry ?? 0;
      return aCarry.compareTo(bCarry);
    });

    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      children: [
        // Run legend.
        _buildLegend(runs),
        const SizedBox(height: SpacingTokens.lg),

        // §7.6.2 — Comparison ladder.
        _buildComparisonLadder(allClubs, clubMap, runs),
        const SizedBox(height: SpacingTokens.lg),

        // §7.6.3 — Comparison table.
        _buildComparisonTable(allClubs, clubMap, runs),
      ],
    );
  }

  Widget _buildLegend(List<MatrixRunWithDetails> runs) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          for (int i = 0; i < runs.length; i++) ...[
            if (i > 0) const SizedBox(width: SpacingTokens.md),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _runColors[i % _runColors.length],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              'Run #${runs[i].run.runNumber}',
              style: const TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonLadder(
    List<String> clubs,
    Map<String, List<_RunClubData>> clubMap,
    List<MatrixRunWithDetails> runs,
  ) {
    // Find global min/max for bar scaling.
    double minVal = double.infinity;
    double maxVal = 0;
    for (final runDataList in clubMap.values) {
      for (final rd in runDataList) {
        if (rd.avgCarry < minVal) minVal = rd.avgCarry;
        if (rd.avgCarry > maxVal) maxVal = rd.avgCarry;
      }
    }
    final range = maxVal - minVal;
    final effectiveRange = range > 0 ? range : 1.0;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparison Ladder',
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          ...clubs.map((clubLabel) {
            final runData = clubMap[clubLabel] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clubLabel,
                    style: const TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: FontWeight.w500,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ...runData.asMap().entries.map((e) {
                    final runIdx = e.key;
                    final rd = e.value;
                    final fraction =
                        (rd.avgCarry - minVal) / effectiveRange;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth =
                              20 + (constraints.maxWidth - 80) * fraction;
                          return Row(
                            children: [
                              Container(
                                height: 4,
                                width: barWidth.clamp(
                                    20, constraints.maxWidth - 60),
                                decoration: BoxDecoration(
                                  color: _runColors[
                                      runIdx % _runColors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.xs),
                              Text(
                                rd.avgCarry.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: TypographyTokens.microSize,
                                  color: _runColors[
                                      runIdx % _runColors.length],
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(
    List<String> clubs,
    Map<String, List<_RunClubData>> clubMap,
    List<MatrixRunWithDetails> runs,
  ) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparison Table',
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Header.
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Club',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
              // §7.6.3 — Most recent first.
              for (int i = 0; i < runs.length; i++)
                Expanded(
                  flex: 2,
                  child: Text(
                    'Run #${runs[i].run.runNumber}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: TypographyTokens.microSize,
                      fontWeight: FontWeight.w500,
                      color: _runColors[i % _runColors.length],
                    ),
                  ),
                ),
            ],
          ),
          const Divider(color: ColorTokens.surfaceBorder),

          // Rows.
          ...clubs.map((clubLabel) {
            final runData = clubMap[clubLabel] ?? [];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      clubLabel,
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  for (int i = 0; i < runs.length; i++)
                    Expanded(
                      flex: 2,
                      child: Text(
                        i < runData.length
                            ? runData[i].avgCarry.toStringAsFixed(1)
                            : '-',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
