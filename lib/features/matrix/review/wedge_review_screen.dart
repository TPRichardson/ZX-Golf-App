// Phase M9 — Wedge Matrix review page.
// Distance ladder with flight colour differentiation and axis filtering.
// Spec §7.7.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/cell_detail_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// A plotted point on the wedge distance ladder.
class _WedgePoint {
  final String cellId;
  final String clubLabel;
  final String effortLabel;
  final String? flightLabel;
  final String fullLabel;
  final double avgCarry;
  final double? avgTotal;
  final int shotCount;
  // Axis value IDs for filtering.
  final Set<String> axisValueIds;

  const _WedgePoint({
    required this.cellId,
    required this.clubLabel,
    required this.effortLabel,
    this.flightLabel,
    required this.fullLabel,
    required this.avgCarry,
    this.avgTotal,
    required this.shotCount,
    required this.axisValueIds,
  });
}

class WedgeReviewScreen extends ConsumerStatefulWidget {
  final String matrixRunId;

  const WedgeReviewScreen({super.key, required this.matrixRunId});

  @override
  ConsumerState<WedgeReviewScreen> createState() => _WedgeReviewScreenState();
}

class _WedgeReviewScreenState extends ConsumerState<WedgeReviewScreen> {
  // §7.7.4 — Filter state: checked axis value IDs.
  final Set<String> _enabledValues = {};
  bool _filtersInitialized = false;

  // §7.7.3 — Flight colour map.
  static const _flightColors = <int, Color>{
    0: ColorTokens.flightLow,
    1: ColorTokens.flightStandard,
    2: ColorTokens.flightHigh,
  };

  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(matrixRunDetailsProvider(widget.matrixRunId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wedge Matrix Review'),
        backgroundColor: ColorTokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: ColorTokens.surfaceBase,
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Run not found'));
          }

          // Initialize filters with all values enabled.
          if (!_filtersInitialized) {
            for (final a in details.axes) {
              for (final v in a.values) {
                _enabledValues.add(v.axisValueId);
              }
            }
            _filtersInitialized = true;
          }

          final points = _buildPoints(details);
          final filteredPoints = points.where((p) {
            return p.axisValueIds.every(
                (id) => _enabledValues.contains(id));
          }).toList();

          // Sort by carry distance.
          filteredPoints.sort((a, b) => a.avgCarry.compareTo(b.avgCarry));

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

              // Flight colour legend.
              _buildFlightLegend(details),
              const SizedBox(height: SpacingTokens.md),

              // §7.7.4 — Filter controls.
              _buildFilters(details),
              const SizedBox(height: SpacingTokens.md),

              // §7.7.2 — Distance ladder.
              _buildLadder(filteredPoints),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<_WedgePoint> _buildPoints(MatrixRunWithDetails details) {
    // Build axis value maps.
    final valueLabels = <String, String>{};
    final valueAxisType = <String, AxisType>{};
    final flightValueOrder = <String, int>{};

    int flightIndex = 0;
    for (final axisWithValues in details.axes) {
      for (final v in axisWithValues.values) {
        valueLabels[v.axisValueId] = v.label;
        valueAxisType[v.axisValueId] = axisWithValues.axis.axisType;
        if (axisWithValues.axis.axisType == AxisType.flight) {
          flightValueOrder[v.axisValueId] = flightIndex++;
        }
      }
    }

    final points = <_WedgePoint>[];
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

      final axisIds =
          (jsonDecode(cellData.cell.axisValueIds) as List).cast<String>();

      String clubLabel = '';
      String effortLabel = '';
      String? flightLabel;

      for (final id in axisIds) {
        final axType = valueAxisType[id];
        final label = valueLabels[id] ?? id;
        if (axType == AxisType.club) {
          clubLabel = label;
        } else if (axType == AxisType.effort) {
          effortLabel = label;
        } else if (axType == AxisType.flight) {
          flightLabel = label;
        }
      }

      final fullLabel = [clubLabel, effortLabel, ?flightLabel]
          .join(' — ');

      points.add(_WedgePoint(
        cellId: cellData.cell.matrixCellId,
        clubLabel: clubLabel,
        effortLabel: effortLabel,
        flightLabel: flightLabel,
        fullLabel: fullLabel,
        avgCarry:
            carryValues.reduce((a, b) => a + b) / carryValues.length,
        avgTotal: totalValues.isNotEmpty
            ? totalValues.reduce((a, b) => a + b) / totalValues.length
            : null,
        shotCount: attempts.length,
        axisValueIds: axisIds.toSet(),
      ));
    }

    return points;
  }

