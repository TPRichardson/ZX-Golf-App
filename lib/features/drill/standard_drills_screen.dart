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

import 'widgets/drill_card.dart';

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

          // Build drill-by-id map for adopt action.
          final drillById = {for (final d in drills) d.drillId: d};

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  children: [
                    for (final area in SkillArea.values)
                      if (grouped.containsKey(area)) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: SpacingTokens.md,
                            bottom: SpacingTokens.sm,
                          ),
                          child: Text(
                            area.dbValue,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: ColorTokens.textPrimary),
                          ),
                        ),
                        for (final drill in grouped[area]!)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: SpacingTokens.sm,
                            ),
                            child: DrillCard(
                              drill: drill,
                              isSelected: _selectedIds.contains(drill.drillId),
                              onTap: () {
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
                              trailing: _selectedIds.contains(drill.drillId)
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: ColorTokens.textTertiary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _selectedIds.remove(drill.drillId);
                                        });
                                      },
                                      tooltip: 'Deselect',
                                    )
                                  : null,
                            ),
                          ),
                      ],
                  ],
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
}
