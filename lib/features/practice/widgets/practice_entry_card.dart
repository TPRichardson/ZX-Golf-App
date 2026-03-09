// Practice Entry Card — drill tile in the practice queue.
// Shows drill info, skill area/type badges, and pending vs complete visual styles.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/core/widgets/zx_badge.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';

const _goldStar = Color(0xFFFFD700);

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
            // Left: drill name + structured info + stars.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drill.name,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodyLgSize,
                      fontWeight: FontWeight.w500,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  if (_structuredInfo(drill) != null) ...[
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      _structuredInfo(drill)!,
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ],
                  if (isComplete && sessionScore != null) ...[
                    const SizedBox(height: SpacingTokens.xs),
                    StarRating(
                      stars: scoreToStars(sessionScore!),
                      size: 18,
                      color: _goldStar,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            // Right: badges stacked vertically.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ZxBadge(
                  label: drill.skillArea.dbValue,
                  color: ColorTokens.skillArea(drill.skillArea),
                ),
                const SizedBox(height: SpacingTokens.xs),
                ZxBadge(
                  label: _drillTypeLabel(drill.drillType),
                  color: _drillTypeColor(drill.drillType),
                ),
              ],
            ),
            // Active indicator.
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: SpacingTokens.sm),
                child: Icon(
                  Icons.play_circle_filled,
                  color: ColorTokens.primaryDefault,
                  size: 24,
                ),
              ),
            // Delete button for pending and completed entries.
            if (onRemove != null)
              Padding(
                padding: const EdgeInsets.only(left: SpacingTokens.xs),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: ColorTokens.errorDestructive,
                  onPressed: onRemove,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _structuredInfo(Drill drill) {
    if (drill.requiredSetCount > 1 && drill.requiredAttemptsPerSet != null) {
      return '${drill.requiredSetCount} Sets of ${drill.requiredAttemptsPerSet}';
    }
    if (drill.requiredSetCount > 1) {
      return '${drill.requiredSetCount} Sets';
    }
    if (drill.requiredAttemptsPerSet != null) {
      return '${drill.requiredAttemptsPerSet} Shots';
    }
    return null;
  }

  static String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
    };
  }

  static Color _drillTypeColor(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => ColorTokens.textTertiary,
      DrillType.transition => ColorTokens.primaryDefault,
      DrillType.pressure => ColorTokens.warningIntegrity,
    };
  }
}
