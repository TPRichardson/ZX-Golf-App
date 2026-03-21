// Phase 2B — ScopeResolver: pre-computes affected subskillIds for reflow triggers.
// TD-04 §3.2 Step 2 — Scope determination is separated from execution.
// No Drift dependency. Works with plain data.

import 'reflow_types.dart';
import 'scoring_helpers.dart';

class ScopeResolver {
  /// TD-04 §3.2 — From session close: affected subskills from drill's SubskillMapping.
  static ReflowTrigger fromSessionClose({
    required String userId,
    required String sessionId,
    required String drillId,
    required String subskillMappingJson,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.sessionClose,
      userId: userId,
      affectedSubskillIds: parseSubskillMapping(subskillMappingJson),
      sessionId: sessionId,
      drillId: drillId,
    );
  }

  /// TD-04 §3.2 — From anchor edit: same scope as session close.
  static ReflowTrigger fromAnchorEdit({
    required String userId,
    required String drillId,
    required String subskillMappingJson,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.anchorEdit,
      userId: userId,
      affectedSubskillIds: parseSubskillMapping(subskillMappingJson),
      drillId: drillId,
    );
  }

  /// TD-04 §3.2 — From instance edit: same scope as anchor edit.
  static ReflowTrigger fromInstanceEdit({
    required String userId,
    required String drillId,
    required String subskillMappingJson,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.instanceEdit,
      userId: userId,
      affectedSubskillIds: parseSubskillMapping(subskillMappingJson),
      drillId: drillId,
    );
  }

  /// TD-04 §3.2 — From instance deletion: same scope as anchor edit.
  static ReflowTrigger fromInstanceDeletion({
    required String userId,
    required String drillId,
    required String subskillMappingJson,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.instanceDeletion,
      userId: userId,
      affectedSubskillIds: parseSubskillMapping(subskillMappingJson),
      drillId: drillId,
    );
  }

  /// TD-04 §3.2 — From session deletion: same scope.
  static ReflowTrigger fromSessionDeletion({
    required String userId,
    required String drillId,
    required String subskillMappingJson,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.sessionDeletion,
      userId: userId,
      affectedSubskillIds: parseSubskillMapping(subskillMappingJson),
      drillId: drillId,
    );
  }

  /// TD-04 §3.2 — From allocation change: all subskillIds in the skill area.
  static ReflowTrigger fromAllocationChange({
    required String userId,
    required Set<String> subskillIdsInArea,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.allocationChange,
      userId: userId,
      affectedSubskillIds: subskillIdsInArea,
    );
  }

  /// TD-04 §3.3 — Full rebuild: all 19 subskillIds.
  static ReflowTrigger forFullRebuild({
    required String userId,
    required Set<String> allSubskillIds,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.fullRebuild,
      userId: userId,
      affectedSubskillIds: allSubskillIds,
    );
  }

}
