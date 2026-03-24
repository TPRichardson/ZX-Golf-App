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

// Fix 6 — Last Instance deletion auto-discards unstructured Session.

void main() {
  late AppDatabase db;
  late PracticeRepository repo;

  const userId = 'test-user-auto-discard';

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

    // Seed unstructured drill (requiredAttemptsPerSet = null).
    await db.into(db.drills).insertOnConflictUpdate(DrillsCompanion.insert(
      drillId: 'unstruct-drill',
      name: 'Unstructured Drill',
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

  /// Seed a closed session with given number of instances.
  Future<({String sessionId, String setId, List<String> instanceIds})>
      seedClosedSession({int instanceCount = 2}) async {
    final pbId = await seedPracticeBlock(db, userId);
    final sessionId = 'session-${DateTime.now().microsecondsSinceEpoch}';
    await db.into(db.sessions).insertOnConflictUpdate(
          SessionsCompanion.insert(
            sessionId: sessionId,
            drillId: 'unstruct-drill',
            practiceBlockId: pbId,
            status: const Value(SessionStatus.closed),
            completionTimestamp: Value(DateTime.now()),
          ),
        );

    final setId = 'set-$sessionId';
    await db.into(db.sets).insertOnConflictUpdate(
          SetsCompanion.insert(
            setId: setId,
            sessionId: sessionId,
            setIndex: 0,
          ),
        );

    final instanceIds = <String>[];
    for (var i = 0; i < instanceCount; i++) {
      final instId = 'inst-$sessionId-$i';
      instanceIds.add(instId);
      await db.into(db.instances).insertOnConflictUpdate(
            InstancesCompanion.insert(
              instanceId: instId,
              setId: setId,
              selectedClub: Value('i7'),
              rawMetrics: jsonEncode({'value': 50.0}),
            ),
          );
    }

    return (
      sessionId: sessionId,
      setId: setId,
      instanceIds: instanceIds,
    );
  }

  group('Fix 6: Last Instance deletion auto-discards unstructured Session',
      () {
    test('Delete one of two instances — Session remains', () async {
      final result = await seedClosedSession(instanceCount: 2);

      await repo.deleteInstance(result.instanceIds.first, userId);

      // Session should still exist.
      final session = await repo.getSessionById(result.sessionId);
      expect(session, isNotNull);
    });

    test('Delete last instance — Session auto-discarded', () async {
      final result = await seedClosedSession(instanceCount: 2);

      // Delete first instance.
      await repo.deleteInstance(result.instanceIds[0], userId);

      // Delete last instance.
      await repo.deleteInstance(result.instanceIds[1], userId);

      // Session should be hard-deleted (not findable).
      final session = await (db.select(db.sessions)
            ..where((t) => t.sessionId.equals(result.sessionId)))
          .getSingleOrNull();
      expect(session, isNull);
    });

    test('Delete last instance triggers reflow', () async {
      final result = await seedClosedSession(instanceCount: 1);

      // Delete the only instance.
      await repo.deleteInstance(result.instanceIds.first, userId);

      // Session should be gone.
      final session = await (db.select(db.sessions)
            ..where((t) => t.sessionId.equals(result.sessionId)))
          .getSingleOrNull();
      expect(session, isNull);

      // Sets should be gone too.
      final sets = await (db.select(db.sets)
            ..where((t) => t.sessionId.equals(result.sessionId)))
          .get();
      expect(sets, isEmpty);
    });
  });
}
