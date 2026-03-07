import 'package:drift/drift.dart';
import 'database.dart';
import 'enums.dart';

// TD-02 §8 / 002_seed_reference_data.sql — Seeds all reference tables and system drills.
// Runs inside MigrationStrategy.onCreate callback.

Future<void> seedReferenceData(AppDatabase db) async {
  await _seedEventTypeRefs(db);
  await _seedSubskillRefs(db);
  await _seedMetricSchemas(db);
  await _seedSystemDrills(db);
  await _validateSeedInvariants(db);
}

// 002_seed_reference_data.sql §1 — 16 EventTypeRef rows.
Future<void> _seedEventTypeRefs(AppDatabase db) async {
  final rows = <EventTypeRefsCompanion>[
    _eventType('AnchorEdit', 'Anchor Edit', 'User Custom Drill anchor change'),
    _eventType('InstanceEdit', 'Instance Edit', 'Instance value edited post-close'),
    _eventType('InstanceDeletion', 'Instance Deletion', 'Instance deleted from unstructured drill post-close'),
    _eventType('SessionDeletion', 'Session Deletion', 'Session deleted'),
    _eventType('SessionAutoDiscarded', 'Session Auto-Discarded', 'Session auto-discarded when last Instance deleted'),
    _eventType('PracticeBlockDeletion', 'PracticeBlock Deletion', 'PracticeBlock deleted'),
    _eventType('DrillDeletion', 'Drill Deletion', 'Drill and all child data deleted'),
    _eventType('SystemParameterChange', 'System Parameter Change', 'Central structural parameter updated'),
    _eventType('ReflowFailed', 'Reflow Failed', 'Reflow failed after all retry attempts'),
    _eventType('ReflowReverted', 'Reflow Reverted', 'Scoring state reverted to previous valid state after failure'),
    _eventType('IntegrityFlagRaised', 'Integrity Flag Raised', 'Instance saved with raw metric outside schema plausibility bounds'),
    _eventType('IntegrityFlagCleared', 'Integrity Flag Cleared', 'User manually cleared an active integrity flag'),
    _eventType('IntegrityFlagAutoResolved', 'Integrity Flag Auto-Resolved', 'All Instances returned to valid bounds following edit'),
    _eventType('ReflowComplete', 'Reflow Complete', 'Reflow completed successfully (TD-03 §4.2 Step 9, TD-04 Step 9)'),
    _eventType('SessionCompletion', 'Session Completion', 'Session closed and scored (TD-03 §4.4, TD-04 §2.2.2)'),
    _eventType('RebuildStorageFailure', 'Rebuild Storage Failure', 'Reflow rebuild results could not be written to materialised tables (TD-03 §4.5, TD-04 §3.4.2)'),
  ];
  await db.batch((batch) {
    batch.insertAll(db.eventTypeRefs, rows);
  });
}

EventTypeRefsCompanion _eventType(String id, String name, String desc) =>
    EventTypeRefsCompanion.insert(
      eventTypeId: id,
      name: name,
      description: Value(desc),
    );

