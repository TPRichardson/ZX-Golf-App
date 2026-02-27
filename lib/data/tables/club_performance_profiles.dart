import 'package:drift/drift.dart';

// TD-02 §3.10 — Club performance profile table. Distance and dispersion data per club.
class ClubPerformanceProfiles extends Table {
  @override
  String get tableName => 'ClubPerformanceProfile';

  TextColumn get profileId => text().named('ProfileID')();
  TextColumn get clubId => text().named('ClubID')();
  DateTimeColumn get effectiveFromDate =>
      dateTime().named('EffectiveFromDate')();
  RealColumn get carryDistance => real().named('CarryDistance').nullable()();
  RealColumn get dispersionLeft => real().named('DispersionLeft').nullable()();
  RealColumn get dispersionRight =>
      real().named('DispersionRight').nullable()();
  RealColumn get dispersionShort =>
      real().named('DispersionShort').nullable()();
  RealColumn get dispersionLong => real().named('DispersionLong').nullable()();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {profileId};
}
