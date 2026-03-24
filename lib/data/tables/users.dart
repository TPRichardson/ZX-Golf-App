import 'package:drift/drift.dart';

// TD-02 §3.1 — User profile table.
class Users extends Table {
  @override
  String get tableName => 'User';

  TextColumn get userId => text().named('UserID')();
  TextColumn get displayName => text().named('DisplayName').nullable()();
  TextColumn get email => text().named('Email').unique()();
  TextColumn get timezone =>
      text().named('Timezone').withDefault(const Constant('UTC'))();
  IntColumn get weekStartDay =>
      integer().named('WeekStartDay').withDefault(const Constant(1))();
  TextColumn get unitPreferences =>
      text().named('UnitPreferences').withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {userId};
}
