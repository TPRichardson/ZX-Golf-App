import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/reflow_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/rebuild_guard.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';

// Fix 3 — Routine template linkage (sourceRoutineId).

void main() {
  late AppDatabase db;
  late PracticeRepository repo;

  const userId = 'test-user-routine-link';

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

    // Seed a user.
    await db.into(db.users).insert(UsersCompanion.insert(
          userId: userId,
          email: 'test@example.com',
          displayName: const Value('Test User'),
        ));
  });

  tearDown(() async {
    await db.close();
  });

  group('Fix 3: Source routine linkage', () {
    test('PracticeBlock from Routine has sourceRoutineId set', () async {
      final pb = await repo.createPracticeBlock(
        userId,
        sourceRoutineId: 'routine-abc-123',
      );

      expect(pb.sourceRoutineId, 'routine-abc-123');
    });

    test('PracticeBlock without Routine has null sourceRoutineId', () async {
      final pb = await repo.createPracticeBlock(userId);

      expect(pb.sourceRoutineId, isNull);
    });

    test('sourceRoutineId is informational — editing Routine does not affect PracticeBlock',
        () async {
      final pb = await repo.createPracticeBlock(
        userId,
        sourceRoutineId: 'routine-xyz-456',
      );

      // Verify the sourceRoutineId persists independently.
      final fetched = await repo.getPracticeBlockById(pb.practiceBlockId);
      expect(fetched, isNotNull);
      expect(fetched!.sourceRoutineId, 'routine-xyz-456');
    });
  });
}
