import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';

// Phase M2 — MatrixRepository tests.

void main() {
  late AppDatabase db;
  late SyncWriteGate gate;
  late MatrixRepository repo;

  const userId = 'test-user-1';

  /// Standard gapping chart config: 1 axis (Club) with 3 values.
  MatrixRunConfig gappingConfig({
    int shotTarget = 3,
    List<String> clubs = const ['7-Iron', '8-Iron', '9-Iron'],
  }) =>
      MatrixRunConfig(
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

  /// Wedge matrix config: 2 axes (Club × Effort).
  MatrixRunConfig wedgeConfig({int shotTarget = 3}) => MatrixRunConfig(
        matrixType: MatrixType.wedgeMatrix,
        sessionShotTarget: shotTarget,
        axes: [
          const AxisConfig(
            axisType: AxisType.club,
            axisName: 'Club',
            labels: ['56°', '60°'],
          ),
          const AxisConfig(
            axisType: AxisType.effort,
            axisName: 'Effort',
            labels: ['50%', '75%', '100%'],
          ),
        ],
      );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = SyncWriteGate();
    repo = MatrixRepository(db, gate);
  });

  tearDown(() => db.close());

  group('createMatrixRun', () {
    test('creates run with 1-axis gapping chart (3 cells)', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());

      expect(run.matrixRunId, isNotEmpty);
      expect(run.userId, userId);
      expect(run.matrixType, MatrixType.gappingChart);
      expect(run.runState, RunState.inProgress);
      expect(run.runNumber, 1);
      expect(run.sessionShotTarget, 3);
      expect(run.shotOrderMode, ShotOrderMode.topToBottom);
      expect(run.isDeleted, false);

      // Verify 1 axis with 3 values.
      final axes = await db.select(db.matrixAxes).get();
      expect(axes.length, 1);
      expect(axes.first.axisType, AxisType.club);

      final values = await db.select(db.matrixAxisValues).get();
      expect(values.length, 3);

      // Verify 3 cells (1D: 3 cells).
      final cells = await db.select(db.matrixCells).get();
      expect(cells.length, 3);
    });

    test('creates run with 2-axis wedge matrix (2×3 = 6 cells)', () async {
      final run = await repo.createMatrixRun(userId, wedgeConfig());

      expect(run.matrixType, MatrixType.wedgeMatrix);

      final axes = await db.select(db.matrixAxes).get();
      expect(axes.length, 2);

      final values = await db.select(db.matrixAxisValues).get();
      expect(values.length, 5); // 2 clubs + 3 efforts

      // Verify 6 cells (2D: 2 × 3).
      final cells = await db.select(db.matrixCells).get();
      expect(cells.length, 6);

      // Each cell has a 2-element axisValueIds array.
      for (final cell in cells) {
        final ids =
            (jsonDecode(cell.axisValueIds) as List<dynamic>).cast<String>();
        expect(ids.length, 2);
      }
    });

    test('RunNumber increments per user', () async {
      final run1 = await repo.createMatrixRun(userId, gappingConfig());
      expect(run1.runNumber, 1);

      // Complete run1 so we can create run2.
      await _completeRunWithAttempts(db, run1.matrixRunId, 3);
      await repo.completeMatrixRun(run1.matrixRunId, userId);

      final run2 = await repo.createMatrixRun(userId, gappingConfig());
      expect(run2.runNumber, 2);
    });

    test('RunNumber is per-user (different users start at 1)', () async {
      final run1 = await repo.createMatrixRun(userId, gappingConfig());
      expect(run1.runNumber, 1);

      // Complete run1 so user-2 isn't blocked by mutual exclusivity.
      await _completeRunWithAttempts(db, run1.matrixRunId, 3);
      await repo.completeMatrixRun(run1.matrixRunId, userId);

      final run2 =
          await repo.createMatrixRun('other-user', gappingConfig());
      expect(run2.runNumber, 1);
    });

    test('rejects sessionShotTarget < 3', () async {
      expect(
        () => repo.createMatrixRun(userId, gappingConfig(shotTarget: 2)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty axes', () async {
      expect(
        () => repo.createMatrixRun(
            userId,
            const MatrixRunConfig(
              matrixType: MatrixType.gappingChart,
              sessionShotTarget: 3,
              axes: [],
            )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects axis with empty labels', () async {
      expect(
        () => repo.createMatrixRun(
            userId,
            const MatrixRunConfig(
              matrixType: MatrixType.gappingChart,
              sessionShotTarget: 3,
              axes: [
                AxisConfig(
                    axisType: AxisType.club,
                    axisName: 'Club',
                    labels: []),
              ],
            )),
        throwsA(isA<ValidationException>()),
      );
    });

    test('blocks if active PracticeBlock exists', () async {
      // Insert an active PracticeBlock.
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-1',
              userId: userId,
            ),
          );

      expect(
        () => repo.createMatrixRun(userId, gappingConfig()),
        throwsA(isA<ConflictException>()),
      );
    });

    test('blocks if another MatrixRun is active', () async {
      await repo.createMatrixRun(userId, gappingConfig());

      expect(
        () => repo.createMatrixRun(userId, gappingConfig()),
        throwsA(isA<ConflictException>()),
      );
    });

    test('stores optional environment and green fields', () async {
      final config = MatrixRunConfig(
        matrixType: MatrixType.chippingMatrix,
        sessionShotTarget: 3,
        environmentType: EnvironmentType.outdoor,
        surfaceType: SurfaceType.grass,
        greenSpeed: 10.5,
        greenFirmness: GreenFirmness.firm,
        dispersionCaptureEnabled: true,
        measurementDevice: 'Trackman',
        axes: const [
          AxisConfig(
              axisType: AxisType.club,
              axisName: 'Club',
              labels: ['SW']),
        ],
      );

      final run = await repo.createMatrixRun(userId, config);
      expect(run.environmentType, EnvironmentType.outdoor);
      expect(run.surfaceType, SurfaceType.grass);
      expect(run.greenSpeed, 10.5);
      expect(run.greenFirmness, GreenFirmness.firm);
      expect(run.dispersionCaptureEnabled, true);
      expect(run.measurementDevice, 'Trackman');
    });
  });

  group('query methods', () {
    test('getMatrixRunById returns run', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      final found = await repo.getMatrixRunById(run.matrixRunId);
      expect(found, isNotNull);
      expect(found!.matrixRunId, run.matrixRunId);
    });

    test('getMatrixRunById excludes deleted runs', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      await repo.discardMatrixRun(run.matrixRunId, userId);
      final found = await repo.getMatrixRunById(run.matrixRunId);
      expect(found, isNull);
    });

    test('getActiveMatrixRun returns InProgress run', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      final active = await repo.getActiveMatrixRun(userId);
      expect(active, isNotNull);
      expect(active!.matrixRunId, run.matrixRunId);
    });

    test('getActiveMatrixRun returns null when no active run', () async {
      final active = await repo.getActiveMatrixRun(userId);
      expect(active, isNull);
    });

    test('getMatrixRunWithDetails returns full composite', () async {
      final run = await repo.createMatrixRun(userId, wedgeConfig());

      // Log an attempt in the first cell.
      final cells = await db.select(db.matrixCells).get();
      await repo.logAttempt(
        cells.first.matrixCellId,
        MatrixAttemptsCompanion.insert(
          matrixAttemptId: 'att-1',
          matrixCellId: cells.first.matrixCellId,
          carryDistanceMeters: const Value(100.0),
        ),
      );

      final details =
          await repo.getMatrixRunWithDetails(run.matrixRunId);
      expect(details, isNotNull);
      expect(details!.run.matrixRunId, run.matrixRunId);
      expect(details.axes.length, 2);
      expect(details.axes[0].values.length, 2); // 2 clubs
      expect(details.axes[1].values.length, 3); // 3 efforts
      expect(details.cells.length, 6);

      // Find the cell with the attempt.
      final cellWithAttempt = details.cells
          .firstWhere((c) => c.cell.matrixCellId == cells.first.matrixCellId);
      expect(cellWithAttempt.attempts.length, 1);
      expect(cellWithAttempt.attempts.first.carryDistanceMeters, 100.0);
    });

    test('getMatrixRunWithDetails returns null for missing run', () async {
      final result = await repo.getMatrixRunWithDetails('nonexistent');
      expect(result, isNull);
    });
  });

  group('logAttempt', () {
    test('logs attempt with carry and total distances', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      final attempt = await repo.logAttempt(
        cells.first.matrixCellId,
        MatrixAttemptsCompanion.insert(
          matrixAttemptId: '',
          matrixCellId: '',
          carryDistanceMeters: const Value(145.5),
          totalDistanceMeters: const Value(155.0),
        ),
      );

      expect(attempt.carryDistanceMeters, 145.5);
      expect(attempt.totalDistanceMeters, 155.0);
      expect(attempt.matrixCellId, cells.first.matrixCellId);
      expect(attempt.matrixAttemptId, isNotEmpty);
    });

    test('logs attempt with dispersion fields', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      final attempt = await repo.logAttempt(
        cells.first.matrixCellId,
        MatrixAttemptsCompanion.insert(
          matrixAttemptId: '',
          matrixCellId: '',
          carryDistanceMeters: const Value(100.0),
          leftDeviationMeters: const Value(2.5),
          rightDeviationMeters: const Value(1.8),
          rolloutDistanceMeters: const Value(4.2),
        ),
      );

      expect(attempt.leftDeviationMeters, 2.5);
      expect(attempt.rightDeviationMeters, 1.8);
      expect(attempt.rolloutDistanceMeters, 4.2);
    });

    test('rejects attempt on excluded cell', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();
      await repo.excludeCell(cells.first.matrixCellId);

      expect(
        () => repo.logAttempt(
          cells.first.matrixCellId,
          MatrixAttemptsCompanion.insert(
            matrixAttemptId: '',
            matrixCellId: '',
            carryDistanceMeters: const Value(100.0),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects attempt on nonexistent cell', () async {
      expect(
        () => repo.logAttempt(
          'nonexistent',
          MatrixAttemptsCompanion.insert(
            matrixAttemptId: '',
            matrixCellId: '',
            carryDistanceMeters: const Value(100.0),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects attempt on completed run', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      // Complete the run first.
      await _completeRunWithAttempts(db, run.matrixRunId, 3);
      await repo.completeMatrixRun(run.matrixRunId, userId);

      expect(
        () => repo.logAttempt(
          cells.first.matrixCellId,
          MatrixAttemptsCompanion.insert(
            matrixAttemptId: '',
            matrixCellId: '',
            carryDistanceMeters: const Value(100.0),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('updateAttempt', () {
    test('updates attempt carry distance', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      final attempt = await repo.logAttempt(
        cells.first.matrixCellId,
        MatrixAttemptsCompanion.insert(
          matrixAttemptId: '',
          matrixCellId: '',
          carryDistanceMeters: const Value(100.0),
        ),
      );

      await repo.updateAttempt(
        attempt.matrixAttemptId,
        const MatrixAttemptsCompanion(
          carryDistanceMeters: Value(110.0),
        ),
      );

      final updated = await (db.select(db.matrixAttempts)
            ..where(
                (t) => t.matrixAttemptId.equals(attempt.matrixAttemptId)))
          .getSingle();
      expect(updated.carryDistanceMeters, 110.0);
    });

    test('throws for nonexistent attempt', () async {
      expect(
        () => repo.updateAttempt(
          'nonexistent',
          const MatrixAttemptsCompanion(
            carryDistanceMeters: Value(100.0),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('deleteAttempt', () {
    test('deletes attempt', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      final attempt = await repo.logAttempt(
        cells.first.matrixCellId,
        MatrixAttemptsCompanion.insert(
          matrixAttemptId: '',
          matrixCellId: '',
          carryDistanceMeters: const Value(100.0),
        ),
      );

      await repo.deleteAttempt(attempt.matrixAttemptId);

      final attempts = await db.select(db.matrixAttempts).get();
      expect(attempts, isEmpty);
    });

    test('throws for nonexistent attempt', () async {
      expect(
        () => repo.deleteAttempt('nonexistent'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('cell exclusion', () {
    test('excludeCell sets excludedFromRun = true', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      await repo.excludeCell(cells.first.matrixCellId);

      final updated = await (db.select(db.matrixCells)
            ..where(
                (t) => t.matrixCellId.equals(cells.first.matrixCellId)))
          .getSingle();
      expect(updated.excludedFromRun, true);
    });

    test('includeCell re-enables cell', () async {
      await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      await repo.excludeCell(cells.first.matrixCellId);
      await repo.includeCell(cells.first.matrixCellId);

      final updated = await (db.select(db.matrixCells)
            ..where(
                (t) => t.matrixCellId.equals(cells.first.matrixCellId)))
          .getSingle();
      expect(updated.excludedFromRun, false);
    });
  });

  group('completeMatrixRun', () {
    test('transitions run to Completed when all cells meet target', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());

      await _completeRunWithAttempts(db, run.matrixRunId, 3);

      final completed =
          await repo.completeMatrixRun(run.matrixRunId, userId);
      expect(completed.runState, RunState.completed);
      expect(completed.endTimestamp, isNotNull);
    });

    test('excluded cells are not checked for minimum attempts', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      // Exclude one cell.
      await repo.excludeCell(cells.last.matrixCellId);

      // Add attempts only to non-excluded cells.
      for (final cell in cells.take(2)) {
        for (var i = 0; i < 3; i++) {
          await repo.logAttempt(
            cell.matrixCellId,
            MatrixAttemptsCompanion.insert(
              matrixAttemptId: '',
              matrixCellId: '',
              carryDistanceMeters: Value(100.0 + i),
            ),
          );
        }
      }

      final completed =
          await repo.completeMatrixRun(run.matrixRunId, userId);
      expect(completed.runState, RunState.completed);
    });

    test('rejects completion when cell has insufficient attempts', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      // Only add attempts to 2 of 3 cells.
      for (final cell in cells.take(2)) {
        for (var i = 0; i < 3; i++) {
          await repo.logAttempt(
            cell.matrixCellId,
            MatrixAttemptsCompanion.insert(
              matrixAttemptId: '',
              matrixCellId: '',
              carryDistanceMeters: Value(100.0 + i),
            ),
          );
        }
      }

      expect(
        () => repo.completeMatrixRun(run.matrixRunId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects completion of already completed run', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      await _completeRunWithAttempts(db, run.matrixRunId, 3);
      await repo.completeMatrixRun(run.matrixRunId, userId);

      expect(
        () => repo.completeMatrixRun(run.matrixRunId, userId),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects completion for wrong user', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      await _completeRunWithAttempts(db, run.matrixRunId, 3);

      expect(
        () => repo.completeMatrixRun(run.matrixRunId, 'other-user'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects completion of nonexistent run', () async {
      expect(
        () => repo.completeMatrixRun('nonexistent', userId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('discardMatrixRun', () {
    test('soft-deletes an active run', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      await repo.discardMatrixRun(run.matrixRunId, userId);

      final found = await repo.getMatrixRunById(run.matrixRunId);
      expect(found, isNull);

      // Still exists in DB with isDeleted = true.
      final raw = await (db.select(db.matrixRuns)
            ..where((t) => t.matrixRunId.equals(run.matrixRunId)))
          .getSingleOrNull();
      expect(raw, isNotNull);
      expect(raw!.isDeleted, true);
    });

    test('allows creating new run after discard', () async {
      final run1 = await repo.createMatrixRun(userId, gappingConfig());
      await repo.discardMatrixRun(run1.matrixRunId, userId);

      final run2 = await repo.createMatrixRun(userId, gappingConfig());
      expect(run2.matrixRunId, isNot(run1.matrixRunId));
    });

    test('rejects discard for wrong user', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());

      expect(
        () => repo.discardMatrixRun(run.matrixRunId, 'other-user'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects discard of nonexistent run', () async {
      expect(
        () => repo.discardMatrixRun('nonexistent', userId),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('getCellsWithAttempts', () {
    test('returns cells with their attempts', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      final cells = await db.select(db.matrixCells).get();

      // Add 2 attempts to first cell, 1 to second.
      for (var i = 0; i < 2; i++) {
        await repo.logAttempt(
          cells[0].matrixCellId,
          MatrixAttemptsCompanion.insert(
            matrixAttemptId: '',
            matrixCellId: '',
            carryDistanceMeters: Value(100.0 + i),
          ),
        );
      }
      await repo.logAttempt(
        cells[1].matrixCellId,
        MatrixAttemptsCompanion.insert(
          matrixAttemptId: '',
          matrixCellId: '',
          carryDistanceMeters: const Value(120.0),
        ),
      );

      final result = await repo.getCellsWithAttempts(run.matrixRunId);
      expect(result.length, 3);

      final firstCell = result
          .firstWhere((c) => c.cell.matrixCellId == cells[0].matrixCellId);
      expect(firstCell.attempts.length, 2);

      final secondCell = result
          .firstWhere((c) => c.cell.matrixCellId == cells[1].matrixCellId);
      expect(secondCell.attempts.length, 1);

      final thirdCell = result
          .firstWhere((c) => c.cell.matrixCellId == cells[2].matrixCellId);
      expect(thirdCell.attempts.length, 0);
    });
  });

  group('Cartesian product cell generation', () {
    test('3-axis matrix generates correct cell count', () async {
      final config = MatrixRunConfig(
        matrixType: MatrixType.chippingMatrix,
        sessionShotTarget: 3,
        axes: const [
          AxisConfig(
            axisType: AxisType.club,
            axisName: 'Club',
            labels: ['SW', 'LW'],
          ),
          AxisConfig(
            axisType: AxisType.carryDistance,
            axisName: 'Distance',
            labels: ['5m', '10m', '15m'],
          ),
          AxisConfig(
            axisType: AxisType.flight,
            axisName: 'Flight',
            labels: ['Low', 'High'],
          ),
        ],
      );

      await repo.createMatrixRun(userId, config);
      final cells = await db.select(db.matrixCells).get();

      // 2 × 3 × 2 = 12 cells
      expect(cells.length, 12);

      // Each cell has a 3-element axisValueIds array.
      for (final cell in cells) {
        final ids =
            (jsonDecode(cell.axisValueIds) as List<dynamic>).cast<String>();
        expect(ids.length, 3);
      }
    });

    test('1-axis matrix generates N cells', () async {
      await repo.createMatrixRun(
        userId,
        gappingConfig(clubs: ['D', 'W3', 'W5', '5i', '6i', '7i', '8i', '9i']),
      );
      final cells = await db.select(db.matrixCells).get();
      expect(cells.length, 8);
    });
  });

  group('mutual exclusivity integration', () {
    test('can start run after PracticeBlock ends', () async {
      // Insert and close a PracticeBlock.
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-1',
              userId: userId,
              endTimestamp: Value(DateTime.now()),
            ),
          );

      // Should succeed — PB is closed (endTimestamp non-null).
      final run = await repo.createMatrixRun(userId, gappingConfig());
      expect(run.runState, RunState.inProgress);
    });

    test('can start PracticeBlock after MatrixRun completes', () async {
      final run = await repo.createMatrixRun(userId, gappingConfig());
      await _completeRunWithAttempts(db, run.matrixRunId, 3);
      await repo.completeMatrixRun(run.matrixRunId, userId);

      // Should not block — no active MatrixRun.
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-2',
              userId: userId,
            ),
          );

      // Verify PB was created.
      final pb = await (db.select(db.practiceBlocks)
            ..where((t) => t.practiceBlockId.equals('pb-2')))
          .getSingleOrNull();
      expect(pb, isNotNull);
    });
  });
}

/// Helper: add minimum attempts to all cells so the run can be completed.
Future<void> _completeRunWithAttempts(
  AppDatabase db,
  String runId,
  int shotTarget,
) async {
  final cells = await (db.select(db.matrixCells)
        ..where((t) => t.matrixRunId.equals(runId))
        ..where((t) => t.excludedFromRun.equals(false)))
      .get();

  var attemptCounter = 0;
  for (final cell in cells) {
    for (var i = 0; i < shotTarget; i++) {
      attemptCounter++;
      await db.into(db.matrixAttempts).insert(
            MatrixAttemptsCompanion.insert(
              matrixAttemptId: 'auto-att-$attemptCounter',
              matrixCellId: cell.matrixCellId,
              carryDistanceMeters: Value(100.0 + i),
            ),
          );
    }
  }
}
