import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 §15.3.3 — Single heatmap tile with RAG colour and proportional sizing.
// Shows star score + SkillScore/SkillProfile progress bars.

class SkillAreaTile extends StatelessWidget {
  final SkillArea skillArea;
  final double normalisedScore;
  final double totalPoints;
  final double average;
  final int allocation;
  final double totalOccupancy;
  final double windowCapacity;
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
    required this.totalOccupancy,
    required this.windowCapacity,
    required this.isExpanded,
    this.hasLeft = false,
    this.hasRight = false,
    required this.onTap,
  });

  // Width thresholds for responsive bar/label display.
  static const _showBarsThreshold = 140.0;
  static const _showLabelsThreshold = 160.0;

  @override
  Widget build(BuildContext context) {
    // RAG colour: grey (no data) → red (low) → amber (mid) → green (high).
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showBars = constraints.maxWidth >= _showBarsThreshold;
            final showLabels = constraints.maxWidth >= _showLabelsThreshold;

            final nameStars = Column(
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
                if (average > 0)
                  StarRating(
                    stars: scoreToStars(average),
                    size: 14,
                    color: ColorTokens.textSecondary,
                  )
                else
                  const SizedBox(height: 14),
              ],
            );

            return Row(
              children: [
                // Left — name + stars. Expanded when no bars to prevent overflow.
                if (showBars)
                  Flexible(child: nameStars)
                else
                  Expanded(child: nameStars),
                if (showBars) ...[
                  const SizedBox(width: SpacingTokens.sm),
                  // Right — stacked bars.
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            if (showLabels)
                              SizedBox(
                                width: 56,
                                child: Text(
                                  'Score',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: ColorTokens.textTertiary,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: _TileFillBar(
                                value: totalPoints,
                                max: allocation.toDouble(),
                                rag: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (showLabels)
                              SizedBox(
                                width: 56,
                                child: Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: ColorTokens.textTertiary,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: _TileFillBar(
                                value: totalOccupancy,
                                max: windowCapacity,
                                rag: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Compact fill bar for skill area tiles.
class _TileFillBar extends StatelessWidget {
  final double value;
  final double max;
  final bool rag;

  const _TileFillBar({
    required this.value,
    required this.max,
    required this.rag,
  });

  @override
  Widget build(BuildContext context) {
    final fill = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

    final Color barColor;
    if (value == 0) {
      barColor = ColorTokens.textTertiary.withValues(alpha: 0.3);
    } else if (rag) {
      barColor = Color.lerp(
        const Color(0xFFE05252),
        const Color(0xFF22C55E),
        fill,
      )!;
    } else {
      barColor = Color.lerp(
        ColorTokens.textTertiary,
        ColorTokens.primaryDefault,
        fill,
      )!;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: fill,
        backgroundColor: ColorTokens.textTertiary.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
        minHeight: 5,
      ),
    );
  }
}
