import 'package:drift/drift.dart';

// Matrix §1.9 — Snapshot club. Per-club distance data within a snapshot.
class SnapshotClubs extends Table {
  @override
  String get tableName => 'SnapshotClub';

  TextColumn get snapshotClubId => text().named('SnapshotClubID')();
  TextColumn get snapshotId => text().named('SnapshotID')();
  TextColumn get clubId => text().named('ClubID')();
  RealColumn get carryDistanceMeters =>
      real().named('CarryDistanceMeters').nullable()();
  RealColumn get totalDistanceMeters =>
      real().named('TotalDistanceMeters').nullable()();
  RealColumn get dispersionLeftMeters =>
      real().named('DispersionLeftMeters').nullable()();
  RealColumn get dispersionRightMeters =>
      real().named('DispersionRightMeters').nullable()();
  // Matrix §7.8.2 — Chipping snapshots include rollout.
  RealColumn get rolloutDistanceMeters =>
      real().named('RolloutDistanceMeters').nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {snapshotClubId};
}
