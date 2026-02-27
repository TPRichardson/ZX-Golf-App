import 'package:drift/drift.dart';

// Spec: S08 §8.13.1 — Calendar day slot container.
class CalendarDays extends Table {
  @override
  String get tableName => 'CalendarDay';

  TextColumn get calendarDayId => text().named('CalendarDayID')();
  TextColumn get userId => text().named('UserID')();
  DateTimeColumn get date => dateTime().named('Date')();
  IntColumn get slotCapacity =>
      integer().named('SlotCapacity').withDefault(const Constant(0))();
  TextColumn get slots =>
      text().named('Slots').withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {calendarDayId};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, date},
      ];
}
