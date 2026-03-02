// Phase 4 — Post-Close Editing + Reflow Tests.
// Verifies that editing/deleting instances on closed sessions triggers reflow,
// and that edits on active sessions do NOT trigger reflow.

import 'package:drift/drift.dart' hide isNotNull, isNull;
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

void main() {
  late AppDatabase db;
  late PracticeRepository repo;
  late ReflowInstrumentation instrumentation;

  const userId = 'test-user-edit';

  late String rawDrillId;
  late String gridDrillId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final eventLogRepo = EventLogRepository(db);
    final scoringRepo = ScoringRepository(db);
    instrumentation = ReflowInstrumentation();
    final reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: SyncWriteGate(),
      database: db,
      instrumentation: instrumentation,
    );
    repo = PracticeRepository(db, reflowEngine, eventLogRepo);

    // Seed raw data drill: 1 set × 3 attempts.
    rawDrillId = 'drill-edit-raw';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: rawDrillId,
      name: 'Edit Test Raw',
      skillArea: SkillArea.driving,
      drillType: DrillType.transition,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'raw_carry_distance',
      origin: DrillOrigin.system,
      subskillMapping: const Value('["driving_distance_maximum"]'),
      anchors: const Value(
          '{"driving_distance_maximum": {"Min": 180, "Scratch": 250, "Pro": 300}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(3),
    ));

    // Seed grid drill: 1 set × 3 attempts.
    gridDrillId = 'drill-edit-grid';
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: gridDrillId,
      name: 'Edit Test Grid',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.system,
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

  /// Start a drill, log instances, close the session.
  /// Returns session + actual instance IDs (from the repo, not the input).
  Future<(Session, List<String>)> createClosedSession(String drillId) async {
    final pb =
        await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
    final entries = await (db.select(db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
        .get();
    final session =
        await repo.startSession(entries.first.practiceEntryId, userId);

    // Get the set.
    final set = await repo.getCurrentSet(session.sessionId);

    // Log 3 instances and capture returned IDs.
    final instanceIds = <String>[];
    for (var i = 0; i < 3; i++) {
      final rawMetrics = drillId == rawDrillId
          ? '{"value": ${200 + i * 20}}'
          : '{"hit": true}';
      final instance = await repo.logInstance(
        set!.setId,
        InstancesCompanion.insert(
          instanceId: 'ignored', // Will be replaced by repo.
          setId: set.setId,
          selectedClub: 'Default',
          rawMetrics: rawMetrics,
        ),
        session.sessionId,
      );
      instanceIds.add(instance.instanceId);
    }

    // Close session.
    await repo.endSession(session.sessionId, userId);

    // Get fresh session (now closed).
    final closedSession = await repo.getSessionById(session.sessionId);
    return (closedSession!, instanceIds);
  }

  /// Start a drill, log an instance, return session (still active) + instance ID.
  Future<(Session, String)> createActiveSession(String drillId) async {
    final pb =
        await repo.createPracticeBlock(userId, initialDrillIds: [drillId]);
    final entries = await (db.select(db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
        .get();
    final session =
        await repo.startSession(entries.first.practiceEntryId, userId);

    final set = await repo.getCurrentSet(session.sessionId);

    final instance = await repo.logInstance(
      set!.setId,
      InstancesCompanion.insert(
        instanceId: 'ignored',
        setId: set.setId,
        selectedClub: 'Default',
        rawMetrics: '{"value": 250}',
      ),
      session.sessionId,
    );

    return (session, instance.instanceId);
  }

  group('Post-close editing', () {
    test('edit Instance on Closed Session triggers reflow', () async {
      final (session, instanceIds) = await createClosedSession(rawDrillId);
      expect(session.status, SessionStatus.closed);

      // Count reflow diagnostics before edit.
      final diagsBefore = instrumentation.diagnostics.length;

      // Edit an instance.
      await repo.updateInstance(
        instanceIds.first,
        const InstancesCompanion(
          rawMetrics: Value('{"value": 270}'),
        ),
        userId,
      );

      // Reflow should have been triggered (new diagnostic entry).
      final diagsAfter = instrumentation.diagnostics.length;
      expect(diagsAfter, greaterThan(diagsBefore));
    });

    test('delete Instance on Closed Session triggers reflow', () async {
      final (session, instanceIds) = await createClosedSession(gridDrillId);
      expect(session.status, SessionStatus.closed);

      final diagsBefore = instrumentation.diagnostics.length;

      // Delete an instance.
      await repo.deleteInstance(instanceIds.first, userId);

      // Verify instance is soft-deleted (query DB directly to bypass filter).
      final deletedInstance = await (db.select(db.instances)
            ..where((t) => t.instanceId.equals(instanceIds.first)))
          .getSingleOrNull();
      expect(deletedInstance!.isDeleted, true);

      // Reflow should have been triggered.
      final diagsAfter = instrumentation.diagnostics.length;
      expect(diagsAfter, greaterThan(diagsBefore));
    });

    test('edit Instance on Active Session does NOT trigger reflow', () async {
      final (session, instId) = await createActiveSession(rawDrillId);
      expect(session.status, SessionStatus.active);

      final diagsBefore = instrumentation.diagnostics.length;

      // Edit an instance on active session.
      await repo.updateInstance(
        instId,
        const InstancesCompanion(
          rawMetrics: Value('{"value": 270}'),
        ),
        userId,
      );

      // No reflow should fire on active session.
      final diagsAfter = instrumentation.diagnostics.length;
      expect(diagsAfter, diagsBefore);
    });

    test('removeCompletedEntry triggers reflow', () async {
      final (session, _) = await createClosedSession(rawDrillId);
      expect(session.status, SessionStatus.closed);

      // Find the entry.
      final entry =
          await repo.getPracticeEntryBySessionId(session.sessionId);
      expect(entry, isNotNull);

      final diagsBefore = instrumentation.diagnostics.length;

      // Remove completed entry.
      await repo.removeCompletedEntry(entry!.practiceEntryId, userId);

      // Reflow should fire for session deletion.
      final diagsAfter = instrumentation.diagnostics.length;
      expect(diagsAfter, greaterThan(diagsBefore));
    });
  });
}
