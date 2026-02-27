import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S16 §16.1.6 — Materialised subskill score cache.
class MaterialisedSubskillScores extends Table {
  @override
  String get tableName => 'MaterialisedSubskillScore';

  TextColumn get userId => text().named('UserID')();
  TextColumn get skillArea =>
      text().named('SkillArea').map(const SkillAreaConverter())();
  TextColumn get subskill => text().named('Subskill')();
  RealColumn get transitionAverage =>
      real().named('TransitionAverage').withDefault(const Constant(0))();
  RealColumn get pressureAverage =>
      real().named('PressureAverage').withDefault(const Constant(0))();
  RealColumn get weightedAverage =>
      real().named('WeightedAverage').withDefault(const Constant(0))();
  RealColumn get subskillPoints =>
      real().named('SubskillPoints').withDefault(const Constant(0))();
  IntColumn get allocation =>
      integer().named('Allocation').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, skillArea, subskill};
}
