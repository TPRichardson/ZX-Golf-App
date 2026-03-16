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
// WindowSize is per-subskill: controls accumulation scoring window capacity.
List<SubskillRefsCompanion> _subskillRefRows() => <SubskillRefsCompanion>[
    // Approach (360)
    _subskill('approach_distance_control', SkillArea.approach, 'Distance Control', 150, 25),
    _subskill('approach_direction_control', SkillArea.approach, 'Direction Control', 150, 25),
    _subskill('approach_shape_control', SkillArea.approach, 'Shape Control', 60, 15),
    // Driving (240)
    _subskill('driving_distance_maximum', SkillArea.driving, 'Distance Maximum', 100, 20),
    _subskill('driving_direction_control', SkillArea.driving, 'Direction Control', 100, 20),
    _subskill('driving_shape_control', SkillArea.driving, 'Shape Control', 40, 10),
    // Putting (240)
    _subskill('putting_distance_control', SkillArea.putting, 'Distance Control', 120, 25),
    _subskill('putting_direction_control', SkillArea.putting, 'Direction Control', 120, 25),
    // Pitching (60)
    _subskill('pitching_distance_control', SkillArea.pitching, 'Distance Control', 25, 10),
    _subskill('pitching_direction_control', SkillArea.pitching, 'Direction Control', 25, 10),
    _subskill('pitching_flight_control', SkillArea.pitching, 'Flight Control', 10, 3),
    // Chipping (60)
    _subskill('chipping_distance_control', SkillArea.chipping, 'Distance Control', 25, 10),
    _subskill('chipping_direction_control', SkillArea.chipping, 'Direction Control', 25, 10),
    _subskill('chipping_flight_control', SkillArea.chipping, 'Flight Control', 10, 3),
    // Woods (20)
    _subskill('woods_distance_control', SkillArea.woods, 'Distance Control', 8, 3),
    _subskill('woods_direction_control', SkillArea.woods, 'Direction Control', 8, 3),
    _subskill('woods_shape_control', SkillArea.woods, 'Shape Control', 4, 2),
    // Bunkers (20)
    _subskill('bunkers_distance_control', SkillArea.bunkers, 'Distance Control', 10, 3),
    _subskill('bunkers_direction_control', SkillArea.bunkers, 'Direction Control', 10, 3),
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
        String id, SkillArea area, String name, int allocation, int windowSize) =>
    SubskillRefsCompanion.insert(
      subskillId: id,
      skillArea: area,
      name: name,
      allocation: allocation,
      windowSize: Value(windowSize),
    );

// 002_seed_reference_data.sql §3 — 8 MetricSchema rows.
Future<void> _seedMetricSchemas(AppDatabase db) async {
  final rows = <MetricSchemasCompanion>[
    _metricSchema('grid_1x3_direction', '1×3 Direction Grid', InputMode.gridCell, null, null, '{"gridType": "OneByThree"}', 'HitRateInterpolation'),
    _metricSchema('grid_3x1_distance', '3×1 Distance Grid', InputMode.gridCell, null, null, '{"gridType": "ThreeByOne"}', 'HitRateInterpolation'),
    _metricSchema('grid_3x3_multioutput', '3×3 Multi-Output Grid', InputMode.gridCell, null, null, '{"gridType": "ThreeByThree"}', 'HitRateInterpolation'),
    _metricSchema('binary_hit_miss', 'Binary Hit/Miss', InputMode.binaryHitMiss, null, null, '{}', 'HitRateInterpolation'),
    _metricSchema('raw_carry_distance', 'Carry Distance (yards)', InputMode.rawDataEntry, 0, 500, '{"unit": "yards"}', 'LinearInterpolation'),
    _metricSchema('raw_total_distance', 'Total Distance (yards)', InputMode.rawDataEntry, 0, 500, '{"unit": "yards"}', 'LinearInterpolation'),
    _metricSchema('driver_club_speed', 'Driver Club Speed (mph)', InputMode.rawDataEntry, 50, 150, '{"unit": "mph"}', 'BestOfSetLinearInterpolation'),
    _metricSchema('driver_ball_speed', 'Driver Ball Speed (mph)', InputMode.rawDataEntry, 80, 200, '{"unit": "mph"}', 'BestOfSetLinearInterpolation'),
    _metricSchema('driver_total_distance', 'Driver Total Distance (yds)', InputMode.rawDataEntry, 100, 400, '{"unit": "yards"}', 'BestOfSetLinearInterpolation'),
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

// Standard drills are server-authoritative — no local seeding.
// ignore: unused_element
Future<void> _seedSystemDrills(AppDatabase db) async {
  // No-op: standard drills fetched from Supabase at runtime.
}

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

  // Invariant 3: No local standard drills (server-authoritative).
  final drillCount = await (db.selectOnly(db.drills)
        ..addColumns([db.drills.drillId.count()])
        ..where(db.drills.origin.equalsValue(DrillOrigin.standard)))
      .getSingle();
  final systemDrillCount =
      drillCount.read(db.drills.drillId.count()) ?? 0;
  assert(systemDrillCount == 0,
      'System Drill count invariant: $systemDrillCount rows, expected 0');

  // Invariant 4: 16 event types
  final eventTypeCount = await db.eventTypeRefs.count().getSingle();
  assert(eventTypeCount == 16,
      'EventTypeRef count invariant: $eventTypeCount rows, expected 16');

  // Invariant 5: 8 metric schemas
  final metricSchemaCount = await db.metricSchemas.count().getSingle();
  assert(metricSchemaCount == 12,
      'MetricSchema count invariant: $metricSchemaCount rows, expected 12');
}
