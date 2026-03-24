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

// Phase 3 — DrillRepository tests.
// Covers: state machines (TD-04 §2.4.1), immutability (TD-04 §2.4.2),
// anchor governance (S04), adoption lifecycle (TD-04 §2.5.1), validation.

void main() {
  late AppDatabase db;
  late DrillRepository repo;
  late EventLogRepository eventLogRepo;
  late ReflowEngine reflowEngine;

  const userId = 'test-user-drill';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncWriteGate = SyncWriteGate();
    eventLogRepo = EventLogRepository(db, syncWriteGate);
    final scoringRepo = ScoringRepository(db);
    final rebuildGuard = RebuildGuard();
    reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: rebuildGuard,
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    repo = DrillRepository(db, eventLogRepo, reflowEngine, syncWriteGate);

    // S09 §9.3 — Seed clubs so bag gate passes for all 7 Skill Areas.
    final clubRepo = ClubRepository(db, syncWriteGate);
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.driver)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.i7)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.w3)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.sw)));

    // Seed a test standard drill (no longer auto-seeded; server-authoritative).
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: 'system-putting-gate-40cm',
      name: '40cm Gate Drill',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      scoringMode: const Value(ScoringMode.shared),
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      gridType: const Value(GridType.oneByThree),
      subskillMapping: const Value('["putting_direction_control"]'),
      clubSelectionMode: const Value(ClubSelectionMode.userLed),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(10),
      anchors: const Value(
          '{"putting_direction_control":{"Min":10,"Scratch":40,"Pro":85}}'),
      origin: DrillOrigin.standard,
      status: const Value(DrillStatus.active),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to create a minimal custom drill companion.
  DrillsCompanion customDrillCompanion({
    String name = 'Test Custom Drill',
    SkillArea skillArea = SkillArea.approach,
    DrillType drillType = DrillType.transition,
    String metricSchemaId = 'grid_1x3_direction',
    String subskillMapping = '["approach_direction_control"]',
    String anchors =
        '{"approach_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}',
    int requiredSetCount = 1,
    int? requiredAttemptsPerSet = 10,
  }) {
    return DrillsCompanion(
      name: Value(name),
      skillArea: Value(skillArea),
      drillType: Value(drillType),
      inputMode: const Value(InputMode.gridCell),
      metricSchemaId: Value(metricSchemaId),
      subskillMapping: Value(subskillMapping),
      anchors: Value(anchors),
      requiredSetCount: Value(requiredSetCount),
      requiredAttemptsPerSet: Value(requiredAttemptsPerSet),
    );
  }

  // ---------------------------------------------------------------------------
  // Drill state machine — TD-04 §2.4.1
  // ---------------------------------------------------------------------------
  group('Drill state machine (TD-04 §2.4.1)', () {
    test('createCustomDrill creates drill with Active status', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );

      expect(drill.status, DrillStatus.active);
      expect(drill.origin, DrillOrigin.custom);
      expect(drill.userId, userId);
      expect(drill.isDeleted, false);
    });

    test('retireDrill: Active→Retired', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );

      final retired = await repo.retireDrill(userId, drill.drillId);
      expect(retired.status, DrillStatus.retired);
    });

    test('reactivateDrill: Retired→Active', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );
      await repo.retireDrill(userId, drill.drillId);

      final reactivated = await repo.reactivateDrill(userId, drill.drillId);
      expect(reactivated.status, DrillStatus.active);
    });

    test('deleteDrill: Active→Deleted (soft)', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );

      await repo.deleteDrill(userId, drill.drillId);

      final fetched = await repo.getById(drill.drillId);
      expect(fetched, isNull); // getById filters isDeleted
    });

    test('deleteDrill: Retired→Deleted (soft)', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );
      await repo.retireDrill(userId, drill.drillId);

      await repo.deleteDrill(userId, drill.drillId);

      final fetched = await repo.getById(drill.drillId);
      expect(fetched, isNull);
    });

    test('retireDrill throws on Retired drill', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );
      await repo.retireDrill(userId, drill.drillId);

      expect(
        () => repo.retireDrill(userId, drill.drillId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });

    test('deleteDrill throws on standard drill', () async {
      // Get a system drill ID from seed data.
      final systemDrills = await repo.watchStandardDrills().first;
      expect(systemDrills, isNotEmpty);
      final systemDrill = systemDrills.first;

      expect(
        () => repo.deleteDrill(userId, systemDrill.drillId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Immutability — TD-04 §2.4.2
  // ---------------------------------------------------------------------------
  group('Immutability (TD-04 §2.4.2)', () {
    late Drill customDrill;

    setUp(() async {
      customDrill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );
    });

    test('update SubskillMapping throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(userId, customDrill.drillId,
            const DrillsCompanion(subskillMapping: Value('["new_subskill"]'))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update MetricSchemaID throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(userId, customDrill.drillId,
            const DrillsCompanion(metricSchemaId: Value('other_schema'))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update DrillType throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(
            userId,
            customDrill.drillId,
            const DrillsCompanion(
                drillType: Value(DrillType.pressure))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update RequiredSetCount throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(userId, customDrill.drillId,
            const DrillsCompanion(requiredSetCount: Value(3))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update RequiredAttemptsPerSet throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(userId, customDrill.drillId,
            const DrillsCompanion(requiredAttemptsPerSet: Value(20))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update ClubSelectionMode throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(
            userId,
            customDrill.drillId,
            const DrillsCompanion(
                clubSelectionMode: Value(ClubSelectionMode.random))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update target fields throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(
            userId,
            customDrill.drillId,
            const DrillsCompanion(
                targetDistanceMode: Value(TargetDistanceMode.fixed))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    // TD-03 §5.3 — ScoringMode and InputMode immutable post-creation.
    test('update ScoringMode throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(
            userId,
            customDrill.drillId,
            const DrillsCompanion(
                scoringMode: Value(ScoringMode.multiOutput))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update InputMode throws invalidStructure', () async {
      expect(
        () => repo.updateDrill(
            userId,
            customDrill.drillId,
            const DrillsCompanion(
                inputMode: Value(InputMode.binaryHitMiss))),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('update Name succeeds', () async {
      final updated = await repo.updateDrill(
        userId,
        customDrill.drillId,
        const DrillsCompanion(name: Value('Renamed Drill')),
      );
      expect(updated.name, 'Renamed Drill');
    });

    test('update Anchors succeeds on Active drill', () async {
      final updated = await repo.updateDrill(
        userId,
        customDrill.drillId,
        const DrillsCompanion(
          anchors: Value(
            '{"approach_direction_control": {"Min": 25, "Scratch": 65, "Pro": 85}}',
          ),
        ),
      );
      expect(updated.anchors, contains('"Min": 25'));
    });
  });

  // ---------------------------------------------------------------------------
  // Anchor governance — S04
  // ---------------------------------------------------------------------------
  group('Anchor governance (S04)', () {
    test('anchor edit on Retired drill throws', () async {
      final drill = await repo.createCustomDrill(
        userId,
        customDrillCompanion(),
      );
      await repo.retireDrill(userId, drill.drillId);

      expect(
        () => repo.updateDrill(
          userId,
          drill.drillId,
          const DrillsCompanion(
            anchors: Value(
              '{"approach_direction_control": {"Min": 20, "Scratch": 60, "Pro": 80}}',
            ),
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });

    test('anchor Min >= Scratch throws invalidAnchors', () async {
      expect(
        () => repo.createCustomDrill(
          userId,
          customDrillCompanion(
            anchors:
                '{"approach_direction_control": {"Min": 70, "Scratch": 70, "Pro": 90}}',
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidAnchors,
        )),
      );
    });

    test('anchor Scratch >= Pro throws invalidAnchors', () async {
      expect(
        () => repo.createCustomDrill(
          userId,
          customDrillCompanion(
            anchors:
                '{"approach_direction_control": {"Min": 30, "Scratch": 90, "Pro": 90}}',
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidAnchors,
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Adoption state machine — TD-04 §2.5.1
  // ---------------------------------------------------------------------------
  group('Adoption state machine (TD-04 §2.5.1)', () {
    late String systemDrillId;

    setUp(() async {
      final systemDrills = await repo.watchStandardDrills().first;
      systemDrillId = systemDrills.first.drillId;
    });

    test('adoptDrill creates adoption with Active status', () async {
      final adoption = await repo.adoptDrill(userId, systemDrillId);
      expect(adoption.status, AdoptionStatus.active);
      expect(adoption.userId, userId);
      expect(adoption.drillId, systemDrillId);
    });

    test('retireAdoption: Active→Retired', () async {
      await repo.adoptDrill(userId, systemDrillId);
      final retired = await repo.retireAdoption(userId, systemDrillId);
      expect(retired.status, AdoptionStatus.retired);
    });

    test('re-adopt from Retired→Active', () async {
      await repo.adoptDrill(userId, systemDrillId);
      await repo.retireAdoption(userId, systemDrillId);
      final reAdopted = await repo.adoptDrill(userId, systemDrillId);
      expect(reAdopted.status, AdoptionStatus.active);
    });

    test('adoptDrill is idempotent on Active adoption', () async {
      final first = await repo.adoptDrill(userId, systemDrillId);
      final second = await repo.adoptDrill(userId, systemDrillId);
      expect(first.userDrillAdoptionId, second.userDrillAdoptionId);
      expect(second.status, AdoptionStatus.active);
    });

    test('retireAdoption on Retired throws stateTransition', () async {
      await repo.adoptDrill(userId, systemDrillId);
      await repo.retireAdoption(userId, systemDrillId);

      expect(
        () => repo.retireAdoption(userId, systemDrillId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });

    test('deleteAdoption soft-deletes adoption', () async {
      await repo.adoptDrill(userId, systemDrillId);
      await repo.deleteAdoption(userId, systemDrillId);

      // Adoption should no longer be found (isDeleted filter).
      final adopted = await repo.watchAdoptedDrills(userId).first;
      final matches =
          adopted.where((d) => d.drill.drillId == systemDrillId);
      expect(matches, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------
  group('Validation', () {
    test('invalid SubskillMapping throws invalidStructure', () async {
      expect(
        () => repo.createCustomDrill(
          userId,
          customDrillCompanion(
            subskillMapping: '["nonexistent_subskill"]',
            anchors:
                '{"nonexistent_subskill": {"Min": 30, "Scratch": 70, "Pro": 90}}',
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('cross-SkillArea SubskillMapping throws invalidStructure', () async {
      // approach_direction_control belongs to Irons, not Driving.
      expect(
        () => repo.createCustomDrill(
          userId,
          customDrillCompanion(
            skillArea: SkillArea.driving,
            subskillMapping: '["approach_direction_control"]',
            anchors:
                '{"approach_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}',
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('TechniqueBlock with RequiredAttemptsPerSet throws', () async {
      expect(
        () => repo.createCustomDrill(
          userId,
          customDrillCompanion(
            drillType: DrillType.techniqueBlock,
            metricSchemaId: 'technique_duration',
            subskillMapping: '[]',
            anchors: '{}',
            requiredSetCount: 1,
            requiredAttemptsPerSet: 10,
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('standard drill update throws invalidStructure', () async {
      final systemDrills = await repo.watchStandardDrills().first;
      final systemDrill = systemDrills.first;

      expect(
        () => repo.updateDrill(
          userId,
          systemDrill.drillId,
          const DrillsCompanion(name: Value('Hacked Name')),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('invalid metricSchemaId throws invalidStructure', () async {
      expect(
        () => repo.createCustomDrill(
          userId,
          customDrillCompanion(
            metricSchemaId: 'nonexistent_schema',
          ),
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Duplicate drill
  // ---------------------------------------------------------------------------
  group('duplicateDrill', () {
    test('creates copy with new ID and UserCustom origin', () async {
      final systemDrills = await repo.watchStandardDrills().first;
      final source = systemDrills.first;

      final copy = await repo.duplicateDrill(userId, source.drillId);

      expect(copy.drillId, isNot(source.drillId));
      expect(copy.origin, DrillOrigin.custom);
      expect(copy.userId, userId);
      expect(copy.name, '${source.name} (Copy)');
      expect(copy.skillArea, source.skillArea);
      expect(copy.drillType, source.drillType);
      expect(copy.metricSchemaId, source.metricSchemaId);
    });
  });

  // ---------------------------------------------------------------------------
  // Watch queries
  // ---------------------------------------------------------------------------
  group('Watch queries', () {
    test('watchStandardDrills returns test-seeded standard drill', () async {
      final drills = await repo.watchStandardDrills().first;
      expect(drills.length, 1);
      for (final drill in drills) {
        expect(drill.origin, DrillOrigin.standard);
        expect(drill.userId, isNull);
      }
    });

    test('watchAdoptedDrills returns adopted drills', () async {
      final systemDrills = await repo.watchStandardDrills().first;
      await repo.adoptDrill(userId, systemDrills[0].drillId);

      final adopted = await repo.watchAdoptedDrills(userId).first;
      expect(adopted.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Bag gate enforcement — S09 §9.3
  // ---------------------------------------------------------------------------
  group('Bag gate (S09 §9.3)', () {
    const otherUserId = 'user-no-clubs';

    test('createCustomDrill throws when no clubs for Skill Area', () async {
      // otherUserId has no clubs at all.
      expect(
        () => repo.createCustomDrill(
          otherUserId,
          customDrillCompanion(skillArea: SkillArea.driving),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('adoptDrill succeeds without clubs (gates moved to session start)', () async {
      // Validation gates removed from adoption — checked at session start.
      final systemDrills = await repo.watchStandardDrills().first;
      final adoption = await repo.adoptDrill(otherUserId, systemDrills.first.drillId);
      expect(adoption.drillId, systemDrills.first.drillId);
    });

    test('createCustomDrill TechniqueBlock passes without clubs', () async {
      // TechniqueBlock is exempt from bag gate.
      final drill = await repo.createCustomDrill(
        otherUserId,
        customDrillCompanion(
          name: 'Tech Block No Club',
          drillType: DrillType.techniqueBlock,
          subskillMapping: '[]',
          anchors: '{}',
          requiredAttemptsPerSet: null,
        ),
      );
      expect(drill.drillType, DrillType.techniqueBlock);
    });
  });
}
