import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.8 — User drill adoption table. Tracks which system drills a user has adopted.
class UserDrillAdoptions extends Table {
  @override
  String get tableName => 'UserDrillAdoption';

  TextColumn get userDrillAdoptionId =>
      text().named('UserDrillAdoptionID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get drillId => text().named('DrillID')();
  TextColumn get status => text()
      .named('Status')
      .withDefault(const Constant('Active'))
      .map(const AdoptionStatusConverter())();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  BoolColumn get hasUnseenUpdate =>
      boolean().named('HasUnseenUpdate').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {userDrillAdoptionId};

  @override
  List<Set<Column>> get uniqueKeys => [
        {userId, drillId},
      ];
}
