// ignore_for_file: unnecessary_import
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';

// TD-03 §3.3.3 — Practice hierarchy repository.
// Phase 4: 18 business methods with state machine guards,
// queue management, session lifecycle, and reflow triggers.
//
// Note: The Drift-generated entity for the `Sets` table is `PracticeSet`
// (via @DataClassName). See CLAUDE.md Known Deviations.

/// TD-03 §3.3.3 — Composite: PracticeBlock + its entries with drill info.
class PracticeBlockWithEntries {
  final PracticeBlock practiceBlock;
  final List<PracticeEntryWithDrill> entries;

  const PracticeBlockWithEntries({
    required this.practiceBlock,
    required this.entries,
  });
}

/// TD-03 §3.3.3 — Composite: PracticeEntry + associated Drill + optional Session.
class PracticeEntryWithDrill {
  final PracticeEntry entry;
  final Drill drill;
  final Session? session;

  const PracticeEntryWithDrill({
    required this.entry,
    required this.drill,
    this.session,
  });
}

class PracticeRepository {
  final AppDatabase _db;
  final ReflowEngine _reflowEngine;
  final EventLogRepository _eventLogRepo;
  final SyncWriteGate _gate;

  static const _uuid = Uuid();

  PracticeRepository(this._db, this._reflowEngine, this._eventLogRepo, this._gate);

