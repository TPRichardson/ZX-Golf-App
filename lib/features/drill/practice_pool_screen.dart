import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/providers/drill_providers.dart';

import '../bag/bag_screen.dart';
import 'drill_detail_screen.dart';
import 'drill_create_screen.dart';
import 'drill_library_screen.dart';
import 'widgets/drill_card.dart';
import 'widgets/skill_area_picker.dart';

/// 5E — Persistent filter state for Practice Pool (survives navigation).
final practicePoolFilterProvider = StateProvider<SkillArea?>((ref) => null);

// Phase 3 — Practice Pool: user's active drill collection.
// Adopted system drills + active custom drills.
// S12 §12.3 — Track tab primary view.

class PracticePoolScreen extends ConsumerStatefulWidget {
  /// When true, tapping a drill pops with the drillId instead of navigating.
  final bool pickMode;

  const PracticePoolScreen({super.key, this.pickMode = false});

  @override
  ConsumerState<PracticePoolScreen> createState() =>
      _PracticePoolScreenState();
}

class _PracticePoolScreenState extends ConsumerState<PracticePoolScreen> {
  // Phase 3 stub — replaced when auth is wired.
  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context) {
    // 5E — Read persistent filter from provider.
    final selectedFilter = ref.watch(practicePoolFilterProvider);
    final poolAsync = ref.watch(practicePoolProvider(_userId));

    return Scaffold(
      appBar: ZxAppBar(
        title: widget.pickMode ? 'Select Drill' : 'Practice Pool',
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
      body: Column(
        children: [
          // 5E — Skill area filter persisted across navigation.
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: SkillAreaPicker(
              selected: selectedFilter,
              onChanged: (area) =>
                  ref.read(practicePoolFilterProvider.notifier).state = area,
            ),
          ),
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_golf,
                          size: 48,
                          color: ColorTokens.textTertiary,
                        ),
                        const SizedBox(height: SpacingTokens.md),
                        Text(
                          'No drills in your practice pool',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: ColorTokens.textSecondary),
                        ),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(
                          'Adopt drills from the System Library\nor create your own',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: ColorTokens.textTertiary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: SpacingTokens.sm),
                  itemBuilder: (context, index) {
                    final dwa = filtered[index];
                    return DrillCard(
                      drill: dwa.drill,
                      onTap: () {
                        if (widget.pickMode) {
                          Navigator.of(context).pop(dwa.drill.drillId);
                          return;
                        }
                        _openDrillDetail(dwa);
                      },
                    );
                  },
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
      ),
      bottomNavigationBar: widget.pickMode
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md,
                SpacingTokens.sm,
                SpacingTokens.md,
                SpacingTokens.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const DrillLibraryScreen(),
                        ));
                      },
                      icon: const Icon(Icons.library_books, size: 18),
                      label: const Text('System Drills'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorTokens.primaryDefault,
                        side: const BorderSide(
                            color: ColorTokens.primaryDefault),
                        padding: const EdgeInsets.symmetric(
                            vertical: SpacingTokens.sm),
                      ),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const DrillCreateScreen(),
                        ));
                      },
                      icon: const Icon(Icons.add, color: Colors.white,
                          size: 18),
                      label: const Text('Create Drill',
                          style: TextStyle(color: Colors.white)),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorTokens.primaryDefault,
                        padding: const EdgeInsets.symmetric(
                            vertical: SpacingTokens.sm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

