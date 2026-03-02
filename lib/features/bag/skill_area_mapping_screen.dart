import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Phase 3 — Skill Area Mapping screen.
// S09 §9.2.3 — Configure which clubs map to which skill areas.
// Mandatory mappings are disabled (always checked).

class SkillAreaMappingScreen extends ConsumerWidget {
  const SkillAreaMappingScreen({super.key});

  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bagAsync = ref.watch(userBagProvider(_userId));
    final mappingsAsync = ref.watch(skillAreaMappingsProvider(_userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Skill Area Mappings'),
      body: bagAsync.when(
        data: (clubs) {
          return mappingsAsync.when(
            data: (mappings) {
              if (clubs.isEmpty) {
                return Center(
                  child: Text(
                    'Add clubs to your bag first',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: ColorTokens.textSecondary),
                  ),
                );
              }

              // Build mapping lookup: (clubType, skillArea) → mapping.
              final mappingLookup = <(ClubType, SkillArea), UserSkillAreaClubMapping>{};
              for (final m in mappings) {
                mappingLookup[(m.clubType, m.skillArea)] = m;
              }

              // Get unique club types in bag.
              final clubTypes =
                  clubs.map((c) => c.clubType).toSet().toList()
                    ..sort((a, b) => a.index.compareTo(b.index));

              return ListView(
                padding: const EdgeInsets.all(SpacingTokens.md),
                children: [
                  for (final area in SkillArea.values) ...[
                    ExpansionTile(
                      title: Text(
                        area.dbValue,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: ColorTokens.textPrimary),
                      ),
                      initiallyExpanded: false,
                      children: [
                        for (final clubType in clubTypes)
                          _MappingCheckbox(
                            clubType: clubType,
                            skillArea: area,
                            mapping: mappingLookup[(clubType, area)],
                            onToggle: (mapped) async {
                              await ref
                                  .read(clubRepositoryProvider)
                                  .updateSkillAreaMapping(
                                    _userId,
                                    clubType,
                                    area,
                                    mapped,
                                  );
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _MappingCheckbox extends StatelessWidget {
  final ClubType clubType;
  final SkillArea skillArea;
  final UserSkillAreaClubMapping? mapping;
  final Future<void> Function(bool mapped) onToggle;

  const _MappingCheckbox({
    required this.clubType,
    required this.skillArea,
    required this.mapping,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMapped = mapping != null;
    final isMandatory = mapping?.isMandatory ?? false;

    return CheckboxListTile(
      title: Text(
        clubType.dbValue,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ColorTokens.textPrimary,
            ),
      ),
      subtitle: isMandatory
          ? Text(
              'Required',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ColorTokens.textTertiary,
                  ),
            )
          : null,
      value: isMapped,
      onChanged: isMandatory
          ? null // Disabled for mandatory mappings.
          : (value) async {
              try {
                await onToggle(value ?? false);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
      activeColor: ColorTokens.primaryDefault,
    );
  }
}
