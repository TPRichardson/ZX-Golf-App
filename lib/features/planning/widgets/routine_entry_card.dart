import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// S08 §8.12.3 — Routine entry card: displays a fixed or criterion entry.

class RoutineEntryCard extends StatelessWidget {
  final RoutineEntry entry;
  final int index;
  final VoidCallback? onRemove;

  const RoutineEntryCard({
    super.key,
    required this.entry,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isFixed = entry.type == RoutineEntryType.fixed;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          // Type icon.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isFixed
                  ? ColorTokens.primaryDefault.withValues(alpha: 0.15)
                  : ColorTokens.warningIntegrity.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            ),
            child: Icon(
              isFixed ? Icons.sports_golf : Icons.auto_awesome,
              size: 16,
              color: isFixed
                  ? ColorTokens.primaryDefault
                  : ColorTokens.warningIntegrity,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),

          // Entry details.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFixed ? 'Fixed Drill' : 'Generated',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                Text(
                  isFixed
                      ? 'Drill: ${entry.drillId ?? 'Unknown'}'
                      : _criterionSummary(entry.criterion!),
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Index badge.
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ColorTokens.surfacePrimary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),

          // Remove button.
          if (onRemove != null) ...[
            const SizedBox(width: SpacingTokens.xs),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 18,
                color: ColorTokens.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _criterionSummary(GenerationCriterion c) {
    final parts = <String>[];
    if (c.skillArea != null) parts.add(c.skillArea!.dbValue);
    if (c.drillTypes.isNotEmpty) {
      parts.add(c.drillTypes.map((d) => d.dbValue).join(', '));
    }
    parts.add(c.mode.dbValue);
    return parts.join(' · ');
  }
}
