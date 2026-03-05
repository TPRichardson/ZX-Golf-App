import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

import '../../settings/calendar_defaults_screen.dart';
import '../widgets/adherence_badge.dart';
import '../widgets/calendar_day_card.dart';
import '../widgets/slot_tile.dart';
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

  // 2-week grid: selected day for inline slot panel.
  DateTime? _selectedDay;

  // Heat scale ceiling, computed from surrounding data.
  int _maxSlots = 1;

  // Drill name cache for inline slot panel.
  final Map<String, String> _drillNames = {};

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
  void initState() {
    super.initState();
    _selectedDay = _today;
    _computeHeatRange();
  }

  /// Fetch 60-day window to determine max filled slots for heat colouring.
  Future<void> _computeHeatRange() async {
    final repo = ref.read(planningRepositoryProvider);
    final days = await repo.getCalendarDaysByUser(
      _userId,
      from: _today.subtract(const Duration(days: 30)),
      to: _today.add(const Duration(days: 30)),
    );
    if (!mounted) return;
    int maxFilled = 1;
    for (final day in days) {
      final filled =
          parseSlotsFromJson(day.slots).where((s) => s.isFilled).length;
      maxFilled = max(maxFilled, filled);
    }
    setState(() => _maxSlots = maxFilled);
  }

  /// Resolve drill names for slots on the selected day.
  Future<void> _resolveDrillNames(List<Slot> slots) async {
    final drillRepo = ref.read(drillRepositoryProvider);
    final ids = slots
        .map((s) => s.drillId)
        .whereType<String>()
        .where((id) => !_drillNames.containsKey(id))
        .toSet();
    for (final id in ids) {
      final drill = await drillRepo.getById(id);
      if (drill != null) {
        _drillNames[id] = drill.name;
      }
    }
    if (mounted && ids.isNotEmpty) setState(() {});
  }

  /// Heat colour interpolated from surfaceRaised (0 slots) → primaryDefault at ~0.35 alpha.
  Color _heatColor(int filled) {
    if (filled == 0) return ColorTokens.surfaceRaised;
    final t = (filled / _maxSlots).clamp(0.0, 1.0);
    return ColorTokens.primaryDefault.withValues(alpha: 0.08 + t * 0.32);
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
            children: [
              Expanded(
                child: daysAsync.when(
                  data: (days) => AdherenceBadge(recentDays: days, repo: repo),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              // Link to slot capacity settings.
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CalendarDefaultsScreen(),
                )),
                child: const Icon(
                  Icons.tune,
                  size: 20,
                  color: ColorTokens.textSecondary,
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              _ViewToggle(
                showTwoWeeks: _showTwoWeeks,
                onChanged: (v) => setState(() => _showTwoWeeks = v),
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
          const SizedBox(height: SpacingTokens.md),
          // Inline slot panel for selected day.
          Expanded(
            child: _buildInlineSlotPanel(dayMap),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(DateTime date, CalendarDay? day) {
    final isToday = date == _today;
    final isSelected = _selectedDay != null &&
        date.year == _selectedDay!.year &&
        date.month == _selectedDay!.month &&
        date.day == _selectedDay!.day;
    final filledCount = day != null
        ? parseSlotsFromJson(day.slots).where((s) => s.isFilled).length
        : 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = date),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: _heatColor(filledCount),
            borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
            border: Border.all(
              color: isSelected
                  ? ColorTokens.primaryHover
                  : isToday
                      ? ColorTokens.primaryDefault
                      : ColorTokens.surfaceBorder,
              width: isSelected ? 2.5 : (isToday ? 2 : 1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (filledCount > 0)
                Text(
                  '$filledCount',
                  style: const TextStyle(
                    fontSize: TypographyTokens.microSize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.primaryDefault,
                  ),
                ),
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: TypographyTokens.microSize,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  color: isToday
                      ? ColorTokens.textPrimary
                      : ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Inline slot panel below the 2-week grid, showing slots for the selected day.
  Widget _buildInlineSlotPanel(Map<DateTime, CalendarDay> dayMap) {
    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    final dateLabel =
        '${_weekdayNames[_selectedDay!.weekday - 1]}, ${_monthNames[_selectedDay!.month - 1]} ${_selectedDay!.day}';
    final selectedDateOnly = DateTime(
        _selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final day = dayMap[selectedDateOnly];
    final slots = day != null ? parseSlotsFromJson(day.slots) : <Slot>[];

    // Trigger drill name resolution for filled slots.
    if (slots.any((s) => s.isFilled)) {
      _resolveDrillNames(slots);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header.
        Row(
          children: [
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
            if (_selectedDay == _today) ...[
              const SizedBox(width: SpacingTokens.sm),
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
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        // Slot list.
        if (slots.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No slots planned',
                    style: TextStyle(color: ColorTokens.textTertiary),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  OutlinedButton.icon(
                    onPressed: () => _addSlotForDate(_selectedDay!),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add slot'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.primaryDefault,
                      side:
                          const BorderSide(color: ColorTokens.primaryDefault),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: slots.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: SpacingTokens.xs),
              itemBuilder: (context, index) {
                if (index < slots.length) {
                  final slot = slots[index];
                  return SlotTile(
                    slot: slot,
                    index: index,
                    drillName: slot.drillId != null
                        ? _drillNames[slot.drillId]
                        : null,
                    onTap: () => _onInlineSlotTap(day!, slots, index),
                  );
                }
                // "Add slot" button after last slot.
                return Padding(
                  padding: const EdgeInsets.only(top: SpacingTokens.xs),
                  child: OutlinedButton.icon(
                    onPressed: () => _addSlot(day!),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add slot'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.primaryDefault,
                      side: const BorderSide(
                          color: ColorTokens.primaryDefault),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// Add an empty slot to a CalendarDay by incrementing its capacity.
  Future<void> _addSlot(CalendarDay day) async {
    final actions = ref.read(planningActionsProvider);
    final currentSlots = parseSlotsFromJson(day.slots);
    await actions.updateSlotCapacity(
        _userId, day.date, currentSlots.length + 1);
  }

  /// Add a slot to a day that may not exist yet (creates CalendarDay first).
  Future<void> _addSlotForDate(DateTime date) async {
    final repo = ref.read(planningRepositoryProvider);
    final day = await repo.getOrCreateCalendarDay(_userId, date);
    final actions = ref.read(planningActionsProvider);
    final currentSlots = parseSlotsFromJson(day.slots);
    await actions.updateSlotCapacity(_userId, date, currentSlots.length + 1);
  }

  /// Handle tap on an inline slot: empty → assign drill, filled → actions sheet.
  void _onInlineSlotTap(CalendarDay day, List<Slot> slots, int index) {
    final slot = slots[index];
    if (slot.isEmpty) {
      _showDrillAssignDialog(day, index);
    } else {
      _showSlotActionsSheet(day, index, slot);
    }
  }

  Future<void> _showDrillAssignDialog(CalendarDay day, int index) async {
    final controller = TextEditingController();
    final drillId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Assign drill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter drill ID',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (drillId != null && drillId.isNotEmpty) {
      final actions = ref.read(planningActionsProvider);
      await actions.assignDrillToSlot(
          _userId, day.date, index, drillId);
      _computeHeatRange();
    }
  }

  void _showSlotActionsSheet(CalendarDay day, int index, Slot slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ShapeTokens.radiusModal)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.isFilled &&
                slot.completionState == CompletionState.incomplete)
              ListTile(
                leading: const Icon(Icons.check,
                    color: ColorTokens.successDefault),
                title: const Text('Mark complete'),
                onTap: () {
                  Navigator.pop(context);
                  _markManualComplete(day.calendarDayId, index);
                },
              ),
            if (slot.isCompleted)
              ListTile(
                leading: const Icon(Icons.undo,
                    color: ColorTokens.primaryDefault),
                title: const Text('Revert completion'),
                onTap: () {
                  Navigator.pop(context);
                  _revertCompletion(day.calendarDayId, index);
                },
              ),
            if (slot.isFilled)
              ListTile(
                leading: const Icon(Icons.clear,
                    color: ColorTokens.errorDestructive),
                title: const Text('Clear slot'),
                onTap: () {
                  Navigator.pop(context);
                  _clearSlot(day.date, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _markManualComplete(
      String calendarDayId, int index) async {
    final actions = ref.read(planningActionsProvider);
    await actions.markSlotManualComplete(calendarDayId, index);
  }

  Future<void> _revertCompletion(
      String calendarDayId, int index) async {
    final actions = ref.read(planningActionsProvider);
    await actions.revertSlotCompletion(calendarDayId, index);
  }

  Future<void> _clearSlot(DateTime date, int index) async {
    final actions = ref.read(planningActionsProvider);
    await actions.clearSlot(_userId, date, index);
    _computeHeatRange();
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

/// Compact 3D / 2W toggle replacing SegmentedButton for narrow layouts.
class _ViewToggle extends StatelessWidget {
  final bool showTwoWeeks;
  final ValueChanged<bool> onChanged;

  const _ViewToggle({required this.showTwoWeeks, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option('3D', false),
          _option('2W', true),
        ],
      ),
    );
  }

  Widget _option(String label, bool value) {
    final selected = showTwoWeeks == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? ColorTokens.primaryDefault : Colors.transparent,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.microSize,
            color: selected
                ? ColorTokens.textPrimary
                : ColorTokens.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
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
