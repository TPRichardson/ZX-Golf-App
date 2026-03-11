// Practice Entry Card — drill tile in the practice queue.
// Shows drill info, skill area/type badges, and pending vs complete visual styles.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';

const _starColor = ColorTokens.primaryDefault;

class PracticeEntryCard extends StatelessWidget {
  final PracticeEntryWithDrill entryWithDrill;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final double? sessionScore;

  const PracticeEntryCard({
    super.key,
    required this.entryWithDrill,
    this.onTap,
    this.onRemove,
    this.sessionScore,
  });

  @override
  Widget build(BuildContext context) {
    final entry = entryWithDrill.entry;
    final drill = entryWithDrill.drill;
    final isComplete = entry.entryType == PracticeEntryType.completedSession;
    final isActive = entry.entryType == PracticeEntryType.activeSession;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        decoration: BoxDecoration(
          color: isComplete
              ? ColorTokens.successDefault.withValues(alpha: 0.08)
              : isActive
                  ? ColorTokens.primaryDefault.withValues(alpha: 0.08)
                  : ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(
            color: isComplete
                ? ColorTokens.successDefault.withValues(alpha: 0.3)
                : isActive
                    ? ColorTokens.primaryDefault.withValues(alpha: 0.3)
                    : ColorTokens.surfaceBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Skill area color indicator.
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: ColorTokens.skillArea(drill.skillArea),
                borderRadius: BorderRadius.circular(ShapeTokens.radiusMicro),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            // Drill name.
            Expanded(
              child: Text(
                drill.name,
                style: TextStyle(
                  fontSize: TypographyTokens.headerSize,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textPrimary,
                ),
              ),
            ),
            // Completed: show stars. Pending: show remove button.
            if (isComplete && sessionScore != null)
              Padding(
                padding: const EdgeInsets.only(left: SpacingTokens.sm),
                child: StarRating(
                  stars: scoreToStars(sessionScore!),
                  size: 20,
                  color: _starColor,
                ),
              )
            else if (onRemove != null)
              Padding(
                padding: const EdgeInsets.only(left: SpacingTokens.xs),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: ColorTokens.textTertiary,
                  onPressed: onRemove,
                ),
              ),
          ],
        ),
      ),
    );
  }

}
