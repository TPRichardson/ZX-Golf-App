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
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Phase 4 — PracticeRepository business method tests.
// Covers: state machines (TD-04 §2.1–2.3), queue operations,
// session lifecycle, reflow triggers, endPracticeBlock.

void main() {
  late AppDatabase db;
  late PracticeRepository repo;
  late EventLogRepository eventLogRepo;
  late ReflowEngine reflowEngine;

  const userId = 'test-user-practice';

  // Seed drill IDs created during setUp.
  late String drillId1;
  late String drillId2;
  late String drillId3;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    eventLogRepo = EventLogRepository(db);
    final scoringRepo = ScoringRepository(db);
    final rebuildGuard = RebuildGuard();
    final syncWriteGate = SyncWriteGate();
    reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: rebuildGuard,
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    repo = PracticeRepository(db, reflowEngine, eventLogRepo);

    // Seed test drills using the raw drills table (bypassing DrillRepository
    // which would require its own dependencies).
    drillId1 = 'drill-grid-1';
    drillId2 = 'drill-raw-2';
    drillId3 = 'drill-tech-3';

    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId1,
      name: 'Grid Drill',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.system,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(9),
    ));

    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId2,
      name: 'Raw Data Drill',
      skillArea: SkillArea.driving,
      drillType: DrillType.pressure,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'raw_carry_distance',
      origin: DrillOrigin.system,
      subskillMapping: const Value('["driving_carry_distance"]'),
      anchors: const Value(
          '{"driving_carry_distance": {"Min": 150, "Scratch": 230, "Pro": 280}}'),
      requiredSetCount: const Value(2),
      requiredAttemptsPerSet: const Value(5),
    ));

    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId3,
      name: 'Technique Block',
      skillArea: SkillArea.chipping,
      drillType: DrillType.techniqueBlock,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'technique_duration',
      origin: DrillOrigin.system,
      subskillMapping: const Value('[]'),
      requiredSetCount: const Value(1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // PracticeBlock lifecycle
  // ---------------------------------------------------------------------------

  group('createPracticeBlock (TD-04 §2.3)', () {
    test('creates practice block with no initial drills', () async {
      final pb = await repo.createPracticeBlock(userId);
      expect(pb.userId, userId);
      expect(pb.endTimestamp, isNull);
      expect(pb.isDeleted, false);
    });

    test('creates practice block with initial drills as entries', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1, drillId2],
      );

      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      expect(entries.length, 2);
      expect(entries[0].drillId, drillId1);
      expect(entries[0].positionIndex, 0);
      expect(entries[1].drillId, drillId2);
      expect(entries[1].positionIndex, 1);
    });

    test('rejects second active practice block', () async {
      await repo.createPracticeBlock(userId);
      expect(
        () => repo.createPracticeBlock(userId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Queue operations
  // ---------------------------------------------------------------------------

  group('Queue operations (S13 §13.4)', () {
    late String pbId;

    setUp(() async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1, drillId2],
      );
      pbId = pb.practiceBlockId;
    });

    test('addDrillToQueue appends at end by default', () async {
      await repo.addDrillToQueue(pbId, drillId3);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      expect(entries.length, 3);
      expect(entries[2].drillId, drillId3);
      expect(entries[2].positionIndex, 2);
    });

    test('addDrillToQueue inserts at specified position', () async {
      await repo.addDrillToQueue(pbId, drillId3, position: 1);
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      expect(entries.length, 3);
      expect(entries[0].drillId, drillId1);
      expect(entries[0].positionIndex, 0);
      expect(entries[1].drillId, drillId3);
      expect(entries[1].positionIndex, 1);
      expect(entries[2].drillId, drillId2);
      expect(entries[2].positionIndex, 2);
    });

    test('removePendingEntry removes and reindexes', () async {
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      await repo.removePendingEntry(entries[0].practiceEntryId);

      final remaining = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      expect(remaining.length, 1);
      expect(remaining[0].drillId, drillId2);
      expect(remaining[0].positionIndex, 0);
    });

    test('reorderQueue updates positions', () async {
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      // Reverse the order.
      await repo.reorderQueue(
        pbId,
        [entries[1].practiceEntryId, entries[0].practiceEntryId],
      );

      final reordered = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      expect(reordered[0].drillId, drillId2);
      expect(reordered[1].drillId, drillId1);
    });

    test('duplicateEntry creates PendingDrill after source', () async {
      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      await repo.duplicateEntry(entries[0].practiceEntryId);

      final updated = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      expect(updated.length, 3);
      expect(updated[0].drillId, drillId1);
      expect(updated[1].drillId, drillId1); // Duplicate
      expect(updated[2].drillId, drillId2);
    });
  });

  // ---------------------------------------------------------------------------
  // Session lifecycle — TD-04 §2.2
  // ---------------------------------------------------------------------------

  group('Session lifecycle (TD-04 §2.2)', () {
    late String pbId;
    late String entryId1;
    late String entryId2;

    setUp(() async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1, drillId2],
      );
      pbId = pb.practiceBlockId;

      final entries = await (db.select(db.practiceEntries)
            ..where((t) => t.practiceBlockId.equals(pbId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();
      entryId1 = entries[0].practiceEntryId;
      entryId2 = entries[1].practiceEntryId;
    });

    test('startSession creates Session + first Set, updates entry to ActiveSession',
        () async {
      final session = await repo.startSession(entryId1, userId);
      expect(session.drillId, drillId1);
      expect(session.status, SessionStatus.active);
      expect(session.practiceBlockId, pbId);

      // Entry updated to ActiveSession.
      final entry = await repo.getPracticeEntryById(entryId1);
      expect(entry!.entryType, PracticeEntryType.activeSession);
      expect(entry.sessionId, session.sessionId);

      // First set created.
      final sets = await (db.select(db.sets)
            ..where((t) => t.sessionId.equals(session.sessionId)))
          .get();
      expect(sets.length, 1);
      expect(sets.first.setIndex, 0);
    });

    test('startSession enforces single active session', () async {
      await repo.startSession(entryId1, userId);

      expect(
        () => repo.startSession(entryId2, userId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.singleActiveSession,
        )),
      );
    });

    test('startSession rejects non-PendingDrill entry', () async {
      await repo.startSession(entryId1, userId);

      expect(
        () => repo.startSession(entryId1, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('discardSession hard-deletes all data, resets entry to PendingDrill',
        () async {
      final session = await repo.startSession(entryId1, userId);

      // Log some instances.
      final currentSet = await repo.getCurrentSet(session.sessionId);
      await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-1',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );

      // Discard.
      await repo.discardSession(entryId1);

      // Entry back to PendingDrill.
      final entry = await repo.getPracticeEntryById(entryId1);
      expect(entry!.entryType, PracticeEntryType.pendingDrill);
      expect(entry.sessionId, isNull);

      // Session, sets, instances hard-deleted.
      final sessions = await (db.select(db.sessions)
            ..where((t) => t.sessionId.equals(session.sessionId)))
          .get();
      expect(sessions, isEmpty);

      final sets = await (db.select(db.sets)
            ..where((t) => t.sessionId.equals(session.sessionId)))
          .get();
      expect(sets, isEmpty);
    });

    test('logInstance creates instance in active session', () async {
      final session = await repo.startSession(entryId1, userId);
      final currentSet = await repo.getCurrentSet(session.sessionId);

      final instance = await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-1',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );

      expect(instance.setId, currentSet.setId);
      expect(instance.selectedClub, 'Putter');
    });

    test('logInstance rejects on non-active session', () async {
      expect(
        () => repo.logInstance(
          'nonexistent-set',
          InstancesCompanion.insert(
            instanceId: 'inst-1',
            setId: 'nonexistent-set',
            selectedClub: 'Putter',
            rawMetrics: '{}',
          ),
          'nonexistent-session',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('advanceSet creates next set with incremented index', () async {
      final session = await repo.startSession(entryId1, userId);

      final set2 = await repo.advanceSet(session.sessionId);
      expect(set2.setIndex, 1);
      expect(set2.sessionId, session.sessionId);

      final set3 = await repo.advanceSet(session.sessionId);
      expect(set3.setIndex, 2);
    });

    test('endSession calls ReflowEngine.closeSession and updates entry',
        () async {
      final session = await repo.startSession(entryId1, userId);

      // Log an instance so the session has data.
      final currentSet = await repo.getCurrentSet(session.sessionId);
      await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-grid-1',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );

      final result = await repo.endSession(session.sessionId, userId);
      expect(result.sessionId, session.sessionId);
      expect(result.drillId, drillId1);

      // Session status is now Closed.
      final closedSession = await repo.getSessionById(session.sessionId);
      expect(closedSession!.status, SessionStatus.closed);

      // Entry updated to CompletedSession.
      final entry = await repo.getPracticeEntryById(entryId1);
      expect(entry!.entryType, PracticeEntryType.completedSession);
    });

    test('endSession rejects non-active session', () async {
      expect(
        () => repo.endSession('nonexistent', userId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PracticeBlock end — S13 §13.10
  // ---------------------------------------------------------------------------

  group('endPracticeBlock (S13 §13.10)', () {
    test('discards when 0 completed sessions', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );

      await repo.endPracticeBlock(pb.practiceBlockId, userId);

      // PB soft-deleted (since 0 sessions).
      final deleted = await (db.select(db.practiceBlocks)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .getSingleOrNull();
      expect(deleted!.isDeleted, true);
    });

    test('closes normally with completed sessions', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      // Start and end a session.
      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);
      final currentSet = await repo.getCurrentSet(session.sessionId);
      await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-for-close',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );
      await repo.endSession(session.sessionId, userId);

      await repo.endPracticeBlock(pb.practiceBlockId, userId);

      // PB has endTimestamp set, NOT deleted.
      final closed =
          await repo.getPracticeBlockById(pb.practiceBlockId);
      expect(closed!.endTimestamp, isNotNull);
      expect(closed.closureType, ClosureType.manual);
      expect(closed.isDeleted, false);
    });

    test('rejects with active session', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      await repo.startSession(entries.first.practiceEntryId, userId);

      expect(
        () => repo.endPracticeBlock(pb.practiceBlockId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('hard-deletes pending entries on close', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1, drillId2],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      // Complete first drill.
      final session =
          await repo.startSession(entries[0].practiceEntryId, userId);
      final currentSet = await repo.getCurrentSet(session.sessionId);
      await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-for-close2',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );
      await repo.endSession(session.sessionId, userId);

      // End block — second entry (pending) should be deleted.
      await repo.endPracticeBlock(pb.practiceBlockId, userId);

      final remaining = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      expect(remaining.length, 1); // Only the completed one.
      expect(
          remaining.first.entryType, PracticeEntryType.completedSession);
    });
  });

  // ---------------------------------------------------------------------------
  // PracticeEntry state transitions — TD-04 §2.1
  // ---------------------------------------------------------------------------

  group('PracticeEntry state transitions (TD-04 §2.1)', () {
    test('PendingDrill → ActiveSession via startSession', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();
      expect(entries.first.entryType, PracticeEntryType.pendingDrill);

      await repo.startSession(entries.first.practiceEntryId, userId);

      final updated =
          await repo.getPracticeEntryById(entries.first.practiceEntryId);
      expect(updated!.entryType, PracticeEntryType.activeSession);
    });

    test('ActiveSession → PendingDrill via discardSession', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      await repo.startSession(entries.first.practiceEntryId, userId);
      await repo.discardSession(entries.first.practiceEntryId);

      final updated =
          await repo.getPracticeEntryById(entries.first.practiceEntryId);
      expect(updated!.entryType, PracticeEntryType.pendingDrill);
    });

    test('ActiveSession → CompletedSession via endSession', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);
      final currentSet = await repo.getCurrentSet(session.sessionId);
      await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-state-transition',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );
      await repo.endSession(session.sessionId, userId);

      final updated =
          await repo.getPracticeEntryById(entries.first.practiceEntryId);
      expect(updated!.entryType, PracticeEntryType.completedSession);
    });

    test('removePendingEntry rejects non-PendingDrill', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      await repo.startSession(entries.first.practiceEntryId, userId);

      expect(
        () => repo.removePendingEntry(entries.first.practiceEntryId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Post-close editing — reflow triggers
  // ---------------------------------------------------------------------------

  group('Post-close editing (reflow triggers)', () {
    late String sessionId;
    late String setId;
    late String instanceId;

    setUp(() async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);
      sessionId = session.sessionId;
      final currentSet = await repo.getCurrentSet(sessionId);
      setId = currentSet!.setId;

      final inst = await repo.logInstance(
        setId,
        InstancesCompanion.insert(
          instanceId: 'inst-for-edit',
          setId: setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        sessionId,
      );
      instanceId = inst.instanceId;

      // Close session.
      await repo.endSession(sessionId, userId);
    });

    test('updateInstance on Closed Session triggers reflow (no throw)',
        () async {
      // This should succeed and trigger reflow internally.
      final updated = await repo.updateInstance(
        instanceId,
        InstancesCompanion(
          rawMetrics: const Value('{"hit": false}'),
        ),
        userId,
      );
      expect(updated.rawMetrics, '{"hit": false}');
    });

    test('deleteInstance on Closed Session triggers reflow (no throw)',
        () async {
      await repo.deleteInstance(instanceId, userId);

      // Instance should be soft-deleted.
      final instance = await (db.select(db.instances)
            ..where((t) => t.instanceId.equals(instanceId)))
          .getSingleOrNull();
      expect(instance!.isDeleted, true);
    });
  });

  // ---------------------------------------------------------------------------
  // removeCompletedEntry
  // ---------------------------------------------------------------------------

  group('removeCompletedEntry (#6)', () {
    test('soft-deletes session, triggers reflow, removes entry', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      final session =
          await repo.startSession(entries.first.practiceEntryId, userId);
      final currentSet = await repo.getCurrentSet(session.sessionId);
      await repo.logInstance(
        currentSet!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-for-remove',
          setId: currentSet.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session.sessionId,
      );
      await repo.endSession(session.sessionId, userId);

      await repo.removeCompletedEntry(
          entries.first.practiceEntryId, userId);

      // Entry hard-deleted.
      final entry =
          await repo.getPracticeEntryById(entries.first.practiceEntryId);
      expect(entry, isNull);

      // Session soft-deleted.
      final deletedSession = await (db.select(db.sessions)
            ..where((t) => t.sessionId.equals(session.sessionId)))
          .getSingleOrNull();
      expect(deletedSession!.isDeleted, true);
    });

    test('rejects removal of non-CompletedSession entry', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId)))
          .get();

      expect(
        () => repo.removeCompletedEntry(
            entries.first.practiceEntryId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('blocked when ActiveSession exists in block', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1, drillId2],
      );
      final entries = await (db.select(db.practiceEntries)
            ..where(
                (t) => t.practiceBlockId.equals(pb.practiceBlockId))
            ..orderBy([(t) => OrderingTerm.asc(t.positionIndex)]))
          .get();

      // Complete first session.
      final session1 =
          await repo.startSession(entries[0].practiceEntryId, userId);
      final set1 = await repo.getCurrentSet(session1.sessionId);
      await repo.logInstance(
        set1!.setId,
        InstancesCompanion.insert(
          instanceId: 'inst-block-test',
          setId: set1.setId,
          selectedClub: 'Putter',
          rawMetrics: '{"hit": true}',
        ),
        session1.sessionId,
      );
      await repo.endSession(session1.sessionId, userId);

      // Start second session.
      await repo.startSession(entries[1].practiceEntryId, userId);

      // Try to remove completed entry while active session exists.
      expect(
        () => repo.removeCompletedEntry(
            entries[0].practiceEntryId, userId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // watchPracticeBlock composite stream
  // ---------------------------------------------------------------------------

  group('watchPracticeBlock (#2)', () {
    test('emits PracticeBlockWithEntries', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        initialDrillIds: [drillId1],
      );

      final result =
          await repo.watchPracticeBlock(pb.practiceBlockId).first;
      expect(result, isNotNull);
      expect(result!.practiceBlock.practiceBlockId, pb.practiceBlockId);
      expect(result.entries.length, 1);
      expect(result.entries.first.drill.name, 'Grid Drill');
      expect(result.entries.first.session, isNull);
    });
  });
}
