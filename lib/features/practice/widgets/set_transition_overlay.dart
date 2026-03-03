import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// S14 §14.10 — Visual feedback between Sets in structured drills.
/// Shows a brief interstitial "Set N Complete — Starting Set N+1".
/// Auto-dismisses after 1.5 seconds.
class SetTransitionOverlay {
  /// Show the set transition interstitial and auto-dismiss.
  /// [completedSetIndex] is 0-based (the set that was just completed).
  static Future<void> show(
    BuildContext context, {
    required int completedSetIndex,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.lg,
          ),
          decoration: BoxDecoration(
            color: ColorTokens.surfaceModal,
            borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Set ${completedSetIndex + 1} Complete',
                style: TextStyle(
                  fontSize: TypographyTokens.headerSize,
                  fontWeight: TypographyTokens.headerWeight,
                  color: ColorTokens.successDefault,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Starting Set ${completedSetIndex + 2}',
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto-dismiss after 1.5 seconds.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
