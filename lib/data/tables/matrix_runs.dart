import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Matrix §8.3.1 — Matrix run table. One complete or in-progress matrix session.
class MatrixRuns extends Table {
  @override
  String get tableName => 'MatrixRun';

  TextColumn get matrixRunId => text().named('MatrixRunID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get matrixType =>
      text().named('MatrixType').map(const MatrixTypeConverter())();
  IntColumn get runNumber => integer().named('RunNumber')();
  TextColumn get runState =>
      text().named('RunState').map(const RunStateConverter())();
  DateTimeColumn get startTimestamp =>
      dateTime().named('StartTimestamp').clientDefault(() => DateTime.now())();
  DateTimeColumn get endTimestamp =>
      dateTime().named('EndTimestamp').nullable()();
  IntColumn get sessionShotTarget => integer().named('SessionShotTarget')();
  TextColumn get shotOrderMode =>
      text().named('ShotOrderMode').map(const ShotOrderModeConverter())();
  BoolColumn get dispersionCaptureEnabled => boolean()
      .named('DispersionCaptureEnabled')
      .withDefault(const Constant(false))();
  TextColumn get measurementDevice =>
      text().named('MeasurementDevice').nullable()();
  TextColumn get environmentType => text()
      .named('EnvironmentType')
      .map(const EnvironmentTypeConverter())
      .nullable()();
  TextColumn get surfaceType => text()
      .named('SurfaceType')
      .map(const SurfaceTypeConverter())
      .nullable()();
  // Matrix §5.5 — Green speed (6.0–15.0 in 0.5 steps). Chipping only.
  RealColumn get greenSpeed => real().named('GreenSpeed').nullable()();
  // Matrix §5.5 — Green firmness. Chipping only.
  TextColumn get greenFirmness => text()
      .named('GreenFirmness')
      .map(const GreenFirmnessConverter())
      .nullable()();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {matrixRunId};
}
