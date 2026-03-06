import 'package:drift/drift.dart';

// Matrix §8.3.4 — Matrix cell. One unique combination of axis values.
// AxisValueIDs stored as JSON array of AxisValueID strings (§8.4).
class MatrixCells extends Table {
  @override
  String get tableName => 'MatrixCell';

  TextColumn get matrixCellId => text().named('MatrixCellID')();
  TextColumn get matrixRunId => text().named('MatrixRunID')();
  // Matrix §8.4.1 — Array of AxisValueID references stored as JSON text.
  TextColumn get axisValueIds =>
      text().named('AxisValueIDs').withDefault(const Constant('[]'))();
  // Matrix §6.8 — Soft-exclusion. Never hard-deleted.
  BoolColumn get excludedFromRun =>
      boolean().named('ExcludedFromRun').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {matrixCellId};
}
