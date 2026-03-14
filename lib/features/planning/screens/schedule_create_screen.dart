import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';

import '../widgets/criterion_editor.dart';
import '../widgets/routine_entry_card.dart';
import '../widgets/template_day_editor.dart';

// S08 §8.12.3 — Schedule creation: name → mode → entries → save.

class ScheduleCreateScreen extends ConsumerStatefulWidget {
  const ScheduleCreateScreen({super.key});

  @override
  ConsumerState<ScheduleCreateScreen> createState() =>
      _ScheduleCreateScreenState();
}

class _ScheduleCreateScreenState extends ConsumerState<ScheduleCreateScreen> {
  final _nameController = TextEditingController();
  ScheduleAppMode _appMode = ScheduleAppMode.list;

  // List mode entries.
  final _listEntries = <RoutineEntry>[];

  // DayPlanning mode template days.
  final _templateDays = <TemplateDay>[];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave {
    if (_nameController.text.trim().isEmpty) return false;
    if (_appMode == ScheduleAppMode.list) return _listEntries.isNotEmpty;
    return _templateDays.isNotEmpty &&
        _templateDays.any((td) => td.entries.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZxAppBar(
        title: 'Create Schedule',
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _canSave
                    ? ColorTokens.primaryDefault
                    : ColorTokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Name field.
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Schedule name',
              labelStyle: TextStyle(color: ColorTokens.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide:
                    const BorderSide(color: ColorTokens.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide:
                    const BorderSide(color: ColorTokens.primaryDefault),
              ),
              filled: true,
              fillColor: ColorTokens.surfaceRaised,
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Mode selector.
          Text(
            'Application Mode',
            style: TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: TypographyTokens.headerWeight,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          SegmentedButton<ScheduleAppMode>(
            segments: const [
              ButtonSegment(
                value: ScheduleAppMode.list,
                label: Text('List'),
              ),
              ButtonSegment(
                value: ScheduleAppMode.dayPlanning,
                label: Text('Day Planning'),
              ),
            ],
            selected: {_appMode},
            onSelectionChanged: (selected) {
              setState(() => _appMode = selected.first);
            },
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return ColorTokens.primaryDefault;
                }
                return ColorTokens.surfaceRaised;
              }),
              foregroundColor:
                  WidgetStateProperty.all(ColorTokens.textPrimary),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),

          // Mode-specific content.
          if (_appMode == ScheduleAppMode.list)
            _buildListModeEntries()
          else
            _buildDayPlanningEntries(),
        ],
      ),
    );
  }

  Widget _buildListModeEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entries',
          style: TextStyle(
            fontSize: TypographyTokens.headerSize,
            fontWeight: TypographyTokens.headerWeight,
            color: ColorTokens.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),

        for (var i = 0; i < _listEntries.length; i++) ...[
          RoutineEntryCard(
            entry: _listEntries[i],
            index: i,
            onRemove: () => setState(() => _listEntries.removeAt(i)),
          ),
          const SizedBox(height: SpacingTokens.sm),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addFixedListEntry,
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
                onPressed: _addCriterionListEntry,
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
    );
  }

  Widget _buildDayPlanningEntries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Template Days',
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
            IconButton(
              onPressed: _addTemplateDay,
              icon: const Icon(Icons.add_circle_outline,
                  color: ColorTokens.primaryDefault),
              tooltip: 'Add template day',
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),

        for (var i = 0; i < _templateDays.length; i++) ...[
          TemplateDayEditor(
            dayIndex: i,
            templateDay: _templateDays[i],
            onChanged: (updated) =>
                setState(() => _templateDays[i] = updated),
            onRemove: () => setState(() => _templateDays.removeAt(i)),
          ),
          const SizedBox(height: SpacingTokens.sm),
        ],
      ],
    );
  }

  void _addTemplateDay() {
    setState(() => _templateDays.add(const TemplateDay(entries: [])));
  }

  Future<void> _addFixedListEntry() async {
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
      setState(() => _listEntries.add(RoutineEntry.fixed(drillId)));
    }
  }

  Future<void> _addCriterionListEntry() async {
    final criterion = await showDialog<GenerationCriterion>(
      context: context,
      builder: (context) => const CriterionEditorDialog(),
    );

    if (criterion != null) {
      setState(
          () => _listEntries.add(RoutineEntry.criterion(criterion)));
    }
  }

  Future<void> _save() async {
    final actions = ref.read(planningActionsProvider);

    String entriesJson;
    if (_appMode == ScheduleAppMode.list) {
      entriesJson =
          jsonEncode(_listEntries.map((e) => e.toJson()).toList());
    } else {
      entriesJson =
          jsonEncode(_templateDays.map((td) => td.toJson()).toList());
    }

    final userId = ref.read(currentUserIdProvider);
    await actions.createSchedule(
      userId,
      _nameController.text.trim(),
      _appMode,
      entriesJson,
    );

    if (mounted) Navigator.pop(context);
  }
}
