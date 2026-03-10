// Practice Block Summary Screen.
// Shown after finishing a practice block — overall stats and per-session scores.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/session_scorer.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_badge.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

const _goldStar = Color(0xFFFFD700);

/// Data for one completed session in the summary.
class _SessionSummary {
  final Drill drill;
  final Session session;
  final double? score;
  final int instanceCount;
  final int setCount;

  const _SessionSummary({
    required this.drill,
    required this.session,
    this.score,
    required this.instanceCount,
    required this.setCount,
  });
}

/// Practice block summary — shown after finishing a practice block.
class PracticeSummaryScreen extends ConsumerStatefulWidget {
  final String practiceBlockId;
  final DateTime startTimestamp;

  const PracticeSummaryScreen({
    super.key,
    required this.practiceBlockId,
    required this.startTimestamp,
  });

  @override
  ConsumerState<PracticeSummaryScreen> createState() =>
      _PracticeSummaryScreenState();
}

class _PracticeSummaryScreenState extends ConsumerState<PracticeSummaryScreen> {
  List<_SessionSummary>? _sessions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final practiceRepo = ref.read(practiceRepositoryProvider);
    final scoringRepo = ref.read(scoringRepositoryProvider);

    // Get all completed sessions for this practice block.
    final pbWithEntries = await practiceRepo
        .watchPracticeBlock(widget.practiceBlockId)
        .first;
    if (pbWithEntries == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final completedEntries = pbWithEntries.entries
        .where((e) =>
            e.entry.entryType == PracticeEntryType.completedSession &&
            e.session != null)
        .toList();

    final sessions = <_SessionSummary>[];

    for (final ewd in completedEntries) {
      final session = ewd.session!;
      final drill = ewd.drill;
      final instances =
          await scoringRepo.getInstancesForSession(session.sessionId);
      final setCount = await practiceRepo.getSetCount(session.sessionId);

      // Compute score for system drills.
      double? score;
      if (drill.origin != DrillOrigin.userCustom) {
        score = _computeSessionScore(drill, instances);
      }

      sessions.add(_SessionSummary(
        drill: drill,
        session: session,
        score: score,
        instanceCount: instances.length,
        setCount: setCount,
      ));
    }

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    }
  }

  /// Recompute session score from instances and drill anchors.
  double? _computeSessionScore(Drill drill, List<Instance> instances) {
    if (instances.isEmpty) return 0.0;

    // Parse anchors.
    Map<String, dynamic> anchorsMap;
    try {
      anchorsMap = jsonDecode(drill.anchors) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    if (anchorsMap.isEmpty) return null;

    final firstAnchors = anchorsMap.values.first as Map<String, dynamic>;
    final min = (firstAnchors['Min'] as num?)?.toDouble();
    final scratch = (firstAnchors['Scratch'] as num?)?.toDouble();
    final pro = (firstAnchors['Pro'] as num?)?.toDouble();
    if (min == null || scratch == null || pro == null) return null;

    final anchors = Anchors(min: min, scratch: scratch, pro: pro);

    // Hit-rate drills (grid/binary).
    if (drill.inputMode == InputMode.gridCell ||
        drill.inputMode == InputMode.binaryHitMiss) {
      int hits = 0;
      for (final instance in instances) {
        try {
          final raw =
              jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
          if (raw['hit'] == true) hits++;
        } catch (_) {}
      }
      return scoreHitRateSession(
        HitRateSessionInput(
            totalHits: hits, totalAttempts: instances.length),
        anchors,
      );
    }

    // Raw data drills.
    if (drill.inputMode == InputMode.rawDataEntry ||
        drill.inputMode == InputMode.continuousMeasurement) {
      final inputs = <RawInstanceInput>[];
      for (final instance in instances) {
        try {
          final raw =
              jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
          if (raw.containsKey('value')) {
            inputs.add(RawInstanceInput((raw['value'] as num).toDouble()));
          }
        } catch (_) {}
      }
      if (inputs.isEmpty) return null;
      return scoreRawDataSession(inputs, anchors);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final totalDuration =
        DateTime.now().difference(widget.startTimestamp).inSeconds;

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: const ZxAppBar(title: 'Practice Complete'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(totalDuration),
    );
  }

  Widget _buildContent(int totalDuration) {
    final sessions = _sessions ?? [];
    final scoredSessions =
        sessions.where((s) => s.score != null).toList();
    final avgScore = scoredSessions.isNotEmpty
        ? scoredSessions.map((s) => s.score!).reduce((a, b) => a + b) /
            scoredSessions.length
        : 0.0;
    final totalSets = sessions.fold<int>(0, (sum, s) => sum + s.setCount);
    final totalShots =
        sessions.fold<int>(0, (sum, s) => sum + s.instanceCount);

    return Column(
      children: [
        // Static header: stars + stats.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            SpacingTokens.lg, SpacingTokens.md, SpacingTokens.lg, 0,
          ),
          child: Column(
            children: [
              if (scoredSessions.isNotEmpty) ...[
                Text(
                  'Overall Performance',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                StarRating(
                  stars: scoreToStars(avgScore),
                  size: 48,
                  color: _goldStar,
                ),
              ],
              const SizedBox(height: SpacingTokens.md),
              Row(
                children: [
                  _StatTile(
                    label: 'Duration',
                    value: formatDuration(totalDuration),
                  ),
                  _StatTile(
                    label: 'Sets',
                    value: '$totalSets',
                  ),
                  _StatTile(
                    label: 'Shots',
                    value: '$totalShots',
                  ),
                ],
              ),
              const SizedBox(height: SpacingTokens.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Completed Drills',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: SpacingTokens.sm),
            ],
          ),
        ),
        // Scrollable session list.
        Expanded(
          child: sessions.isEmpty
              ? Center(
                  child: Text(
                    'No drills completed',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    SpacingTokens.lg, 0, SpacingTokens.lg, SpacingTokens.lg,
                  ),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: SpacingTokens.sm),
                      child: _SessionCard(summary: sessions[index]),
                    );
                  },
                ),
        ),
        // Done button.
        Container(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primaryDefault,
                padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.sm + 4),
              ),
              child: const Text('Done'),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
        padding: const EdgeInsets.symmetric(
          vertical: SpacingTokens.md,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                fontWeight: TypographyTokens.displayLgWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final _SessionSummary summary;

  const _SessionCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final drill = summary.drill;
    final session = summary.session;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Row(
        children: [
          // Skill area color bar.
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: ColorTokens.skillArea(drill.skillArea),
              borderRadius: BorderRadius.circular(ShapeTokens.radiusMicro),
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Drill name + info.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  drill.name,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodyLgSize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  '${summary.setCount} sets · ${summary.instanceCount} shots'
                  '${session.sessionDuration != null ? ' · ${formatDuration(session.sessionDuration!)}' : ''}',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.textTertiary,
                  ),
                ),
                if (summary.score != null) ...[
                  const SizedBox(height: SpacingTokens.xs),
                  StarRating(
                    stars: scoreToStars(summary.score!),
                    size: 16,
                    color: _goldStar,
                  ),
                ],
              ],
            ),
          ),
          // Skill area badge.
          ZxBadge(
            label: drill.skillArea.dbValue,
            color: ColorTokens.skillArea(drill.skillArea),
          ),
        ],
      ),
    );
  }
}
