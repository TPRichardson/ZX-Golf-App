// Anchor score bar — horizontal bar showing Min/Scratch/Pro markers
// with the user's score plotted on it.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Horizontal bar showing Min, Scratch, and Pro anchor positions,
/// with the user's performance plotted on it. The bar gradient goes red → amber → green.
///
/// Two modes:
/// - **Percentage mode** (default): 0–100 scale, anchors are percentages.
/// - **Value mode**: when [userValue] is provided, the bar scales from
///   Min to 105% of Pro, with the user's raw value plotted.
class AnchorScoreBar extends StatelessWidget {
  /// User's actual hit rate percentage (0–100). Used in percentage mode.
  final double userHitRatePct;

  /// User's raw performance value (e.g., 95 mph). When set, uses value mode.
  final double? userValue;

  final String? anchorsJson;

  const AnchorScoreBar({
    super.key,
    this.userHitRatePct = 0,
    this.userValue,
    this.anchorsJson,
  });

  @override
  Widget build(BuildContext context) {
    // Parse anchors from JSON. Format: {"subskillId": {"Min": x, "Scratch": y, "Pro": z}}
    double? minAnchor;
    double? scratchAnchor;
    double? proAnchor;

    if (anchorsJson != null) {
      try {
        final anchors = jsonDecode(anchorsJson!) as Map<String, dynamic>;
        if (anchors.isNotEmpty) {
          final first = anchors.values.first as Map<String, dynamic>;
          minAnchor = (first['Min'] as num?)?.toDouble();
          scratchAnchor = (first['Scratch'] as num?)?.toDouble();
          proAnchor = (first['Pro'] as num?)?.toDouble();
        }
      } catch (_) {}
    }

    if (minAnchor == null || scratchAnchor == null || proAnchor == null) {
      return const SizedBox.shrink();
    }

    final mn = minAnchor;
    final sc = scratchAnchor;
    final pr = proAnchor;

    // Value mode: scale from min to 105% of pro.
    final isValueMode = userValue != null;
    final scaleMin = isValueMode ? mn : 0.0;
    final scaleMax = isValueMode ? pr * 1.05 : 100.0;
    final scaleRange = scaleMax - scaleMin;
    final userVal = isValueMode
        ? userValue!.clamp(scaleMin, scaleMax)
        : userHitRatePct.clamp(0.0, 100.0);

    double toFraction(double v) =>
        scaleRange > 0 ? ((v - scaleMin) / scaleRange).clamp(0.0, 1.0) : 0.0;

    final mnFrac = toFraction(mn);
    final scFrac = toFraction(sc);
    final prFrac = toFraction(pr);
    final userFrac = toFraction(userVal);

    return Column(
      children: [
        const SizedBox(height: SpacingTokens.md),
        SizedBox(
          height: isValueMode ? 72 : 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final minPos = (mnFrac * width).clamp(0.0, width);
              final scratchPos = (scFrac * width).clamp(0.0, width);
              final proPos = (prFrac * width).clamp(0.0, width);
              final userPos = (userFrac * width).clamp(0.0, width);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bar: solid red up to Min, then RAG gradient from Min onward.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: isValueMode ? 24 : 20,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          stops: [
                            mnFrac,
                            mnFrac,
                            (mnFrac + scFrac) / 2,
                            prFrac,
                          ],
                          colors: const [
                            ColorTokens.ragRed, // Red (0 to Min)
                            ColorTokens.ragRed, // Red (at Min)
                            ColorTokens.ragAmber, // Amber (mid)
                            ColorTokens.ragGreen, // Green (Pro)
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Min marker.
                  _AnchorMarker(
                    position: minPos,
                    label: 'Min',
                    color: ColorTokens.ragRed,
                    topOffset: isValueMode ? 20 : 16,
                  ),
                  // Scratch marker.
                  _AnchorMarker(
                    position: scratchPos,
                    label: 'Scratch',
                    color: ColorTokens.ragAmber,
                    topOffset: isValueMode ? 20 : 16,
                  ),
                  // Pro marker.
                  _AnchorMarker(
                    position: proPos,
                    label: 'Pro',
                    color: ColorTokens.ragGreen,
                    topOffset: isValueMode ? 20 : 16,
                  ),
                  // User value label above the marker.
                  if (isValueMode)
                    Positioned(
                      left: userPos - 20,
                      top: 0,
                      child: SizedBox(
                        width: 40,
                        child: Text(
                          '${userVal.round()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: TypographyTokens.bodySize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  // User score marker.
                  Positioned(
                    left: userPos - 6,
                    top: isValueMode ? 20 : 14,
                    child: Container(
                      width: 12,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ColorTokens.textPrimary,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: ColorTokens.surfaceBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnchorMarker extends StatelessWidget {
  final double position;
  final String label;
  final Color color;
  final double topOffset;

  const _AnchorMarker({
    required this.position,
    required this.label,
    required this.color,
    this.topOffset = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position - 1,
      top: topOffset,
      child: Column(
        children: [
          Container(
            width: 2,
            height: 16,
            color: color,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
