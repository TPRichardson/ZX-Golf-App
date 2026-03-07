import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S12 §12.6.2 — Analysis filter row.
// Scope, DrillType, Resolution, DateRange, ChartMode.

class AnalysisFilters extends ConsumerWidget {
  final AnalysisScope scope;
  final SkillArea? selectedSkillArea;
  final String? selectedSubskillId;
  final String? selectedDrillId;
  final DrillType? drillTypeFilter;
  final SurfaceType? surfaceFilter;
  final TimeResolution resolution;
  final DateRangePreset dateRange;
  final ChartMode chartMode;
  final ValueChanged<AnalysisScope> onScopeChanged;
  final ValueChanged<SkillArea?> onSkillAreaChanged;
  final ValueChanged<String?> onSubskillChanged;
  final ValueChanged<String?> onDrillIdChanged;
  final ValueChanged<DrillType?> onDrillTypeChanged;
  final ValueChanged<SurfaceType?> onSurfaceChanged;
  final ValueChanged<TimeResolution> onResolutionChanged;
  final ValueChanged<DateRangePreset> onDateRangeChanged;
  final ValueChanged<ChartMode> onChartModeChanged;

  const AnalysisFilters({
    super.key,
    required this.scope,
    required this.selectedSkillArea,
    required this.selectedSubskillId,
    required this.selectedDrillId,
    required this.drillTypeFilter,
    required this.surfaceFilter,
    required this.resolution,
    required this.dateRange,
    required this.chartMode,
    required this.onScopeChanged,
    required this.onSkillAreaChanged,
    required this.onSubskillChanged,
    required this.onDrillIdChanged,
    required this.onDrillTypeChanged,
    required this.onSurfaceChanged,
    required this.onResolutionChanged,
    required this.onDateRangeChanged,
    required this.onChartModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      color: ColorTokens.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Scope (left) + Type (right).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterLabel('Scope'),
                    _buildScopeChips(),
                  ],
                ),
                const SizedBox(width: SpacingTokens.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterLabel('Type'),
                    _buildDrillTypeChips(),
                  ],
                ),
                const SizedBox(width: SpacingTokens.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _filterLabel('Surface'),
                    _buildSurfaceChips(),
                  ],
                ),
              ],
            ),
          ),

          // Row 3: Conditional pickers (SkillArea / Drill).
          if (scope == AnalysisScope.skillArea) ...[
            const SizedBox(height: SpacingTokens.sm),
            _filterLabel('Skill Area'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SkillArea.values.map((area) {
                  final selected = selectedSkillArea == area;
                  return Padding(
                    padding:
                        const EdgeInsets.only(right: SpacingTokens.xs),
                    child: FilterChip(
                      label: Text(area.dbValue),
                      selected: selected,
                      onSelected: (_) => onSkillAreaChanged(
                          selected ? null : area),
                      selectedColor: ColorTokens.primaryDefault
                          .withValues(alpha: 0.3),
                      labelStyle: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: selected
                            ? ColorTokens.textPrimary
                            : ColorTokens.textSecondary,
                      ),
                      backgroundColor: ColorTokens.surfaceModal,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ShapeTokens.radiusSegmented),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (scope == AnalysisScope.drill) ...[
            const SizedBox(height: SpacingTokens.sm),
            _filterLabel('Drill'),
            _buildDrillPicker(ref),
          ],

        ],
      ),
    );
  }

  static Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, right: SpacingTokens.xs),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ColorTokens.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildScopeChips() {
    return _ChipGroup<AnalysisScope>(
      values: AnalysisScope.values,
      selected: scope,
      labelOf: (s) => switch (s) {
        AnalysisScope.overall => 'All',
        AnalysisScope.skillArea => 'Skill Area',
        AnalysisScope.drill => 'Drill',
      },
      onSelected: onScopeChanged,
    );
  }

  Widget _buildDrillTypeChips() {
    return Row(
      children: [
        FilterChip(
          label: const Text('All'),
          selected: drillTypeFilter == null,
          onSelected: (_) => onDrillTypeChanged(null),
          selectedColor:
              ColorTokens.primaryDefault.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            fontSize: TypographyTokens.microSize,
            color: drillTypeFilter == null
                ? ColorTokens.textPrimary
                : ColorTokens.textSecondary,
          ),
          backgroundColor: ColorTokens.surfaceModal,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ShapeTokens.radiusSegmented),
          ),
        ),
        const SizedBox(width: SpacingTokens.xs),
        // S12 §12.6.2 — Technique excluded from filter.
        ...[DrillType.transition, DrillType.pressure].map((dt) {
          final selected = drillTypeFilter == dt;
          return Padding(
            padding: const EdgeInsets.only(right: SpacingTokens.xs),
            child: FilterChip(
              label: Text(dt.dbValue),
              selected: selected,
              onSelected: (_) =>
                  onDrillTypeChanged(selected ? null : dt),
              selectedColor: ColorTokens.primaryDefault
                  .withValues(alpha: 0.3),
              labelStyle: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: selected
                    ? ColorTokens.textPrimary
                    : ColorTokens.textSecondary,
              ),
              backgroundColor: ColorTokens.surfaceModal,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusSegmented),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSurfaceChips() {
    return Row(
      children: [
        FilterChip(
          label: const Text('All'),
          selected: surfaceFilter == null,
          onSelected: (_) => onSurfaceChanged(null),
          selectedColor: ColorTokens.primaryDefault.withValues(alpha: 0.3),
          labelStyle: TextStyle(
            fontSize: TypographyTokens.microSize,
            color: surfaceFilter == null
                ? ColorTokens.textPrimary
                : ColorTokens.textSecondary,
          ),
          backgroundColor: ColorTokens.surfaceModal,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
          ),
        ),
        const SizedBox(width: SpacingTokens.xs),
        ...SurfaceType.values.map((st) {
          final selected = surfaceFilter == st;
          return Padding(
            padding: const EdgeInsets.only(right: SpacingTokens.xs),
            child: FilterChip(
              label: Text(st.dbValue),
              selected: selected,
              onSelected: (_) => onSurfaceChanged(selected ? null : st),
              selectedColor: ColorTokens.primaryDefault.withValues(alpha: 0.3),
              labelStyle: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: selected
                    ? ColorTokens.textPrimary
                    : ColorTokens.textSecondary,
              ),
              backgroundColor: ColorTokens.surfaceModal,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusSegmented),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDrillPicker(WidgetRef ref) {
    final drillMapAsync = ref.watch(drillMapProvider(kDevUserId));

    return drillMapAsync.when(
      data: (drillMap) {
        final drills = drillMap.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: drills.take(20).map((drill) {
              final selected = selectedDrillId == drill.drillId;
              return Padding(
                padding:
                    const EdgeInsets.only(right: SpacingTokens.xs),
                child: FilterChip(
                  label: Text(drill.name),
                  selected: selected,
                  onSelected: (_) => onDrillIdChanged(
                      selected ? null : drill.drillId),
                  selectedColor: ColorTokens.primaryDefault
                      .withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: selected
                        ? ColorTokens.textPrimary
                        : ColorTokens.textSecondary,
                  ),
                  backgroundColor: ColorTokens.surfaceModal,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        ShapeTokens.radiusSegmented),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Bottom bar with Resolution, Range, and Chart filters.
class AnalysisBottomFilters extends StatelessWidget {
  final TimeResolution resolution;
  final DateRangePreset dateRange;
  final ChartMode chartMode;
  final ValueChanged<TimeResolution> onResolutionChanged;
  final ValueChanged<DateRangePreset> onDateRangeChanged;
  final ValueChanged<ChartMode> onChartModeChanged;

  const AnalysisBottomFilters({
    super.key,
    required this.resolution,
    required this.dateRange,
    required this.chartMode,
    required this.onResolutionChanged,
    required this.onDateRangeChanged,
    required this.onChartModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: SpacingTokens.xs,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnalysisFilters._filterLabel('Resolution'),
                _ChipGroup<TimeResolution>(
                  values: TimeResolution.values,
                  selected: resolution,
                  labelOf: (r) => switch (r) {
                    TimeResolution.daily => 'Daily',
                    TimeResolution.weekly => 'Weekly',
                    TimeResolution.monthly => 'Monthly',
                  },
                  onSelected: onResolutionChanged,
                ),
              ],
            ),
            const SizedBox(width: SpacingTokens.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnalysisFilters._filterLabel('Range'),
                _ChipGroup<DateRangePreset>(
                  values: DateRangePreset.values,
                  selected: dateRange,
                  labelOf: (d) => switch (d) {
                    DateRangePreset.fourWeeks => '4W',
                    DateRangePreset.threeMonths => '3M',
                    DateRangePreset.sixMonths => '6M',
                    DateRangePreset.twelveMonths => '12M',
                  },
                  onSelected: onDateRangeChanged,
                ),
            ],
          ),
          const SizedBox(width: SpacingTokens.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnalysisFilters._filterLabel('Chart'),
              _ChipGroup<ChartMode>(
                values: ChartMode.values,
                selected: chartMode,
                labelOf: (c) => switch (c) {
                  ChartMode.performance => 'Perf',
                  ChartMode.volume => 'Vol',
                  ChartMode.both => 'Both',
                },
                onSelected: onChartModeChanged,
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}

class _ChipGroup<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const _ChipGroup({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: values.map((v) {
        final isSelected = v == selected;
        return Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.xs),
          child: FilterChip(
            label: Text(labelOf(v)),
            selected: isSelected,
            onSelected: (_) => onSelected(v),
            selectedColor:
                ColorTokens.primaryDefault.withValues(alpha: 0.3),
            labelStyle: TextStyle(
              fontSize: TypographyTokens.microSize,
              color: isSelected
                  ? ColorTokens.textPrimary
                  : ColorTokens.textSecondary,
            ),
            backgroundColor: ColorTokens.surfaceModal,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(ShapeTokens.radiusSegmented),
            ),
          ),
        );
      }).toList(),
    );
  }
}
