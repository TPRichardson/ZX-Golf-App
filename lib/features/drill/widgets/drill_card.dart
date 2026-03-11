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

  const DrillCard({
    super.key,
    required this.drill,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ZxCard(
      onTap: onTap,
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
          // Drill name.
          Expanded(
            child: Text(
              drill.name,
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: FontWeight.w600,
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
