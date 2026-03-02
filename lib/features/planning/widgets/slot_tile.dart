import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// S08 §8.12.2 — Individual slot tile with state indicators.

class SlotTile extends StatelessWidget {
  final Slot slot;
  final int index;
  final String? drillName;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const SlotTile({
    super.key,
    required this.slot,
    required this.index,
    this.drillName,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Row(
          children: [
            _buildStateIcon(),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slot.isEmpty ? 'Empty slot' : (drillName ?? slot.drillId ?? ''),
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: FontWeight.w400,
                      color: slot.isEmpty
                          ? ColorTokens.textTertiary
                          : ColorTokens.textPrimary,
                    ),
                  ),
                  if (_ownerLabel != null)
                    Text(
                      _ownerLabel!,
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (!slot.planned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: ColorTokens.primaryDefault.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'overflow',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.primaryDefault,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (slot.completionState) {
      case CompletionState.completedLinked:
        return const Icon(
          Icons.check_circle,
          size: 20,
          color: ColorTokens.successDefault,
        );
      case CompletionState.completedManual:
        return const Icon(
          Icons.check_circle_outline,
          size: 20,
          color: ColorTokens.successActive,
        );
      case CompletionState.incomplete:
        if (slot.isEmpty) {
          return const Icon(
            Icons.radio_button_unchecked,
            size: 20,
            color: ColorTokens.textTertiary,
          );
        }
        return const Icon(
          Icons.circle_outlined,
          size: 20,
          color: ColorTokens.primaryDefault,
        );
    }
  }

  Color get _backgroundColor {
    if (slot.isCompleted) {
      return ColorTokens.successDefault.withValues(alpha: 0.08);
    }
    return ColorTokens.surfaceRaised;
  }

  Color get _borderColor {
    if (slot.isCompleted) return ColorTokens.successDefault.withValues(alpha: 0.3);
    if (slot.isFilled) return ColorTokens.surfaceBorder;
    return Colors.transparent;
  }

  String? get _ownerLabel {
    switch (slot.ownerType) {
      case SlotOwnerType.routineInstance:
        return 'From routine';
      case SlotOwnerType.scheduleInstance:
        return 'From schedule';
      case SlotOwnerType.manual:
        return null;
    }
  }
}
