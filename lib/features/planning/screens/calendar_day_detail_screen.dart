import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import '../widgets/slot_tile.dart';

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
  // Phase 1 stub — replaced when auth is wired. Uses kDevUserId for consistency.
  static const _userId = kDevUserId;

  CalendarDay? _day;
  List<Slot> _slots = [];
  final Map<String, String> _drillNames = {};

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
      body: ListView.separated(
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
            onTap: () => _onSlotTap(index),
            onLongPress: () => _onSlotLongPress(index),
          );
        },
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
        _userId, _day!.date, index, drillId);
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
    final actions = ref.read(planningActionsProvider);
    await actions.clearSlot(_userId, _day!.date, index);
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
      final actions = ref.read(planningActionsProvider);
      try {
        await actions.updateSlotCapacity(_userId, _day!.date, result);
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

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
