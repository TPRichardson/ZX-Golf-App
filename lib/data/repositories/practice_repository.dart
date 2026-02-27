// ignore_for_file: unnecessary_import
import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.2 — Practice hierarchy repository.
// Manages: PracticeBlock, Session, Set (Drift entity), Instance, PracticeEntry.
//
// Note: The Drift-generated entity for the `Sets` table is `Set`, which
// conflicts with dart:core.Set. We rely on Drift's type inference via
// `_db.select(_db.sets)` and `insertReturning` so the generated Set data
// class is resolved from database.dart without needing to reference
// dart:core.Set directly in this file.
class PracticeRepository {
  final AppDatabase _db;

  PracticeRepository(this._db);

  // ---------------------------------------------------------------------------
  // PracticeBlock CRUD
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create practice block.
  Future<PracticeBlock> createPracticeBlock(
      PracticeBlocksCompanion data) async {
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
  // Session CRUD
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create session.
  Future<Session> createSession(SessionsCompanion data) async {
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
  // Set CRUD
  // Note: The Drift entity name `Set` shadows dart:core.Set. We use
  // insertReturning and select builders which let Drift infer the correct
  // generated type without explicit type annotations.
  // ---------------------------------------------------------------------------

  // TD-02 §3.5 — Create set.
  Future<void> createSet(SetsCompanion data) async {
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

  // TD-03 §3.2 — Retrieve set by primary key. Filters IsDeleted = false.
  // Returns dynamic due to Drift Set naming conflict with dart:core.Set.
  Future<dynamic> getSetById(String id) {
    return (_db.select(_db.sets)
          ..where((t) => t.setId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Sets for a specific session.
  Stream<List<dynamic>> watchSetsBySession(String sessionId) {
    return (_db.select(_db.sets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.setIndex)]))
        .watch();
  }

  // TD-03 §3.2 — Soft delete set.
  Future<void> softDeleteSet(String id) async {
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
  // Instance CRUD
  // ---------------------------------------------------------------------------

  // TD-02 §3.6 — Create instance.
  Future<Instance> createInstance(InstancesCompanion data) async {
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
  Future<Instance> updateInstance(
      String id, InstancesCompanion data) async {
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
  // PracticeEntry CRUD
  // ---------------------------------------------------------------------------

  // TD-02 §3.7 — Create practice entry.
  Future<PracticeEntry> createPracticeEntry(
      PracticeEntriesCompanion data) async {
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
}
