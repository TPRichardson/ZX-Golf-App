// Anchor score bar — horizontal bar showing Min/Scratch/Pro markers
// with the user's score plotted on it.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Horizontal bar showing Min, Scratch, and Pro anchor positions on a 0–100 scale,
/// with the user's hit rate plotted on it. The bar gradient goes red → amber → green.
class AnchorScoreBar extends StatelessWidget {
  /// User's actual hit rate percentage (0–100).
  final double userHitRatePct;
  final String? anchorsJson;

  const AnchorScoreBar({
    super.key,
    required this.userHitRatePct,
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
    final userPct = userHitRatePct.clamp(0.0, 100.0);

    return Column(
      children: [
        const SizedBox(height: SpacingTokens.md),
        SizedBox(
          height: 56,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final minPos = (mn / 100.0 * width).clamp(0.0, width);
              final scratchPos = (sc / 100.0 * width).clamp(0.0, width);
              final proPos = (pr / 100.0 * width).clamp(0.0, width);
              final userPos = (userPct / 100.0 * width).clamp(0.0, width);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Bar: solid red up to Min, then RAG gradient from Min onward.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 20,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          stops: [
                            (mn / 100.0),
                            (mn / 100.0),
                            ((mn + sc) / 200.0),
                            (pr / 100.0).clamp(0.0, 1.0),
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
                  ),
                  // Scratch marker.
                  _AnchorMarker(
                    position: scratchPos,
                    label: 'Scratch',
                    color: ColorTokens.ragAmber,
                  ),
                  // Pro marker.
                  _AnchorMarker(
                    position: proPos,
                    label: 'Pro',
                    color: ColorTokens.ragGreen,
                  ),
                  // User score marker.
                  Positioned(
                    left: userPos - 6,
                    top: 14,
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

  const _AnchorMarker({
    required this.position,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position - 1,
      top: 16,
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
              fontSize: TypographyTokens.bodySmSize,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
