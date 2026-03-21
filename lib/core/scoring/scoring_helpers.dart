// Phase 2A — Shared scoring helper functions.
// Pure functions, no DB dependency.

import 'dart:convert';

import '../constants.dart';
import '../error_types.dart';
import 'scoring_types.dart';

/// TD-07 §2.3 — Validates that anchors satisfy min < scratch < pro
/// and all values are finite.
void validateAnchors(Anchors anchors) {
  if (!anchors.min.isFinite ||
      !anchors.scratch.isFinite ||
      !anchors.pro.isFinite) {
    throw ValidationException(
      code: ValidationException.invalidAnchors,
      message:
          'Anchor values must be finite: min=${anchors.min}, scratch=${anchors.scratch}, pro=${anchors.pro}',
    );
  }
  if (!(anchors.min < anchors.scratch && anchors.scratch < anchors.pro)) {
    throw ValidationException(
      code: ValidationException.invalidAnchors,
      message:
          'Anchors must satisfy min < scratch < pro: min=${anchors.min}, scratch=${anchors.scratch}, pro=${anchors.pro}',
    );
  }
}

/// TD-06 §5.1.2 — Parses a scoring adapter binding string to enum.
/// Accepts both camelCase (JSON) and PascalCase (DB seed) formats.
ScoringAdapterType parseScoringAdapterBinding(String binding) {
  switch (binding) {
    case 'hitRateInterpolation':
    case 'HitRateInterpolation':
      return ScoringAdapterType.hitRateInterpolation;
    case 'linearInterpolation':
    case 'LinearInterpolation':
      return ScoringAdapterType.linearInterpolation;
    case 'bestOfSetLinearInterpolation':
    case 'BestOfSetLinearInterpolation':
      return ScoringAdapterType.bestOfSetLinearInterpolation;
    case 'none':
    case 'None':
      return ScoringAdapterType.none;
    default:
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Unknown scoring adapter binding: $binding',
      );
  }
}

/// Spec: S01 §1.4 — Two-segment piecewise linear interpolation clamped to [0.0, 5.0].
///
/// Case 1: value < min → 0.0
/// Case 2: min ≤ value ≤ scratch → kScratchScore × (value − min) / (scratch − min)
/// Case 3: scratch < value ≤ pro → kScratchScore + (kMaxScore − kScratchScore) × (value − scratch) / (pro − scratch)
/// Case 4: value > pro → 5.0
double interpolate(double value, Anchors anchors) {
  if (value < anchors.min) {
    // Case 1 — Below minimum.
    return 0.0;
  } else if (value <= anchors.scratch) {
    // Case 2 — Between min and scratch.
    return kScratchScore *
        (value - anchors.min) /
        (anchors.scratch - anchors.min);
  } else if (value <= anchors.pro) {
    // Case 3 — Between scratch and pro.
    return kScratchScore +
        (kMaxScore - kScratchScore) *
            (value - anchors.scratch) /
            (anchors.pro - anchors.scratch);
  } else {
    // Case 4 — Above pro, hard cap.
    return kMaxScore;
  }
}

// ---------------------------------------------------------------------------
// Shared JSON parsing helpers — extracted from ReflowEngine, ScopeResolver,
// DrillRepository, PracticeRepository, and review_providers.
// ---------------------------------------------------------------------------

/// Parse SubskillMapping JSON array to a Set of subskill IDs.
Set<String> parseSubskillMapping(String json) {
  if (json.isEmpty || json == '[]') return {};
  final List<dynamic> list = jsonDecode(json) as List<dynamic>;
  return list.map((e) => e as String).toSet();
}

/// Parse drill anchors JSON to a Map of metric key → Anchors.
Map<String, Anchors> parseAnchorsMap(String json) {
  final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
  final result = <String, Anchors>{};
  for (final entry in map.entries) {
    final anchor = entry.value as Map<String, dynamic>;
    result[entry.key] = Anchors(
      min: (anchor['Min'] as num).toDouble(),
      scratch: (anchor['Scratch'] as num).toDouble(),
      pro: (anchor['Pro'] as num).toDouble(),
    );
  }
  return result;
}

/// Extract a numeric value from raw metrics JSON. Tries common keys.
double extractNumericValue(String rawMetrics) {
  final parsed = jsonDecode(rawMetrics);
  if (parsed is num) return parsed.toDouble();
  if (parsed is Map) {
    for (final key in ['value', 'distance', 'speed', 'carry']) {
      if (parsed.containsKey(key) && parsed[key] is num) {
        return (parsed[key] as num).toDouble();
      }
    }
  }
  return 0.0;
}

/// Determine if a raw metric represents a "hit" for grid/binary drills.
bool isHit(String rawMetrics, ScoringAdapterType adapterType) {
  final parsed = jsonDecode(rawMetrics);
  if (parsed is Map) {
    if (parsed.containsKey('hit')) return parsed['hit'] == true;
    if (parsed.containsKey('result')) return parsed['result'] == true;
  }
  return false;
}

/// Encode a list of [WindowEntry] to JSON string.
String encodeWindowEntries(List<WindowEntry> entries) {
  return jsonEncode(entries
      .map((e) => {
            'sessionId': e.sessionId,
            'drillId': e.drillId,
            'completionTimestamp': e.completionTimestamp.toIso8601String(),
            'score': e.score,
            'occupancy': e.occupancy,
            'isDualMapped': e.isDualMapped,
          })
      .toList());
}

/// Decode a JSON string to a list of [WindowEntry].
List<WindowEntry> decodeWindowEntries(String json) {
  if (json.isEmpty || json == '[]') return [];
  final List<dynamic> list = jsonDecode(json) as List<dynamic>;
  return list.map((e) {
    final map = e as Map<String, dynamic>;
    return WindowEntry(
      sessionId: map['sessionId'] as String,
      drillId: map['drillId'] as String? ?? '',
      completionTimestamp:
          DateTime.parse(map['completionTimestamp'] as String),
      score: (map['score'] as num).toDouble(),
      occupancy: (map['occupancy'] as num).toDouble(),
      isDualMapped: map['isDualMapped'] as bool,
    );
  }).toList();
}

/// Create a [WindowEntry] with dual-mapping occupancy logic.
/// Dual-mapped drills (mapped to 2+ subskills) get 0.5 occupancy each.
WindowEntry createWindowEntry({
  required String sessionId,
  required String drillId,
  required DateTime? completionTimestamp,
  required double score,
  required int subskillCount,
}) {
  final isDualMapped = subskillCount > 1;
  return WindowEntry(
    sessionId: sessionId,
    drillId: drillId,
    completionTimestamp: completionTimestamp ?? DateTime.now(),
    score: score,
    occupancy: isDualMapped ? 0.5 : 1.0,
    isDualMapped: isDualMapped,
  );
}
