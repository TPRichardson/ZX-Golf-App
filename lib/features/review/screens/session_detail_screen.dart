import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
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
    final sessionFuture = ref.watch(_sessionDetailProvider(sessionId));

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
                    if (detail.integritySuppressed)
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
                              'Integrity suppressed',
                              style: TextStyle(
                                fontSize: TypographyTokens.bodySize,
                                color: ColorTokens.warningIntegrity,
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

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
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
  final double sessionScore;
  final DateTime? completionTimestamp;
  final String skillArea;
  final String drillType;
  final bool integritySuppressed;

  const _SessionDetail({
    required this.drillName,
    required this.sessionScore,
    this.completionTimestamp,
    required this.skillArea,
    required this.drillType,
    required this.integritySuppressed,
  });
}

final _sessionDetailProvider =
    FutureProvider.family<_SessionDetail?, String>((ref, sessionId) async {
  final scoringRepo = ref.watch(scoringRepositoryProvider);
  final session = await scoringRepo.getSessionById(sessionId);
  if (session == null) return null;

  final drill = await scoringRepo.getDrillForSession(sessionId);

  // Session scores aren't persisted on the Session row; look them up
  // from materialised window entries.
  double sessionScore = 0;
  final userId = kDevUserId;
  final windows = await scoringRepo.getWindowStatesForUser(userId);
  for (final w in windows) {
    final entries = parseWindowEntries(w.entries);
    for (final e in entries) {
      if (e.sessionId == sessionId) {
        sessionScore = e.score;
        break;
      }
    }
    if (sessionScore > 0) break;
  }

  return _SessionDetail(
    drillName: drill?.name ?? 'Unknown',
    sessionScore: sessionScore,
    completionTimestamp: session.completionTimestamp,
    skillArea: drill?.skillArea.dbValue ?? 'Unknown',
    drillType: drill?.drillType.dbValue ?? 'Unknown',
    integritySuppressed: session.integritySuppressed,
  );
});
