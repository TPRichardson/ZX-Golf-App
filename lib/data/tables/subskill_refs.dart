import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S02 §2.3 — Canonical subskill reference tree.
class SubskillRefs extends Table {
  @override
  String get tableName => 'SubskillRef';

  TextColumn get subskillId => text().named('SubskillID')();
  TextColumn get skillArea =>
      text().named('SkillArea').map(const SkillAreaConverter())();
  TextColumn get name => text().named('Name')();
  IntColumn get allocation => integer().named('Allocation')();

  @override
  Set<Column> get primaryKey => {subskillId};
}