  Widget _buildFlightLegend(MatrixRunWithDetails details) {
    final flightAxis = details.axes
        .where((a) => a.axis.axisType == AxisType.flight)
        .firstOrNull;
    if (flightAxis == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          for (int i = 0; i < flightAxis.values.length; i++) ...[
            if (i > 0) const SizedBox(width: SpacingTokens.md),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _flightColors[i % _flightColors.length] ??
                    ColorTokens.primaryDefault,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              flightAxis.values[i].label,
              style: const TextStyle(
                fontSize: TypographyTokens.bodySmSize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters(MatrixRunWithDetails details) {
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
            'Filter',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          for (final axisWithValues in details.axes)
            _buildAxisFilter(axisWithValues),
        ],
      ),
    );
  }

  Widget _buildAxisFilter(MatrixAxisWithValues axisWithValues) {
    final axisLabel = axisWithValues.axis.axisType.dbValue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          axisLabel,
          style: const TextStyle(
            fontSize: TypographyTokens.bodySmSize,
            color: ColorTokens.textTertiary,
          ),
        ),
        Wrap(
          spacing: SpacingTokens.xs,
          children: axisWithValues.values.map((v) {
            final enabled = _enabledValues.contains(v.axisValueId);
            return FilterChip(
              label: Text(v.label),
              selected: enabled,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _enabledValues.add(v.axisValueId);
                  } else {
                    _enabledValues.remove(v.axisValueId);
                  }
                });
              },
              selectedColor: ColorTokens.primaryDefault.withValues(alpha: 0.2),
              backgroundColor: ColorTokens.surfaceBase,
              labelStyle: TextStyle(
                fontSize: TypographyTokens.bodySmSize,
                color: enabled
                    ? ColorTokens.primaryDefault
                    : ColorTokens.textTertiary,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: SpacingTokens.xs),
      ],
    );
  }

  Widget _buildLadder(List<_WedgePoint> points) {
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: const Center(
          child: Text(
            'No matching data',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textTertiary,
            ),
          ),
        ),
      );
    }

    final minCarry = points.first.avgCarry;
    final maxCarry = points.last.avgCarry;
    final range = maxCarry - minCarry;
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
            'Distance Ladder',
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          ...points.map((pt) {
            final fraction =
                (pt.avgCarry - minCarry) / effectiveRange;

            // Determine colour from flight label index.
            Color pointColor = ColorTokens.primaryDefault;
            if (pt.flightLabel != null) {
              // Use simple heuristic: match by common flight names.
              final lower = pt.flightLabel!.toLowerCase();
              if (lower.contains('low')) {
                pointColor = _flightColors[0]!;
              } else if (lower.contains('standard') ||
                  lower.contains('mid')) {
                pointColor = _flightColors[1]!;
              } else if (lower.contains('high')) {
                pointColor = _flightColors[2]!;
              }
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CellDetailScreen(
                      matrixRunId: widget.matrixRunId,
                      cellId: pt.cellId,
                      cellLabel: pt.fullLabel,
                      matrixType: MatrixType.wedgeMatrix,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        pt.fullLabel,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: ColorTokens.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final offset =
                              (constraints.maxWidth - 50) * fraction;
                          return Stack(
                            children: [
                              // Baseline.
                              Container(
                                height: 1,
                                margin: const EdgeInsets.only(top: 5),
                                color: ColorTokens.surfaceBorder,
                              ),
                              // Point.
                              Positioned(
                                left: offset.clamp(
                                    0, constraints.maxWidth - 50),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: pointColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        pt.avgCarry.toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: pointColor,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
