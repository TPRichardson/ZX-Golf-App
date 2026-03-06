// Phase M9 — Chipping Matrix review page.
// Distance accuracy overview + expandable club sections + accuracy metrics.
// Spec §7.8.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/cell_detail_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Parsed cell data for chipping review.
class _ChipCell {
  final String cellId;
  final String clubLabel;
  final String distanceLabel;
  final String? flightLabel;
  final String fullLabel;
  final double? targetDistance; // Parsed from distanceLabel.
  final double avgCarry;
  final double avgError;
  final double? avgRollout;
  final double? avgTotal;
  final double shortBias; // 0–1.
  final int shotCount;

  const _ChipCell({
    required this.cellId,
    required this.clubLabel,
    required this.distanceLabel,
    this.flightLabel,
    required this.fullLabel,
    this.targetDistance,
    required this.avgCarry,
    required this.avgError,
    this.avgRollout,
    this.avgTotal,
    required this.shortBias,
    required this.shotCount,
  });
}

class ChippingReviewScreen extends ConsumerStatefulWidget {
  final String matrixRunId;

  const ChippingReviewScreen({super.key, required this.matrixRunId});

  @override
  ConsumerState<ChippingReviewScreen> createState() =>
      _ChippingReviewScreenState();
}

class _ChippingReviewScreenState extends ConsumerState<ChippingReviewScreen> {
  final Set<String> _expandedClubs = {};

  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(matrixRunDetailsProvider(widget.matrixRunId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chipping Matrix Review'),
        backgroundColor: ColorTokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: ColorTokens.surfaceBase,
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Run not found'));
          }

          final cells = _buildCells(details);
          if (cells.isEmpty) {
            return const Center(
              child: Text(
                'No data recorded',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            );
          }

          // Group by distance target for the accuracy overview.
          final byDistance = <String, List<_ChipCell>>{};
          for (final c in cells) {
            byDistance.putIfAbsent(c.distanceLabel, () => []).add(c);
          }

          // Group by club for the club sections.
          final byClub = <String, List<_ChipCell>>{};
          for (final c in cells) {
            byClub.putIfAbsent(c.clubLabel, () => []).add(c);
          }

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              // Run header.
              Text(
                'Run #${details.run.runNumber}',
                style: const TextStyle(
                  fontSize: TypographyTokens.headerSize,
                  fontWeight: TypographyTokens.headerWeight,
                  color: ColorTokens.textPrimary,
                ),
              ),
              const SizedBox(height: SpacingTokens.lg),

              // §7.8.4 — Distance Accuracy Overview.
              _buildAccuracyOverview(byDistance),
              const SizedBox(height: SpacingTokens.lg),

              // §7.8.5 — Club sections.
              ...byClub.entries.map((entry) =>
                  _buildClubSection(entry.key, entry.value)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<_ChipCell> _buildCells(MatrixRunWithDetails details) {
    final valueLabels = <String, String>{};
    final valueAxisType = <String, AxisType>{};
    for (final axisWithValues in details.axes) {
      for (final v in axisWithValues.values) {
        valueLabels[v.axisValueId] = v.label;
        valueAxisType[v.axisValueId] = axisWithValues.axis.axisType;
      }
    }

    final cells = <_ChipCell>[];
    for (final cellData in details.cells) {
      if (cellData.cell.excludedFromRun) continue;
      final attempts = cellData.attempts;
      if (attempts.isEmpty) continue;

      final axisIds =
          (jsonDecode(cellData.cell.axisValueIds) as List).cast<String>();

      String clubLabel = '';
      String distanceLabel = '';
      String? flightLabel;

      for (final id in axisIds) {
        final axType = valueAxisType[id];
        final label = valueLabels[id] ?? id;
        if (axType == AxisType.club) {
          clubLabel = label;
        } else if (axType == AxisType.carryDistance) {
          distanceLabel = label;
        } else if (axType == AxisType.flight) {
          flightLabel = label;
        }
      }

      final fullLabel = [
        clubLabel,
        distanceLabel,
        if (flightLabel != null) flightLabel,
      ].join(' — ');

      // Parse target distance from label (e.g. "10" or "10y").
      final targetDistance =
          double.tryParse(distanceLabel.replaceAll(RegExp(r'[^\d.]'), ''));

      final carryValues = attempts
          .where((a) => a.carryDistanceMeters != null)
          .map((a) => a.carryDistanceMeters!)
          .toList();
      final totalValues = attempts
          .where((a) => a.totalDistanceMeters != null)
          .map((a) => a.totalDistanceMeters!)
          .toList();
      final rolloutValues = attempts
          .where((a) => a.rolloutDistanceMeters != null)
          .map((a) => a.rolloutDistanceMeters!)
          .toList();

      if (carryValues.isEmpty) continue;

      final avgCarry =
          carryValues.reduce((a, b) => a + b) / carryValues.length;
      final avgTotal = totalValues.isNotEmpty
          ? totalValues.reduce((a, b) => a + b) / totalValues.length
          : null;
      final avgRollout = rolloutValues.isNotEmpty
          ? rolloutValues.reduce((a, b) => a + b) / rolloutValues.length
          : null;

      // §7.8.6 — Average error = mean |carry − target|.
      double avgError = 0;
      if (targetDistance != null) {
        avgError = carryValues
                .map((c) => (c - targetDistance).abs())
                .reduce((a, b) => a + b) /
            carryValues.length;
      }

      // §7.8.6 — Short bias = % of attempts finishing short of target.
      double shortBias = 0;
      if (targetDistance != null && carryValues.isNotEmpty) {
        final shortCount =
            carryValues.where((c) => c < targetDistance).length;
        shortBias = shortCount / carryValues.length;
      }

      cells.add(_ChipCell(
        cellId: cellData.cell.matrixCellId,
        clubLabel: clubLabel,
        distanceLabel: distanceLabel,
        flightLabel: flightLabel,
        fullLabel: fullLabel,
        targetDistance: targetDistance,
        avgCarry: avgCarry,
        avgError: avgError,
        avgRollout: avgRollout,
        avgTotal: avgTotal,
        shortBias: shortBias,
        shotCount: carryValues.length,
      ));
    }

    return cells;
  }

  /// §7.8.4 — Distance Accuracy Overview table.
  Widget _buildAccuracyOverview(Map<String, List<_ChipCell>> byDistance) {
    // Sort distance labels numerically.
    final sortedKeys = byDistance.keys.toList()
      ..sort((a, b) {
        final da = double.tryParse(a.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        final db = double.tryParse(b.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
        return da.compareTo(db);
      });

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
            'Distance Accuracy Overview',
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Header.
          const Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Target',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Avg Error',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Short Bias',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: ColorTokens.surfaceBorder),

          // Rows.
          ...sortedKeys.map((distLabel) {
            final cells = byDistance[distLabel]!;
            // Aggregate across all clubs/flights for this distance.
            double totalError = 0;
            double totalShort = 0;
            int count = 0;
            for (final c in cells) {
              totalError += c.avgError * c.shotCount;
              totalShort += c.shortBias * c.shotCount;
              count += c.shotCount;
            }
            final aggError = count > 0 ? totalError / count : 0;
            final aggShort = count > 0 ? totalShort / count : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      distLabel,
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      aggError.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${(aggShort * 100).toStringAsFixed(0)}%',
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

  /// §7.8.5 — Expandable club section.
  Widget _buildClubSection(String clubLabel, List<_ChipCell> cells) {
    final isExpanded = _expandedClubs.contains(clubLabel);

    // Group by distance within club.
    final byDistance = <String, List<_ChipCell>>{};
    for (final c in cells) {
      byDistance.putIfAbsent(c.distanceLabel, () => []).add(c);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        children: [
          // Tap to expand/collapse.
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedClubs.remove(clubLabel);
                } else {
                  _expandedClubs.add(clubLabel);
                }
              });
            },
            borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                    color: ColorTokens.textSecondary,
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    clubLabel,
                    style: const TextStyle(
                      fontSize: TypographyTokens.bodyLgSize,
                      fontWeight: FontWeight.w500,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${cells.length} cells',
                    style: const TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(
                color: ColorTokens.surfaceBorder, height: 1),
            // Distance groups within club.
            for (final distEntry in byDistance.entries)
              _buildDistanceGroup(distEntry.key, distEntry.value),
          ],
        ],
      ),
    );
  }

  Widget _buildDistanceGroup(String distLabel, List<_ChipCell> cells) {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$distLabel Target',
            style: const TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Flight cells side by side.
          Wrap(
            spacing: SpacingTokens.sm,
            runSpacing: SpacingTokens.sm,
            children: cells.map((c) => _buildCellCard(c)).toList(),
          ),
        ],
      ),
    );
  }

  /// §7.8.6 — Accuracy metrics card for a single cell.
  Widget _buildCellCard(_ChipCell cell) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CellDetailScreen(
              matrixRunId: widget.matrixRunId,
              cellId: cell.cellId,
              cellLabel: cell.fullLabel,
              matrixType: MatrixType.chippingMatrix,
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceBase,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cell.flightLabel ?? 'Standard',
              style: const TextStyle(
                fontSize: TypographyTokens.microSize,
                fontWeight: FontWeight.w500,
                color: ColorTokens.primaryDefault,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            _metricLine('Avg Carry', cell.avgCarry.toStringAsFixed(1)),
            _metricLine('Avg Error', cell.avgError.toStringAsFixed(2)),
            if (cell.avgRollout != null)
              _metricLine(
                  'Avg Rollout', cell.avgRollout!.toStringAsFixed(1)),
            _metricLine(
                'Short Bias', '${(cell.shortBias * 100).toStringAsFixed(0)}%'),
            _metricLine('Attempts', '${cell.shotCount}'),
          ],
        ),
      ),
    );
  }

  Widget _metricLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              color: ColorTokens.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
