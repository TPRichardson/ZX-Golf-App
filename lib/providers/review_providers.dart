// Phase 6 — Review & Analysis Riverpod providers.
// S05 — SkillScore dashboard, analysis, plan adherence.
// Bridges materialised scoring data + reference data to UI.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/features/planning/weakness_detection.dart';

import 'database_providers.dart';
import 'repository_providers.dart';
import 'scoring_providers.dart';
import 'planning_providers.dart';

// ---------------------------------------------------------------------------
// TD-07 §13.5 — RebuildNeeded staleness indicator
// ---------------------------------------------------------------------------

/// TD-07 §13.5 — Whether materialised scoring data is stale.
/// When true, score displays render at dimmed opacity.
final rebuildNeededProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  final row = await (db.select(db.syncMetadataEntries)
        ..where((t) => t.key.equals(SyncMetadataKeys.rebuildNeeded)))
      .getSingleOrNull();
  return row != null && row.value == 'true';
});

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
// Drill-level session score map — Fix 7: Multi-Output averaging
// ---------------------------------------------------------------------------

/// Fix 7 — Build a map of sessionId → drill-level score from window entries.
/// For Multi-Output drills, a session appears in multiple subskill windows
/// with different scores. The drill-level score is the mean of all window scores.
Map<String, double> buildDrillLevelScoreMap(
    List<MaterialisedWindowState> windows) {
  final scoreAccumulator = <String, List<double>>{};
  for (final w in windows) {
    final entries = parseWindowEntries(w.entries);
    for (final e in entries) {
      scoreAccumulator.putIfAbsent(e.sessionId, () => []).add(e.score);
    }
  }
  return scoreAccumulator.map(
    (sessionId, scores) => MapEntry(
      sessionId,
      scores.reduce((a, b) => a + b) / scores.length,
    ),
  );
}

// ---------------------------------------------------------------------------
// Session score map — cached drill-level scores from window entries
// ---------------------------------------------------------------------------

/// Drill-level score map derived from window states. Avoids re-parsing
/// window entry JSON on every widget rebuild.
final sessionScoreMapProvider =
    Provider.family<AsyncValue<Map<String, double>>, String>((ref, userId) {
  final windowsAsync = ref.watch(windowStatesProvider(userId));
  return windowsAsync.whenData((windows) => buildDrillLevelScoreMap(windows));
});

// ---------------------------------------------------------------------------
// Heatmap provider — S15 §15.3.3 continuous grey-to-green
// ---------------------------------------------------------------------------

/// S15 §15.3.3 — Normalised 0–1 opacity for each SkillArea heatmap tile.
/// skillAreaScore is already earned points; allocation is max possible points.
/// Normalised = earnedPoints / allocation (0–1 range).
final skillAreaHeatmapProvider = Provider.family<
    AsyncValue<Map<SkillArea, double>>, String>((ref, userId) {
  final scoresAsync = ref.watch(skillAreaScoresProvider(userId));
  return scoresAsync.whenData((scores) {
    final map = <SkillArea, double>{};
    for (final score in scores) {
      final normalised = score.allocation > 0 && score.skillAreaScore > 0
          ? (score.skillAreaScore / score.allocation).clamp(0.0, 1.0)
          : 0.0;
      map[score.skillArea] = normalised;
    }
    return map;
  });
});

// ---------------------------------------------------------------------------
// Skill area reference allocations — from SubskillRefs (always available)
// ---------------------------------------------------------------------------

/// Sum of subskill allocations per SkillArea from reference data.
final skillAreaAllocationsProvider =
    FutureProvider<Map<SkillArea, int>>((ref) async {
  final refs = await ref.watch(scoringRepositoryProvider).getAllSubskillRefs();
  final map = <SkillArea, int>{};
  for (final r in refs) {
    map[r.skillArea] = (map[r.skillArea] ?? 0) + r.allocation;
  }
  return map;
});

// ---------------------------------------------------------------------------
// Skill area stats — points from materialised scores, average from windows
// ---------------------------------------------------------------------------

