// Phase 2B — Reflow type definitions.
// No Drift dependency. All types are plain immutable Dart classes.

/// TD-04 §3.2 — Trigger types that initiate a reflow cycle.
enum ReflowTriggerType {
  sessionClose,
  anchorEdit,
  instanceEdit,
  instanceDeletion,
  sessionDeletion,
  allocationChange,
  fullRebuild,
}

/// TD-04 §3.2 — Pre-computed reflow trigger with affected scope.
/// Immutable value object created by ScopeResolver.
/// Supports [mergeWith] for deferred trigger coalescing (TD-04 §3.3.3).
class ReflowTrigger {
  final ReflowTriggerType type;
  final String userId;
  final Set<String> affectedSubskillIds;
  final String? sessionId;
  final String? drillId;

  const ReflowTrigger({
    required this.type,
    required this.userId,
    required this.affectedSubskillIds,
    this.sessionId,
    this.drillId,
  });

  /// TD-04 §3.3.3 — Coalesce two triggers into one with unioned scope.
  /// If either trigger is a fullRebuild, the merged result is a fullRebuild.
  ReflowTrigger mergeWith(ReflowTrigger other) {
    assert(userId == other.userId, 'Cannot merge triggers for different users');
    final mergedType =
        (type == ReflowTriggerType.fullRebuild ||
                other.type == ReflowTriggerType.fullRebuild)
            ? ReflowTriggerType.fullRebuild
            : type;
    return ReflowTrigger(
      type: mergedType,
      userId: userId,
      affectedSubskillIds: {...affectedSubskillIds, ...other.affectedSubskillIds},
    );
  }
}

/// TD-04 §3.2 — Result of a completed reflow cycle.
class ReflowResult {
  final bool success;
  final Duration elapsed;
  final int subskillsRebuilt;
  final int windowEntriesProcessed;
  final double? newOverallScore;
  final String? errorCode;

  const ReflowResult({
    required this.success,
    required this.elapsed,
    required this.subskillsRebuilt,
    required this.windowEntriesProcessed,
    this.newOverallScore,
    this.errorCode,
  });

  const ReflowResult.failure({
    required this.elapsed,
    required this.errorCode,
  })  : success = false,
        subskillsRebuilt = 0,
        windowEntriesProcessed = 0,
        newOverallScore = null;
}

/// TD-03 §4.4 — Result of scoring a single session during close or reflow.
class SessionScoringResult {
  final String sessionId;
  final String drillId;
  final double sessionScore;
  final bool integrityBreach;
  final Set<String> subskillIds;
  final String drillType;
  final bool isDualMapped;

  const SessionScoringResult({
    required this.sessionId,
    required this.drillId,
    required this.sessionScore,
    required this.integrityBreach,
    required this.subskillIds,
    required this.drillType,
    required this.isDualMapped,
  });
}
