import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';

// S08 §8.12.1 — 4-week adherence headline percentage.

class AdherenceBadge extends StatelessWidget {
  final List<CalendarDay> recentDays;
  final PlanningRepository repo;

  const AdherenceBadge({
    super.key,
    required this.recentDays,
    required this.repo,
  });

  @override
  Widget build(BuildContext context) {
    final adherence = _calculateAdherence();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: adherence >= 0.7
                ? ColorTokens.successDefault
                : adherence >= 0.4
                    ? ColorTokens.warningIntegrity
                    : ColorTokens.textTertiary,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            '${(adherence * 100).round()}% adherence',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAdherence() {
    if (recentDays.isEmpty) return 0;

    var totalPlanned = 0;
    var totalCompleted = 0;

    for (final day in recentDays) {
      final slots = repo.parseSlots(day.slots);
      for (final slot in slots) {
        if (slot.planned && slot.isFilled) {
          totalPlanned++;
          if (slot.isCompleted) totalCompleted++;
        }
      }
    }

    if (totalPlanned == 0) return 0;
    return totalCompleted / totalPlanned;
  }
}
