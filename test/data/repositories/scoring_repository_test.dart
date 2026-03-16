import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Phase 2B — ScoringRepository tests.
// Uses in-memory Drift database with real seed data.

void main() {
  late AppDatabase db;
  late ScoringRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ScoringRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Lock management
  // ---------------------------------------------------------------------------
  group('Lock management', () {
    const userId = 'test-user-lock';

    test('acquireLock succeeds on first call', () async {
      expect(await repo.acquireLock(userId), isTrue);
    });

    test('acquireLock fails when lock is held', () async {
      expect(await repo.acquireLock(userId), isTrue);
      expect(await repo.acquireLock(userId), isFalse);
    });

    test('releaseLock allows re-acquisition', () async {
      await repo.acquireLock(userId);
      await repo.releaseLock(userId);
      expect(await repo.acquireLock(userId), isTrue);
    });

    test('hasExpiredLock returns false for no lock', () async {
      expect(await repo.hasExpiredLock(userId), isFalse);
    });

    test('hasExpiredLock returns false for active lock', () async {
      await repo.acquireLock(userId);
      expect(await repo.hasExpiredLock(userId), isFalse);
    });

    test('force-acquire on expired lock', () async {
      // Insert a lock that's already expired.
      final pastExpiry = DateTime.now().subtract(const Duration(seconds: 60));
      await db.into(db.userScoringLocks).insertOnConflictUpdate(
            UserScoringLocksCompanion.insert(
              userId: userId,
              isLocked: const Value(true),
              lockedAt: Value(DateTime.now().subtract(const Duration(seconds: 90))),
              lockExpiresAt: Value(pastExpiry),
            ),
          );
      // Should force-acquire since lock is expired.
      expect(await repo.acquireLock(userId), isTrue);
    });

    test('hasExpiredLock returns true for expired lock', () async {
      // Insert a lock that's already expired.
      final pastExpiry = DateTime.now().subtract(const Duration(seconds: 60));
      await db.into(db.userScoringLocks).insertOnConflictUpdate(
            UserScoringLocksCompanion.insert(
              userId: userId,
              isLocked: const Value(true),
              lockedAt: Value(DateTime.now().subtract(const Duration(seconds: 90))),
              lockExpiresAt: Value(pastExpiry),
            ),
          );
      expect(await repo.hasExpiredLock(userId), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Materialised CRUD
  // ---------------------------------------------------------------------------
  group('MaterialisedWindowState CRUD', () {
    const userId = 'test-user-mat';

    test('upsert and watch window state', () async {
      await repo.upsertWindowState(MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_distance_control',
        practiceType: DrillType.transition,
        entries: const Value('[]'),
        totalOccupancy: const Value(5.0),
        weightedSum: const Value(17.5),
        windowAverage: const Value(3.5),
      ));

      final results =
          await repo.watchWindowStatesByUser(userId).first;
      expect(results, hasLength(1));
      expect(results.first.subskill, 'approach_distance_control');
      expect(results.first.windowAverage, 3.5);
    });

    test('upsert overwrites existing row', () async {
      await repo.upsertWindowState(MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_distance_control',
        practiceType: DrillType.transition,
        windowAverage: const Value(3.0),
      ));
      await repo.upsertWindowState(MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_distance_control',
        practiceType: DrillType.transition,
        windowAverage: const Value(4.0),
      ));

      final results =
          await repo.watchWindowStatesByUser(userId).first;
      expect(results, hasLength(1));
      expect(results.first.windowAverage, 4.0);
    });

    test('deleteWindowStatesForUser removes all rows', () async {
      await repo.upsertWindowState(MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_distance_control',
        practiceType: DrillType.transition,
      ));
      await repo.upsertWindowState(MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_direction_control',
        practiceType: DrillType.pressure,
      ));

      final deleted = await repo.deleteWindowStatesForUser(userId);
      expect(deleted, 2);

      final results =
          await repo.watchWindowStatesByUser(userId).first;
      expect(results, isEmpty);
    });
  });

  group('MaterialisedSubskillScore CRUD', () {
    const userId = 'test-user-sub';

    test('upsert and watch subskill score', () async {
      await repo.upsertSubskillScore(
          MaterialisedSubskillScoresCompanion.insert(
        userId: userId,
        skillArea: SkillArea.driving,
        subskill: 'driving_distance_maximum',
        weightedAverage: const Value(3.5),
        subskillPoints: const Value(66.5),
        allocation: const Value(95),
      ));

      final results =
          await repo.watchSubskillScoresByUser(userId).first;
      expect(results, hasLength(1));
      expect(results.first.subskillPoints, 66.5);
    });
  });

  group('MaterialisedSkillAreaScore CRUD', () {
    const userId = 'test-user-sa';

    test('upsert and watch skill area score', () async {
      await repo.upsertSkillAreaScore(
          MaterialisedSkillAreaScoresCompanion.insert(
        userId: userId,
        skillArea: SkillArea.putting,
        skillAreaScore: const Value(120.0),
        allocation: const Value(200),
      ));

      final results =
          await repo.watchSkillAreaScoresByUser(userId).first;
      expect(results, hasLength(1));
      expect(results.first.skillAreaScore, 120.0);
    });
  });

  group('MaterialisedOverallScore CRUD', () {
    const userId = 'test-user-overall';

    test('upsert and watch overall score', () async {
      await repo.upsertOverallScore(MaterialisedOverallScoresCompanion.insert(
        userId: userId,
        overallScore: const Value(500.0),
      ));

      final result =
          await repo.watchOverallScoreByUser(userId).first;
      expect(result, isNotNull);
      expect(result!.overallScore, 500.0);
    });

    test('watch returns null for non-existent user', () async {
      final result =
          await repo.watchOverallScoreByUser('no-such-user').first;
      expect(result, isNull);
    });
  });

  group('truncateAllMaterialisedForUser', () {
    const userId = 'test-user-trunc';

    test('removes all 4 materialised table rows for user', () async {
      await repo.upsertWindowState(MaterialisedWindowStatesCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_distance_control',
        practiceType: DrillType.transition,
      ));
      await repo.upsertSubskillScore(
          MaterialisedSubskillScoresCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
        subskill: 'approach_distance_control',
      ));
      await repo.upsertSkillAreaScore(
          MaterialisedSkillAreaScoresCompanion.insert(
        userId: userId,
        skillArea: SkillArea.approach,
      ));
      await repo.upsertOverallScore(MaterialisedOverallScoresCompanion.insert(
        userId: userId,
      ));

      await repo.truncateAllMaterialisedForUser(userId);

      expect(await repo.watchWindowStatesByUser(userId).first, isEmpty);
      expect(await repo.watchSubskillScoresByUser(userId).first, isEmpty);
      expect(await repo.watchSkillAreaScoresByUser(userId).first, isEmpty);
      expect(await repo.watchOverallScoreByUser(userId).first, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Raw data queries
  // ---------------------------------------------------------------------------
  group('Raw data queries', () {
    const userId = 'test-user-raw';

    Future<void> seedDrillSessionAndInstances({
      required String drillId,
      required String sessionId,
      required String practiceBlockId,
      required String subskillMapping,
      required DrillType drillType,
      required SessionStatus sessionStatus,
      String metricSchemaId = 'grid_1x3_direction',
      bool sessionIsDeleted = false,
      bool drillIsDeleted = false,
      int instanceCount = 3,
    }) async {
      // Seed practice block.
      await db.into(db.practiceBlocks).insertOnConflictUpdate(
            PracticeBlocksCompanion.insert(
              practiceBlockId: practiceBlockId,
              userId: userId,
            ),
          );

      // Use one of the seeded system drills' metric schema for simplicity.
      await db.into(db.drills).insertOnConflictUpdate(DrillsCompanion.insert(
            drillId: drillId,
            name: 'Test Drill $drillId',
            skillArea: SkillArea.approach,
            drillType: drillType,
            inputMode: InputMode.gridCell,
            metricSchemaId: metricSchemaId,
            subskillMapping: Value(subskillMapping),
            origin: DrillOrigin.standard,
            isDeleted: Value(drillIsDeleted),
            anchors:
                const Value('{"approach_distance_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
          ));

      await db.into(db.sessions).insertOnConflictUpdate(
            SessionsCompanion.insert(
              sessionId: sessionId,
              drillId: drillId,
              practiceBlockId: practiceBlockId,
              status: Value(sessionStatus),
              isDeleted: Value(sessionIsDeleted),
              completionTimestamp: Value(DateTime(2026, 3, 1, 12, 0)),
            ),
          );

      // Create a set and instances.
      final setId = 'set-$sessionId';
      await db.into(db.sets).insertOnConflictUpdate(
            SetsCompanion.insert(
              setId: setId,
              sessionId: sessionId,
              setIndex: 0,
            ),
          );

      for (var i = 0; i < instanceCount; i++) {
        await db.into(db.instances).insertOnConflictUpdate(
              InstancesCompanion.insert(
                instanceId: 'inst-$sessionId-$i',
                setId: setId,
                selectedClub: Value('i7'),
                rawMetrics: '{"hit": true}',
              ),
            );
      }
    }

    test('getClosedSessionsForSubskill returns matching sessions', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-q1',
        sessionId: 'session-q1',
        practiceBlockId: 'block-q1',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.transition,
        sessionStatus: SessionStatus.closed,
      );

      final results = await repo.getClosedSessionsForSubskill(
        userId,
        'approach_distance_control',
        DrillType.transition,
      );
      expect(results, hasLength(1));
      expect(results.first.session.sessionId, 'session-q1');
      expect(results.first.drill.drillId, 'drill-q1');
    });

    test('getClosedSessionsForSubskill excludes active sessions', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-q2',
        sessionId: 'session-q2',
        practiceBlockId: 'block-q2',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.transition,
        sessionStatus: SessionStatus.active,
      );

      final results = await repo.getClosedSessionsForSubskill(
        userId,
        'approach_distance_control',
        DrillType.transition,
      );
      expect(results, isEmpty);
    });

    test('getClosedSessionsForSubskill excludes deleted sessions', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-q3',
        sessionId: 'session-q3',
        practiceBlockId: 'block-q3',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.transition,
        sessionStatus: SessionStatus.closed,
        sessionIsDeleted: true,
      );

      final results = await repo.getClosedSessionsForSubskill(
        userId,
        'approach_distance_control',
        DrillType.transition,
      );
      expect(results, isEmpty);
    });

    test('getClosedSessionsForSubskill excludes deleted drills', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-q4',
        sessionId: 'session-q4',
        practiceBlockId: 'block-q4',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.transition,
        sessionStatus: SessionStatus.closed,
        drillIsDeleted: true,
      );

      final results = await repo.getClosedSessionsForSubskill(
        userId,
        'approach_distance_control',
        DrillType.transition,
      );
      expect(results, isEmpty);
    });

    test('getClosedSessionsForSubskill filters by drillType', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-q5',
        sessionId: 'session-q5',
        practiceBlockId: 'block-q5',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.pressure,
        sessionStatus: SessionStatus.closed,
      );

      final transition = await repo.getClosedSessionsForSubskill(
        userId,
        'approach_distance_control',
        DrillType.transition,
      );
      expect(transition, isEmpty);

      final pressure = await repo.getClosedSessionsForSubskill(
        userId,
        'approach_distance_control',
        DrillType.pressure,
      );
      expect(pressure, hasLength(1));
    });

    test('getInstancesForSession returns correct instances', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-qi',
        sessionId: 'session-qi',
        practiceBlockId: 'block-qi',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.transition,
        sessionStatus: SessionStatus.closed,
        instanceCount: 5,
      );

      final instances = await repo.getInstancesForSession('session-qi');
      expect(instances, hasLength(5));
    });

    test('getDrillForSession returns correct drill', () async {
      await seedDrillSessionAndInstances(
        drillId: 'drill-qd',
        sessionId: 'session-qd',
        practiceBlockId: 'block-qd',
        subskillMapping: '["approach_distance_control"]',
        drillType: DrillType.transition,
        sessionStatus: SessionStatus.closed,
      );

      final drill = await repo.getDrillForSession('session-qd');
      expect(drill, isNotNull);
      expect(drill!.drillId, 'drill-qd');
    });

    test('getDrillForSession returns null for non-existent session', () async {
      final drill = await repo.getDrillForSession('no-such-session');
      expect(drill, isNull);
    });

    test('getMetricSchemaForDrill returns schema for inserted drill', () async {
      // Insert a test drill referencing a seeded metric schema.
      await db.into(db.drills).insert(DrillsCompanion.insert(
        drillId: 'drill-schema-test',
        name: 'Schema Test Drill',
        skillArea: SkillArea.putting,
        drillType: DrillType.transition,
        inputMode: InputMode.gridCell,
        metricSchemaId: 'grid_1x3_direction',
        origin: DrillOrigin.custom,
      ));
      final schema = await repo.getMetricSchemaForDrill('drill-schema-test');
      expect(schema, isNotNull);
      expect(schema!.metricSchemaId, 'grid_1x3_direction');
    });

    test('getSubskillRefs returns correct subset', () async {
      final refs = await repo.getSubskillRefs(
          {'approach_distance_control', 'approach_direction_control'});
      expect(refs, hasLength(2));
    });

    test('getSubskillRefsBySkillArea returns correct refs', () async {
      final refs = await repo.getSubskillRefsBySkillArea(SkillArea.putting);
      expect(refs, hasLength(2));
      expect(refs.map((r) => r.subskillId),
          containsAll(['putting_distance_control', 'putting_direction_control']));
    });

    test('getAllSubskillRefs returns all 19', () async {
      final refs = await repo.getAllSubskillRefs();
      expect(refs, hasLength(19));
    });
  });
}
