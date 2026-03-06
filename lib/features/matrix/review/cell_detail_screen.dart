// Phase M9 — Cell detail screen.
// Shows attempt list for a specific matrix cell with edit/delete capability.
// Spec §7.4.4, §7.7.5, §7.8.7.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

/// Cell detail view showing attempts with edit/delete.
class CellDetailScreen extends ConsumerStatefulWidget {
  final String matrixRunId;
  final String cellId;
  final String cellLabel;
  final MatrixType matrixType;

  const CellDetailScreen({
    super.key,
    required this.matrixRunId,
    required this.cellId,
    required this.cellLabel,
    required this.matrixType,
  });

  @override
  ConsumerState<CellDetailScreen> createState() => _CellDetailScreenState();
}

class _CellDetailScreenState extends ConsumerState<CellDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailsAsync =
        ref.watch(matrixRunDetailsProvider(widget.matrixRunId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cellLabel),
        backgroundColor: ColorTokens.surfacePrimary,
        surfaceTintColor: Colors.transparent,
      ),
      backgroundColor: ColorTokens.surfaceBase,
      body: detailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(child: Text('Run not found'));
          }

          final cellData = details.cells
              .where((c) => c.cell.matrixCellId == widget.cellId)
              .firstOrNull;
          if (cellData == null) {
            return const Center(child: Text('Cell not found'));
          }

          final attempts = cellData.attempts;
          if (attempts.isEmpty) {
            return const Center(
              child: Text(
                'No attempts recorded',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            );
          }

          // Compute averages.
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

          final avgCarry = carryValues.isNotEmpty
              ? carryValues.reduce((a, b) => a + b) / carryValues.length
              : null;
          final avgTotal = totalValues.isNotEmpty
              ? totalValues.reduce((a, b) => a + b) / totalValues.length
              : null;
          final avgRollout = rolloutValues.isNotEmpty
              ? rolloutValues.reduce((a, b) => a + b) / rolloutValues.length
              : null;

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              // Summary section.
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: ColorTokens.surfaceRaised,
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                  border: Border.all(color: ColorTokens.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cellLabel,
                      style: const TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    if (avgCarry != null)
                      _summaryRow(
                          'Average Carry', '${avgCarry.toStringAsFixed(1)}'),
                    if (avgTotal != null)
                      _summaryRow(
                          'Average Total', '${avgTotal.toStringAsFixed(1)}'),
                    if (avgRollout != null)
                      _summaryRow('Average Rollout',
                          avgRollout.toStringAsFixed(1)),
                    _summaryRow('Attempts', '${attempts.length}'),
                  ],
                ),
              ),
              const SizedBox(height: SpacingTokens.md),

              // Attempt list.
              ...attempts.asMap().entries.map((entry) {
                final index = entry.key;
                final attempt = entry.value;
                return _buildAttemptTile(attempt, index + 1);
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptTile(MatrixAttempt attempt, int number) {
    final isChipping = widget.matrixType == MatrixType.chippingMatrix;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attempt $number',
                  style: const TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Row(
                  children: [
                    if (attempt.carryDistanceMeters != null)
                      _metricChip('Carry',
                          attempt.carryDistanceMeters!.toStringAsFixed(1)),
                    if (attempt.totalDistanceMeters != null) ...[
                      const SizedBox(width: SpacingTokens.sm),
                      _metricChip('Total',
                          attempt.totalDistanceMeters!.toStringAsFixed(1)),
                    ],
                    if (isChipping &&
                        attempt.rolloutDistanceMeters != null) ...[
                      const SizedBox(width: SpacingTokens.sm),
                      _metricChip('Rollout',
                          attempt.rolloutDistanceMeters!.toStringAsFixed(1)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Edit button.
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: ColorTokens.textTertiary,
            onPressed: () => _showEditDialog(attempt),
          ),
          // Delete button.
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: ColorTokens.errorDestructive,
            onPressed: () => _deleteAttempt(attempt),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Text(
      '$label $value',
      style: const TextStyle(
        fontSize: TypographyTokens.microSize,
        color: ColorTokens.textSecondary,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }

  Future<void> _deleteAttempt(MatrixAttempt attempt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Delete Attempt'),
        content: const Text('This attempt will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: ColorTokens.errorDestructive),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(matrixActionsProvider)
          .deleteAttempt(attempt.matrixAttemptId);
    }
  }

  Future<void> _showEditDialog(MatrixAttempt attempt) async {
    final carryCtrl = TextEditingController(
      text: attempt.carryDistanceMeters?.toStringAsFixed(1) ?? '',
    );
    final totalCtrl = TextEditingController(
      text: attempt.totalDistanceMeters?.toStringAsFixed(1) ?? '',
    );
    final rolloutCtrl = TextEditingController(
      text: attempt.rolloutDistanceMeters?.toStringAsFixed(1) ?? '',
    );
    final isChipping = widget.matrixType == MatrixType.chippingMatrix;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Edit Attempt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: carryCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Carry'),
            ),
            const SizedBox(height: SpacingTokens.sm),
            TextField(
              controller: totalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Total'),
            ),
            if (isChipping) ...[
              const SizedBox(height: SpacingTokens.sm),
              TextField(
                controller: rolloutCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Rollout'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final carry = double.tryParse(carryCtrl.text);
      final total = double.tryParse(totalCtrl.text);
      final rollout = isChipping ? double.tryParse(rolloutCtrl.text) : null;

      await ref.read(matrixActionsProvider).updateAttempt(
            attempt.matrixAttemptId,
            MatrixAttemptsCompanion(
              carryDistanceMeters: Value(carry),
              totalDistanceMeters: Value(total),
              rolloutDistanceMeters: Value(rollout),
            ),
          );
    }

    carryCtrl.dispose();
    totalCtrl.dispose();
    rolloutCtrl.dispose();
  }
}
