// Phase M5 — Matrix cell card widget.
// Displays a cell's label, attempt count, and status.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Card displaying a matrix cell with its label, attempt count, and status.
class MatrixCellCard extends StatelessWidget {
  final String label;
  final int attemptCount;
  final int shotTarget;
  final bool isExcluded;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MatrixCellCard({
    super.key,
    required this.label,
    required this.attemptCount,
    required this.shotTarget,
    this.isExcluded = false,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
  });

  Color get _statusColor {
    if (isExcluded) return ColorTokens.textTertiary;
    if (attemptCount >= shotTarget) return ColorTokens.successDefault;
    if (attemptCount > 0) return ColorTokens.warningIntegrity;
    return ColorTokens.textSecondary;
  }

  String get _statusText {
    if (isExcluded) return 'Excluded';
    if (attemptCount >= shotTarget) return 'Complete';
    if (attemptCount > 0) return '$attemptCount/$shotTarget';
    return '0/$shotTarget';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? ColorTokens.surfaceRaised
              : ColorTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(
            color:
                isActive ? ColorTokens.primaryDefault : ColorTokens.surfaceBorder,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  fontWeight: FontWeight.w500,
                  color: isExcluded
                      ? ColorTokens.textTertiary
                      : ColorTokens.textPrimary,
                  decoration:
                      isExcluded ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusGrid),
              ),
              child: Text(
                _statusText,
                style: TextStyle(
                  fontSize: TypographyTokens.bodySmSize,
                  fontWeight: FontWeight.w500,
                  color: _statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
