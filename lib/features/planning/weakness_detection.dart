import 'dart:math';

import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';

// S08 §8.7 — Weakness Detection Engine.
// Pure computation — reads scoring state, ranks subskills, selects drills.
// No side effects, no writes.

/// S08 §8.7.2 — Ranked subskill with WeaknessIndex.
class RankedSubskill {
  final String subskillId;
  final SkillArea skillArea;
  final double transitionAverage;
  final double pressureAverage;
  final double weightedAverage;
  final int allocation;
  final double weaknessIndex;
  final bool isIncomplete;

  const RankedSubskill({
    required this.subskillId,
    required this.skillArea,
    required this.transitionAverage,
    required this.pressureAverage,
    required this.weightedAverage,
    required this.allocation,
    required this.weaknessIndex,
    required this.isIncomplete,
  });
}

class WeaknessDetectionEngine {
  /// S08 §8.7.2 — Rank subskills by WeaknessIndex.
  ///
  /// WeaknessIndex = (5 - WeightedAverage) * AllocationWeight
  /// AllocationWeight = Allocation / 1000
  ///
  /// Priority 1: Incomplete windows (no data) ranked above saturated.
  List<RankedSubskill> rankSubskills(
    List<MaterialisedSubskillScore> scores,
    List<SubskillRef> subskillRefs,
  ) {
    final scoreMap = {for (final s in scores) s.subskill: s};

    final ranked = <RankedSubskill>[];

    for (final ref in subskillRefs) {
      final score = scoreMap[ref.subskillId];
      final allocationWeight = ref.allocation / kTotalAllocation;

      if (score == null || score.weightedAverage == 0) {
        // S08 §8.7.2 — Incomplete window: no data.
        ranked.add(RankedSubskill(
          subskillId: ref.subskillId,
          skillArea: ref.skillArea,
          transitionAverage: 0,
          pressureAverage: 0,
          weightedAverage: 0,
          allocation: ref.allocation,
          weaknessIndex: kMaxScore * allocationWeight,
          isIncomplete: true,
        ));
      } else {
        final weaknessIndex =
            (kMaxScore - score.weightedAverage) * allocationWeight;
        ranked.add(RankedSubskill(
          subskillId: ref.subskillId,
          skillArea: ref.skillArea,
          transitionAverage: score.transitionAverage,
          pressureAverage: score.pressureAverage,
          weightedAverage: score.weightedAverage,
          allocation: score.allocation,
          weaknessIndex: weaknessIndex,
          isIncomplete: false,
        ));
      }
    }

    // Sort: incomplete first, then descending WeaknessIndex.
    ranked.sort((a, b) {
      if (a.isIncomplete != b.isIncomplete) {
        return a.isIncomplete ? -1 : 1;
      }
      return b.weaknessIndex.compareTo(a.weaknessIndex);
    });

    return ranked;
  }

