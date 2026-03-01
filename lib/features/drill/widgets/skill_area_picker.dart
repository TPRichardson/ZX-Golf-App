import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';

// S02 §2.1 — Skill area picker. 7 options + optional "All" filter.

class SkillAreaPicker extends StatelessWidget {
  final SkillArea? selected;
  final ValueChanged<SkillArea?> onChanged;
  final bool showAll;

  const SkillAreaPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showAll = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (showAll)
            _Chip(
              label: 'All',
              isSelected: selected == null,
              onTap: () => onChanged(null),
            ),
          for (final area in SkillArea.values)
            _Chip(
              label: area.dbValue,
              isSelected: selected == area,
              onTap: () => onChanged(area),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: SpacingTokens.xs),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MotionTokens.fast,
          curve: MotionTokens.curve,
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm + 4,
            vertical: SpacingTokens.xs + 2,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorTokens.primaryDefault
                : ColorTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
            border: isSelected
                ? null
                : Border.all(color: ColorTokens.surfaceBorder),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? ColorTokens.textPrimary
                      : ColorTokens.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }
}
