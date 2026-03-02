import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/review/screens/plan_adherence_screen.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S05 §5.3 — Plan adherence headline badge on Dashboard.
// Shows adherence % for the last 4 weeks by default.

class PlanAdherenceBadge extends ConsumerWidget {
  final String userId;

  const PlanAdherenceBadge({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));
    final adherenceAsync = ref.watch(planAdherenceProvider(
      (userId: userId, start: fourWeeksAgo, end: now),
    ));

    return adherenceAsync.when(
      data: (adherence) {
        if (adherence.totalPlanned == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PlanAdherenceScreen(userId: userId),
            ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.sm),
            decoration: BoxDecoration(
              color: ColorTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              border: Border.all(color: ColorTokens.surfaceBorder),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.checklist_rounded,
                  color: ColorTokens.primaryDefault,
                  size: 20,
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: Text(
                    'Plan Adherence (4 weeks)',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${adherence.percentage.round()}%',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
