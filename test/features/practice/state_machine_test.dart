// Phase 4 — State Machine Exhaustive Tests.
// TD-04 §2.1 (PracticeEntry), §2.2 (Session), §2.3 (PracticeBlock).
// Every valid and invalid transition.

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
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

void main() {
  late AppDatabase db;
  late PracticeRepository repo;

  const userId = 'test-user-sm';
  late String drillId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final eventLogRepo = EventLogRepository(db, SyncWriteGate());
    final scoringRepo = ScoringRepository(db);
    final reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: SyncWriteGate(),
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    repo = PracticeRepository(db, reflowEngine, eventLogRepo, SyncWriteGate());

    // S09 §9.3 — Seed clubs so bag gate passes for Putting and Irons.
    final clubRepo = ClubRepository(db, SyncWriteGate());
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.i7)));

    // Seed a structured drill: 1 set × 3 attempts.
    drillId = 'drill-sm';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId,
      name: 'State Machine Drill',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'binary_hit_miss',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(3),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // TD-04 §2.1 — PracticeEntry State Machine
  // States: PendingDrill, ActiveSession, CompletedSession
  // ---------------------------------------------------------------------------

  group('PracticeEntry state machine (TD-04 §2.1)', () {
    test('PendingDrill → ActiveSession via startSession', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final entry = entries.first;
      expect(entry.entryType, PracticeEntryType.pendingDrill);

      await repo.startSession(entry.practiceEntryId, userId);

      final updated = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceEntryId.equals(entry.practiceEntryId)))
          .getSingle();
      expect(updated.entryType, PracticeEntryType.activeSession);
      expect(updated.sessionId, isNotNull);
    });

    test('ActiveSession → CompletedSession via endSession', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);

      // Log instances.
      final set = await repo.getCurrentSet(session.sessionId);
      for (var i = 0; i < 3; i++) {
        await repo.logInstance(
          set!.setId,
          InstancesCompanion.insert(
            instanceId: 'ignored',
            setId: set.setId,
            selectedClub: Value('Putter'),
            rawMetrics: '{"hit": true}',
          ),
          session.sessionId,
        );
      }

      await repo.endSession(session.sessionId, userId);

      final updated = await (db.select(db.practiceEntries)
            ..where((t) =>
                t.practiceEntryId.equals(entries.first.practiceEntryId)))
          .getSingle();
      expect(updated.entryType, PracticeEntryType.completedSession);
    });

    test('ActiveSession → PendingDrill via discardSession', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      await repo.startSession(entries.first.practiceEntryId, userId);

      await repo.discardSession(entries.first.practiceEntryId);

      final updated = await (db.select(db.practiceEntries)
            ..where((t) =>
                t.practiceEntryId.equals(entries.first.practiceEntryId)))
          .getSingle();
      expect(updated.entryType, PracticeEntryType.pendingDrill);
      expect(updated.sessionId, isNull);
    });

    test('removePendingEntry only works on PendingDrill', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      // Start session → ActiveSession.
      await repo.startSession(entries.first.practiceEntryId, userId);

      // Cannot remove ActiveSession entry.
      expect(
        () => repo.removePendingEntry(entries.first.practiceEntryId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // TD-04 §2.2 — Session State Machine
  // States: Active, Closed, Discarded
  // ---------------------------------------------------------------------------

  group('Session state machine (TD-04 §2.2)', () {
    test('Active → Closed via endSession', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);

      expect(session.status, SessionStatus.active);

      final set = await repo.getCurrentSet(session.sessionId);
      for (var i = 0; i < 3; i++) {
        await repo.logInstance(
          set!.setId,
          InstancesCompanion.insert(
            instanceId: 'ignored',
            setId: set.setId,
            selectedClub: Value('Putter'),
            rawMetrics: '{"hit": true}',
          ),
          session.sessionId,
        );
      }

      await repo.endSession(session.sessionId, userId);

      final closedSession = await repo.getSessionById(session.sessionId);
      expect(closedSession!.status, SessionStatus.closed);
      expect(closedSession.completionTimestamp, isNotNull);
    });

    test('Active → Discarded via discardSession', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);
      expect(session.status, SessionStatus.active);

      await repo.discardSession(entries.first.practiceEntryId);

      // Session should be hard-deleted.
      final discardedSession =
          await repo.getSessionById(session.sessionId);
      expect(discardedSession, isNull);
    });

    test('cannot end a Closed session', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);

      final set = await repo.getCurrentSet(session.sessionId);
      for (var i = 0; i < 3; i++) {
        await repo.logInstance(
          set!.setId,
          InstancesCompanion.insert(
            instanceId: 'ignored',
            setId: set.setId,
            selectedClub: Value('Putter'),
            rawMetrics: '{"hit": true}',
          ),
          session.sessionId,
        );
      }

      await repo.endSession(session.sessionId, userId);

      // Try to end again — should fail.
      expect(
        () => repo.endSession(session.sessionId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cannot log instance on Closed session', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);

      final set = await repo.getCurrentSet(session.sessionId);
      for (var i = 0; i < 3; i++) {
        await repo.logInstance(
          set!.setId,
          InstancesCompanion.insert(
            instanceId: 'ignored',
            setId: set.setId,
            selectedClub: Value('Putter'),
            rawMetrics: '{"hit": true}',
          ),
          session.sessionId,
        );
      }

      await repo.endSession(session.sessionId, userId);

      // Try to log instance on closed session.
      expect(
        () => repo.logInstance(
          set!.setId,
          InstancesCompanion.insert(
            instanceId: 'ignored',
            setId: set.setId,
            selectedClub: Value('Putter'),
            rawMetrics: '{"hit": true}',
          ),
          session.sessionId,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // TD-04 §2.3 — PracticeBlock Lifecycle
  // ---------------------------------------------------------------------------

  group('PracticeBlock lifecycle (TD-04 §2.3)', () {
    test('single-active-session enforcement', () async {
      // Need two drills.
      await db.into(db.drills).insert(DrillsCompanion.insert(
        drillId: 'drill-sm-2',
        name: 'SM Drill 2',
        skillArea: SkillArea.approach,
        drillType: DrillType.transition,
        inputMode: InputMode.binaryHitMiss,
        metricSchemaId: 'binary_hit_miss',
        origin: DrillOrigin.standard,
        subskillMapping: const Value('["approach_direction_control"]'),
        anchors: const Value(
            '{"approach_direction_control": {"Min": 30, "Scratch": 70, "Pro": 90}}'),
        requiredSetCount: const Value(1),
      ));

      final pb = await repo.createPracticeBlock(userId,
          initialDrillIds: [drillId, 'drill-sm-2']);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      // Start first session.
      await repo.startSession(entries[0].practiceEntryId, userId);

      // Try to start second session — should fail.
      expect(
        () => repo.startSession(entries[1].practiceEntryId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('cannot end PB with active session', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      await repo.startSession(entries.first.practiceEntryId, userId);

      expect(
        () => repo.endPracticeBlock(pb.practiceBlockId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('endPracticeBlock with 0 sessions: soft-deletes', () async {
      final pb = await repo.createPracticeBlock(userId,
          initialDrillIds: [drillId]);

      await repo.endPracticeBlock(pb.practiceBlockId, userId);

      // Query DB directly to bypass IsDeleted filter.
      final deleted = await (db.select(db.practiceBlocks)
            ..where((t) =>
                t.practiceBlockId.equals(pb.practiceBlockId)))
          .getSingleOrNull();
      expect(deleted!.isDeleted, true);
    });

    test('endPracticeBlock with completed session: closes normally', () async {
      final pb =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);

      final set = await repo.getCurrentSet(session.sessionId);
      for (var i = 0; i < 3; i++) {
        await repo.logInstance(
          set!.setId,
          InstancesCompanion.insert(
            instanceId: 'ignored',
            setId: set.setId,
            selectedClub: Value('Putter'),
            rawMetrics: '{"hit": true}',
          ),
          session.sessionId,
        );
      }
      await repo.endSession(session.sessionId, userId);

      await repo.endPracticeBlock(pb.practiceBlockId, userId);

      final closedPb =
          await repo.getPracticeBlockById(pb.practiceBlockId);
      expect(closedPb!.endTimestamp, isNotNull);
      expect(closedPb.isDeleted, false);
    });

    test('second createPracticeBlock auto-closes the first', () async {
      final first =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);

      final second =
          await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);

      // First block should now be closed.
      final reloaded = await (db.select(db.practiceBlocks)
            ..where((t) => t.practiceBlockId.equals(first.practiceBlockId)))
          .getSingle();
      expect(reloaded.endTimestamp, isNotNull);
      // Second block is the new active one.
      expect(second.endTimestamp, isNull);
    });
  });
}