// 002_seed_reference_data.sql §2 — 19 SubskillRef rows (allocations sum to 1000).
List<SubskillRefsCompanion> _subskillRefRows() => <SubskillRefsCompanion>[
    // Irons (360)
    _subskill('irons_distance_control', SkillArea.irons, 'Distance Control', 150),
    _subskill('irons_direction_control', SkillArea.irons, 'Direction Control', 150),
    _subskill('irons_shape_control', SkillArea.irons, 'Shape Control', 60),
    // Driving (240)
    _subskill('driving_distance_maximum', SkillArea.driving, 'Distance Maximum', 100),
    _subskill('driving_direction_control', SkillArea.driving, 'Direction Control', 100),
    _subskill('driving_shape_control', SkillArea.driving, 'Shape Control', 40),
    // Putting (240)
    _subskill('putting_distance_control', SkillArea.putting, 'Distance Control', 120),
    _subskill('putting_direction_control', SkillArea.putting, 'Direction Control', 120),
    // Pitching (60)
    _subskill('pitching_distance_control', SkillArea.pitching, 'Distance Control', 25),
    _subskill('pitching_direction_control', SkillArea.pitching, 'Direction Control', 25),
    _subskill('pitching_flight_control', SkillArea.pitching, 'Flight Control', 10),
    // Chipping (60)
    _subskill('chipping_distance_control', SkillArea.chipping, 'Distance Control', 25),
    _subskill('chipping_direction_control', SkillArea.chipping, 'Direction Control', 25),
    _subskill('chipping_flight_control', SkillArea.chipping, 'Flight Control', 10),
    // Woods (20)
    _subskill('woods_distance_control', SkillArea.woods, 'Distance Control', 8),
    _subskill('woods_direction_control', SkillArea.woods, 'Direction Control', 8),
    _subskill('woods_shape_control', SkillArea.woods, 'Shape Control', 4),
    // Bunkers (20)
    _subskill('bunkers_distance_control', SkillArea.bunkers, 'Distance Control', 10),
    _subskill('bunkers_direction_control', SkillArea.bunkers, 'Direction Control', 10),
  ];

Future<void> _seedSubskillRefs(AppDatabase db) async {
  await db.batch((batch) {
    batch.insertAll(db.subskillRefs, _subskillRefRows());
  });
}

/// TD-07 §13.6 8c — Re-seed SubskillRef allocations idempotently.
/// Safe to call when rows already exist (uses insertOrReplace).
Future<void> reseedSubskillRefs(AppDatabase db) async {
  await db.batch((batch) {
    batch.insertAll(db.subskillRefs, _subskillRefRows(),
        mode: InsertMode.insertOrReplace);
  });
}

SubskillRefsCompanion _subskill(
        String id, SkillArea area, String name, int allocation) =>
    SubskillRefsCompanion.insert(
      subskillId: id,
      skillArea: area,
      name: name,
      allocation: allocation,
    );

// 002_seed_reference_data.sql §3 — 8 MetricSchema rows.
Future<void> _seedMetricSchemas(AppDatabase db) async {
  final rows = <MetricSchemasCompanion>[
    _metricSchema('grid_1x3_direction', '1×3 Direction Grid', InputMode.gridCell, null, null, '{"gridType": "OneByThree"}', 'HitRateInterpolation'),
    _metricSchema('grid_3x1_distance', '3×1 Distance Grid', InputMode.gridCell, null, null, '{"gridType": "ThreeByOne"}', 'HitRateInterpolation'),
    _metricSchema('grid_3x3_multioutput', '3×3 Multi-Output Grid', InputMode.gridCell, null, null, '{"gridType": "ThreeByThree"}', 'HitRateInterpolation'),
    _metricSchema('binary_hit_miss', 'Binary Hit/Miss', InputMode.binaryHitMiss, null, null, '{}', 'HitRateInterpolation'),
    _metricSchema('raw_carry_distance', 'Carry Distance (yards)', InputMode.rawDataEntry, 0, 500, '{"unit": "yards"}', 'LinearInterpolation'),
    _metricSchema('raw_ball_speed', 'Ball Speed (mph)', InputMode.rawDataEntry, 0, 250, '{"unit": "mph"}', 'LinearInterpolation'),
    _metricSchema('raw_club_head_speed', 'Club Head Speed (mph)', InputMode.rawDataEntry, 0, 200, '{"unit": "mph"}', 'LinearInterpolation'),
    _metricSchema('technique_duration', 'Technique Block Duration', InputMode.rawDataEntry, 0, 43200, '{"unit": "seconds"}', 'None'),
  ];
  await db.batch((batch) {
    batch.insertAll(db.metricSchemas, rows);
  });
}

MetricSchemasCompanion _metricSchema(
  String id,
  String name,
  InputMode inputMode,
  double? hardMin,
  double? hardMax,
  String? validationRules,
  String scoringAdapterBinding,
) =>
    MetricSchemasCompanion.insert(
      metricSchemaId: id,
      name: name,
      inputMode: inputMode,
      hardMinInput: Value(hardMin),
      hardMaxInput: Value(hardMax),
      validationRules: Value(validationRules),
      scoringAdapterBinding: scoringAdapterBinding,
    );

