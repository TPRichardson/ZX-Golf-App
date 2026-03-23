// Phase 2B — ReflowEngine: central orchestrator for scoring reflow.
// TD-04 §3.2 Steps 1-10, TD-03 §4.4, TD-04 §3.3, TD-04 §3.4.1.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/database.dart';
import '../../data/enums.dart';
import '../../data/repositories/event_log_repository.dart';
import '../../data/repositories/scoring_repository.dart';
import '../constants.dart';
import '../error_types.dart';
import '../instrumentation/reflow_diagnostics.dart';
import '../sync/sync_types.dart';
import '../sync/sync_write_gate.dart';
import 'integrity_evaluator.dart';
import 'overall_scorer.dart';
import 'rebuild_guard.dart';
import 'reflow_types.dart';
import 'scoring_helpers.dart';
import 'scoring_types.dart';
import 'session_scorer.dart';
import 'skill_area_scorer.dart';
import 'subskill_scorer.dart';
import 'window_composer.dart';

class ReflowEngine {
  final ScoringRepository _scoringRepo;
  final EventLogRepository _eventLogRepo;
  final RebuildGuard _rebuildGuard;
  final SyncWriteGate _syncWriteGate;
  final AppDatabase _db;
  final ReflowInstrumentation _instrumentation;

  static const _uuid = Uuid();

  ReflowEngine({
    required ScoringRepository scoringRepository,
    required EventLogRepository eventLogRepository,
    required RebuildGuard rebuildGuard,
    required SyncWriteGate syncWriteGate,
    required AppDatabase database,
    required ReflowInstrumentation instrumentation,
  })  : _scoringRepo = scoringRepository,
        _eventLogRepo = eventLogRepository,
        _rebuildGuard = rebuildGuard,
        _syncWriteGate = syncWriteGate,
        _db = database,
        _instrumentation = instrumentation;

  // ---------------------------------------------------------------------------
  // executeReflow — TD-04 §3.2 Steps 1-10
  // ---------------------------------------------------------------------------

  /// TD-04 §3.2 — Execute a scoped reflow cycle for the given trigger.
  Future<ReflowResult> executeReflow(ReflowTrigger trigger) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Check RebuildGuard — defer if rebuilding.
    if (_rebuildGuard.isHeld) {
      _rebuildGuard.defer(trigger);
      _instrumentation.emit('reflow.deferred', stopwatch.elapsed, {
        'userId': trigger.userId,
        'subskillCount': trigger.affectedSubskillIds.length,
      });
      return ReflowResult(
        success: true,
        elapsed: stopwatch.elapsed,
        subskillsRebuilt: 0,
        windowEntriesProcessed: 0,
      );
    }

    // Step 2: Acquire UserScoringLock with retries.
    // TD-04 §3.2 Step 1 — 3 retries × 500ms.
    var lockAcquired = false;
    for (var attempt = 0; attempt <= kLockMaxRetries; attempt++) {
      lockAcquired = await _scoringRepo.acquireLock(trigger.userId);
      if (lockAcquired) break;
      if (attempt < kLockMaxRetries) {
        await Future.delayed(kLockRetryDelay);
      }
    }
    if (!lockAcquired) {
      stopwatch.stop();
      _instrumentation.emit('reflow.lockTimeout', stopwatch.elapsed);
      throw ReflowException(
        code: ReflowException.lockTimeout,
        message:
            'Failed to acquire scoring lock after ${kLockMaxRetries + 1} attempts',
        context: {'userId': trigger.userId},
      );
    }

