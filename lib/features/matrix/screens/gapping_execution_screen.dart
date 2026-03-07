// Phase M5 — Gapping Chart execution screen.
// Matrix §6.5–6.7 — Cell-by-cell distance entry for gapping runs.

import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_completion_screen.dart';
import 'package:zx_golf_app/features/matrix/widgets/matrix_cell_card.dart';
import 'package:zx_golf_app/features/matrix/widgets/matrix_execution_header.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

const _uuid = Uuid();

/// Matrix §6.5 — Execution screen for a gapping chart run.
/// Navigates through cells (one per club), capturing distance attempts.
class GappingExecutionScreen extends ConsumerStatefulWidget {
  final String matrixRunId;
  final String userId;

  const GappingExecutionScreen({
    super.key,
    required this.matrixRunId,
    required this.userId,
  });

  @override
  ConsumerState<GappingExecutionScreen> createState() =>
      _GappingExecutionScreenState();
}

class _GappingExecutionScreenState
    extends ConsumerState<GappingExecutionScreen> {
  final _carryController = TextEditingController();
  final _totalController = TextEditingController();
  int _currentCellIndex = 0;
  bool _ending = false;
  bool _showCellList = false;

  @override
  void dispose() {
    _carryController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  /// Resolve the label for a cell by finding the matching axis value.
  String _cellLabel(
    MatrixCellWithAttempts cellWithAttempts,
    List<MatrixAxisWithValues> axes,
  ) {
    final cell = cellWithAttempts.cell;
    final axisValueIds =
        (jsonDecode(cell.axisValueIds) as List).cast<String>();
    // For gapping charts (1D), there's one axis value ID per cell.
    for (final axisWithValues in axes) {
      for (final value in axisWithValues.values) {
        if (axisValueIds.contains(value.axisValueId)) {
          return value.label;
        }
      }
    }
    return 'Unknown';
  }

  /// Get the sorted active (non-excluded) cells.
  List<MatrixCellWithAttempts> _activeCells(MatrixRunWithDetails details) {
    return details.cells
        .where((c) => !c.cell.excludedFromRun)
        .toList();
  }

  Future<void> _submitAttempt(MatrixCellWithAttempts cellWithAttempts) async {
    final carryText = _carryController.text.trim();
    if (carryText.isEmpty) return;

    final carry = double.tryParse(carryText);
    if (carry == null) return;

    final totalText = _totalController.text.trim();
    final total = totalText.isNotEmpty ? double.tryParse(totalText) : null;

    HapticFeedback.lightImpact();

    try {
      await ref.read(matrixActionsProvider).logAttempt(
            cellWithAttempts.cell.matrixCellId,
            MatrixAttemptsCompanion.insert(
              matrixAttemptId: _uuid.v4(),
              matrixCellId: cellWithAttempts.cell.matrixCellId,
              carryDistanceMeters: Value(carry),
              totalDistanceMeters: Value(total),
            ),
          );

      _carryController.clear();
      _totalController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _completeRun() async {
    if (_ending) return;
    setState(() => _ending = true);

    try {
      final run = await ref
          .read(matrixActionsProvider)
          .completeMatrixRun(widget.matrixRunId, widget.userId);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MatrixCompletionScreen(
              matrixRunId: run.matrixRunId,
              userId: widget.userId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _ending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _discardRun() async {
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Discard Run?',
      message: 'This will permanently discard this matrix run and all recorded attempts.',
      confirmLabel: 'Discard',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(matrixActionsProvider)
          .discardMatrixRun(widget.matrixRunId, widget.userId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _excludeCell(String cellId) async {
    try {
      await ref.read(matrixActionsProvider).excludeCell(cellId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _includeCell(String cellId) async {
    try {
      await ref.read(matrixActionsProvider).includeCell(cellId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
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
            return _buildExecution(details);
          },
        ),
      ),
    );
  }

  Widget _buildExecution(MatrixRunWithDetails details) {
    final activeCells = _activeCells(details);
    if (_currentCellIndex >= activeCells.length && activeCells.isNotEmpty) {
      _currentCellIndex = activeCells.length - 1;
    }

    final currentCell =
        activeCells.isNotEmpty ? activeCells[_currentCellIndex] : null;
    final currentLabel = currentCell != null
        ? _cellLabel(currentCell, details.axes)
        : 'No cells';

    // Check if all active cells are complete.
    final allComplete = activeCells.isNotEmpty &&
        activeCells.every((c) =>
            c.attempts.length >= details.run.sessionShotTarget);

    return Column(
      children: [
        // Header.
        MatrixExecutionHeader(
          matrixType: details.run.matrixType,
          runNumber: details.run.runNumber,
          currentCellLabel: currentLabel,
          currentCellIndex: _currentCellIndex,
          totalCells: activeCells.length,
          currentAttemptCount: currentCell?.attempts.length ?? 0,
          sessionShotTarget: details.run.sessionShotTarget,
        ),

        // Main content area.
        Expanded(
          child: _showCellList
              ? _buildCellList(details)
              : _buildInputArea(details, currentCell, currentLabel),
        ),

        // Bottom bar.
        _buildBottomBar(details, currentCell, activeCells, allComplete),
      ],
    );
  }

  Widget _buildInputArea(
    MatrixRunWithDetails details,
    MatrixCellWithAttempts? currentCell,
    String currentLabel,
  ) {
    if (currentCell == null) {
      return const Center(
        child: Text(
          'All cells excluded. Include cells or discard run.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
      );
    }

    final attempts = currentCell.attempts;
    final shotTarget = details.run.sessionShotTarget;
    final cellComplete = attempts.length >= shotTarget;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Previous attempts for this cell.
          if (attempts.isNotEmpty) ...[
            Text(
              'Recorded Shots — $currentLabel',
              style: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w500,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            ...attempts.asMap().entries.map((entry) {
              final i = entry.key;
              final a = entry.value;
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: SpacingTokens.xs),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    ),
                    Text(
                      a.carryDistanceMeters?.toStringAsFixed(1) ?? '-',
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodyLgSize,
                        color: ColorTokens.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (a.totalDistanceMeters != null) ...[
                      const Text(
                        ' / ',
                        style: TextStyle(color: ColorTokens.textTertiary),
                      ),
                      Text(
                        a.totalDistanceMeters!.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodyLgSize,
                          color: ColorTokens.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Delete attempt.
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: ColorTokens.textTertiary),
                      onPressed: () => ref
                          .read(matrixActionsProvider)
                          .deleteAttempt(a.matrixAttemptId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: SpacingTokens.md),
          ],

          // Input area (only if cell not complete).
          if (!cellComplete) ...[
            const Text(
              'Carry Distance',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            TextField(
              controller: _carryController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              autofocus: true,
              style: const TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                color: ColorTokens.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle:
                    const TextStyle(color: ColorTokens.textTertiary),
                filled: true,
                fillColor: ColorTokens.surfacePrimary,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusInput),
                  borderSide: const BorderSide(
                      color: ColorTokens.surfaceBorder),
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            const Text(
              'Total Distance (Optional)',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            TextField(
              controller: _totalController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: const TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                color: ColorTokens.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle:
                    const TextStyle(color: ColorTokens.textTertiary),
                filled: true,
                fillColor: ColorTokens.surfacePrimary,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusInput),
                  borderSide: const BorderSide(
                      color: ColorTokens.surfaceBorder),
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _submitAttempt(currentCell),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorTokens.successDefault,
                  padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.sm),
                ),
                child: const Text(
                  'Record',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodyLgSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Cell is complete indicator.
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: ColorTokens.successDefault.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusCard),
                border: Border.all(
                  color:
                      ColorTokens.successDefault.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: ColorTokens.successDefault),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    '$currentLabel Complete',
                    style: const TextStyle(
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
    );
  }

  Widget _buildCellList(MatrixRunWithDetails details) {
    return ListView.separated(
      padding: const EdgeInsets.all(SpacingTokens.md),
      itemCount: details.cells.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: SpacingTokens.sm),
      itemBuilder: (_, index) {
        final cellWithAttempts = details.cells[index];
        final label = _cellLabel(cellWithAttempts, details.axes);
        final isActive = !cellWithAttempts.cell.excludedFromRun &&
            _activeCells(details).indexOf(cellWithAttempts) ==
                _currentCellIndex;

        return MatrixCellCard(
          label: label,
          attemptCount: cellWithAttempts.attempts.length,
          shotTarget: details.run.sessionShotTarget,
          isExcluded: cellWithAttempts.cell.excludedFromRun,
          isActive: isActive,
          onTap: () {
            if (cellWithAttempts.cell.excludedFromRun) {
              _showCellOptions(cellWithAttempts, label, excluded: true);
            } else {
              final activeCells = _activeCells(details);
              final activeIndex = activeCells.indexOf(cellWithAttempts);
              if (activeIndex >= 0) {
                setState(() {
                  _currentCellIndex = activeIndex;
                  _showCellList = false;
                });
              }
            }
          },
          onLongPress: () => _showCellOptions(
            cellWithAttempts,
            label,
            excluded: cellWithAttempts.cell.excludedFromRun,
          ),
        );
      },
    );
  }

  void _showCellOptions(
    MatrixCellWithAttempts cellWithAttempts,
    String label, {
    required bool excluded,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.surfaceModal,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: ColorTokens.textPrimary,
                ),
              ),
            ),
            if (excluded)
              ListTile(
                leading: const Icon(Icons.add_circle_outline,
                    color: ColorTokens.primaryDefault),
                title: const Text('Include Cell',
                    style: TextStyle(color: ColorTokens.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _includeCell(cellWithAttempts.cell.matrixCellId);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: ColorTokens.warningIntegrity),
                title: const Text('Exclude Cell',
                    style: TextStyle(color: ColorTokens.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _excludeCell(cellWithAttempts.cell.matrixCellId);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    MatrixRunWithDetails details,
    MatrixCellWithAttempts? currentCell,
    List<MatrixCellWithAttempts> activeCells,
    bool allComplete,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfacePrimary,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          // Cell list toggle.
          IconButton(
            icon: Icon(
              _showCellList ? Icons.edit_note : Icons.list,
              color: ColorTokens.textSecondary,
            ),
            onPressed: () =>
                setState(() => _showCellList = !_showCellList),
            tooltip: _showCellList ? 'Back to input' : 'View all cells',
          ),

          // Previous cell.
          if (!_showCellList && _currentCellIndex > 0)
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: ColorTokens.textSecondary),
              onPressed: () =>
                  setState(() => _currentCellIndex--),
              tooltip: 'Previous club',
            ),

          // Next cell.
          if (!_showCellList &&
              _currentCellIndex < activeCells.length - 1)
            IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: ColorTokens.textSecondary),
              onPressed: () =>
                  setState(() => _currentCellIndex++),
              tooltip: 'Next club',
            ),

          const Spacer(),

          // Discard.
          TextButton(
            onPressed: _discardRun,
            style: TextButton.styleFrom(
              foregroundColor: ColorTokens.errorDestructive,
            ),
            child: const Text('Discard'),
          ),

          const SizedBox(width: SpacingTokens.sm),

          // Complete.
          FilledButton(
            onPressed: allComplete && !_ending ? _completeRun : null,
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.successDefault,
            ),
            child: _ending
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Complete'),
          ),
        ],
      ),
    );
  }
}
