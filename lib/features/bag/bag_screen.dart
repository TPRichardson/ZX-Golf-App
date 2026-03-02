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

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: SpacingTokens.md,
                    bottom: SpacingTokens.sm,
                  ),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: ColorTokens.textPrimary,
                        ),
                  ),
                ),
                for (final club in entry.value)
                  Padding(
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
                  ),
              ],
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

  Map<String, List<UserClub>> _groupClubs(List<UserClub> clubs) {
    final grouped = <String, List<UserClub>>{};
    for (final club in clubs) {
      final category = _clubCategory(club.clubType);
      grouped.putIfAbsent(category, () => []).add(club);
    }
    // Order categories.
    final ordered = <String, List<UserClub>>{};
    for (final cat in [
      'Driver',
      'Woods',
      'Hybrids',
      'Irons',
      'Wedges',
      'Specialty',
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
    if (type == ClubType.chipper) return 'Specialty';
    if (type.dbValue.startsWith('W')) return 'Woods';
    if (type.dbValue.startsWith('H')) return 'Hybrids';
    if (type.dbValue.startsWith('i')) return 'Irons';
    // Wedges: PW, AW, GW, SW, UW, LW.
    return 'Wedges';
  }

  void _showAddClubDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Club'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: [
              for (final type in ClubType.values)
                ListTile(
                  title: Text(type.dbValue),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(clubRepositoryProvider).addClub(
                          _userId,
                          UserClubsCompanion(
                            clubType: drift.Value(type),
                          ),
                        );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
