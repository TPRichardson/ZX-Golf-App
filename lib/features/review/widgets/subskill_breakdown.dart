import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S05 §5.1 — Subskill breakdown within a SkillArea accordion.
// Shows earned points / allocation + average with RAG colouring,
// matching the skill area tile visual language.
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
    final refsAsync = ref.watch(allSubskillRefsProvider);
    final subskillStatsAsync =
        ref.watch(subskillWindowStatsProvider(userId));

    return refsAsync.when(
      data: (allRefs) {
        // Always show all subskills for this area from reference data.
        final areaRefs =
            allRefs.where((r) => r.skillArea == skillArea).toList();
        if (areaRefs.isEmpty) return const SizedBox.shrink();

        final stats = subskillStatsAsync.valueOrNull ?? {};

        return Column(
          children: areaRefs.map((subRef) {
            final s = stats[subRef.subskillId];
            final totalPoints = s?.totalPoints ?? 0.0;
            final average = s?.average ?? 0.0;
            final normalised =
                average > 0 ? (average / 5.0).clamp(0.0, 1.0) : 0.0;

            return _SubskillTile(
              name: subRef.name,
              earnedPoints: totalPoints.round(),
              allocation: subRef.allocation,
              average: average,
              normalisedScore: normalised,
              onTap: () => onSubskillTap(subRef.subskillId),
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

class _SubskillTile extends StatelessWidget {
  final String name;
  final int earnedPoints;
  final int allocation;
  final double average;
  final double normalisedScore;
  final VoidCallback onTap;

  const _SubskillTile({
    required this.name,
    required this.earnedPoints,
    required this.allocation,
    required this.average,
    required this.normalisedScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Same RAG colour logic as SkillAreaTile.
    final Color tileColor;
    if (normalisedScore == 0.0) {
      tileColor = ColorTokens.surfaceRaised;
    } else if (normalisedScore <= 0.6) {
      tileColor = Color.lerp(
        const Color(0xFFD64545),
        const Color(0xFFF5A623),
        (normalisedScore / 0.6).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.25);
    } else {
      tileColor = Color.lerp(
        const Color(0xFFF5A623),
        const Color(0xFF1FA463),
        ((normalisedScore - 0.6) / 0.4).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.25);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: SpacingTokens.sm - 2,
        ),
        decoration: BoxDecoration(
          color: tileColor,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  fontWeight: TypographyTokens.bodyWeight,
                  color: ColorTokens.textPrimary,
                ),
              ),
            ),
            Text(
              '$earnedPoints / $allocation pts',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text(
              'avg ${average.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: SpacingTokens.xs),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: ColorTokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
