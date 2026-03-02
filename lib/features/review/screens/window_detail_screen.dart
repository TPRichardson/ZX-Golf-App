import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S05 §5.1 — Window Detail View: ordered entries list for a single window.
// Newest first (CompletionTimestamp DESC).
// Read-only — no edit/delete.

class WindowDetailScreen extends ConsumerWidget {
  final String userId;
  final String subskillId;
  final DrillType practiceType;

  const WindowDetailScreen({
    super.key,
    required this.userId,
    required this.subskillId,
    required this.practiceType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final windowAsync = ref.watch(windowDetailProvider(
      (userId: userId, subskill: subskillId, practiceType: practiceType),
    ));
    final drillMapAsync = ref.watch(drillMapProvider(userId));
    final refsAsync = ref.watch(allSubskillRefsProvider);

    final subskillName = refsAsync.whenOrNull(
      data: (refs) =>
          refs.where((r) => r.subskillId == subskillId).firstOrNull?.name,
    ) ?? subskillId;

    final typeName =
        practiceType == DrillType.transition ? 'Transition' : 'Pressure';

    return Scaffold(
      appBar: ZxAppBar(title: '$subskillName — $typeName'),
      body: windowAsync.when(
        data: (detail) {
          if (detail == null || detail.entries.isEmpty) {
            return Center(
              child: Text(
                'No entries in this window',
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            );
          }

          final drillMap = drillMapAsync.valueOrNull ?? <String, Drill>{};

          // Entries already newest-first from reflow engine.
          final entries = detail.entries;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saturation header.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SpacingTokens.md),
                color: ColorTokens.surfaceRaised,
                child: Text(
                  'Window: ${detail.totalOccupancy.toStringAsFixed(1)} / '
                  '${kMaxWindowOccupancy.toStringAsFixed(1)} occupancy   '
                  'Avg: ${detail.windowAverage.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  itemCount: entries.length,
                  separatorBuilder: (_, i) {
                    // Visual divider at roll-off boundary (last entry).
                    if (i == entries.length - 2) {
                      return Column(
                        children: [
                          const SizedBox(height: SpacingTokens.sm),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: SpacingTokens.sm),
                                child: Text(
                                  'Roll-off boundary',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.microSize,
                                    color: ColorTokens.textTertiary,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: SpacingTokens.sm),
                        ],
                      );
                    }
                    return const SizedBox(height: SpacingTokens.sm);
                  },
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final drill = drillMap[_getDrillIdForSession(
                        entry.sessionId, drillMap)];
                    final drillName = drill?.name ?? 'Unknown drill';
                    final date =
                        _formatDate(entry.completionTimestamp);

                    return Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      decoration: BoxDecoration(
                        color: ColorTokens.surfaceRaised,
                        borderRadius:
                            BorderRadius.circular(ShapeTokens.radiusCard),
                        border:
                            Border.all(color: ColorTokens.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  drillName,
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodySize,
                                    fontWeight: TypographyTokens.headerWeight,
                                    color: ColorTokens.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: SpacingTokens.xs),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: TypographyTokens.microSize,
                                    color: ColorTokens.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Score.
                          Text(
                            entry.score.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: TypographyTokens.headerSize,
                              fontWeight: TypographyTokens.headerWeight,
                              color: ColorTokens.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.sm),
                          // Occupancy badge.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.sm,
                              vertical: SpacingTokens.xs,
                            ),
                            decoration: BoxDecoration(
                              color: entry.isDualMapped
                                  ? ColorTokens.warningMuted
                                      .withValues(alpha: 0.2)
                                  : ColorTokens.surfaceModal,
                              borderRadius: BorderRadius.circular(
                                  ShapeTokens.radiusGrid),
                            ),
                            child: Text(
                              entry.occupancy == 1.0 ? '1.0' : '0.5',
                              style: TextStyle(
                                fontSize: TypographyTokens.microSize,
                                color: entry.isDualMapped
                                    ? ColorTokens.warningIntegrity
                                    : ColorTokens.textTertiary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
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
            'Error loading window detail',
            style: TextStyle(color: ColorTokens.errorDestructive),
          ),
        ),
      ),
    );
  }

  String? _getDrillIdForSession(
      String sessionId, Map<String, Drill> drillMap) {
    // Window entries don't carry drillId directly. We cannot resolve
    // drill names without session-to-drill mapping. For now, return null.
    // The drill name lookup is best-effort.
    return null;
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
