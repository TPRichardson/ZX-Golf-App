import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import 'club_detail_screen.dart';
import 'training_kit_tab.dart';
import 'training_kit_item_detail_screen.dart';
import 'widgets/club_card.dart';

// Phase 3 — Bag screen. Two tabs: Golf Bag and Training Kit.
// S09 §9.1 — Club configuration.

// Card height (ZxCard 12+12 padding + ~70 content + 2 border) + 8 bottom margin.
const _kCardItemExtent = 108.0;

class BagScreen extends ConsumerStatefulWidget {
  /// Which tab to show initially: 0 = Golf Bag, 1 = Training Kit.
  final int initialTab;

  const BagScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends ConsumerState<BagScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final bagAsync = ref.watch(userBagProvider(userId));

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ZxShellTopBar(
              onHomeTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              isBagHighlighted: true,
              title: 'Equipment',
            ),
            ZxSimpleTabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Golf Bag'),
                Tab(text: 'Training Kit'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _GolfBagTab(bagAsync: bagAsync),
                  const TrainingKitTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            final existingTypes = bagAsync.valueOrNull
                    ?.map((c) => c.clubType)
                    .toSet() ??
                <ClubType>{};
            _showAddClubDialog(context, ref, existingTypes);
          } else {
            _showAddItemCategoryPicker(context);
          }
        },
        backgroundColor: ColorTokens.primaryDefault,
        child: const Icon(Icons.add, color: ColorTokens.textPrimary),
      ),
    );
  }

  void _showAddItemCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Text(
                'Add Equipment',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: ColorTokens.textPrimary,
                    ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final category in EquipmentCategory.values)
                    ListTile(
                      leading: Icon(
                        _categoryIcon(category),
                        color: ColorTokens.textSecondary,
                      ),
                      title: Text(
                        _categoryLabel(category),
                        style: const TextStyle(color: ColorTokens.textPrimary),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TrainingKitItemDetailScreen(
                            category: category,
                          ),
                        ));
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
          ],
        ),
      ),
    );
  }

  // Common clubs — the 16 most typical clubs in a bag.
  static const _commonClubs = <ClubType>[
    ClubType.driver,
    ClubType.w3,
    ClubType.w5,
    ClubType.h3,
    ClubType.h4,
    ClubType.i2,
    ClubType.i3,
    ClubType.i4,
    ClubType.i5,
    ClubType.i6,
    ClubType.i7,
    ClubType.i8,
    ClubType.i9,
    ClubType.pw,
    ClubType.gw,
    ClubType.sw,
    ClubType.lw,
    ClubType.putter,
  ];

  // Full list — all clubs grouped by category for expandable view.
  static const _fullClubGroups = <String, List<ClubType>>{
    'Driver': [ClubType.driver],
    'Woods': [
      ClubType.w1, ClubType.w2, ClubType.w3, ClubType.w4, ClubType.w5,
      ClubType.w6, ClubType.w7, ClubType.w8, ClubType.w9,
    ],
    'Hybrids': [
      ClubType.h1, ClubType.h2, ClubType.h3, ClubType.h4, ClubType.h5,
      ClubType.h6, ClubType.h7, ClubType.h8, ClubType.h9,
    ],
    'Irons': [
      ClubType.i1, ClubType.i2, ClubType.i3, ClubType.i4, ClubType.i5,
      ClubType.i6, ClubType.i7, ClubType.i8, ClubType.i9,
    ],
    'Wedges': [
      ClubType.pw, ClubType.aw, ClubType.gw, ClubType.sw, ClubType.uw,
      ClubType.lw,
    ],
    'Chipper': [ClubType.chipper],
    'Putter': [ClubType.putter],
  };

  void _showAddClubDialog(
      BuildContext context, WidgetRef ref, Set<ClubType> existingTypes) {
    showDialog(
      context: context,
      builder: (ctx) => _AddClubsDialog(
        commonClubs: _commonClubs,
        fullClubGroups: _fullClubGroups,
        existingTypes: existingTypes,
        onAdd: (selected) async {
          Navigator.pop(ctx);
          final clubRepo = ref.read(clubRepositoryProvider);
          for (final type in selected) {
            await clubRepo.addClub(
              ref.read(currentUserIdProvider),
              UserClubsCompanion(clubType: drift.Value(type)),
            );
          }
        },
      ),
    );
  }
}

