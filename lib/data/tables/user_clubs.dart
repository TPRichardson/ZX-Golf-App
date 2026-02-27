import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.9 — User club table. Golf clubs in a user's bag.
class UserClubs extends Table {
  @override
  String get tableName => 'UserClub';

  TextColumn get clubId => text().named('ClubID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get clubType =>
      text().named('ClubType').map(const ClubTypeConverter())();
  TextColumn get make => text().named('Make').nullable()();
  TextColumn get model => text().named('Model').nullable()();
  RealColumn get loft => real().named('Loft').nullable()();
  TextColumn get status => text()
      .named('Status')
      .withDefault(const Constant('Active'))
      .map(const UserClubStatusConverter())();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {clubId};
}
