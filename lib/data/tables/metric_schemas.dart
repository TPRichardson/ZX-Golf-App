import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Spec: S04 §4.3 — Metric schema definitions.
class MetricSchemas extends Table {
  @override
  String get tableName => 'MetricSchema';

  TextColumn get metricSchemaId => text().named('MetricSchemaID')();
  TextColumn get name => text().named('Name')();
  TextColumn get inputMode =>
      text().named('InputMode').map(const InputModeConverter())();
  RealColumn get hardMinInput => real().named('HardMinInput').nullable()();
  RealColumn get hardMaxInput => real().named('HardMaxInput').nullable()();
  TextColumn get validationRules =>
      text().named('ValidationRules').nullable()();
  TextColumn get scoringAdapterBinding =>
      text().named('ScoringAdapterBinding')();

  @override
  Set<Column> get primaryKey => {metricSchemaId};
}