    try {
      // TD-07 §13.6 — Mark rebuildNeeded before materialised state modification.
      await _setRebuildNeeded(true);

      // Steps 3-9: Execute inside transaction.
      final result = await _db.transaction(() async {
        return _executeReflowSteps(trigger, stopwatch);
      });

      // TD-07 §13.6 — Clear rebuildNeeded after successful commit.
      await _setRebuildNeeded(false);

      // Step 9b: Emit EventLog: ReflowComplete.
      await _emitReflowCompleteEvent(trigger);

      stopwatch.stop();
      _instrumentation.emit('reflow.complete', stopwatch.elapsed, {
        'subskillsRebuilt': result.subskillsRebuilt,
        'windowEntries': result.windowEntriesProcessed,
      });

      return result;
    } catch (e) {
      stopwatch.stop();
      _instrumentation.emit('reflow.failed', stopwatch.elapsed, {
        'error': e.toString(),
      });
      if (e is ReflowException) rethrow;
      throw ReflowException(
        code: ReflowException.transactionFailed,
        message: 'Reflow transaction failed: $e',
        context: {'userId': trigger.userId},
      );
    } finally {
      // Step 10: Release lock.
      await _scoringRepo.releaseLock(trigger.userId);
    }
  }

  Future<ReflowResult> _executeReflowSteps(
    ReflowTrigger trigger,
    Stopwatch stopwatch,
  ) async {
    var totalWindowEntries = 0;
    final affectedSkillAreas = <SkillArea>{};

    // Pre-fetch all metric schemas once (small table, ~20 rows).
    final allSchemas = await _scoringRepo.getAllMetricSchemas();

    // Pre-fetch subskill refs for all affected subskills in one query.
    final allRefs =
        await _scoringRepo.getSubskillRefs(trigger.affectedSubskillIds);
    final refMap = {for (final r in allRefs) r.subskillId: r};

    // Step 3-5: For each affected subskill, rebuild windows.
    for (final subskillId in trigger.affectedSubskillIds) {
      final ref = refMap[subskillId];
      if (ref == null) continue;
      affectedSkillAreas.add(ref.skillArea);

      // Rebuild Transition window.
      final transitionEntries = await _rebuildWindowForSubskill(
        trigger.userId,
        subskillId,
        DrillType.transition,
        allSchemas,
        ref,
      );
      totalWindowEntries += transitionEntries;

      // Rebuild Pressure window.
      final pressureEntries = await _rebuildWindowForSubskill(
        trigger.userId,
        subskillId,
        DrillType.pressure,
        allSchemas,
        ref,
      );
      totalWindowEntries += pressureEntries;
    }

    // Fetch all window states once for subskill + skill area scoring.
    final allWindowStates =
        await _scoringRepo.getWindowStatesForUser(trigger.userId);

    // Step 6: Rebuild subskill scores.
    for (final subskillId in trigger.affectedSubskillIds) {
      final ref = refMap[subskillId];
      if (ref == null) continue;
      await _rebuildSubskillScore(trigger.userId, ref, allWindowStates);
    }

    // Fetch all subskill scores once for skill area scoring.
    final allSubskillScores =
        await _scoringRepo.getSubskillScoresForUser(trigger.userId);

    // Step 7: Rebuild affected SkillArea scores.
    for (final area in affectedSkillAreas) {
      await _rebuildSkillAreaScore(trigger.userId, area, allSubskillScores);
    }

    // Step 8: Rebuild Overall score.
    final newOverall = await _rebuildOverallScore(trigger.userId);

    // Step 9: Reset IntegritySuppressed.
    await _scoringRepo.resetIntegritySuppressedForSubskills(
      trigger.userId,
      trigger.affectedSubskillIds,
    );

    return ReflowResult(
      success: true,
      elapsed: stopwatch.elapsed,
      subskillsRebuilt: trigger.affectedSubskillIds.length,
      windowEntriesProcessed: totalWindowEntries,
      newOverallScore: newOverall,
    );
  }

  // ---------------------------------------------------------------------------
  // Window rebuilding — TD-04 §3.2 Steps 3-5
  // ---------------------------------------------------------------------------

  /// Rebuild a single window (Transition or Pressure) for a subskill.
  /// Returns the number of window entries processed.
  /// [schemaCache] and [subskillRef] are pre-fetched to avoid N+1 queries.
  Future<int> _rebuildWindowForSubskill(
    String userId,
    String subskillId,
    DrillType drillType,
    Map<String, MetricSchema> schemaCache,
    SubskillRef subskillRef,
  ) async {
    // TD-04 §3.2 Step 3 — Fetch closed sessions.
    final sessionsWithDrills = await _scoringRepo.getClosedSessionsForSubskill(
      userId,
      subskillId,
      drillType,
    );

    if (sessionsWithDrills.isEmpty) {
      // Write empty window state to clear stale data.
      final emptyWindow = composeWindow([]);
      await _scoringRepo.upsertWindowState(
        MaterialisedWindowStatesCompanion.insert(
          userId: userId,
          skillArea: subskillRef.skillArea,
          subskill: subskillId,
          practiceType: drillType,
          entries: Value(encodeWindowEntries(emptyWindow.entries)),
          totalOccupancy: Value(emptyWindow.totalOccupancy),
          weightedSum: Value(emptyWindow.weightedSum),
          windowAverage: Value(emptyWindow.windowAverage),
        ),
      );
      return 0;
    }

    // Batch-fetch instances for all sessions at once (eliminates N+1).
    final sessionIds =
        sessionsWithDrills.map((s) => s.session.sessionId).toList();
    final instancesBySession =
        await _scoringRepo.getInstancesForSessions(sessionIds);

    // TD-04 §3.2 Step 4 — Score each session and build WindowEntry list.
    final entries = <WindowEntry>[];
    for (final swd in sessionsWithDrills) {
      final schema = schemaCache[swd.drill.metricSchemaId];
      final instances = instancesBySession[swd.session.sessionId] ?? [];

      // Fix 1 — Multi-Output: score with the target subskill's anchors.
      final sessionScore =
          _scoreSessionInMemory(swd, schema, instances, forSubskillId: subskillId);
      if (sessionScore == null) continue;

      entries.add(createWindowEntry(
        sessionId: swd.session.sessionId,
        drillId: swd.drill.drillId,
        completionTimestamp: swd.session.completionTimestamp,
        score: sessionScore,
        subskillCount:
            parseSubskillMapping(swd.drill.subskillMapping).length,
      ));
    }

    // Per-drill window cap before roll-off.
    final drillWindowCaps = <String, int?>{
      for (final swd in sessionsWithDrills)
        swd.drill.drillId: swd.drill.windowCap,
    };
    final capped = _applyPerDrillWindowCap(entries, drillWindowCaps);

    // TD-04 §3.2 Step 5 — Partial roll-off before composing.
    final adjusted = _applyPartialRollOff(capped,
        maxOccupancy: subskillRef.windowSize.toDouble());

    // Compose the window using the pure stateless composer.
    final windowState = composeWindow(adjusted,
        maxOccupancy: subskillRef.windowSize.toDouble());

    // Write materialised window state.
    await _scoringRepo.upsertWindowState(
      MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: subskillRef.skillArea,
        subskill: subskillId,
        practiceType: drillType,
        entries: Value(encodeWindowEntries(windowState.entries)),
        totalOccupancy: Value(windowState.totalOccupancy),
        weightedSum: Value(windowState.weightedSum),
        windowAverage: Value(windowState.windowAverage),
      ),
    );

    return entries.length;
  }

  /// Per-drill window cap: for each drill with a non-null WindowCap,
  /// keep only the [cap] most recent entries (sorted DESC by timestamp).
  List<WindowEntry> _applyPerDrillWindowCap(
    List<WindowEntry> entries,
    Map<String, int?> drillWindowCaps,
  ) {
    // Skip if no caps are defined.
    if (drillWindowCaps.values.every((c) => c == null)) return entries;

    final sorted = List<WindowEntry>.from(entries)
      ..sort((a, b) {
        final ts = b.completionTimestamp.compareTo(a.completionTimestamp);
        if (ts != 0) return ts;
        return b.sessionId.compareTo(a.sessionId);
      });

    final drillCounts = <String, int>{};
    final result = <WindowEntry>[];
    for (final entry in sorted) {
      final cap = drillWindowCaps[entry.drillId];
      if (cap == null) {
        result.add(entry);
      } else {
        final count = drillCounts[entry.drillId] ?? 0;
        if (count < cap) {
          result.add(entry);
          drillCounts[entry.drillId] = count + 1;
        }
      }
    }
    return result;
  }

  /// TD-04 §3.2 Step 5 — Partial roll-off: sort DESC, walk forward accumulating
  /// occupancy. If an entry's full occupancy would exceed [maxOccupancy] but its
  /// occupancy minus 0.5 fits, include at reduced occupancy.
  List<WindowEntry> _applyPartialRollOff(List<WindowEntry> entries,
      {double maxOccupancy = kMaxWindowOccupancy}) {
    // Sort by CompletionTimestamp DESC, SessionID DESC.
    final sorted = List<WindowEntry>.from(entries)
      ..sort((a, b) {
        final tsCompare = b.completionTimestamp.compareTo(a.completionTimestamp);
        if (tsCompare != 0) return tsCompare;
        return b.sessionId.compareTo(a.sessionId);
      });

    final result = <WindowEntry>[];
    var accumulated = 0.0;

    for (final entry in sorted) {
      if (accumulated + entry.occupancy <= maxOccupancy) {
        result.add(entry);
        accumulated += entry.occupancy;
      } else if (entry.occupancy > 0.5 &&
          accumulated + (entry.occupancy - 0.5) <= maxOccupancy) {
        // Partial roll-off: reduce occupancy by 0.5.
        final reduced = entry.copyWith(occupancy: entry.occupancy - 0.5);
        result.add(reduced);
        accumulated += reduced.occupancy;
      }
      // Otherwise, entry doesn't fit at all — dropped.
    }

    return result;
  }

  /// Score a session using pre-fetched data (no DB queries).
  /// Returns null for technique blocks or missing schemas.
  /// [forSubskillId]: when provided (Fix 1 — Multi-Output), use that subskill's
  /// anchors instead of defaulting to the first subskill.
  double? _scoreSessionInMemory(
    SessionWithDrill swd,
    MetricSchema? schema,
    List<Instance> instances, {
    String? forSubskillId,
  }) {
    if (schema == null) return null;

    final adapterType = parseScoringAdapterBinding(schema.scoringAdapterBinding);
    if (adapterType == ScoringAdapterType.none) return null;
    if (instances.isEmpty) return 0.0;

    // Parse anchors for this drill's subskill.
    final anchorsMap = parseAnchorsMap(swd.drill.anchors);
    final subskillMapping = parseSubskillMapping(swd.drill.subskillMapping);
    if (subskillMapping.isEmpty || anchorsMap.isEmpty) return 0.0;

    // Fix 1 — Multi-Output: use the target subskill's anchors if specified.
    final targetSubskill = forSubskillId != null && anchorsMap.containsKey(forSubskillId)
        ? forSubskillId
        : subskillMapping.first;
    final anchors = anchorsMap[targetSubskill];
    if (anchors == null) return 0.0;

    if (adapterType == ScoringAdapterType.scoringGameInterpolation) {
      // Scoring game: sum strokes, compute +/- par, negate, interpolate.
      final par = _parsePar(schema.validationRules);
      final inputs = instances
          .map((i) => RawInstanceInput(extractNumericValue(i.rawMetrics)))
          .toList();
      return scoreScoringGameSession(inputs, par, anchors);
    } else if (adapterType == ScoringAdapterType.bestOfSetLinearInterpolation) {
      // Best-of-set: group by set, max per set, average, interpolate.
      final bySet = <String, List<double>>{};
      for (final i in instances) {
        bySet.putIfAbsent(i.setId, () => [])
            .add(extractNumericValue(i.rawMetrics));
      }
      return scoreBestOfSetSession(bySet, anchors);
    } else if (adapterType == ScoringAdapterType.linearInterpolation) {
      // Raw data drill: score per-instance then average.
      final inputs = instances
          .map((i) => RawInstanceInput(extractNumericValue(i.rawMetrics)))
          .toList();
      return scoreRawDataSession(inputs, anchors);
    } else {
      // Hit-rate drill (grid/binary): aggregate hits/attempts.
      var totalHits = 0;
      var totalAttempts = instances.length;
      for (final instance in instances) {
        if (isHit(instance.rawMetrics, adapterType)) {
          totalHits++;
        }
      }
      return scoreHitRateSession(
        HitRateSessionInput(totalHits: totalHits, totalAttempts: totalAttempts),
        anchors,
      );
    }
  }

  /// Score a session by fetching data from DB. Used by closeSession.
  Future<double?> _scoreSession(SessionWithDrill swd) async {
    final schema =
        await _scoringRepo.getMetricSchemaForDrill(swd.drill.drillId);
    if (schema == null) return null;

    final instances =
        await _scoringRepo.getInstancesForSession(swd.session.sessionId);

    return _scoreSessionInMemory(swd, schema, instances);
  }

  // ---------------------------------------------------------------------------
  // Score rebuilding (subskill, skill area, overall)
  // ---------------------------------------------------------------------------

  Future<void> _rebuildSubskillScore(
    String userId,
    SubskillRef ref,
    List<MaterialisedWindowState> allWindowStates,
  ) async {
    // Find window states from the pre-fetched list.
    final transitionWindow = _extractWindowState(
      allWindowStates, ref.subskillId, DrillType.transition);
    final pressureWindow = _extractWindowState(
      allWindowStates, ref.subskillId, DrillType.pressure);

    final score = scoreSubskill(
      transition: transitionWindow,
      pressure: pressureWindow,
      allocation: ref.allocation,
      windowSize: ref.windowSize,
    );

    await _scoringRepo.upsertSubskillScore(
      MaterialisedSubskillScoresCompanion.insert(
        userId: userId,
        skillArea: ref.skillArea,
        subskill: ref.subskillId,
        transitionAverage: Value(score.transitionAverage),
        pressureAverage: Value(score.pressureAverage),
        weightedAverage: Value(score.weightedAverage),
        subskillPoints: Value(score.subskillPoints),
        allocation: Value(score.allocation),
      ),
    );
  }

  WindowState _extractWindowState(
    List<MaterialisedWindowState> states,
    String subskillId,
    DrillType drillType,
  ) {
    final matching = states.where((s) =>
        s.subskill == subskillId && s.practiceType == drillType);
    if (matching.isEmpty) {
      return const WindowState(
        entries: [],
        totalOccupancy: 0,
        weightedSum: 0,
        windowAverage: 0,
      );
    }
    final s = matching.first;
    return WindowState(
      entries: decodeWindowEntries(s.entries),
      totalOccupancy: s.totalOccupancy,
      weightedSum: s.weightedSum,
      windowAverage: s.windowAverage,
    );
  }

  Future<void> _rebuildSkillAreaScore(
    String userId,
    SkillArea area,
    List<MaterialisedSubskillScore> allSubskillScores,
  ) async {
    final subskillRefs =
        await _scoringRepo.getSubskillRefsBySkillArea(area);

    final scores = <SubskillScore>[];
    for (final ref in subskillRefs) {
      final matching =
          allSubskillScores.where((s) => s.subskill == ref.subskillId);
      if (matching.isNotEmpty) {
        final m = matching.first;
        scores.add(SubskillScore(
          transitionAverage: m.transitionAverage,
          pressureAverage: m.pressureAverage,
          weightedAverage: m.weightedAverage,
          subskillPoints: m.subskillPoints,
          allocation: m.allocation,
        ));
      } else {
        scores.add(SubskillScore(
          transitionAverage: 0,
          pressureAverage: 0,
          weightedAverage: 0,
          subskillPoints: 0,
          allocation: ref.allocation,
        ));
      }
    }

    final areaScore = scoreSkillArea(scores);
    final totalAllocation =
        subskillRefs.fold<int>(0, (sum, r) => sum + r.allocation);

    await _scoringRepo.upsertSkillAreaScore(
      MaterialisedSkillAreaScoresCompanion.insert(
        userId: userId,
        skillArea: area,
        skillAreaScore: Value(areaScore),
        allocation: Value(totalAllocation),
      ),
    );
  }

  Future<double> _rebuildOverallScore(String userId) async {
    final areaScores =
        await _scoringRepo.getSkillAreaScoresForUser(userId);
    final overall =
        scoreOverall(areaScores.map((a) => a.skillAreaScore).toList());

    await _scoringRepo.upsertOverallScore(
      MaterialisedOverallScoresCompanion.insert(
        userId: userId,
        overallScore: Value(overall),
      ),
    );

    return overall;
  }

  // ---------------------------------------------------------------------------
  // executeFullRebuild — TD-04 §3.3
  // ---------------------------------------------------------------------------

  /// TD-04 §3.3 — Full rebuild: truncate and recompute all materialised state.
  Future<ReflowResult> executeFullRebuild(String userId) async {
    final stopwatch = Stopwatch()..start();

    // Step 1: Acquire RebuildGuard.
    if (!_rebuildGuard.acquire()) {
      stopwatch.stop();
      throw ReflowException(
        code: ReflowException.rebuildTimeout,
        message: 'RebuildGuard already held — concurrent rebuild rejected',
        context: {'userId': userId},
      );
    }

    // Step 2: Acquire SyncWriteGate.
    _syncWriteGate.acquireExclusive();

    try {
      final result = await executeFullRebuildInternal(userId);
      return result;
    } finally {
      // Release SyncWriteGate + RebuildGuard.
      _syncWriteGate.release();
      final coalesced = _rebuildGuard.release();

      // Execute coalesced deferred triggers if any.
      if (coalesced != null) {
        // Fire-and-forget: execute the coalesced trigger.
        // In production this would be awaited; for correctness we await here.
        await executeReflow(coalesced);
      }
    }
  }

  /// TD-04 §3.3 — Full rebuild internals without gate acquisition.
  /// Called by merge pipeline when gate is already held by SyncEngine.
  /// Phase 7B: extracted from executeFullRebuild to avoid deadlock.
  Future<ReflowResult> executeFullRebuildInternal(String userId) async {
    final stopwatch = Stopwatch()..start();

    // Get all subskill refs for full scope.
    final allRefs = await _scoringRepo.getAllSubskillRefs();
    final allSubskillIds = allRefs.map((r) => r.subskillId).toSet();

    // Truncate all materialised tables.
    await _scoringRepo.truncateAllMaterialisedForUser(userId);

    // Execute the reflow steps (lock acquired inside).
    var lockAcquired = false;
    for (var attempt = 0; attempt <= kLockMaxRetries; attempt++) {
      lockAcquired = await _scoringRepo.acquireLock(userId);
      if (lockAcquired) break;
      if (attempt < kLockMaxRetries) {
        await Future.delayed(kLockRetryDelay);
      }
    }
    if (!lockAcquired) {
      throw ReflowException(
        code: ReflowException.lockTimeout,
        message: 'Failed to acquire scoring lock for full rebuild',
        context: {'userId': userId},
      );
    }

    try {
      // TD-07 §13.6 — Mark rebuildNeeded before materialised state modification.
      await _setRebuildNeeded(true);

      final result = await _db.transaction(() async {
        return _executeFullRebuildBulk(userId, allRefs, stopwatch);
      });

      // TD-07 §13.6 — Clear rebuildNeeded after successful commit.
      await _setRebuildNeeded(false);

      // Write event log directly to DB, bypassing EventLogRepository's
      // awaitGateRelease() — the gate may already be held by the caller
      // (e.g. executeFullRebuild or merge pipeline).
      await _emitReflowCompleteEventDirect(ReflowTrigger(
        type: ReflowTriggerType.fullRebuild,
        userId: userId,
        affectedSubskillIds: allSubskillIds,
      ));

      stopwatch.stop();
      _instrumentation.emit('fullRebuild.complete', stopwatch.elapsed, {
        'subskillsRebuilt': result.subskillsRebuilt,
      });

      return result;
    } finally {
      await _scoringRepo.releaseLock(userId);
    }
  }

  /// Optimized full rebuild: pre-fetches ALL data in bulk, then scores
  /// everything in-memory with minimal DB round-trips.
  Future<ReflowResult> _executeFullRebuildBulk(
    String userId,
    List<SubskillRef> allRefs,
    Stopwatch stopwatch,
  ) async {
    // 1. Bulk-fetch schemas, drills, build metadata caches.
    final timer = Stopwatch()..start();
    final allSchemas = await _scoringRepo.getAllMetricSchemas();
    final allDrillsMap = await _scoringRepo.getAllDrillsMap();
    _instrumentation.emit('bulk.schemas', timer.elapsed);

    final cache = _buildDrillMetadataCache(allDrillsMap, allSchemas);

    // 2. Fetch lightweight sessions, index by (subskillId, drillType).
    timer.reset();
    final allLightSessions =
        await _scoringRepo.getAllClosedSessionsLight(userId);
    _instrumentation.emit('bulk.sessions', timer.elapsed, {
      'count': allLightSessions.length,
    });

    final sessionIndex = _indexSessionsBySubskill(allLightSessions, cache);

    // 3. Pre-filter: cap sessions per window at per-subskill occupancy limit.
    final capResult = _capSessionsPerWindow(sessionIndex, allRefs);
    final cappedIndex = capResult.cappedIndex;
    final neededSessionIds = capResult.neededSessionIds;

    // 4. Batch-fetch instance metrics only for needed sessions (raw SQL).
    timer.reset();
    final instanceMetrics =
        await _scoringRepo.getInstanceMetricsForSessions(
            neededSessionIds.toList());
    // Also fetch set-grouped metrics for best-of-set scoring.
    final instanceMetricsBySet =
        await _scoringRepo.getInstanceMetricsBySetForSessions(
            neededSessionIds.toList());
    _instrumentation.emit('bulk.instances', timer.elapsed, {
      'sessionCount': neededSessionIds.length,
      'instanceCount': instanceMetrics.values
          .fold<int>(0, (s, l) => s + l.length),
    });

    // 5. Score all windows in memory.
    final affectedSkillAreas = <SkillArea>{};
    var totalWindowEntries = 0;
    final windowCompanions = <MaterialisedWindowStatesCompanion>[];
    final windowStateMap = <String, WindowState>{};

    timer.reset();
    for (final ref in allRefs) {
      affectedSkillAreas.add(ref.skillArea);

      for (final drillType in [DrillType.transition, DrillType.pressure]) {
        final sessions =
            cappedIndex[ref.subskillId]?[drillType] ?? [];

        // Score each session in memory using cached metadata.
        final entries = <WindowEntry>[];
        for (final ls in sessions) {
          final sessionScore = _scoreSessionBulk(
            ls, ref.subskillId, cache,
            instanceMetrics, instanceMetricsBySet,
          );
          if (sessionScore == null) continue;

          entries.add(createWindowEntry(
            sessionId: ls.sessionId,
            drillId: ls.drillId,
            completionTimestamp: ls.completionTimestamp,
            score: sessionScore,
            subskillCount: cache.drillSubskillCache[ls.drillId]!.length,
          ));
        }

        totalWindowEntries += entries.length;

        // Per-drill window cap before roll-off.
        final capped =
            _applyPerDrillWindowCap(entries, cache.drillWindowCapCache);

        final adjusted = _applyPartialRollOff(capped,
            maxOccupancy: ref.windowSize.toDouble());
        final windowState = composeWindow(adjusted,
            maxOccupancy: ref.windowSize.toDouble());

        windowCompanions.add(MaterialisedWindowStatesCompanion.insert(
          userId: userId,
          skillArea: ref.skillArea,
          subskill: ref.subskillId,
          practiceType: drillType,
          entries: Value(encodeWindowEntries(windowState.entries)),
          totalOccupancy: Value(windowState.totalOccupancy),
          weightedSum: Value(windowState.weightedSum),
          windowAverage: Value(windowState.windowAverage),
        ));

        // Store computed WindowState in memory for subskill scoring.
        windowStateMap['${ref.subskillId}:${drillType.name}'] = windowState;
      }
    }

    _instrumentation.emit('bulk.scoring', timer.elapsed, {
      'windowEntries': totalWindowEntries,
    });

    // 6. Batch-write all window states at once.
    timer.reset();
    await _db.batch((batch) {
      for (final c in windowCompanions) {
        batch.insert(_db.materialisedWindowStates, c,
            onConflict: DoUpdate((_) => c));
      }
    });

    _instrumentation.emit('bulk.windowWrite', timer.elapsed);

    // 7. Compute & write subskill scores, then area + overall scores.
    final subskillScoreMap =
        await _computeAndWriteSubskillScores(userId, allRefs, windowStateMap);

    final newOverall = await _computeAndWriteAreaAndOverallScores(
      userId, allRefs, affectedSkillAreas, subskillScoreMap,
    );

    // 8. Reset IntegritySuppressed for all subskills.
    final allSubskillIds = allRefs.map((r) => r.subskillId).toSet();
    await _scoringRepo.resetIntegritySuppressedForSubskills(
      userId,
      allSubskillIds,
    );

    return ReflowResult(
      success: true,
      elapsed: stopwatch.elapsed,
      subskillsRebuilt: allRefs.length,
      windowEntriesProcessed: totalWindowEntries,
      newOverallScore: newOverall,
    );
  }

  // ---------------------------------------------------------------------------
  // _executeFullRebuildBulk helpers
  // ---------------------------------------------------------------------------

  /// Builds pre-parsed drill and schema metadata caches from raw data.
  _BulkRebuildCache _buildDrillMetadataCache(
    Map<String, Drill> allDrillsMap,
    Map<String, MetricSchema> allSchemas,
  ) {
    final drillSubskillCache = <String, Set<String>>{};
    final drillAnchorsCache = <String, Map<String, Anchors>>{};
    final drillTypeCache = <String, DrillType>{};
    final drillSchemaIdCache = <String, String>{};
    final drillWindowCapCache = <String, int?>{};
    for (final drill in allDrillsMap.values) {
      drillSubskillCache[drill.drillId] =
          parseSubskillMapping(drill.subskillMapping);
      drillAnchorsCache[drill.drillId] = parseAnchorsMap(drill.anchors);
      drillTypeCache[drill.drillId] = drill.drillType;
      drillSchemaIdCache[drill.drillId] = drill.metricSchemaId;
      drillWindowCapCache[drill.drillId] = drill.windowCap;
    }

    final adapterTypeCache = <String, ScoringAdapterType>{};
    final schemaValidationRulesCache = <String, String?>{};
    for (final entry in allSchemas.entries) {
      adapterTypeCache[entry.key] =
          parseScoringAdapterBinding(entry.value.scoringAdapterBinding);
      schemaValidationRulesCache[entry.key] = entry.value.validationRules;
    }

    return _BulkRebuildCache(
      drillSubskillCache: drillSubskillCache,
      drillAnchorsCache: drillAnchorsCache,
      drillTypeCache: drillTypeCache,
      drillSchemaIdCache: drillSchemaIdCache,
      drillWindowCapCache: drillWindowCapCache,
      adapterTypeCache: adapterTypeCache,
      schemaValidationRulesCache: schemaValidationRulesCache,
    );
  }

  /// Indexes lightweight sessions by (subskillId, drillType) in memory.
  /// Benchmark drills are normalised to the Transition window.
  Map<String, Map<DrillType, List<LightSession>>> _indexSessionsBySubskill(
    List<LightSession> sessions,
    _BulkRebuildCache cache,
  ) {
    final sessionIndex = <String, Map<DrillType, List<LightSession>>>{};
    for (final ls in sessions) {
      final subskillIds = cache.drillSubskillCache[ls.drillId];
      var drillType = cache.drillTypeCache[ls.drillId];
      if (subskillIds == null || drillType == null) continue;
      // Benchmark drills score in the Transition window.
      if (drillType == DrillType.benchmark) drillType = DrillType.transition;
      for (final subskillId in subskillIds) {
        sessionIndex
            .putIfAbsent(subskillId, () => {})
            .putIfAbsent(drillType, () => [])
            .add(ls);
      }
    }
    return sessionIndex;
  }

  /// Caps sessions per window at ~2.2x the per-subskill occupancy limit and
  /// collects the set of session IDs that will need instance metrics fetched.
  ({
    Map<String, Map<DrillType, List<LightSession>>> cappedIndex,
    Set<String> neededSessionIds,
  }) _capSessionsPerWindow(
    Map<String, Map<DrillType, List<LightSession>>> sessionIndex,
    List<SubskillRef> allRefs,
  ) {
    final neededSessionIds = <String>{};
    final cappedIndex = <String, Map<DrillType, List<LightSession>>>{};
    for (final ref in allRefs) {
      final maxSessionsPerWindow = (ref.windowSize * 2.2).ceil();
      for (final drillType in [DrillType.transition, DrillType.pressure]) {
        final sessions = sessionIndex[ref.subskillId]?[drillType] ?? [];
        final capped = sessions.length > maxSessionsPerWindow
            ? sessions.sublist(0, maxSessionsPerWindow)
            : sessions;
        cappedIndex
            .putIfAbsent(ref.subskillId, () => {})[drillType] = capped;
        for (final s in capped) {
          neededSessionIds.add(s.sessionId);
        }
      }
    }
    return (cappedIndex: cappedIndex, neededSessionIds: neededSessionIds);
  }

  /// Scores a single session for a given subskill using cached metadata.
  /// Returns null if the session should be skipped (no adapter, no metrics,
  /// missing anchors).
  double? _scoreSessionBulk(
    LightSession ls,
    String subskillId,
    _BulkRebuildCache cache,
    Map<String, List<String>> instanceMetrics,
    Map<String, Map<String, List<String>>> instanceMetricsBySet,
  ) {
    final schemaId = cache.drillSchemaIdCache[ls.drillId];
    final adapterType = schemaId != null
        ? (cache.adapterTypeCache[schemaId] ?? ScoringAdapterType.none)
        : ScoringAdapterType.none;

    if (adapterType == ScoringAdapterType.none) return null;

    final metrics = instanceMetrics[ls.sessionId] ?? [];
    if (metrics.isEmpty) return null;

    final anchorsMap = cache.drillAnchorsCache[ls.drillId]!;
    final subskillIds = cache.drillSubskillCache[ls.drillId]!;
    if (subskillIds.isEmpty || anchorsMap.isEmpty) return null;

    // Fix 1 — Multi-Output: use the current subskill's anchors, not always the first.
    final targetSubskill = anchorsMap.containsKey(subskillId)
        ? subskillId
        : subskillIds.first;
    final anchors = anchorsMap[targetSubskill];
    if (anchors == null) return null;

    if (adapterType == ScoringAdapterType.scoringGameInterpolation) {
      // Scoring game: sum strokes, compute +/- par, negate, interpolate.
      final validationRules = cache.schemaValidationRulesCache[schemaId];
      final par = _parsePar(validationRules);
      final inputs = metrics
          .map((m) => RawInstanceInput(extractNumericValue(m)))
          .toList();
      return scoreScoringGameSession(inputs, par, anchors);
    } else if (adapterType == ScoringAdapterType.bestOfSetLinearInterpolation) {
      final setGrouped = instanceMetricsBySet[ls.sessionId] ?? {};
      final bySet = <String, List<double>>{};
      for (final entry in setGrouped.entries) {
        bySet[entry.key] = entry.value
            .map((m) => extractNumericValue(m))
            .toList();
      }
      return scoreBestOfSetSession(bySet, anchors);
    } else if (adapterType == ScoringAdapterType.linearInterpolation) {
      final inputs = metrics
          .map((m) => RawInstanceInput(extractNumericValue(m)))
          .toList();
      return scoreRawDataSession(inputs, anchors);
    } else {
      var totalHits = 0;
      for (final m in metrics) {
        if (isHit(m, adapterType)) {
          totalHits++;
        }
      }
      return scoreHitRateSession(
        HitRateSessionInput(
            totalHits: totalHits, totalAttempts: metrics.length),
        anchors,
      );
    }
  }

  /// Computes subskill scores from window state map and batch-writes them.
  /// Returns the subskillScoreMap for use in area/overall scoring.
  Future<Map<String, SubskillScore>> _computeAndWriteSubskillScores(
    String userId,
    List<SubskillRef> allRefs,
    Map<String, WindowState> windowStateMap,
  ) async {
    final subskillCompanions = <MaterialisedSubskillScoresCompanion>[];
    final subskillScoreMap = <String, SubskillScore>{};

    for (final ref in allRefs) {
      final transitionWindow =
          windowStateMap['${ref.subskillId}:${DrillType.transition.name}'] ??
              const WindowState(
                  entries: [],
                  totalOccupancy: 0,
                  weightedSum: 0,
                  windowAverage: 0);
      final pressureWindow =
          windowStateMap['${ref.subskillId}:${DrillType.pressure.name}'] ??
              const WindowState(
                  entries: [],
                  totalOccupancy: 0,
                  weightedSum: 0,
                  windowAverage: 0);

      final score = scoreSubskill(
        transition: transitionWindow,
        pressure: pressureWindow,
        allocation: ref.allocation,
        windowSize: ref.windowSize,
      );

      subskillScoreMap[ref.subskillId] = score;
      subskillCompanions.add(MaterialisedSubskillScoresCompanion.insert(
        userId: userId,
        skillArea: ref.skillArea,
        subskill: ref.subskillId,
        transitionAverage: Value(score.transitionAverage),
        pressureAverage: Value(score.pressureAverage),
        weightedAverage: Value(score.weightedAverage),
        subskillPoints: Value(score.subskillPoints),
        allocation: Value(score.allocation),
      ));
    }

    // Batch-write all subskill scores.
    await _db.batch((batch) {
      for (final c in subskillCompanions) {
        batch.insert(_db.materialisedSubskillScores, c,
            onConflict: DoUpdate((_) => c));
      }
    });

    return subskillScoreMap;
  }

  /// Computes skill area scores and overall score, batch-writes them.
  /// Returns the new overall score.
  Future<double> _computeAndWriteAreaAndOverallScores(
    String userId,
    List<SubskillRef> allRefs,
    Set<SkillArea> affectedSkillAreas,
    Map<String, SubskillScore> subskillScoreMap,
  ) async {
    final refsByArea = <SkillArea, List<SubskillRef>>{};
    for (final ref in allRefs) {
      refsByArea.putIfAbsent(ref.skillArea, () => []).add(ref);
    }

    final areaScoreCompanions = <MaterialisedSkillAreaScoresCompanion>[];
    final areaScoreValues = <double>[];

    for (final area in affectedSkillAreas) {
      final areaRefs = refsByArea[area] ?? [];
      final scores = <SubskillScore>[];
      for (final ref in areaRefs) {
        scores.add(subskillScoreMap[ref.subskillId] ??
            SubskillScore(
              transitionAverage: 0,
              pressureAverage: 0,
              weightedAverage: 0,
              subskillPoints: 0,
              allocation: ref.allocation,
            ));
      }

      final areaScore = scoreSkillArea(scores);
      areaScoreValues.add(areaScore);
      final totalAllocation =
          areaRefs.fold<int>(0, (sum, r) => sum + r.allocation);

      areaScoreCompanions.add(MaterialisedSkillAreaScoresCompanion.insert(
        userId: userId,
        skillArea: area,
        skillAreaScore: Value(areaScore),
        allocation: Value(totalAllocation),
      ));
    }

    // Compute overall score in-memory.
    final newOverall = scoreOverall(areaScoreValues);

    // Batch-write area scores + overall score.
    await _db.batch((batch) {
      for (final c in areaScoreCompanions) {
        batch.insert(_db.materialisedSkillAreaScores, c,
            onConflict: DoUpdate((_) => c));
      }
      batch.insert(
          _db.materialisedOverallScores,
          MaterialisedOverallScoresCompanion.insert(
            userId: userId,
            overallScore: Value(newOverall),
          ),
          onConflict: DoUpdate((_) => MaterialisedOverallScoresCompanion.insert(
                userId: userId,
                overallScore: Value(newOverall),
              )));
    });

    return newOverall;
  }

  // ---------------------------------------------------------------------------
  // closeSession — TD-03 §4.4
  // ---------------------------------------------------------------------------

  /// TD-03 §4.4 — Close a session: score instances, evaluate integrity,
  /// compute session score, trigger scoped reflow.
  Future<SessionScoringResult> closeSession(
    String sessionId,
    String userId,
  ) async {
    final session = await _scoringRepo.getSessionById(sessionId);
    if (session == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Session not found: $sessionId',
      );
    }

    final drill = await _scoringRepo.getDrillForSession(sessionId);
    if (drill == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Drill not found for session: $sessionId',
      );
    }

    final schema =
        await _scoringRepo.getMetricSchemaForDrill(drill.drillId);
    if (schema == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'MetricSchema not found for drill: ${drill.drillId}',
      );
    }

    final adapterType = parseScoringAdapterBinding(schema.scoringAdapterBinding);
    final subskillMapping = parseSubskillMapping(drill.subskillMapping);
    final isDualMapped = subskillMapping.length > 1;
    final isCustomDrill = drill.origin == DrillOrigin.custom;

    // Score instances — only for system drills.
    double sessionScore = 0.0;
    bool integrityBreach = false;

    if (!isCustomDrill && adapterType != ScoringAdapterType.none) {
      final instances =
          await _scoringRepo.getInstancesForSession(sessionId);

      // Evaluate integrity per instance for raw data drills.
      if (adapterType == ScoringAdapterType.linearInterpolation) {
        for (final instance in instances) {
          final value = extractNumericValue(instance.rawMetrics);
          final breach = evaluateIntegrity(IntegrityInput(
            value: value,
            hardMinInput: schema.hardMinInput,
            hardMaxInput: schema.hardMaxInput,
            adapterType: adapterType,
          ));
          if (breach) integrityBreach = true;
        }
      }

      // Score the session.
      final swd = SessionWithDrill(session: session, drill: drill);
      sessionScore = await _scoreSession(swd) ?? 0.0;
    }

    // Update session: set status=Closed, integrity flag, completion timestamp.
    await _scoringRepo.updateSession(
      sessionId,
      SessionsCompanion(
        status: const Value(SessionStatus.closed),
        completionTimestamp: Value(DateTime.now()),
        integrityFlag: Value(integrityBreach),
        updatedAt: Value(DateTime.now()),
      ),
    );

    // Fix 8 — Session close pipeline: update materialised tables directly
    // instead of routing through executeReflow(). Per TD-03 §4.4, session close
    // is the primary scoring pipeline, not a reflow.
    // Custom drills are excluded — they don't contribute to the 1000 score.
    if (!isCustomDrill &&
        adapterType != ScoringAdapterType.none &&
        drill.drillType != DrillType.techniqueBlock &&
        subskillMapping.isNotEmpty) {
      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: userId,
        affectedSubskillIds: subskillMapping,
        sessionId: sessionId,
        drillId: drill.drillId,
      );
      await _executeSessionClosePipeline(trigger);
    }

    // Emit EventLog: SessionCompletion.
    await _eventLogRepo.create(EventLogsCompanion.insert(
      eventLogId: _uuid.v4(),
      userId: userId,
      eventTypeId: 'SessionCompletion',
      affectedEntityIds: Value(jsonEncode([sessionId])),
      affectedSubskills: Value(jsonEncode(subskillMapping.toList())),
      metadata: Value(jsonEncode({
        'sessionScore': sessionScore,
        'integrityBreach': integrityBreach,
        'drillType': drill.drillType.dbValue,
        'isCustomDrill': isCustomDrill,
      })),
    ));

    return SessionScoringResult(
      sessionId: sessionId,
      drillId: drill.drillId,
      sessionScore: isCustomDrill ? 0.0 : sessionScore,
      integrityBreach: integrityBreach,
      subskillIds: subskillMapping,
      drillType: drill.drillType.dbValue,
      isDualMapped: isDualMapped,
      isCustomDrill: isCustomDrill,
    );
  }

  /// Helper to construct a trigger from session close context.
  ReflowTrigger buildSessionCloseTrigger({
    required String userId,
    required String sessionId,
    required String drillId,
    required Set<String> subskillMapping,
  }) {
    return ReflowTrigger(
      type: ReflowTriggerType.sessionClose,
      userId: userId,
      affectedSubskillIds: subskillMapping,
      sessionId: sessionId,
      drillId: drillId,
    );
  }

  // ---------------------------------------------------------------------------
  // _executeSessionClosePipeline — Fix 8: TD-03 §4.4
  // ---------------------------------------------------------------------------

  /// Fix 8 — Session close pipeline: runs the same scoring steps as reflow but
  /// is classified as a session close event, not a reflow. Acquires lock, updates
  /// materialised tables, emits SessionCloseComplete (not ReflowComplete).
  Future<void> _executeSessionClosePipeline(ReflowTrigger trigger) async {
    final stopwatch = Stopwatch()..start();

    // Acquire UserScoringLock (same pattern as executeReflow).
    var lockAcquired = false;
    for (var attempt = 0; attempt <= kLockMaxRetries; attempt++) {
      lockAcquired = await _scoringRepo.acquireLock(trigger.userId);
      if (lockAcquired) break;
      if (attempt < kLockMaxRetries) {
        await Future.delayed(kLockRetryDelay);
      }
    }
    if (!lockAcquired) {
      stopwatch.stop();
      throw ReflowException(
        code: ReflowException.lockTimeout,
        message: 'Failed to acquire scoring lock for session close pipeline',
        context: {'userId': trigger.userId},
      );
    }

    try {
      await _setRebuildNeeded(true);

      await _db.transaction(() async {
        return _executeReflowSteps(trigger, stopwatch);
      });

      await _setRebuildNeeded(false);

      // Emit SessionCloseComplete (not ReflowComplete).
      await _eventLogRepo.create(EventLogsCompanion.insert(
        eventLogId: _uuid.v4(),
        userId: trigger.userId,
        eventTypeId: 'SessionCloseComplete',
        affectedSubskills:
            Value(jsonEncode(trigger.affectedSubskillIds.toList())),
        metadata: Value(jsonEncode({
          'sessionId': trigger.sessionId,
          'drillId': trigger.drillId,
        })),
      ));

      stopwatch.stop();
    } catch (e) {
      stopwatch.stop();
      if (e is ReflowException) rethrow;
      throw ReflowException(
        code: ReflowException.transactionFailed,
        message: 'Session close pipeline failed: $e',
        context: {'userId': trigger.userId},
      );
    } finally {
      await _scoringRepo.releaseLock(trigger.userId);
    }
  }

  // ---------------------------------------------------------------------------
  // checkCrashRecovery — TD-04 §3.4.1
  // ---------------------------------------------------------------------------

  /// TD-04 §3.4.1 — Check for expired lock and trigger full rebuild.
  Future<bool> checkCrashRecovery(String userId) async {
    final hasExpired = await _scoringRepo.hasExpiredLock(userId);
    if (!hasExpired) return false;

    // Release the expired lock.
    await _scoringRepo.releaseLock(userId);

    // Trigger full rebuild.
    await executeFullRebuild(userId);
    return true;
  }

  Future<void> _emitReflowCompleteEvent(ReflowTrigger trigger) async {
    await _eventLogRepo.create(EventLogsCompanion.insert(
      eventLogId: _uuid.v4(),
      userId: trigger.userId,
      eventTypeId: 'ReflowComplete',
      affectedSubskills:
          Value(jsonEncode(trigger.affectedSubskillIds.toList())),
      metadata: Value(jsonEncode({
        'triggerType': trigger.type.name,
        'subskillCount': trigger.affectedSubskillIds.length,
      })),
    ));
  }

  /// Direct DB write for event log — bypasses EventLogRepository's
  /// awaitGateRelease(). Used by executeFullRebuildInternal where the
  /// SyncWriteGate may already be held by the caller.
  Future<void> _emitReflowCompleteEventDirect(ReflowTrigger trigger) async {
    await _db.into(_db.eventLogs).insert(EventLogsCompanion.insert(
      eventLogId: _uuid.v4(),
      userId: trigger.userId,
      eventTypeId: 'ReflowComplete',
      affectedSubskills:
          Value(jsonEncode(trigger.affectedSubskillIds.toList())),
      metadata: Value(jsonEncode({
        'triggerType': trigger.type.name,
        'subskillCount': trigger.affectedSubskillIds.length,
      })),
    ));
  }

  // ---------------------------------------------------------------------------
  // TD-07 §13.6 — RebuildNeeded flag management
  // ---------------------------------------------------------------------------

  /// TD-07 §13.6 — Set or clear the rebuildNeeded flag in SyncMetadata.
  /// Written directly to DB to avoid gate contention during rebuild.
  Future<void> _setRebuildNeeded(bool needed) async {
    await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
      SyncMetadataEntriesCompanion.insert(
        key: SyncMetadataKeys.rebuildNeeded,
        value: needed ? 'true' : 'false',
      ),
    );
  }
}

