// Phase 4 — Post-Session Summary Screen.
// S13 §13.13 — Summary after session close: score, delta, integrity.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/core/widgets/zx_badge.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/screens/practice_summary_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/anchor_score_bar.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';


/// S13 §13.13 — Post-session summary showing score and performance data.
class PostSessionSummaryScreen extends ConsumerWidget {
  final Drill drill;
  final Session session;
  final double? sessionScore;
  final bool integrityBreach;
  final String? practiceBlockId;
  final String? userId;

  const PostSessionSummaryScreen({
    super.key,
    required this.drill,
    required this.session,
    this.sessionScore,
    this.integrityBreach = false,
    this.practiceBlockId,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustom = drill.origin == DrillOrigin.custom;
    final score = isCustom ? null : sessionScore;

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: const BoxDecoration(
                color: ColorTokens.surfaceRaised,
                border: Border(
                  bottom: BorderSide(color: ColorTokens.surfaceBorder),
                ),
              ),
              child: Center(
                child: Text(
                  'Session Complete',
                  style: TextStyle(
                    fontSize: TypographyTokens.displayLgSize,
                    fontWeight: TypographyTokens.displayLgWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  children: [
                    const SizedBox(height: SpacingTokens.xl),
                    // Drill name.
                    Text(
                      drill.name,
                      style: TextStyle(
                        fontSize: TypographyTokens.displayLgSize,
                        fontWeight: TypographyTokens.displayLgWeight,
                        color: ColorTokens.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    // Skill area + drill type pills.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ZxBadge(
                          label: drill.skillArea.dbValue,
                          color: ColorTokens.skillArea(drill.skillArea),
                        ),
                        const SizedBox(width: SpacingTokens.xs),
                        ZxBadge(
                          label: _drillTypeLabel(drill.drillType),
                          color: _drillTypeColor(drill.drillType),
                        ),
                      ],
                    ),
                    const SizedBox(height: SpacingTokens.xxl),
                    // Score display — system drills show stars,
                    // custom drills show raw metrics.
                    if (score != null) ...[
                      StarRating(
                        stars: scoreToStars(score),
                        size: 48,
                        color: ColorTokens.achievementGold,
                      ),
                      // Anchor bar — Min/Scratch/Pro with user hit rate.
                      _HitRateAnchorBar(
                        sessionId: session.sessionId,
                        drill: drill,
                        ref: ref,
                      ),
                    ] else if (isCustom)
                      _CustomDrillMetrics(
                        sessionId: session.sessionId,
                        drill: drill,
                        ref: ref,
                      )
                    else
                      Text(
                        'No Score',
                        style: TextStyle(
                          fontSize: TypographyTokens.displayLgSize,
                          fontWeight: TypographyTokens.displayLgWeight,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    // Scoring game scorecard.
                    if (drill.inputMode == InputMode.scoringGame)
                      _ScoringGameScorecard(
                        sessionId: session.sessionId,
                        ref: ref,
                      ),
                    const SizedBox(height: SpacingTokens.lg),
                    // Duration.
                    if (session.sessionDuration != null)
                      Text(
                        'Drill completed in ${formatDuration(session.sessionDuration!)}',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textSecondary,
                        ),
                      ),
                    const SizedBox(height: SpacingTokens.xl),
                    // Integrity flag warning.
                    // Debug: raw score.
                    if (sessionScore != null)
                      Text(
                        'Raw score: ${sessionScore!.toStringAsFixed(2)} / 5',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    const SizedBox(height: SpacingTokens.md),
                    if (integrityBreach)
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.md),
                        decoration: BoxDecoration(
                          color: ColorTokens.warningIntegrity
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(ShapeTokens.radiusCard),
                          border: Border.all(
                            color: ColorTokens.warningIntegrity
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: ColorTokens.warningIntegrity,
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                'Integrity flag: some values were outside expected bounds.',
                                style: TextStyle(
                                  fontSize: TypographyTokens.bodySize,
                                  color: ColorTokens.warningIntegrity,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Bottom buttons.
            _buildBottomButtons(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, WidgetRef ref) {
    final hasNextDrill = practiceBlockId != null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasNextDrill) ...[
            _NextDrillButton(
              practiceBlockId: practiceBlockId!,
              userId: userId!,
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],
          Row(
            children: [
              Expanded(
                child: ZxPillButton(
                  label: 'Discard',
                  icon: Icons.delete_outline,
                  variant: ZxPillVariant.destructive,
                  expanded: true,
                  centered: true,
                  onTap: () => _discardSession(context, ref),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: ZxPillButton(
                  label: 'Back to Practice',
                  icon: Icons.list_alt,
                  variant: ZxPillVariant.secondary,
                  expanded: true,
                  centered: true,
                  onTap: () => _navigateToPracticeOverview(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToPracticeOverview(BuildContext context) {
    // Pop back to the practice queue screen.
    Navigator.of(context).pop();
  }

  Future<void> _discardSession(BuildContext context, WidgetRef ref) async {
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Discard Session?',
      message: 'This will discard "${drill.name}" and remove it from this practice block.',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      final repo = ref.read(practiceRepositoryProvider);
      final entry = await repo.getPracticeEntryBySessionId(session.sessionId);
      if (entry != null) {
        await repo.removeCompletedEntry(entry.practiceEntryId, userId ?? '');
      }
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  static String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
      DrillType.benchmark => 'Benchmark',
    };
  }

  static Color _drillTypeColor(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => ColorTokens.textTertiary,
      DrillType.transition => ColorTokens.primaryDefault,
      DrillType.pressure => ColorTokens.warningIntegrity,
      DrillType.benchmark => ColorTokens.successDefault,
    };
  }
}

/// Button that shows "Next Drill" or "Finish Practice" based on pending drills.
/// Starts the next drill directly instead of navigating back to the queue.
class _NextDrillButton extends ConsumerStatefulWidget {
  final String practiceBlockId;
  final String userId;

  const _NextDrillButton({
    required this.practiceBlockId,
    required this.userId,
  });

  @override
  ConsumerState<_NextDrillButton> createState() => _NextDrillButtonState();
}

class _NextDrillButtonState extends ConsumerState<_NextDrillButton> {
  bool _loading = false;

  Future<void> _startNextDrill(PracticeEntryWithDrill ewd) async {
    if (_loading) return;
    setState(() => _loading = true);

    final drill = ewd.drill;

    // Check club availability.
    if (drill.clubSelectionMode != null) {
      final clubs = await ref
          .read(clubsForSkillAreaProvider((widget.userId, drill.skillArea))
              .future);
      if (clubs.isEmpty && mounted) {
        setState(() => _loading = false);
        return;
      }
    }

    final actions = ref.read(practiceActionsProvider);
    final session = await actions.startSession(
      ewd.entry.practiceEntryId,
      widget.userId,
    );

    if (!mounted) return;

    final screen = PracticeRouter.routeToExecutionScreen(
      drill: drill,
      session: session,
      userId: widget.userId,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pbAsync =
        ref.watch(practiceBlockWithEntriesProvider(widget.practiceBlockId));

    return pbAsync.when(
      data: (pbWithEntries) {
        if (pbWithEntries == null) return const SizedBox.shrink();

        final nextPending = pbWithEntries.entries
            .where(
                (e) => e.entry.entryType == PracticeEntryType.pendingDrill)
            .toList();

        if (nextPending.isEmpty) {
          return ZxPillButton(
            label: 'Finish Practice',
            icon: Icons.check_circle_outline,
            variant: ZxPillVariant.progress,
            expanded: true,
            centered: true,
            onTap: () async {
              final startTimestamp = pbWithEntries.practiceBlock.startTimestamp;
              final actions = ref.read(practiceActionsProvider);
              await actions.endPracticeBlock(
                  widget.practiceBlockId, widget.userId);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => PracticeSummaryScreen(
                      practiceBlockId: widget.practiceBlockId,
                      startTimestamp: startTimestamp,
                    ),
                  ),
                  (route) => route.isFirst,
                );
              }
            },
          );
        }

        return ZxPillButton(
          label: 'Next Drill: ${nextPending.first.drill.name}',
          icon: Icons.play_arrow,
          variant: ZxPillVariant.primary,
          expanded: true,
          centered: true,
          isLoading: _loading,
          onTap: () => _startNextDrill(nextPending.first),
        );
      },
      loading: () => ZxPillButton(
        label: 'Next Drill',
        icon: Icons.play_arrow,
        variant: ZxPillVariant.primary,
        expanded: true,
        centered: true,
        isLoading: true,
        onTap: null,
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Raw metric summary for custom drills (no /5 score).
class _CustomDrillMetrics extends StatelessWidget {
  final String sessionId;
  final Drill drill;
  final WidgetRef ref;

  const _CustomDrillMetrics({
    required this.sessionId,
    required this.drill,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Instance>>(
      future: ref
          .read(scoringRepositoryProvider)
          .getInstancesForSession(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            'Custom Drill',
            style: TextStyle(
              fontSize: TypographyTokens.displayLgSize,
              fontWeight: TypographyTokens.displayLgWeight,
              color: ColorTokens.textTertiary,
            ),
          );
        }

        final instances = snapshot.data!;
        final metrics = _computeMetrics(instances);

        return Column(
          children: [
            Text(
              'Custom Drill',
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: ColorTokens.textTertiary,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            for (final entry in metrics.entries)
              _DetailRow(label: entry.key, value: entry.value),
            if (drill.target != null) ...[
              const SizedBox(height: SpacingTokens.sm),
              _DetailRow(
                label: 'Target',
                value: drill.target!.toStringAsFixed(1),
              ),
            ],
          ],
        );
      },
    );
  }

  Map<String, String> _computeMetrics(List<Instance> instances) {
    final metrics = <String, String>{};
    metrics['Attempts'] = '${instances.length}';

    int hits = 0;
    bool hasHitData = false;
    final numericValues = <double>[];

    for (final instance in instances) {
      try {
        final raw = jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
        if (raw.containsKey('hit')) {
          hasHitData = true;
          if (raw['hit'] == true) hits++;
        }
        if (raw.containsKey('value')) {
          final v = (raw['value'] as num).toDouble();
          numericValues.add(v);
        }
      } catch (_) {}
    }

    if (hasHitData) {
      final rate = (hits / instances.length * 100).toStringAsFixed(1);
      metrics['Hits'] = '$hits / ${instances.length}';
      metrics['Hit Rate'] = '$rate%';
    }

    if (numericValues.isNotEmpty) {
      final avg =
          numericValues.reduce((a, b) => a + b) / numericValues.length;
      metrics['Average'] = avg.toStringAsFixed(1);
      metrics['Best'] =
          numericValues.reduce((a, b) => a > b ? a : b).toStringAsFixed(1);
    }

    return metrics;
  }
}

/// Loads instances for the session, computes hit rate %, and shows the anchor bar.
class _HitRateAnchorBar extends StatelessWidget {
  final String sessionId;
  final Drill drill;
  final WidgetRef ref;

  const _HitRateAnchorBar({
    required this.sessionId,
    required this.drill,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Instance>>(
      future: ref.read(scoringRepositoryProvider).getInstancesForSession(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final instances = snapshot.data!;
        // Scoring game: compute negated +/- par as the anchor bar value.
        if (drill.inputMode == InputMode.scoringGame) {
          var totalStrokes = 0;
          var totalPar = 0;
          for (final instance in instances) {
            try {
              final raw = jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
              totalStrokes += (raw['strokes'] as num).toInt();
              totalPar += (raw['par'] as num?)?.toInt() ?? 2;
            } catch (_) {}
          }
          final negated = -(totalStrokes - totalPar).toDouble();
          return AnchorScoreBar(
            userValue: negated,
            anchorsJson: drill.anchors,
          );
        }

        final isValueDrill = drill.inputMode == InputMode.rawDataEntry ||
            drill.inputMode == InputMode.continuousMeasurement;

        if (isValueDrill) {
          // Value-based drill: compute best-of-set average or simple average.
          final bySet = <String, List<double>>{};
          for (final instance in instances) {
            try {
              final raw = jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
              final value = (raw['value'] as num?)?.toDouble();
              if (value != null) {
                bySet.putIfAbsent(instance.setId, () => []).add(value);
              }
            } catch (_) {}
          }
          if (bySet.isEmpty) return const SizedBox.shrink();
          // Best per set, then average.
          final bestPerSet = bySet.values
              .map((vals) => vals.reduce((a, b) => a > b ? a : b))
              .toList();
          final avg = bestPerSet.reduce((a, b) => a + b) / bestPerSet.length;
          return AnchorScoreBar(
            userValue: avg,
            anchorsJson: drill.anchors,
          );
        }

        // Hit-rate drill.
        int hits = 0;
        for (final instance in instances) {
          try {
            final raw = jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
            if (raw['hit'] == true) hits++;
          } catch (_) {}
        }
        final hitRatePct = hits / instances.length * 100.0;
        return AnchorScoreBar(
          userHitRatePct: hitRatePct,
          anchorsJson: drill.anchors,
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              fontWeight: FontWeight.w500,
              color: ColorTokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Scorecard table for scoring game sessions.
/// Shows hole-by-hole: number, distance, category, strokes, +/- par.
class _ScoringGameScorecard extends StatelessWidget {
  final String sessionId;
  final WidgetRef ref;

  const _ScoringGameScorecard({
    required this.sessionId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Instance>>(
      future: ref
          .read(scoringRepositoryProvider)
          .getInstancesForSession(sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final instances = snapshot.data!;
        final holes = <_HoleResult>[];
        var totalStrokes = 0;
        var totalPar = 0;

        for (final instance in instances) {
          try {
            final raw =
                jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
            final strokes = (raw['strokes'] as num).toInt();
            final distance = (raw['distance'] as num).toInt();
            final category = raw['category'] as String? ?? '';
            final par = (raw['par'] as num?)?.toInt() ?? 2;
            final holeNum = (raw['holeNumber'] as num?)?.toInt() ?? (holes.length + 1);
            holes.add(_HoleResult(holeNum, distance, category, strokes, par));
            totalStrokes += strokes;
            totalPar += par;
          } catch (_) {}
        }

        if (holes.isEmpty) return const SizedBox.shrink();

        final plusMinus = totalStrokes - totalPar;
        final plusMinusLabel =
            plusMinus == 0 ? 'E' : (plusMinus > 0 ? '+$plusMinus' : '$plusMinus');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SpacingTokens.lg),
            // Summary line.
            Center(
              child: Text(
                '$totalStrokes strokes ($plusMinusLabel)',
                style: TextStyle(
                  fontSize: TypographyTokens.displayLgSize,
                  fontWeight: TypographyTokens.displayLgWeight,
                  color: plusMinus < 0
                      ? ColorTokens.successDefault
                      : plusMinus == 0
                          ? ColorTokens.textPrimary
                          : ColorTokens.errorDestructive,
                ),
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
            // Scorecard table.
            Container(
              decoration: BoxDecoration(
                color: ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              ),
              child: Column(
                children: [
                  // Header row.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: SpacingTokens.sm,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('#',
                              style: TextStyle(
                                  fontSize: TypographyTokens.bodySmSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.textTertiary)),
                        ),
                        Expanded(
                          child: Text('Distance',
                              style: TextStyle(
                                  fontSize: TypographyTokens.bodySmSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.textTertiary)),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text('Strokes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: TypographyTokens.bodySmSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.textTertiary)),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text('+/-',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: TypographyTokens.bodySmSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.textTertiary)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: ColorTokens.surfaceBorder),
                  // Hole rows.
                  for (final hole in holes)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.md,
                        vertical: SpacingTokens.xs,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text('${hole.number}',
                                style: TextStyle(
                                    fontSize: TypographyTokens.bodySmSize,
                                    color: ColorTokens.textSecondary)),
                          ),
                          Expanded(
                            child: Text(
                              '${hole.distance}ft  ${hole.category}',
                              style: TextStyle(
                                fontSize: TypographyTokens.bodySmSize,
                                color: ColorTokens.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 64,
                            child: Text('${hole.strokes}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: TypographyTokens.bodySmSize,
                                    fontWeight: FontWeight.w600,
                                    color: ColorTokens.textPrimary)),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              hole.plusMinusLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: TypographyTokens.bodySmSize,
                                fontWeight: FontWeight.w600,
                                color: hole.plusMinus < 0
                                    ? ColorTokens.successDefault
                                    : hole.plusMinus == 0
                                        ? ColorTokens.textTertiary
                                        : ColorTokens.errorDestructive,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HoleResult {
  final int number;
  final int distance;
  final String category;
  final int strokes;
  final int par;

  const _HoleResult(
      this.number, this.distance, this.category, this.strokes, this.par);

  int get plusMinus => strokes - par;
  String get plusMinusLabel =>
      plusMinus == 0 ? '-' : (plusMinus > 0 ? '+$plusMinus' : '$plusMinus');
}
