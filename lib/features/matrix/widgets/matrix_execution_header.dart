// Phase M5 — Matrix execution header widget.
// Displays matrix type, run number, and cell progress.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

/// Header for matrix execution screens showing run info and cell progress.
class MatrixExecutionHeader extends StatelessWidget {
  final MatrixType matrixType;
  final int runNumber;
  final String currentCellLabel;
  final int currentCellIndex;
  final int totalCells;
  final int currentAttemptCount;
  final int sessionShotTarget;

  const MatrixExecutionHeader({
    super.key,
    required this.matrixType,
    required this.runNumber,
    required this.currentCellLabel,
    required this.currentCellIndex,
    required this.totalCells,
    required this.currentAttemptCount,
    required this.sessionShotTarget,
  });

  String get _matrixTypeLabel {
    switch (matrixType) {
      case MatrixType.gappingChart:
        return 'Gapping Chart';
      case MatrixType.wedgeMatrix:
        return 'Wedge Matrix';
      case MatrixType.chippingMatrix:
        return 'Chipping Matrix';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          bottom: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_matrixTypeLabel #$runNumber',
                  style: const TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
              Text(
                'Cell ${currentCellIndex + 1}/$totalCells',
                style: const TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              Text(
                currentCellLabel,
                style: const TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  fontWeight: FontWeight.w500,
                  color: ColorTokens.primaryDefault,
                ),
              ),
              const SizedBox(width: SpacingTokens.md),
              Text(
                '$currentAttemptCount/$sessionShotTarget shots',
                style: const TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
