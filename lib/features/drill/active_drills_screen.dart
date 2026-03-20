import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
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

/// Display order: driver at top → putter at bottom.
const _skillAreaDisplayOrder = [
  SkillArea.driving,
  SkillArea.woods,
  SkillArea.approach,
  SkillArea.bunkers,
  SkillArea.pitching,
  SkillArea.chipping,
  SkillArea.putting,
];

int _skillAreaSortKey(SkillArea area) =>
    _skillAreaDisplayOrder.indexOf(area);

/// Sort order within a skill area page:
/// DrillType (Technique→Transition→Pressure→Benchmark),
/// then ClubSelectionMode, then InputMode, then alphabetical.
const _drillTypeSortOrder = [
  DrillType.techniqueBlock,
  DrillType.transition,
  DrillType.pressure,
  DrillType.benchmark,
];

int _drillSortCompare(Drill a, Drill b) {
  // 1. DrillType
  final typeA = _drillTypeSortOrder.indexOf(a.drillType);
  final typeB = _drillTypeSortOrder.indexOf(b.drillType);
  if (typeA != typeB) return typeA.compareTo(typeB);
  // 2. ClubSelectionMode (null first, then by name)
  final clubA = a.clubSelectionMode?.name ?? '';
  final clubB = b.clubSelectionMode?.name ?? '';
  final clubCmp = clubA.compareTo(clubB);
  if (clubCmp != 0) return clubCmp;
  // 3. InputMode
  final inputCmp = a.inputMode.name.compareTo(b.inputMode.name);
  if (inputCmp != 0) return inputCmp;
  // 4. Alphabetical
  return a.name.compareTo(b.name);
}

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

  /// Persists last viewed page across widget rebuilds within the session.
  static int _lastPage = 0;

  /// Multi-select state for pick mode (drill ID → count).
  final _selectedDrillCounts = <String, int>{};

  /// Page controller for skill area carousel.
  late final PageController _pageController;
  int _currentPage = _lastPage;

  /// Remove mode state.
  bool _removeMode = false;
  final Set<String> _removeDrillIds = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _lastPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
        // Dot indicator + skill area label.
        _buildCarouselIndicator(),
        const SizedBox(height: SpacingTokens.sm),
        // Carousel pages.
        Expanded(
          child: poolAsync.when(
            data: (drills) {
              // Group by skill area.
              final groups = <SkillArea, List<DrillWithAdoption>>{};
              for (final dwa in drills) {
                groups.putIfAbsent(dwa.drill.skillArea, () => []).add(dwa);
              }
              // Sort within each group.
              for (final list in groups.values) {
                list.sort((a, b) => _drillSortCompare(a.drill, b.drill));
              }

              return PageView.builder(
                controller: _pageController,
                itemCount: _skillAreaDisplayOrder.length,
                onPageChanged: (page) => setState(() {
                  _currentPage = page;
                  _lastPage = page;
                }),
                itemBuilder: (context, index) {
                  final area = _skillAreaDisplayOrder[index];
                  final areaDrills = groups[area] ?? [];

                  if (areaDrills.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sports_golf,
                              size: 48,
                              color: ColorTokens.textTertiary.withValues(alpha: 0.5)),
                          const SizedBox(height: SpacingTokens.md),
                          Text(
                            'No ${area.dbValue} drills',
                            style: const TextStyle(
                              fontSize: TypographyTokens.bodyLgSize,
                              color: ColorTokens.textTertiary,
                            ),
                          ),
                          const SizedBox(height: SpacingTokens.sm),
                          Text(
                            'Add or create drills for this skill',
                            style: const TextStyle(
                              fontSize: TypographyTokens.bodySize,
                              color: ColorTokens.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by drill type within this skill area.
                  final typeGroups = <DrillType, List<DrillWithAdoption>>{};
                  for (final dwa in areaDrills) {
                    typeGroups
                        .putIfAbsent(dwa.drill.drillType, () => [])
                        .add(dwa);
                  }
                  final orderedTypes = _drillTypeSortOrder
                      .where((t) => typeGroups.containsKey(t))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.lg,
                    ),
                    itemCount: orderedTypes.length,
                    itemBuilder: (context, i) {
                      final type = orderedTypes[i];
                      final typeDrills = typeGroups[type]!;
                      return _DrillTypeSection(
                        drillType: type,
                        drills: typeDrills,
                        cardBuilder: (dwa) => _buildDrillCard(context, dwa),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
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

  Widget _buildCarouselIndicator() {
    final currentArea = _skillAreaDisplayOrder[_currentPage];
    final areaColor = ColorTokens.skillArea(currentArea);
    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.sm),
      child: Column(
      children: [
        // Page title.
        const Text(
          'My Active Drills',
          style: TextStyle(
            fontSize: TypographyTokens.bodyLgSize,
            fontWeight: FontWeight.w500,
            color: ColorTokens.textSecondary,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        // Skill area name in its colour.
        Text(
          currentArea.dbValue,
          style: TextStyle(
            fontSize: TypographyTokens.headerSize,
            fontWeight: FontWeight.w600,
            color: areaColor,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        // Dot indicators.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_skillAreaDisplayOrder.length, (index) {
            final isActive = index == _currentPage;
            final dotColor = ColorTokens.skillArea(_skillAreaDisplayOrder[index]);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 14 : 8,
              height: isActive ? 14 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? dotColor
                    : dotColor.withValues(alpha: 0.35),
              ),
            );
          }),
        ),
      ],
    ),
    );
  }

  Widget _buildDrillCard(BuildContext context, DrillWithAdoption dwa) {
    final drillId = dwa.drill.drillId;
    final count = _selectedDrillCounts[drillId] ?? 0;
    return DrillCard(
      drill: dwa.drill,
      hasUnseenUpdate: dwa.adoption?.hasUnseenUpdate ?? false,
      subtitle: '${dwa.drill.requiredSetCount}x${dwa.drill.requiredAttemptsPerSet ?? 0}',
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _removeMode = false;
                  _removeDrillIds.clear();
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorTokens.textTertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                  border: Border.all(
                    color: ColorTokens.textTertiary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(Icons.close,
                    size: 24,
                    color: ColorTokens.textTertiary),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxPillButton(
                label: _removeDrillIds.isEmpty
                    ? 'Remove Drills From Active'
                    : 'Remove ${_removeDrillIds.length} From Active',
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
        0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: hasActiveDrills
                ? IntrinsicHeight(
                    child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _removeMode = true),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ColorTokens.errorDestructive.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                              border: Border.all(
                                color: ColorTokens.errorDestructive.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(Icons.delete_outline,
                                size: 24,
                                color: ColorTokens.errorDestructive),
                          ),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.sm),
                      Expanded(
                        child: ZxPillButton(
                          label: '+Add/Create Drills',
                          icon: Icons.add,
                          size: ZxPillSize.md,
                          variant: ZxPillVariant.secondary,
                          centered: true,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const AddDrillsScreen(),
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                  )
                : ZxPillButton(
                    label: '+Add/Create Drills',
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

/// Collapsible drill type section within a skill area page.
class _DrillTypeSection extends StatefulWidget {
  final DrillType drillType;
  final List<DrillWithAdoption> drills;
  final Widget Function(DrillWithAdoption) cardBuilder;

  const _DrillTypeSection({
    required this.drillType,
    required this.drills,
    required this.cardBuilder,
  });

  @override
  State<_DrillTypeSection> createState() => _DrillTypeSectionState();
}

class _DrillTypeSectionState extends State<_DrillTypeSection> {
  bool _expanded = true;

  static String _typeLabel(DrillType type) => switch (type) {
        DrillType.techniqueBlock => 'Technique',
        DrillType.transition => 'Transition',
        DrillType.pressure => 'Pressure',
        DrillType.benchmark => 'Benchmark',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header — tap to collapse/expand.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              child: Row(
                children: [
                  Text(
                    _typeLabel(widget.drillType),
                    style: const TextStyle(
                      fontSize: TypographyTokens.bodyLgSize,
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Text(
                    '(${widget.drills.length})',
                    style: const TextStyle(
                      fontSize: TypographyTokens.bodySize,
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
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: widget.cardBuilder(dwa),
                )),
        ],
      ),
    );
  }
}
