import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Matrix §6 — Matrix runtime model repository.
// Manages MatrixRun lifecycle, cell generation, attempt CRUD,
// completion validation, and mutual exclusivity with PracticeBlock.

/// Composite: MatrixRun + axes + axis values + cells + attempts.
class MatrixRunWithDetails {
  final MatrixRun run;
  final List<MatrixAxisWithValues> axes;
  final List<MatrixCellWithAttempts> cells;

  const MatrixRunWithDetails({
    required this.run,
    required this.axes,
    required this.cells,
  });
}

/// Composite: MatrixAxis + its values.
class MatrixAxisWithValues {
  final MatrixAxis axis;
  final List<MatrixAxisValue> values;

  const MatrixAxisWithValues({required this.axis, required this.values});
}

/// Composite: MatrixCell + its attempts.
class MatrixCellWithAttempts {
  final MatrixCell cell;
  final List<MatrixAttempt> attempts;

  const MatrixCellWithAttempts({required this.cell, required this.attempts});
}

/// Configuration for creating a new matrix run.
class MatrixRunConfig {
  final MatrixType matrixType;
  final int sessionShotTarget;
  final ShotOrderMode shotOrderMode;
  final bool dispersionCaptureEnabled;
  final String? measurementDevice;
  final EnvironmentType? environmentType;
  final SurfaceType? surfaceType;
  final double? greenSpeed;
  final GreenFirmness? greenFirmness;
  /// List of axes, each containing (axisType, axisName, [labels]).
  final List<AxisConfig> axes;

  const MatrixRunConfig({
    required this.matrixType,
    required this.sessionShotTarget,
    this.shotOrderMode = ShotOrderMode.topToBottom,
    this.dispersionCaptureEnabled = false,
    this.measurementDevice,
    this.environmentType,
    this.surfaceType,
    this.greenSpeed,
    this.greenFirmness,
    required this.axes,
  });
}

/// Configuration for a single axis.
class AxisConfig {
  final AxisType axisType;
  final String axisName;
  final List<String> labels;

  const AxisConfig({
    required this.axisType,
    required this.axisName,
    required this.labels,
  });
}

class MatrixRepository {
  final AppDatabase _db;
  final SyncWriteGate _gate;

  static const _uuid = Uuid();

  MatrixRepository(this._db, this._gate);

  // ---------------------------------------------------------------------------
  // MatrixRun CRUD
  // ---------------------------------------------------------------------------

