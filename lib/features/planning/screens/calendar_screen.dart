import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

import '../widgets/slot_tile.dart';
import 'calendar_day_detail_screen.dart';
import '../widgets/planning_actions_sheet.dart';

// S08 §8.12.1 — Calendar screen: 3-day rolling + 2-week toggle.

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Phase 1 stub — replaced when auth is wired. Uses kDevUserId for consistency.
  static const _userId = kDevUserId;

  // 2-week grid: week offset from current week (0 = this week).
  int _weekOffset = 0;

  // 2-week grid: selected day for inline slot panel.
  DateTime? _selectedDay;

  // Heat scale ceiling, computed from surrounding data.
  int _maxSlots = 1;

  // Drill info cache for inline slot panel.
  final Map<String, String> _drillNames = {};
  final Map<String, SkillArea> _drillSkillAreas = {};

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _rangeStartFor(int weekStartDay) {
    final diff = (_today.weekday - weekStartDay + 7) % 7;
    return _today.subtract(Duration(days: diff)).add(Duration(days: _weekOffset * 7));
  }

  DateTime _rangeEndFor(DateTime rangeStart) {
    return rangeStart.add(const Duration(days: 13));
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _today;
    _computeHeatRange();
  }

  /// Fetch 60-day window to determine max slot count for heat colouring.
  Future<void> _computeHeatRange() async {
    final repo = ref.read(planningRepositoryProvider);
    final days = await repo.getCalendarDaysByUser(
      _userId,
      from: _today.subtract(const Duration(days: 30)),
      to: _today.add(const Duration(days: 30)),
    );
    if (!mounted) return;
    int maxCount = 1;
    for (final day in days) {
      final count = parseSlotsFromJson(day.slots).length;
      maxCount = max(maxCount, count);
    }
    setState(() => _maxSlots = maxCount);
  }

  /// Resolve drill names and skill areas for slots on the selected day.
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
        _drillSkillAreas[id] = drill.skillArea;
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
    super.build(context); // AutomaticKeepAliveClientMixin
    final prefs = ref.watch(userPreferencesProvider);
    final rangeStart = _rangeStartFor(prefs.weekStartDay);
    final rangeEnd = _rangeEndFor(rangeStart);
    // Fetch a wide window (90 days back, 180 days ahead) so week shifts
    // reuse the same provider instance and avoid loading-state blinks.
    final queryStart = _today.subtract(const Duration(days: 90));
    final queryEnd = _today.add(const Duration(days: 180));
    final daysAsync = ref.watch(calendarDaysProvider((
      userId: _userId,
      start: queryStart,
      end: queryEnd,
    )));
    return Column(
      children: [
        // Week navigation header.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md, 12, SpacingTokens.md, 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _weekOffset -= 1),
                    child: const Padding(
                      padding: EdgeInsets.all(SpacingTokens.xs),
                      child: Icon(Icons.chevron_left, size: 22, color: ColorTokens.primaryDefault),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _weekOffset = 0;
                      _selectedDay = _today;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                        vertical: SpacingTokens.xs,
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.primaryDefault,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _weekOffset += 1),
                    child: const Padding(
                      padding: EdgeInsets.all(SpacingTokens.xs),
                      child: Icon(Icons.chevron_right, size: 22, color: ColorTokens.primaryDefault),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Calendar grid.
        Expanded(
          child: daysAsync.when(
            data: (days) => _buildWeekGrid(days, rangeStart, rangeEnd),
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

    return Column(
      children: [
        // Padded top section: grid + slot panel.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, 0,
            ),
            child: Column(
              children: [
                // Header row — highlight column matching selected day.
                Row(
                  children: [
                    for (int i = 0; i < headers.length; i++)
                      Expanded(
                        child: Center(
                          child: Text(
                            headers[i],
                            style: TextStyle(
                              fontSize: TypographyTokens.bodySize,
                              fontWeight: _selectedDay != null &&
                                      (_selectedDay!.weekday - prefs.weekStartDay + 7) % 7 == i
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: _selectedDay != null &&
                                      (_selectedDay!.weekday - prefs.weekStartDay + 7) % 7 == i
                                  ? ColorTokens.primaryDefault
                                  : ColorTokens.textTertiary,
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
          ),
        ),
        // Routine / Schedule — full width, connected to bottom nav.
        _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildGridCell(DateTime date, CalendarDay? day) {
    final isToday = date == _today;
    final isSelected = _selectedDay != null &&
        date.year == _selectedDay!.year &&
        date.month == _selectedDay!.month &&
        date.day == _selectedDay!.day;
    final slots = day != null ? parseSlotsFromJson(day.slots) : <Slot>[];
    final totalSlots = slots.length;
    final completedCount = slots.where((s) => s.isCompleted).length;

    // Use consistent border width to prevent layout shift on selection.
    const double borderWidth = 2.5;
    final Color borderColor = isSelected
        ? ColorTokens.primaryDefault
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        if (isSelected) {
          // Second tap on already-selected day — open detail page.
          if (day != null) {
            _navigateToDetail(day);
          } else {
            _createAndNavigate(date);
          }
        } else {
          setState(() => _selectedDay = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: _heatColor(totalSlots),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _ordinalDay(date.day),
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                color: isToday
                    ? ColorTokens.textPrimary
                    : ColorTokens.textSecondary,
              ),
            ),
            Text(
              totalSlots > 0 ? '$completedCount/$totalSlots' : '–',
              style: TextStyle(
                fontSize: TypographyTokens.bodySmSize,
                fontWeight: FontWeight.w600,
                color: totalSlots > 0
                    ? ColorTokens.primaryDefault
                    : ColorTokens.textTertiary,
              ),
            ),
          ],
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
        // Day header with +/- slot buttons.
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
            if (slots.any((s) => s.isFilled)) ...[
              const SizedBox(width: SpacingTokens.sm),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 22,
                  icon: const Icon(Icons.play_circle_filled,
                      color: ColorTokens.successDefault),
                  tooltip: _selectedDay == _today
                      ? 'Start today\'s practice'
                      : 'Start practice based on this day',
                  onPressed: () => _startDayPractice(slots),
                ),
              ),
            ],
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
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.primaryDefault,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Remove slot button — only when there are removable empty slots.
            if (slots.any((s) => s.isEmpty && !s.isCompleted && !s.isMatrixSlot))
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: const Icon(Icons.remove_circle_outline,
                      color: ColorTokens.textTertiary),
                  tooltip: 'Remove empty slot',
                  onPressed: () => _removeSlotForDate(_selectedDay!, slots.length),
                ),
              ),
            const Text(
              'slot',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
            // Add slot button.
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: const Icon(Icons.add_circle_outline,
                    color: ColorTokens.primaryDefault),
                tooltip: 'Add slot',
                onPressed: () => _addSlotForDate(_selectedDay!),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        // Slot list.
        if (slots.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No slots planned',
                style: TextStyle(color: ColorTokens.textTertiary),
              ),
            ),
          )
        else
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                padding: const EdgeInsets.only(right: SpacingTokens.sm),
                itemCount: slots.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: SpacingTokens.xs),
                itemBuilder: (context, index) {
                  final slot = slots[index];
                  return SlotTile(
                    slot: slot,
                    index: index,
                    drillName: slot.drillId != null
                        ? _drillNames[slot.drillId]
                        : null,
                    skillArea: slot.drillId != null
                        ? _drillSkillAreas[slot.drillId]
                        : null,
                    onTap: () => _onInlineSlotTap(day!, slots, index),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    if (_selectedDay == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: ZxPillButton(
              label: 'Add Routine',
              icon: Icons.add,
              size: ZxPillSize.md,
              variant: ZxPillVariant.primary,
              expanded: true,
              centered: true,
              onTap: () => _showRoutinePicker(_selectedDay!),
            ),
          ),
          ZxPillButton(
            label: 'Add Schedule',
            icon: Icons.add,
            size: ZxPillSize.md,
            variant: ZxPillVariant.primary,
            expanded: true,
            centered: true,
            onTap: () => _showSchedulePicker(_selectedDay!),
          ),
        ],
      ),
    );
  }

  /// Add a single slot to a day. If the day doesn't exist yet, creates it with 1 slot
  /// (bypasses default capacity pattern so user gets exactly what they asked for).
  Future<void> _addSlotForDate(DateTime date) async {
    final repo = ref.read(planningRepositoryProvider);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final existing = await repo.getCalendarDayByDate(_userId, dateOnly);
    if (existing != null) {
      final currentSlots = parseSlotsFromJson(existing.slots);
      final actions = ref.read(planningActionsProvider);
      await actions.updateSlotCapacity(_userId, dateOnly, currentSlots.length + 1);
    } else {
      final actions = ref.read(planningActionsProvider);
      await actions.updateSlotCapacity(_userId, dateOnly, 1);
    }
  }

  /// Remove the last slot from a day (reduce capacity by 1).
  Future<void> _removeSlotForDate(DateTime date, int currentCount) async {
    if (currentCount <= 0) return;
    final actions = ref.read(planningActionsProvider);
    try {
      await actions.updateSlotCapacity(_userId, date, currentCount - 1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showRoutinePicker(DateTime date) =>
      showRoutinePickerSheet(context, ref, userId: _userId, date: date);

  void _showSchedulePicker(DateTime date) =>
      showSchedulePickerSheet(context, ref, userId: _userId, date: date);

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
    final drillId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const PracticePoolScreen(pickMode: true),
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

  Future<void> _startDayPractice(List<Slot> slots) async {
    final drillIds = slots
        .where((s) => s.isFilled && !s.isCompleted)
        .map((s) => s.drillId!)
        .toList();
    if (drillIds.isEmpty) return;

    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(
      _userId,
      initialDrillIds: drillIds,
      surfaceType: envSurface.surface,
    );

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: _userId,
        ),
      ));
    }
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

String _ordinalDay(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  return switch (day % 10) {
    1 => '${day}st',
    2 => '${day}nd',
    3 => '${day}rd',
    _ => '${day}th',
  };
}

const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];


