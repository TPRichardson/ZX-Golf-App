import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/widgets/detail_row.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/empty_state.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/drill/drill_detail_screen.dart';
import 'package:zx_golf_app/core/scoring/scoring_helpers.dart';
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
            return const EmptyState(message: 'Session not found');
          }

          return ListView(
            padding: const EdgeInsets.all(SpacingTokens.md),
            children: [
              // Session header.
              _buildHeader(context, ref, detail),
              const SizedBox(height: SpacingTokens.md),
              // Instance breakdown by set.
              _buildInstanceBreakdown(detail),
              const SizedBox(height: SpacingTokens.xl),
              // Delete session.
              _buildDeleteButton(context, ref),
              const SizedBox(height: SpacingTokens.md),
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

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, _SessionDetail detail) {
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
          Text(
            detail.drillName,
            style: TextStyle(
              fontSize: TypographyTokens.displayLgSize,
              fontWeight: TypographyTokens.displayLgWeight,
              color: ColorTokens.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          DetailRow(
              labelWidth: 100,
              label: 'Session ID',
              value: detail.sessionId),
          DetailRow(
              labelWidth: 100,
              label: 'Score',
              value:
                  '${detail.sessionScore.toStringAsFixed(2)} (${scoreToStars(detail.sessionScore).toStringAsFixed(1)}\u2605)'),
          DetailRow(
              labelWidth: 100,
              label: 'Date',
              value: _formatDate(detail.completionTimestamp)),
          DetailRow(
              labelWidth: 100,
              label: 'Skill Area',
              value: detail.skillArea),
          DetailRow(
              labelWidth: 100,
              label: 'Drill Type',
              value: detail.drillType),
          DetailRow(
              labelWidth: 100,
              label: 'Input Mode',
              value: detail.inputMode),
          if (detail.sessionDuration != null)
            DetailRow(
                labelWidth: 100,
                label: 'Duration',
                value: _formatDuration(detail.sessionDuration!)),
          // Hit rate summary for binary/grid drills.
          if (detail.totalAttempts > 0)
            DetailRow(
                labelWidth: 100,
                label: 'Hit Rate',
                value:
                    '${detail.totalHits}/${detail.totalAttempts} (${(detail.totalHits / detail.totalAttempts * 100).toStringAsFixed(0)}%)'),
          // S11 §11.6 — Integrity flag display and suppression toggle.
          if (detail.integrityFlag && !detail.integritySuppressed)
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.sm),
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
                          .suppressIntegrityFlag(sessionId, userId);
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
              padding: const EdgeInsets.only(top: SpacingTokens.sm),
              child: Text(
                'Integrity flag cleared by user',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySmSize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            ),
          // 7C — Edit Drill cross-navigation for custom drills.
          if (detail.drillOrigin == DrillOrigin.custom)
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.md),
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  ref.context,
                  MaterialPageRoute(
                    builder: (_) => DrillDetailScreen(
                      drillId: detail.drillId,
                      isCustom: true,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorTokens.primaryDefault,
                  side: const BorderSide(color: ColorTokens.primaryDefault),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: SpacingTokens.sm),
                    Text('Edit Drill'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstanceBreakdown(_SessionDetail detail) {
    if (detail.setInstances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: SpacingTokens.md),
        child: EmptyState(message: 'No instances recorded'),
      );
    }

    final isBinary = detail.inputMode == 'BinaryHitMiss' ||
        detail.inputMode == 'GridCell';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instances',
          style: TextStyle(
            fontSize: TypographyTokens.headerSize,
            fontWeight: TypographyTokens.headerWeight,
            color: ColorTokens.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        for (final setGroup in detail.setInstances) ...[
          if (detail.setInstances.length > 1)
            Padding(
              padding: const EdgeInsets.only(
                  top: SpacingTokens.sm, bottom: SpacingTokens.xs),
              child: Text(
                'Set ${setGroup.setIndex + 1}',
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: ColorTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              border: Border.all(color: ColorTokens.surfaceBorder),
            ),
            child: Column(
              children: [
                // Column header.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: ColorTokens.surfaceBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '#',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySmSize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.textTertiary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isBinary ? 'Result' : 'Value',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySmSize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.textTertiary,
                          ),
                        ),
                      ),
                      Text(
                        'Time',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Instance rows.
                for (var i = 0; i < setGroup.instances.length; i++)
                  _buildInstanceRow(
                      i + 1, setGroup.instances[i], isBinary),
              ],
            ),
          ),
          // Set summary.
          if (isBinary)
            Padding(
              padding: const EdgeInsets.only(
                  top: SpacingTokens.xs, left: SpacingTokens.sm),
              child: Text(
                _setHitSummary(setGroup.instances),
                style: TextStyle(
                  fontSize: TypographyTokens.bodySmSize,
                  fontWeight: FontWeight.w600,
                  color: ColorTokens.textSecondary,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInstanceRow(
      int index, _InstanceData instance, bool isBinary) {
    final resultText = isBinary
        ? (instance.isHit ? 'Hit' : 'Miss')
        : instance.displayValue;
    final resultColor = isBinary
        ? (instance.isHit
            ? ColorTokens.successDefault
            : ColorTokens.errorDestructive)
        : ColorTokens.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ColorTokens.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (isBinary)
                  Icon(
                    instance.isHit
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 16,
                    color: resultColor,
                  ),
                if (isBinary) const SizedBox(width: SpacingTokens.xs),
                Text(
                  resultText,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w500,
                    color: resultColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(instance.timestamp),
            style: TextStyle(
              fontSize: TypographyTokens.bodySmSize,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _setHitSummary(List<_InstanceData> instances) {
    final hits = instances.where((i) => i.isHit).length;
    final total = instances.length;
    final pct = total > 0 ? (hits / total * 100).toStringAsFixed(0) : '0';
    return '$hits/$total hits ($pct%)';
  }

  String _formatDuration(int seconds) => formatDuration(seconds);

  String _formatDate(DateTime? dt) => formatDate(dt, includeTime: true);

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Widget _buildDeleteButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        icon: Icon(Icons.delete_outline,
            size: 18, color: ColorTokens.errorDestructive),
        label: Text(
          'Delete Session',
          style: TextStyle(
            color: ColorTokens.errorDestructive,
            fontSize: TypographyTokens.bodySize,
          ),
        ),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: ColorTokens.surfaceModal,
              title: const Text('Delete Session',
                  style: TextStyle(color: ColorTokens.textPrimary)),
              content: const Text(
                'This will permanently delete this session and all its data. '
                'Scores will be recalculated.',
                style: TextStyle(color: ColorTokens.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel',
                      style: TextStyle(color: ColorTokens.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: TextStyle(color: ColorTokens.errorDestructive)),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;
          await ref
              .read(practiceRepositoryProvider)
              .deleteClosedSession(sessionId, userId);
          ref.invalidate(closedSessionsProvider(userId));
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

/// Instance display data.
class _InstanceData {
  final String instanceId;
  final String rawMetrics;
  final DateTime timestamp;
  final bool isHit;
  final String displayValue;

  const _InstanceData({
    required this.instanceId,
    required this.rawMetrics,
    required this.timestamp,
    required this.isHit,
    required this.displayValue,
  });
}

/// Instances grouped by set.
class _SetGroup {
  final int setIndex;
  final List<_InstanceData> instances;

  const _SetGroup({required this.setIndex, required this.instances});
}

/// Lightweight session detail data.
class _SessionDetail {
  final String sessionId;
  final String drillName;
  final String drillId;
  final DrillOrigin drillOrigin;
  final double sessionScore;
  final DateTime? completionTimestamp;
  final String skillArea;
  final String drillType;
  final String inputMode;
  final bool integrityFlag;
  final bool integritySuppressed;
  final int? sessionDuration;
  final List<_SetGroup> setInstances;
  final int totalHits;
  final int totalAttempts;

  const _SessionDetail({
    required this.sessionId,
    required this.drillName,
    required this.drillId,
    required this.drillOrigin,
    required this.sessionScore,
    this.completionTimestamp,
    required this.skillArea,
    required this.drillType,
    required this.inputMode,
    required this.integrityFlag,
    required this.integritySuppressed,
    this.sessionDuration,
    required this.setInstances,
    required this.totalHits,
    required this.totalAttempts,
  });
}

/// Parse raw metrics to determine hit/miss.
bool _parseIsHit(String rawMetrics) {
  try {
    final parsed = jsonDecode(rawMetrics);
    if (parsed is Map) {
      if (parsed.containsKey('hit')) return parsed['hit'] == true;
      if (parsed.containsKey('result')) return parsed['result'] == true;
    }
  } catch (_) {}
  return false;
}

/// Parse raw metrics to a display string.
String _parseDisplayValue(String rawMetrics) {
  try {
    final parsed = jsonDecode(rawMetrics);
    if (parsed is num) return parsed.toString();
    if (parsed is Map) {
      // Show hit/miss for binary.
      if (parsed.containsKey('hit')) {
        return parsed['hit'] == true ? 'Hit' : 'Miss';
      }
      // Show grid cell for grid drills.
      if (parsed.containsKey('row') && parsed.containsKey('col')) {
        return 'R${parsed['row']} C${parsed['col']}';
      }
      // Show numeric value for raw data.
      for (final key in ['value', 'strokes', 'distance', 'speed', 'carry']) {
        if (parsed.containsKey(key) && parsed[key] is num) {
          return '${parsed[key]}';
        }
      }
      // Fallback: show all keys.
      return parsed.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
    }
  } catch (_) {}
  return rawMetrics;
}

final _sessionDetailProvider = FutureProvider.family<_SessionDetail?,
    ({String userId, String sessionId})>((ref, params) async {
  final scoringRepo = ref.watch(scoringRepositoryProvider);
  final practiceRepo = ref.watch(practiceRepositoryProvider);
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
    final entries = decodeWindowEntries(w.entries);
    for (final e in entries) {
      if (e.sessionId == params.sessionId) {
        scores.add(e.score);
      }
    }
  }
  final sessionScore =
      scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

  // Fetch sets and instances for the breakdown.
  final sets =
      await practiceRepo.watchSetsBySession(params.sessionId).first;
  final allInstances =
      await scoringRepo.getInstancesForSession(params.sessionId);

  // Group instances by set.
  final instancesBySet = <String, List<Instance>>{};
  for (final inst in allInstances) {
    instancesBySet.putIfAbsent(inst.setId, () => []).add(inst);
  }

  int totalHits = 0;
  int totalAttempts = 0;

  final setGroups = <_SetGroup>[];
  for (final s in sets) {
    final instances = instancesBySet[s.setId] ?? [];
    final instanceData = instances.map((inst) {
      final hit = _parseIsHit(inst.rawMetrics);
      if (hit) totalHits++;
      totalAttempts++;
      return _InstanceData(
        instanceId: inst.instanceId,
        rawMetrics: inst.rawMetrics,
        timestamp: inst.timestamp,
        isHit: hit,
        displayValue: _parseDisplayValue(inst.rawMetrics),
      );
    }).toList();
    setGroups.add(_SetGroup(setIndex: s.setIndex, instances: instanceData));
  }

  return _SessionDetail(
    sessionId: params.sessionId,
    drillName: drill?.name ?? 'Unknown',
    drillId: session.drillId,
    drillOrigin: drill?.origin ?? DrillOrigin.standard,
    sessionScore: sessionScore,
    completionTimestamp: session.completionTimestamp,
    skillArea: drill?.skillArea.dbValue ?? 'Unknown',
    drillType: drill?.drillType.dbValue ?? 'Unknown',
    inputMode: drill?.inputMode.dbValue ?? 'Unknown',
    integrityFlag: session.integrityFlag,
    integritySuppressed: session.integritySuppressed,
    sessionDuration: session.sessionDuration,
    setInstances: setGroups,
    totalHits: totalHits,
    totalAttempts: totalAttempts,
  );
});
