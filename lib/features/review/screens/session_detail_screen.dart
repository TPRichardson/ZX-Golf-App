import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/drill/drill_detail_screen.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S12 §12.6.2 — Session detail: single session instance breakdown.
// Read-only view of a closed session.

class SessionDetailScreen extends ConsumerWidget {
  final String userId;
  final String sessionId;

  const SessionDetailScreen({
    super.key,
    required this.userId,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionFuture = ref.watch(
        _sessionDetailProvider((userId: userId, sessionId: sessionId)));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Session Detail'),
      body: sessionFuture.when(
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Text(
                'Session not found',
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              // Session header.
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: BoxDecoration(
                  color: ColorTokens.surfaceRaised,
                  borderRadius:
                      BorderRadius.circular(ShapeTokens.radiusCard),
                  border: Border.all(color: ColorTokens.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.drillName,
                      style: TextStyle(
                        fontSize: TypographyTokens.displayLgSize,
                        fontWeight: TypographyTokens.displayLgWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    _InfoRow(
                        label: 'Score',
                        value: detail.sessionScore
                            .toStringAsFixed(2)),
                    _InfoRow(
                        label: 'Date',
                        value: _formatDate(detail.completionTimestamp)),
                    _InfoRow(
                        label: 'Skill Area',
                        value: detail.skillArea),
                    _InfoRow(
                        label: 'Drill Type',
                        value: detail.drillType),
                    if (detail.sessionDuration != null)
                      _InfoRow(
                          label: 'Duration',
                          value: _formatDuration(detail.sessionDuration!)),
                    // S11 §11.6 — Integrity flag display and suppression toggle.
                    if (detail.integrityFlag && !detail.integritySuppressed)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: SpacingTokens.sm),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: ColorTokens.warningIntegrity,
                            ),
                            const SizedBox(width: SpacingTokens.xs),
                            Text(
                              'Integrity flag active',
                              style: TextStyle(
                                fontSize: TypographyTokens.bodySize,
                                color: ColorTokens.warningIntegrity,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () async {
                                await ref
                                    .read(practiceRepositoryProvider)
                                    .suppressIntegrityFlag(
                                        sessionId, userId);
                                ref.invalidate(_sessionDetailProvider(
                                    (userId: userId, sessionId: sessionId)));
                              },
                              child: Text(
                                'Clear Flag',
                                style: TextStyle(
                                  fontSize: TypographyTokens.bodySize,
                                  color: ColorTokens.primaryDefault,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (detail.integrityFlag && detail.integritySuppressed)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: SpacingTokens.sm),
                        child: Text(
                          'Integrity flag cleared by user',
                          style: TextStyle(
                            fontSize: TypographyTokens.microSize,
                            color: ColorTokens.textTertiary,
                          ),
                        ),
                      ),
                    // 7C — Edit Drill cross-navigation for custom drills.
                    if (detail.drillOrigin == DrillOrigin.userCustom)
                      Padding(
                        padding: const EdgeInsets.only(
                            top: SpacingTokens.md),
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DrillDetailScreen(
                                drillId: detail.drillId,
                                isCustom: true,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit Drill'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorTokens.primaryDefault,
                            side: const BorderSide(
                                color: ColorTokens.primaryDefault),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading session',
            style: TextStyle(color: ColorTokens.errorDestructive),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) => formatDuration(seconds);

  String _formatDate(DateTime? dt) =>
      formatDate(dt, includeTime: true);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.xs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight session detail data.
class _SessionDetail {
  final String drillName;
  final String drillId;
  final DrillOrigin drillOrigin;
  final double sessionScore;
  final DateTime? completionTimestamp;
  final String skillArea;
  final String drillType;
  final bool integrityFlag;
  final bool integritySuppressed;
  final int? sessionDuration;

  const _SessionDetail({
    required this.drillName,
    required this.drillId,
    required this.drillOrigin,
    required this.sessionScore,
    this.completionTimestamp,
    required this.skillArea,
    required this.drillType,
    required this.integrityFlag,
    required this.integritySuppressed,
    this.sessionDuration,
  });
}

final _sessionDetailProvider = FutureProvider.family<_SessionDetail?,
    ({String userId, String sessionId})>((ref, params) async {
  final scoringRepo = ref.watch(scoringRepositoryProvider);
  final session = await scoringRepo.getSessionById(params.sessionId);
  if (session == null) return null;

  final drill = await scoringRepo.getDrillForSession(params.sessionId);

  // Session scores aren't persisted on the Session row; look them up
  // from materialised window entries.
  // Fix 7 — Multi-Output: collect all scores for this session across windows
  // and average them for drill-level display.
  final windows = await scoringRepo.getWindowStatesForUser(params.userId);
  final scores = <double>[];
  for (final w in windows) {
    final entries = parseWindowEntries(w.entries);
    for (final e in entries) {
      if (e.sessionId == params.sessionId) {
        scores.add(e.score);
      }
    }
  }
  final sessionScore =
      scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

  return _SessionDetail(
    drillName: drill?.name ?? 'Unknown',
    drillId: session.drillId,
    drillOrigin: drill?.origin ?? DrillOrigin.system,
    sessionScore: sessionScore,
    completionTimestamp: session.completionTimestamp,
    skillArea: drill?.skillArea.dbValue ?? 'Unknown',
    drillType: drill?.drillType.dbValue ?? 'Unknown',
    integrityFlag: session.integrityFlag,
    integritySuppressed: session.integritySuppressed,
    sessionDuration: session.sessionDuration,
  );
});
