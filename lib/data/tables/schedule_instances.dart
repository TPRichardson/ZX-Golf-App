import 'package:drift/drift.dart';

// Spec: S08 §8.2.5 — Instance of a schedule applied to a date range.
class ScheduleInstances extends Table {
  @override
  String get tableName => 'ScheduleInstance';

  TextColumn get scheduleInstanceId => text().named('ScheduleInstanceID')();
  TextColumn get scheduleId => text().named('ScheduleID').nullable()();
  TextColumn get userId => text().named('UserID')();
  DateTimeColumn get startDate => dateTime().named('StartDate')();
  DateTimeColumn get endDate => dateTime().named('EndDate')();
  TextColumn get ownedSlots =>
      text().named('OwnedSlots').withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {scheduleInstanceId};
}
