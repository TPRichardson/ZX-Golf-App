import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Standard full-width action button used by input delegates to record
/// a shot, hole, or measurement during drill execution.
class ShotRecordButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const ShotRecordButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorTokens.primaryDefault,
          foregroundColor: Colors.white,
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
