import 'package:drift/drift.dart';

// Spec: S08 §8.2.4 — Instance of a routine applied to a calendar day.
class RoutineInstances extends Table {
  @override
  String get tableName => 'RoutineInstance';

  TextColumn get routineInstanceId => text().named('RoutineInstanceID')();
  TextColumn get routineId => text().named('RoutineID').nullable()();
  TextColumn get userId => text().named('UserID')();
  DateTimeColumn get calendarDayDate => dateTime().named('CalendarDayDate')();
  TextColumn get ownedSlots =>
      text().named('OwnedSlots').withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {routineInstanceId};
}
