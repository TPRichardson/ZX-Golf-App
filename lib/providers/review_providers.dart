// Phase 6 — Review & Analysis Riverpod providers.
// S05 — SkillScore dashboard, analysis, plan adherence.
// Bridges materialised scoring data + reference data to UI.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/planning/weakness_detection.dart';

import 'repository_providers.dart';
import 'scoring_providers.dart';
import 'planning_providers.dart';

// ---------------------------------------------------------------------------
// Window entry JSON parsing — used by window detail views
// ---------------------------------------------------------------------------

/// Parse MaterialisedWindowState.entries JSON to a list of [WindowEntry].
/// Format: `[{"sessionId","completionTimestamp","score","occupancy","isDualMapped"}]`
List<WindowEntry> parseWindowEntries(String json) {
  if (json.isEmpty || json == '[]') return [];
  final List<dynamic> list = jsonDecode(json) as List<dynamic>;
  return list.map((e) {
    final map = e as Map<String, dynamic>;
    return WindowEntry(
      sessionId: map['sessionId'] as String,
      completionTimestamp:
          DateTime.parse(map['completionTimestamp'] as String),
      score: (map['score'] as num).toDouble(),
      occupancy: (map['occupancy'] as num).toDouble(),
      isDualMapped: map['isDualMapped'] as bool,
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// Heatmap provider — S15 §15.3.3 continuous grey-to-green
// ---------------------------------------------------------------------------

/// S15 §15.3.3 — Normalised 0–1 opacity for each SkillArea heatmap tile.
/// Computed from skillAreaScore / maxPossibleScore (kMaxScore * allocation weight).
final skillAreaHeatmapProvider = Provider.family<
    AsyncValue<Map<SkillArea, double>>, String>((ref, userId) {
  final scoresAsync = ref.watch(skillAreaScoresProvider(userId));
  return scoresAsync.whenData((scores) {
    final map = <SkillArea, double>{};
    for (final score in scores) {
      // Max possible = kMaxScore (5.0) for the skill area weighted average.
      // Normalise to 0–1 range.
      final normalised =
          score.skillAreaScore > 0 ? (score.skillAreaScore / kMaxScore).clamp(0.0, 1.0) : 0.0;
      map[score.skillArea] = normalised;
    }
    return map;
  });
});

// ---------------------------------------------------------------------------
// Subskills by area — filtered view
// ---------------------------------------------------------------------------

/// Filters subskillScoresProvider by a specific SkillArea.
final subskillsByAreaProvider = Provider.family<
    AsyncValue<List<MaterialisedSubskillScore>>,
    ({String userId, SkillArea skillArea})>((ref, params) {
  final scoresAsync = ref.watch(subskillScoresProvider(params.userId));
  return scoresAsync.whenData((scores) {
    return scores
        .where((s) => s.skillArea == params.skillArea)
        .toList();
  });
});

// ---------------------------------------------------------------------------
// Window detail — parsed entries for a specific window
// ---------------------------------------------------------------------------

/// Parsed window detail for a specific subskill + practice type.
final windowDetailProvider = Provider.family<
    AsyncValue<ParsedWindowDetail?>,
    ({String userId, String subskill, DrillType practiceType})>(
    (ref, params) {
  final windowsAsync = ref.watch(windowStatesProvider(params.userId));
  return windowsAsync.whenData((windows) {
    final match = windows.where((w) =>
        w.subskill == params.subskill &&
        w.practiceType == params.practiceType);
    if (match.isEmpty) return null;
    final ws = match.first;
    return ParsedWindowDetail(
      entries: parseWindowEntries(ws.entries),
      totalOccupancy: ws.totalOccupancy,
      weightedSum: ws.weightedSum,
      windowAverage: ws.windowAverage,
      subskill: ws.subskill,
      practiceType: ws.practiceType,
      skillArea: ws.skillArea,
    );
  });
});

/// Parsed window state with deserialized entries.
class ParsedWindowDetail {
  final List<WindowEntry> entries;
  final double totalOccupancy;
  final double weightedSum;
  final double windowAverage;
  final String subskill;
  final DrillType practiceType;
  final SkillArea skillArea;

  const ParsedWindowDetail({
    required this.entries,
    required this.totalOccupancy,
    required this.weightedSum,
    required this.windowAverage,
    required this.subskill,
    required this.practiceType,
    required this.skillArea,
  });
}

// ---------------------------------------------------------------------------
// Weakness ranking — S08 §8.7
// ---------------------------------------------------------------------------

/// S08 §8.7 — Ranked subskills by WeaknessIndex via WeaknessDetectionEngine.
/// Watches subskillScoresProvider stream to reactively update after reflow.
final weaknessRankingProvider =
    FutureProvider.family<List<RankedSubskill>, String>((ref, userId) async {
  // Watch the stream provider so this re-fires when scores change after reflow.
  final subskillScoresAsync = ref.watch(subskillScoresProvider(userId));
  final subskillScores = subskillScoresAsync.valueOrNull ?? [];

  final subskillRefs =
      await ref.watch(scoringRepositoryProvider).getAllSubskillRefs();
  final engine = ref.watch(weaknessDetectionEngineProvider);
  return engine.rankSubskills(subskillScores, subskillRefs);
});

// ---------------------------------------------------------------------------
// Session queries — S05 §5.2
// ---------------------------------------------------------------------------

/// All closed sessions with drill data for a user.
/// Watches windowStatesProvider stream to reactively update after reflow.
final closedSessionsProvider =
    FutureProvider.family<List<SessionWithDrill>, String>((ref, userId) {
  // Watch a stream provider so this invalidates when scoring data changes.
  ref.watch(windowStatesProvider(userId));
  return ref
      .watch(scoringRepositoryProvider)
      .getAllClosedSessionsForUser(userId);
});

/// Closed sessions filtered by drillId.
/// Watches windowStatesProvider stream to reactively update after reflow.
final drillSessionsProvider = FutureProvider.family<List<SessionWithDrill>,
    ({String userId, String drillId})>((ref, params) async {
  // Watch a stream provider so this invalidates when scoring data changes.
  ref.watch(windowStatesProvider(params.userId));
  final all = await ref
      .watch(scoringRepositoryProvider)
      .getAllClosedSessionsForUser(params.userId);
  return all.where((s) => s.drill.drillId == params.drillId).toList();
});

/// Lightweight sessions for trend computation.
/// Watches windowStatesProvider stream to reactively update after reflow.
final lightSessionsProvider =
    FutureProvider.family<List<LightSession>, String>((ref, userId) {
  // Watch a stream provider so this invalidates when scoring data changes.
  ref.watch(windowStatesProvider(userId));
  return ref
      .watch(scoringRepositoryProvider)
      .getAllClosedSessionsLight(userId);
});

// ---------------------------------------------------------------------------
// Drill name lookup — for window entry display
// ---------------------------------------------------------------------------

/// All drills indexed by drillId for name lookups.
/// Watches windowStatesProvider stream to reactively update when drills change.
final drillMapProvider =
    FutureProvider.family<Map<String, Drill>, String>((ref, userId) {
  // Watch a stream provider so this invalidates when data changes.
  ref.watch(windowStatesProvider(userId));
  return ref.watch(scoringRepositoryProvider).getAllDrillsMap();
});

// ---------------------------------------------------------------------------
// Subskill refs — for display names
// ---------------------------------------------------------------------------

/// All subskill refs for name lookups.
/// Reference data — stable after seed, but invalidate to be safe.
final allSubskillRefsProvider =
    FutureProvider<List<SubskillRef>>((ref) async {
  return ref.watch(scoringRepositoryProvider).getAllSubskillRefs();
});

// ---------------------------------------------------------------------------
// Plan adherence — S05 §5.3
// ---------------------------------------------------------------------------

/// S05 §5.3 — Plan adherence calculation.
/// Adherence = (Completed planned Slots / Total planned Slots) × 100.
/// Only slots with drillId count as planned; overflow (planned=false) excluded.
/// Watches windowStatesProvider to reactively update after session completion.
final planAdherenceProvider = FutureProvider.family<PlanAdherence,
    ({String userId, DateTime start, DateTime end})>((ref, params) async {
  // Watch a stream provider so this invalidates when scoring data changes
  // (completion matching runs after session close / reflow).
  ref.watch(windowStatesProvider(params.userId));
  final repo = ref.watch(planningRepositoryProvider);
  final days = await repo
      .getCalendarDaysByUser(params.userId, from: params.start, to: params.end);

  int totalPlanned = 0;
  int completedPlanned = 0;
  final perSkillArea = <SkillArea, ({int total, int completed})>{};

  // We need drill lookups for skill area breakdown.
  final drillMap =
      await ref.watch(scoringRepositoryProvider).getAllDrillsMap();

  for (final day in days) {
    final slots = _parseSlotsJson(day.slots);
    for (final slot in slots) {
      // Only planned slots with drillId count.
      if (!slot.planned || slot.drillId == null) continue;
      totalPlanned++;
      if (slot.isCompleted) completedPlanned++;

      // Skill area breakdown.
      final drill = drillMap[slot.drillId];
      if (drill != null) {
        final area = drill.skillArea;
        final existing =
            perSkillArea[area] ?? (total: 0, completed: 0);
        perSkillArea[area] = (
          total: existing.total + 1,
          completed: existing.completed + (slot.isCompleted ? 1 : 0),
        );
      }
    }
  }

  return PlanAdherence(
    totalPlanned: totalPlanned,
    completedPlanned: completedPlanned,
    percentage:
        totalPlanned > 0 ? (completedPlanned / totalPlanned * 100) : 0,
    perSkillArea: perSkillArea,
  );
});

/// Plan adherence result.
class PlanAdherence {
  final int totalPlanned;
  final int completedPlanned;
  final double percentage;
  final Map<SkillArea, ({int total, int completed})> perSkillArea;

  const PlanAdherence({
    required this.totalPlanned,
    required this.completedPlanned,
    required this.percentage,
    required this.perSkillArea,
  });
}

List<Slot> _parseSlotsJson(String json) {
  if (json.isEmpty || json == '[]') return [];
  final List<dynamic> list = jsonDecode(json) as List<dynamic>;
  return list
      .map((e) => Slot.fromJson(e as Map<String, dynamic>))
      .toList();
}
