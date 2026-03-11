import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/review/screens/subskill_detail_screen.dart';
import 'package:zx_golf_app/features/review/screens/weakness_ranking_screen.dart';
import 'package:zx_golf_app/features/review/widgets/overall_score_display.dart';
import 'package:zx_golf_app/features/review/widgets/plan_adherence_badge.dart';
import 'package:zx_golf_app/features/review/widgets/skill_area_heatmap.dart';
import 'package:zx_golf_app/features/review/widgets/trend_snapshot.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S12 §12.6.1 — Dashboard screen: Overall Score + Heatmap + Trend + CTA.
// S15 §15.2 — Neutral score presentation.

class ReviewDashboardScreen extends ConsumerStatefulWidget {
  const ReviewDashboardScreen({super.key});

  @override
  ConsumerState<ReviewDashboardScreen> createState() =>
      _ReviewDashboardScreenState();
}

class _ReviewDashboardScreenState
    extends ConsumerState<ReviewDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  SkillArea? _expandedSkillArea;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final overallAsync = ref.watch(overallWindowScoreProvider(kDevUserId));

    return overallAsync.when(
      data: (overallScore) {
        if (overallScore == 0.0) return _buildZeroState();
        return _buildDashboard(overallScore);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Error loading scores',
          style: TextStyle(color: ColorTokens.errorDestructive),
        ),
      ),
    );
  }

  Widget _buildDashboard(double overallScore) {
    // TD-07 §13.5 — Dim scores when rebuild is needed.
    final isStale = ref.watch(rebuildNeededProvider).valueOrNull ?? false;
    final profileComplete =
        ref.watch(profileCompletenessProvider(kDevUserId)).valueOrNull ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      children: [
        // 1. Overall Score + Skill Areas — single section.
        Opacity(
          opacity: isStale ? 0.5 : 1.0,
          child: OverallScoreDisplay(
            score: overallScore,
            profileComplete: profileComplete,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        SkillAreaHeatmap(
          userId: kDevUserId,
          onExpandedChanged: (area) {
            setState(() => _expandedSkillArea = area);
          },
          onSubskillTap: (subskillId) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SubskillDetailScreen(
                userId: kDevUserId,
                subskillId: subskillId,
              ),
            ));
          },
        ),
        const SizedBox(height: SpacingTokens.md),

        // 3. Plan Adherence badge.
        PlanAdherenceBadge(userId: kDevUserId),
        const SizedBox(height: SpacingTokens.md),

        // 4. Trend Snapshot.
        TrendSnapshot(
          userId: kDevUserId,
          skillArea: _expandedSkillArea,
        ),
        const SizedBox(height: SpacingTokens.lg),

        // 5. CTA: Weakness Ranking.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    const WeaknessRankingScreen(userId: kDevUserId),
              ));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorTokens.primaryDefault,
              side: const BorderSide(color: ColorTokens.primaryDefault),
              padding: const EdgeInsets.symmetric(
                vertical: SpacingTokens.sm + 2,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_down),
                SizedBox(width: SpacingTokens.sm),
                Text('View Weakness Ranking'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZeroState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: ColorTokens.textTertiary,
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'No scores yet',
              style: TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                fontWeight: TypographyTokens.displayLgWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'Complete practice sessions to see your SkillScore '
              'and skill area breakdown here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
