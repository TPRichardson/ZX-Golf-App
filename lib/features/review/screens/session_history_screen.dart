import 'dart:math' show sqrt;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/star_rating.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/review/screens/session_detail_screen.dart';
import 'package:zx_golf_app/providers/review_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

// S12 §12.6.2 — Session history screen for a specific drill.
// List: date, 0–5 score, set/instance count.
// S05 §5.2 — Variance tracking: SD with RAG thresholds.

class SessionHistoryScreen extends ConsumerWidget {
  final String userId;
  final String drillId;

  const SessionHistoryScreen({
    super.key,
    required this.userId,
    required this.drillId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync =
        ref.watch(drillSessionsProvider((userId: userId, drillId: drillId)));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Session History'),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const EmptyState(
                message: 'No sessions for this drill');
          }

          // Build session score map from window entries.
          final windowsAsync = ref.watch(
              windowStatesProvider(userId));
          final sessionScoreMap =
              _buildSessionScoreMap(windowsAsync.valueOrNull ?? []);

          // Variance tracking using window-derived scores.
          final variance = _computeVariance(sessions, sessionScoreMap);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Variance header.
              if (variance != null)
                _VarianceHeader(variance: variance),
              // Drill name.
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.md),
                child: Text(
                  sessions.first.drill.name,
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final score =
                        sessionScoreMap[s.session.sessionId] ?? 0.0;
                    final date = _formatDate(
                        s.session.completionTimestamp ?? DateTime.now());

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SessionDetailScreen(
                            userId: userId,
                            sessionId: s.session.sessionId,
                          ),
                        ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(
                            bottom: SpacingTokens.sm),
                        padding:
                            const EdgeInsets.all(SpacingTokens.sm),
                        decoration: BoxDecoration(
                          color: ColorTokens.surfaceRaised,
                          borderRadius: BorderRadius.circular(
                              ShapeTokens.radiusCard),
                          border: Border.all(
                              color: ColorTokens.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize:
                                          TypographyTokens.bodySize,
                                      color:
                                          ColorTokens.textPrimary,
                                    ),
                                  ),
                                  // S11 §11.6 — Show warning when integrityFlag is set and NOT suppressed.
                                  if (s.session.integrityFlag && !s.session.integritySuppressed)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: SpacingTokens.xs),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber,
                                            size: 14,
                                            color: ColorTokens
                                                .warningIntegrity,
                                          ),
                                          const SizedBox(
                                              width:
                                                  SpacingTokens.xs),
                                          Text(
                                            'Integrity flag',
                                            style: TextStyle(
                                              fontSize:
                                                  TypographyTokens
                                                      .bodySmSize,
                                              color: ColorTokens
                                                  .warningIntegrity,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            StarRating(
                              stars: scoreToStars(score),
                              size: 16,
                              color: scoreColor(score),
                            ),
                            const SizedBox(width: SpacingTokens.sm),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: ColorTokens.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading sessions',
            style: TextStyle(color: ColorTokens.errorDestructive),
          ),
        ),
      ),
    );
  }

  /// Build a map of sessionId → score from window entry data.
  /// Fix 7 — Multi-Output: delegates to buildDrillLevelScoreMap which
  /// averages scores when a session appears in multiple subskill windows.
  Map<String, double> _buildSessionScoreMap(
      List<MaterialisedWindowState> windows) {
    return buildDrillLevelScoreMap(windows);
  }

  _VarianceData? _computeVariance(
    List<SessionWithDrill> sessions,
    Map<String, double> scoreMap,
  ) {
    final scores = sessions
        .map((s) => scoreMap[s.session.sessionId])
        .whereType<double>()
        .toList();

    if (scores.length < 2) return null;

    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores
            .map((s) => (s - mean) * (s - mean))
            .reduce((a, b) => a + b) /
        scores.length;
    final sd = sqrt(variance);

    // S05 §5.2 — Confidence and RAG.
    _VarianceConfidence confidence;
    if (scores.length < 10) {
      confidence = _VarianceConfidence.none;
    } else if (scores.length < 20) {
      confidence = _VarianceConfidence.low;
    } else {
      confidence = _VarianceConfidence.full;
    }

    // RAG thresholds: Green < 0.40, Amber 0.40–0.80, Red >= 0.80.
    _VarianceRag rag;
    if (sd < 0.40) {
      rag = _VarianceRag.green;
    } else if (sd < 0.80) {
      rag = _VarianceRag.amber;
    } else {
      rag = _VarianceRag.red;
    }

    return _VarianceData(
      sd: sd,
      mean: mean,
      sessionCount: scores.length,
      confidence: confidence,
      rag: rag,
    );
  }

  String _formatDate(DateTime dt) => formatDate(dt);
}

enum _VarianceConfidence { none, low, full }

enum _VarianceRag { green, amber, red }

class _VarianceData {
  final double sd;
  final double mean;
  final int sessionCount;
  final _VarianceConfidence confidence;
  final _VarianceRag rag;

  const _VarianceData({
    required this.sd,
    required this.mean,
    required this.sessionCount,
    required this.confidence,
    required this.rag,
  });
}

class _VarianceHeader extends StatelessWidget {
  final _VarianceData variance;

  const _VarianceHeader({required this.variance});

  @override
  Widget build(BuildContext context) {
    if (variance.confidence == _VarianceConfidence.none) {
      return const SizedBox.shrink();
    }

    final ragColor = switch (variance.rag) {
      _VarianceRag.green => ColorTokens.successDefault,
      _VarianceRag.amber => ColorTokens.warningIntegrity,
      _VarianceRag.red => ColorTokens.errorDestructive,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.sm),
      color: ColorTokens.surfaceRaised,
      child: Row(
        children: [
          Icon(Icons.show_chart, size: 18, color: ragColor),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'SD: ${variance.sd.toStringAsFixed(3)}',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ragColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: SpacingTokens.md),
          Text(
            'Mean: ${variance.mean.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          if (variance.confidence == _VarianceConfidence.low)
            Text(
              'Low confidence',
              style: TextStyle(
                fontSize: TypographyTokens.bodySmSize,
                color: ColorTokens.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
