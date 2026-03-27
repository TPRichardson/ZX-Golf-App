import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Standard full-width action button used by input delegates to record
/// a shot, hole, or measurement during drill execution.
class ShotRecordButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  /// When true, renders in grey instead of cyan (e.g. behind a dialog).
  final bool muted;

  const ShotRecordButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: muted
              ? ColorTokens.surfaceRaised
              : ColorTokens.primaryDefault,
          foregroundColor: muted
              ? ColorTokens.textTertiary
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: TypographyTokens.bodyLgSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
