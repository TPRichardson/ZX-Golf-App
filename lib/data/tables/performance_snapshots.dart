import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// Matrix §1.9 — Performance snapshot. Point-in-time club distance calibration.
class PerformanceSnapshots extends Table {
  @override
  String get tableName => 'PerformanceSnapshot';

  TextColumn get snapshotId => text().named('SnapshotID')();
  TextColumn get userId => text().named('UserID')();
  TextColumn get matrixRunId => text().named('MatrixRunID').nullable()();
  TextColumn get matrixType => text()
      .named('MatrixType')
      .map(const MatrixTypeConverter())
      .nullable()();
  // Matrix §1.9 — One primary per user. Feeds drill target distance resolution.
  BoolColumn get isPrimary =>
      boolean().named('IsPrimary').withDefault(const Constant(false))();
  TextColumn get label => text().named('Label').nullable()();
  DateTimeColumn get snapshotTimestamp => dateTime()
      .named('SnapshotTimestamp')
      .clientDefault(() => DateTime.now())();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {snapshotId};
}