  /// Matrix §6.1–6.4 — Create a new matrix run with axes, values, and cells.
  /// Guards: no active PracticeBlock or MatrixRun for this user.
  Future<MatrixRun> createMatrixRun(
    String userId,
    MatrixRunConfig config,
  ) async {
    await _gate.awaitGateRelease();

    // Validate shot target.
    if (config.sessionShotTarget < 3) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'SessionShotTarget must be >= 3',
        context: {'value': config.sessionShotTarget},
      );
    }

    // Validate axes.
    if (config.axes.isEmpty) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'At least one axis is required',
      );
    }
    for (final axis in config.axes) {
      if (axis.labels.isEmpty) {
        throw ValidationException(
          code: ValidationException.requiredField,
          message: 'Axis "${axis.axisName}" must have at least one value',
        );
      }
    }

    try {
      return await _db.transaction(() async {
        // Matrix §2.4 — Mutual exclusivity: no active PracticeBlock.
        final activePB = await (_db.select(_db.practiceBlocks)
              ..where((t) => t.userId.equals(userId))
              ..where((t) => t.endTimestamp.isNull())
              ..where((t) => t.isDeleted.equals(false))
              ..limit(1))
            .getSingleOrNull();
        if (activePB != null) {
          throw ConflictException(
            code: ConflictException.dualActiveSession,
            message: 'Cannot start matrix run: active practice block exists',
            context: {'practiceBlockId': activePB.practiceBlockId},
          );
        }

        // Matrix §6.1 — No active MatrixRun for this user.
        final activeRun = await _getActiveMatrixRunRaw(userId);
        if (activeRun != null) {
          throw ConflictException(
            code: ConflictException.dualActiveSession,
            message: 'Cannot start matrix run: another matrix run is active',
            context: {'matrixRunId': activeRun.matrixRunId},
          );
        }

        // Compute next RunNumber (per-user sequential).
        final maxRunResult = await _db.customSelect(
          'SELECT MAX(RunNumber) as maxRun FROM MatrixRun WHERE UserID = ?',
          variables: [Variable.withString(userId)],
        ).getSingleOrNull();
        final nextRunNumber =
            (maxRunResult?.read<int?>('maxRun') ?? 0) + 1;

        final runId = _uuid.v4();

        // Insert MatrixRun.
        final run = await _db.into(_db.matrixRuns).insertReturning(
              MatrixRunsCompanion.insert(
                matrixRunId: runId,
                userId: userId,
                matrixType: config.matrixType,
                runNumber: nextRunNumber,
                runState: RunState.inProgress,
                sessionShotTarget: config.sessionShotTarget,
                shotOrderMode: config.shotOrderMode,
                dispersionCaptureEnabled:
                    Value(config.dispersionCaptureEnabled),
                measurementDevice: Value(config.measurementDevice),
                environmentType: Value(config.environmentType),
                surfaceType: Value(config.surfaceType),
                greenSpeed: Value(config.greenSpeed),
                greenFirmness: Value(config.greenFirmness),
              ),
            );

        // Matrix §6.2 — Create axes and axis values.
        final allAxisValues = <List<String>>[]; // AxisValueIDs per axis
        for (var axisIndex = 0;
            axisIndex < config.axes.length;
            axisIndex++) {
          final axisConfig = config.axes[axisIndex];
          final axisId = _uuid.v4();

          await _db.into(_db.matrixAxes).insert(
                MatrixAxesCompanion.insert(
                  matrixAxisId: axisId,
                  matrixRunId: runId,
                  axisType: axisConfig.axisType,
                  axisName: axisConfig.axisName,
                  axisOrder: axisIndex + 1,
                ),
              );

          final valueIds = <String>[];
          for (var valIndex = 0;
              valIndex < axisConfig.labels.length;
              valIndex++) {
            final valueId = _uuid.v4();
            await _db.into(_db.matrixAxisValues).insert(
                  MatrixAxisValuesCompanion.insert(
                    axisValueId: valueId,
                    matrixAxisId: axisId,
                    label: axisConfig.labels[valIndex],
                    sortOrder: valIndex + 1,
                  ),
                );
            valueIds.add(valueId);
          }
          allAxisValues.add(valueIds);
        }

        // Matrix §6.3–6.4 — Generate cells as Cartesian product of axis values.
        final cellCombinations = _cartesianProduct(allAxisValues);
        for (final combination in cellCombinations) {
          await _db.into(_db.matrixCells).insert(
                MatrixCellsCompanion.insert(
                  matrixCellId: _uuid.v4(),
                  matrixRunId: runId,
                  axisValueIds: Value(jsonEncode(combination)),
                ),
              );
        }

        return run;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create matrix run',
        context: {'error': e.toString()},
      );
    }
  }

  /// Matrix §6.3 — Cartesian product of axis value ID lists.
  static List<List<String>> _cartesianProduct(List<List<String>> lists) {
    if (lists.isEmpty) return [];
    if (lists.length == 1) {
      return lists[0].map((v) => [v]).toList();
    }

    var result = lists[0].map((v) => [v]).toList();
    for (var i = 1; i < lists.length; i++) {
      final newResult = <List<String>>[];
      for (final existing in result) {
        for (final value in lists[i]) {
          newResult.add([...existing, value]);
        }
      }
      result = newResult;
    }
    return result;
  }

  /// Retrieve a single MatrixRun by ID.
  Future<MatrixRun?> getMatrixRunById(String runId) {
    return (_db.select(_db.matrixRuns)
          ..where((t) => t.matrixRunId.equals(runId))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get active (InProgress) MatrixRun for a user, or null.
  Future<MatrixRun?> getActiveMatrixRun(String userId) {
    return _getActiveMatrixRunRaw(userId);
  }

  Future<MatrixRun?> _getActiveMatrixRunRaw(String userId) {
    return (_db.select(_db.matrixRuns)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.runState.equals(RunState.inProgress.dbValue))
          ..where((t) => t.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Watch active MatrixRun for a user.
  Stream<MatrixRun?> watchActiveMatrixRun(String userId) {
    return (_db.select(_db.matrixRuns)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.runState.equals(RunState.inProgress.dbValue))
          ..where((t) => t.isDeleted.equals(false))
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Watch all completed runs for a user, most recent first.
  Stream<List<MatrixRun>> watchMatrixRunsByUser(String userId) {
    return (_db.select(_db.matrixRuns)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.desc(t.startTimestamp),
          ]))
        .watch();
  }

  /// Fetch full run details: run + axes + values + cells + attempts.
  Future<MatrixRunWithDetails?> getMatrixRunWithDetails(String runId) async {
    final run = await getMatrixRunById(runId);
    if (run == null) return null;

    final axes = await (_db.select(_db.matrixAxes)
          ..where((t) => t.matrixRunId.equals(runId))
          ..orderBy([(t) => OrderingTerm.asc(t.axisOrder)]))
        .get();

    // Batch-fetch all axis values for this run's axes in one query.
    final axisIds = axes.map((a) => a.matrixAxisId).toList();
    final allValues = axisIds.isEmpty
        ? <MatrixAxisValue>[]
        : await (_db.select(_db.matrixAxisValues)
              ..where((t) => t.matrixAxisId.isIn(axisIds))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
            .get();
    final valuesByAxis = <String, List<MatrixAxisValue>>{};
    for (final v in allValues) {
      valuesByAxis.putIfAbsent(v.matrixAxisId, () => []).add(v);
    }
    final axesWithValues = axes
        .map((a) => MatrixAxisWithValues(
            axis: a, values: valuesByAxis[a.matrixAxisId] ?? []))
        .toList();

    final cells = await (_db.select(_db.matrixCells)
          ..where((t) => t.matrixRunId.equals(runId)))
        .get();

    // Batch-fetch all attempts for this run's cells in one query.
    final cellIds = cells.map((c) => c.matrixCellId).toList();
    final allAttempts = cellIds.isEmpty
        ? <MatrixAttempt>[]
        : await (_db.select(_db.matrixAttempts)
              ..where((t) => t.matrixCellId.isIn(cellIds))
              ..orderBy([(t) => OrderingTerm.asc(t.attemptTimestamp)]))
            .get();
    final attemptsByCell = <String, List<MatrixAttempt>>{};
    for (final a in allAttempts) {
      attemptsByCell.putIfAbsent(a.matrixCellId, () => []).add(a);
    }
    final cellsWithAttempts = cells
        .map((c) => MatrixCellWithAttempts(
            cell: c, attempts: attemptsByCell[c.matrixCellId] ?? []))
        .toList();

    return MatrixRunWithDetails(
      run: run,
      axes: axesWithValues,
      cells: cellsWithAttempts,
    );
  }

  /// Watch full run details as a stream.
  Stream<MatrixRunWithDetails?> watchMatrixRunWithDetails(String runId) {
    // Watch the run table for changes, then rebuild full details.
    return (_db.select(_db.matrixRuns)
          ..where((t) => t.matrixRunId.equals(runId))
          ..where((t) => t.isDeleted.equals(false)))
        .watchSingleOrNull()
        .asyncMap((run) async {
      if (run == null) return null;
      return getMatrixRunWithDetails(runId);
    });
  }

  // ---------------------------------------------------------------------------
  // Attempt CRUD
  // ---------------------------------------------------------------------------

  /// Matrix §6.5 — Log a new attempt in a cell.
  /// Guard: run must be InProgress, cell must not be excluded.
  Future<MatrixAttempt> logAttempt(
    String cellId,
    MatrixAttemptsCompanion data,
  ) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        // Validate cell exists and run is InProgress.
        final cell = await (_db.select(_db.matrixCells)
              ..where((t) => t.matrixCellId.equals(cellId)))
            .getSingleOrNull();
        if (cell == null) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Cell not found',
            context: {'cellId': cellId},
          );
        }
        if (cell.excludedFromRun) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Cannot log attempt in excluded cell',
            context: {'cellId': cellId},
          );
        }

        final run = await (_db.select(_db.matrixRuns)
              ..where((t) => t.matrixRunId.equals(cell.matrixRunId))
              ..where((t) => t.isDeleted.equals(false)))
            .getSingleOrNull();
        if (run == null || run.runState != RunState.inProgress) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Cannot log attempt: run is not in progress',
          );
        }

        final attemptId = _uuid.v4();
        return await _db.into(_db.matrixAttempts).insertReturning(
              data.copyWith(
                matrixAttemptId: Value(attemptId),
                matrixCellId: Value(cellId),
              ),
            );
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to log attempt',
        context: {'error': e.toString()},
      );
    }
  }

  /// Matrix §6.10 — Update an existing attempt.
  Future<void> updateAttempt(
    String attemptId,
    MatrixAttemptsCompanion data,
  ) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final updated = await (_db.update(_db.matrixAttempts)
              ..where((t) => t.matrixAttemptId.equals(attemptId)))
            .write(data.copyWith(
          updatedAt: Value(DateTime.now()),
        ));
        if (updated == 0) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Attempt not found',
            context: {'attemptId': attemptId},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update attempt',
        context: {'error': e.toString()},
      );
    }
  }

  /// Matrix §6.10 — Delete an attempt.
  Future<void> deleteAttempt(String attemptId) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final deleted = await (_db.delete(_db.matrixAttempts)
              ..where((t) => t.matrixAttemptId.equals(attemptId)))
            .go();
        if (deleted == 0) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Attempt not found',
            context: {'attemptId': attemptId},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to delete attempt',
        context: {'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Cell exclusion
  // ---------------------------------------------------------------------------

  /// Matrix §6.8 — Soft-exclude a cell from the run.
  Future<void> excludeCell(String cellId) async {
    await _gate.awaitGateRelease();
    await (_db.update(_db.matrixCells)
          ..where((t) => t.matrixCellId.equals(cellId)))
        .write(MatrixCellsCompanion(
      excludedFromRun: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Matrix §6.9 — Re-include a previously excluded cell.
  Future<void> includeCell(String cellId) async {
    await _gate.awaitGateRelease();
    await (_db.update(_db.matrixCells)
          ..where((t) => t.matrixCellId.equals(cellId)))
        .write(MatrixCellsCompanion(
      excludedFromRun: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ---------------------------------------------------------------------------
  // Run lifecycle
  // ---------------------------------------------------------------------------

  /// Matrix §6.11 — Complete a matrix run.
  /// Guard: all active (non-excluded) cells must meet minimum attempt count.
  Future<MatrixRun> completeMatrixRun(String runId, String userId) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final run = await (_db.select(_db.matrixRuns)
              ..where((t) => t.matrixRunId.equals(runId))
              ..where((t) => t.isDeleted.equals(false)))
            .getSingleOrNull();
        if (run == null) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Matrix run not found',
            context: {'runId': runId},
          );
        }
        if (run.runState != RunState.inProgress) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Matrix run is not in progress',
          );
        }
        if (run.userId != userId) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Matrix run does not belong to user',
          );
        }

        // Check all active cells meet minimum attempts.
        final activeCells = await (_db.select(_db.matrixCells)
              ..where((t) => t.matrixRunId.equals(runId))
              ..where((t) => t.excludedFromRun.equals(false)))
            .get();

        // Batch-fetch attempt counts per cell in one query.
        final activeCellIds =
            activeCells.map((c) => c.matrixCellId).toList();
        final allAttempts = activeCellIds.isEmpty
            ? <MatrixAttempt>[]
            : await (_db.select(_db.matrixAttempts)
                  ..where((t) => t.matrixCellId.isIn(activeCellIds)))
                .get();
        final attemptCountByCell = <String, int>{};
        for (final a in allAttempts) {
          attemptCountByCell[a.matrixCellId] =
              (attemptCountByCell[a.matrixCellId] ?? 0) + 1;
        }

        for (final cell in activeCells) {
          final count = attemptCountByCell[cell.matrixCellId] ?? 0;
          if (count < run.sessionShotTarget) {
            throw ValidationException(
              code: ValidationException.stateTransition,
              message:
                  'Cell has insufficient attempts ($count/${run.sessionShotTarget})',
              context: {'cellId': cell.matrixCellId},
            );
          }
        }

        // Transition to Completed.
        final now = DateTime.now();
        await (_db.update(_db.matrixRuns)
              ..where((t) => t.matrixRunId.equals(runId)))
            .write(MatrixRunsCompanion(
          runState: const Value(RunState.completed),
          endTimestamp: Value(now),
          updatedAt: Value(now),
        ));

        return (await getMatrixRunById(runId))!;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to complete matrix run',
        context: {'error': e.toString()},
      );
    }
  }

  /// Matrix §1.6 — Discard (soft-delete) a matrix run.
  Future<void> discardMatrixRun(String runId, String userId) async {
    await _gate.awaitGateRelease();
    try {
      await _db.transaction(() async {
        final run = await (_db.select(_db.matrixRuns)
              ..where((t) => t.matrixRunId.equals(runId))
              ..where((t) => t.isDeleted.equals(false)))
            .getSingleOrNull();
        if (run == null) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Matrix run not found',
            context: {'runId': runId},
          );
        }
        if (run.userId != userId) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Matrix run does not belong to user',
          );
        }

        final now = DateTime.now();
        await (_db.update(_db.matrixRuns)
              ..where((t) => t.matrixRunId.equals(runId)))
            .write(MatrixRunsCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(now),
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to discard matrix run',
        context: {'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Get attempts for a specific cell.
  Future<List<MatrixAttempt>> getAttemptsForCell(String cellId) {
    return (_db.select(_db.matrixAttempts)
          ..where((t) => t.matrixCellId.equals(cellId))
          ..orderBy([(t) => OrderingTerm.asc(t.attemptTimestamp)]))
        .get();
  }

  /// Get cells for a run (with attempt counts for progress tracking).
  Future<List<MatrixCellWithAttempts>> getCellsWithAttempts(
      String runId) async {
    final cells = await (_db.select(_db.matrixCells)
          ..where((t) => t.matrixRunId.equals(runId)))
        .get();

    // Batch-fetch all attempts for this run's cells in one query.
    final cellIds = cells.map((c) => c.matrixCellId).toList();
    final allAttempts = cellIds.isEmpty
        ? <MatrixAttempt>[]
        : await (_db.select(_db.matrixAttempts)
              ..where((t) => t.matrixCellId.isIn(cellIds))
              ..orderBy([(t) => OrderingTerm.asc(t.attemptTimestamp)]))
            .get();
    final attemptsByCell = <String, List<MatrixAttempt>>{};
    for (final a in allAttempts) {
      attemptsByCell.putIfAbsent(a.matrixCellId, () => []).add(a);
    }

    return cells
        .map((c) => MatrixCellWithAttempts(
            cell: c, attempts: attemptsByCell[c.matrixCellId] ?? []))
        .toList();
  }
}
