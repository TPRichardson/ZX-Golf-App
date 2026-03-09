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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
          children: [
            // Column headers aligned to bar positions.
            Padding(
              padding: const EdgeInsets.only(
                left: SpacingTokens.sm,
                right: SpacingTokens.sm,
                top: SpacingTokens.xs,
                bottom: 0,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 150 + SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'SkillScore',
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        fontWeight: FontWeight.w900,
                        color: ColorTokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: Text(
                      'SkillProfile',
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        fontWeight: FontWeight.w900,
                        color: ColorTokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm + 14),
                ],
              ),
            ),
            ...areaRefs.map((subRef) {
            final s = stats[subRef.subskillId];
            final totalPoints = s?.totalPoints ?? 0.0;
            final average = s?.average ?? 0.0;
            final totalOccupancy = s?.totalOccupancy ?? 0.0;
            final normalised =
                average > 0 ? (average / 5.0).clamp(0.0, 1.0) : 0.0;

            return _SubskillTile(
              name: subRef.name,
              earnedPoints: totalPoints.round(),
              allocation: subRef.allocation,
              average: average,
              normalisedScore: normalised,
              totalOccupancy: totalOccupancy,
              windowCapacity: subRef.windowSize * 2.0,
              onTap: () => onSubskillTap(subRef.subskillId),
            );
          }),
        ]));
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
  final double totalOccupancy;
  final double windowCapacity;
  final VoidCallback onTap;

  const _SubskillTile({
    required this.name,
    required this.earnedPoints,
    required this.allocation,
    required this.average,
    required this.normalisedScore,
    required this.totalOccupancy,
    required this.windowCapacity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // RAG pill colour.
    final Color pillColor;
    if (normalisedScore == 0.0) {
      pillColor = ColorTokens.textTertiary.withValues(alpha: 0.3);
    } else if (normalisedScore <= 0.6) {
      pillColor = Color.lerp(
        const Color(0xFFE05252),
        const Color(0xFFE8A830),
        (normalisedScore / 0.6).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.6);
    } else {
      pillColor = Color.lerp(
        const Color(0xFFE8A830),
        const Color(0xFF22C55E),
        ((normalisedScore - 0.6) / 0.4).clamp(0.0, 1.0),
      )!.withValues(alpha: 0.6);
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm,
          vertical: 3,
        ),
        child: Row(
          children: [
            // RAG pill behind subskill name — fixed width for bar alignment.
            SizedBox(
              width: 150,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: TypographyTokens.bodyWeight,
                    color: ColorTokens.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(child: _WindowFillBar(
              occupancy: earnedPoints.toDouble(),
              capacity: allocation.toDouble(),
            )),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              allocation.toString(),
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                fontWeight: FontWeight.w900,
                color: ColorTokens.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(child: _WindowFillBar(
              occupancy: totalOccupancy,
              capacity: windowCapacity,
              rag: false,
            )),
            const SizedBox(width: SpacingTokens.xs),
            Text(
              windowCapacity.toInt().toString(),
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                fontWeight: FontWeight.w900,
                color: ColorTokens.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
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

/// Linear progress bar. RAG mode: red→green. Profile mode: grey→cyan.
class _WindowFillBar extends StatelessWidget {
  final double occupancy;
  final double capacity;
  final bool rag;

  const _WindowFillBar({
    required this.occupancy,
    required this.capacity,
    this.rag = true,
  });

  @override
  Widget build(BuildContext context) {
    final fill = capacity > 0 ? (occupancy / capacity).clamp(0.0, 1.0) : 0.0;

    final Color barColor;
    if (occupancy == 0) {
      barColor = ColorTokens.textTertiary.withValues(alpha: 0.3);
    } else if (rag) {
      barColor = Color.lerp(
        const Color(0xFFE05252),
        const Color(0xFF22C55E),
        fill,
      )!;
    } else {
      barColor = Color.lerp(
        ColorTokens.textTertiary,
        ColorTokens.primaryDefault,
        fill,
      )!;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: fill,
        backgroundColor: ColorTokens.textTertiary.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
        minHeight: 6,
      ),
    );
  }
}
