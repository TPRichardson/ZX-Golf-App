import 'package:drift/drift.dart';

// Spec: S17 — User device registration for sync.
class UserDevices extends Table {
  @override
  String get tableName => 'UserDevice';

  TextColumn get deviceId => text().named('DeviceID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get deviceLabel => text().named('DeviceLabel').nullable()();
  DateTimeColumn get registeredAt =>
      dateTime().named('RegisteredAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get lastSyncAt =>
      dateTime().named('LastSyncAt').nullable()();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {deviceId};
}