// 002_seed_reference_data.sql §4 — 28 System Drills with deterministic UUIDs.
Future<void> _seedSystemDrills(AppDatabase db) async {
  final rows = <DrillsCompanion>[
    // 4.1 Technique Blocks (7)
    _systemDrill('a0000001-0000-4000-8000-000000000001', 'Driving Technique', SkillArea.driving, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),
    _systemDrill('a0000001-0000-4000-8000-000000000002', 'Irons Technique', SkillArea.irons, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),
    _systemDrill('a0000001-0000-4000-8000-000000000003', 'Putting Technique', SkillArea.putting, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),
    _systemDrill('a0000001-0000-4000-8000-000000000004', 'Pitching Technique', SkillArea.pitching, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),
    _systemDrill('a0000001-0000-4000-8000-000000000005', 'Chipping Technique', SkillArea.chipping, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),
    _systemDrill('a0000001-0000-4000-8000-000000000006', 'Woods Technique', SkillArea.woods, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),
    _systemDrill('a0000001-0000-4000-8000-000000000007', 'Bunkers Technique', SkillArea.bunkers, DrillType.techniqueBlock, null, InputMode.rawDataEntry, 'technique_duration', null, '[]', null, null, null, null, null, null, 1, null, '{}'),

    // 4.2 Direction Control — 1×3 Grid (7)
    _systemDrill('a0000002-0000-4000-8000-000000000001', 'Driving Direction', SkillArea.driving, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["driving_direction_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, 7, null, 1, 10, '{"driving_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000002-0000-4000-8000-000000000002', 'Irons Direction', SkillArea.irons, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["irons_direction_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, 7, null, 1, 10, '{"irons_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000002-0000-4000-8000-000000000003', 'Woods Direction', SkillArea.woods, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["woods_direction_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, 7, null, 1, 10, '{"woods_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000002-0000-4000-8000-000000000004', 'Pitching Direction', SkillArea.pitching, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["pitching_direction_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, 7, null, 1, 10, '{"pitching_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000002-0000-4000-8000-000000000005', 'Putting Direction', SkillArea.putting, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["putting_direction_control"]', null, TargetDistanceMode.fixed, 10, null, null, null, 1, 10, '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 80}}'),
    _systemDrill('a0000002-0000-4000-8000-000000000006', 'Chipping Direction', SkillArea.chipping, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["chipping_direction_control"]', ClubSelectionMode.userLed, TargetDistanceMode.fixed, 30, TargetSizeMode.fixed, 3, null, 1, 10, '{"chipping_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000002-0000-4000-8000-000000000007', 'Bunkers Direction', SkillArea.bunkers, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_1x3_direction', GridType.oneByThree, '["bunkers_direction_control"]', ClubSelectionMode.userLed, TargetDistanceMode.fixed, 20, TargetSizeMode.fixed, 10, null, 1, 10, '{"bunkers_direction_control": {"Min": 10, "Scratch": 50, "Pro": 70}}'),

    // 4.3 Distance Control — 3×1 Grid (6)
    _systemDrill('a0000003-0000-4000-8000-000000000001', 'Irons Distance', SkillArea.irons, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_3x1_distance', GridType.threeByOne, '["irons_distance_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, null, 4, 1, 10, '{"irons_distance_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000003-0000-4000-8000-000000000002', 'Woods Distance', SkillArea.woods, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_3x1_distance', GridType.threeByOne, '["woods_distance_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, null, 5, 1, 10, '{"woods_distance_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000003-0000-4000-8000-000000000003', 'Pitching Distance', SkillArea.pitching, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_3x1_distance', GridType.threeByOne, '["pitching_distance_control"]', ClubSelectionMode.userLed, TargetDistanceMode.clubCarry, null, TargetSizeMode.percentageOfTargetDistance, null, 3, 1, 10, '{"pitching_distance_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000003-0000-4000-8000-000000000004', 'Putting Distance', SkillArea.putting, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_3x1_distance', GridType.threeByOne, '["putting_distance_control"]', null, TargetDistanceMode.fixed, 30, TargetSizeMode.fixed, null, 4, 1, 10, '{"putting_distance_control": {"Min": 20, "Scratch": 60, "Pro": 80}}'),
    _systemDrill('a0000003-0000-4000-8000-000000000005', 'Chipping Distance', SkillArea.chipping, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_3x1_distance', GridType.threeByOne, '["chipping_distance_control"]', ClubSelectionMode.userLed, TargetDistanceMode.fixed, 30, TargetSizeMode.fixed, null, 6, 1, 10, '{"chipping_distance_control": {"Min": 10, "Scratch": 50, "Pro": 70}}'),
    _systemDrill('a0000003-0000-4000-8000-000000000006', 'Bunkers Distance', SkillArea.bunkers, DrillType.transition, ScoringMode.shared, InputMode.gridCell, 'grid_3x1_distance', GridType.threeByOne, '["bunkers_distance_control"]', ClubSelectionMode.userLed, TargetDistanceMode.fixed, 30, TargetSizeMode.fixed, null, 10, 1, 10, '{"bunkers_distance_control": {"Min": 10, "Scratch": 40, "Pro": 60}}'),

    // 4.4 Distance Maximum — Raw Data Entry (3)
    _systemDrill('a0000004-0000-4000-8000-000000000001', 'Driving Carry', SkillArea.driving, DrillType.transition, ScoringMode.shared, InputMode.rawDataEntry, 'raw_carry_distance', null, '["driving_distance_maximum"]', null, null, null, null, null, null, 1, 10, '{"driving_distance_maximum": {"Min": 180, "Scratch": 250, "Pro": 300}}'),
    _systemDrill('a0000004-0000-4000-8000-000000000002', 'Driving Ball Speed', SkillArea.driving, DrillType.transition, ScoringMode.shared, InputMode.rawDataEntry, 'raw_ball_speed', null, '["driving_distance_maximum"]', null, null, null, null, null, null, 1, 10, '{"driving_distance_maximum": {"Min": 130, "Scratch": 155, "Pro": 170}}'),
    _systemDrill('a0000004-0000-4000-8000-000000000003', 'Driving Club Speed', SkillArea.driving, DrillType.transition, ScoringMode.shared, InputMode.rawDataEntry, 'raw_club_head_speed', null, '["driving_distance_maximum"]', null, null, null, null, null, null, 1, 10, '{"driving_distance_maximum": {"Min": 85, "Scratch": 105, "Pro": 115}}'),

    // 4.5 Shape Control — Binary Hit/Miss (3)
    _systemDrill('a0000005-0000-4000-8000-000000000001', 'Irons Shape', SkillArea.irons, DrillType.transition, ScoringMode.shared, InputMode.binaryHitMiss, 'binary_hit_miss', null, '["irons_shape_control"]', ClubSelectionMode.userLed, null, null, null, null, null, 1, 10, '{"irons_shape_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000005-0000-4000-8000-000000000002', 'Driving Shape', SkillArea.driving, DrillType.transition, ScoringMode.shared, InputMode.binaryHitMiss, 'binary_hit_miss', null, '["driving_shape_control"]', ClubSelectionMode.userLed, null, null, null, null, null, 1, 10, '{"driving_shape_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000005-0000-4000-8000-000000000003', 'Woods Shape', SkillArea.woods, DrillType.transition, ScoringMode.shared, InputMode.binaryHitMiss, 'binary_hit_miss', null, '["woods_shape_control"]', ClubSelectionMode.userLed, null, null, null, null, null, 1, 10, '{"woods_shape_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),

    // 4.6 Flight Control — Binary Hit/Miss (2)
    _systemDrill('a0000005-0000-4000-8000-000000000004', 'Pitching Flight', SkillArea.pitching, DrillType.transition, ScoringMode.shared, InputMode.binaryHitMiss, 'binary_hit_miss', null, '["pitching_flight_control"]', ClubSelectionMode.userLed, null, null, null, null, null, 1, 10, '{"pitching_flight_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
    _systemDrill('a0000005-0000-4000-8000-000000000005', 'Chipping Flight', SkillArea.chipping, DrillType.transition, ScoringMode.shared, InputMode.binaryHitMiss, 'binary_hit_miss', null, '["chipping_flight_control"]', ClubSelectionMode.userLed, null, null, null, null, null, 1, 10, '{"chipping_flight_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
  ];
  await db.batch((batch) {
    batch.insertAll(db.drills, rows);
  });
}

DrillsCompanion _systemDrill(
  String id,
  String name,
  SkillArea skillArea,
  DrillType drillType,
  ScoringMode? scoringMode,
  InputMode inputMode,
  String metricSchemaId,
  GridType? gridType,
  String subskillMapping,
  ClubSelectionMode? clubSelectionMode,
  TargetDistanceMode? targetDistanceMode,
  double? targetDistanceValue,
  TargetSizeMode? targetSizeMode,
  double? targetSizeWidth,
  double? targetSizeDepth,
  int requiredSetCount,
  int? requiredAttemptsPerSet,
  String anchors,
) =>
    DrillsCompanion.insert(
      drillId: id,
      userId: const Value(null),
      name: name,
      skillArea: skillArea,
      drillType: drillType,
      scoringMode: Value(scoringMode),
      inputMode: inputMode,
      metricSchemaId: metricSchemaId,
      gridType: Value(gridType),
      subskillMapping: Value(subskillMapping),
      clubSelectionMode: Value(clubSelectionMode),
      targetDistanceMode: Value(targetDistanceMode),
      targetDistanceValue: Value(targetDistanceValue),
      targetSizeMode: Value(targetSizeMode),
      targetSizeWidth: Value(targetSizeWidth),
      targetSizeDepth: Value(targetSizeDepth),
      requiredSetCount: Value(requiredSetCount),
      requiredAttemptsPerSet: Value(requiredAttemptsPerSet),
      anchors: Value(anchors),
      origin: DrillOrigin.system,
      status: Value(DrillStatus.active),
      isDeleted: const Value(false),
    );

// 002_seed_reference_data.sql §5 — Post-seed invariant validation.
Future<void> _validateSeedInvariants(AppDatabase db) async {
  // Invariant 1: Global allocation sum = 1000
  final allocations = await (db.selectOnly(db.subskillRefs)
        ..addColumns([db.subskillRefs.allocation.sum()]))
      .getSingle();
  final totalAllocation =
      allocations.read(db.subskillRefs.allocation.sum()) ?? 0;
  assert(totalAllocation == 1000,
      'SubskillRef allocation invariant: sum=$totalAllocation, expected 1000');

  // Invariant 2: Exactly 19 subskills
  final subskillCount = await db.subskillRefs.count().getSingle();
  assert(subskillCount == 19,
      'SubskillRef count invariant: $subskillCount rows, expected 19');

  // Invariant 3: Exactly 28 system drills
  final drillCount = await (db.selectOnly(db.drills)
        ..addColumns([db.drills.drillId.count()])
        ..where(db.drills.origin.equalsValue(DrillOrigin.system)))
      .getSingle();
  final systemDrillCount =
      drillCount.read(db.drills.drillId.count()) ?? 0;
  assert(systemDrillCount == 28,
      'System Drill count invariant: $systemDrillCount rows, expected 28');

  // Invariant 4: 16 event types
  final eventTypeCount = await db.eventTypeRefs.count().getSingle();
  assert(eventTypeCount == 16,
      'EventTypeRef count invariant: $eventTypeCount rows, expected 16');

  // Invariant 5: 8 metric schemas
  final metricSchemaCount = await db.metricSchemas.count().getSingle();
  assert(metricSchemaCount == 8,
      'MetricSchema count invariant: $metricSchemaCount rows, expected 8');
}
