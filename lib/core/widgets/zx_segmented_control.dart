import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S15 §15.8 — Segmented control. 8px container radius, 8px selection highlight.
// No pill shapes per S15 §15.7.

class ZxSegmentedControl<T> extends StatelessWidget {
  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  const ZxSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.map((segment) {
          final isSelected = segment == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(segment),
              child: AnimatedContainer(
                duration: MotionTokens.fast,
                curve: MotionTokens.curve,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorTokens.primaryDefault
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusSegmented - 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  labelBuilder(segment),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? ColorTokens.textPrimary
                            : ColorTokens.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
