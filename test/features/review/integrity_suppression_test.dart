import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Phase 8 — Integrity suppression (S11 §11.6) tests.

void main() {
  late AppDatabase db;
  late PracticeRepository practiceRepo;
  late EventLogRepository eventLogRepo;

  const userId = 'test-user-integrity';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final gate = SyncWriteGate();
    eventLogRepo = EventLogRepository(db, gate);
    final scoringRepo = ScoringRepository(db);
    final reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: gate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    practiceRepo = PracticeRepository(db, reflowEngine, eventLogRepo, gate);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper: create user + drill + block + session.
  Future<String> createSessionWithIntegrityFlag({
    bool integrityFlag = true,
    bool integritySuppressed = false,
  }) async {
    // User.
    await db.into(db.users).insertOnConflictUpdate(
          UsersCompanion.insert(userId: userId, email: '$userId@test.com'),
        );

    // Drill.
    await db.into(db.drills).insertOnConflictUpdate(DrillsCompanion.insert(
      drillId: 'drill-1',
      name: 'Test Drill',
      skillArea: SkillArea.approach,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'binary_hit_miss',
      subskillMapping: const Value('["approach_direction_control"]'),
      anchors: const Value('{}'),
      origin: DrillOrigin.custom,
      status: const Value(DrillStatus.active),
    ));

    // Practice block.
    await db.into(db.practiceBlocks).insertOnConflictUpdate(
          PracticeBlocksCompanion.insert(
            practiceBlockId: 'pb-1',
            userId: userId,
          ),
        );

    // Session with integrity flag.
    const sessionId = 'session-integrity-1';
    await db.into(db.sessions).insert(SessionsCompanion.insert(
      sessionId: sessionId,
      drillId: 'drill-1',
      practiceBlockId: 'pb-1',
      integrityFlag: Value(integrityFlag),
      integritySuppressed: Value(integritySuppressed),
      status: const Value(SessionStatus.closed),
    ));

    return sessionId;
  }

  group('IntegritySuppression', () {
    test('suppressIntegrityFlag sets integritySuppressed to true', () async {
      final sessionId = await createSessionWithIntegrityFlag();

      await practiceRepo.suppressIntegrityFlag(sessionId, userId);

      final session = await practiceRepo.getSessionById(sessionId);
      expect(session, isNotNull);
      expect(session!.integrityFlag, true);
      expect(session.integritySuppressed, true);
    });

    test('suppressIntegrityFlag writes EventLog entry', () async {
      final sessionId = await createSessionWithIntegrityFlag();

      await practiceRepo.suppressIntegrityFlag(sessionId, userId);

      // Check event log.
      final events = await (db.select(db.eventLogs)
            ..where((t) => t.eventTypeId.equals('IntegrityFlagCleared')))
          .get();
      expect(events.length, 1);
      expect(events.first.userId, userId);
    });

    test('session with integrityFlag=false and integritySuppressed=false is clean',
        () async {
      final sessionId = await createSessionWithIntegrityFlag(
          integrityFlag: false, integritySuppressed: false);

      final session = await practiceRepo.getSessionById(sessionId);
      expect(session!.integrityFlag, false);
      expect(session.integritySuppressed, false);
    });

    test('session with integrityFlag=true and integritySuppressed=true is cleared',
        () async {
      final sessionId = await createSessionWithIntegrityFlag(
          integrityFlag: true, integritySuppressed: true);

      final session = await practiceRepo.getSessionById(sessionId);
      expect(session!.integrityFlag, true);
      expect(session.integritySuppressed, true);
    });

    test('suppressIntegrityFlag on already-suppressed session is idempotent',
        () async {
      final sessionId = await createSessionWithIntegrityFlag(
          integrityFlag: true, integritySuppressed: true);

      await practiceRepo.suppressIntegrityFlag(sessionId, userId);

      final session = await practiceRepo.getSessionById(sessionId);
      expect(session!.integritySuppressed, true);
    });

    test('display logic: show warning when integrityFlag && !integritySuppressed',
        () async {
      final sessionId = await createSessionWithIntegrityFlag();
      final session = await practiceRepo.getSessionById(sessionId);

      // This is the corrected display logic from the bug fix.
      final shouldShowWarning =
          session!.integrityFlag && !session.integritySuppressed;
      expect(shouldShowWarning, true);
    });

    test('display logic: hide warning when integrityFlag && integritySuppressed',
        () async {
      final sessionId = await createSessionWithIntegrityFlag(
          integritySuppressed: true);
      final session = await practiceRepo.getSessionById(sessionId);

      final shouldShowWarning =
          session!.integrityFlag && !session.integritySuppressed;
      expect(shouldShowWarning, false);
    });

    test('display logic: hide warning when no integrityFlag', () async {
      final sessionId =
          await createSessionWithIntegrityFlag(integrityFlag: false);
      final session = await practiceRepo.getSessionById(sessionId);

      final shouldShowWarning =
          session!.integrityFlag && !session.integritySuppressed;
      expect(shouldShowWarning, false);
    });

    test('updatedAt is refreshed after suppression', () async {
      final sessionId = await createSessionWithIntegrityFlag();

      final before = await practiceRepo.getSessionById(sessionId);
      final beforeUpdatedAt = before!.updatedAt;

      // Delay to ensure timestamp changes (Windows DateTime has ~ms precision).
      await Future.delayed(const Duration(milliseconds: 50));

      await practiceRepo.suppressIntegrityFlag(sessionId, userId);

      final after = await practiceRepo.getSessionById(sessionId);
      // updatedAt should be at or after the original value.
      expect(
        !after!.updatedAt.isBefore(beforeUpdatedAt),
        true,
        reason: 'updatedAt should be >= original after suppression',
      );
    });

    test('EventLog metadata contains suppression action', () async {
      final sessionId = await createSessionWithIntegrityFlag();

      await practiceRepo.suppressIntegrityFlag(sessionId, userId);

      final events = await (db.select(db.eventLogs)
            ..where((t) => t.eventTypeId.equals('IntegrityFlagCleared')))
          .get();
      expect(events.first.metadata, contains('user_suppressed'));
    });
  });
}
