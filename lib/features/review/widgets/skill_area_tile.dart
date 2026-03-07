import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 §15.3.3 — Single heatmap tile with RAG colour and proportional sizing.
// Shows earned points / allocation and average score.

class SkillAreaTile extends StatelessWidget {
  final SkillArea skillArea;
  final double normalisedScore;
  final double rawScore;
  final int allocation;
  final bool isExpanded;
  final VoidCallback onTap;

  const SkillAreaTile({
    super.key,
    required this.skillArea,
    required this.normalisedScore,
    required this.rawScore,
    required this.allocation,
    required this.isExpanded,
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
        const Color(0xFFD64545),
        const Color(0xFFF5A623),
        (normalisedScore / 0.6).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.25);
    } else {
      tileColor = Color.lerp(
        const Color(0xFFF5A623),
        const Color(0xFF1FA463),
        ((normalisedScore - 0.6) / 0.4).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.25);
    }

    // Earned points = (average / 5.0) * allocation.
    final earnedPoints = allocation > 0
        ? (rawScore / 5.0 * allocation).round()
        : 0;

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
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: isExpanded
              ? Border.all(color: ColorTokens.primaryDefault, width: 1.5)
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
              '$earnedPoints / $allocation',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              'avg ${rawScore.toStringAsFixed(1)}',
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
