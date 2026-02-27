import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.1 — User identity & settings repository.
// TD-03 §3.2 — Standard CRUD pattern with constructor-injected AppDatabase.
class UserRepository {
  final AppDatabase _db;

  UserRepository(this._db);

  // TD-03 §3.2 — Create user record.
  Future<User> create(UsersCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.users).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create user',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve user by primary key.
  Future<User?> getById(String id) {
    return (_db.select(_db.users)..where((t) => t.userId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of all users.
  Stream<List<User>> watchAll() {
    return _db.select(_db.users).watch();
  }

  // TD-03 §3.2 — Update user fields. Returns updated entity.
  // Spec: S03 §3.2 — SyncWriteGate compatible: writes through transaction.
  Future<User> update(String id, UsersCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.users)
              ..where((t) => t.userId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'User not found after update',
            context: {'userId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update user',
        context: {'userId': id, 'error': e.toString()},
      );
    }
  }
}
