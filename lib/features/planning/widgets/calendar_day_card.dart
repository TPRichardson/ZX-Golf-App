import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// S08 §8.12.1 — Calendar day summary card.

class CalendarDayCard extends StatelessWidget {
  final CalendarDay day;
  final PlanningRepository repo;
  final bool isToday;
  final VoidCallback? onTap;

  const CalendarDayCard({
    super.key,
    required this.day,
    required this.repo,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slots = repo.parseSlots(day.slots);
    final filledSlots = slots.where((s) => s.isFilled).length;
    final completedSlots = slots.where((s) => s.isCompleted).length;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: isToday ? ColorTokens.surfaceRaised : ColorTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(
            color: isToday
                ? ColorTokens.primaryDefault
                : ColorTokens.surfaceBorder,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(day.date),
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                if (filledSlots > 0)
                  Text(
                    '$completedSlots/$filledSlots',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: completedSlots == filledSlots && filledSlots > 0
                          ? ColorTokens.successDefault
                          : ColorTokens.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            // Slot progress dots
            Row(
              children: [
                for (var i = 0; i < slots.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _SlotDot(slot: slots[i]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}';

class _SlotDot extends StatelessWidget {
  final Slot slot;

  const _SlotDot({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _dotColor,
      ),
    );
  }

  Color get _dotColor {
    if (slot.isCompleted) return ColorTokens.successDefault;
    if (slot.isFilled) return ColorTokens.primaryDefault;
    return ColorTokens.surfaceBorder;
  }
}
