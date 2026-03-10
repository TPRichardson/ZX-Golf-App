import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import 'club_detail_screen.dart';
import 'skill_area_mapping_screen.dart';
import 'widgets/club_card.dart';

// Phase 3 — Bag screen. Displays user's golf bag, grouped by club category.
// S09 §9.1 — Club configuration.

// Card height (ZxCard 16+16 padding + ~60 content + 2 border) + 8 bottom margin.
const _kCardItemExtent = 104.0;

class BagScreen extends ConsumerWidget {
  const BagScreen({super.key});

  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bagAsync = ref.watch(userBagProvider(_userId));

    return Scaffold(
      appBar: ZxAppBar(
        title: 'Golf Bag',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Skill Area Mappings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SkillAreaMappingScreen(),
              ));
            },
          ),
        ],
      ),
      body: bagAsync.when(
        data: (clubs) {
          if (clubs.isEmpty) {
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

          // Group clubs by category.
          final grouped = _groupClubs(clubs);
          final flatClubs = [
            for (final entry in grouped.entries)
              ...entry.value,
          ];

          return Column(
            children: [
              // Fixed header area.
              Padding(
                padding: const EdgeInsets.only(
                  top: SpacingTokens.md,
                  left: SpacingTokens.md,
                  right: SpacingTokens.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${clubs.length} ${clubs.length == 1 ? 'club' : 'clubs'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: ColorTokens.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              // Column header row — aligned with ZxCard internal padding.
              Padding(
                padding: EdgeInsets.only(
                  bottom: SpacingTokens.sm,
                  // ListView md padding + ZxCard md padding
                  left: SpacingTokens.md + SpacingTokens.md,
                  right: SpacingTokens.md + SpacingTokens.md,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 56,
                      child: Text('Club',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.textSecondary,
                          )),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Flexible(
                      child: Text('Skill Areas',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySize,
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
                              fontSize: TypographyTokens.bodySize,
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
                              fontSize: TypographyTokens.bodySize,
                              fontWeight: FontWeight.w600,
                              color: ColorTokens.textSecondary,
                            )),
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.xs),
                    const SizedBox(width: 24), // chevron space
                  ],
                ),
              ),
              // Scrollable club list with snap-to-card physics.
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddClubDialog(context, ref),
        backgroundColor: ColorTokens.primaryDefault,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Canonical club order — matches _fullClubGroups.
  static final _clubOrder = {
    for (var i = 0; i < ClubType.values.length; i++)
      ClubType.values[i]: i,
  };

  Map<String, List<UserClub>> _groupClubs(List<UserClub> clubs) {
    final grouped = <String, List<UserClub>>{};
    for (final club in clubs) {
      final category = _clubCategory(club.clubType);
      grouped.putIfAbsent(category, () => []).add(club);
    }
    // Sort clubs within each group by canonical order.
    for (final list in grouped.values) {
      list.sort((a, b) =>
          (_clubOrder[a.clubType] ?? 0).compareTo(_clubOrder[b.clubType] ?? 0));
    }
    // Order categories.
    final ordered = <String, List<UserClub>>{};
    for (final cat in [
      'Driver',
      'Woods',
      'Hybrids',
      'Irons',
      'Wedges',
      'Chipper',
      'Putter'
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
    if (type.dbValue.startsWith('W')) return 'Woods';
    if (type.dbValue.startsWith('H')) return 'Hybrids';
    if (type.dbValue.startsWith('i')) return 'Irons';
    // Wedges: PW, AW, GW, SW, UW, LW.
    return 'Wedges';
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

  void _showAddClubDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddClubsDialog(
        commonClubs: _commonClubs,
        fullClubGroups: _fullClubGroups,
        onAdd: (selected) async {
          Navigator.pop(ctx);
          final clubRepo = ref.read(clubRepositoryProvider);
          for (final type in selected) {
            await clubRepo.addClub(
              _userId,
              UserClubsCompanion(clubType: drift.Value(type)),
            );
          }
        },
      ),
    );
  }
}

/// Multi-select dialog with Common / Full tabs.
class _AddClubsDialog extends StatefulWidget {
  final List<ClubType> commonClubs;
  final Map<String, List<ClubType>> fullClubGroups;
  final ValueChanged<Set<ClubType>> onAdd;

  const _AddClubsDialog({
    required this.commonClubs,
    required this.fullClubGroups,
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
                onToggle: _toggle,
              ),
              _FullClubList(
                groups: widget.fullClubGroups,
                selected: _selected,
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
  final ValueChanged<ClubType> onToggle;

  const _ClubGrid({
    required this.clubs,
    required this.selected,
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
        final isSelected = selected.contains(club);
        return InkWell(
          onTap: () => onToggle(club),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
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
        );
      },
    );
  }
}

/// Expandable category list showing all clubs.
class _FullClubList extends StatelessWidget {
  final Map<String, List<ClubType>> groups;
  final Set<ClubType> selected;
  final Set<String> expanded;
  final ValueChanged<ClubType> onToggle;
  final ValueChanged<String> onToggleGroup;

  const _FullClubList({
    required this.groups,
    required this.selected,
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
    // Single-club categories — tap cell directly.
    if (clubs.length == 1) {
      final club = clubs.first;
      final isSelected = selected.contains(club);
      return Padding(
        padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
        child: InkWell(
          onTap: () => onToggle(club),
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
      );
    }

    // Multi-club categories — expandable header + grid.
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
                            fontSize: TypographyTokens.microSize,
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
                  final isSelected = selected.contains(club);
                  return InkWell(
                    onTap: () => onToggle(club),
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
