// Shared test fixtures for Phase 2A/2B scoring tests.
// Anchor sets from S14 §14.3. Helpers for window entry generation.
// Phase 2B: DB seeding helpers for in-memory integration tests.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// S14 §14.3.1 — Standard direction anchors (Irons, Driving, Woods, Pitching).
const kStandardDirectionAnchors = Anchors(min: 30, scratch: 70, pro: 90);

// S14 §14.3.1 — Putting direction anchors.
const kPuttingDirectionAnchors = Anchors(min: 20, scratch: 60, pro: 80);

// S14 §14.3.1 — Bunkers direction anchors.
const kBunkersDirectionAnchors = Anchors(min: 10, scratch: 50, pro: 70);

// S14 §14.3.3 — Driving carry distance anchors.
const kDrivingCarryAnchors = Anchors(min: 180, scratch: 250, pro: 300);

// S14 §14.3.3 — Ball speed anchors.
const kBallSpeedAnchors = Anchors(min: 130, scratch: 155, pro: 170);

// S14 §14.3.3 — Club head speed anchors.
const kClubHeadSpeedAnchors = Anchors(min: 85, scratch: 105, pro: 115);

// TD-05 §4.6 — User custom drill anchors.
const kCustomDrillAnchors = Anchors(min: 20, scratch: 50, pro: 75);

// S14 §14.3.2 — Standard distance control anchors (Irons, Woods).
const kStandardDistanceAnchors = Anchors(min: 30, scratch: 70, pro: 90);

// S14 §14.3.2 — Putting distance control anchors.
const kPuttingDistanceAnchors = Anchors(min: 20, scratch: 60, pro: 80);

// S14 §14.3.2 — Chipping distance control anchors.
const kChippingDistanceAnchors = Anchors(min: 10, scratch: 50, pro: 70);

// S14 §14.3.2 — Bunkers distance control anchors.
const kBunkersDistanceAnchors = Anchors(min: 10, scratch: 40, pro: 60);

/// Creates a [WindowEntry] with sensible defaults for testing.
WindowEntry makeWindowEntry({
  required String sessionId,
  required double score,
  double occupancy = 1.0,
  bool isDualMapped = false,
  DateTime? completionTimestamp,
}) {
  return WindowEntry(
    sessionId: sessionId,
    completionTimestamp:
        completionTimestamp ?? DateTime(2026, 1, 1, 12, 0, 0),
    score: score,
    occupancy: occupancy,
    isDualMapped: isDualMapped,
  );
}

/// Generates [count] window entries with sequential timestamps and sessionIds.
/// Entries are generated oldest-first (S1 oldest, S[count] newest).
List<WindowEntry> generateEntries({
  required int count,
  required double score,
  double occupancy = 1.0,
  bool isDualMapped = false,
}) {
  return List.generate(count, (i) {
    final index = i + 1;
    return WindowEntry(
      sessionId: 'S$index',
      completionTimestamp:
          DateTime(2026, 1, 1, 12, 0, 0).add(Duration(minutes: index)),
      score: score,
      occupancy: occupancy,
      isDualMapped: isDualMapped,
    );
  });
}

// ---------------------------------------------------------------------------
// Phase 2B — DB seeding helpers for in-memory integration tests.
// ---------------------------------------------------------------------------

/// Seed a PracticeBlock for the given user. Returns the practiceBlockId.
Future<String> seedPracticeBlock(
  AppDatabase db,
  String userId, {
  String? practiceBlockId,
}) async {
  final id = practiceBlockId ?? 'pb-${DateTime.now().microsecondsSinceEpoch}';
  await db.into(db.practiceBlocks).insertOnConflictUpdate(
        PracticeBlocksCompanion.insert(
          practiceBlockId: id,
          userId: userId,
        ),
      );
  return id;
}

/// Seed a complete session with instances for testing.
/// Returns the sessionId.
///
/// [rawMetrics] is either a JSON string per instance, or a list of JSON strings
/// (one per instance). If a single string is provided, all instances get it.
Future<String> seedSessionWithInstances(
  AppDatabase db, {
  required String userId,
  required String drillId,
  required String practiceBlockId,
  required int instanceCount,
  dynamic rawMetrics = '{"hit": true}',
  String? sessionId,
  SessionStatus status = SessionStatus.closed,
  DateTime? completionTimestamp,
}) async {
  final sid =
      sessionId ?? 'session-${DateTime.now().microsecondsSinceEpoch}';

  await db.into(db.sessions).insertOnConflictUpdate(
        SessionsCompanion.insert(
          sessionId: sid,
          drillId: drillId,
          practiceBlockId: practiceBlockId,
          status: Value(status),
          completionTimestamp:
              Value(completionTimestamp ?? DateTime(2026, 3, 1, 12, 0)),
        ),
      );

  final setId = 'set-$sid';
  await db.into(db.sets).insertOnConflictUpdate(
        SetsCompanion.insert(
          setId: setId,
          sessionId: sid,
          setIndex: 0,
        ),
      );

  final metricsList = rawMetrics is List
      ? rawMetrics
      : List.filled(instanceCount, rawMetrics);

  for (var i = 0; i < instanceCount; i++) {
    final metrics =
        metricsList[i] is String ? metricsList[i] as String : jsonEncode(metricsList[i]);
    await db.into(db.instances).insertOnConflictUpdate(
          InstancesCompanion.insert(
            instanceId: 'inst-$sid-$i',
            setId: setId,
            selectedClub: 'i7',
            rawMetrics: metrics,
          ),
        );
  }

  return sid;
}

/// Seed a user-custom drill for testing. Returns the drillId.
Future<String> seedTestDrill(
  AppDatabase db, {
  required String drillId,
  required SkillArea skillArea,
  required DrillType drillType,
  required String metricSchemaId,
  required List<String> subskillMapping,
  required Map<String, Map<String, double>> anchors,
  InputMode inputMode = InputMode.gridCell,
}) async {
  await db.into(db.drills).insertOnConflictUpdate(DrillsCompanion.insert(
    drillId: drillId,
    name: 'Test $drillId',
    skillArea: skillArea,
    drillType: drillType,
    inputMode: inputMode,
    metricSchemaId: metricSchemaId,
    subskillMapping: Value(jsonEncode(subskillMapping)),
    origin: DrillOrigin.userCustom,
    anchors: Value(jsonEncode(anchors)),
  ));
  return drillId;
}