/// Per-area stats: totalPoints from materialised skill area scores (accumulation
/// formula), average from raw window states (0–5 performance quality metric).
final skillAreaWindowStatsProvider = Provider.family<
    AsyncValue<Map<SkillArea, ({double totalPoints, double average})>>,
    String>((ref, userId) {
  final scoresAsync = ref.watch(skillAreaScoresProvider(userId));
  final windowsAsync = ref.watch(windowStatesProvider(userId));
  return scoresAsync.whenData((scores) {
    // Build average from window states (raw performance quality).
    final windows = windowsAsync.valueOrNull ?? [];
    final sums = <SkillArea, double>{};
    final occupancies = <SkillArea, double>{};
    for (final w in windows) {
      sums[w.skillArea] = (sums[w.skillArea] ?? 0) + w.weightedSum;
      occupancies[w.skillArea] =
          (occupancies[w.skillArea] ?? 0) + w.totalOccupancy;
    }

    final map = <SkillArea, ({double totalPoints, double average})>{};
    for (final score in scores) {
      final occ = occupancies[score.skillArea] ?? 0;
      final rawSum = sums[score.skillArea] ?? 0;
      map[score.skillArea] = (
        totalPoints: score.skillAreaScore,
        average: occ > 0 ? rawSum / occ : 0.0,
      );
    }
    return map;
  });
});

// ---------------------------------------------------------------------------
// Overall score — from materialised skill area scores
// ---------------------------------------------------------------------------

/// Overall SkillScore from materialised skill area scores (accumulation formula).
/// Used by both Home Dashboard and Review Dashboard for a single source of truth.
final overallWindowScoreProvider =
    Provider.family<AsyncValue<double>, String>((ref, userId) {
  final scoresAsync = ref.watch(skillAreaScoresProvider(userId));
  return scoresAsync.whenData((scores) =>
      scores.fold<double>(0.0, (sum, s) => sum + s.skillAreaScore));
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
// Subskill stats — points from materialised scores, average from windows
// ---------------------------------------------------------------------------

/// Per-subskill stats: totalPoints from materialised subskill scores (accumulation
/// formula), average from raw window states (0–5 performance quality metric).
/// Keyed by subskillId.
final subskillWindowStatsProvider = Provider.family<
    AsyncValue<Map<String, ({double totalPoints, double average})>>,
    String>((ref, userId) {
  final scoresAsync = ref.watch(subskillScoresProvider(userId));
  final windowsAsync = ref.watch(windowStatesProvider(userId));
  return scoresAsync.whenData((scores) {
    // Build average from window states (raw performance quality).
    final windows = windowsAsync.valueOrNull ?? [];
    final sums = <String, double>{};
    final occupancies = <String, double>{};
    for (final w in windows) {
      sums[w.subskill] = (sums[w.subskill] ?? 0) + w.weightedSum;
      occupancies[w.subskill] =
          (occupancies[w.subskill] ?? 0) + w.totalOccupancy;
    }

    final map = <String, ({double totalPoints, double average})>{};
    for (final s in scores) {
      final occ = occupancies[s.subskill] ?? 0;
      final rawSum = sums[s.subskill] ?? 0;
      map[s.subskill] = (
        totalPoints: s.subskillPoints,
        average: occ > 0 ? rawSum / occ : 0.0,
      );
    }
    return map;
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
/// Reads from closedSessionsProvider (cached) instead of making a separate DB call.
final drillSessionsProvider = Provider.family<AsyncValue<List<SessionWithDrill>>,
    ({String userId, String drillId})>((ref, params) {
  final allAsync = ref.watch(closedSessionsProvider(params.userId));
  return allAsync.whenData(
      (all) => all.where((s) => s.drill.drillId == params.drillId).toList());
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

/// Single SubskillRef lookup by subskillId.
/// Derives from allSubskillRefsProvider to avoid extra DB calls.
final subskillRefProvider =
    Provider.family<AsyncValue<SubskillRef?>, String>((ref, subskillId) {
  final refsAsync = ref.watch(allSubskillRefsProvider);
  return refsAsync.whenData((refs) =>
      refs.where((r) => r.subskillId == subskillId).firstOrNull);
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

List<Slot> _parseSlotsJson(String json) => parseSlotsFromJson(json);
