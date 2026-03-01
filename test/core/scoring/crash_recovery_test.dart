import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Phase 2B — Crash recovery tests (TD-04 §3.4.1).

void main() {
  late AppDatabase db;
  late ScoringRepository scoringRepo;
  late EventLogRepository eventLogRepo;
  late RebuildGuard rebuildGuard;
  late SyncWriteGate syncWriteGate;
  late ReflowInstrumentation instrumentation;
  late ReflowEngine engine;

  const userId = 'test-user-crash';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scoringRepo = ScoringRepository(db);
    eventLogRepo = EventLogRepository(db);
    rebuildGuard = RebuildGuard();
    syncWriteGate = SyncWriteGate();
    instrumentation = ReflowInstrumentation();
    engine = ReflowEngine(
      scoringRepository: scoringRepo,
      eventLogRepository: eventLogRepo,
      rebuildGuard: rebuildGuard,
      syncWriteGate: syncWriteGate,
      database: db,
      instrumentation: instrumentation,
    );
  });

  tearDown(() async {
    rebuildGuard.dispose();
    syncWriteGate.dispose();
    await db.close();
  });

  group('Crash recovery — TD-04 §3.4.1', () {
    test('expired lock triggers full rebuild', () async {
      // Insert an expired lock.
      final pastExpiry = DateTime.now().subtract(const Duration(seconds: 60));
      await db.into(db.userScoringLocks).insertOnConflictUpdate(
            UserScoringLocksCompanion.insert(
              userId: userId,
              isLocked: const Value(true),
              lockedAt:
                  Value(DateTime.now().subtract(const Duration(seconds: 90))),
              lockExpiresAt: Value(pastExpiry),
            ),
          );

      final recovered = await engine.checkCrashRecovery(userId);
      expect(recovered, isTrue);

      // Lock should be released after recovery.
      expect(await scoringRepo.hasExpiredLock(userId), isFalse);

      // Overall score should exist (full rebuild executed).
      final overall =
          await scoringRepo.watchOverallScoreByUser(userId).first;
      expect(overall, isNotNull);
    });

    test('non-expired lock does not trigger rebuild', () async {
      // Acquire a fresh lock (non-expired).
      await scoringRepo.acquireLock(userId);

      final recovered = await engine.checkCrashRecovery(userId);
      expect(recovered, isFalse);

      // Clean up.
      await scoringRepo.releaseLock(userId);
    });

    test('no lock at all does not trigger rebuild', () async {
      final recovered = await engine.checkCrashRecovery(userId);
      expect(recovered, isFalse);
    });
  });
}
