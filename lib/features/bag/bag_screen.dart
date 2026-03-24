import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import 'club_detail_screen.dart';
import 'training_kit_tab.dart';
import 'training_kit_item_detail_screen.dart';
import 'widgets/add_clubs_dialog.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _checkCarriesBeforeLeaving();
      },
      child: Scaffold(
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
    ),
    );
  }

  Future<void> _checkCarriesBeforeLeaving() async {
    final userId = ref.read(currentUserIdProvider);
    final clubs = ref.read(userBagProvider(userId)).valueOrNull ?? [];
    final clubRepo = ref.read(clubRepositoryProvider);

    // Check non-putter clubs for missing carry distances.
    bool hasMissing = false;
    for (final club in clubs) {
      if (club.clubType == ClubType.putter) continue;
      final profile = await clubRepo.getActiveProfile(club.clubId);
      if (profile == null || profile.carryDistance == null) {
        hasMissing = true;
        break;
      }
    }

    if (!mounted) return;

    if (hasMissing && clubs.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: ColorTokens.surfaceModal,
          title: const Text('Missing Carry Distances',
              style: TextStyle(color: ColorTokens.textPrimary)),
          content: const Text(
            'Some clubs are missing carry distances. '
            'Carry distances are required for some drills.',
            style: TextStyle(color: ColorTokens.textSecondary),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
              SpacingTokens.lg, 0, SpacingTokens.lg, SpacingTokens.lg),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ZxPillButton(
                  label: 'Add Carry Distances',
                  variant: ZxPillVariant.primary,
                  expanded: true,
                  centered: true,
                  onTap: () => Navigator.pop(dialogCtx, false),
                ),
                const SizedBox(height: SpacingTokens.sm),
                ZxPillButton(
                  label: 'Skip for Now',
                  variant: ZxPillVariant.tertiary,
                  expanded: true,
                  centered: true,
                  onTap: () => Navigator.pop(dialogCtx, true),
                ),
              ],
            ),
          ],
        ),
      );
      if (proceed == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
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
      builder: (ctx) => AddClubsDialog(
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
