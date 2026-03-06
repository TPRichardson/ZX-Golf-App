import 'package:drift/drift.dart';

// Matrix §8.3.3 — Matrix axis value. One value within an axis.
class MatrixAxisValues extends Table {
  @override
  String get tableName => 'MatrixAxisValue';

  TextColumn get axisValueId => text().named('AxisValueID')();
  TextColumn get matrixAxisId => text().named('MatrixAxisID')();
  TextColumn get label => text().named('Label')();
  IntColumn get sortOrder => integer().named('SortOrder')();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {axisValueId};
}
