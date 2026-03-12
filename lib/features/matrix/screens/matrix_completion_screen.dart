// Phase M5 — Matrix run completion screen.
// Matrix §6.7 — Post-completion summary with snapshot creation option.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

/// Matrix §6.7 — Completion summary for a finished matrix run.
/// Shows per-club averages and option to create a performance snapshot.
class MatrixCompletionScreen extends ConsumerStatefulWidget {
  final String matrixRunId;
  final String userId;

  const MatrixCompletionScreen({
    super.key,
    required this.matrixRunId,
    required this.userId,
  });

  @override
  ConsumerState<MatrixCompletionScreen> createState() =>
      _MatrixCompletionScreenState();
}

class _MatrixCompletionScreenState
    extends ConsumerState<MatrixCompletionScreen> {
  bool _creatingSnapshot = false;
  bool _snapshotCreated = false;
  final _labelController = TextEditingController();
  bool _setAsPrimary = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _createSnapshot() async {
    if (_creatingSnapshot) return;
    setState(() => _creatingSnapshot = true);

    try {
      await ref.read(matrixActionsProvider).createSnapshotFromRun(
            widget.matrixRunId,
            widget.userId,
            label: _labelController.text.trim().isNotEmpty
                ? _labelController.text.trim()
                : null,
            setAsPrimary: _setAsPrimary,
          );
      if (mounted) {
        setState(() {
          _snapshotCreated = true;
          _creatingSnapshot = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creatingSnapshot = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _done() {
    ref.read(showHomeProvider.notifier).state = true;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  /// Compute per-club averages from cell attempts.
  List<_ClubSummary> _computeClubSummaries(MatrixRunWithDetails details) {
    final summaries = <_ClubSummary>[];

    // Build axis value ID → label map.
    final valueLabels = <String, String>{};
    for (final axisWithValues in details.axes) {
      for (final v in axisWithValues.values) {
        valueLabels[v.axisValueId] = v.label;
      }
    }

    for (final cellWithAttempts in details.cells) {
      if (cellWithAttempts.cell.excludedFromRun) continue;

      final axisValueIds =
          (jsonDecode(cellWithAttempts.cell.axisValueIds) as List)
              .cast<String>();
      final label = axisValueIds
          .map((id) => valueLabels[id] ?? id)
          .join(' × ');

      final attempts = cellWithAttempts.attempts;
      if (attempts.isEmpty) continue;

      final carryValues = attempts
          .where((a) => a.carryDistanceMeters != null)
          .map((a) => a.carryDistanceMeters!)
          .toList();
      final totalValues = attempts
          .where((a) => a.totalDistanceMeters != null)
          .map((a) => a.totalDistanceMeters!)
          .toList();

      summaries.add(_ClubSummary(
        label: label,
        attemptCount: attempts.length,
        avgCarry: carryValues.isNotEmpty
            ? carryValues.reduce((a, b) => a + b) / carryValues.length
            : null,
        avgTotal: totalValues.isNotEmpty
            ? totalValues.reduce((a, b) => a + b) / totalValues.length
            : null,
      ));
    }

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(matrixRunDetailsProvider(widget.matrixRunId));

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: detailsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (details) {
            if (details == null) {
              return const Center(child: Text('Run not found'));
            }
            return _buildContent(details);
          },
        ),
      ),
    );
  }

  Widget _buildContent(MatrixRunWithDetails details) {
    final summaries = _computeClubSummaries(details);

    return Column(
      children: [
        // Header.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.md,
          ),
          decoration: const BoxDecoration(
            color: ColorTokens.surfaceRaised,
            border: Border(
              bottom: BorderSide(color: ColorTokens.surfaceBorder),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Run Complete',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    color: ColorTokens.textSecondary),
                onPressed: _done,
              ),
            ],
          ),
        ),

        // Scrollable content.
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Run info.
                Text(
                  'Run #${details.run.runNumber}',
                  style: const TextStyle(
                    fontSize: TypographyTokens.displayLgSize,
                    fontWeight: TypographyTokens.displayLgWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.lg),

                // Club distance table.
                const Text(
                  'Distance Summary',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                _buildDistanceTable(summaries),

                const SizedBox(height: SpacingTokens.xl),

                // Snapshot creation.
                if (!_snapshotCreated) ...[
                  const Text(
                    'Save as Performance Snapshot',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  const Text(
                    'Create a snapshot to save these distances for drill target pre-population.',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  TextField(
                    controller: _labelController,
                    style:
                        const TextStyle(color: ColorTokens.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Label (optional)',
                      labelStyle: const TextStyle(
                          color: ColorTokens.textSecondary),
                      filled: true,
                      fillColor: ColorTokens.surfacePrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            ShapeTokens.radiusInput),
                        borderSide: const BorderSide(
                            color: ColorTokens.surfaceBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  SwitchListTile(
                    value: _setAsPrimary,
                    onChanged: (v) =>
                        setState(() => _setAsPrimary = v),
                    title: const Text(
                      'Set as Primary Snapshot',
                      style:
                          TextStyle(color: ColorTokens.textPrimary),
                    ),
                    subtitle: const Text(
                      'Primary snapshot is used for drill target distances.',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                    activeThumbColor: ColorTokens.primaryDefault,
                    tileColor: ColorTokens.surfacePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          ShapeTokens.radiusCard),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _creatingSnapshot ? null : _createSnapshot,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorTokens.primaryDefault,
                        padding: const EdgeInsets.symmetric(
                            vertical: SpacingTokens.sm),
                      ),
                      child: _creatingSnapshot
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorTokens.textPrimary,
                              ),
                            )
                          : const Text('Save Snapshot'),
                    ),
                  ),
                ] else ...[
                  // Snapshot created confirmation.
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    decoration: BoxDecoration(
                      color: ColorTokens.successDefault
                          .withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusCard),
                      border: Border.all(
                        color: ColorTokens.successDefault
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: ColorTokens.successDefault),
                        SizedBox(width: SpacingTokens.sm),
                        Text(
                          'Snapshot Saved',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodyLgSize,
                            fontWeight: FontWeight.w500,
                            color: ColorTokens.successDefault,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Done button.
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          decoration: const BoxDecoration(
            color: ColorTokens.surfacePrimary,
            border: Border(
              top: BorderSide(color: ColorTokens.surfaceBorder),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _done,
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primaryDefault,
                padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.md),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceTable(List<_ClubSummary> summaries) {
    if (summaries.isEmpty) {
      return const Text(
        'No data recorded.',
        style: TextStyle(color: ColorTokens.textSecondary),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfacePrimary,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        children: [
          // Header row.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ColorTokens.surfaceBorder),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Club',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textSecondary,
                      )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Carry',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textSecondary,
                      )),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Total',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textSecondary,
                      )),
                ),
              ],
            ),
          ),
          // Data rows.
          ...summaries.map((s) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: ColorTokens.surfaceBorder, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        s.label,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        s.avgCarry?.toStringAsFixed(1) ?? '-',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          fontWeight: FontWeight.w500,
                          color: ColorTokens.textPrimary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        s.avgTotal?.toStringAsFixed(1) ?? '-',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ClubSummary {
  final String label;
  final int attemptCount;
  final double? avgCarry;
  final double? avgTotal;

  const _ClubSummary({
    required this.label,
    required this.attemptCount,
    this.avgCarry,
    this.avgTotal,
  });
}
