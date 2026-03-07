// S12 §12.2–12.3 — Home Dashboard: persistent launch layer above tabs.
// Shows OverallScore, today's slot summary, and practice action buttons.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/matrix/screens/chipping_setup_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/gapping_execution_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/gapping_setup_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_execution_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/wedge_setup_screen.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/features/review/widgets/overall_score_display.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

class HomeDashboardScreen extends ConsumerWidget {
  final ValueChanged<int>? onGoToTab;

  const HomeDashboardScreen({super.key, this.onGoToTab});

  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallAsync = ref.watch(overallScoreProvider(_userId));
    final todayAsync = ref.watch(todayCalendarDayProvider(_userId));
    final activePb = ref.watch(activePracticeBlockProvider(_userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // S05 §5.1 — Overall SkillScore display.
          overallAsync.when(
            data: (overall) => overall != null
                ? OverallScoreDisplay(score: overall.overallScore)
                : const _ZeroStateScore(),
            loading: () => const _ZeroStateScore(),
            error: (_, _) => const _ZeroStateScore(),
          ),
          const SizedBox(height: SpacingTokens.lg),
          // S08 §8.13 — Today's slot summary.
          todayAsync.when(
            data: (day) {
              final slots = parseSlotsFromJson(day.slots);
              final filled = slots.where((s) => s.isFilled).length;
              final completed = slots.where((s) => s.isCompleted).length;
              final total = slots.length;
              return _SlotSummary(
                filled: filled,
                completed: completed,
                total: total,
              );
            },
            loading: () => const _SlotSummary(filled: 0, completed: 0, total: 0),
            error: (_, _) => const _SlotSummary(filled: 0, completed: 0, total: 0),
          ),
          const SizedBox(height: SpacingTokens.xxl),
          // Action zone — thumb-friendly bottom buttons.
          _ActionZone(
            userId: _userId,
            todayAsync: todayAsync,
            activePb: activePb,
          ),
        ],
      ),
    );
  }
}