/// Golf Bag tab — displays user's clubs grouped by category.
class _GolfBagTab extends StatelessWidget {
  final AsyncValue<List<UserClub>> bagAsync;
  const _GolfBagTab({required this.bagAsync});

  // Canonical club order.
  static final _clubOrder = {
    for (var i = 0; i < ClubType.values.length; i++)
      ClubType.values[i]: i,
  };

  @override
  Widget build(BuildContext context) {
    return bagAsync.when(
      data: (clubs) {
        // Filter out training clubs from the Golf Bag view.
        final bagClubs = clubs
            .where((c) => c.clubType != ClubType.trainingClub)
            .toList();

        if (bagClubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.golf_course,
                  size: 48,
                  color: ColorTokens.textTertiary,
                ),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  'Your bag is empty',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: ColorTokens.textSecondary),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Add clubs to get started',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: ColorTokens.textTertiary),
                ),
              ],
            ),
          );
        }

        final grouped = _groupClubs(bagClubs);
        final flatClubs = [
          for (final entry in grouped.entries)
            ...entry.value,
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: SpacingTokens.md,
                left: SpacingTokens.md,
                right: SpacingTokens.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        '${bagClubs.length} ${bagClubs.length == 1 ? 'club' : 'clubs'}',
                        style: const TextStyle(
                          fontSize: TypographyTokens.headerSize,
                          fontWeight: FontWeight.w500,
                          color: ColorTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Padding(
              padding: EdgeInsets.only(
                bottom: SpacingTokens.sm,
                left: SpacingTokens.md + SpacingTokens.md,
                right: SpacingTokens.md + SpacingTokens.md,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 56,
                    child: Text('Club',
                        style: TextStyle(
                          fontSize: TypographyTokens.headerSize,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.textSecondary,
                        )),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Flexible(
                    child: Text('Skill Areas',
                        style: TextStyle(
                          fontSize: TypographyTokens.headerSize,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.textSecondary,
                        )),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: Text('Loft',
                          style: TextStyle(
                            fontSize: TypographyTokens.headerSize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.textSecondary,
                          )),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: Text('Carry',
                          style: TextStyle(
                            fontSize: TypographyTokens.headerSize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.textSecondary,
                          )),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                ),
                itemExtent: _kCardItemExtent,
                physics: _CardSnapPhysics(itemExtent: _kCardItemExtent),
                itemCount: flatClubs.length,
                itemBuilder: (context, index) {
                  final club = flatClubs[index];
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: SpacingTokens.sm,
                    ),
                    child: ClubCard(
                      club: club,
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ClubDetailScreen(
                            clubId: club.clubId,
                          ),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
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
    );
  }

  Map<String, List<UserClub>> _groupClubs(List<UserClub> clubs) {
    final grouped = <String, List<UserClub>>{};
    for (final club in clubs) {
      final category = _clubCategory(club.clubType);
      grouped.putIfAbsent(category, () => []).add(club);
    }
    for (final list in grouped.values) {
      list.sort((a, b) =>
          (_clubOrder[a.clubType] ?? 0).compareTo(_clubOrder[b.clubType] ?? 0));
    }
    final ordered = <String, List<UserClub>>{};
    for (final cat in [
      'Driver', 'Woods', 'Hybrids', 'Irons', 'Wedges', 'Chipper', 'Putter'
    ]) {
      if (grouped.containsKey(cat)) {
        ordered[cat] = grouped[cat]!;
      }
    }
    return ordered;
  }

  String _clubCategory(ClubType type) {
    if (type == ClubType.driver) return 'Driver';
    if (type == ClubType.putter) return 'Putter';
    if (type == ClubType.chipper) return 'Chipper';
    if (type == ClubType.trainingClub) return 'Training';
    if (type.dbValue.startsWith('W')) return 'Woods';
    if (type.dbValue.startsWith('H')) return 'Hybrids';
    if (type.dbValue.startsWith('i')) return 'Irons';
    return 'Wedges';
  }
}

/// Human-readable label for an equipment category.
String _categoryLabel(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.specialistTrainingClub:
      return 'Specialist Training Club';
    case EquipmentCategory.launchMonitor:
      return 'Launch Monitor';
    case EquipmentCategory.puttingGate:
      return 'Putting Gate';
    case EquipmentCategory.alignmentAid:
      return 'Alignment Aid';
    case EquipmentCategory.impactTrainer:
      return 'Impact Trainer';
    case EquipmentCategory.tempoTrainer:
      return 'Tempo Trainer';
    case EquipmentCategory.puttingStrokeTrainer:
      return 'Putting Stroke Trainer';
    case EquipmentCategory.shortGameTarget:
      return 'Short Game Target';
  }
}

/// Icon for an equipment category.
IconData _categoryIcon(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.specialistTrainingClub:
      return Icons.sports_golf;
    case EquipmentCategory.launchMonitor:
      return Icons.radar;
    case EquipmentCategory.puttingGate:
      return Icons.door_sliding;
    case EquipmentCategory.alignmentAid:
      return Icons.straighten;
    case EquipmentCategory.impactTrainer:
      return Icons.fitness_center;
    case EquipmentCategory.tempoTrainer:
      return Icons.timer;
    case EquipmentCategory.puttingStrokeTrainer:
      return Icons.swap_horiz;
    case EquipmentCategory.shortGameTarget:
      return Icons.gps_fixed;
  }
}