  // ---------------------------------------------------------------------------
  // PracticeBlock CRUD (retained from Phase 1)
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create practice block.
  Future<PracticeBlock> createPracticeBlockRaw(
      PracticeBlocksCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.practiceBlocks).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create practice block',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve practice block by primary key.
  Future<PracticeBlock?> getPracticeBlockById(String id) {
    return (_db.select(_db.practiceBlocks)
          ..where((t) => t.practiceBlockId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of non-deleted practice blocks.
  Stream<List<PracticeBlock>> watchAllPracticeBlocks() {
    return (_db.select(_db.practiceBlocks)
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Practice blocks for a specific user.
  Stream<List<PracticeBlock>> watchPracticeBlocksByUser(String userId) {
    return (_db.select(_db.practiceBlocks)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update practice block fields.
  // Spec: TD-03 §2.1.1 — SyncWriteGate compatible: writes through transaction.
  Future<PracticeBlock> updatePracticeBlock(
      String id, PracticeBlocksCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.practiceBlocks)
              ..where((t) => t.practiceBlockId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Practice block not found after update',
            context: {'practiceBlockId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update practice block',
        context: {'practiceBlockId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete practice block.
  Future<void> softDeletePracticeBlock(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.practiceBlocks)
              ..where((t) => t.practiceBlockId.equals(id)))
            .write(const PracticeBlocksCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Practice block not found for soft delete',
            context: {'practiceBlockId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete practice block',
        context: {'practiceBlockId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Session CRUD (retained from Phase 1)
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create session.
  Future<Session> createSession(SessionsCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.sessions).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create session',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve session by primary key.
  Future<Session?> getSessionById(String id) {
    return (_db.select(_db.sessions)
          ..where((t) => t.sessionId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Sessions for a specific practice block.
  Stream<List<Session>> watchSessionsByBlock(String practiceBlockId) {
    return (_db.select(_db.sessions)
          ..where((t) => t.practiceBlockId.equals(practiceBlockId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — All non-deleted sessions.
  Stream<List<Session>> watchAllSessions() {
    return (_db.select(_db.sessions)
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update session fields.
  Future<Session> updateSession(String id, SessionsCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.sessions)
              ..where((t) => t.sessionId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Session not found after update',
            context: {'sessionId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update session',
        context: {'sessionId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete session.
  Future<void> softDeleteSession(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.sessions)
              ..where((t) => t.sessionId.equals(id)))
            .write(const SessionsCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Session not found for soft delete',
            context: {'sessionId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete session',
        context: {'sessionId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete (discard) session. Permanent removal.
  Future<void> hardDeleteSession(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.sessions)
              ..where((t) => t.sessionId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Session not found for hard delete',
            context: {'sessionId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete session',
        context: {'sessionId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Set CRUD (retained from Phase 1)
  // DEVIATION: @DataClassName('PracticeSet'). See CLAUDE.md Known Deviations.
  // ---------------------------------------------------------------------------

  // TD-02 §3.5 — Create set.
  Future<PracticeSet> createSetReturning(SetsCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.sets).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create set',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-02 §3.5 — Create set (void return, Phase 1 compat).
  Future<void> createSet(SetsCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        await _db.into(_db.sets).insert(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create set',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve set by primary key.
  Future<PracticeSet?> getSetById(String id) {
    return (_db.select(_db.sets)
          ..where((t) => t.setId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Sets for a specific session.
  Stream<List<PracticeSet>> watchSetsBySession(String sessionId) {
    return (_db.select(_db.sets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.setIndex)]))
        .watch();
  }

  // TD-03 §3.2 — Soft delete set.
  Future<void> softDeleteSet(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.sets)
              ..where((t) => t.setId.equals(id)))
            .write(const SetsCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Set not found for soft delete',
            context: {'setId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete set',
        context: {'setId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Instance CRUD (retained from Phase 1)
  // ---------------------------------------------------------------------------

  // TD-02 §3.6 — Create instance.
  Future<Instance> createInstance(InstancesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.instances).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create instance',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve instance by primary key. Filters IsDeleted = false.
  Future<Instance?> getInstanceById(String id) {
    return (_db.select(_db.instances)
          ..where((t) => t.instanceId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Instances for a specific set.
  Stream<List<Instance>> watchInstancesBySet(String setId) {
    return (_db.select(_db.instances)
          ..where((t) => t.setId.equals(setId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .watch();
  }

  // TD-03 §3.2 — Update instance fields.
  Future<Instance> updateInstanceRaw(
      String id, InstancesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.instances)
              ..where((t) => t.instanceId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Instance not found after update',
            context: {'instanceId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update instance',
        context: {'instanceId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete instance.
  Future<void> softDeleteInstance(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.instances)
              ..where((t) => t.instanceId.equals(id)))
            .write(const InstancesCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Instance not found for soft delete',
            context: {'instanceId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete instance',
        context: {'instanceId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete instance. Permanent removal.
  Future<void> hardDeleteInstance(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.instances)
              ..where((t) => t.instanceId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Instance not found for hard delete',
            context: {'instanceId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete instance',
        context: {'instanceId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PracticeEntry CRUD (retained from Phase 1)
  // ---------------------------------------------------------------------------

  // TD-02 §3.7 — Create practice entry.
  Future<PracticeEntry> createPracticeEntry(
      PracticeEntriesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.practiceEntries).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create practice entry',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve practice entry by primary key.
  Future<PracticeEntry?> getPracticeEntryById(String id) {
    return (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceEntryId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Entries for a specific practice block, ordered by position.
  Stream<List<PracticeEntry>> watchEntriesByBlock(String practiceBlockId) {
    return (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(practiceBlockId))
          ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
        .watch();
  }

  // TD-03 §3.2 — Update practice entry fields.
  Future<PracticeEntry> updatePracticeEntry(
      String id, PracticeEntriesCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.practiceEntries)
              ..where((t) => t.practiceEntryId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Practice entry not found after update',
            context: {'practiceEntryId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update practice entry',
        context: {'practiceEntryId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete practice entry. Permanent removal.
  Future<void> hardDeletePracticeEntry(String id) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.practiceEntries)
              ..where((t) => t.practiceEntryId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Practice entry not found for hard delete',
            context: {'practiceEntryId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete practice entry',
        context: {'practiceEntryId': id, 'error': e.toString()},
      );
    }
  }

  // ===========================================================================
  // Phase 4 — Business Methods (TD-03 §3.3.3)
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // #1: createPracticeBlock — S13 §13.2
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #1 — Create a new PracticeBlock.
  /// Guard: no existing active PB for this user.
  Future<PracticeBlock> createPracticeBlock(
    String userId, {
    List<String>? initialDrillIds,
  }) async {
    await _gate.awaitGateRelease();
    // Guard: no active practice block for user.
    final existing = await _findActivePracticeBlock(userId);
    if (existing != null) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'User already has an active practice block',
        context: {
          'userId': userId,
          'activePracticeBlockId': existing.practiceBlockId,
        },
      );
    }

    final pbId = _uuid.v4();
    final pb = await createPracticeBlockRaw(PracticeBlocksCompanion.insert(
      practiceBlockId: pbId,
      userId: userId,
      drillOrder: Value(jsonEncode(initialDrillIds ?? [])),
    ));

    // Add initial drills as pending entries.
    if (initialDrillIds != null) {
      for (var i = 0; i < initialDrillIds.length; i++) {
        await createPracticeEntry(PracticeEntriesCompanion.insert(
          practiceEntryId: _uuid.v4(),
          practiceBlockId: pbId,
          drillId: initialDrillIds[i],
          positionIndex: i,
        ));
      }
    }

    return pb;
  }

  // ---------------------------------------------------------------------------
  // #2: watchPracticeBlock — S13 §13.3
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #2 — Composite stream: PB + entries + drill info.
  Stream<PracticeBlockWithEntries?> watchPracticeBlock(String pbId) {
    return watchEntriesByBlock(pbId).asyncMap((entries) async {
      final pb = await getPracticeBlockById(pbId);
      if (pb == null) return null;

      final enriched = <PracticeEntryWithDrill>[];
      for (final entry in entries) {
        final drill = await (_db.select(_db.drills)
              ..where((t) => t.drillId.equals(entry.drillId)))
            .getSingleOrNull();
        if (drill == null) continue;

        Session? session;
        if (entry.sessionId != null) {
          session = await getSessionById(entry.sessionId!);
        }
        enriched.add(PracticeEntryWithDrill(
          entry: entry,
          drill: drill,
          session: session,
        ));
      }

      return PracticeBlockWithEntries(
        practiceBlock: pb,
        entries: enriched,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // #3: getActivePracticeBlock — S13 §13.2
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #3 — Stream of active PB for user (no endTimestamp, not deleted).
  Stream<PracticeBlock?> getActivePracticeBlock(String userId) {
    return (_db.select(_db.practiceBlocks)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.endTimestamp.isNull())
          ..where((t) => t.isDeleted.equals(false)))
        .watchSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // #4: addDrillToQueue — S13 §13.4
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #4 — Add a drill to the practice queue.
  Future<PracticeEntry> addDrillToQueue(
    String pbId,
    String drillId, {
    int? position,
  }) async {
    await _gate.awaitGateRelease();
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId))
          ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
        .get();

    final targetPosition = position ?? entries.length;
    final entryId = _uuid.v4();

    // Shift entries at or after target position.
    if (targetPosition < entries.length) {
      await _db.transaction(() async {
        for (final e in entries) {
          if (e.positionIndex >= targetPosition) {
            await (_db.update(_db.practiceEntries)
                  ..where(
                      (t) => t.practiceEntryId.equals(e.practiceEntryId)))
                .write(PracticeEntriesCompanion(
              positionIndex: Value(e.positionIndex + 1),
              updatedAt: Value(DateTime.now()),
            ));
          }
        }
      });
    }

    return createPracticeEntry(PracticeEntriesCompanion.insert(
      practiceEntryId: entryId,
      practiceBlockId: pbId,
      drillId: drillId,
      positionIndex: targetPosition,
    ));
  }

  // ---------------------------------------------------------------------------
  // #5: removePendingEntry — TD-04 §2.1
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #5 — Remove a pending drill entry.
  /// Guard: must be PendingDrill.
  Future<void> removePendingEntry(String entryId) async {
    await _gate.awaitGateRelease();
    final entry = await _requireEntry(entryId);
    if (entry.entryType != PracticeEntryType.pendingDrill) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only remove PendingDrill entries',
        context: {
          'entryId': entryId,
          'currentType': entry.entryType.dbValue,
        },
      );
    }

    await hardDeletePracticeEntry(entryId);
    await _reindexEntries(entry.practiceBlockId);
  }

  // ---------------------------------------------------------------------------
  // #6: removeCompletedEntry — TD-04 §2.1
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #6 — Remove a completed session entry.
  /// Soft-delete session + reflow + EventLog + hard-delete entry.
  /// Blocked if an ActiveSession exists in the block.
  Future<void> removeCompletedEntry(String entryId, String userId) async {
    await _gate.awaitGateRelease();
    final entry = await _requireEntry(entryId);
    if (entry.entryType != PracticeEntryType.completedSession) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only remove CompletedSession entries',
        context: {
          'entryId': entryId,
          'currentType': entry.entryType.dbValue,
        },
      );
    }

    // Block if an ActiveSession exists in the block.
    final hasActive = await _hasActiveSession(entry.practiceBlockId);
    if (hasActive) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Cannot remove completed entry while an active session exists',
        context: {'entryId': entryId},
      );
    }

    // Soft-delete the session.
    if (entry.sessionId != null) {
      await softDeleteSession(entry.sessionId!);

      // Trigger full reflow for session deletion.
      await _reflowEngine.executeReflow(ReflowTrigger(
        type: ReflowTriggerType.sessionDeletion,
        userId: userId,
        affectedSubskillIds: await _getSubskillsForSession(entry.sessionId!),
        sessionId: entry.sessionId,
      ));

      // EventLog.
      await _eventLogRepo.create(EventLogsCompanion.insert(
        eventLogId: _uuid.v4(),
        userId: userId,
        eventTypeId: 'SessionDeletion',
        affectedEntityIds: Value(jsonEncode([entry.sessionId])),
      ));
    }

    // Hard-delete the entry.
    await hardDeletePracticeEntry(entryId);
    await _reindexEntries(entry.practiceBlockId);
  }

  // ---------------------------------------------------------------------------
  // #7: reorderQueue — S13 §13.4.2
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #7 — Reorder queue entries.
  /// ActiveSession position is locked (cannot be moved).
  Future<void> reorderQueue(
      String pbId, List<String> orderedEntryIds) async {
    await _gate.awaitGateRelease();
    // Verify all entry IDs belong to the practice block.
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId)))
        .get();
    final entryMap = {for (final e in entries) e.practiceEntryId: e};

    for (final id in orderedEntryIds) {
      if (!entryMap.containsKey(id)) {
        throw ValidationException(
          code: ValidationException.requiredField,
          message: 'Entry $id does not belong to practice block $pbId',
          context: {'entryId': id, 'practiceBlockId': pbId},
        );
      }
    }

    // Two-pass reorder to avoid UNIQUE constraint violations on
    // {PracticeBlockID, PositionIndex}: first set all to negative temp values,
    // then assign final positions.
    await _db.transaction(() async {
      for (var i = 0; i < orderedEntryIds.length; i++) {
        await (_db.update(_db.practiceEntries)
              ..where(
                  (t) => t.practiceEntryId.equals(orderedEntryIds[i])))
            .write(PracticeEntriesCompanion(
          positionIndex: Value(-(i + 1)),
          updatedAt: Value(DateTime.now()),
        ));
      }
      for (var i = 0; i < orderedEntryIds.length; i++) {
        await (_db.update(_db.practiceEntries)
              ..where(
                  (t) => t.practiceEntryId.equals(orderedEntryIds[i])))
            .write(PracticeEntriesCompanion(
          positionIndex: Value(i),
        ));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // #8: duplicateEntry — S13 §13.4.3
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #8 — Duplicate an entry (creates PendingDrill after source).
  Future<PracticeEntry> duplicateEntry(String entryId) async {
    await _gate.awaitGateRelease();
    final source = await _requireEntry(entryId);
    return addDrillToQueue(
      source.practiceBlockId,
      source.drillId,
      position: source.positionIndex + 1,
    );
  }

  // ---------------------------------------------------------------------------
  // #9: startSession — TD-04 §2.2, S13 §13.5
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #9 — Start a session for a practice entry.
  /// Guard: no other ActiveSession in block, drill not deleted, entry is PendingDrill.
  Future<Session> startSession(String entryId, String userId) async {
    await _gate.awaitGateRelease();
    final entry = await _requireEntry(entryId);

    // Guard: must be PendingDrill.
    if (entry.entryType != PracticeEntryType.pendingDrill) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only start session on PendingDrill entries',
        context: {
          'entryId': entryId,
          'currentType': entry.entryType.dbValue,
        },
      );
    }

    // Guard: no existing ActiveSession in this block.
    final hasActive = await _hasActiveSession(entry.practiceBlockId);
    if (hasActive) {
      throw ValidationException(
        code: ValidationException.singleActiveSession,
        message: 'Only one active session is allowed per practice block',
        context: {'practiceBlockId': entry.practiceBlockId},
      );
    }

    // Guard: drill must exist and not be deleted.
    final drill = await (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(entry.drillId)))
        .getSingleOrNull();
    if (drill == null || drill.isDeleted) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Drill not found or deleted',
        context: {'drillId': entry.drillId},
      );
    }

    final sessionId = _uuid.v4();
    final pb = await getPracticeBlockById(entry.practiceBlockId);

    // Create Session.
    final session = await createSession(SessionsCompanion.insert(
      sessionId: sessionId,
      drillId: entry.drillId,
      practiceBlockId: pb!.practiceBlockId,
    ));

    // Create first Set (index 0).
    final setId = _uuid.v4();
    await createSetReturning(SetsCompanion.insert(
      setId: setId,
      sessionId: sessionId,
      setIndex: 0,
    ));

    // Update entry: PendingDrill → ActiveSession, attach sessionId.
    await updatePracticeEntry(
      entryId,
      PracticeEntriesCompanion(
        entryType: const Value(PracticeEntryType.activeSession),
        sessionId: Value(sessionId),
        updatedAt: Value(DateTime.now()),
      ),
    );

    return session;
  }

  // ---------------------------------------------------------------------------
  // #10: discardSession — TD-04 §2.2
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #10 — Discard an active session.
  /// Hard-delete Session/Sets/Instances, reset entry to PendingDrill.
  Future<void> discardSession(String entryId) async {
    await _gate.awaitGateRelease();
    final entry = await _requireEntry(entryId);
    if (entry.entryType != PracticeEntryType.activeSession) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only discard ActiveSession entries',
        context: {
          'entryId': entryId,
          'currentType': entry.entryType.dbValue,
        },
      );
    }
    if (entry.sessionId == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Entry has no session to discard',
        context: {'entryId': entryId},
      );
    }

    // Hard-delete all instances in this session.
    final sets = await (_db.select(_db.sets)
          ..where((t) => t.sessionId.equals(entry.sessionId!)))
        .get();
    await _db.transaction(() async {
      for (final s in sets) {
        await (_db.delete(_db.instances)
              ..where((t) => t.setId.equals(s.setId)))
            .go();
      }
      // Hard-delete all sets.
      await (_db.delete(_db.sets)
            ..where((t) => t.sessionId.equals(entry.sessionId!)))
          .go();
      // Hard-delete the session.
      await (_db.delete(_db.sessions)
            ..where((t) => t.sessionId.equals(entry.sessionId!)))
          .go();
    });

    // Reset entry to PendingDrill.
    await updatePracticeEntry(
      entryId,
      PracticeEntriesCompanion(
        entryType: const Value(PracticeEntryType.pendingDrill),
        sessionId: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // #11: restartSession — alias for discardSession
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #11 — Restart = discard + can immediately start again.
  Future<void> restartSession(String entryId) async {
    await discardSession(entryId);
  }

  // ---------------------------------------------------------------------------
  // #12: logInstance — S04, S13 §13.6
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #12 — Log a single instance in a set.
  Future<Instance> logInstance(
    String setId,
    InstancesCompanion data,
    String sessionId,
  ) async {
    await _gate.awaitGateRelease();
    // Verify session is Active.
    final session = await getSessionById(sessionId);
    if (session == null || session.status != SessionStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Cannot log instance: session is not active',
        context: {'sessionId': sessionId},
      );
    }

    // Verify set belongs to session.
    final set = await getSetById(setId);
    if (set == null || set.sessionId != sessionId) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Set does not belong to session',
        context: {'setId': setId, 'sessionId': sessionId},
      );
    }

    final instanceId = _uuid.v4();
    return createInstance(data.copyWith(
      instanceId: Value(instanceId),
      setId: Value(setId),
    ));
  }

  // ---------------------------------------------------------------------------
  // #13: advanceSet — S13 §13.7
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #13 — Create the next set with incremented index.
  Future<PracticeSet> advanceSet(String sessionId) async {
    await _gate.awaitGateRelease();
    final session = await getSessionById(sessionId);
    if (session == null || session.status != SessionStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Cannot advance set: session is not active',
        context: {'sessionId': sessionId},
      );
    }

    // Find current max set index.
    final sets = await (_db.select(_db.sets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.setIndex)]))
        .get();

    final nextIndex = sets.isEmpty ? 0 : sets.first.setIndex + 1;
    final setId = _uuid.v4();

    return createSetReturning(SetsCompanion.insert(
      setId: setId,
      sessionId: sessionId,
      setIndex: nextIndex,
    ));
  }

  // ---------------------------------------------------------------------------
  // #14: endSession — TD-04 §2.2, TD-03 §4.4
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #14 — End a session: calls ReflowEngine.closeSession().
  Future<SessionScoringResult> endSession(
    String sessionId,
    String userId,
  ) async {
    await _gate.awaitGateRelease();
    final session = await getSessionById(sessionId);
    if (session == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Session not found',
        context: {'sessionId': sessionId},
      );
    }
    if (session.status != SessionStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Can only end active sessions',
        context: {
          'sessionId': sessionId,
          'currentStatus': session.status.dbValue,
        },
      );
    }

    // Delegate to ReflowEngine for full scoring pipeline.
    // Spec: TD-03 §4.4 — Runs outside UserScoringLock.
    final result = await _reflowEngine.closeSession(sessionId, userId);

    // Update entry: ActiveSession → CompletedSession.
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.sessionId.equals(sessionId)))
        .get();
    for (final entry in entries) {
      await updatePracticeEntry(
        entry.practiceEntryId,
        PracticeEntriesCompanion(
          entryType: const Value(PracticeEntryType.completedSession),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // #15: endPracticeBlock — S13 §13.10
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #15 — End a practice block.
  /// Guard: no ActiveSession. Hard-delete pending entries.
  /// Discard if 0 completed sessions, else close normally.
  Future<void> endPracticeBlock(String pbId, String userId) async {
    await _gate.awaitGateRelease();
    final pb = await getPracticeBlockById(pbId);
    if (pb == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Practice block not found',
        context: {'practiceBlockId': pbId},
      );
    }
    if (pb.endTimestamp != null) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Practice block already ended',
        context: {'practiceBlockId': pbId},
      );
    }

    // Guard: no ActiveSession.
    final hasActive = await _hasActiveSession(pbId);
    if (hasActive) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Cannot end practice block with active session',
        context: {'practiceBlockId': pbId},
      );
    }

    // Get all entries.
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId)))
        .get();

    // Hard-delete pending entries.
    final pendingEntries = entries
        .where((e) => e.entryType == PracticeEntryType.pendingDrill)
        .toList();
    for (final entry in pendingEntries) {
      await hardDeletePracticeEntry(entry.practiceEntryId);
    }

    // Count completed sessions.
    final completedCount = entries
        .where((e) => e.entryType == PracticeEntryType.completedSession)
        .length;

    if (completedCount == 0) {
      // Discard: soft-delete the practice block.
      await softDeletePracticeBlock(pbId);
    } else {
      // Close normally.
      await updatePracticeBlock(
        pbId,
        PracticeBlocksCompanion(
          endTimestamp: Value(DateTime.now()),
          closureType: const Value(ClosureType.manual),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // #16: saveQueueAsRoutine — Phase 5 stub
  // ---------------------------------------------------------------------------

  /// Phase 5 stub — replaced in Phase 5 (routine management).
  Future<void> saveQueueAsRoutine(String pbId, String name) async {
    throw UnimplementedError(
      'saveQueueAsRoutine is a Phase 5 stub',
    );
  }

  // ---------------------------------------------------------------------------
  // #17: updateInstance (business) — post-close edit → reflow
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #17 — Update an instance's data.
  /// Post-close edit on Closed Session triggers reflow via instanceEdit trigger.
  /// Active Session edits do NOT trigger reflow.
  Future<Instance> updateInstance(
    String instanceId,
    InstancesCompanion data,
    String userId,
  ) async {
    await _gate.awaitGateRelease();
    final instance = await getInstanceById(instanceId);
    if (instance == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Instance not found',
        context: {'instanceId': instanceId},
      );
    }

    // Find the session for this instance.
    final set = await getSetById(instance.setId);
    if (set == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Set not found for instance',
        context: {'setId': instance.setId},
      );
    }
    final session = await getSessionById(set.sessionId);

    final updated = await updateInstanceRaw(
      instanceId,
      data.copyWith(updatedAt: Value(DateTime.now())),
    );

    // Post-close edit triggers reflow.
    if (session != null && session.status == SessionStatus.closed) {
      final subskills = await _getSubskillsForSession(session.sessionId);
      if (subskills.isNotEmpty) {
        await _reflowEngine.executeReflow(ReflowTrigger(
          type: ReflowTriggerType.instanceEdit,
          userId: userId,
          affectedSubskillIds: subskills,
          sessionId: session.sessionId,
        ));
      }
    }

    return updated;
  }

  // ---------------------------------------------------------------------------
  // #18: deleteInstance (business) — post-close delete → reflow
  // ---------------------------------------------------------------------------

  /// TD-03 §3.3.3 #18 — Soft-delete an instance.
  /// Post-close deletion on Closed Session triggers reflow.
  Future<void> deleteInstance(String instanceId, String userId) async {
    await _gate.awaitGateRelease();
    final instance = await getInstanceById(instanceId);
    if (instance == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Instance not found',
        context: {'instanceId': instanceId},
      );
    }

    // Find the session for this instance.
    final set = await getSetById(instance.setId);
    if (set == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Set not found for instance',
        context: {'setId': instance.setId},
      );
    }
    final session = await getSessionById(set.sessionId);

    await softDeleteInstance(instanceId);

    // Post-close deletion triggers reflow.
    if (session != null && session.status == SessionStatus.closed) {
      final subskills = await _getSubskillsForSession(session.sessionId);
      if (subskills.isNotEmpty) {
        await _reflowEngine.executeReflow(ReflowTrigger(
          type: ReflowTriggerType.instanceDeletion,
          userId: userId,
          affectedSubskillIds: subskills,
          sessionId: session.sessionId,
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Additional query helpers for Phase 4
  // ---------------------------------------------------------------------------

  /// Find a practice entry by its sessionId.
  Future<PracticeEntry?> getPracticeEntryBySessionId(String sessionId) {
    return (_db.select(_db.practiceEntries)
          ..where((t) => t.sessionId.equals(sessionId)))
        .getSingleOrNull();
  }

  /// Get all practice entries for a block.
  Future<List<PracticeEntry>> getPracticeEntriesByBlock(String pbId) {
    return (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId)))
        .get();
  }

  /// Get the active session in a practice block (if any).
  Future<Session?> getActiveSessionInBlock(String pbId) async {
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId))
          ..where(
              (t) => t.entryType.equalsValue(PracticeEntryType.activeSession)))
        .get();
    if (entries.isEmpty) return null;
    final entry = entries.first;
    if (entry.sessionId == null) return null;
    return getSessionById(entry.sessionId!);
  }

  /// Get the current (latest) set for a session.
  Future<PracticeSet?> getCurrentSet(String sessionId) async {
    final sets = await (_db.select(_db.sets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.setIndex)]))
        .get();
    return sets.isEmpty ? null : sets.first;
  }

  /// Count non-deleted instances in a set.
  Future<int> getInstanceCount(String setId) async {
    final instances = await (_db.select(_db.instances)
          ..where((t) => t.setId.equals(setId))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return instances.length;
  }

  /// Count non-deleted sets in a session.
  Future<int> getSetCount(String sessionId) async {
    final sets = await (_db.select(_db.sets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.isDeleted.equals(false)))
        .get();
    return sets.length;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<PracticeBlock?> _findActivePracticeBlock(String userId) async {
    return (_db.select(_db.practiceBlocks)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.endTimestamp.isNull())
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<bool> _hasActiveSession(String pbId) async {
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId))
          ..where(
              (t) => t.entryType.equalsValue(PracticeEntryType.activeSession)))
        .get();
    return entries.isNotEmpty;
  }

  Future<PracticeEntry> _requireEntry(String entryId) async {
    final entry = await getPracticeEntryById(entryId);
    if (entry == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Practice entry not found',
        context: {'entryId': entryId},
      );
    }
    return entry;
  }

  Future<void> _reindexEntries(String pbId) async {
    final entries = await (_db.select(_db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pbId))
          ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
        .get();

    await _db.transaction(() async {
      for (var i = 0; i < entries.length; i++) {
        if (entries[i].positionIndex != i) {
          await (_db.update(_db.practiceEntries)
                ..where((t) =>
                    t.practiceEntryId.equals(entries[i].practiceEntryId)))
              .write(PracticeEntriesCompanion(
            positionIndex: Value(i),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }
    });
  }

  Future<Set<String>> _getSubskillsForSession(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return {};
    final drill = await (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(session.drillId)))
        .getSingleOrNull();
    if (drill == null) return {};
    return _parseSubskillMapping(drill.subskillMapping);
  }

  Set<String> _parseSubskillMapping(String json) {
    if (json == '[]' || json.isEmpty) return {};
    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => e as String).toSet();
  }

  // ---------------------------------------------------------------------------
  // Integrity flag suppression — S11 §11.6
  // ---------------------------------------------------------------------------

  /// S11 §11.6 — Suppress integrity flag: user reviewed and confirmed data.
  Future<void> suppressIntegrityFlag(String sessionId, String userId) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        await (_db.update(_db.sessions)
              ..where((t) => t.sessionId.equals(sessionId)))
            .write(SessionsCompanion(
          integritySuppressed: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
      });
      // S11 §11.6 — Log integrity flag clearance event.
      await _eventLogRepo.create(EventLogsCompanion.insert(
        eventLogId: _uuid.v4(),
        userId: userId,
        eventTypeId: 'IntegrityFlagCleared',
        affectedEntityIds: Value(jsonEncode([sessionId])),
        metadata: const Value('{"action":"user_suppressed"}'),
      ));
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to suppress integrity flag',
        context: {'sessionId': sessionId, 'error': e.toString()},
      );
    }
  }
}
