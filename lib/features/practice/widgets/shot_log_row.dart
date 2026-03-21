import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Tracked shot entry for the shot log.
class ShotEntry {
  final String instanceId;
  final String label;
  final bool isHit;
  final String club;
  final String? clubId;
  final String rawMetrics;
  final double? score;

  const ShotEntry({
    required this.instanceId,
    required this.label,
    required this.isHit,
    required this.club,
    this.clubId,
    required this.rawMetrics,
    this.score,
  });
}

/// Single row in the shot log.
class ShotLogRow extends StatelessWidget {
  final int index;
  final ShotEntry shot;

  const ShotLogRow({super.key, required this.index, required this.shot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Shot number.
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: ColorTokens.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Hit/miss indicator dot.
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shot.isHit
                  ? ColorTokens.successDefault
                  : ColorTokens.missDefault,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Result label.
          Expanded(
            child: Text(
              shot.label,
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: shot.isHit
                    ? ColorTokens.successDefault
                    : ColorTokens.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Club name.
          Padding(
            padding: const EdgeInsets.only(right: SpacingTokens.xl + SpacingTokens.sm),
            child: Text(
              shot.club,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
