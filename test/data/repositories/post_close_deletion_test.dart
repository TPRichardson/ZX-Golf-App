import 'dart:convert';

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

import '../../fixtures/scoring_fixtures.dart';

// Fix 5 — Post-close structured drill deletion guard.
// Structured drills (requiredAttemptsPerSet != null) block instance/set deletion
// on Closed sessions. Unstructured drills allow it.

void main() {
  late AppDatabase db;
  late PracticeRepository repo;
  late ReflowEngine reflowEngine;

  const userId = 'test-user-deletion-guard';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncWriteGate = SyncWriteGate();
    final eventLogRepo = EventLogRepository(db, syncWriteGate);
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
    repo = PracticeRepository(db, reflowEngine, eventLogRepo, syncWriteGate);

    // Seed user.
    await db.into(db.users).insert(UsersCompanion.insert(
          userId: userId,
          displayName: const Value('Test User'),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  /// Seed a drill with optional structured/unstructured config.
  Future<String> seedDrill({
    required String drillId,
    int? requiredAttemptsPerSet,
  }) async {
    await db.into(db.drills).insertOnConflictUpdate(DrillsCompanion.insert(
      drillId: drillId,
      name: 'Test Drill $drillId',
      skillArea: SkillArea.irons,
      drillType: DrillType.transition,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'raw_carry_distance',
      subskillMapping: const Value('["irons_direction_control"]'),
      origin: DrillOrigin.custom,
      anchors: const Value(
          '{"irons_direction_control": {"Min": 10, "Scratch": 50, "Pro": 90}}'),
      requiredAttemptsPerSet: Value(requiredAttemptsPerSet),
    ));
    return drillId;
  }

  /// Seed a closed session with instances.
  Future<({String sessionId, String setId, List<String> instanceIds})>
      seedClosedSession({
    required String drillId,
    required String pbId,
    int instanceCount = 2,
  }) async {
    final sessionId =
        'session-${DateTime.now().microsecondsSinceEpoch}';
    await db.into(db.sessions).insertOnConflictUpdate(
          SessionsCompanion.insert(
            sessionId: sessionId,
            drillId: drillId,
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
              selectedClub: 'i7',
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

  group('Fix 5: Post-close structured drill deletion guard', () {
    test('Delete Instance from closed structured session throws', () async {
      final drillId = await seedDrill(
        drillId: 'structured-drill',
        requiredAttemptsPerSet: 10,
      );
      final pbId = await seedPracticeBlock(db, userId);
      final result = await seedClosedSession(
        drillId: drillId,
        pbId: pbId,
      );

      expect(
        () => repo.deleteInstance(result.instanceIds.first, userId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });

    test('Delete Instance from closed unstructured session succeeds',
        () async {
      final drillId = await seedDrill(
        drillId: 'unstructured-drill',
        requiredAttemptsPerSet: null,
      );
      final pbId = await seedPracticeBlock(db, userId);
      final result = await seedClosedSession(
        drillId: drillId,
        pbId: pbId,
      );

      // Should not throw.
      await repo.deleteInstance(result.instanceIds.first, userId);

      // Verify instance is soft-deleted.
      final instance = await (db.select(db.instances)
            ..where((t) => t.instanceId.equals(result.instanceIds.first)))
          .getSingleOrNull();
      expect(instance?.isDeleted, isTrue);
    });

    test('Delete Set from closed structured session throws', () async {
      final drillId = await seedDrill(
        drillId: 'structured-drill-set',
        requiredAttemptsPerSet: 10,
      );
      final pbId = await seedPracticeBlock(db, userId);
      final result = await seedClosedSession(
        drillId: drillId,
        pbId: pbId,
      );

      expect(
        () => repo.deleteSet(result.setId, userId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });

    test('Session-level deletion works for structured drills', () async {
      final drillId = await seedDrill(
        drillId: 'structured-session-del',
        requiredAttemptsPerSet: 10,
      );
      final pbId = await seedPracticeBlock(db, userId);
      final result = await seedClosedSession(
        drillId: drillId,
        pbId: pbId,
      );

      // Session soft-delete should work for any drill type.
      await repo.softDeleteSession(result.sessionId);

      final session = await (db.select(db.sessions)
            ..where((t) => t.sessionId.equals(result.sessionId)))
          .getSingleOrNull();
      expect(session?.isDeleted, isTrue);
    });
  });
}
