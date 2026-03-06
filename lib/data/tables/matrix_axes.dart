import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Matrix §8.3.2 — Matrix axis table. One dimension of a matrix run.
// DEVIATION: Drift generates 'MatrixAxe' from 'MatrixAxes'. See CLAUDE.md Known Deviations.
@DataClassName('MatrixAxis')
class MatrixAxes extends Table {
  @override
  String get tableName => 'MatrixAxis';

  TextColumn get matrixAxisId => text().named('MatrixAxisID')();
  TextColumn get matrixRunId => text().named('MatrixRunID')();
  TextColumn get axisType =>
      text().named('AxisType').map(const AxisTypeConverter())();
  TextColumn get axisName => text().named('AxisName')();
  IntColumn get axisOrder => integer().named('AxisOrder')();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {matrixAxisId};
}
