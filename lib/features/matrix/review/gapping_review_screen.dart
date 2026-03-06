// Phase M9 — Gapping Chart review page.
// Shows distance ladder chart + numerical table + gap highlighting.
// Spec §7.4–7.5.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/cell_detail_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Data class for a club's summary in the gapping chart.
class _ClubEntry {
  final String cellId;
  final String label;
  final double avgCarry;
  final double? avgTotal;
  final int shotCount;

  const _ClubEntry({
    required this.cellId,
    required this.label,
    required this.avgCarry,
    this.avgTotal,
    required this.shotCount,
  });
}

/// Gap analysis result.
class _GapInfo {
  final double gap;
  final bool isSmall;
  final bool isLarge;

  const _GapInfo({
    required this.gap,
    this.isSmall = false,
    this.isLarge = false,
  });

  bool get hasWarning => isSmall || isLarge;
}

class GappingReviewScreen extends ConsumerWidget {
  final String matrixRunId;

  const GappingReviewScreen({super.key, required this.matrixRunId});

  // §7.5.1 — Default gap thresholds.
  static const double _defaultMinGap = 6.0;
  static const double _defaultMaxGap = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(matrixRunDetailsProvider(matrixRunId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gapping Chart Review'),
        backgroundColor: ColorTokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: ColorTokens.surfaceBase,
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Run not found'));
          }

          final entries = _buildEntries(details);
          if (entries.isEmpty) {
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

          // §7.4.2 — Order by carry distance.
          entries.sort((a, b) => a.avgCarry.compareTo(b.avgCarry));
          final gaps = _computeGaps(entries);

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
              if (details.run.endTimestamp != null)
                Text(
                  _formatDate(details.run.endTimestamp!),
                  style: const TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              const SizedBox(height: SpacingTokens.lg),

              // §7.4.2 — Distance ladder chart.
              _buildLadderChart(entries, gaps),
              const SizedBox(height: SpacingTokens.lg),

              // §7.4.3 — Numerical table.
              _buildTable(context, entries, gaps, details.run.matrixType),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<_ClubEntry> _buildEntries(MatrixRunWithDetails details) {
    final valueLabels = <String, String>{};
    for (final axisWithValues in details.axes) {
      for (final v in axisWithValues.values) {
        valueLabels[v.axisValueId] = v.label;
      }
    }

    final entries = <_ClubEntry>[];
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

      entries.add(_ClubEntry(
        cellId: cellData.cell.matrixCellId,
        label: label,
        avgCarry:
            carryValues.reduce((a, b) => a + b) / carryValues.length,
        avgTotal: totalValues.isNotEmpty
            ? totalValues.reduce((a, b) => a + b) / totalValues.length
            : null,
        shotCount: attempts.length,
      ));
    }

    return entries;
  }

  /// §7.5.2 — Compute gaps between adjacent clubs (ordered by carry).
  List<_GapInfo?> _computeGaps(List<_ClubEntry> entries) {
    final gaps = <_GapInfo?>[];
    for (int i = 0; i < entries.length; i++) {
      if (i == entries.length - 1) {
        gaps.add(null); // No gap for the last club.
      } else {
        final gap = entries[i + 1].avgCarry - entries[i].avgCarry;
        gaps.add(_GapInfo(
          gap: gap,
          isSmall: gap < _defaultMinGap,
          isLarge: gap > _defaultMaxGap,
        ));
      }
    }
    return gaps;
  }

  Widget _buildLadderChart(List<_ClubEntry> entries, List<_GapInfo?> gaps) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final minCarry = entries.first.avgCarry;
    final maxCarry = entries.last.avgCarry;
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
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final club = entry.value;
            final gap = gaps[index];
            // Bar width proportional to carry distance.
            final fraction =
                (club.avgCarry - minCarry) / effectiveRange;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      club.label,
                      style: const TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final barWidth = 20 +
                            (constraints.maxWidth - 80) * fraction;
                        return Row(
                          children: [
                            Container(
                              height: 6,
                              width: barWidth.clamp(20, constraints.maxWidth - 60),
                              decoration: BoxDecoration(
                                color: gap != null && gap.hasWarning
                                    ? ColorTokens.warningIntegrity
                                    : ColorTokens.primaryDefault,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.xs),
                            Text(
                              club.avgCarry.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: TypographyTokens.microSize,
                                color: ColorTokens.textPrimary,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            if (gap != null && gap.hasWarning) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.warning_amber,
                                size: 12,
                                color: ColorTokens.warningIntegrity,
                              ),
                            ],
                          ],
                        );
                      },
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

  Widget _buildTable(BuildContext context, List<_ClubEntry> entries,
      List<_GapInfo?> gaps, MatrixType matrixType) {
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
            'Distance Table',
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Header row.
          const Row(
            children: [
              Expanded(
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
              Expanded(
                flex: 2,
                child: Text(
                  'Avg Carry',
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
                  'Avg Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Shots',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
              SizedBox(width: 24), // Gap warning icon space.
            ],
          ),
          const Divider(color: ColorTokens.surfaceBorder),

          // Data rows.
          ...entries.asMap().entries.map((entry) {
            final index = entry.key;
            final club = entry.value;
            final gap = gaps[index];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CellDetailScreen(
                      matrixRunId: matrixRunId,
                      cellId: club.cellId,
                      cellLabel: club.label,
                      matrixType: matrixType,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        club.label,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        club.avgCarry.toStringAsFixed(1),
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
                        club.avgTotal?.toStringAsFixed(1) ?? '-',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${club.shotCount}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: gap != null && gap.hasWarning
                          ? Tooltip(
                              message: gap.isSmall
                                  ? 'Small gap (${gap.gap.toStringAsFixed(0)} — min: ${_defaultMinGap.toStringAsFixed(0)})'
                                  : 'Large gap (${gap.gap.toStringAsFixed(0)} — max: ${_defaultMaxGap.toStringAsFixed(0)})',
                              child: Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: ColorTokens.warningIntegrity,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),

          // Gap legend.
          const SizedBox(height: SpacingTokens.sm),
          const Divider(color: ColorTokens.surfaceBorder),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              Icon(Icons.warning_amber,
                  size: 12, color: ColorTokens.warningIntegrity),
              const SizedBox(width: 4),
              Text(
                'Gap < ${_defaultMinGap.toStringAsFixed(0)} or > ${_defaultMaxGap.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: TypographyTokens.microSize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
