// Phase 4 — Post-Session Summary Screen.
// S13 §13.13 — Summary after session close: score, delta, integrity.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/core/widgets/zx_badge.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/widgets/anchor_score_bar.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

const _goldStar = Color(0xFFFFD700);

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
    final isCustom = drill.origin == DrillOrigin.userCustom;
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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session Complete',
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: ColorTokens.textSecondary,
                    onPressed: () => _navigateHome(context, ref),
                  ),
                ],
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
                        color: _goldStar,
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
                          fontSize: TypographyTokens.microSize,
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
    // Check if there's a next pending drill.
    final hasNextDrill = practiceBlockId != null;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        children: [
          // Practice Overview button.
          Expanded(
            child: OutlinedButton(
              onPressed: () => _navigateToPracticeOverview(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.primaryDefault,
                side: const BorderSide(color: ColorTokens.primaryDefault),
                padding: const EdgeInsets.symmetric(
                  vertical: SpacingTokens.sm + 4,
                ),
              ),
              child: const Text('Practice Overview'),
            ),
          ),
          if (hasNextDrill) ...[
            const SizedBox(width: SpacingTokens.sm),
            // Next Drill button.
            Expanded(
              child: _NextDrillButton(
                practiceBlockId: practiceBlockId!,
                userId: userId!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateHome(BuildContext context, WidgetRef ref) {
    ref.read(showHomeProvider.notifier).state = true;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _navigateToPracticeOverview(BuildContext context) {
    // Pop back to the practice queue screen.
    Navigator.of(context).pop();
  }

  static String _drillTypeLabel(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => 'Technique',
      DrillType.transition => 'Transition',
      DrillType.pressure => 'Pressure',
    };
  }

  static Color _drillTypeColor(DrillType type) {
    return switch (type) {
      DrillType.techniqueBlock => ColorTokens.textTertiary,
      DrillType.transition => ColorTokens.primaryDefault,
      DrillType.pressure => ColorTokens.warningIntegrity,
    };
  }
}

/// Button that checks for next pending drill and navigates to it.
class _NextDrillButton extends ConsumerWidget {
  final String practiceBlockId;
  final String userId;

  const _NextDrillButton({
    required this.practiceBlockId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbAsync =
        ref.watch(practiceBlockWithEntriesProvider(practiceBlockId));

    return pbAsync.when(
      data: (pbWithEntries) {
        if (pbWithEntries == null) {
          return const SizedBox.shrink();
        }

        final nextPending = pbWithEntries.entries
            .where(
                (e) => e.entry.entryType == PracticeEntryType.pendingDrill)
            .toList();

        if (nextPending.isEmpty) {
          return const SizedBox.shrink();
        }

        return FilledButton(
          onPressed: () {
            // Pop back to queue — user can start from there.
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(
            backgroundColor: ColorTokens.primaryDefault,
            padding: const EdgeInsets.symmetric(
              vertical: SpacingTokens.sm + 4,
            ),
          ),
          child: const Text('Next Drill'),
        );
      },
      loading: () => FilledButton(
        onPressed: null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.sm + 4,
          ),
        ),
        child: const Text('Next Drill'),
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
