// Phase 4 — Session Execution Controller.
// Manages active session flow: structured completion, set advancement,
// real-time scoring feedback.
// S13 §13.6–13.9, S04 §4.3.

import 'dart:convert';

import 'package:zx_golf_app/core/scoring/instance_scorer.dart' as scorer;
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';

/// Result of logging an instance with real-time scoring.
class InstanceResult {
  final Instance instance;
  final double? realtimeScore;

  const InstanceResult({required this.instance, this.realtimeScore});
}

/// S13 §13.6–13.9 — Controls a single active Session execution.
/// Handles structured/unstructured/technique completion, set advancement,
/// and real-time scoring.
class SessionExecutionController {
  final PracticeRepository _repo;
  final Session session;
  final Drill drill;

  /// Current set being filled.
  PracticeSet? _currentSet;

  /// Instances logged in the current set.
  int _currentSetInstanceCount = 0;

  /// Number of completed sets.
  int _completedSetCount = 0;

  SessionExecutionController({
    required PracticeRepository repository,
    required this.session,
    required this.drill,
  }) : _repo = repository;

  /// Initialise from DB state (call after construction).
  Future<void> initialize() async {
    _currentSet = await _repo.getCurrentSet(session.sessionId);
    _completedSetCount = await _repo.getSetCount(session.sessionId);
    if (_currentSet != null) {
      _currentSetInstanceCount =
          await _repo.getInstanceCount(_currentSet!.setId);
    }
    // If multiple sets already exist, the "current" is the latest,
    // and completed count is total - 1 (current is in-progress).
    if (_completedSetCount > 0) {
      _completedSetCount = _completedSetCount - 1;
    }
  }

  /// S04 §4.3 — Whether this is a structured drill (has requiredAttemptsPerSet).
  bool get isStructured =>
      drill.requiredAttemptsPerSet != null &&
      drill.drillType != DrillType.techniqueBlock;

  /// Whether this is a technique block.
  bool get isTechniqueBlock => drill.drillType == DrillType.techniqueBlock;

  /// S13 §13.7 — Required set count for the drill.
  int get requiredSetCount => drill.requiredSetCount;

  /// S04 §4.3 — Required attempts per set (null for unstructured).
  int? get requiredAttemptsPerSet => drill.requiredAttemptsPerSet;

  /// Current set ID.
  String? get currentSetId => _currentSet?.setId;

  /// Current set index (0-based).
  int get currentSetIndex => _currentSet?.setIndex ?? 0;

  /// Instance count in current set.
  int get currentSetInstanceCount => _currentSetInstanceCount;

  /// Number of fully completed sets.
  int get completedSetCount => _completedSetCount;

  /// S13 §13.6 — Log an instance and compute real-time score.
  /// Returns the instance + optional 0–5 score for display.
  /// For structured drills: auto-advances set or signals auto-completion.
  Future<InstanceResult> logInstance(InstancesCompanion data) async {
    if (_currentSet == null) {
      throw StateError('No current set available');
    }

    final instance = await _repo.logInstance(
      _currentSet!.setId,
      data,
      session.sessionId,
    );
    _currentSetInstanceCount++;

    // Compute real-time score for display (not materialised).
    // Spec: S01 §1.4 — Only for LinearInterpolation adapter.
    final realtimeScore = _computeRealtimeScore(instance);

    return InstanceResult(
      instance: instance,
      realtimeScore: realtimeScore,
    );
  }

  /// S14 §14.10 — Undo the last instance logged in the current set.
  /// Available only while session is active (pre-scoring). Hard-deletes.
  /// Returns the deleted instance, or null if no instances exist.
  Future<Instance?> undoLastInstance() async {
    if (_currentSet == null || _currentSetInstanceCount <= 0) return null;

    // Get the most recent instance in this set.
    final instances = await _repo.watchInstancesBySet(_currentSet!.setId).first;
    if (instances.isEmpty) return null;

    final lastInstance = instances.last;
    await _repo.hardDeleteInstance(lastInstance.instanceId);
    _currentSetInstanceCount--;
    return lastInstance;
  }

  /// Whether undo is available (at least one instance in current set).
  bool get canUndo => _currentSetInstanceCount > 0;

  /// S13 §13.7 — Check if the current set is complete (structured only).
  bool isCurrentSetComplete() {
    if (!isStructured) return false;
    return _currentSetInstanceCount >= (requiredAttemptsPerSet ?? 0);
  }

  /// S13 §13.8 — Check if the entire session is auto-complete (structured).
  /// True when all sets are filled and the current set is complete.
  bool isSessionAutoComplete() {
    if (!isStructured) return false;
    if (!isCurrentSetComplete()) return false;
    // completedSetCount + 1 (current) == requiredSetCount means done.
    return (_completedSetCount + 1) >= requiredSetCount;
  }

  /// Fix 4 — Maximum instances that can be bulk-added in the current set.
  /// For structured drills: remaining capacity. For unstructured: unlimited (returns null).
  int? get remainingSetCapacity {
    if (!isStructured || requiredAttemptsPerSet == null) return null;
    return (requiredAttemptsPerSet! - _currentSetInstanceCount)
        .clamp(0, requiredAttemptsPerSet!);
  }

  /// Fix 4 — Log multiple instances with the same metrics in a batch.
  /// Timestamps use 1ms micro-offsets for ordering.
  /// Returns the count of instances actually logged.
  Future<int> logBulkInstances(
    int count,
    InstancesCompanion Function(int index) dataBuilder,
  ) async {
    if (_currentSet == null) {
      throw StateError('No current set available');
    }

    // Cap at remaining capacity for structured drills.
    final cap = remainingSetCapacity;
    final actualCount = cap != null ? count.clamp(0, cap) : count;

    for (var i = 0; i < actualCount; i++) {
      final data = dataBuilder(i);
      await _repo.logInstance(
        _currentSet!.setId,
        data,
        session.sessionId,
      );
      _currentSetInstanceCount++;
    }

    return actualCount;
  }

  /// S13 §13.7 — Advance to the next set.
  Future<PracticeSet> advanceSet() async {
    _completedSetCount++;
    _currentSet = await _repo.advanceSet(session.sessionId);
    _currentSetInstanceCount = 0;
    return _currentSet!;
  }

  /// S01 §1.4 — Compute real-time instance score for display.
  /// Only applies to LinearInterpolation drills (raw data input).
  /// Grid/binary drills score at session level (hit-rate), not per-instance.
  double? _computeRealtimeScore(Instance instance) {
    if (drill.drillType == DrillType.techniqueBlock) return null;
    if (drill.inputMode != InputMode.rawDataEntry) return null;

    try {
      final anchorsJson =
          jsonDecode(drill.anchors) as Map<String, dynamic>;
      if (anchorsJson.isEmpty) return null;

      // For raw data drills, extract numeric value from rawMetrics.
      final metricsMap =
          jsonDecode(instance.rawMetrics) as Map<String, dynamic>;
      final value = (metricsMap['value'] as num?)?.toDouble();
      if (value == null) return null;

      // Use the first subskill's anchors.
      final firstAnchor =
          anchorsJson.values.first as Map<String, dynamic>;
      final min = (firstAnchor['Min'] as num).toDouble();
      final scratch = (firstAnchor['Scratch'] as num).toDouble();
      final pro = (firstAnchor['Pro'] as num).toDouble();

      return scorer.scoreInstance(
        RawInstanceInput(value),
        Anchors(min: min, scratch: scratch, pro: pro),
      );
    } catch (_) {
      return null;
    }
  }
}
