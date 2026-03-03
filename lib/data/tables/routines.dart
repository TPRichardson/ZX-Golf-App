import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S08 §8.1.2 — Routine definition table.
class Routines extends Table {
  @override
  String get tableName => 'Routine';

  TextColumn get routineId => text().named('RoutineID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get name => text().named('Name')();
  TextColumn get entries =>
      text().named('Entries').withDefault(const Constant('[]'))();
  TextColumn get status => text()
      .named('Status')
      .withDefault(const Constant('Active'))
      .map(const RoutineStatusConverter())();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();
  // 5F — MRU sort: tracks when routine was last applied/instantiated.
  DateTimeColumn get lastAppliedAt =>
      dateTime().named('LastAppliedAt').nullable()();

  @override
  Set<Column> get primaryKey => {routineId};
}
