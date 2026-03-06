import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Matrix §1.9 — Performance snapshot repository.
// Manages PerformanceSnapshot + SnapshotClub lifecycle,
// primary snapshot designation, and derived pre-population.

class PerformanceSnapshotRepository {
  final AppDatabase _db;
  final SyncWriteGate _gate;

  static const _uuid = Uuid();

  PerformanceSnapshotRepository(this._db, this._gate);

  // ---------------------------------------------------------------------------
  // Snapshot creation
  // ---------------------------------------------------------------------------

  /// Matrix §1.9 — Create a PerformanceSnapshot from a completed MatrixRun.
  /// Aggregates cell averages into SnapshotClub records.
  Future<PerformanceSnapshot> createSnapshotFromRun(
    String runId,
    String userId, {
    String? label,
    bool setAsPrimary = false,
  }) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        // Verify run is completed.
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
        if (run.runState != RunState.completed) {
          throw ValidationException(
            code: ValidationException.stateTransition,
            message: 'Cannot create snapshot from incomplete run',
          );
        }

        final snapshotId = _uuid.v4();

        // If setting as primary, unset any existing primary.
        if (setAsPrimary) {
          await _unsetPrimarySnapshot(userId);
        }

        await _db.into(_db.performanceSnapshots).insert(
              PerformanceSnapshotsCompanion.insert(
                snapshotId: snapshotId,
                userId: userId,
                matrixRunId: Value(runId),
                matrixType: Value(run.matrixType),
                isPrimary: Value(setAsPrimary),
                label: Value(label),
              ),
            );

        // Build SnapshotClub records from cell data.
        await _buildSnapshotClubs(snapshotId, runId, run.matrixType);

