import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/features/drill/active_drills_screen.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';

import '../widgets/criterion_editor.dart';
import '../widgets/routine_entry_card.dart';

// S08 §8.12.3 — Routine creation: name → entries → save.

class RoutineCreateScreen extends ConsumerStatefulWidget {
  const RoutineCreateScreen({super.key});

  @override
  ConsumerState<RoutineCreateScreen> createState() =>
      _RoutineCreateScreenState();
}

class _RoutineCreateScreenState extends ConsumerState<RoutineCreateScreen> {
  final _nameController = TextEditingController();
  final _entries = <RoutineEntry>[];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ZxAppBar(title: 'Create Routine'),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          // Name field.
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: ColorTokens.textPrimary),
            decoration: InputDecoration(
              labelText: 'Routine name',
              labelStyle: TextStyle(color: ColorTokens.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide: const BorderSide(color: ColorTokens.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide: const BorderSide(color: ColorTokens.primaryDefault),
              ),
              filled: true,
              fillColor: ColorTokens.surfaceRaised,
            ),
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
              onRemove: () => setState(() => _entries.removeAt(i)),
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],

          // Add entry buttons.
          Row(
            children: [
              Expanded(
                child: ZxPillButton(
                  label: 'Fixed Drill',
                  icon: Icons.add,
                  variant: ZxPillVariant.secondary,
                  expanded: true,
                  centered: true,
                  onTap: _addFixedEntry,
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: ZxPillButton(
                  label: 'Generated',
                  icon: Icons.auto_awesome,
                  variant: ZxPillVariant.secondary,
                  expanded: true,
                  centered: true,
                  onTap: _addCriterionEntry,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md,
            SpacingTokens.sm,
            SpacingTokens.md,
            SpacingTokens.md,
          ),
          child: ZxPillButton(
            label: 'Save Routine',
            icon: Icons.check,
            variant: ZxPillVariant.progress,
            expanded: true,
            centered: true,
            onTap: _canSave ? _save : null,
          ),
        ),
      ),
    );
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _entries.isNotEmpty;

  Future<void> _addFixedEntry() async {
    final drillId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ActiveDrillsScreen(slotPickMode: true),
      ),
    );

    if (drillId != null && drillId.isNotEmpty) {
      setState(() => _entries.add(RoutineEntry.fixed(drillId)));
    }
  }

  Future<void> _addCriterionEntry() async {
    final criterion = await showDialog<GenerationCriterion>(
      context: context,
      builder: (context) => const CriterionEditorDialog(),
    );

    if (criterion != null) {
      setState(() => _entries.add(RoutineEntry.criterion(criterion)));
    }
  }

  Future<void> _save() async {
    final actions = ref.read(planningActionsProvider);
    final userId = ref.read(currentUserIdProvider);
    await actions.createRoutine(
      userId,
      _nameController.text.trim(),
      _entries,
    );

    if (mounted) Navigator.pop(context);
  }
}
