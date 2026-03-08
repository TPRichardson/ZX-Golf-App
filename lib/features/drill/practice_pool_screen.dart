import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

import '../bag/bag_screen.dart';
import 'add_drills_screen.dart';
import 'drill_detail_screen.dart';
import 'widgets/drill_card.dart';

/// 5E — Persistent filter state for Practice Pool (survives navigation).
final practicePoolFilterProvider = StateProvider<SkillArea?>((ref) => null);

/// Toggle between grouped (by skill area) and flat list display.
final practicePoolGroupedProvider = StateProvider<bool>((ref) => false);

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

// Phase 3 — Practice Pool: user's active drill collection.
// Adopted system drills + active custom drills.
// S12 §12.3 — Track tab primary view.

class PracticePoolScreen extends ConsumerStatefulWidget {
  /// When true, tapping a drill pops with the drillId instead of navigating.
  final bool pickMode;

  /// When true, omits Scaffold/AppBar (embedded in a parent tab).
  final bool embedded;

  const PracticePoolScreen({
    super.key,
    this.pickMode = false,
    this.embedded = false,
  });

  @override
  ConsumerState<PracticePoolScreen> createState() =>
      _PracticePoolScreenState();
}

class _PracticePoolScreenState extends ConsumerState<PracticePoolScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.embedded;
  // Phase 3 stub — replaced when auth is wired.
  static const _userId = kDevUserId;

  Widget _buildBody(BuildContext context) {
    final selectedFilter = ref.watch(practicePoolFilterProvider);
    final isGrouped = ref.watch(practicePoolGroupedProvider);
    final poolAsync = ref.watch(practicePoolProvider(_userId));

    return Column(
      children: [
        // Page header + filter button.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.md, SpacingTokens.md, SpacingTokens.sm, 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Your Drills',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ColorTokens.textPrimary,
                    ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Transform.translate(
                offset: const Offset(0, -1),
                child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const AddDrillsScreen(),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.only(
                    left: SpacingTokens.xs,
                    right: SpacingTokens.sm,
                    top: SpacingTokens.xs,
                    bottom: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusSegmented),
                    border: Border.all(color: ColorTokens.primaryDefault),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 16,
                        color: ColorTokens.primaryDefault,
                      ),
                      const SizedBox(width: SpacingTokens.xs),
                      Text(
                        'Add',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ColorTokens.primaryDefault,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
              const Spacer(),
              // 5E — Skill area filter + grouped/flat toggle.
              _FilterButton(
                selected: selectedFilter,
                onChanged: (area) =>
                    ref.read(practicePoolFilterProvider.notifier).state = area,
                isGrouped: isGrouped,
                onGroupToggle: (v) =>
                    ref.read(practicePoolGroupedProvider.notifier).state = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        // Drill list.
        Expanded(
          child: poolAsync.when(
            data: (drills) {
              final filtered = selectedFilter == null
                  ? drills
                  : drills
                      .where(
                          (d) => d.drill.skillArea == selectedFilter)
                      .toList();

              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.sports_golf,
                  message: 'No drills in your drill library',
                  subtitle:
                      'Adopt drills from the System Library\nor create your own',
                );
              }

              // Sort: driver at top → putter at bottom.
              final sorted = List.of(filtered)
                ..sort((a, b) => _skillAreaSortKey(a.drill.skillArea)
                    .compareTo(_skillAreaSortKey(b.drill.skillArea)));

              if (isGrouped) {
                return _buildGroupedList(context, sorted);
              }
              return _buildFlatList(context, sorted);
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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
      ),
      itemCount: drills.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: SpacingTokens.sm),
      itemBuilder: (context, index) {
        final dwa = drills[index];
        return _buildDrillCard(context, dwa);
      },
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
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
    );
  }

  Widget _buildDrillCard(BuildContext context, DrillWithAdoption dwa) {
    return DrillCard(
      drill: dwa.drill,
      onTap: () {
        if (widget.pickMode) {
          Navigator.of(context).pop(dwa.drill.drillId);
          return;
        }
        _openDrillDetail(dwa);
      },
      trailing: widget.pickMode
          ? null
          : _PlayDrillButton(
              drillId: dwa.drill.drillId,
              userId: _userId,
            ),
    );
  }

  Future<void> _startPlannedPractice(List<String> drillIds) async {
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(
      _userId,
      initialDrillIds: drillIds,
      surfaceType: envSurface.surface,
    );

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: _userId,
        ),
      ));
    }
  }

  Future<void> _startCleanPractice() async {
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(_userId, surfaceType: envSurface.surface);

    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: _userId,
        ),
      ));
    }
  }

  Widget _buildBottomBar() {
    final activePb = ref.watch(activePracticeBlockProvider(_userId));
    final hasActivePb = activePb.valueOrNull != null;
    final todayAsync = ref.watch(todayCalendarDayProvider(_userId));

    // Extract filled drill IDs from today's slots.
    List<String> filledDrillIds = [];
    todayAsync.whenData((day) {
      filledDrillIds = parseSlotsFromJson(day.slots)
          .where((s) => s.isFilled && !s.isCompleted)
          .map((s) => s.drillId!)
          .toList();
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasActivePb) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startCleanPractice,
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  label: const Text(
                    'Practice Drills',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.successDefault,
                    padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.sm,
                    ),
                  ),
                ),
              ),
            ),
            if (filledDrillIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _startPlannedPractice(filledDrillIds),
                    icon: Icon(Icons.calendar_today, color: ColorTokens.primaryDefault, size: 18),
                    label: Text(
                      'Start Planned Practice (${filledDrillIds.length} drills)',
                      style: TextStyle(color: ColorTokens.primaryDefault),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: ColorTokens.primaryDefault),
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.sm,
                      ),
                    ),
                  ),
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

    return Scaffold(
      appBar: ZxAppBar(
        title: widget.pickMode ? 'Select Drill' : 'Drill Library',
        actions: widget.pickMode
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
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
      bottomNavigationBar: widget.pickMode ? null : _buildBottomBar(),
    );
  }

  void _openDrillDetail(DrillWithAdoption dwa) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DrillDetailScreen(
        drillId: dwa.drill.drillId,
        isCustom: dwa.drill.origin == DrillOrigin.userCustom,
      ),
    ));
  }
}

