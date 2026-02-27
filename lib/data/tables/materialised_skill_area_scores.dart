import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S16 §16.1.6 — Materialised skill area score cache.
class MaterialisedSkillAreaScores extends Table {
  @override
  String get tableName => 'MaterialisedSkillAreaScore';

  TextColumn get userId => text().named('UserID')();
  TextColumn get skillArea =>
      text().named('SkillArea').map(const SkillAreaConverter())();
  RealColumn get skillAreaScore =>
      real().named('SkillAreaScore').withDefault(const Constant(0))();
  IntColumn get allocation =>
      integer().named('Allocation').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId, skillArea};
}
