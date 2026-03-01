import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §3.2 — Scoring materialised state repository.
// Phase 2B: full implementation replacing Phase 2A stubs.
//
// Manages: MaterialisedWindowState, MaterialisedSubskillScore,
//          MaterialisedSkillAreaScore, MaterialisedOverallScore,
//          UserScoringLock.
class ScoringRepository {
  final AppDatabase _db;

  ScoringRepository(this._db);

  // ---------------------------------------------------------------------------
  // UserScoringLock — TD-04 §3.2 Steps 1/10
  // ---------------------------------------------------------------------------

  // TD-04 §3.2 Step 1 — Acquire scoring lock. INSERT ON CONFLICT UPDATE.
  // Returns false if a non-expired lock is already held.
  Future<bool> acquireLock(String userId) async {
    final now = DateTime.now();
    final expiresAt = now.add(kUserScoringLockExpiry);

    // Check existing lock state.
    final existing = await (_db.select(_db.userScoringLocks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    if (existing != null && existing.isLocked) {
      // Check if lock has expired.
      if (existing.lockExpiresAt != null &&
          existing.lockExpiresAt!.isAfter(now)) {
        // Non-expired lock held — cannot acquire.
        return false;
      }
      // Expired lock — force-acquire.
    }

    await _db.into(_db.userScoringLocks).insertOnConflictUpdate(
          UserScoringLocksCompanion.insert(
            userId: userId,
            isLocked: const Value(true),
            lockedAt: Value(now),
            lockExpiresAt: Value(expiresAt),
          ),
        );
    return true;
  }

  // TD-04 §3.2 Step 10 — Release scoring lock.
  Future<void> releaseLock(String userId) async {
    await (_db.update(_db.userScoringLocks)
          ..where((t) => t.userId.equals(userId)))
        .write(const UserScoringLocksCompanion(
      isLocked: Value(false),
      lockedAt: Value(null),
      lockExpiresAt: Value(null),
    ));
  }

  // TD-04 §3.4.1 — Check if a user has an expired lock (crash recovery).
  Future<bool> hasExpiredLock(String userId) async {
    final existing = await (_db.select(_db.userScoringLocks)
          ..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();

    if (existing == null || !existing.isLocked) return false;
    if (existing.lockExpiresAt == null) return true;
    return existing.lockExpiresAt!.isBefore(DateTime.now());
  }

  // ---------------------------------------------------------------------------
  // MaterialisedWindowState — S16 §16.1.6
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Reactive stream of window states for a user.
  Stream<List<MaterialisedWindowState>> watchWindowStatesByUser(
      String userId) {
    return (_db.select(_db.materialisedWindowStates)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // Spec: S16 §16.1.6 — Upsert window state row.
  Future<void> upsertWindowState(
      MaterialisedWindowStatesCompanion data) async {
    await _db.into(_db.materialisedWindowStates).insertOnConflictUpdate(data);
  }

  // Phase 2B — Delete all window states for a user (full rebuild truncation).
  Future<int> deleteWindowStatesForUser(String userId) {
    return (_db.delete(_db.materialisedWindowStates)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // MaterialisedSubskillScore — S16 §16.1.6
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Reactive stream of subskill scores for a user.
  Stream<List<MaterialisedSubskillScore>> watchSubskillScoresByUser(
      String userId) {
    return (_db.select(_db.materialisedSubskillScores)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // Spec: S16 §16.1.6 — Upsert subskill score row.
  Future<void> upsertSubskillScore(
      MaterialisedSubskillScoresCompanion data) async {
    await _db.into(_db.materialisedSubskillScores).insertOnConflictUpdate(data);
  }

  // Phase 2B — Delete all subskill scores for a user (full rebuild truncation).
  Future<int> deleteSubskillScoresForUser(String userId) {
    return (_db.delete(_db.materialisedSubskillScores)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // MaterialisedSkillAreaScore — S16 §16.1.6
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Reactive stream of skill area scores for a user.
  Stream<List<MaterialisedSkillAreaScore>> watchSkillAreaScoresByUser(
      String userId) {
    return (_db.select(_db.materialisedSkillAreaScores)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // Spec: S16 §16.1.6 — Upsert skill area score row.
  Future<void> upsertSkillAreaScore(
      MaterialisedSkillAreaScoresCompanion data) async {
    await _db
        .into(_db.materialisedSkillAreaScores)
        .insertOnConflictUpdate(data);
  }

  // Phase 2B — Delete all skill area scores for a user (full rebuild truncation).
  Future<int> deleteSkillAreaScoresForUser(String userId) {
    return (_db.delete(_db.materialisedSkillAreaScores)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // MaterialisedOverallScore — S16 §16.1.6
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Reactive stream of overall score for a user.
  Stream<MaterialisedOverallScore?> watchOverallScoreByUser(String userId) {
    return (_db.select(_db.materialisedOverallScores)
          ..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull();
  }

  // Spec: S16 §16.1.6 — Upsert overall score row.
  Future<void> upsertOverallScore(
      MaterialisedOverallScoresCompanion data) async {
    await _db.into(_db.materialisedOverallScores).insertOnConflictUpdate(data);
  }

  // Phase 2B — Delete overall score for a user (full rebuild truncation).
  Future<int> deleteOverallScoreForUser(String userId) {
    return (_db.delete(_db.materialisedOverallScores)
          ..where((t) => t.userId.equals(userId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Bulk operations — TD-04 §3.3
  // ---------------------------------------------------------------------------

  // TD-04 §3.3 — Truncate all materialised tables for a user in a transaction.
  Future<void> truncateAllMaterialisedForUser(String userId) {
    return _db.transaction(() async {
      await deleteWindowStatesForUser(userId);
      await deleteSubskillScoresForUser(userId);
      await deleteSkillAreaScoresForUser(userId);
      await deleteOverallScoreForUser(userId);
    });
  }

  // ---------------------------------------------------------------------------
  // Raw data queries for reflow engine — TD-04 §3.2 Steps 3-5
  // ---------------------------------------------------------------------------

  // TD-04 §3.2 Step 3 — Get closed sessions for a subskill by drill type.
  // JOIN Sessions -> Drills, filter Status=Closed, IsDeleted=false,
  // SubskillMapping contains subskillId.
  // ORDER BY CompletionTimestamp DESC, SessionID DESC.
  Future<List<SessionWithDrill>> getClosedSessionsForSubskill(
    String userId,
    String subskillId,
    DrillType drillType,
  ) async {
    final query = _db.select(_db.sessions).join([
      innerJoin(
        _db.drills,
        _db.drills.drillId.equalsExp(_db.sessions.drillId),
      ),
      innerJoin(
        _db.practiceBlocks,
        _db.practiceBlocks.practiceBlockId
            .equalsExp(_db.sessions.practiceBlockId),
      ),
    ]);

    query.where(
      _db.practiceBlocks.userId.equals(userId) &
          _db.sessions.status.equalsValue(SessionStatus.closed) &
          _db.sessions.isDeleted.equals(false) &
          _db.drills.isDeleted.equals(false) &
          _db.drills.drillType.equalsValue(drillType) &
          _db.drills.subskillMapping.like('%$subskillId%'),
    );

    query.orderBy([
      OrderingTerm.desc(_db.sessions.completionTimestamp),
      OrderingTerm.desc(_db.sessions.sessionId),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      return SessionWithDrill(
        session: row.readTable(_db.sessions),
        drill: row.readTable(_db.drills),
      );
    }).toList();
  }

  // TD-04 §3.2 Step 4 — Get all non-deleted instances for a session.
  Future<List<Instance>> getInstancesForSession(String sessionId) async {
    final query = _db.select(_db.instances).join([
      innerJoin(
        _db.sets,
        _db.sets.setId.equalsExp(_db.instances.setId),
      ),
    ]);
    query.where(
      _db.sets.sessionId.equals(sessionId) &
          _db.instances.isDeleted.equals(false),
    );
    query.orderBy([
      OrderingTerm.asc(_db.sets.setIndex),
      OrderingTerm.asc(_db.instances.timestamp),
    ]);
    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.instances)).toList();
  }

  // TD-04 §3.2 — Get drill for a session.
  Future<Drill?> getDrillForSession(String sessionId) async {
    final session = await (_db.select(_db.sessions)
          ..where((t) => t.sessionId.equals(sessionId)))
        .getSingleOrNull();
    if (session == null) return null;
    return (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(session.drillId)))
        .getSingleOrNull();
  }

  // TD-04 §3.2 — Get metric schema for a drill.
  Future<MetricSchema?> getMetricSchemaForDrill(String drillId) async {
    final drill = await (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(drillId)))
        .getSingleOrNull();
    if (drill == null) return null;
    return (_db.select(_db.metricSchemas)
          ..where((t) => t.metricSchemaId.equals(drill.metricSchemaId)))
        .getSingleOrNull();
  }

  // Phase 2B — Get subskill refs by IDs.
  Future<List<SubskillRef>> getSubskillRefs(Set<String> ids) {
    return (_db.select(_db.subskillRefs)
          ..where((t) => t.subskillId.isIn(ids)))
        .get();
  }

  // Phase 2B — Get subskill refs by skill area.
  Future<List<SubskillRef>> getSubskillRefsBySkillArea(SkillArea area) {
    return (_db.select(_db.subskillRefs)
          ..where((t) => t.skillArea.equalsValue(area)))
        .get();
  }

  // Phase 2B — Get all subskill refs.
  Future<List<SubskillRef>> getAllSubskillRefs() {
    return _db.select(_db.subskillRefs).get();
  }

  // TD-04 §3.2 Step 9 — Reset IntegritySuppressed for affected sessions.
  Future<void> resetIntegritySuppressedForSubskills(
    String userId,
    Set<String> subskillIds,
  ) async {
    // Find sessions whose drill maps to any of the affected subskills.
    final query = _db.select(_db.sessions).join([
      innerJoin(
        _db.drills,
        _db.drills.drillId.equalsExp(_db.sessions.drillId),
      ),
      innerJoin(
        _db.practiceBlocks,
        _db.practiceBlocks.practiceBlockId
            .equalsExp(_db.sessions.practiceBlockId),
      ),
    ]);

    // Build OR condition for subskill matching.
    Expression<bool>? subskillFilter;
    for (final id in subskillIds) {
      final condition = _db.drills.subskillMapping.like('%$id%');
      subskillFilter =
          subskillFilter == null ? condition : (subskillFilter | condition);
    }
    if (subskillFilter == null) return;

    query.where(
      _db.practiceBlocks.userId.equals(userId) &
          _db.sessions.integritySuppressed.equals(true) &
          subskillFilter,
    );

    final rows = await query.get();
    final sessionIds =
        rows.map((r) => r.readTable(_db.sessions).sessionId).toList();

    if (sessionIds.isEmpty) return;

    await (_db.update(_db.sessions)
          ..where((t) => t.sessionId.isIn(sessionIds)))
        .write(const SessionsCompanion(integritySuppressed: Value(false)));
  }

  // Phase 2B — Batch-fetch all non-deleted instances for multiple sessions.
  // Returns a map of sessionId → List<Instance>.
  Future<Map<String, List<Instance>>> getInstancesForSessions(
      List<String> sessionIds) async {
    if (sessionIds.isEmpty) return {};

    final query = _db.select(_db.instances).join([
      innerJoin(
        _db.sets,
        _db.sets.setId.equalsExp(_db.instances.setId),
      ),
    ]);
    query.where(
      _db.sets.sessionId.isIn(sessionIds) &
          _db.instances.isDeleted.equals(false),
    );
    query.orderBy([
      OrderingTerm.asc(_db.sets.setIndex),
      OrderingTerm.asc(_db.instances.timestamp),
    ]);
    final rows = await query.get();

    final result = <String, List<Instance>>{};
    for (final row in rows) {
      final set = row.readTable(_db.sets);
      final instance = row.readTable(_db.instances);
      result.putIfAbsent(set.sessionId, () => []).add(instance);
    }
    return result;
  }

  // Phase 2B — Direct (non-stream) fetch of window states for a user.
  Future<List<MaterialisedWindowState>> getWindowStatesForUser(
      String userId) {
    return (_db.select(_db.materialisedWindowStates)
          ..where((t) => t.userId.equals(userId)))
        .get();
  }

  // Phase 2B — Direct (non-stream) fetch of subskill scores for a user.
  Future<List<MaterialisedSubskillScore>> getSubskillScoresForUser(
      String userId) {
    return (_db.select(_db.materialisedSubskillScores)
          ..where((t) => t.userId.equals(userId)))
        .get();
  }

  // Phase 2B — Direct (non-stream) fetch of skill area scores for a user.
  Future<List<MaterialisedSkillAreaScore>> getSkillAreaScoresForUser(
      String userId) {
    return (_db.select(_db.materialisedSkillAreaScores)
          ..where((t) => t.userId.equals(userId)))
        .get();
  }

  // Phase 2B — Get ALL closed sessions for a user with their drills.
  // Used by full rebuild to avoid N+1 per-subskill queries.
  Future<List<SessionWithDrill>> getAllClosedSessionsForUser(
      String userId) async {
    final query = _db.select(_db.sessions).join([
      innerJoin(
        _db.drills,
        _db.drills.drillId.equalsExp(_db.sessions.drillId),
      ),
      innerJoin(
        _db.practiceBlocks,
        _db.practiceBlocks.practiceBlockId
            .equalsExp(_db.sessions.practiceBlockId),
      ),
    ]);

    query.where(
      _db.practiceBlocks.userId.equals(userId) &
          _db.sessions.status.equalsValue(SessionStatus.closed) &
          _db.sessions.isDeleted.equals(false) &
          _db.drills.isDeleted.equals(false),
    );

    query.orderBy([
      OrderingTerm.desc(_db.sessions.completionTimestamp),
      OrderingTerm.desc(_db.sessions.sessionId),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      return SessionWithDrill(
        session: row.readTable(_db.sessions),
        drill: row.readTable(_db.drills),
      );
    }).toList();
  }

  // Phase 2B — Lightweight session fetch: only SessionID, DrillID,
  // CompletionTimestamp. Uses raw SQL to minimize ORM deserialization overhead.
  Future<List<LightSession>> getAllClosedSessionsLight(String userId) async {
    final rows = await _db.customSelect(
      'SELECT s.SessionID, s.DrillID, s.CompletionTimestamp '
      'FROM Session s '
      'INNER JOIN PracticeBlock pb ON pb.PracticeBlockID = s.PracticeBlockID '
      'WHERE pb.UserID = ? AND s.Status = ? AND s.IsDeleted = 0 '
      'ORDER BY s.CompletionTimestamp DESC, s.SessionID DESC',
      variables: [Variable.withString(userId), Variable.withString('Closed')],
    ).get();

    return rows.map((row) => LightSession(
      sessionId: row.read<String>('SessionID'),
      drillId: row.read<String>('DrillID'),
      completionTimestamp: row.readNullable<DateTime>('CompletionTimestamp'),
    )).toList();
  }

  // Phase 2B — Lightweight instance fetch: only SessionID and RawMetrics.
  // Uses raw SQL to minimize ORM deserialization overhead for large datasets.
  Future<Map<String, List<String>>> getInstanceMetricsForSessions(
      List<String> sessionIds) async {
    if (sessionIds.isEmpty) return {};

    // Chunk session IDs to stay within SQLite variable limits.
    const chunkSize = 500;
    final result = <String, List<String>>{};

    for (var i = 0; i < sessionIds.length; i += chunkSize) {
      final chunk = sessionIds.sublist(
          i, i + chunkSize > sessionIds.length ? sessionIds.length : i + chunkSize);
      final placeholders = List.filled(chunk.length, '?').join(', ');
      final variables = chunk.map((id) => Variable.withString(id)).toList();

      final rows = await _db.customSelect(
        'SELECT st.SessionID, i.RawMetrics '
        'FROM Instance i '
        'INNER JOIN "Set" st ON st.SetID = i.SetID '
        'WHERE st.SessionID IN ($placeholders) AND i.IsDeleted = 0 '
        'ORDER BY st.SetIndex, i.Timestamp',
        variables: variables,
      ).get();

      for (final row in rows) {
        final sessionId = row.read<String>('SessionID');
        final rawMetrics = row.read<String>('RawMetrics');
        result.putIfAbsent(sessionId, () => []).add(rawMetrics);
      }
    }
    return result;
  }

  // Phase 2B — Get all non-deleted drills, indexed by drillId.
  Future<Map<String, Drill>> getAllDrillsMap() async {
    final drills = await (_db.select(_db.drills)
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return {for (final d in drills) d.drillId: d};
  }

  // Phase 2B — Get all metric schemas (small table, cache-friendly).
  Future<Map<String, MetricSchema>> getAllMetricSchemas() async {
    final schemas = await _db.select(_db.metricSchemas).get();
    return {for (final s in schemas) s.metricSchemaId: s};
  }

  // Phase 2B — Get a session by ID.
  Future<Session?> getSessionById(String sessionId) {
    return (_db.select(_db.sessions)
          ..where((t) => t.sessionId.equals(sessionId)))
        .getSingleOrNull();
  }

  // Phase 2B — Update session status and fields after close.
  Future<void> updateSession(String sessionId, SessionsCompanion data) async {
    await (_db.update(_db.sessions)
          ..where((t) => t.sessionId.equals(sessionId)))
        .write(data);
  }
}

/// Join result: Session with its associated Drill.
class SessionWithDrill {
  final Session session;
  final Drill drill;

  const SessionWithDrill({required this.session, required this.drill});
}

/// Lightweight session data for bulk rebuild (avoids full ORM deserialization).
class LightSession {
  final String sessionId;
  final String drillId;
  final DateTime? completionTimestamp;

  const LightSession({
    required this.sessionId,
    required this.drillId,
    this.completionTimestamp,
  });
}
