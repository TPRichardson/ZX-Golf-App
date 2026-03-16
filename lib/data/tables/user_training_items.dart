import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Training Kit item table. Equipment inventory for practice.
class UserTrainingItems extends Table {
  @override
  String get tableName => 'UserTrainingItem';

  TextColumn get itemId => text().named('ItemID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get category =>
      text().named('Category').map(const EquipmentCategoryConverter())();
  // JSON array of SkillArea dbValues, e.g. '["Driving","Putting"]'.
  TextColumn get skillAreas =>
      text().named('SkillAreas').withDefault(const Constant('[]'))();
  TextColumn get name => text().named('Name')();
  TextColumn get properties =>
      text().named('Properties').withDefault(const Constant('{}'))();
  TextColumn get linkedClubId => text().named('LinkedClubID').nullable()();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {itemId};
}
