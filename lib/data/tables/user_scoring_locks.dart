import 'package:drift/drift.dart';

// Spec: S16 §16.4.3 — Per-user scoring lock for reflow serialisation.
class UserScoringLocks extends Table {
  @override
  String get tableName => 'UserScoringLock';

  TextColumn get userId => text().named('UserID')();
  BoolColumn get isLocked =>
      boolean().named('IsLocked').withDefault(const Constant(false))();
  DateTimeColumn get lockedAt => dateTime().named('LockedAt').nullable()();
  DateTimeColumn get lockExpiresAt =>
      dateTime().named('LockExpiresAt').nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
