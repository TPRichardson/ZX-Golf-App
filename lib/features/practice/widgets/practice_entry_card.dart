// Phase 4 — Practice Entry Card widget.
// S13 §13.3 — Queue entry card showing drill name, type badge, status.

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_card.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';

/// S13 §13.3 — Card displaying a practice entry in the queue.
class PracticeEntryCard extends StatelessWidget {
  final PracticeEntryWithDrill entryWithDrill;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const PracticeEntryCard({
    super.key,
    required this.entryWithDrill,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final entry = entryWithDrill.entry;
    final drill = entryWithDrill.drill;

    return ZxCard(
      onTap: onTap,
      child: Row(
        children: [
          // Skill area color indicator.
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: _skillAreaColor(drill.skillArea),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
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
                const SizedBox(height: SpacingTokens.xs),
                Row(
                  children: [
                    _buildTypeBadge(drill.drillType),
                    const SizedBox(width: SpacingTokens.sm),
                    _buildStatusBadge(entry.entryType),
                  ],
                ),
              ],
            ),
          ),
          // Completed indicator.
          if (entry.entryType == PracticeEntryType.completedSession)
            const Padding(
              padding: EdgeInsets.only(right: SpacingTokens.sm),
              child: Icon(
                Icons.check_circle,
                color: ColorTokens.successDefault,
                size: 24,
              ),
            ),
          // Remove button for pending entries.
          if (entry.entryType == PracticeEntryType.pendingDrill &&
              onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: ColorTokens.textTertiary,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(DrillType type) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
      ),
      child: Text(
        type.name,
        style: TextStyle(
          fontSize: TypographyTokens.microSize,
          color: ColorTokens.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(PracticeEntryType type) {
    final (label, color) = switch (type) {
      PracticeEntryType.pendingDrill => ('Pending', ColorTokens.textTertiary),
      PracticeEntryType.activeSession =>
        ('Active', ColorTokens.primaryDefault),
      PracticeEntryType.completedSession =>
        ('Done', ColorTokens.successDefault),
    };

    return Text(
      label,
      style: TextStyle(
        fontSize: TypographyTokens.microSize,
        color: color,
      ),
    );
  }

  Color _skillAreaColor(SkillArea area) {
    return switch (area) {
      SkillArea.driving => ColorTokens.primaryDefault,
      SkillArea.irons => ColorTokens.successDefault,
      SkillArea.putting => const Color(0xFF9B59B6),
      SkillArea.pitching => const Color(0xFFE67E22),
      SkillArea.chipping => const Color(0xFF3498DB),
      SkillArea.woods => const Color(0xFF1ABC9C),
      SkillArea.bunkers => const Color(0xFFF39C12),
    };
  }
}
