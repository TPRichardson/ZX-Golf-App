import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/features/drill/active_drills_screen.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import '../widgets/slot_tile.dart';
import '../widgets/planning_actions_sheet.dart';

// S08 §8.12.2 — Single day detail with slot list.

class CalendarDayDetailScreen extends ConsumerStatefulWidget {
  final String calendarDayId;

  const CalendarDayDetailScreen({
    super.key,
    required this.calendarDayId,
  });

  @override
  ConsumerState<CalendarDayDetailScreen> createState() =>
      _CalendarDayDetailScreenState();
}

class _CalendarDayDetailScreenState
    extends ConsumerState<CalendarDayDetailScreen> {
  CalendarDay? _day;
  List<Slot> _slots = [];
  final Map<String, String> _drillNames = {};
  final Map<String, SkillArea> _drillSkillAreas = {};

  @override
  void initState() {
    super.initState();
    _loadDay();
  }

  Future<void> _loadDay() async {
    final repo = ref.read(planningRepositoryProvider);
    final drillRepo = ref.read(drillRepositoryProvider);
    final day = await repo.getCalendarDayById(widget.calendarDayId);
    if (day != null && mounted) {
      final slots = repo.parseSlots(day.slots);
      await _resolveDrillNames(drillRepo, slots);
      if (mounted) {
        setState(() {
          _day = day;
          _slots = slots;
        });
      }
    }
  }

  Future<void> _resolveDrillNames(
      DrillRepository drillRepo, List<Slot> slots) async {
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
  }

  @override
  Widget build(BuildContext context) {
    if (_day == null) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Day Detail'),
        body: const Center(
          child: CircularProgressIndicator(
            color: ColorTokens.primaryDefault,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: ZxAppBar(
        title: _formatDate(_day!.date),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _editCapacity,
            tooltip: 'Edit capacity',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(SpacingTokens.md),
              itemCount: _slots.length,
              separatorBuilder: (_, _) => const SizedBox(height: SpacingTokens.sm),
              itemBuilder: (context, index) {
                final slot = _slots[index];
                return SlotTile(
                  slot: slot,
                  index: index,
                  drillName: slot.drillId != null
                      ? _drillNames[slot.drillId]
                      : null,
                  skillArea: slot.drillId != null
                      ? _drillSkillAreas[slot.drillId]
                      : null,
                  onTap: () => _onSlotTap(index),
                  onLongPress: () => _onSlotLongPress(index),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm,
            ),
            color: ColorTokens.surfaceRaised,
            child: Row(
              children: [
                Expanded(
                  child: ZxPillButton(
                    label: 'Routine',
                    icon: Icons.add,
                    variant: ZxPillVariant.primary,
                    size: ZxPillSize.sm,
                    expanded: true,
                    centered: true,
                    onTap: () => _showRoutinePicker(),
                  ),
                ),
                const SizedBox(width: SpacingTokens.xs),
                Expanded(
                  child: ZxPillButton(
                    label: 'Schedule',
                    icon: Icons.add,
                    variant: ZxPillVariant.primary,
                    size: ZxPillSize.sm,
                    expanded: true,
                    centered: true,
                    onTap: () => _showSchedulePicker(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSlotTap(int index) {
    final slot = _slots[index];

    if (slot.isEmpty) {
      // Show drill picker (simplified for Phase 5).
      _showDrillAssignDialog(index);
    } else if (slot.completionState == CompletionState.incomplete) {
      _showSlotActionsSheet(index);
    }
  }

  void _onSlotLongPress(int index) {
    _showSlotActionsSheet(index);
  }

  void _showSlotActionsSheet(int index) {
    final slot = _slots[index];

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(ShapeTokens.radiusModal)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (slot.isFilled &&
                slot.completionState == CompletionState.incomplete)
              ListTile(
                leading: const Icon(Icons.check, color: ColorTokens.successDefault),
                title: const Text('Mark complete'),
                onTap: () {
                  Navigator.pop(context);
                  _markManualComplete(index);
                },
              ),
            if (slot.isCompleted)
              ListTile(
                leading: const Icon(Icons.undo, color: ColorTokens.primaryDefault),
                title: const Text('Revert completion'),
                onTap: () {
                  Navigator.pop(context);
                  _revertCompletion(index);
                },
              ),
            if (slot.isFilled)
              ListTile(
                leading: const Icon(Icons.clear, color: ColorTokens.errorDestructive),
                title: const Text('Clear slot'),
                onTap: () {
                  Navigator.pop(context);
                  _clearSlot(index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDrillAssignDialog(int index) async {
    final drillId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ActiveDrillsScreen(slotPickMode: true),
      ),
    );

    if (drillId != null && drillId.isNotEmpty) {
      final userId = ref.read(currentUserIdProvider);
      final actions = ref.read(planningActionsProvider);
      await actions.assignDrillToSlot(
        userId, _day!.date, index, drillId);
      await _loadDay();
    }
  }

  Future<void> _markManualComplete(int index) async {
    final actions = ref.read(planningActionsProvider);
    await actions.markSlotManualComplete(_day!.calendarDayId, index);
    await _loadDay();
  }

  Future<void> _revertCompletion(int index) async {
    final actions = ref.read(planningActionsProvider);
    await actions.revertSlotCompletion(_day!.calendarDayId, index);
    await _loadDay();
  }

  Future<void> _clearSlot(int index) async {
    final userId = ref.read(currentUserIdProvider);
    final actions = ref.read(planningActionsProvider);
    await actions.clearSlot(userId, _day!.date, index);
    await _loadDay();
  }

  Future<void> _editCapacity() async {
    final controller =
        TextEditingController(text: _day!.slotCapacity.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Slot capacity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Number of slots',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              Navigator.pop(context, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final userId = ref.read(currentUserIdProvider);
      final actions = ref.read(planningActionsProvider);
      try {
        await actions.updateSlotCapacity(userId, _day!.date, result);
        await _loadDay();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  void _showRoutinePicker() => showRoutinePickerSheet(
        context, ref,
        userId: ref.read(currentUserIdProvider),
        date: _day!.date,
        onApplied: _loadDay,
      );

  void _showSchedulePicker() => showSchedulePickerSheet(
        context, ref,
        userId: ref.read(currentUserIdProvider),
        date: _day!.date,
        onApplied: _loadDay,
      );

  String _formatDate(DateTime date) =>
      formatDate(date, includeWeekday: true);
}
