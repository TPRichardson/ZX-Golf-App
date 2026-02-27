import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S16 §16.1.6 — Materialised scoring window state cache.
class MaterialisedWindowStates extends Table {
  @override
  String get tableName => 'MaterialisedWindowState';

  TextColumn get userId => text().named('UserID')();
  TextColumn get skillArea =>
      text().named('SkillArea').map(const SkillAreaConverter())();
  TextColumn get subskill => text().named('Subskill')();
  TextColumn get practiceType =>
      text().named('PracticeType').map(const DrillTypeConverter())();
  TextColumn get entries =>
      text().named('Entries').withDefault(const Constant('[]'))();
  RealColumn get totalOccupancy =>
      real().named('TotalOccupancy').withDefault(const Constant(0))();
  RealColumn get weightedSum =>
      real().named('WeightedSum').withDefault(const Constant(0))();
  RealColumn get windowAverage =>
      real().named('WindowAverage').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, skillArea, subskill, practiceType};
}
