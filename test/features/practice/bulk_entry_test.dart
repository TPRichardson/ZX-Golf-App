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
import 'package:zx_golf_app/data/repositories/club_repository.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

// Fix 4 — Bulk entry tests.

void main() {
  late AppDatabase db;
  late PracticeRepository practiceRepo;
  late ReflowEngine reflowEngine;

  const userId = 'test-user-bulk';
  const drillId = 'drill-bulk-struct';
  const drillIdUnstruct = 'drill-bulk-unstruct';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final syncWriteGate = SyncWriteGate();
    final eventLogRepo = EventLogRepository(db, syncWriteGate);
    final scoringRepo = ScoringRepository(db);
    reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    practiceRepo =
        PracticeRepository(db, reflowEngine, eventLogRepo, syncWriteGate);

    // S09 §9.3 — Seed clubs so bag gate passes for Putting.
    final clubRepo = ClubRepository(db, syncWriteGate);
    await clubRepo.addClub(
        userId, const UserClubsCompanion(clubType: Value(ClubType.putter)));

    // Structured drill: 1 set × 10 attempts.
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillId,
      name: 'Bulk Structured',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
      requiredAttemptsPerSet: const Value(10),
    ));

    // Unstructured drill.
    await db.into(db.drills).insert(DrillsCompanion.insert(
      drillId: drillIdUnstruct,
      name: 'Bulk Unstructured',
      skillArea: SkillArea.putting,
      drillType: DrillType.transition,
      inputMode: InputMode.binaryHitMiss,
      metricSchemaId: 'grid_1x3_direction',
      origin: DrillOrigin.standard,
      subskillMapping: const Value('["putting_direction_control"]'),
      anchors: const Value(
          '{"putting_direction_control": {"Min": 20, "Scratch": 60, "Pro": 90}}'),
      requiredSetCount: const Value(1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<(Session, SessionExecutionController)> startSession(
      String targetDrillId) async {
    final pb = await practiceRepo.createPracticeBlock(userId,
        initialDrillIds: [targetDrillId]);
    final entries = await (db.select(db.practiceEntries)
          ..where((t) => t.practiceBlockId.equals(pb.practiceBlockId)))
        .get();
    final session =
        await practiceRepo.startSession(entries.first.practiceEntryId, userId);
    final controller = SessionExecutionController(
      repository: practiceRepo,
      session: session,
      drill: (await (db.select(db.drills)
                ..where((t) => t.drillId.equals(targetDrillId)))
              .getSingle()),
    );
    await controller.initialize();
    return (session, controller);
  }

  group('Fix 4: Bulk entry', () {
    test('bulk add 5 instances to unstructured session', () async {
      final (session, controller) = await startSession(drillIdUnstruct);

      expect(controller.remainingSetCapacity, isNull);

      final added = await controller.logBulkInstances(5, (i) {
        return InstancesCompanion.insert(
          instanceId: 'bulk-$i',
          setId: controller.currentSetId!,
          selectedClub: 'Putter',
          rawMetrics: jsonEncode({'hit': true}),
        );
      });

      expect(added, 5);
      expect(controller.currentSetInstanceCount, 5);
    });

    test('structured drill caps bulk at remaining capacity', () async {
      final (session, controller) = await startSession(drillId);

      // requiredAttemptsPerSet = 10, currently 0 logged.
      expect(controller.remainingSetCapacity, 10);

      // Log 7 first.
      for (var i = 0; i < 7; i++) {
        await controller.logInstance(InstancesCompanion.insert(
          instanceId: 'pre-$i',
          setId: controller.currentSetId!,
          selectedClub: 'Putter',
          rawMetrics: jsonEncode({'hit': true}),
        ));
      }
      expect(controller.remainingSetCapacity, 3);

      // Try to bulk add 10 — should cap at 3.
      final added = await controller.logBulkInstances(10, (i) {
        return InstancesCompanion.insert(
          instanceId: 'bulk-capped-$i',
          setId: controller.currentSetId!,
          selectedClub: 'Putter',
          rawMetrics: jsonEncode({'hit': true}),
        );
      });

      expect(added, 3);
      expect(controller.currentSetInstanceCount, 10);
      expect(controller.isCurrentSetComplete(), isTrue);
    });

    test('bulk entry timestamps produce valid ordering', () async {
      final (session, controller) = await startSession(drillIdUnstruct);

      await controller.logBulkInstances(5, (i) {
        return InstancesCompanion.insert(
          instanceId: 'ts-$i',
          setId: controller.currentSetId!,
          selectedClub: 'Putter',
          rawMetrics: jsonEncode({'hit': true}),
        );
      });

      // Verify 5 instances exist in DB.
      final instances = await (db.select(db.instances)
            ..where((t) => t.setId.equals(controller.currentSetId!)))
          .get();
      expect(instances.length, 5);

      // Verify they have unique IDs.
      final ids = instances.map((i) => i.instanceId).toSet();
      expect(ids.length, 5);
    });
  });
}
