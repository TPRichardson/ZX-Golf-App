import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/data/repositories/performance_snapshot_repository.dart';

// Phase M2 — PerformanceSnapshotRepository tests.

void main() {
  late AppDatabase db;
  late SyncWriteGate gate;
  late MatrixRepository matrixRepo;
  late PerformanceSnapshotRepository snapRepo;

  const userId = 'test-user-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = SyncWriteGate();
    matrixRepo = MatrixRepository(db, gate);
    snapRepo = PerformanceSnapshotRepository(db, gate);
  });

  tearDown(() => db.close());

  /// Create and complete a gapping chart run with attempts.
  Future<MatrixRun> createCompletedGappingRun({
    String user = userId,
    List<String> clubs = const ['7-Iron', '8-Iron', '9-Iron'],
    int shotTarget = 3,
    List<double>? carryDistances,
  }) async {
    final config = MatrixRunConfig(
      matrixType: MatrixType.gappingChart,
      sessionShotTarget: shotTarget,
      axes: [
        AxisConfig(
          axisType: AxisType.club,
          axisName: 'Club',
          labels: clubs,
        ),
      ],
    );
    final run = await matrixRepo.createMatrixRun(user, config);
    final cells = await (db.select(db.matrixCells)
          ..where((t) => t.matrixRunId.equals(run.matrixRunId)))
        .get();

    var counter = 0;
    for (var ci = 0; ci < cells.length; ci++) {
      final cell = cells[ci];
      for (var i = 0; i < shotTarget; i++) {
        counter++;
        final carry = carryDistances != null && ci < carryDistances.length
            ? carryDistances[ci] + i
            : 100.0 + ci * 10 + i;
        await matrixRepo.logAttempt(
          cell.matrixCellId,
          MatrixAttemptsCompanion.insert(
            matrixAttemptId: 'att-$counter',
            matrixCellId: cell.matrixCellId,
            carryDistanceMeters: Value(carry),
            totalDistanceMeters: Value(carry + 10),
          ),
        );
      }
    }

    return await matrixRepo.completeMatrixRun(run.matrixRunId, user);
  }

  group('createSnapshotFromRun', () {
    test('creates snapshot from completed run', () async {
      final run = await createCompletedGappingRun();

      final snapshot = await snapRepo.createSnapshotFromRun(
        run.matrixRunId,
        userId,
        label: 'Test gapping',
      );

      expect(snapshot.snapshotId, isNotEmpty);
      expect(snapshot.userId, userId);
      expect(snapshot.matrixRunId, run.matrixRunId);
      expect(snapshot.matrixType, MatrixType.gappingChart);
      expect(snapshot.label, 'Test gapping');
      expect(snapshot.isPrimary, false);
      expect(snapshot.isDeleted, false);
    });

    test('creates SnapshotClub records per club', () async {
      final run = await createCompletedGappingRun(
        clubs: ['7-Iron', '8-Iron'],
      );

      final snapshot =
          await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);
      final clubs = await snapRepo.getSnapshotClubs(snapshot.snapshotId);

      expect(clubs.length, 2);

      final labels = clubs.map((c) => c.clubId).toSet();
      expect(labels, containsAll(['7-Iron', '8-Iron']));

      // Verify carry/total computed.
      for (final club in clubs) {
        expect(club.carryDistanceMeters, isNotNull);
        expect(club.totalDistanceMeters, isNotNull);
      }
    });

    test('aggregates attempts into averages', () async {
      // 1 club, 3 attempts: carry = 100, 101, 102 → avg = 101.
      final run = await createCompletedGappingRun(
        clubs: ['PW'],
        shotTarget: 3,
        carryDistances: [100.0],
      );

      final snapshot =
          await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);
      final clubs = await snapRepo.getSnapshotClubs(snapshot.snapshotId);

      expect(clubs.length, 1);
      expect(clubs.first.clubId, 'PW');
      expect(clubs.first.carryDistanceMeters, 101.0); // avg of 100, 101, 102
      expect(clubs.first.totalDistanceMeters, 111.0); // avg of 110, 111, 112
    });

    test('sets as primary when requested', () async {
      final run = await createCompletedGappingRun();

      final snapshot = await snapRepo.createSnapshotFromRun(
        run.matrixRunId,
        userId,
        setAsPrimary: true,
      );

      expect(snapshot.isPrimary, true);
    });

    test('unsets previous primary when setting new primary', () async {
      final run1 = await createCompletedGappingRun();
      final snap1 = await snapRepo.createSnapshotFromRun(
        run1.matrixRunId,
        userId,
        setAsPrimary: true,
      );

      final run2 = await createCompletedGappingRun();
      final snap2 = await snapRepo.createSnapshotFromRun(
        run2.matrixRunId,
        userId,
        setAsPrimary: true,
      );

      // snap1 should no longer be primary.
      final updated1 = await snapRepo.getSnapshot(snap1.snapshotId);
      expect(updated1!.isPrimary, false);

      // snap2 should be primary.
      final updated2 = await snapRepo.getSnapshot(snap2.snapshotId);
      expect(updated2!.isPrimary, true);
    });

    test('rejects snapshot from incomplete run', () async {
      final config = MatrixRunConfig(
        matrixType: MatrixType.gappingChart,
        sessionShotTarget: 3,
        axes: const [
          AxisConfig(
            axisType: AxisType.club,
            axisName: 'Club',
            labels: ['7i'],
          ),
        ],
      );
      final run = await matrixRepo.createMatrixRun(userId, config);

      expect(
        () => snapRepo.createSnapshotFromRun(run.matrixRunId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects snapshot from nonexistent run', () async {
      expect(
        () => snapRepo.createSnapshotFromRun('nonexistent', userId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('snapshot queries', () {
    test('getSnapshot returns snapshot', () async {
      final run = await createCompletedGappingRun();
      final snap =
          await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);

      final found = await snapRepo.getSnapshot(snap.snapshotId);
      expect(found, isNotNull);
      expect(found!.snapshotId, snap.snapshotId);
    });

    test('getSnapshot excludes deleted', () async {
      final run = await createCompletedGappingRun();
      final snap =
          await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);

      await snapRepo.deleteSnapshot(snap.snapshotId);
      final found = await snapRepo.getSnapshot(snap.snapshotId);
      expect(found, isNull);
    });

    test('getPrimarySnapshot returns current primary', () async {
      final run = await createCompletedGappingRun();
      await snapRepo.createSnapshotFromRun(
        run.matrixRunId,
        userId,
        setAsPrimary: true,
      );

      final primary = await snapRepo.getPrimarySnapshot(userId);
      expect(primary, isNotNull);
      expect(primary!.isPrimary, true);
    });

    test('getPrimarySnapshot returns null when no primary', () async {
      final primary = await snapRepo.getPrimarySnapshot(userId);
      expect(primary, isNull);
    });
  });

  group('setPrimarySnapshot', () {
    test('designates snapshot as primary', () async {
      final run = await createCompletedGappingRun();
      final snap =
          await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);
      expect(snap.isPrimary, false);

      await snapRepo.setPrimarySnapshot(snap.snapshotId, userId);

      final updated = await snapRepo.getSnapshot(snap.snapshotId);
      expect(updated!.isPrimary, true);
    });

    test('unsets previous primary', () async {
      final run1 = await createCompletedGappingRun();
      final snap1 = await snapRepo.createSnapshotFromRun(
        run1.matrixRunId,
        userId,
        setAsPrimary: true,
      );

      final run2 = await createCompletedGappingRun();
      final snap2 =
          await snapRepo.createSnapshotFromRun(run2.matrixRunId, userId);

      await snapRepo.setPrimarySnapshot(snap2.snapshotId, userId);

      final updated1 = await snapRepo.getSnapshot(snap1.snapshotId);
      expect(updated1!.isPrimary, false);
      final updated2 = await snapRepo.getSnapshot(snap2.snapshotId);
      expect(updated2!.isPrimary, true);
    });
  });

  group('deleteSnapshot', () {
    test('soft-deletes snapshot', () async {
      final run = await createCompletedGappingRun();
      final snap =
          await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);

      await snapRepo.deleteSnapshot(snap.snapshotId);

      final found = await snapRepo.getSnapshot(snap.snapshotId);
      expect(found, isNull);

      // Still exists in DB.
      final raw = await (db.select(db.performanceSnapshots)
            ..where((t) => t.snapshotId.equals(snap.snapshotId)))
          .getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, true);
    });
  });

  group('getDerivedDistances', () {
    test('returns empty map when no runs exist', () async {
      final result = await snapRepo.getDerivedDistances(
        userId,
        MatrixType.gappingChart,
      );
      expect(result, isEmpty);
    });

    test('returns distances from single completed run', () async {
      final run = await createCompletedGappingRun(
        clubs: ['7-Iron'],
        carryDistances: [150.0],
      );
      await snapRepo.createSnapshotFromRun(run.matrixRunId, userId);

      final result = await snapRepo.getDerivedDistances(
        userId,
        MatrixType.gappingChart,
      );
      expect(result.containsKey('7-Iron'), true);
      // With shotTarget=3: carry = 150, 151, 152 → avg = 151.
      expect(result['7-Iron'], closeTo(151.0, 0.1));
    });

    test('returns distances scoped to MatrixType', () async {
      // Create a gapping run.
      final gapRun = await createCompletedGappingRun(
        clubs: ['7-Iron'],
        carryDistances: [150.0],
      );
      await snapRepo.createSnapshotFromRun(gapRun.matrixRunId, userId);

      // Query for wedge type — should be empty.
      final result = await snapRepo.getDerivedDistances(
        userId,
        MatrixType.wedgeMatrix,
      );
      expect(result, isEmpty);
    });

    test('returns empty when runs have no snapshots', () async {
      // Create completed run but don't create a snapshot.
      await createCompletedGappingRun(clubs: ['7-Iron']);

      final result = await snapRepo.getDerivedDistances(
        userId,
        MatrixType.gappingChart,
      );
      expect(result, isEmpty);
    });
  });
}
