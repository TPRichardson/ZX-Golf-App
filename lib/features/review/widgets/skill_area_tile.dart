import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 §15.3.3 — Single heatmap tile with RAG colour and proportional sizing.
// Shows earned points / allocation and average score.

class SkillAreaTile extends StatelessWidget {
  final SkillArea skillArea;
  final double normalisedScore;
  final double totalPoints;
  final double average;
  final int allocation;
  final bool isExpanded;
  /// Whether tiles exist to the left/right of this one in its row.
  /// Controls bottom corner rounding when expanded.
  final bool hasLeft;
  final bool hasRight;
  final VoidCallback onTap;

  const SkillAreaTile({
    super.key,
    required this.skillArea,
    required this.normalisedScore,
    required this.totalPoints,
    required this.average,
    required this.allocation,
    required this.isExpanded,
    this.hasLeft = false,
    this.hasRight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // RAG colour: grey (no data) → red (low) → amber (mid) → green (high).
    // Breakpoints: 0–0.6 (0–3.0) red→amber, 0.6–1.0 (3.0–5.0) amber→green.
    final Color tileColor;
    if (normalisedScore == 0.0) {
      tileColor = ColorTokens.surfaceRaised;
    } else if (normalisedScore <= 0.6) {
      tileColor = Color.lerp(
        const Color(0xFFE05252),
        const Color(0xFFE8A830),
        (normalisedScore / 0.6).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.6);
    } else {
      tileColor = Color.lerp(
        const Color(0xFFE8A830),
        const Color(0xFF22C55E),
        ((normalisedScore - 0.6) / 0.4).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.6);
    }

    final earnedPoints = totalPoints.round();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.standard,
        curve: MotionTokens.curve,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.sm - 2,
        ),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: isExpanded
              ? BorderRadius.only(
                  topLeft: Radius.circular(ShapeTokens.radiusCard),
                  topRight: Radius.circular(ShapeTokens.radiusCard),
                  bottomLeft: hasLeft
                      ? Radius.circular(ShapeTokens.radiusCard)
                      : Radius.zero,
                  bottomRight: hasRight
                      ? Radius.circular(ShapeTokens.radiusCard)
                      : Radius.zero,
                )
              : BorderRadius.circular(ShapeTokens.radiusCard),
          border: isExpanded
              ? Border(
                  top: BorderSide(
                      color: ColorTokens.primaryDefault, width: 1.5),
                  left: BorderSide(
                      color: ColorTokens.primaryDefault, width: 1.5),
                  right: BorderSide(
                      color: ColorTokens.primaryDefault, width: 1.5),
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              skillArea.dbValue,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$earnedPoints / $allocation pts',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'avg ${average.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
