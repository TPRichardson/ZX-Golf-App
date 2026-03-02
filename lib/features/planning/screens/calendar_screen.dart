import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import '../widgets/adherence_badge.dart';
import '../widgets/calendar_day_card.dart';
import 'calendar_day_detail_screen.dart';

// S08 §8.12.1 — Calendar screen: 3-day rolling + 2-week toggle.

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // Phase 3 stub — replaced when auth is wired.
  static const _userId = 'local-user';

  bool _showTwoWeeks = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _rangeStart {
    if (_showTwoWeeks) {
      // Start from Monday of current week.
      return _today.subtract(Duration(days: _today.weekday - 1));
    }
    return _today.subtract(const Duration(days: 1));
  }

  DateTime get _rangeEnd {
    if (_showTwoWeeks) {
      return _rangeStart.add(const Duration(days: 13));
    }
    return _today.add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(calendarDaysProvider((
      userId: _userId,
      start: _rangeStart,
      end: _rangeEnd,
    )));
    final repo = ref.watch(planningRepositoryProvider);

    return Column(
      children: [
        // Toggle + adherence header.
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              daysAsync.when(
                data: (days) => AdherenceBadge(recentDays: days, repo: repo),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('3 Day')),
                  ButtonSegment(value: true, label: Text('2 Week')),
                ],
                selected: {_showTwoWeeks},
                onSelectionChanged: (selected) {
                  setState(() => _showTwoWeeks = selected.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return ColorTokens.primaryDefault;
                    }
                    return ColorTokens.surfaceRaised;
                  }),
                  foregroundColor: WidgetStateProperty.all(
                    ColorTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Calendar day list.
        Expanded(
          child: daysAsync.when(
            data: (days) => _buildDayList(days),
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: ColorTokens.primaryDefault,
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading calendar',
                style: TextStyle(color: ColorTokens.textSecondary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayList(List<CalendarDay> days) {
    final repo = ref.watch(planningRepositoryProvider);

    // Build list of dates in range, pairing with CalendarDay if exists.
    final dateRange = <DateTime>[];
    var current = _rangeStart;
    while (!current.isAfter(_rangeEnd)) {
      dateRange.add(current);
      current = current.add(const Duration(days: 1));
    }

    final dayMap = <DateTime, CalendarDay>{};
    for (final day in days) {
      final dateOnly = DateTime(day.date.year, day.date.month, day.date.day);
      dayMap[dateOnly] = day;
    }

    return ListView.separated(
      padding: const EdgeInsets.all(SpacingTokens.md),
      itemCount: dateRange.length,
      separatorBuilder: (_, _) => const SizedBox(height: SpacingTokens.sm),
      itemBuilder: (context, index) {
        final date = dateRange[index];
        final day = dayMap[date];

        if (day != null) {
          return CalendarDayCard(
            day: day,
            repo: repo,
            isToday: date == _today,
            onTap: () => _navigateToDetail(day),
          );
        }

        // No CalendarDay for this date — show empty placeholder.
        return _EmptyDayCard(
          date: date,
          isToday: date == _today,
          onTap: () => _createAndNavigate(date),
        );
      },
    );
  }

  void _navigateToDetail(CalendarDay day) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CalendarDayDetailScreen(calendarDayId: day.calendarDayId),
    ));
  }

  Future<void> _createAndNavigate(DateTime date) async {
    final repo = ref.read(planningRepositoryProvider);
    final day = await repo.getOrCreateCalendarDay(_userId, date);

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            CalendarDayDetailScreen(calendarDayId: day.calendarDayId),
      ));
    }
  }
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class _EmptyDayCard extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final VoidCallback? onTap;

  const _EmptyDayCard({
    required this.date,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: ColorTokens.surfacePrimary,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(
            color: isToday
                ? ColorTokens.primaryDefault.withValues(alpha: 0.5)
                : ColorTokens.surfaceBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_weekdayNames[date.weekday - 1]}, ${_monthNames[date.month - 1]} ${date.day}',
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textSecondary,
              ),
            ),
            Text(
              'Tap to plan',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
