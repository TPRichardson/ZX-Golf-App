import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 §15.3.3 — Single heatmap tile with continuous grey-to-green opacity.
// Tap toggles accordion expand/collapse for subskill breakdown.

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
    // S15 §15.3.3 — Continuous grey-to-green interpolation.
    final tileColor = Color.lerp(
      ColorTokens.heatmapBase,
      ColorTokens.heatmapHigh,
      normalisedScore,
    )!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: MotionTokens.standard,
        curve: MotionTokens.curve,
        padding: const EdgeInsets.all(SpacingTokens.sm),
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
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              rawScore.toStringAsFixed(1),
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
