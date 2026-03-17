import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/enums.dart';

// S12 §12.6.2 — Analysis filter row.
// Unified pill-style filter bar matching Active Drills pattern.

const _skillAreaDisplayOrder = [
  SkillArea.driving,
  SkillArea.woods,
  SkillArea.approach,
  SkillArea.bunkers,
  SkillArea.pitching,
  SkillArea.chipping,
  SkillArea.putting,
];

class AnalysisFilters extends StatelessWidget {
  final SkillArea? selectedSkillArea;
  final DrillType? drillTypeFilter;
  final ValueChanged<SkillArea?> onSkillAreaChanged;
  final ValueChanged<DrillType?> onDrillTypeChanged;

  const AnalysisFilters({
    super.key,
    required this.selectedSkillArea,
    required this.drillTypeFilter,
    required this.onSkillAreaChanged,
    required this.onDrillTypeChanged,
  });

  static String _typeLabel(DrillType? type) => switch (type) {
        null => 'All Types',
        DrillType.transition => 'Transition',
        DrillType.pressure => 'Pressure',
        DrillType.techniqueBlock => 'Technique',
        DrillType.benchmark => 'Benchmark',
      };

  static String _skillLabel(SkillArea? area) =>
      area?.dbValue ?? 'All Skills';

  static Widget _divider() => Container(
        width: 1,
        height: 24,
        color: ColorTokens.textTertiary,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md, SpacingTokens.sm,
        SpacingTokens.md, SpacingTokens.xs,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          children: [
            // Skill area filter.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (ctx) =>
                        _SkillAreaGridDialog(selected: selectedSkillArea),
                  );
                  if (result == null) return;
                  if (result == 'all') {
                    onSkillAreaChanged(null);
                  } else {
                    onSkillAreaChanged(SkillArea.values
                        .firstWhere((a) => a.dbValue == result));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _skillLabel(selectedSkillArea),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: ColorTokens.primaryDefault,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      const Icon(
                        Icons.filter_list,
                        size: 20,
                        color: ColorTokens.primaryDefault,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _divider(),
            // Drill type filter.
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: ColorTokens.surfaceModal,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusModal),
                      ),
                      title: const Text(
                        'Filter by Drill Type',
                        style: TextStyle(color: ColorTokens.textPrimary),
                      ),
                      contentPadding:
                          const EdgeInsets.all(SpacingTokens.md),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final type in [null, ...DrillType.values])
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: SpacingTokens.sm),
                              child: ZxPillButton(
                                label: _typeLabel(type),
                                expanded: true,
                                centered: true,
                                variant: type == drillTypeFilter
                                    ? ZxPillVariant.primary
                                    : ZxPillVariant.tertiary,
                                onTap: () => Navigator.pop(
                                    ctx, type?.name ?? 'all'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (result == null) return;
                  if (result == 'all') {
                    onDrillTypeChanged(null);
                  } else {
                    onDrillTypeChanged(DrillType.values
                        .firstWhere((t) => t.name == result));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.md,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _typeLabel(drillTypeFilter),
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: ColorTokens.primaryDefault,
                                fontWeight: FontWeight.w500,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      const Icon(
                        Icons.filter_list,
                        size: 20,
                        color: ColorTokens.primaryDefault,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 2x4 grid dialog for skill area filter selection.
class _SkillAreaGridDialog extends StatelessWidget {
  final SkillArea? selected;

  const _SkillAreaGridDialog({required this.selected});

  @override
  Widget build(BuildContext context) {
    final items = <({String value, String label, Color? color})>[
      (value: 'all', label: 'All Skills', color: null),
      for (final area in _skillAreaDisplayOrder)
        (
          value: area.dbValue,
          label: area.dbValue,
          color: ColorTokens.skillArea(area),
        ),
    ];

    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Filter by Skill Area',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      contentPadding: const EdgeInsets.all(SpacingTokens.md),
      content: SizedBox(
        width: 280,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: SpacingTokens.sm,
            crossAxisSpacing: SpacingTokens.sm,
            childAspectRatio: 2.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = item.value == 'all'
                ? selected == null
                : selected?.dbValue == item.value;
            return ZxPillButton(
              label: item.label,
              expanded: true,
              centered: true,
              color: item.color,
              variant: isSelected
                  ? ZxPillVariant.primary
                  : ZxPillVariant.tertiary,
              onTap: () => Navigator.pop(context, item.value),
            );
          },
        ),
      ),
    );
  }
}

