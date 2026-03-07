import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S15 §15.8 — Button component. Four variants: primary, secondary, destructive, text.
// On-press: darken ~4%, no bounce (S15 §15.4).

enum ZxButtonVariant { primary, secondary, destructive, text }

class ZxButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ZxButtonVariant variant;
  final bool isLoading;

  const ZxButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ZxButtonVariant.primary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      ZxButtonVariant.primary => _buildFilled(
          ColorTokens.primaryDefault, ColorTokens.primaryActive),
      ZxButtonVariant.secondary => _buildOutlined(),
      ZxButtonVariant.destructive => _buildFilled(
          ColorTokens.errorDestructive, ColorTokens.errorActive),
      ZxButtonVariant.text => _buildText(),
    };
  }

  Widget _buildFilled(Color background, Color pressedColor) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: ColorTokens.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        animationDuration: MotionTokens.fast,
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return pressedColor;
          }
          return null;
        }),
      ),
      child: isLoading
          ? const SizedBox(
              width: SpacingTokens.md,
              height: SpacingTokens.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }

  Widget _buildOutlined() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorTokens.primaryDefault,
        side: const BorderSide(color: ColorTokens.primaryDefault),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        animationDuration: MotionTokens.fast,
      ),
      child: isLoading
          ? const SizedBox(
              width: SpacingTokens.md,
              height: SpacingTokens.md,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }

  Widget _buildText() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ColorTokens.primaryDefault,
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.xs,
        ),
        animationDuration: MotionTokens.fast,
      ),
      child: Text(label),
    );
  }
}
