import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

// S05 §5.1, S12 §12.6.1 — Weakness Ranking Screen.
// Ranked subskills by WeaknessIndex. Informational only.

class WeaknessRankingScreen extends ConsumerWidget {
  final String userId;

  const WeaknessRankingScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(weaknessRankingProvider(userId));
    final refsAsync = ref.watch(allSubskillRefsProvider);
    final windowsAsync = ref.watch(windowStatesProvider(userId));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Weakness Ranking'),
      body: rankingAsync.when(
        data: (ranking) {
          if (ranking.isEmpty) {
            return const EmptyState(
                message: 'No subskill data available');
          }

          final nameMap = refsAsync.whenOrNull(
            data: (refs) => {for (final r in refs) r.subskillId: r.name},
          ) ?? <String, String>{};

          final windowSizeMap = refsAsync.whenOrNull(
            data: (refs) => {for (final r in refs) r.subskillId: r.windowSize},
          ) ?? <String, int>{};

          // Build saturation lookup from window states.
          final windowStates = windowsAsync.valueOrNull ?? [];
          final saturationMap =
              _buildSaturationMap(windowStates);

          return ListView.builder(
            padding: const EdgeInsets.all(SpacingTokens.md),
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final r = ranking[index];
              final name = nameMap[r.subskillId] ?? r.subskillId;
              final saturation = saturationMap[r.subskillId];

              return Container(
                margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
                padding: const EdgeInsets.all(SpacingTokens.sm),
                decoration: BoxDecoration(
                  color: ColorTokens.surfaceRaised,
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                  border: Border.all(color: ColorTokens.surfaceBorder),
                ),
                child: Row(
                  children: [
                    // Rank position.
                    SizedBox(
                      width: 32,
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          fontWeight: TypographyTokens.headerWeight,
                          color: r.isIncomplete
                              ? ColorTokens.warningIntegrity
                              : ColorTokens.textSecondary,
                          fontFeatures: const [
                            FontFeature.tabularFigures()
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    // Name + skill area badge.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: TypographyTokens.bodySize,
                              fontWeight: TypographyTokens.bodyWeight,
                              color: ColorTokens.textPrimary,
                            ),
                          ),
                          const SizedBox(height: SpacingTokens.xs),
                          Row(
                            children: [
                              _SkillAreaBadge(skillArea: r.skillArea),
                              const SizedBox(width: SpacingTokens.sm),
                              if (saturation != null)
                                Text(
                                  'T:${saturation.transitionOccupancy.toStringAsFixed(0)}/${windowSizeMap[r.subskillId] ?? 25} '
                                  'P:${saturation.pressureOccupancy.toStringAsFixed(0)}/${windowSizeMap[r.subskillId] ?? 25}',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.microSize,
                                    color: ColorTokens.textTertiary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Score + WI column.
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          r.isIncomplete
                              ? '--'
                              : r.weightedAverage.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: TypographyTokens.headerSize,
                            fontWeight: TypographyTokens.headerWeight,
                            color: ColorTokens.textPrimary,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const SizedBox(height: SpacingTokens.xs),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'WI: ${r.weaknessIndex.toStringAsFixed(3)}',
                              style: TextStyle(
                                fontSize: TypographyTokens.microSize,
                                color: ColorTokens.textTertiary,
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SpacingTokens.xs + 2,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorTokens.surfaceModal,
                                borderRadius: BorderRadius.circular(
                                    ShapeTokens.radiusGrid),
                              ),
                              child: Text(
                                '${r.allocation}/$kTotalAllocation',
                                style: TextStyle(
                                  fontSize: TypographyTokens.microSize,
                                  color: ColorTokens.textTertiary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading rankings',
            style: TextStyle(color: ColorTokens.errorDestructive),
          ),
        ),
      ),
    );
  }

  Map<String, _SubskillSaturation> _buildSaturationMap(
    List<MaterialisedWindowState> windows,
  ) {
    final map = <String, _SubskillSaturation>{};
    for (final w in windows) {
      final existing =
          map[w.subskill] ?? _SubskillSaturation();
      if (w.practiceType == DrillType.transition) {
        map[w.subskill] = existing.copyWith(
            transitionOccupancy: w.totalOccupancy);
      } else if (w.practiceType == DrillType.pressure) {
        map[w.subskill] = existing.copyWith(
            pressureOccupancy: w.totalOccupancy);
      }
    }
    return map;
  }
}

class _SubskillSaturation {
  final double transitionOccupancy;
  final double pressureOccupancy;

  const _SubskillSaturation({
    this.transitionOccupancy = 0,
    this.pressureOccupancy = 0,
  });

  _SubskillSaturation copyWith({
    double? transitionOccupancy,
    double? pressureOccupancy,
  }) => _SubskillSaturation(
    transitionOccupancy: transitionOccupancy ?? this.transitionOccupancy,
    pressureOccupancy: pressureOccupancy ?? this.pressureOccupancy,
  );
}

class _SkillAreaBadge extends StatelessWidget {
  final SkillArea skillArea;

  const _SkillAreaBadge({required this.skillArea});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.primaryDefault.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
      ),
      child: Text(
        skillArea.dbValue,
        style: TextStyle(
          fontSize: TypographyTokens.microSize,
          color: ColorTokens.primaryDefault,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
