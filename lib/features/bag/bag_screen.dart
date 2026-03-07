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

  // Club categories for the grouped picker.
  static const _clubGroups = <String, List<ClubType>>{
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
    'Putter': [ClubType.putter],
    'Specialty': [ClubType.chipper],
  };

  void _showAddClubDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Add Club',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final entry in _clubGroups.entries)
                _ClubGroupTile(
                  category: entry.key,
                  clubs: entry.value,
                  onClubSelected: (type) async {
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

/// A category row in the add-club picker. Single-item categories (Driver,
/// Putter) select immediately on tap. Multi-item categories expand to show
/// individual clubs.
class _ClubGroupTile extends StatefulWidget {
  final String category;
  final List<ClubType> clubs;
  final ValueChanged<ClubType> onClubSelected;

  const _ClubGroupTile({
    required this.category,
    required this.clubs,
    required this.onClubSelected,
  });

  @override
  State<_ClubGroupTile> createState() => _ClubGroupTileState();
}

class _ClubGroupTileState extends State<_ClubGroupTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Single-club categories — tap selects directly.
    if (widget.clubs.length == 1) {
      return ListTile(
        title: Text(widget.category,
            style: const TextStyle(color: ColorTokens.textPrimary)),
        leading: const Icon(Icons.sports_golf, color: ColorTokens.textSecondary),
        onTap: () => widget.onClubSelected(widget.clubs.first),
      );
    }

    // Multi-club categories — expand to show children.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(widget.category,
              style: const TextStyle(color: ColorTokens.textPrimary)),
          leading:
              const Icon(Icons.sports_golf, color: ColorTokens.textSecondary),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: ColorTokens.textTertiary,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(left: SpacingTokens.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.clubs
                  .map((club) => ListTile(
                        dense: true,
                        title: Text(club.dbValue,
                            style: const TextStyle(
                                color: ColorTokens.textSecondary)),
                        onTap: () => widget.onClubSelected(club),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
