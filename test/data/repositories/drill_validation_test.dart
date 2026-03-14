import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Fix 2 — Subskill count validation on drill creation.
// S04 §4.2: TechniqueBlock → 0 subskills, Transition/Pressure → 1 or 2.

void main() {
  late AppDatabase db;
  late DrillRepository repo;

  const userId = 'test-user-validation';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncWriteGate = SyncWriteGate();
    final eventLogRepo = EventLogRepository(db, syncWriteGate);
    final scoringRepo = ScoringRepository(db);
    final rebuildGuard = RebuildGuard();
    final reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: rebuildGuard,
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    repo = DrillRepository(db, eventLogRepo, reflowEngine, syncWriteGate);

    // S09 §9.3 — Seed clubs so bag gate passes for Irons.
    final clubRepo = ClubRepository(db, syncWriteGate);
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.i7)));
  });

  tearDown(() async {
    await db.close();
  });

  group('Fix 2: Subskill count validation (S04 §4.2)', () {
    test('Pressure drill with 0 subskills throws ValidationException',
        () async {
      final companion = DrillsCompanion(
        name: const Value('Pressure No Subskills'),
        skillArea: const Value(SkillArea.approach),
        drillType: const Value(DrillType.pressure),
        inputMode: const Value(InputMode.rawDataEntry),
        metricSchemaId: const Value('raw_carry_distance'),
        subskillMapping: const Value('[]'),
        anchors: const Value('{}'),
      );

      expect(
        () => repo.createCustomDrill(userId, companion),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Pressure drill with 3 subskills throws ValidationException',
        () async {
      final companion = DrillsCompanion(
        name: const Value('Pressure Too Many'),
        skillArea: const Value(SkillArea.approach),
        drillType: const Value(DrillType.pressure),
        inputMode: const Value(InputMode.rawDataEntry),
        metricSchemaId: const Value('raw_carry_distance'),
        subskillMapping: const Value(
            '["approach_direction_control","approach_distance_control","approach_consistency"]'),
        anchors: const Value('{}'),
      );

      expect(
        () => repo.createCustomDrill(userId, companion),
        throwsA(isA<ValidationException>()),
      );
    });

    test('Pressure drill with 1 subskill succeeds', () async {
      final companion = DrillsCompanion(
        name: const Value('Pressure Single'),
        skillArea: const Value(SkillArea.approach),
        drillType: const Value(DrillType.pressure),
        inputMode: const Value(InputMode.rawDataEntry),
        metricSchemaId: const Value('raw_carry_distance'),
        subskillMapping: const Value('["approach_direction_control"]'),
        anchors: const Value(
            '{"approach_direction_control": {"Min": 10, "Scratch": 50, "Pro": 90}}'),
      );

      final drill = await repo.createCustomDrill(userId, companion);
      expect(drill.drillType, DrillType.pressure);
    });

    test('Pressure drill with 2 subskills succeeds', () async {
      final companion = DrillsCompanion(
        name: const Value('Pressure Dual'),
        skillArea: const Value(SkillArea.approach),
        drillType: const Value(DrillType.pressure),
        inputMode: const Value(InputMode.rawDataEntry),
        metricSchemaId: const Value('raw_carry_distance'),
        subskillMapping: const Value(
            '["approach_direction_control","approach_distance_control"]'),
        anchors: const Value(
            '{"approach_direction_control": {"Min": 10, "Scratch": 50, "Pro": 90}, "approach_distance_control": {"Min": 5, "Scratch": 30, "Pro": 60}}'),
      );

      final drill = await repo.createCustomDrill(userId, companion);
      expect(drill.drillType, DrillType.pressure);
    });

    test('TechniqueBlock drill with subskills throws ValidationException',
        () async {
      final companion = DrillsCompanion(
        name: const Value('Technique With Subskills'),
        skillArea: const Value(SkillArea.approach),
        drillType: const Value(DrillType.techniqueBlock),
        inputMode: const Value(InputMode.rawDataEntry),
        metricSchemaId: const Value('technique_duration'),
        subskillMapping: const Value('["approach_direction_control"]'),
        requiredSetCount: const Value(1),
        requiredAttemptsPerSet: const Value(null),
      );

      expect(
        () => repo.createCustomDrill(userId, companion),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
