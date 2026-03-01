import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Phase 3 — Practice Pool: user's active drill collection.
// Adopted system drills + active custom drills.
// S12 §12.3 — Track tab primary view.

class PracticePoolScreen extends ConsumerStatefulWidget {
  const PracticePoolScreen({super.key});

  @override
  ConsumerState<PracticePoolScreen> createState() =>
      _PracticePoolScreenState();
}

class _PracticePoolScreenState extends ConsumerState<PracticePoolScreen> {
  // Phase 3 stub — replaced when auth is wired.
  static const _userId = 'local-user';
  SkillArea? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final poolAsync = ref.watch(practicePoolProvider(_userId));

    return Scaffold(
      appBar: ZxAppBar(
        title: 'Practice Pool',
        actions: [
          IconButton(
            icon: const Icon(Icons.golf_course),
            tooltip: 'Golf Bag',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const BagScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: 'System Library',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const DrillLibraryScreen(),
              ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Skill area filter.
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: SkillAreaPicker(
              selected: _selectedFilter,
              onChanged: (area) => setState(() => _selectedFilter = area),
            ),
          ),
          // Drill list.
          Expanded(
            child: poolAsync.when(
              data: (drills) {
                final filtered = _selectedFilter == null
                    ? drills
                    : drills
                        .where(
                            (d) => d.drill.skillArea == _selectedFilter)
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
                      onTap: () => _openDrillDetail(dwa),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const DrillCreateScreen(),
          ));
        },
        backgroundColor: ColorTokens.primaryDefault,
        child: const Icon(Icons.add, color: Colors.white),
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

