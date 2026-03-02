import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/startup_checks.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Phase 8 — Startup integrity checks tests.

void main() {
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late ReflowEngine reflowEngine;
  late StartupChecks checks;

  const userId = 'test-user-startup';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final gate = SyncWriteGate();
    final eventLogRepo = EventLogRepository(db, gate);
    scoringRepo = ScoringRepository(db);
    reflowEngine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: RebuildGuard(),
      syncWriteGate: gate,
      database: db,
      instrumentation: ReflowInstrumentation(),
    );
    checks = StartupChecks(db, scoringRepo, reflowEngine);
  });

  tearDown(() async {
    await db.close();
  });

  group('StartupChecks', () {
    test('runAll with clean state returns false (no rebuild triggered)',
        () async {
      // Seed required reference data.
      await _seedMinimalUser(db, userId);
      final result = await checks.runAll(userId);
      expect(result, false);
    });

    test('rebuildNeeded flag triggers full rebuild', () async {
      await _seedMinimalUser(db, userId);
      // Set rebuildNeeded flag.
      await db.into(db.syncMetadataEntries).insert(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.rebuildNeeded,
              value: 'true',
            ),
          );

      final result = await checks.runAll(userId);
      expect(result, true);

      // After rebuild, flag should be cleared.
      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.rebuildNeeded)))
          .getSingleOrNull();
      expect(row?.value, 'false');
    });

    test('expired scoring lock triggers rebuild', () async {
      await _seedMinimalUser(db, userId);
      // Create an expired lock.
      await db.into(db.userScoringLocks).insert(
            UserScoringLocksCompanion.insert(
              userId: userId,
              isLocked: const Value(true),
              lockedAt:
                  Value(DateTime.now().subtract(const Duration(minutes: 5))),
              lockExpiresAt:
                  Value(DateTime.now().subtract(const Duration(minutes: 1))),
            ),
          );

      final result = await checks.runAll(userId);
      expect(result, true);
    });

    test('allocation invariant passes with correct seed data', () async {
      await _seedMinimalUser(db, userId);
      // Allocation invariant is checked implicitly — no exception means pass.
      final result = await checks.runAll(userId);
      expect(result, false);
    });

    test('allocation invariant check detects mismatch and re-seeds', () async {
      await _seedMinimalUser(db, userId);
      // Verify initial state is correct.
      var refs = await scoringRepo.getAllSubskillRefs();
      final initialTotal = refs.fold<int>(0, (sum, r) => sum + r.allocation);
      expect(initialTotal, kTotalAllocation);

      // Corrupt the allocation by updating one ref's allocation to 0.
      final firstRef = refs.first;
      await (db.update(db.subskillRefs)
            ..where((t) => t.subskillId.equals(firstRef.subskillId)))
          .write(const SubskillRefsCompanion(allocation: Value(0)));

      // Verify corruption.
      refs = await scoringRepo.getAllSubskillRefs();
      final corruptedTotal = refs.fold<int>(0, (sum, r) => sum + r.allocation);
      expect(corruptedTotal, lessThan(kTotalAllocation));

      // Run checks — should re-seed.
      await checks.runAll(userId);

      // Verify re-seed restored correct allocations.
      refs = await scoringRepo.getAllSubskillRefs();
      final restoredTotal = refs.fold<int>(0, (sum, r) => sum + r.allocation);
      expect(restoredTotal, kTotalAllocation);
    });

    test('rebuildNeeded false does not trigger rebuild', () async {
      await _seedMinimalUser(db, userId);
      await db.into(db.syncMetadataEntries).insert(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.rebuildNeeded,
              value: 'false',
            ),
          );

      final result = await checks.runAll(userId);
      expect(result, false);
    });

    test('non-expired lock does not trigger rebuild', () async {
      await _seedMinimalUser(db, userId);
      await db.into(db.userScoringLocks).insert(
            UserScoringLocksCompanion.insert(
              userId: userId,
              isLocked: const Value(true),
              lockedAt: Value(DateTime.now()),
              lockExpiresAt:
                  Value(DateTime.now().add(const Duration(minutes: 5))),
            ),
          );

      final result = await checks.runAll(userId);
      // Non-expired lock: acquireLock will fail, but hasExpiredLock returns false.
      expect(result, false);
    });

    test('referential integrity check runs after RebuildStorageFailure event',
        () async {
      await _seedMinimalUser(db, userId);
      // Insert a RebuildStorageFailure event.
      await db.into(db.eventLogs).insert(EventLogsCompanion.insert(
            eventLogId: 'test-event-1',
            userId: userId,
            eventTypeId: 'RebuildStorageFailure',
          ));

      // Should not throw — FK check runs and logs results.
      final result = await checks.runAll(userId);
      expect(result, false);
    });
  });
}

Future<void> _seedMinimalUser(AppDatabase db, String userId) async {
  await db.into(db.users).insert(UsersCompanion.insert(userId: userId));
}