  /// S08 §8.7.4 — Select a drill for a criterion from the practice pool.
  ///
  /// Mode-specific sorting:
  /// - Weakest: descending WeaknessIndex → lowest avg → least recent → alpha
  /// - Strength: ascending WeaknessIndex → highest avg → most recent → alpha
  /// - Novelty: descending WeaknessIndex → least recent → alpha
  /// - Random: uniform from eligible pool
  ///
  /// S08 §8.9.1 — alreadySelected enforces drill repetition block.
  String? selectDrill(
    GenerationCriterion criterion,
    List<DrillWithScore> practicePool,
    List<RankedSubskill> ranking,
    Set<String> alreadySelected, {
    Random? random,
  }) {
    // Filter pool by criterion constraints.
    var eligible = practicePool.where((d) {
      if (alreadySelected.contains(d.drillId)) return false;

      if (criterion.skillArea != null &&
          d.skillArea != criterion.skillArea) {
        return false;
      }

      if (criterion.drillTypes.isNotEmpty &&
          !criterion.drillTypes.contains(d.drillType)) {
        return false;
      }

      if (criterion.subskillId != null) {
        if (!d.subskillIds.contains(criterion.subskillId)) return false;
      }

      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    // Build a weakness lookup for each subskill.
    final weaknessMap = {for (final r in ranking) r.subskillId: r};

    switch (criterion.mode) {
      case GenerationMode.weakest:
        eligible.sort((a, b) => _compareWeakest(a, b, weaknessMap));
        return eligible.first.drillId;

      case GenerationMode.strength:
        eligible.sort((a, b) => _compareStrength(a, b, weaknessMap));
        return eligible.first.drillId;

      case GenerationMode.novelty:
        eligible.sort((a, b) => _compareNovelty(a, b, weaknessMap));
        return eligible.first.drillId;

      case GenerationMode.random:
        final rng = random ?? Random();
        return eligible[rng.nextInt(eligible.length)].drillId;
    }
  }

  /// S08 §8.2.2 — Resolve all entries for a routine application.
  /// Fixed entries pass through; criterion entries use selectDrill.
  List<String?> resolveEntries(
    List<RoutineEntry> entries,
    List<DrillWithScore> practicePool,
    List<RankedSubskill> ranking,
    int availableSlotCount, {
    Random? random,
  }) {
    final resolved = <String?>[];
    final alreadySelected = <String>{};
    final toResolve = entries.take(availableSlotCount);

    for (final entry in toResolve) {
      switch (entry.type) {
        case RoutineEntryType.fixed:
          resolved.add(entry.drillId);
          if (entry.drillId != null) alreadySelected.add(entry.drillId!);

        case RoutineEntryType.criterion:
          if (entry.criterion == null) {
            resolved.add(null);
            continue;
          }
          final drillId = selectDrill(
            entry.criterion!,
            practicePool,
            ranking,
            alreadySelected,
            random: random,
          );
          if (drillId != null) {
            resolved.add(drillId);
            alreadySelected.add(drillId);
          } else {
            resolved.add(null);
          }
      }
    }

    return resolved;
  }

  // ---------------------------------------------------------------------------
  // Sort comparators — S08 §8.7.4
  // ---------------------------------------------------------------------------

  /// Weakest: highest WeaknessIndex (of primary subskill) → lowest avg → least recent → alpha.
  int _compareWeakest(
    DrillWithScore a,
    DrillWithScore b,
    Map<String, RankedSubskill> weaknessMap,
  ) {
    final aWi = _maxWeaknessIndex(a.subskillIds, weaknessMap);
    final bWi = _maxWeaknessIndex(b.subskillIds, weaknessMap);
    if (aWi != bWi) return bWi.compareTo(aWi); // Descending.

    // Tiebreak: lower average score = weaker.
    if (a.averageScore != b.averageScore) {
      return a.averageScore.compareTo(b.averageScore);
    }

    // Tiebreak: least recent.
    final aRecent = a.lastPracticed ?? DateTime(1970);
    final bRecent = b.lastPracticed ?? DateTime(1970);
    if (aRecent != bRecent) return aRecent.compareTo(bRecent);

    // Tiebreak: alphabetical.
    return a.name.compareTo(b.name);
  }

  /// Strength: lowest WeaknessIndex → highest avg → most recent → alpha.
  int _compareStrength(
    DrillWithScore a,
    DrillWithScore b,
    Map<String, RankedSubskill> weaknessMap,
  ) {
    final aWi = _maxWeaknessIndex(a.subskillIds, weaknessMap);
    final bWi = _maxWeaknessIndex(b.subskillIds, weaknessMap);
    if (aWi != bWi) return aWi.compareTo(bWi); // Ascending.

    if (a.averageScore != b.averageScore) {
      return b.averageScore.compareTo(a.averageScore); // Descending avg.
    }

    final aRecent = a.lastPracticed ?? DateTime(1970);
    final bRecent = b.lastPracticed ?? DateTime(1970);
    if (aRecent != bRecent) return bRecent.compareTo(aRecent); // Most recent.

    return a.name.compareTo(b.name);
  }

  /// Novelty: highest WeaknessIndex → least recent → alpha.
  int _compareNovelty(
    DrillWithScore a,
    DrillWithScore b,
    Map<String, RankedSubskill> weaknessMap,
  ) {
    final aWi = _maxWeaknessIndex(a.subskillIds, weaknessMap);
    final bWi = _maxWeaknessIndex(b.subskillIds, weaknessMap);
    if (aWi != bWi) return bWi.compareTo(aWi); // Descending.

    final aRecent = a.lastPracticed ?? DateTime(1970);
    final bRecent = b.lastPracticed ?? DateTime(1970);
    if (aRecent != bRecent) return aRecent.compareTo(bRecent); // Least recent.

    return a.name.compareTo(b.name);
  }

  double _maxWeaknessIndex(
    Set<String> subskillIds,
    Map<String, RankedSubskill> weaknessMap,
  ) {
    double maxWi = 0;
    for (final id in subskillIds) {
      final ranked = weaknessMap[id];
      if (ranked != null && ranked.weaknessIndex > maxWi) {
        maxWi = ranked.weaknessIndex;
      }
    }
    return maxWi;
  }
}

/// Lightweight drill representation for weakness engine.
/// Avoids coupling to Drift entity directly.
class DrillWithScore {
  final String drillId;
  final String name;
  final SkillArea skillArea;
  final DrillType drillType;
  final Set<String> subskillIds;
  final double averageScore;
  final DateTime? lastPracticed;

  const DrillWithScore({
    required this.drillId,
    required this.name,
    required this.skillArea,
    required this.drillType,
    required this.subskillIds,
    this.averageScore = 0,
    this.lastPracticed,
  });
}
