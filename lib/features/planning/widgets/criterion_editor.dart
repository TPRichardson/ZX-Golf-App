import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// S08 §8.12.3 — Criterion editor dialog for generated routine entries.
// Form: SkillArea (optional), DrillTypes (multi-select), Mode.

class CriterionEditorDialog extends StatefulWidget {
  const CriterionEditorDialog({super.key});

  @override
  State<CriterionEditorDialog> createState() => _CriterionEditorDialogState();
}

class _CriterionEditorDialogState extends State<CriterionEditorDialog> {
  SkillArea? _skillArea;
  final _selectedDrillTypes = <DrillType>{};
  GenerationMode _mode = GenerationMode.weakest;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      title: const Text(
        'Generation Criterion',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill Area picker.
            Text(
              'Skill Area (optional)',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Wrap(
              spacing: SpacingTokens.xs,
              runSpacing: SpacingTokens.xs,
              children: [
                _buildSkillAreaChip(null, 'Any'),
                for (final sa in SkillArea.values)
                  _buildSkillAreaChip(sa, sa.dbValue),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // Drill types multi-select.
            Text(
              'Drill Types',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Wrap(
              spacing: SpacingTokens.xs,
              runSpacing: SpacingTokens.xs,
              children: [
                for (final dt in DrillType.values) _buildDrillTypeChip(dt),
              ],
            ),
            const SizedBox(height: SpacingTokens.md),

            // Generation mode.
            Text(
              'Mode',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Wrap(
              spacing: SpacingTokens.xs,
              runSpacing: SpacingTokens.xs,
              children: [
                for (final mode in GenerationMode.values)
                  _buildModeChip(mode),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              GenerationCriterion(
                skillArea: _skillArea,
                drillTypes: _selectedDrillTypes.toList(),
                mode: _mode,
              ),
            );
          },
          child: Text(
            'Add',
            style: TextStyle(color: ColorTokens.primaryDefault),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillAreaChip(SkillArea? sa, String label) {
    final selected = _skillArea == sa;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: TypographyTokens.bodySize,
          color: selected ? ColorTokens.textPrimary : ColorTokens.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _skillArea = sa),
      selectedColor: ColorTokens.primaryDefault,
      backgroundColor: ColorTokens.surfaceRaised,
      checkmarkColor: ColorTokens.textPrimary,
      side: BorderSide(
        color: selected ? ColorTokens.primaryDefault : ColorTokens.surfaceBorder,
      ),
    );
  }

  Widget _buildDrillTypeChip(DrillType dt) {
    final selected = _selectedDrillTypes.contains(dt);
    return FilterChip(
      label: Text(
        dt.dbValue,
        style: TextStyle(
          fontSize: TypographyTokens.bodySize,
          color: selected ? ColorTokens.textPrimary : ColorTokens.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _selectedDrillTypes.add(dt);
          } else {
            _selectedDrillTypes.remove(dt);
          }
        });
      },
      selectedColor: ColorTokens.primaryDefault,
      backgroundColor: ColorTokens.surfaceRaised,
      checkmarkColor: ColorTokens.textPrimary,
      side: BorderSide(
        color: selected ? ColorTokens.primaryDefault : ColorTokens.surfaceBorder,
      ),
    );
  }

  Widget _buildModeChip(GenerationMode mode) {
    final selected = _mode == mode;
    return ChoiceChip(
      label: Text(
        mode.dbValue,
        style: TextStyle(
          fontSize: TypographyTokens.bodySize,
          color: selected ? ColorTokens.textPrimary : ColorTokens.textSecondary,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _mode = mode),
      selectedColor: ColorTokens.primaryDefault,
      backgroundColor: ColorTokens.surfaceRaised,
      checkmarkColor: ColorTokens.textPrimary,
      side: BorderSide(
        color: selected ? ColorTokens.primaryDefault : ColorTokens.surfaceBorder,
      ),
    );
  }
}
