import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.2 — Drill definition repository.
// Manages: Drill, UserDrillAdoption, MetricSchema (read-only).
class DrillRepository {
  final AppDatabase _db;

  DrillRepository(this._db);

  // ---------------------------------------------------------------------------
  // Drill CRUD
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create drill record.
  Future<Drill> create(DrillsCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.drills).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create drill',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve drill by primary key. Filters IsDeleted = false.
  Future<Drill?> getById(String id) {
    return (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of all non-deleted drills.
  Stream<List<Drill>> watchAll() {
    return (_db.select(_db.drills)
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // Spec: S04 §4.2 — System drills (UserID IS NULL, origin = system).
  Stream<List<Drill>> watchSystemDrills() {
    return (_db.select(_db.drills)
          ..where((t) => t.userId.isNull())
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — User-specific drills (non-system).
  Stream<List<Drill>> watchUserDrills(String userId) {
    return (_db.select(_db.drills)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update drill fields. Returns updated entity.
  // Spec: TD-03 §2.1.1 — SyncWriteGate compatible: writes through transaction.
  Future<Drill> update(String id, DrillsCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.drills)
              ..where((t) => t.drillId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Drill not found after update',
            context: {'drillId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update drill',
        context: {'drillId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete: set IsDeleted = true.
  Future<void> softDelete(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.drills)
              ..where((t) => t.drillId.equals(id)))
            .write(const DrillsCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Drill not found for soft delete',
            context: {'drillId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete drill',
        context: {'drillId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UserDrillAdoption CRUD
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create adoption record.
  Future<UserDrillAdoption> createAdoption(
      UserDrillAdoptionsCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db
            .into(_db.userDrillAdoptions)
            .insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create drill adoption',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve adoption by primary key. Filters IsDeleted = false.
  Future<UserDrillAdoption?> getAdoptionById(String id) {
    return (_db.select(_db.userDrillAdoptions)
          ..where((t) => t.userDrillAdoptionId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of all non-deleted adoptions for a user.
  Stream<List<UserDrillAdoption>> watchAdoptionsByUser(String userId) {
    return (_db.select(_db.userDrillAdoptions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update adoption fields.
  Future<UserDrillAdoption> updateAdoption(
      String id, UserDrillAdoptionsCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.userDrillAdoptions)
              ..where((t) => t.userDrillAdoptionId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Drill adoption not found after update',
            context: {'userDrillAdoptionId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update drill adoption',
        context: {'userDrillAdoptionId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete adoption.
  Future<void> softDeleteAdoption(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.userDrillAdoptions)
              ..where((t) => t.userDrillAdoptionId.equals(id)))
            .write(const UserDrillAdoptionsCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Drill adoption not found for soft delete',
            context: {'userDrillAdoptionId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete drill adoption',
        context: {'userDrillAdoptionId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // MetricSchema — read-only
  // ---------------------------------------------------------------------------

  // Spec: S04 §4.3 — Metric schema lookup by ID.
  Future<MetricSchema?> getMetricSchemaById(String id) {
    return (_db.select(_db.metricSchemas)
          ..where((t) => t.metricSchemaId.equals(id)))
        .getSingleOrNull();
  }

  // Spec: S04 §4.3 — Reactive stream of all metric schemas.
  Stream<List<MetricSchema>> watchAllMetricSchemas() {
    return _db.select(_db.metricSchemas).watch();
  }
}
