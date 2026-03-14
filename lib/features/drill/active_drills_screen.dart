import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

import '../bag/bag_screen.dart';
import 'add_drills_screen.dart';
import 'drill_detail_screen.dart';
import 'widgets/drill_card.dart';

/// 5E — Persistent filter state for Active Drills (survives navigation).
final activeDrillsFilterProvider = StateProvider<SkillArea?>((ref) => null);

/// Drill type filter (Transition/Pressure/Technique).
final activeDrillsTypeFilterProvider = StateProvider<DrillType?>((ref) => null);

/// Toggle between grouped (by skill area) and flat list display.
final activeDrillsGroupedProvider = StateProvider<bool>((ref) => false);

/// Display order: driver at top → putter at bottom.
const _skillAreaDisplayOrder = [
  SkillArea.driving,
  SkillArea.woods,
  SkillArea.irons,
  SkillArea.bunkers,
  SkillArea.pitching,
  SkillArea.chipping,
  SkillArea.putting,
];

int _skillAreaSortKey(SkillArea area) =>
    _skillAreaDisplayOrder.indexOf(area);

// Phase 3 — Active Drills: user's active drill collection.
// Adopted standard drills + active custom drills.
// S12 §12.3 — Track tab primary view.

class ActiveDrillsScreen extends ConsumerStatefulWidget {
  /// When true, tapping a drill pops with the drillId instead of navigating.
  final bool pickMode;

  /// When true, single-tap pops with a single drill ID string.
  /// Used by calendar slot assignment.
  final bool slotPickMode;

  /// When true, omits Scaffold/AppBar (embedded in a parent tab).
  final bool embedded;

  /// Existing block stats passed from practice queue (pick mode only).
  final int existingDrillCount;
  final int existingSets;
  final int existingShots;

  const ActiveDrillsScreen({
    super.key,
    this.pickMode = false,
    this.slotPickMode = false,
    this.embedded = false,
    this.existingDrillCount = 0,
    this.existingSets = 0,
    this.existingShots = 0,
  });

  @override
  ConsumerState<ActiveDrillsScreen> createState() =>
      _ActiveDrillsScreenState();
}

