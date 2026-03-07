import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/converters.dart';

// TD-02 §3.2 — Drill definition table. Covers system and user-custom drills.
class Drills extends Table {
  @override
  String get tableName => 'Drill';

  TextColumn get drillId => text().named('DrillID')();
  TextColumn get userId => text().named('UserID').nullable()();
  TextColumn get name => text().named('Name')();
  TextColumn get skillArea =>
      text().named('SkillArea').map(const SkillAreaConverter())();
  TextColumn get drillType =>
      text().named('DrillType').map(const DrillTypeConverter())();
  TextColumn get scoringMode => text()
      .named('ScoringMode')
      .map(const ScoringModeConverter())
      .nullable()();
  TextColumn get inputMode =>
      text().named('InputMode').map(const InputModeConverter())();
  TextColumn get metricSchemaId => text().named('MetricSchemaID')();
  TextColumn get gridType =>
      text().named('GridType').map(const GridTypeConverter()).nullable()();
  TextColumn get subskillMapping =>
      text().named('SubskillMapping').withDefault(const Constant('[]'))();
  TextColumn get clubSelectionMode => text()
      .named('ClubSelectionMode')
      .map(const ClubSelectionModeConverter())
      .nullable()();
  TextColumn get targetDistanceMode => text()
      .named('TargetDistanceMode')
      .map(const TargetDistanceModeConverter())
      .nullable()();
  RealColumn get targetDistanceValue =>
      real().named('TargetDistanceValue').nullable()();
  TextColumn get targetSizeMode => text()
      .named('TargetSizeMode')
      .map(const TargetSizeModeConverter())
      .nullable()();
  RealColumn get targetSizeWidth => real().named('TargetSizeWidth').nullable()();
  RealColumn get targetSizeDepth => real().named('TargetSizeDepth').nullable()();
  IntColumn get requiredSetCount =>
      integer().named('RequiredSetCount').withDefault(const Constant(1))();
  IntColumn get requiredAttemptsPerSet =>
      integer().named('RequiredAttemptsPerSet').nullable()();
  TextColumn get anchors =>
      text().named('Anchors').withDefault(const Constant('{}'))();
  RealColumn get target => real().named('Target').nullable()();
  TextColumn get origin =>
      text().named('Origin').map(const DrillOriginConverter())();
  TextColumn get status => text()
      .named('Status')
      .withDefault(const Constant('Active'))
      .map(const DrillStatusConverter())();
  BoolColumn get isDeleted =>
      boolean().named('IsDeleted').withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().named('CreatedAt').clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt =>
      dateTime().named('UpdatedAt').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {drillId};
}
