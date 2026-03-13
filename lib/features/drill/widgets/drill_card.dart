import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/data/database.dart';

// S15 §15.8 — Drill card for list display.
// Simplified: skill area colour bar, drill name, optional trailing widget.

class DrillCard extends StatelessWidget {
  final Drill drill;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool hasUnseenUpdate;
  final bool isSelected;
  final bool isDestructiveSelected;
  final String? subtitle;

  const DrillCard({
    super.key,
    required this.drill,
    this.onTap,
    this.trailing,
    this.hasUnseenUpdate = false,
    this.isSelected = false,
    this.isDestructiveSelected = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ZxCard(
      onTap: onTap,
      borderColor: isDestructiveSelected
          ? ColorTokens.errorDestructive
          : isSelected
              ? ColorTokens.primaryDefault
              : null,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Skill area colour indicator.
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: ColorTokens.skillArea(drill.skillArea),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusMicro),
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          // Drill name, subtitle, unseen update dot.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        drill.name,
                        style: TextStyle(
                          fontSize: TypographyTokens.bodyLgSize,
                          fontWeight: FontWeight.w600,
                          color: isDestructiveSelected
                            ? ColorTokens.errorDestructive
                            : ColorTokens.textPrimary,
                        ),
                      ),
                    ),
                    if (hasUnseenUpdate) ...[
                      const SizedBox(width: SpacingTokens.sm),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: ColorTokens.primaryDefault,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySmSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