class _ActiveDrillsScreenState extends ConsumerState<ActiveDrillsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.embedded;

  /// Multi-select state for pick mode (drill ID → count).
  final _selectedDrillCounts = <String, int>{};

  /// Remove mode state.
  bool _removeMode = false;
  final Set<String> _removeDrillIds = {};

  /// Total number of drills selected (sum of all counts).
  int get _totalSelectedCount =>
      _selectedDrillCounts.values.fold(0, (a, b) => a + b);

  /// Compute sets and shots for selected drills, respecting counts.
  ({int sets, int shots}) _statsForSelectedDrills(
      List<DrillWithAdoption> pool) {
    int sets = 0;
    int shots = 0;
    for (final dwa in pool) {
      final count = _selectedDrillCounts[dwa.drill.drillId] ?? 0;
      if (count == 0) continue;
      sets += dwa.drill.requiredSetCount * count;
      shots += dwa.drill.requiredSetCount *
          (dwa.drill.requiredAttemptsPerSet ?? 0) *
          count;
    }
    return (sets: sets, shots: shots);
  }

  Widget _buildBody(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final selectedFilter = ref.watch(activeDrillsFilterProvider);
    final typeFilter = ref.watch(activeDrillsTypeFilterProvider);
    final isGrouped = ref.watch(activeDrillsGroupedProvider);
    final poolAsync = ref.watch(activeDrillsProvider(userId));

    return Column(
      children: [
        // Info bar (multi-pick mode only — shows drill/set/shot counts).
        if (widget.pickMode && !widget.slotPickMode)
          poolAsync.when(
            data: (drills) => _buildInfoBar(drills),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        if (widget.pickMode && !widget.slotPickMode)
          const SizedBox(height: SpacingTokens.sm),
        // Page subtitle (non-pick mode only — pick mode has it in the AppBar).
        if (!widget.pickMode && !widget.slotPickMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, 0,
            ),
            child: Center(
              child: Text(
                'My Active Drills',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ColorTokens.textPrimary,
                    ),
              ),
            ),
          ),
        // Filters row — unified pill with dividers.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md, SpacingTokens.sm, SpacingTokens.md, 0,
          ),
          child: _UnifiedFilterBar(
            selectedSkill: selectedFilter,
            onSkillChanged: (area) =>
                ref.read(activeDrillsFilterProvider.notifier).state = area,
            selectedType: typeFilter,
            onTypeChanged: (type) =>
                ref.read(activeDrillsTypeFilterProvider.notifier).state = type,
            isGrouped: isGrouped,
            onGroupToggle: (v) =>
                ref.read(activeDrillsGroupedProvider.notifier).state = v,
          ),
        ),
        SizedBox(height: (widget.pickMode || widget.slotPickMode) ? SpacingTokens.md : SpacingTokens.sm),
        // Drill list.
        Expanded(
          child: poolAsync.when(
            data: (drills) {
              var filtered = drills.toList();
              if (selectedFilter != null) {
                filtered = filtered
                    .where((d) => d.drill.skillArea == selectedFilter)
                    .toList();
              }
              if (typeFilter != null) {
                filtered = filtered
                    .where((d) => d.drill.drillType == typeFilter)
                    .toList();
              }
              final hiddenCount = drills.length - filtered.length;

              // Hidden-by-filter notice.
              final notice = hiddenCount > 0
                  ? Padding(
                      padding: const EdgeInsets.only(
                        bottom: SpacingTokens.xs,
                        left: SpacingTokens.md,
                        right: SpacingTokens.md,
                      ),
                      child: Text(
                        '$hiddenCount drill${hiddenCount == 1 ? '' : 's'} hidden by filters',
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    )
                  : null;

              if (filtered.isEmpty) {
                // No drills in library at all.
                if (drills.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const EmptyState(
                        icon: Icons.sports_golf,
                        message: 'No Drills in Library',
                      ),
                      const SizedBox(height: SpacingTokens.sm),
                      Text(
                        'Add drills to get started',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodyLgSize,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    ],
                  );
                }
                // Drills exist but none match the active filter.
                return Column(
                  children: [
                    ?notice,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const EmptyState(
                            icon: Icons.sports_golf,
                            message: 'No drills match this filter',
                            subtitle: 'Try a different skill area filter',
                          ),
                          const SizedBox(height: SpacingTokens.md),
                          ZxPillButton(
                            label: 'Clear Filter',
                            icon: Icons.filter_list_off,
                            variant: ZxPillVariant.secondary,
                            onTap: () => ref
                                .read(activeDrillsFilterProvider.notifier)
                                .state = null,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Sort: driver at top → putter at bottom.
              final sorted = List.of(filtered)
                ..sort((a, b) => _skillAreaSortKey(a.drill.skillArea)
                    .compareTo(_skillAreaSortKey(b.drill.skillArea)));

              if (isGrouped) {
                return Column(
                  children: [
                    ?notice,
                    Expanded(child: _buildGroupedList(context, sorted)),
                  ],
                );
              }
              return Column(
                children: [
                  ?notice,
                  Expanded(child: _buildFlatList(context, sorted)),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text(
                'Error: $error',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: ColorTokens.errorDestructive),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlatList(BuildContext context, List<DrillWithAdoption> drills) {
    return Scrollbar(
      thumbVisibility: true,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.lg,
        ),
        itemCount: drills.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: SpacingTokens.sm),
        itemBuilder: (context, index) {
          final dwa = drills[index];
          return _buildDrillCard(context, dwa);
        },
      ),
    );
  }

  Widget _buildGroupedList(
      BuildContext context, List<DrillWithAdoption> drills) {
    // Group by skill area, preserving display order.
    final groups = <SkillArea, List<DrillWithAdoption>>{};
    for (final dwa in drills) {
      groups.putIfAbsent(dwa.drill.skillArea, () => []).add(dwa);
    }
    final orderedAreas = _skillAreaDisplayOrder
        .where((a) => groups.containsKey(a))
        .toList();

    return Scrollbar(
      thumbVisibility: true,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
        itemCount: orderedAreas.length,
        itemBuilder: (context, index) {
          final area = orderedAreas[index];
          final areaDrills = groups[area]!;
          return _SkillAreaGroup(
            area: area,
            drills: areaDrills,
            cardBuilder: (dwa) => _buildDrillCard(context, dwa),
          );
        },
      ),
    );
  }

  Widget _buildDrillCard(BuildContext context, DrillWithAdoption dwa) {
    final drillId = dwa.drill.drillId;
    final count = _selectedDrillCounts[drillId] ?? 0;
    return DrillCard(
      drill: dwa.drill,
      hasUnseenUpdate: dwa.adoption?.hasUnseenUpdate ?? false,
      subtitle: dwa.drill.origin == DrillOrigin.standard ? 'Standard' : 'Custom',
      isDestructiveSelected: _removeMode && _removeDrillIds.contains(drillId),
      onTap: () {
        if (_removeMode) {
          setState(() {
            if (_removeDrillIds.contains(drillId)) {
              _removeDrillIds.remove(drillId);
            } else {
              _removeDrillIds.add(drillId);
            }
          });
          return;
        }
        // Slot pick mode: single tap → pop immediately with drill ID.
        if (widget.slotPickMode) {
          Navigator.of(context).pop(drillId);
          return;
        }
        if (widget.pickMode) {
          setState(() {
            _selectedDrillCounts[drillId] = count + 1;
          });
          return;
        }
        _openDrillDetail(dwa);
      },
      trailing: _removeMode
          ? IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: _removeDrillIds.contains(drillId)
                    ? ColorTokens.errorDestructive
                    : ColorTokens.textTertiary,
              ),
              onPressed: () {
                setState(() {
                  if (_removeDrillIds.contains(drillId)) {
                    _removeDrillIds.remove(drillId);
                  } else {
                    _removeDrillIds.add(drillId);
                  }
                });
              },
              tooltip: _removeDrillIds.contains(drillId)
                  ? 'Deselect'
                  : 'Select for removal',
            )
          : widget.pickMode && !widget.slotPickMode
              ? _DrillCountControl(
                  count: count,
                  onDecrement: () {
                    setState(() {
                      if (count <= 1) {
                        _selectedDrillCounts.remove(drillId);
                      } else {
                        _selectedDrillCounts[drillId] = count - 1;
                      }
                    });
                  },
                )
              : null,
    );
  }

  Future<void> _removeSelectedDrills() async {
    final userId = ref.read(currentUserIdProvider);
    final drillRepo = ref.read(drillRepositoryProvider);
    for (final drillId in _removeDrillIds.toList()) {
      try {
        await drillRepo.retireAdoption(userId, drillId);
      } catch (_) {
        // Custom drills: retire instead.
        try {
          await drillRepo.retireDrill(userId, drillId);
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(() {
        _removeMode = false;
        _removeDrillIds.clear();
      });
    }
  }

  Future<void> _startPlannedPractice(List<String> drillIds) async {
    final userId = ref.read(currentUserIdProvider);
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(
      userId,
      initialDrillIds: drillIds,
      surfaceType: envSurface.surface,
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }

  Future<void> _startCleanPractice() async {
    final userId = ref.read(currentUserIdProvider);
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(userId, surfaceType: envSurface.surface);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }

  Widget _buildBottomBar() {
    final userId = ref.watch(currentUserIdProvider);
    final activePb = ref.watch(activePracticeBlockProvider(userId));
    final hasActivePb = activePb.valueOrNull != null;
    final todayAsync = ref.watch(todayCalendarDayProvider(userId));

    // Extract filled drill IDs from today's slots.
    List<String> filledDrillIds = [];
    todayAsync.whenData((day) {
      if (day == null) return;
      filledDrillIds = parseSlotsFromJson(day.slots)
          .where((s) => s.isFilled && !s.isCompleted)
          .map((s) => s.drillId!)
          .toList();
    });

    final poolAsync = ref.watch(activeDrillsProvider(userId));
    final hasActiveDrills =
        poolAsync.valueOrNull != null && poolAsync.valueOrNull!.isNotEmpty;

    if (_removeMode) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.md,
          SpacingTokens.sm,
          SpacingTokens.md,
          SpacingTokens.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: ZxPillButton(
                label: 'Cancel',
                variant: ZxPillVariant.tertiary,
                centered: true,
                onTap: () {
                  setState(() {
                    _removeMode = false;
                    _removeDrillIds.clear();
                  });
                },
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxPillButton(
                label: _removeDrillIds.isEmpty
                    ? 'Remove Drills'
                    : 'Remove ${_removeDrillIds.length} Drill${_removeDrillIds.length == 1 ? '' : 's'}',
                variant: ZxPillVariant.destructive,
                centered: true,
                onTap: _removeDrillIds.isEmpty ? null : _removeSelectedDrills,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: hasActiveDrills
                ? Row(
                    children: [
                      Expanded(
                        child: ZxPillButton(
                          label: 'Remove Drills',
                          icon: Icons.remove_circle_outline,
                          size: ZxPillSize.md,
                          variant: ZxPillVariant.destructive,
                          centered: true,
                          onTap: () {
                            setState(() => _removeMode = true);
                          },
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: ZxPillButton(
                          label: 'Add More Drills',
                          icon: Icons.add,
                          size: ZxPillSize.md,
                          variant: ZxPillVariant.primary,
                          centered: true,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const AddDrillsScreen(),
                            ));
                          },
                        ),
                      ),
                    ],
                  )
                : ZxPillButton(
                    label: 'Add More Drills',
                    icon: Icons.add,
                    size: ZxPillSize.md,
                    variant: ZxPillVariant.primary,
                    expanded: true,
                    centered: true,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AddDrillsScreen(),
                      ));
                    },
                  ),
          ),
          if (!hasActivePb) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: ZxPillButton(
                label: 'Begin Practice',
                icon: Icons.play_circle_filled,
                size: ZxPillSize.md,
                variant: ZxPillVariant.progress,
                expanded: true,
                centered: true,
                onTap: _startCleanPractice,
              ),
            ),
            if (filledDrillIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                child: ZxPillButton(
                  label: 'Start Planned Practice (${filledDrillIds.length} drills)',
                  icon: Icons.calendar_today,
                  variant: ZxPillVariant.primary,
                  expanded: true,
                  centered: true,
                  onTap: () => _startPlannedPractice(filledDrillIds),
                ),
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    // Embedded mode: no Scaffold, used inside a parent TabBarView.
    if (widget.embedded) {
      return Column(
        children: [
          Expanded(child: _buildBody(context)),
          _buildBottomBar(),
        ],
      );
    }

    final title = widget.slotPickMode
        ? 'Add Drill to Slot'
        : 'My Active Drills';

    return Scaffold(
      appBar: ZxAppBar(
        title: title,
        titleSize: (widget.pickMode || widget.slotPickMode)
            ? TypographyTokens.displayLgSize
            : null,
        actions: (widget.pickMode || widget.slotPickMode)
            ? null
            : [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/golf-bag.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      ColorTokens.textPrimary,
                      BlendMode.srcIn,
                    ),
                  ),
                  tooltip: 'Golf Bag',
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BagScreen(),
                    ));
                  },
                ),
              ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: widget.slotPickMode
          ? null
          : widget.pickMode
              ? _buildPickModeBottomBar()
              : _buildBottomBar(),
    );
  }

  Widget _buildInfoBar(List<DrillWithAdoption> drills) {
    final adding = _statsForSelectedDrills(drills);
    final totalCount = _totalSelectedCount;
    final existDrills = widget.existingDrillCount;
    final existSets = widget.existingSets;
    final existShots = widget.existingShots;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      color: ColorTokens.surfaceRaised,
      child: Column(
        children: [
          Text(
            'Practice Information',
            style: TextStyle(
              fontSize: TypographyTokens.displayLgSize,
              color: ColorTokens.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Row(
            children: [
              _statCell(
                context,
                '${existDrills + totalCount}',
                '(+$totalCount)',
                'Drills',
              ),
              _statCell(
                context,
                '${existSets + adding.sets}',
                '(+${adding.sets})',
                'Sets',
              ),
              _statCell(
                context,
                '${existShots + adding.shots}',
                '(+${adding.shots})',
                'Shots',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCell(
      BuildContext context, String total, String delta, String label) {
    return Expanded(
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            fontSize: TypographyTokens.bodySize,
            color: ColorTokens.textSecondary,
          ),
          children: [
            TextSpan(text: '$total '),
            TextSpan(
              text: delta,
              style: const TextStyle(
                color: ColorTokens.primaryDefault,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: '\n$label'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPickModeBottomBar() {
    final totalCount = _totalSelectedCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md,
            SpacingTokens.md,
            SpacingTokens.md,
            SpacingTokens.xl,
          ),
          child: ZxPillButton(
            label: totalCount == 0
                ? 'Select drills to add'
                : 'Add $totalCount drill${totalCount == 1 ? '' : 's'}',
            icon: Icons.playlist_add,
            size: ZxPillSize.lg,
            variant: totalCount == 0
                ? ZxPillVariant.tertiary
                : ZxPillVariant.progress,
            expanded: true,
            centered: true,
            onTap: totalCount == 0
                ? null
                : () {
                    // Expand map to flat list: {drillA: 3} → [drillA, drillA, drillA]
                    final flatList = <String>[
                      for (final entry in _selectedDrillCounts.entries)
                        for (var i = 0; i < entry.value; i++) entry.key,
                    ];
                    Navigator.of(context).pop(flatList);
                  },
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  void _openDrillDetail(DrillWithAdoption dwa) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DrillDetailScreen(
        drillId: dwa.drill.drillId,
        isCustom: dwa.drill.origin == DrillOrigin.custom,
      ),
    ));
  }
}

/// Counter control for pick mode: minus button + count badge.
class _DrillCountControl extends StatelessWidget {
  final int count;
  final VoidCallback onDecrement;

  const _DrillCountControl({
    required this.count,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Icon(
        Icons.add_circle_outline,
        color: ColorTokens.textTertiary.withAlpha(100),
        size: 30,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.xs),
          child: GestureDetector(
            onTap: onDecrement,
            child: Icon(
              Icons.remove_circle_outline,
              color: ColorTokens.errorActive,
              size: 30,
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        Container(
          constraints: const BoxConstraints(minWidth: 32),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.sm + 2,
            vertical: SpacingTokens.xs + 2,
          ),
          decoration: BoxDecoration(
            color: ColorTokens.primaryDefault.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            border: Border.all(
              color: ColorTokens.primaryDefault.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ColorTokens.primaryDefault,
              fontWeight: FontWeight.w600,
              fontSize: TypographyTokens.headerSize,
            ),
          ),
        ),
      ],
    );
  }
}

/// Drill type filter chip (All / Transition / Pressure / Technique).
/// Unified filter bar — group toggle | skill area | drill type in one pill, full width.
class _UnifiedFilterBar extends StatelessWidget {
  final SkillArea? selectedSkill;
  final ValueChanged<SkillArea?> onSkillChanged;
  final DrillType? selectedType;
  final ValueChanged<DrillType?> onTypeChanged;
  final bool isGrouped;
  final ValueChanged<bool> onGroupToggle;

  const _UnifiedFilterBar({
    required this.selectedSkill,
    required this.onSkillChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.isGrouped,
    required this.onGroupToggle,
  });

  static String _typeLabel(DrillType? type) => switch (type) {
        null => 'All Types',
        DrillType.transition => 'Transition',
        DrillType.pressure => 'Pressure',
        DrillType.techniqueBlock => 'Technique',
      };

  Widget _divider() => Container(
        width: 1,
        height: 24,
        color: ColorTokens.textTertiary,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          // Group toggle.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onGroupToggle(!isGrouped),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.md,
              ),
              child: Icon(
                isGrouped ? Icons.list : Icons.view_agenda_outlined,
                size: 24,
                color: ColorTokens.primaryDefault,
              ),
            ),
          ),
          _divider(),
          // Skill area filter.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) =>
                      _SkillAreaGridDialog(selected: selectedSkill),
                );
                if (result == null) return;
                if (result == 'all') {
                  onSkillChanged(null);
                } else {
                  onSkillChanged(SkillArea.values
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
                        selectedSkill?.dbValue ?? 'All Skills',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: ColorTokens.primaryDefault,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Icon(
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
                    contentPadding: const EdgeInsets.all(SpacingTokens.md),
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
                              variant: type == selectedType
                                  ? ZxPillVariant.primary
                                  : ZxPillVariant.tertiary,
                              onTap: () =>
                                  Navigator.pop(ctx, type?.name ?? 'all'),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                if (result == null) return;
                if (result == 'all') {
                  onTypeChanged(null);
                } else {
                  onTypeChanged(
                      DrillType.values.firstWhere((t) => t.name == result));
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
                        _typeLabel(selectedType),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: ColorTokens.primaryDefault,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    Icon(
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
    );
  }
}

/// 2×4 grid dialog for skill area filter selection.
class _SkillAreaGridDialog extends StatelessWidget {
  final SkillArea? selected;

  const _SkillAreaGridDialog({required this.selected});

  @override
  Widget build(BuildContext context) {
    // "All" + 7 skill areas = 8 items in a 2×4 grid.
    final items = <({String value, String label, Color? color})>[
      (value: 'all', label: 'All Skills', color: null),
      for (final area in _skillAreaDisplayOrder)
        (value: area.dbValue, label: area.dbValue, color: ColorTokens.skillArea(area)),
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

/// Expandable skill area group header with drill cards.
class _SkillAreaGroup extends StatefulWidget {
  final SkillArea area;
  final List<DrillWithAdoption> drills;
  final Widget Function(DrillWithAdoption) cardBuilder;

  const _SkillAreaGroup({
    required this.area,
    required this.drills,
    required this.cardBuilder,
  });

  @override
  State<_SkillAreaGroup> createState() => _SkillAreaGroupState();
}

class _SkillAreaGroupState extends State<_SkillAreaGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.skillArea(widget.area);
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: SpacingTokens.md,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(
                          ShapeTokens.radiusMicro),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    widget.area.dbValue,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: ColorTokens.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '(${widget.drills.length})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorTokens.textTertiary,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: ColorTokens.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          // Drill cards.
          if (_expanded)
            ...widget.drills.map((dwa) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: widget.cardBuilder(dwa),
                )),
        ],
      ),
    );
  }
}
