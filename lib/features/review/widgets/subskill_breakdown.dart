import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S05 §5.1 — Subskill breakdown within a SkillArea accordion.
// Shows weighted average, transition/pressure split, allocation.
// Tap subskill → navigate to subskill detail screen.

class SubskillBreakdown extends ConsumerWidget {
  final String userId;
  final SkillArea skillArea;
  final void Function(String subskillId) onSubskillTap;

  const SubskillBreakdown({
    super.key,
    required this.userId,
    required this.skillArea,
    required this.onSubskillTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoresAsync = ref.watch(subskillsByAreaProvider(
      (userId: userId, skillArea: skillArea),
    ));
    final refsAsync = ref.watch(allSubskillRefsProvider);

    return scoresAsync.when(
      data: (scores) {
        if (scores.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Text(
              'No data yet',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          );
        }

        // Build name lookup from refs.
        final nameMap = refsAsync.whenOrNull(
          data: (refs) => {for (final r in refs) r.subskillId: r.name},
        ) ?? <String, String>{};

        return Column(
          children: scores.map((score) {
            return _SubskillRow(
              subskillId: score.subskill,
              name: nameMap[score.subskill] ?? score.subskill,
              weightedAverage: score.weightedAverage,
              transitionAverage: score.transitionAverage,
              pressureAverage: score.pressureAverage,
              allocation: score.allocation,
              onTap: () => onSubskillTap(score.subskill),
            );
          }).toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(SpacingTokens.md),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Text(
          'Error loading subskills',
          style: TextStyle(color: ColorTokens.errorDestructive),
        ),
      ),
    );
  }
}

class _SubskillRow extends StatelessWidget {
  final String subskillId;
  final String name;
  final double weightedAverage;
  final double transitionAverage;
  final double pressureAverage;
  final int allocation;
  final VoidCallback onTap;

  const _SubskillRow({
    required this.subskillId,
    required this.name,
    required this.weightedAverage,
    required this.transitionAverage,
    required this.pressureAverage,
    required this.allocation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm,
        ),
        child: Row(
          children: [
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
                  Text(
                    'T: ${transitionAverage.toStringAsFixed(2)}  '
                    'P: ${pressureAverage.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            // Weighted average.
            Text(
              weightedAverage.toStringAsFixed(2),
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            // Allocation badge.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm,
                vertical: SpacingTokens.xs,
              ),
              decoration: BoxDecoration(
                color: ColorTokens.surfaceModal,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
              ),
              child: Text(
                '$allocation/$kTotalAllocation',
                style: TextStyle(
                  fontSize: TypographyTokens.microSize,
                  color: ColorTokens.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: ColorTokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
