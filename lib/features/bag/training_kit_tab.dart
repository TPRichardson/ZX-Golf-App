import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/providers/training_kit_providers.dart';

import 'training_kit_item_detail_screen.dart';

/// Parse the SkillAreas JSON array column into a list of [SkillArea].
List<SkillArea> parseSkillAreas(String json) {
  if (json.isEmpty || json == '[]') return const [];
  try {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => SkillArea.fromString(e as String))
        .toList();
  } on Exception {
    return const [];
  }
}

// Training Kit tab — displays equipment items grouped by category.

class TrainingKitTab extends ConsumerWidget {
  const TrainingKitTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final kitAsync = ref.watch(userTrainingKitProvider(userId));

    return kitAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction,
                  size: 48,
                  color: ColorTokens.textTertiary,
                ),
                const SizedBox(height: SpacingTokens.md),
                Text(
                  'No training equipment',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: ColorTokens.textSecondary),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Tap + to add equipment',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: ColorTokens.textTertiary),
                ),
              ],
            ),
          );
        }

        // Group by category — only show categories with items.
        final grouped = <EquipmentCategory, List<UserTrainingItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.category, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.all(SpacingTokens.md),
          children: [
            for (final category in EquipmentCategory.values)
              if (grouped.containsKey(category)) ...[
                Padding(
                  padding: const EdgeInsets.only(
                    top: SpacingTokens.md,
                    bottom: SpacingTokens.sm,
                  ),
                  child: Text(
                    _categoryLabel(category),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: ColorTokens.textPrimary),
                  ),
                ),
                for (final item in grouped[category]!)
                  Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
                    child: _UserTrainingItemCard(item: item),
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
    );
  }
}

/// Card for a training kit item — mirrors ClubCard pattern.
class _UserTrainingItemCard extends StatelessWidget {
  final UserTrainingItem item;
  const _UserTrainingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final props = _parseProperties(item.properties);
    final areas = parseSkillAreas(item.skillAreas);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => TrainingKitItemDetailScreen(
            category: item.category,
            existingItemId: item.itemId,
          ),
        ));
      },
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.md),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: FontWeight.w500,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  if (props.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: SpacingTokens.xs),
                      child: Text(
                        props,
                        style: const TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            const Icon(
              Icons.chevron_right,
              color: ColorTokens.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a detail string from properties JSON.
  String _parseProperties(String propertiesJson) {
    if (propertiesJson == '{}' || propertiesJson.isEmpty) return '';
    try {
      final map = jsonDecode(propertiesJson) as Map<String, dynamic>;
      final parts = <String>[];
      if (map['brand'] != null) parts.add(map['brand'] as String);
      if (map['model'] != null) parts.add(map['model'] as String);
      if (map['make'] != null && map['brand'] == null) {
        parts.add(map['make'] as String);
      }
      if (map['widthCm'] != null) parts.add('${map['widthCm']} cm');
      if (map['loft'] != null) parts.add('${map['loft']}°');
      return parts.join(' · ');
    } on Exception {
      return '';
    }
  }
}

String _categoryLabel(EquipmentCategory category) {
  switch (category) {
    case EquipmentCategory.specialistTrainingClub:
      return 'Specialist Training Clubs';
    case EquipmentCategory.launchMonitor:
      return 'Launch Monitors';
    case EquipmentCategory.puttingGate:
      return 'Putting Gates';
    case EquipmentCategory.alignmentAid:
      return 'Alignment Aids';
    case EquipmentCategory.impactTrainer:
      return 'Impact Trainers';
    case EquipmentCategory.tempoTrainer:
      return 'Tempo Trainers';
    case EquipmentCategory.puttingStrokeTrainer:
      return 'Putting Stroke Trainers';
    case EquipmentCategory.shortGameTarget:
      return 'Short Game Targets';
  }
}
