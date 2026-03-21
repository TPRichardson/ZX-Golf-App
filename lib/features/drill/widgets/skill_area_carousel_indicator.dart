import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/drill/drill_sort_order.dart';

/// Shared carousel indicator with title, skill area name, and page dots.
/// Used by active_drills_screen and standard_drills_screen.
class SkillAreaCarouselIndicator extends StatelessWidget {
  final String title;
  final int currentPage;

  const SkillAreaCarouselIndicator({
    super.key,
    required this.title,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final currentArea = kSkillAreaDisplayOrder[currentPage];
    final areaColor = ColorTokens.skillArea(currentArea);
    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.sm),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            currentArea.dbValue,
            style: TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: FontWeight.w600,
              color: areaColor,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(kSkillAreaDisplayOrder.length, (index) {
              final isActive = index == currentPage;
              final dotColor =
                  ColorTokens.skillArea(kSkillAreaDisplayOrder[index]);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 14 : 8,
                height: isActive ? 14 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? dotColor
                      : dotColor.withValues(alpha: 0.35),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
