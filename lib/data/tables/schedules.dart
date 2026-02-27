import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S08 §8.1.3 — Schedule definition table.
class Schedules extends Table {
  @override
  String get tableName => 'Schedule';

  TextColumn get scheduleId => text().named('ScheduleID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get name => text().named('Name')();
  TextColumn get applicationMode => text()
      .named('ApplicationMode')
      .map(const ScheduleAppModeConverter())();
  TextColumn get entries =>
      text().named('Entries').withDefault(const Constant('[]'))();
  TextColumn get status => text()
      .named('Status')
      .withDefault(const Constant('Active'))
      .map(const ScheduleStatusConverter())();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {scheduleId};
}
