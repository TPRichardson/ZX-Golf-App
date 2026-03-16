import 'package:drift/drift.dart';

// TD-02 §3.6 — Instance table. Individual drill attempts within a set.
class Instances extends Table {
  @override
  String get tableName => 'Instance';

  TextColumn get instanceId => text().named('InstanceID')();
  TextColumn get setId => text().named('SetID')();
  TextColumn get selectedClub => text().named('SelectedClub').nullable()();
  TextColumn get rawMetrics => text().named('RawMetrics')();
  DateTimeColumn get timestamp =>
      dateTime().named('Timestamp').clientDefault(() => DateTime.now())();
  RealColumn get resolvedTargetDistance =>
      real().named('ResolvedTargetDistance').nullable()();
  RealColumn get resolvedTargetWidth =>
      real().named('ResolvedTargetWidth').nullable()();
  RealColumn get resolvedTargetDepth =>
      real().named('ResolvedTargetDepth').nullable()();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {instanceId};
}
