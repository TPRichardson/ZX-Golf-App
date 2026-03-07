import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_badge.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// S15 §15.8 — Drill card for list display.
// Shows drill name, skill area badge, drill type, origin icon, and input mode.

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
        children: [
          // Skill area colour indicator.
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _skillAreaColor(drill.skillArea),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusMicro),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Origin icon: system vs custom.
                    Icon(
                      drill.origin == DrillOrigin.system
                          ? Icons.verified_outlined
                          : Icons.person_outline,
                      size: 16,
                      color: drill.origin == DrillOrigin.system
                          ? ColorTokens.primaryDefault
                          : ColorTokens.textTertiary,
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Expanded(
                      child: Text(
                        drill.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: ColorTokens.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                Row(
                  children: [
                    ZxBadge(
                      label: drill.skillArea.dbValue,
                      color: _skillAreaColor(drill.skillArea),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    ZxBadge(
                      label: _drillTypeLabel(drill.drillType),
                      color: _drillTypeColor(drill.drillType),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  static Color _skillAreaColor(SkillArea area) {
    return ColorTokens.skillArea(area);
  }

  static String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
    };
  }

  static Color _drillTypeColor(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => ColorTokens.textTertiary,
      DrillType.transition => ColorTokens.primaryDefault,
      DrillType.pressure => ColorTokens.warningIntegrity,
    };
  }
}
