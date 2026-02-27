import 'package:drift/drift.dart';

// Spec: S07 §7.9 — Append-only event log. No UpdatedAt per S06 §6.2.
class EventLogs extends Table {
  @override
  String get tableName => 'EventLog';

  TextColumn get eventLogId => text().named('EventLogID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get deviceId => text().named('DeviceID').nullable()();
  TextColumn get eventTypeId => text().named('EventTypeID')();
  DateTimeColumn get timestamp =>
      dateTime().named('Timestamp').clientDefault(() => DateTime.now())();
  TextColumn get affectedEntityIds =>
      text().named('AffectedEntityIDs').nullable()();
  TextColumn get affectedSubskills =>
      text().named('AffectedSubskills').nullable()();
  TextColumn get metadata => text().named('Metadata').nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {eventLogId};
}
