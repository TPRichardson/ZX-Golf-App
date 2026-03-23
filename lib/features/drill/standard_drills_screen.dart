import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import 'package:zx_golf_app/features/bag/bag_screen.dart';

import 'drill_sort_order.dart';
import 'widgets/drill_card.dart';
import 'widgets/skill_area_carousel_indicator.dart';

// Standard Drills — server-authoritative catalogue fetched from Supabase.
// S14 §14.1 — Standard drill catalogue.

class StandardDrillsScreen extends ConsumerStatefulWidget {
  /// When true, tapping a drill pops with the drillId instead of navigating.
  final bool pickMode;

  const StandardDrillsScreen({super.key, this.pickMode = false});

  @override
  ConsumerState<StandardDrillsScreen> createState() =>
      _StandardDrillsScreenState();
}

class _StandardDrillsScreenState extends ConsumerState<StandardDrillsScreen> {
  final Set<String> _selectedIds = {};
  bool _isAdopting = false;
  late final PageController _pageController;
  int _currentPage = 0;
  bool _didJumpToFirstTab = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final catalogueAsync = ref.watch(standardDrillCatalogueProvider);
    final adoptedAsync = ref.watch(adoptedDrillsProvider(userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Standard Drills'),
      body: catalogueAsync.when(
        data: (drills) {
          if (drills.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 48, color: ColorTokens.textTertiary),
                    const SizedBox(height: SpacingTokens.md),
                    Text(
                      'Connect to browse standard drills',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: ColorTokens.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final adopted = adoptedAsync.valueOrNull ?? [];
          final adoptedIds = adopted.map((a) => a.drill.drillId).toSet();

          // Only show drills not already adopted.
          final available =
              drills.where((d) => !adoptedIds.contains(d.drillId)).toList();

          // Clean up selections for drills that were adopted.
          _selectedIds.removeWhere((id) => adoptedIds.contains(id));

          if (available.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xl),
                child: Text(
                  'All standard drills added',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ColorTokens.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Group by SkillArea.
          final grouped = <SkillArea, List<Drill>>{};
          for (final drill in available) {
            grouped.putIfAbsent(drill.skillArea, () => []).add(drill);
          }
          // Sort within each group by drill type.
          for (final list in grouped.values) {
            list.sort((a, b) {
              final typeA = kDrillTypeSortOrder.indexOf(a.drillType);
              final typeB = kDrillTypeSortOrder.indexOf(b.drillType);
              if (typeA != typeB) return typeA.compareTo(typeB);
              return a.name.compareTo(b.name);
            });
          }

          // Build drill-by-id map for adopt action.
          final drillById = {for (final d in drills) d.drillId: d};

          // Jump to first tab with available drills on initial load.
          if (!_didJumpToFirstTab && grouped.isNotEmpty) {
            _didJumpToFirstTab = true;
            final firstIndex = kSkillAreaDisplayOrder.indexWhere(
                (a) => (grouped[a]?.isNotEmpty ?? false));
            if (firstIndex > 0) {
              _currentPage = firstIndex;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(firstIndex);
                }
              });
            }
          }

          return Column(
            children: [
              // Carousel indicator.
              _buildCarouselIndicator(),
              const SizedBox(height: SpacingTokens.sm),
              // Carousel pages.
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: kSkillAreaDisplayOrder.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final area = kSkillAreaDisplayOrder[index];
                    final areaDrills = grouped[area] ?? [];

                    if (areaDrills.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 48,
                                color: ColorTokens.successDefault.withValues(alpha: 0.5)),
                            const SizedBox(height: SpacingTokens.md),
                            Text(
                              'All ${area.dbValue} drills added',
                              style: const TextStyle(
                                fontSize: TypographyTokens.bodyLgSize,
                                color: ColorTokens.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Group by drill type.
                    final typeGroups = <DrillType, List<Drill>>{};
                    for (final d in areaDrills) {
                      typeGroups.putIfAbsent(d.drillType, () => []).add(d);
                    }
                    final orderedTypes = kDrillTypeSortOrder
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
                          selectedIds: _selectedIds,
                          onTap: (drill) {
                            if (widget.pickMode) {
                              Navigator.of(context).pop(drill.drillId);
                              return;
                            }
                            setState(() {
                              if (_selectedIds.contains(drill.drillId)) {
                                _selectedIds.remove(drill.drillId);
                              } else {
                                _selectedIds.add(drill.drillId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (_selectedIds.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: ZxPillButton(
                        label: 'Add ${_selectedIds.length} Drill${_selectedIds.length == 1 ? '' : 's'}',
                        icon: Icons.add,
                        variant: ZxPillVariant.primary,
                        isLoading: _isAdopting,
                        onTap: _isAdopting
                            ? null
                            : () => _adoptSelected(drillById),
                      ),
                    ),
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
    );
  }

  Future<void> _adoptSelected(Map<String, Drill> drillById) async {
    setState(() => _isAdopting = true);
    final drillRepo = ref.read(drillRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final drillsToAdopt = _selectedIds
        .map((id) => drillById[id])
        .whereType<Drill>()
        .toList();

    // Pop first to dispose the widget before DB writes trigger provider
    // notifications on defunct elements.
    Navigator.of(context).popUntil((route) => route.isFirst);

    try {
      for (final drill in drillsToAdopt) {
        await drillRepo.adoptStandardDrill(userId, drill);
      }
    } on ValidationException catch (e) {
      setState(() => _isAdopting = false);
      if (!mounted) return;
      final isEquipmentError = e.context?['missing'] != null;
      final isCarryError = e.context?['missingCarry'] != null;
      final String title;
      final String actionLabel;
      final Widget actionScreen;
      if (isEquipmentError) {
        title = 'Missing Equipment';
        actionLabel = 'Open Training Kit';
        actionScreen = const BagScreen(initialTab: 1);
      } else if (isCarryError) {
        title = 'Missing Carry Distances';
        actionLabel = 'Customise Golf Bag';
        actionScreen = const BagScreen();
      } else {
        title = 'Missing Clubs';
        actionLabel = 'Customise Golf Bag';
        actionScreen = const BagScreen();
      }
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: ColorTokens.surfaceModal,
          title: Text(title,
              style: const TextStyle(color: ColorTokens.textPrimary)),
          content: Text(
            e.message,
            style: const TextStyle(color: ColorTokens.textSecondary),
          ),
          actions: [
            ZxPillButton(
              label: 'Return to Drills',
              variant: ZxPillVariant.tertiary,
              onTap: () => Navigator.pop(dialogCtx),
            ),
            ZxPillButton(
              label: actionLabel,
              variant: ZxPillVariant.primary,
              onTap: () {
                Navigator.pop(dialogCtx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => actionScreen),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('[StandardDrills] Adopt error: $e');
      setState(() => _isAdopting = false);
    }
  }

  Widget _buildCarouselIndicator() {
    return SkillAreaCarouselIndicator(
      title: 'Standard Drills',
      currentPage: _currentPage,
    );
  }
}

class _DrillTypeSection extends StatefulWidget {
  final DrillType drillType;
  final List<Drill> drills;
  final Set<String> selectedIds;
  final void Function(Drill) onTap;

  const _DrillTypeSection({
    required this.drillType,
    required this.drills,
    required this.selectedIds,
    required this.onTap,
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
          if (_expanded)
            ...widget.drills.map((drill) => Padding(
                  padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                  child: DrillCard(
                    drill: drill,
                    isSelected: widget.selectedIds.contains(drill.drillId),
                    onTap: () => widget.onTap(drill),
                  ),
                )),
        ],
      ),
    );
  }
}