/// Multi-select dialog with Common / Full tabs.
class _AddClubsDialog extends StatefulWidget {
  final List<ClubType> commonClubs;
  final Map<String, List<ClubType>> fullClubGroups;
  final Set<ClubType> existingTypes;
  final ValueChanged<Set<ClubType>> onAdd;

  const _AddClubsDialog({
    required this.commonClubs,
    required this.fullClubGroups,
    required this.existingTypes,
    required this.onAdd,
  });

  @override
  State<_AddClubsDialog> createState() => _AddClubsDialogState();
}

class _AddClubsDialogState extends State<_AddClubsDialog> {
  final _selected = <ClubType>{};
  final _expanded = <String>{};

  void _toggle(ClubType type) {
    setState(() {
      if (_selected.contains(type)) {
        _selected.remove(type);
      } else {
        _selected.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Clubs',
                style: TextStyle(color: ColorTokens.textPrimary)),
            const SizedBox(height: SpacingTokens.sm),
            TabBar(
              labelColor: ColorTokens.primaryDefault,
              unselectedLabelColor: ColorTokens.textTertiary,
              indicatorColor: ColorTokens.primaryDefault,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: ColorTokens.surfaceBorder,
              labelStyle: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Common'),
                Tab(text: 'Full'),
              ],
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: TabBarView(
            children: [
              _ClubGrid(
                clubs: widget.commonClubs,
                selected: _selected,
                existingTypes: widget.existingTypes,
                onToggle: _toggle,
              ),
              _FullClubList(
                groups: widget.fullClubGroups,
                selected: _selected,
                existingTypes: widget.existingTypes,
                expanded: _expanded,
                onToggle: _toggle,
                onToggleGroup: (group) => setState(() {
                  if (_expanded.contains(group)) {
                    _expanded.remove(group);
                  } else {
                    _expanded.add(group);
                  }
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed:
                _selected.isEmpty ? null : () => widget.onAdd(_selected),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
            ),
            child: Text(
                'Add${_selected.isEmpty ? '' : ' (${_selected.length})'}'),
          ),
        ],
      ),
    );
  }
}

/// 3-column grid of tappable club cells with selection state.
class _ClubGrid extends StatelessWidget {
  final List<ClubType> clubs;
  final Set<ClubType> selected;
  final Set<ClubType> existingTypes;
  final ValueChanged<ClubType> onToggle;

  const _ClubGrid({
    required this.clubs,
    required this.selected,
    required this.existingTypes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SpacingTokens.sm,
        crossAxisSpacing: SpacingTokens.sm,
        childAspectRatio: 2.0,
      ),
      itemCount: clubs.length,
      itemBuilder: (context, index) {
        final club = clubs[index];
        final isOwned = existingTypes.contains(club);
        final isSelected = selected.contains(club);
        return InkWell(
          onTap: isOwned ? null : () => onToggle(club),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          child: Opacity(
            opacity: isOwned ? 0.35 : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? ColorTokens.primaryDefault.withValues(alpha: 0.2)
                    : ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
                border: Border.all(
                  color: isSelected
                      ? ColorTokens.primaryDefault
                      : ColorTokens.surfaceBorder,
                ),
              ),
              child: Center(
                child: Text(
                  club.dbValue,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? ColorTokens.primaryDefault
                        : ColorTokens.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Expandable category list showing all clubs.
class _FullClubList extends StatelessWidget {
  final Map<String, List<ClubType>> groups;
  final Set<ClubType> selected;
  final Set<ClubType> existingTypes;
  final Set<String> expanded;
  final ValueChanged<ClubType> onToggle;
  final ValueChanged<String> onToggleGroup;

  const _FullClubList({
    required this.groups,
    required this.selected,
    required this.existingTypes,
    required this.expanded,
    required this.onToggle,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final entry in groups.entries)
          _buildGroup(entry.key, entry.value),
      ],
    );
  }

  Widget _buildGroup(String category, List<ClubType> clubs) {
    if (clubs.length == 1) {
      final club = clubs.first;
      final isOwned = existingTypes.contains(club);
      final isSelected = selected.contains(club);
      return Padding(
        padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
        child: Opacity(
          opacity: isOwned ? 0.35 : 1.0,
          child: InkWell(
          onTap: isOwned ? null : () => onToggle(club),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.md,
              vertical: SpacingTokens.sm + 2,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorTokens.primaryDefault.withValues(alpha: 0.2)
                  : ColorTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
              border: Border.all(
                color: isSelected
                    ? ColorTokens.primaryDefault
                    : ColorTokens.surfaceBorder,
              ),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? ColorTokens.primaryDefault
                    : ColorTokens.textPrimary,
              ),
            ),
          ),
        ),
        ),
      );
    }

    final isExpanded = expanded.contains(category);
    final selectedInGroup = clubs.where((c) => selected.contains(c)).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => onToggleGroup(category),
            borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm + 2,
              ),
              decoration: BoxDecoration(
                color: ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
                border: Border.all(color: ColorTokens.surfaceBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedInGroup > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs + 2, vertical: 2),
                      margin:
                          const EdgeInsets.only(right: SpacingTokens.xs),
                      decoration: BoxDecoration(
                        color: ColorTokens.primaryDefault
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                            ShapeTokens.radiusSegmented),
                      ),
                      child: Text('$selectedInGroup',
                          style: const TextStyle(
                            fontSize: TypographyTokens.bodySmSize,
                            color: ColorTokens.primaryDefault,
                          )),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: ColorTokens.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.sm),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: SpacingTokens.sm,
                crossAxisSpacing: SpacingTokens.sm,
                childAspectRatio: 2.0,
                children: clubs.map((club) {
                  final isOwned = existingTypes.contains(club);
                  final isSelected = selected.contains(club);
                  return Opacity(
                    opacity: isOwned ? 0.35 : 1.0,
                    child: InkWell(
                    onTap: isOwned ? null : () => onToggle(club),
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusGrid),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorTokens.primaryDefault
                                .withValues(alpha: 0.2)
                            : ColorTokens.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusGrid),
                        border: Border.all(
                          color: isSelected
                              ? ColorTokens.primaryDefault
                              : ColorTokens.surfaceBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          club.dbValue,
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySize,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? ColorTokens.primaryDefault
                                : ColorTokens.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Scroll physics that snaps to card boundaries.
class _CardSnapPhysics extends ScrollPhysics {
  final double itemExtent;

  const _CardSnapPhysics({required this.itemExtent, super.parent});

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _CardSnapPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  double _targetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    var page = position.pixels / itemExtent;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return (page.roundToDouble() * itemExtent)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final target = _targetPixels(position, toleranceFor(position), velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: toleranceFor(position),
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
