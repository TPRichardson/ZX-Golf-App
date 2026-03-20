import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

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
                          fontSize: TypographyTokens.bodySize,
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
                Row(
                  children: [
                    Text(
                      _gridLabel(drill),
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    _ModeChip(
                      icon: Icons.gps_fixed,
                      label: _targetLabel(drill),
                      color: _targetColor(drill),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    _ModeChip(
                      svgIcon: 'assets/icons/golf-club-iron.svg',
                      label: _clubLabel(drill),
                      color: _clubColor(drill),
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

  static String _gridLabel(Drill drill) {
    return switch (drill.gridType) {
      GridType.threeByThree => 'Full Grid',
      GridType.oneByThree => 'Left/Right',
      GridType.threeByOne => 'Long/Short',
      null => drill.inputMode.dbValue,
    };
  }

  static String _targetLabel(Drill drill) {
    return switch (drill.targetDistanceMode) {
      TargetDistanceMode.randomRange => 'Fixed Random',
      TargetDistanceMode.randomDistancePerSet => 'Fixed Static',
      TargetDistanceMode.clubCarry => 'Suggested',
      TargetDistanceMode.fixed => 'Fixed Static',
      TargetDistanceMode.percentageOfClubCarry => '% Carry',
      null => 'N/A',
    };
  }

  /// Returns: amber = system, cyan = suggested, null = grey.
  static Color? _targetColor(Drill drill) {
    if (drill.targetDistanceMode == TargetDistanceMode.randomRange ||
        drill.targetDistanceMode == TargetDistanceMode.randomDistancePerSet) {
      return ColorTokens.ragAmber;
    }
    if (drill.targetDistanceMode == TargetDistanceMode.clubCarry) {
      return ColorTokens.primaryDefault;
    }
    return null;
  }

  static String _clubLabel(Drill drill) {
    return switch (drill.clubSelectionMode) {
      ClubSelectionMode.userLed => 'Suggested',
      ClubSelectionMode.random => 'Fixed Random',
      ClubSelectionMode.guided => 'Fixed Sequence',
      null => 'N/A',
    };
  }

  static Color? _clubColor(Drill drill) {
    if (drill.clubSelectionMode == ClubSelectionMode.random ||
        drill.clubSelectionMode == ClubSelectionMode.guided) {
      return ColorTokens.ragAmber;
    }
    if (drill.clubSelectionMode == ClubSelectionMode.userLed) {
      return ColorTokens.primaryDefault;
    }
    return null;
  }
}

class _ModeChip extends StatelessWidget {
  final IconData? icon;
  final String? svgIcon;
  final String label;
  final Color? color;

  const _ModeChip({
    this.icon,
    this.svgIcon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ColorTokens.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (svgIcon != null)
          SvgPicture.asset(svgIcon!, width: 12, height: 12,
              colorFilter: ColorFilter.mode(c, BlendMode.srcIn))
        else if (icon != null)
          Icon(icon, size: 12, color: c),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.bodySmSize,
            color: c,
          ),
        ),
      ],
    );
  }
}
