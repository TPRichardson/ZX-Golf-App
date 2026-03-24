import 'dart:convert';

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

import '../../fixtures/scoring_fixtures.dart';

// Fix 9 — Integrity flag auto-resolution.
// After Instance edit, if no Instance is in breach, auto-clear integrityFlag.

void main() {
  late AppDatabase db;
  late PracticeRepository repo;

  const userId = 'test-user-integrity-resolve';

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
    repo = PracticeRepository(db, reflowEngine, eventLogRepo, syncWriteGate);

    // Seed user.
    await db.into(db.users).insert(UsersCompanion.insert(
          userId: userId,
          email: 'test@example.com',
          displayName: const Value('Test User'),
        ));

    // Seed drill with raw_carry_distance schema (linearInterpolation).
    // HardMinInput: 0, HardMaxInput: 500 in seed data.
    await db.into(db.drills).insertOnConflictUpdate(DrillsCompanion.insert(
      drillId: 'integrity-drill',
      name: 'Integrity Test Drill',
      skillArea: SkillArea.approach,
      drillType: DrillType.transition,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'raw_carry_distance',
      subskillMapping: const Value('["approach_direction_control"]'),
      origin: DrillOrigin.custom,
      anchors: const Value(
          '{"approach_direction_control": {"Min": 10, "Scratch": 50, "Pro": 90}}'),
      requiredAttemptsPerSet: const Value(null),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  group('Fix 9: Integrity flag auto-resolution', () {
    test(
        'Edit Instance to within bounds auto-clears integrity flag',
        () async {
      final pbId = await seedPracticeBlock(db, userId);
      final sessionId = 'session-integrity';

      // Create a closed session with integrityFlag=true.
      await db.into(db.sessions).insertOnConflictUpdate(
            SessionsCompanion.insert(
              sessionId: sessionId,
              drillId: 'integrity-drill',
              practiceBlockId: pbId,
              status: const Value(SessionStatus.closed),
              completionTimestamp: Value(DateTime.now()),
              integrityFlag: const Value(true),
            ),
          );

      final setId = 'set-integrity';
      await db.into(db.sets).insertOnConflictUpdate(
            SetsCompanion.insert(
              setId: setId,
              sessionId: sessionId,
              setIndex: 0,
            ),
          );

      // Instance with value within bounds (0–500).
      await db.into(db.instances).insertOnConflictUpdate(
            InstancesCompanion.insert(
              instanceId: 'inst-integrity-1',
              setId: setId,
              selectedClub: Value('i7'),
              rawMetrics: jsonEncode({'value': 50.0}),
            ),
          );

      // Edit the instance to a value still within bounds.
      await repo.updateInstance(
        'inst-integrity-1',
        InstancesCompanion(
          rawMetrics: Value(jsonEncode({'value': 100.0})),
        ),
        userId,
      );

      // Verify integrity flag was auto-cleared.
      final session = await repo.getSessionById(sessionId);
      expect(session, isNotNull);
      expect(session!.integrityFlag, isFalse);
      expect(session.integritySuppressed, isFalse);
    });

    test(
        'Edit Instance but another Instance still in breach — flag remains',
        () async {
      final pbId = await seedPracticeBlock(db, userId);
      final sessionId = 'session-integrity-still-breach';

      await db.into(db.sessions).insertOnConflictUpdate(
            SessionsCompanion.insert(
              sessionId: sessionId,
              drillId: 'integrity-drill',
              practiceBlockId: pbId,
              status: const Value(SessionStatus.closed),
              completionTimestamp: Value(DateTime.now()),
              integrityFlag: const Value(true),
            ),
          );

      final setId = 'set-integrity-2';
      await db.into(db.sets).insertOnConflictUpdate(
            SetsCompanion.insert(
              setId: setId,
              sessionId: sessionId,
              setIndex: 0,
            ),
          );

      // Instance 1: within bounds.
      await db.into(db.instances).insertOnConflictUpdate(
            InstancesCompanion.insert(
              instanceId: 'inst-integrity-ok',
              setId: setId,
              selectedClub: Value('i7'),
              rawMetrics: jsonEncode({'value': 50.0}),
            ),
          );

      // Instance 2: out of bounds (> 500).
      await db.into(db.instances).insertOnConflictUpdate(
            InstancesCompanion.insert(
              instanceId: 'inst-integrity-breach',
              setId: setId,
              selectedClub: Value('i7'),
              rawMetrics: jsonEncode({'value': 600.0}),
            ),
          );

      // Edit instance 1 to within bounds (this doesn't fix inst-2).
      await repo.updateInstance(
        'inst-integrity-ok',
        InstancesCompanion(
          rawMetrics: Value(jsonEncode({'value': 100.0})),
        ),
        userId,
      );

      // Flag should still be set because inst-integrity-breach is still outside bounds.
      final session = await repo.getSessionById(sessionId);
      expect(session, isNotNull);
      expect(session!.integrityFlag, isTrue);
    });

    test('IntegrityFlagAutoResolved event emitted on auto-clear', () async {
      final pbId = await seedPracticeBlock(db, userId);
      final sessionId = 'session-integrity-event';

      await db.into(db.sessions).insertOnConflictUpdate(
            SessionsCompanion.insert(
              sessionId: sessionId,
              drillId: 'integrity-drill',
              practiceBlockId: pbId,
              status: const Value(SessionStatus.closed),
              completionTimestamp: Value(DateTime.now()),
              integrityFlag: const Value(true),
            ),
          );

      final setId = 'set-integrity-event';
      await db.into(db.sets).insertOnConflictUpdate(
            SetsCompanion.insert(
              setId: setId,
              sessionId: sessionId,
              setIndex: 0,
            ),
          );

      await db.into(db.instances).insertOnConflictUpdate(
            InstancesCompanion.insert(
              instanceId: 'inst-integrity-event',
              setId: setId,
              selectedClub: Value('i7'),
              rawMetrics: jsonEncode({'value': 50.0}),
            ),
          );

      // Edit to trigger auto-resolution.
      await repo.updateInstance(
        'inst-integrity-event',
        InstancesCompanion(
          rawMetrics: Value(jsonEncode({'value': 100.0})),
        ),
        userId,
      );

      // Check event log for IntegrityFlagAutoResolved.
      final events = await (db.select(db.eventLogs)
            ..where((t) => t.eventTypeId.equals('IntegrityFlagAutoResolved')))
          .get();
      expect(events, isNotEmpty);
      expect(events.first.affectedEntityIds, contains(sessionId));
    });
  });
}
