import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/features/review/screens/subskill_detail_screen.dart';
import 'package:zx_golf_app/features/review/widgets/overall_score_display.dart';
import 'package:zx_golf_app/features/review/widgets/plan_adherence_badge.dart';
import 'package:zx_golf_app/features/review/widgets/skill_area_heatmap.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// Home screen: Overall Score + Heatmap + Begin Practice.

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

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final userId = ref.watch(currentUserIdProvider);
    final overallAsync = ref.watch(overallWindowScoreProvider(userId));

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
    final userId = ref.watch(currentUserIdProvider);
    // TD-07 §13.5 — Dim scores when rebuild is needed.
    final isStale = ref.watch(rebuildNeededProvider).valueOrNull ?? false;
    final profileComplete =
        ref.watch(profileCompletenessProvider(userId)).valueOrNull ?? 0.0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              Opacity(
                opacity: isStale ? 0.5 : 1.0,
                child: OverallScoreDisplay(
                  score: overallScore,
                  profileComplete: profileComplete,
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
              SkillAreaHeatmap(
                userId: userId,
                onExpandedChanged: (_) {},
                onSubskillTap: (subskillId) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SubskillDetailScreen(
                      userId: userId,
                      subskillId: subskillId,
                    ),
                  ));
                },
              ),
              const SizedBox(height: SpacingTokens.md),
              PlanAdherenceBadge(userId: userId),
            ],
          ),
        ),
        _buildBeginPractice(),
      ],
    );
  }

  Widget _buildZeroState() {
    return Column(
      children: [
        Expanded(
          child: Center(
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
          ),
        ),
        _buildBeginPractice(),
      ],
    );
  }

  Widget _buildBeginPractice() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.md, 0, SpacingTokens.md, SpacingTokens.md,
        ),
        child: ZxPillButton(
          label: 'Begin Practice',
          icon: Icons.play_circle_filled,
          size: ZxPillSize.md,
          variant: ZxPillVariant.progress,
          expanded: true,
          centered: true,
          onTap: _startPractice,
        ),
      ),
    );
  }

  Future<void> _startPractice() async {
    final userId = ref.read(currentUserIdProvider);
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(
      userId,
      environmentType: envSurface.environment,
      surfaceType: envSurface.surface,
    );

    if (mounted) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }
}
