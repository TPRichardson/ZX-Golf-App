import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S05 §5.1, S15 §15.2 — Overall score display.
// Neutral presentation: no celebratory text, no emotional framing.
// Tabular lining numerals for score readability.

class OverallScoreDisplay extends StatelessWidget {
  final double score;
  final double profileComplete;

  const OverallScoreDisplay({
    super.key,
    required this.score,
    this.profileComplete = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // S01 §1.12 — Overall score is 0–1000, displayed as integer.
    final displayScore = score.round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.lg,
        horizontal: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left half — SkillScore.
            Expanded(
              child: Column(
                children: [
                  Text(
                    'SkillScore',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: TypographyTokens.bodyWeight,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CustomPaint(
                      painter: _CircleProgressPainter(
                        progress: (score / 1000).clamp(0.0, 1.0),
                        trackColor: ColorTokens.textTertiary.withValues(alpha: 0.15),
                        progressColor: _skillScoreColor(score),
                        strokeWidth: 6,
                      ),
                      child: Center(
                        child: Text(
                          '$displayScore',
                          style: TextStyle(
                            fontSize: TypographyTokens.displayLgSize,
                            fontWeight: TypographyTokens.displayLgWeight,
                            color: ColorTokens.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right half — SkillProfile completeness.
            Expanded(
              child: Column(
                children: [
                  Text(
                    'SkillProfile',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: TypographyTokens.bodyWeight,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CustomPaint(
                      painter: _CircleProgressPainter(
                        progress: profileComplete,
                        trackColor: ColorTokens.textTertiary.withValues(alpha: 0.15),
                        progressColor: ColorTokens.primaryDefault,
                        strokeWidth: 6,
                      ),
                      child: Center(
                        child: Text(
                          '${(profileComplete * 100).round()}%',
                          style: TextStyle(
                            fontSize: TypographyTokens.displayLgSize,
                            fontWeight: TypographyTokens.displayLgWeight,
                            color: ColorTokens.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SkillScore ring colour — delegates to shared RAG token.
Color _skillScoreColor(double score) => ColorTokens.ragScoreColor(score);

/// Circular progress arc painter for profile completeness.
class _CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _CircleProgressPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc.
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
