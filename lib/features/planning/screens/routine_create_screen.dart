import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
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
  static const _userId = 'local-user';

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
      appBar: ZxAppBar(
        title: 'Create Routine',
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
                child: OutlinedButton.icon(
                  onPressed: _addFixedEntry,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Fixed drill'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.primaryDefault,
                    side: const BorderSide(color: ColorTokens.primaryDefault),
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
                    side: const BorderSide(color: ColorTokens.primaryDefault),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _entries.isNotEmpty;

  Future<void> _addFixedEntry() async {
    // Simplified: prompt for drill ID.
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
    await actions.createRoutine(
      _userId,
      _nameController.text.trim(),
      _entries,
    );

    if (mounted) Navigator.pop(context);
  }
}