        return (await (_db.select(_db.performanceSnapshots)
                  ..where((t) => t.snapshotId.equals(snapshotId)))
                .getSingle());
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create snapshot',
        context: {'error': e.toString()},
      );
    }
  }

  /// Build SnapshotClub records by aggregating cell averages per club.
  Future<void> _buildSnapshotClubs(
    String snapshotId,
    String runId,
    MatrixType matrixType,
  ) async {
    // Get all active cells with their attempts.
    final cells = await (_db.select(_db.matrixCells)
          ..where((t) => t.matrixRunId.equals(runId))
          ..where((t) => t.excludedFromRun.equals(false)))
        .get();

    // Resolve which AxisValueID corresponds to the Club axis.
    final axes = await (_db.select(_db.matrixAxes)
          ..where((t) => t.matrixRunId.equals(runId))
          ..orderBy([(t) => OrderingTerm.asc(t.axisOrder)]))
        .get();

    // Find club axis index (0-based position in AxisValueIDs array).
    final clubAxisIndex =
        axes.indexWhere((a) => a.axisType == AxisType.club);
    if (clubAxisIndex < 0) return; // No club axis → no snapshot clubs.

    // Get all values for the club axis to map AxisValueID → Label (clubId).
    final clubAxis = axes[clubAxisIndex];
    final clubValues = await (_db.select(_db.matrixAxisValues)
          ..where((t) => t.matrixAxisId.equals(clubAxis.matrixAxisId)))
        .get();
    final clubValueMap = {
      for (final v in clubValues) v.axisValueId: v.label,
    };

    // Group cells by club (by the club axis value ID).
    final clubCells = <String, List<MatrixCell>>{};
    for (final cell in cells) {
      final valueIds =
          (jsonDecode(cell.axisValueIds) as List<dynamic>).cast<String>();
      if (clubAxisIndex < valueIds.length) {
        final clubValueId = valueIds[clubAxisIndex];
        clubCells.putIfAbsent(clubValueId, () => []).add(cell);
      }
    }

    // For each club, aggregate attempts across all its cells.
    for (final entry in clubCells.entries) {
      final clubLabel = clubValueMap[entry.key] ?? entry.key;
      final allAttempts = <MatrixAttempt>[];
      for (final cell in entry.value) {
        final attempts = await (_db.select(_db.matrixAttempts)
              ..where((t) => t.matrixCellId.equals(cell.matrixCellId)))
            .get();
        allAttempts.addAll(attempts);
      }

      if (allAttempts.isEmpty) continue;

      // Compute averages.
      double? avgCarry = _avg(
          allAttempts.map((a) => a.carryDistanceMeters).whereType<double>());
      double? avgTotal = _avg(
          allAttempts.map((a) => a.totalDistanceMeters).whereType<double>());
      double? avgLeft = _avg(
          allAttempts.map((a) => a.leftDeviationMeters).whereType<double>());
      double? avgRight = _avg(allAttempts
          .map((a) => a.rightDeviationMeters)
          .whereType<double>());
      double? avgRollout = _avg(allAttempts
          .map((a) => a.rolloutDistanceMeters)
          .whereType<double>());

      await _db.into(_db.snapshotClubs).insert(
            SnapshotClubsCompanion.insert(
              snapshotClubId: _uuid.v4(),
              snapshotId: snapshotId,
              clubId: clubLabel,
              carryDistanceMeters: Value(avgCarry),
              totalDistanceMeters: Value(avgTotal),
              dispersionLeftMeters: Value(avgLeft),
              dispersionRightMeters: Value(avgRight),
              rolloutDistanceMeters: Value(avgRollout),
            ),
          );
    }
  }

  static double? _avg(Iterable<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // ---------------------------------------------------------------------------
  // Snapshot queries
  // ---------------------------------------------------------------------------

  /// Get a snapshot with its clubs.
  Future<PerformanceSnapshot?> getSnapshot(String snapshotId) {
    return (_db.select(_db.performanceSnapshots)
          ..where((t) => t.snapshotId.equals(snapshotId))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  /// Get clubs for a snapshot.
  Future<List<SnapshotClub>> getSnapshotClubs(String snapshotId) {
    return (_db.select(_db.snapshotClubs)
          ..where((t) => t.snapshotId.equals(snapshotId)))
        .get();
  }

  /// Watch all snapshots for a user, most recent first.
  Stream<List<PerformanceSnapshot>> watchSnapshotsByUser(String userId) {
    return (_db.select(_db.performanceSnapshots)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.snapshotTimestamp)]))
        .watch();
  }

  /// Get the current primary snapshot for a user.
  Future<PerformanceSnapshot?> getPrimarySnapshot(String userId) {
    return (_db.select(_db.performanceSnapshots)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isPrimary.equals(true))
          ..where((t) => t.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // Primary snapshot management
  // ---------------------------------------------------------------------------

  /// Matrix §1.9 — Designate a snapshot as primary (unsets previous).
  Future<void> setPrimarySnapshot(String snapshotId, String userId) async {
    await _gate.awaitGateRelease();
    await _db.transaction(() async {
      await _unsetPrimarySnapshot(userId);
      await (_db.update(_db.performanceSnapshots)
            ..where((t) => t.snapshotId.equals(snapshotId)))
          .write(PerformanceSnapshotsCompanion(
        isPrimary: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }

  Future<void> _unsetPrimarySnapshot(String userId) async {
    await (_db.update(_db.performanceSnapshots)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isPrimary.equals(true)))
        .write(PerformanceSnapshotsCompanion(
      isPrimary: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ---------------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------------

  /// Soft-delete a snapshot.
  Future<void> deleteSnapshot(String snapshotId) async {
    await _gate.awaitGateRelease();
    await (_db.update(_db.performanceSnapshots)
          ..where((t) => t.snapshotId.equals(snapshotId)))
        .write(PerformanceSnapshotsCompanion(
      isDeleted: const Value(true),
      updatedAt: Value(DateTime.now()),
    ));
  }

  // ---------------------------------------------------------------------------
  // Derived pre-population (Matrix §1.9.3)
  // ---------------------------------------------------------------------------

  /// Matrix §1.9.3 — Compute derived club distances from up to 3 most recent
  /// completed runs of a given MatrixType, using recency-weighted formula.
  /// Returns map of clubLabel → weighted average carry distance.
  Future<Map<String, double>> getDerivedDistances(
    String userId,
    MatrixType matrixType,
  ) async {
    // Get up to 3 most recent completed runs.
    final runs = await (_db.select(_db.matrixRuns)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.matrixType.equals(matrixType.dbValue))
          ..where((t) => t.runState.equals(RunState.completed.dbValue))
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.startTimestamp)])
          ..limit(3))
        .get();

    if (runs.isEmpty) return {};

    final now = DateTime.now();
    final clubWeightedValues = <String, List<_WeightedValue>>{};

    for (final run in runs) {
      final ageDays =
          now.difference(run.startTimestamp).inDays.toDouble();
      // Matrix §1.9.3 — Recency weight formula.
      final weight = exp(-2.25 * sqrt(ageDays / 365.0));

      // Get snapshot for this run (if exists).
      final snapshot = await (_db.select(_db.performanceSnapshots)
            ..where((t) => t.matrixRunId.equals(run.matrixRunId))
            ..where((t) => t.isDeleted.equals(false))
            ..limit(1))
          .getSingleOrNull();

      if (snapshot == null) continue;

      final clubs = await getSnapshotClubs(snapshot.snapshotId);
      for (final club in clubs) {
        if (club.carryDistanceMeters != null) {
          clubWeightedValues
              .putIfAbsent(club.clubId, () => [])
              .add(_WeightedValue(club.carryDistanceMeters!, weight));
        }
      }
    }

    // Compute weighted averages.
    final result = <String, double>{};
    for (final entry in clubWeightedValues.entries) {
      final totalWeight =
          entry.value.fold<double>(0, (sum, wv) => sum + wv.weight);
      final weightedSum = entry.value
          .fold<double>(0, (sum, wv) => sum + wv.value * wv.weight);
      if (totalWeight > 0) {
        result[entry.key] = weightedSum / totalWeight;
      }
    }

    return result;
  }
}

class _WeightedValue {
  final double value;
  final double weight;
  const _WeightedValue(this.value, this.weight);
}
