import 'package:drift/drift.dart';

// Spec: S16 §16.1.6 — Materialised overall score cache.
class MaterialisedOverallScores extends Table {
  @override
  String get tableName => 'MaterialisedOverallScore';

  TextColumn get userId => text().named('UserID')();
  RealColumn get overallScore =>
      real().named('OverallScore').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}
