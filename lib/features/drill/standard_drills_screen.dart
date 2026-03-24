import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

import 'drill_sort_order.dart';
import 'widgets/drill_card.dart';
import 'widgets/skill_area_carousel_indicator.dart';

// Manage Standard Drills — shows all system drills in one list.
// Active drills appear normally; retired/unadopted drills appear greyed out.
// Tapping the toggle icon switches between active and retired.

class StandardDrillsScreen extends ConsumerStatefulWidget {
  final bool pickMode;

  const StandardDrillsScreen({super.key, this.pickMode = false});

  @override
  ConsumerState<StandardDrillsScreen> createState() =>
      _StandardDrillsScreenState();
}

class _StandardDrillsScreenState extends ConsumerState<StandardDrillsScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

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
    final allDrillsAsync = ref.watch(allSystemDrillsProvider(userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Manage Standard Drills'),
      body: allDrillsAsync.when(
        data: (allDrills) {
          if (allDrills.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xl),
                child: Text(
                  'No standard drills available',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: ColorTokens.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              SkillAreaCarouselIndicator(
                title: 'Manage Standard Drills',
                currentPage: _currentPage,
              ),
              const SizedBox(height: SpacingTokens.sm),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: kSkillAreaDisplayOrder.length,
                  onPageChanged: (page) =>
                      setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final area = kSkillAreaDisplayOrder[index];
                    final areaDrills = allDrills
                        .where((d) => d.drill.skillArea == area)
                        .toList();

                    areaDrills.sort(_sortByTypeAndName);

                    if (areaDrills.isEmpty) {
                      return Center(
                        child: Text(
                          'No ${area.dbValue} drills',
                          style: const TextStyle(
                            fontSize: TypographyTokens.bodyLgSize,
                            color: ColorTokens.textTertiary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.lg,
                      ),
                      itemCount: areaDrills.length,
                      itemBuilder: (context, i) {
                        final dwa = areaDrills[i];
                        final isActive = dwa.adoption != null &&
                            dwa.adoption!.status == AdoptionStatus.active;

                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: SpacingTokens.sm),
                          child: Opacity(
                            opacity: isActive ? 1.0 : 0.4,
                            child: DrillCard(
                              drill: dwa.drill,
                              trailing: IconButton(
                                icon: Icon(
                                  isActive
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isActive
                                      ? ColorTokens.successDefault
                                      : ColorTokens.textTertiary,
                                  size: 22,
                                ),
                                tooltip: isActive ? 'Unadopt' : 'Adopt',
                                onPressed: () => isActive
                                    ? _retireDrill(userId, dwa.drill.drillId)
                                    : _reAdoptDrill(
                                        userId, dwa.drill.drillId),
                              ),
                              onTap: widget.pickMode
                                  ? () => Navigator.of(context)
                                      .pop(dwa.drill.drillId)
                                  : null,
                            ),
                          ),
                        );
                      },
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
    );
  }

  int _sortByTypeAndName(DrillWithAdoption a, DrillWithAdoption b) {
    final typeA = kDrillTypeSortOrder.indexOf(a.drill.drillType);
    final typeB = kDrillTypeSortOrder.indexOf(b.drill.drillType);
    if (typeA != typeB) return typeA.compareTo(typeB);
    return a.drill.name.compareTo(b.drill.name);
  }

  Future<void> _retireDrill(String userId, String drillId) async {
    try {
      await ref.read(drillRepositoryProvider).retireAdoption(userId, drillId);
    } catch (e) {
      debugPrint('[ManageDrills] Retire failed: $e');
    }
  }

  Future<void> _reAdoptDrill(String userId, String drillId) async {
    try {
      await ref.read(drillRepositoryProvider).adoptDrill(userId, drillId);
    } catch (e) {
      debugPrint('[ManageDrills] Re-adopt failed: $e');
    }
  }
}
