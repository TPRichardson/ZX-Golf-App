import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S15 §15.8.4 — Achievement banners.
// Factual, not celebratory. Fade in 150ms, fade out 200ms.
// No slide, bounce, scale, glow, confetti, streak effects.

class AchievementBanner extends StatefulWidget {
  final String message;
  final VoidCallback? onDismissed;

  const AchievementBanner({
    super.key,
    required this.message,
    this.onDismissed,
  });

  @override
  State<AchievementBanner> createState() => _AchievementBannerState();
}

class _AchievementBannerState extends State<AchievementBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      // S15 §15.10 — Entry: standard 150ms, exit: slow 200ms.
      duration: MotionTokens.standard,
      reverseDuration: MotionTokens.slow,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: MotionTokens.curve,
    );
    _controller.forward();

    // Auto-dismiss after 3 seconds.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismissed?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          // S15 §15.8.4 — surfaceRaised bg, radiusCard corner radius.
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.primaryDefault, width: 1),
        ),
        child: Text(
          widget.message,
          style: TextStyle(
            fontSize: TypographyTokens.bodySize,
            color: ColorTokens.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Show an achievement banner as an overlay at the top of the screen.
void showAchievementBanner(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => Positioned(
      top: MediaQuery.of(context).padding.top + SpacingTokens.md,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: AchievementBanner(
          message: message,
          onDismissed: () => entry.remove(),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}
