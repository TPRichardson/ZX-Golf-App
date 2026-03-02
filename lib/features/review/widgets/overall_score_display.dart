import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S05 §5.1, S15 §15.2 — Overall score display.
// Neutral presentation: no celebratory text, no emotional framing.
// Tabular lining numerals for score readability.

class OverallScoreDisplay extends StatelessWidget {
  final double score;

  const OverallScoreDisplay({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    // S01 §1.12 — Overall score is 0–1000, displayed as integer.
    final displayScore = score.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.lg,
        horizontal: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            'SkillScore',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: TypographyTokens.bodyWeight,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          // S15 §15.5 — Display XL with tabular figures.
          Text(
            '$displayScore',
            style: TextStyle(
              fontSize: TypographyTokens.displayXlSize,
              fontWeight: TypographyTokens.displayXlWeight,
              height: TypographyTokens.displayXlHeight,
              color: ColorTokens.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'out of 1000',
            style: TextStyle(
              fontSize: TypographyTokens.microSize,
              fontWeight: TypographyTokens.microWeight,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