/// Parse par value from MetricSchema validationRules JSON.
/// Defaults to 2 if not specified.
int _parsePar(String? validationRules) {
  if (validationRules == null || validationRules.isEmpty) return 2;
  final parsed = jsonDecode(validationRules);
  if (parsed is Map && parsed.containsKey('par')) {
    return (parsed['par'] as num).toInt();
  }
  return 2;
}

/// Private data class holding pre-parsed drill and schema metadata caches
/// used during bulk rebuild. Avoids re-parsing on every session evaluation.
class _BulkRebuildCache {
  /// Maps drillId -> set of subskill IDs the drill contributes to.
  final Map<String, Set<String>> drillSubskillCache;

  /// Maps drillId -> per-subskill anchors map.
  final Map<String, Map<String, Anchors>> drillAnchorsCache;

  /// Maps drillId -> drill type.
  final Map<String, DrillType> drillTypeCache;

  /// Maps drillId -> metric schema ID.
  final Map<String, String> drillSchemaIdCache;

  /// Maps drillId -> optional per-drill window cap.
  final Map<String, int?> drillWindowCapCache;

  /// Maps schemaId -> scoring adapter type.
  final Map<String, ScoringAdapterType> adapterTypeCache;

  /// Maps schemaId -> validationRules JSON string (nullable).
  final Map<String, String?> schemaValidationRulesCache;

  const _BulkRebuildCache({
    required this.drillSubskillCache,
    required this.drillAnchorsCache,
    required this.drillTypeCache,
    required this.drillSchemaIdCache,
    required this.drillWindowCapCache,
    required this.adapterTypeCache,
    required this.schemaValidationRulesCache,
  });
}
