import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

import 'criterion_editor.dart';
import 'routine_entry_card.dart';

// S08 §8.12.3 — Template day editor for DayPlanning mode schedules.
// Each template day contains a list of RoutineEntry items.

class TemplateDayEditor extends StatelessWidget {
  final int dayIndex;
  final TemplateDay templateDay;
  final ValueChanged<TemplateDay> onChanged;
  final VoidCallback onRemove;

  const TemplateDayEditor({
    super.key,
    required this.dayIndex,
    required this.templateDay,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${dayIndex + 1}',
                style: TextStyle(
                  fontSize: TypographyTokens.headerSize,
                  fontWeight: TypographyTokens.headerWeight,
                  color: ColorTokens.textPrimary,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${templateDay.entries.length} entries',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  GestureDetector(
                    onTap: onRemove,
                    child: const Icon(Icons.close,
                        size: 18, color: ColorTokens.textTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),

          // Entry list.
          for (var i = 0; i < templateDay.entries.length; i++) ...[
            RoutineEntryCard(
              entry: templateDay.entries[i],
              index: i,
              onRemove: () {
                final newEntries =
                    List<RoutineEntry>.from(templateDay.entries)
                      ..removeAt(i);
                onChanged(TemplateDay(entries: newEntries));
              },
            ),
            const SizedBox(height: SpacingTokens.xs),
          ],

          // Add entry buttons.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addFixedEntry(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Fixed',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.primaryDefault,
                    side: const BorderSide(
                        color: ColorTokens.primaryDefault),
                    padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.xs),
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.xs),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addCriterionEntry(context),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generated',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorTokens.primaryDefault,
                    side: const BorderSide(
                        color: ColorTokens.primaryDefault),
                    padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.xs),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addFixedEntry(BuildContext context) async {
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
      final newEntries = [
        ...templateDay.entries,
        RoutineEntry.fixed(drillId),
      ];
      onChanged(TemplateDay(entries: newEntries));
    }
  }

  Future<void> _addCriterionEntry(BuildContext context) async {
    final criterion = await showDialog<GenerationCriterion>(
      context: context,
      builder: (context) => const CriterionEditorDialog(),
    );

    if (criterion != null) {
      final newEntries = [
        ...templateDay.entries,
        RoutineEntry.criterion(criterion),
      ];
      onChanged(TemplateDay(entries: newEntries));
    }
  }
}
