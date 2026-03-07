import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
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
      child: Row(
        children: [
          // Skill area colour indicator.
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _skillAreaColor(drill.skillArea),
              borderRadius: BorderRadius.circular(2),
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
                    _Badge(
                      label: drill.skillArea.dbValue,
                      color: _skillAreaColor(drill.skillArea),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    _Badge(
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
    return switch (area) {
      SkillArea.driving => const Color(0xFF00B3C6),
      SkillArea.irons => const Color(0xFF1FA463),
      SkillArea.putting => const Color(0xFFF5A623),
      SkillArea.pitching => const Color(0xFF9B59B6),
      SkillArea.chipping => const Color(0xFFE67E22),
      SkillArea.woods => const Color(0xFF3498DB),
      SkillArea.bunkers => const Color(0xFFD64545),
    };
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