class _PlayDrillButton extends ConsumerWidget {
  final String drillId;
  final String userId;

  const _PlayDrillButton({required this.drillId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        Icons.play_circle_outline,
        size: 32,
        color: ColorTokens.successDefault,
      ),
      onPressed: () async {
        final envSurface = await showEnvironmentSurfacePicker(context);
        if (envSurface == null || !context.mounted) return;

        final actions = ref.read(practiceActionsProvider);
        final pb = await actions.startPracticeBlock(
          userId,
          initialDrillIds: [drillId],
          surfaceType: envSurface.surface,
        );

        if (context.mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PracticeQueueScreen(
              practiceBlockId: pb.practiceBlockId,
              userId: userId,
            ),
          ));
        }
      },
      tooltip: 'Start practice with this drill',
    );
  }
}

/// Filter button with inline group toggle.
/// Uses a manual showMenu to support null (All) as a selectable value.
class _FilterButton extends StatelessWidget {
  final SkillArea? selected;
  final ValueChanged<SkillArea?> onChanged;
  final bool isGrouped;
  final ValueChanged<bool> onGroupToggle;

  const _FilterButton({
    required this.selected,
    required this.onChanged,
    required this.isGrouped,
    required this.onGroupToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusSegmented),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Group toggle.
          GestureDetector(
            onTap: () => onGroupToggle(!isGrouped),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              child: Icon(
                isGrouped ? Icons.list : Icons.view_agenda_outlined,
                size: 16,
                color: ColorTokens.primaryDefault,
              ),
            ),
          ),
          // Divider.
          Container(
            width: 1,
            height: 16,
            color: ColorTokens.textTertiary,
          ),
          // Filter menu.
          GestureDetector(
            onTapDown: (details) async {
              final result = await showMenu<String>(
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                ),
                items: [
                  const PopupMenuItem(value: 'all', child: Text('All')),
                  for (final area in SkillArea.values)
                    PopupMenuItem(
                        value: area.dbValue, child: Text(area.dbValue)),
                ],
              );
              if (result == null) return;
              if (result == 'all') {
                onChanged(null);
              } else {
                onChanged(
                    SkillArea.values.firstWhere((a) => a.dbValue == result));
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected?.dbValue ?? 'All',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ColorTokens.primaryDefault,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  Icon(
                    Icons.filter_list,
                    size: 16,
                    color: ColorTokens.primaryDefault,
                  ),
                ],
              ),
            ),
          ),
        ],
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