/// Zero-state score display when no scoring data exists.
class _ZeroStateScore extends StatelessWidget {
  const _ZeroStateScore();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.lg,
        horizontal: SpacingTokens.md,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            'SkillScore',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: TypographyTokens.bodyWeight,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            '--',
            style: TextStyle(
              fontSize: TypographyTokens.displayXlSize,
              fontWeight: TypographyTokens.displayXlWeight,
              color: ColorTokens.textTertiary,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Complete a session to see your score',
            style: TextStyle(
              fontSize: TypographyTokens.microSize,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's slot progress summary with a progress bar.
class _SlotSummary extends StatelessWidget {
  final int filled;
  final int completed;
  final int total;

  const _SlotSummary({
    required this.filled,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = filled > 0 ? completed / filled : 0.0;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Plan',
                style: TextStyle(
                  fontSize: TypographyTokens.headerSize,
                  fontWeight: TypographyTokens.headerWeight,
                  color: ColorTokens.textPrimary,
                ),
              ),
              Text(
                '$completed / $filled drills',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusBadge),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: ColorTokens.surfaceBase,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorTokens.successDefault,
              ),
              minHeight: 6,
            ),
          ),
          if (filled == 0) ...[
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'No drills planned for today',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Action buttons for starting practice.
class _ActionZone extends ConsumerWidget {
  final String userId;
  final AsyncValue<dynamic> todayAsync;
  final AsyncValue<dynamic> activePb;

  const _ActionZone({
    required this.userId,
    required this.todayAsync,
    required this.activePb,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActivePb = activePb.valueOrNull != null;
    final activePbData = activePb.valueOrNull;
    final activeMatrixRun =
        ref.watch(activeMatrixRunProvider(userId)).valueOrNull;

    // Parse filled drill IDs from today's calendar.
    List<String> filledDrillIds = [];
    todayAsync.whenData((day) {
      final slots = parseSlotsFromJson(day.slots);
      filledDrillIds = slots
          .where((s) => s.isFilled && !s.isCompleted)
          .map((s) => s.drillId!)
          .toList();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resume active practice block.
        if (hasActivePb && activePbData != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PracticeQueueScreen(
                  practiceBlockId: activePbData.practiceBlockId,
                  userId: userId,
                ),
              ));
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text(
              'Resume Practice',
              style: TextStyle(color: Colors.white),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.successDefault,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
            ),
          ),
        // Resume active matrix run.
        if (activeMatrixRun != null && !hasActivePb) ...[
          FilledButton.icon(
            onPressed: () {
              // Route to appropriate execution screen.
              final Widget screen =
                  activeMatrixRun.matrixType == MatrixType.gappingChart
                      ? GappingExecutionScreen(
                          matrixRunId: activeMatrixRun.matrixRunId,
                          userId: userId,
                        )
                      : MatrixExecutionScreen(
                          matrixRunId: activeMatrixRun.matrixRunId,
                          userId: userId,
                        );
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => screen));
            },
            icon: const Icon(Icons.grid_on, color: Colors.white),
            label: Text(
              'Resume ${_matrixTypeLabel(activeMatrixRun.matrixType)}',
              style: const TextStyle(color: Colors.white),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
        ],
        // "Start Today's Practice" — visible when filled incomplete slots exist and no active PB.
        if (!hasActivePb && filledDrillIds.isNotEmpty) ...[
          FilledButton.icon(
            onPressed: () => _startTodayPractice(context, ref, filledDrillIds),
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: Text(
              'Start Today\'s Practice (${filledDrillIds.length} drills)',
              style: const TextStyle(color: Colors.white),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.successDefault,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
        ],
        // "Start Clean Practice" — always visible when no active PB.
        if (!hasActivePb)
          OutlinedButton.icon(
            onPressed: () => _startCleanPractice(context, ref),
            icon: Icon(Icons.sports_golf, color: ColorTokens.primaryDefault),
            label: Text(
              'Start Clean Practice',
              style: TextStyle(color: ColorTokens.primaryDefault),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorTokens.primaryDefault),
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
            ),
          ),
        // Matrix — Start matrix buttons (gapping, wedge, chipping).
        if (!hasActivePb && activeMatrixRun == null) ...[
          const SizedBox(height: SpacingTokens.md),
          const Text(
            'Distance Calibration',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GappingSetupScreen(userId: userId),
              ));
            },
            icon: Icon(Icons.grid_on, color: ColorTokens.primaryDefault),
            label: Text(
              'Gapping Chart',
              style: TextStyle(color: ColorTokens.primaryDefault),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorTokens.primaryDefault),
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WedgeSetupScreen(userId: userId),
              ));
            },
            icon: Icon(Icons.grid_view, color: ColorTokens.primaryDefault),
            label: Text(
              'Wedge Matrix',
              style: TextStyle(color: ColorTokens.primaryDefault),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorTokens.primaryDefault),
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChippingSetupScreen(userId: userId),
              ));
            },
            icon: Icon(Icons.grid_3x3, color: ColorTokens.primaryDefault),
            label: Text(
              'Chipping Matrix',
              style: TextStyle(color: ColorTokens.primaryDefault),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: ColorTokens.primaryDefault),
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            ),
          ),
        ],
      ],
    );
  }

  static String _matrixTypeLabel(MatrixType type) {
    switch (type) {
      case MatrixType.gappingChart:
        return 'Gapping Chart';
      case MatrixType.wedgeMatrix:
        return 'Wedge Matrix';
      case MatrixType.chippingMatrix:
        return 'Chipping Matrix';
    }
  }

  Future<void> _startTodayPractice(
    BuildContext context,
    WidgetRef ref,
    List<String> drillIds,
  ) async {
    final surface = await showSurfacePicker(context);
    if (surface == null || !context.mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(
      userId,
      initialDrillIds: drillIds,
      surfaceType: surface,
    );

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }

  Future<void> _startCleanPractice(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final surface = await showSurfacePicker(context);
    if (surface == null || !context.mounted) return;

    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(userId, surfaceType: surface);

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }
}
