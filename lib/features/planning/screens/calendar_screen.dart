import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

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
  // Phase 1 stub — replaced when auth is wired. Uses kDevUserId for consistency.
  static const _userId = kDevUserId;

  bool _showTwoWeeks = false;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _rangeStartFor(int weekStartDay) {
    if (_showTwoWeeks) {
      // Start from the configured week start day.
      final diff = (_today.weekday - weekStartDay + 7) % 7;
      return _today.subtract(Duration(days: diff));
    }
    return _today;
  }

  DateTime _rangeEndFor(DateTime rangeStart) {
    if (_showTwoWeeks) {
      return rangeStart.add(const Duration(days: 13));
    }
    return _today.add(const Duration(days: 2));
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPreferencesProvider);
    final rangeStart = _rangeStartFor(prefs.weekStartDay);
    final rangeEnd = _rangeEndFor(rangeStart);
    final daysAsync = ref.watch(calendarDaysProvider((
      userId: _userId,
      start: rangeStart,
      end: rangeEnd,
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
              Flexible(
                child: daysAsync.when(
                  data: (days) => AdherenceBadge(recentDays: days, repo: repo),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
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
        // Fix 12 — "Start Today's Practice" button.
        _StartTodayButton(userId: _userId, today: _today),
        // Calendar day list.
        Expanded(
          child: daysAsync.when(
            data: (days) => _showTwoWeeks
                ? _buildWeekGrid(days, rangeStart, rangeEnd)
                : _buildDayList(days, rangeStart, rangeEnd),
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

  Widget _buildDayList(
      List<CalendarDay> days, DateTime rangeStart, DateTime rangeEnd) {
    final repo = ref.watch(planningRepositoryProvider);

    // Build list of dates in range, pairing with CalendarDay if exists.
    final dateRange = <DateTime>[];
    var current = rangeStart;
    while (!current.isAfter(rangeEnd)) {
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

  Widget _buildWeekGrid(
      List<CalendarDay> days, DateTime rangeStart, DateTime rangeEnd) {
    // Map dates to CalendarDay entries.
    final dayMap = <DateTime, CalendarDay>{};
    for (final day in days) {
      final dateOnly = DateTime(day.date.year, day.date.month, day.date.day);
      dayMap[dateOnly] = day;
    }

    // Build 14 dates.
    final dateRange = <DateTime>[];
    var current = rangeStart;
    while (!current.isAfter(rangeEnd)) {
      dateRange.add(current);
      current = current.add(const Duration(days: 1));
    }

    // Day-of-week headers (starting from configured week start).
    final prefs = ref.watch(userPreferencesProvider);
    final headers = List.generate(7, (i) {
      final day = (prefs.weekStartDay + i - 1) % 7;
      return _weekdayNames[day];
    });

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        children: [
          // Header row.
          Row(
            children: [
              for (final h in headers)
                Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          // 2 rows of 7 day cells.
          for (int row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: SpacingTokens.xs),
            Row(
              children: [
                for (int col = 0; col < 7; col++) ...[
                  if (col > 0) const SizedBox(width: SpacingTokens.xs),
                  Expanded(
                    child: _buildGridCell(
                      dateRange[row * 7 + col],
                      dayMap[dateRange[row * 7 + col]],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridCell(DateTime date, CalendarDay? day) {
    final isToday = date == _today;
    final slotCount = day != null
        ? parseSlotsFromJson(day.slots).where((s) => s.isFilled).length
        : 0;

    return GestureDetector(
      onTap: () => _showDayBottomSheet(date, day),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: isToday
                ? ColorTokens.primaryDefault.withValues(alpha: 0.15)
                : ColorTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
            border: Border.all(
              color: isToday
                  ? ColorTokens.primaryDefault
                  : ColorTokens.surfaceBorder,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  color: isToday
                      ? ColorTokens.textPrimary
                      : ColorTokens.textSecondary,
                ),
              ),
              if (slotCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: ColorTokens.primaryDefault.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$slotCount',
                    style: const TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.primaryDefault,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayBottomSheet(DateTime date, CalendarDay? day) {
    final dateLabel =
        '${_weekdayNames[date.weekday - 1]}, ${_monthNames[date.month - 1]} ${date.day}';
    final slots = day != null ? parseSlotsFromJson(day.slots) : <Slot>[];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ColorTokens.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShapeTokens.radiusModal),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                if (date == _today)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorTokens.primaryDefault.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.primaryDefault,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),
            // Slot summary.
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: SpacingTokens.md),
                child: Text(
                  'No slots planned',
                  style: TextStyle(color: ColorTokens.textTertiary),
                ),
              )
            else
              for (final slot in slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: Row(
                    children: [
                      Icon(
                        slot.isFilled
                            ? Icons.sports_golf
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: slot.isFilled
                            ? ColorTokens.primaryDefault
                            : ColorTokens.textTertiary,
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: Text(
                          slot.isFilled ? 'Drill assigned' : 'Empty slot',
                          style: TextStyle(
                            color: slot.isFilled
                                ? ColorTokens.textPrimary
                                : ColorTokens.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: SpacingTokens.sm),
            // Action button.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (day != null) {
                    _navigateToDetail(day);
                  } else {
                    _createAndNavigate(date);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.primaryDefault,
                  side: const BorderSide(color: ColorTokens.primaryDefault),
                ),
                child: const Text('View / Edit Day'),
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],
        ),
      ),
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

/// Fix 12 — "Start Today's Practice" button.
/// Visible only when today's CalendarDay has ≥1 filled Slot and no active PB.
class _StartTodayButton extends ConsumerWidget {
  final String userId;
  final DateTime today;

  const _StartTodayButton({required this.userId, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayDayAsync = ref.watch(todayCalendarDayProvider(userId));
    final activePb = ref.watch(activePracticeBlockProvider(userId));

    return todayDayAsync.when(
      data: (day) {
        final slots = _parseSlotsFromJson(day.slots);
        final filledDrillIds = slots
            .where((s) => s.isFilled)
            .map((s) => s.drillId!)
            .toList();

        // Hide if no filled slots or active PB exists.
        if (filledDrillIds.isEmpty) return const SizedBox.shrink();
        if (activePb.valueOrNull != null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md,
            vertical: SpacingTokens.sm,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _startTodayPractice(context, ref, filledDrillIds),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                'Start Today\'s Practice (${filledDrillIds.length} drills)',
                style: const TextStyle(color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.successDefault,
                padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _startTodayPractice(
    BuildContext context,
    WidgetRef ref,
    List<String> drillIds,
  ) async {
    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(
      userId,
      initialDrillIds: drillIds,
    );

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }

  List<Slot> _parseSlotsFromJson(String slotsJson) =>
      parseSlotsFromJson(slotsJson);
}

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
