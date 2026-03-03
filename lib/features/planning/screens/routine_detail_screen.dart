import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import '../widgets/criterion_editor.dart';
import '../widgets/routine_entry_card.dart';

// S08 §8.12.3 — Routine detail screen: view/edit entries + lifecycle actions.

class RoutineDetailScreen extends ConsumerStatefulWidget {
  final String routineId;

  const RoutineDetailScreen({super.key, required this.routineId});

  @override
  ConsumerState<RoutineDetailScreen> createState() =>
      _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends ConsumerState<RoutineDetailScreen> {
  Routine? _routine;
  List<RoutineEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    final repo = ref.read(planningRepositoryProvider);
    final routine = await repo.getRoutineById(widget.routineId);
    if (routine != null && mounted) {
      setState(() {
        _routine = routine;
        _entries = _parseEntries(routine.entries);
      });
    }
  }

  List<RoutineEntry> _parseEntries(String json) {
    try {
      return (jsonDecode(json) as List<dynamic>)
          .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_routine == null) {
      return Scaffold(
        appBar: const ZxAppBar(title: 'Routine'),
        body: const Center(
          child:
              CircularProgressIndicator(color: ColorTokens.primaryDefault),
        ),
      );
    }

    final isActive = _routine!.status == RoutineStatus.active;

    return Scaffold(
      appBar: ZxAppBar(
        title: _routine!.name,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: ColorTokens.surfaceModal,
            onSelected: _onMenuAction,
            itemBuilder: (context) => [
              // 7B — Clone Routine.
              const PopupMenuItem(
                value: 'duplicate',
                child: Text('Duplicate'),
              ),
              if (isActive)
                const PopupMenuItem(
                  value: 'retire',
                  child: Text('Retire'),
                ),
              if (_routine!.status == RoutineStatus.retired)
                const PopupMenuItem(
                  value: 'reactivate',
                  child: Text('Reactivate'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: TextStyle(color: ColorTokens.errorDestructive)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Status badge.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? ColorTokens.successDefault.withValues(alpha: 0.15)
                      : ColorTokens.textTertiary.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                ),
                child: Text(
                  _routine!.status.dbValue,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: isActive
                        ? ColorTokens.successDefault
                        : ColorTokens.textTertiary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_entries.length} ${_entries.length == 1 ? 'entry' : 'entries'}',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Entries list.
          Text(
            'Entries',
            style: TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: TypographyTokens.headerWeight,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),

          for (var i = 0; i < _entries.length; i++) ...[
            RoutineEntryCard(
              entry: _entries[i],
              index: i,
              onRemove: isActive ? () => _removeEntry(i) : null,
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],

          // Add entry buttons (only when active).
          if (isActive) ...[
            const SizedBox(height: SpacingTokens.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addFixedEntry,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Fixed drill'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.primaryDefault,
                      side: const BorderSide(
                          color: ColorTokens.primaryDefault),
                    ),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addCriterionEntry,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Generated'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorTokens.primaryDefault,
                      side: const BorderSide(
                          color: ColorTokens.primaryDefault),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _removeEntry(int index) async {
    final newEntries = List<RoutineEntry>.from(_entries)..removeAt(index);
    if (newEntries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Routine must have at least one entry')),
        );
      }
      return;
    }

    try {
      final actions = ref.read(planningActionsProvider);
      await actions.updateRoutineEntries(_routine!.routineId, newEntries);
      await _loadRoutine();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _addFixedEntry() async {
    final controller = TextEditingController();
    final drillId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Add fixed drill'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Drill ID'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (drillId != null && drillId.isNotEmpty) {
      try {
        final newEntries = [..._entries, RoutineEntry.fixed(drillId)];
        final actions = ref.read(planningActionsProvider);
        await actions.updateRoutineEntries(
            _routine!.routineId, newEntries);
        await _loadRoutine();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _addCriterionEntry() async {
    final criterion = await showDialog<GenerationCriterion>(
      context: context,
      builder: (context) => const CriterionEditorDialog(),
    );

    if (criterion != null) {
      try {
        final newEntries = [
          ..._entries,
          RoutineEntry.criterion(criterion),
        ];
        final actions = ref.read(planningActionsProvider);
        await actions.updateRoutineEntries(
            _routine!.routineId, newEntries);
        await _loadRoutine();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _onMenuAction(String action) async {
    final actions = ref.read(planningActionsProvider);
    try {
      switch (action) {
        // 7B — Clone Routine with entries, append " (Copy)".
        case 'duplicate':
          final repo = ref.read(planningRepositoryProvider);
          final newRoutine = await repo.createRoutineWithEntries(
            _routine!.userId,
            '${_routine!.name} (Copy)',
            _entries,
          );
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RoutineDetailScreen(routineId: newRoutine.routineId),
              ),
            );
          }
        case 'retire':
          await actions.retireRoutine(_routine!.routineId);
          await _loadRoutine();
        case 'reactivate':
          await actions.reactivateRoutine(_routine!.routineId);
          await _loadRoutine();
        case 'delete':
          await actions.deleteRoutine(_routine!.routineId);
          if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}
