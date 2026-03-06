import 'package:drift/drift.dart';

// Matrix §8.3.5 — Matrix attempt. Single recorded shot within a cell.
class MatrixAttempts extends Table {
  @override
  String get tableName => 'MatrixAttempt';

  TextColumn get matrixAttemptId => text().named('MatrixAttemptID')();
  TextColumn get matrixCellId => text().named('MatrixCellID')();
  DateTimeColumn get attemptTimestamp =>
      dateTime().named('AttemptTimestamp').clientDefault(() => DateTime.now())();
  // All matrix types: carry and total distance.
  RealColumn get carryDistanceMeters =>
      real().named('CarryDistanceMeters').nullable()();
  RealColumn get totalDistanceMeters =>
      real().named('TotalDistanceMeters').nullable()();
  // Matrix §8.3.5 — Gapping Chart and Wedge Matrix only.
  RealColumn get leftDeviationMeters =>
      real().named('LeftDeviationMeters').nullable()();
  RealColumn get rightDeviationMeters =>
      real().named('RightDeviationMeters').nullable()();
  // Matrix §8.3.5 — Chipping Matrix only.
  RealColumn get rolloutDistanceMeters =>
      real().named('RolloutDistanceMeters').nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {matrixAttemptId};
}
