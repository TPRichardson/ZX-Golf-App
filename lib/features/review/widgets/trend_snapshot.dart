import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S12 §12.6.1 — Trend Snapshot: compact sparkline + last value.
// Context-aware: null skillArea = Overall, non-null = that SkillArea.
// Step 5 provides full sparkline; this is the initial implementation.

class TrendSnapshot extends ConsumerWidget {
  final String userId;
  final SkillArea? skillArea;

  const TrendSnapshot({
    super.key,
    required this.userId,
    this.skillArea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(lightSessionsProvider(userId));

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();

        final label =
            skillArea != null ? '${skillArea!.dbValue} Trend' : 'Score Trend';
        final sessionCount = sessions.length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: ColorTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            border: Border.all(color: ColorTokens.surfaceBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      '$sessionCount sessions recorded',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Sparkline placeholder — replaced with fl_chart in Step 5.
              SizedBox(
                width: 80,
                height: 32,
                child: CustomPaint(
                  painter: _MiniSparklinePainter(
                    sessions
                        .take(7)
                        .map((s) => s.completionTimestamp
                            ?.millisecondsSinceEpoch
                            .toDouble() ?? 0)
                        .toList()
                        .reversed
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Minimal sparkline painter using session timestamps as proxy data points.
/// Replaced with proper fl_chart sparkline in Step 5/6.
class _MiniSparklinePainter extends CustomPainter {
  final List<double> values;

  _MiniSparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final paint = Paint()
      ..color = ColorTokens.primaryDefault
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;
    if (range == 0) return;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = (1 - (values[i] - minVal) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter old) =>
      old.values != values;
}
