import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.11 — User skill area club mapping. Which clubs a user assigns to each skill area.
class UserSkillAreaClubMappings extends Table {
  @override
  String get tableName => 'UserSkillAreaClubMapping';

  TextColumn get mappingId => text().named('MappingID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get clubType =>
      text().named('ClubType').map(const ClubTypeConverter())();
  TextColumn get skillArea =>
      text().named('SkillArea').map(const SkillAreaConverter())();
  BoolColumn get isMandatory =>
      boolean().named('IsMandatory').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {mappingId};
}
