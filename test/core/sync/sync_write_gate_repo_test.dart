import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/data/repositories/user_repository.dart';

// Phase 7B — SyncWriteGate repository integration tests.
// Verifies that gate-checked repositories properly block writes when the
// gate is held and allow writes when it is released. Also verifies that
// ScoringRepository is exempt from gate checks.

void main() {
  late AppDatabase db;
  late SyncWriteGate gate;
  late UserRepository userRepo;
  late EventLogRepository eventLogRepo;
  late PlanningRepository planningRepo;
  late ScoringRepository scoringRepo;

  const userId = 'test-user-gate';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = SyncWriteGate();
    userRepo = UserRepository(db, gate);
    eventLogRepo = EventLogRepository(db, gate);
    planningRepo = PlanningRepository(db, gate);
    scoringRepo = ScoringRepository(db);
  });

  tearDown(() async {
    gate.dispose();
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Gate not held — writes proceed immediately
  // ---------------------------------------------------------------------------

  group('Gate not held — writes proceed immediately', () {
    test('UserRepository.create succeeds when gate not held', () async {
      final user = await userRepo.create(UsersCompanion.insert(
        userId: userId,
        email: '$userId@test.com',
      ));
      expect(user.userId, userId);
      expect(gate.isHeld, isFalse);
    });

    test('EventLogRepository.create succeeds when gate not held', () async {
      final log = await eventLogRepo.create(EventLogsCompanion.insert(
        eventLogId: 'log-1',
        userId: userId,
        eventTypeId: 'AnchorEdit',
      ));
      expect(log.eventLogId, 'log-1');
      expect(log.userId, userId);
    });

    test('PlanningRepository.createCalendarDay succeeds when gate not held',
        () async {
      final day = await planningRepo.createCalendarDay(
        CalendarDaysCompanion.insert(
          calendarDayId: 'cd-1',
          userId: userId,
          date: DateTime(2026, 3, 1),
          slotCapacity: const Value(5),
          slots: const Value('[{"planned":false}]'),
        ),
      );
      expect(day.calendarDayId, 'cd-1');
      expect(day.userId, userId);
    });
  });

  // ---------------------------------------------------------------------------
  // Gate held — writes block until release
  // ---------------------------------------------------------------------------

  group('Gate held — writes block until release', () {
    test('UserRepository.create blocks when gate held, completes on release',
        () async {
      gate.acquireExclusive();
      expect(gate.isHeld, isTrue);

      var writeCompleted = false;
      final writeFuture = userRepo
          .create(UsersCompanion.insert(userId: userId, email: '$userId@test.com'))
          .then((user) {
        writeCompleted = true;
        return user;
      });

      // Yield to let microtasks run — write should still be pending.
      await Future.delayed(Duration.zero);
      expect(writeCompleted, isFalse);

      // Release the gate — write should now complete.
      gate.release();
      final user = await writeFuture;
      expect(writeCompleted, isTrue);
      expect(user.userId, userId);
    });

    test('EventLogRepository.create blocks when gate held', () async {
      gate.acquireExclusive();

      var writeCompleted = false;
      final writeFuture = eventLogRepo
          .create(EventLogsCompanion.insert(
            eventLogId: 'log-blocked',
            userId: userId,
            eventTypeId: 'AnchorEdit',
          ))
          .then((log) {
        writeCompleted = true;
        return log;
      });

      await Future.delayed(Duration.zero);
      expect(writeCompleted, isFalse);

      gate.release();
      final log = await writeFuture;
      expect(writeCompleted, isTrue);
      expect(log.eventLogId, 'log-blocked');
    });

    test('PlanningRepository.createCalendarDay blocks when gate held',
        () async {
      gate.acquireExclusive();

      var writeCompleted = false;
      final writeFuture = planningRepo
          .createCalendarDay(CalendarDaysCompanion.insert(
            calendarDayId: 'cd-blocked',
            userId: userId,
            date: DateTime(2026, 3, 2),
            slotCapacity: const Value(3),
            slots: const Value('[]'),
          ))
          .then((day) {
        writeCompleted = true;
        return day;
      });

      await Future.delayed(Duration.zero);
      expect(writeCompleted, isFalse);

      gate.release();
      final day = await writeFuture;
      expect(writeCompleted, isTrue);
      expect(day.calendarDayId, 'cd-blocked');
    });
  });

  // ---------------------------------------------------------------------------
  // Gate release unblocks queued writes
  // ---------------------------------------------------------------------------

  group('Gate release unblocks queued writes', () {
    test('Multiple queued writes complete after release', () async {
      gate.acquireExclusive();

      var completedCount = 0;

      final f1 = userRepo
          .create(UsersCompanion.insert(userId: 'user-q1', email: 'q1@test.com'))
          .then((_) => completedCount++);
      final f2 = eventLogRepo
          .create(EventLogsCompanion.insert(
            eventLogId: 'log-q2',
            userId: 'user-q1',
            eventTypeId: 'AnchorEdit',
          ))
          .then((_) => completedCount++);
      final f3 = planningRepo
          .createCalendarDay(CalendarDaysCompanion.insert(
            calendarDayId: 'cd-q3',
            userId: 'user-q1',
            date: DateTime(2026, 3, 3),
            slotCapacity: const Value(5),
            slots: const Value('[]'),
          ))
          .then((_) => completedCount++);

      await Future.delayed(Duration.zero);
      expect(completedCount, 0);

      gate.release();
      await Future.wait([f1, f2, f3]);
      expect(completedCount, 3);
    });

    test('Writes complete in FIFO order after release', () async {
      gate.acquireExclusive();

      final completionOrder = <String>[];

      final f1 = userRepo
          .create(UsersCompanion.insert(userId: 'user-fifo', email: 'fifo@test.com'))
          .then((_) => completionOrder.add('user'));
      final f2 = eventLogRepo
          .create(EventLogsCompanion.insert(
            eventLogId: 'log-fifo',
            userId: 'user-fifo',
            eventTypeId: 'AnchorEdit',
          ))
          .then((_) => completionOrder.add('event_log'));
      final f3 = planningRepo
          .createCalendarDay(CalendarDaysCompanion.insert(
            calendarDayId: 'cd-fifo',
            userId: 'user-fifo',
            date: DateTime(2026, 3, 4),
            slotCapacity: const Value(5),
            slots: const Value('[]'),
          ))
          .then((_) => completionOrder.add('calendar_day'));

      await Future.delayed(Duration.zero);
      expect(completionOrder, isEmpty);

      gate.release();
      await Future.wait([f1, f2, f3]);

      // All three waiters are notified in the order they were added
      // (FIFO from _waiters list). Because awaitGateRelease adds to a list
      // and release() iterates in order, the completers fire in FIFO order.
      expect(completionOrder, ['user', 'event_log', 'calendar_day']);
    });
  });

  // ---------------------------------------------------------------------------
  // Hard timeout
  // ---------------------------------------------------------------------------

  group('Hard timeout', () {
    test('Gate auto-releases after hard timeout', () {
      fakeAsync((async) {
        final fakeGate = SyncWriteGate();
        fakeGate.acquireExclusive();
        expect(fakeGate.isHeld, isTrue);

        var waiterCompleted = false;
        fakeGate.awaitGateRelease().then((_) {
          waiterCompleted = true;
        });

        // Advance time just short of the timeout — gate still held.
        async.elapse(kSyncWriteGateHardTimeout - const Duration(seconds: 1));
        expect(fakeGate.isHeld, isTrue);
        expect(waiterCompleted, isFalse);

        // Advance past the timeout — gate should auto-release.
        async.elapse(const Duration(seconds: 2));
        expect(fakeGate.isHeld, isFalse);
        expect(waiterCompleted, isTrue);

        fakeGate.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Concurrent writes
  // ---------------------------------------------------------------------------

  group('Concurrent writes', () {
    test('Multiple concurrent writes queue correctly', () async {
      gate.acquireExclusive();

      const count = 5;
      var completedCount = 0;

      final futures = <Future>[];
      for (var i = 0; i < count; i++) {
        futures.add(
          eventLogRepo
              .create(EventLogsCompanion.insert(
                eventLogId: 'log-concurrent-$i',
                userId: userId,
                eventTypeId: 'AnchorEdit',
              ))
              .then((_) => completedCount++),
        );
      }

      await Future.delayed(Duration.zero);
      expect(completedCount, 0);

      gate.release();
      await Future.wait(futures);
      expect(completedCount, count);

      // Verify all entries were actually persisted.
      final allLogs = await eventLogRepo.watchByUser(userId).first;
      final concurrentLogs = allLogs
          .where((l) => l.eventLogId.startsWith('log-concurrent-'))
          .toList();
      expect(concurrentLogs.length, count);
    });

    test('Write started during gate release completes', () async {
      gate.acquireExclusive();

      // Start one write that will be blocked.
      var firstCompleted = false;
      final firstFuture = userRepo
          .create(UsersCompanion.insert(userId: 'user-during-release', email: 'during@test.com'))
          .then((_) {
        firstCompleted = true;
      });

      await Future.delayed(Duration.zero);
      expect(firstCompleted, isFalse);

      // Release the gate.
      gate.release();

      // Immediately start another write — gate is no longer held,
      // so this should proceed without blocking.
      final secondUser = await userRepo.create(
        UsersCompanion.insert(userId: 'user-after-release', email: 'after@test.com'),
      );

      await firstFuture;
      expect(firstCompleted, isTrue);
      expect(secondUser.userId, 'user-after-release');
    });
  });

  // ---------------------------------------------------------------------------
  // ScoringRepository exempt
  // ---------------------------------------------------------------------------

  group('ScoringRepository exempt', () {
    test('ScoringRepository constructor only takes DB', () {
      // ScoringRepository does not accept a SyncWriteGate parameter.
      // Constructing with just the DB confirms gate exemption.
      final repo = ScoringRepository(db);
      expect(repo, isNotNull);
    });

    test('ScoringRepository upsert works with gate held', () async {
      gate.acquireExclusive();
      expect(gate.isHeld, isTrue);

      // ScoringRepository does not check the gate, so this should
      // complete immediately even with the gate held.
      await scoringRepo.upsertWindowState(
        MaterialisedWindowStatesCompanion.insert(
          userId: userId,
          skillArea: SkillArea.putting,
          subskill: 'putting_direction_control',
          practiceType: DrillType.transition,
          entries: const Value('[]'),
          totalOccupancy: const Value(0.0),
          weightedSum: const Value(0.0),
          windowAverage: const Value(0.0),
        ),
      );

      // Verify the row was written while gate was still held.
      expect(gate.isHeld, isTrue);
      final states = await scoringRepo.watchWindowStatesByUser(userId).first;
      expect(states.length, 1);
      expect(states.first.subskill, 'putting_direction_control');

      gate.release();
    });
  });

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  group('Dispose', () {
    test('Gate dispose releases all waiters', () async {
      gate.acquireExclusive();

      var waiterCompleted = false;
      final waiterFuture = gate.awaitGateRelease().then((_) {
        waiterCompleted = true;
      });

      await Future.delayed(Duration.zero);
      expect(waiterCompleted, isFalse);

      // Dispose should complete all pending waiters.
      gate.dispose();
      await waiterFuture;
      expect(waiterCompleted, isTrue);
      expect(gate.isHeld, isFalse);
    });

    test('Gate dispose cancels timeout timer', () {
      fakeAsync((async) {
        final fakeGate = SyncWriteGate();
        fakeGate.acquireExclusive();
        expect(fakeGate.isHeld, isTrue);

        // Dispose before the timeout fires.
        fakeGate.dispose();
        expect(fakeGate.isHeld, isFalse);

        // Advance past the hard timeout — nothing should blow up
        // because the timer was cancelled by dispose.
        async.elapse(kSyncWriteGateHardTimeout + const Duration(seconds: 10));

        // Gate should remain in a clean state.
        expect(fakeGate.isHeld, isFalse);
      });
    });
  });
}
