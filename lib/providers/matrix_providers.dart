// Phase M4 — Matrix domain Riverpod providers.
// Bridges MatrixRepository + PerformanceSnapshotRepository to UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/sync/sync_orchestrator.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/data/repositories/performance_snapshot_repository.dart';

import 'repository_providers.dart';
import 'sync_providers.dart';

/// Stream of user's active matrix run (at most one).
final activeMatrixRunProvider =
    StreamProvider.family<MatrixRun?, String>((ref, userId) {
  return ref.watch(matrixRepositoryProvider).watchActiveMatrixRun(userId);
});

/// Stream of all matrix runs for a user (non-deleted, newest first).
final matrixRunsProvider =
    StreamProvider.family<List<MatrixRun>, String>((ref, userId) {
  return ref.watch(matrixRepositoryProvider).watchMatrixRunsByUser(userId);
});

/// Stream of full details for a specific matrix run (axes, values, cells, attempts).
final matrixRunDetailsProvider =
    StreamProvider.family<MatrixRunWithDetails?, String>((ref, runId) {
  return ref.watch(matrixRepositoryProvider).watchMatrixRunWithDetails(runId);
});

/// Stream of user's performance snapshots (non-deleted, newest first).
final snapshotsProvider =
    StreamProvider.family<List<PerformanceSnapshot>, String>((ref, userId) {
  return ref
      .watch(performanceSnapshotRepositoryProvider)
      .watchSnapshotsByUser(userId);
});

/// Current primary snapshot for a user.
final primarySnapshotProvider =
    FutureProvider.family<PerformanceSnapshot?, String>((ref, userId) {
  return ref
      .watch(performanceSnapshotRepositoryProvider)
      .getPrimarySnapshot(userId);
});

/// Derived distances for target pre-population (per MatrixType).
final derivedDistancesProvider = FutureProvider.family<Map<String, double>,
    ({String userId, MatrixType matrixType})>((ref, params) {
  return ref
      .watch(performanceSnapshotRepositoryProvider)
      .getDerivedDistances(params.userId, params.matrixType);
});

/// Coordinator for matrix run lifecycle actions.
/// Bridges MatrixRepository + PerformanceSnapshotRepository + SyncOrchestrator.
class MatrixActions {
  final MatrixRepository _matrixRepo;
  final PerformanceSnapshotRepository _snapshotRepo;
  final SyncOrchestrator? _syncOrchestrator;

  MatrixActions(
    this._matrixRepo,
    this._snapshotRepo, [
    this._syncOrchestrator,
  ]);

  /// Create a new matrix run with the given configuration.
  /// Guards mutual exclusivity (no active PB or MatrixRun).
  Future<MatrixRun> createMatrixRun(
    String userId,
    MatrixRunConfig config,
  ) async {
    return _matrixRepo.createMatrixRun(userId, config);
  }

  /// Log a shot attempt to a cell.
  Future<MatrixAttempt> logAttempt(
    String cellId,
    MatrixAttemptsCompanion data,
  ) async {
    return _matrixRepo.logAttempt(cellId, data);
  }

  /// Update an existing attempt.
  Future<void> updateAttempt(
    String attemptId,
    MatrixAttemptsCompanion data,
  ) async {
    await _matrixRepo.updateAttempt(attemptId, data);
  }

  /// Delete an attempt (soft-delete).
  Future<void> deleteAttempt(String attemptId) async {
    await _matrixRepo.deleteAttempt(attemptId);
  }

  /// Exclude a cell from the run.
  Future<void> excludeCell(String cellId) async {
    await _matrixRepo.excludeCell(cellId);
  }

  /// Include a previously excluded cell.
  Future<void> includeCell(String cellId) async {
    await _matrixRepo.includeCell(cellId);
  }

  /// Complete a matrix run (validates all active cells meet shot target).
  /// Triggers post-session sync.
  Future<MatrixRun> completeMatrixRun(String runId, String userId) async {
    final run = await _matrixRepo.completeMatrixRun(runId, userId);
    _syncOrchestrator?.requestSync(SyncTrigger.postSession);
    return run;
  }

  /// Discard (soft-delete) a matrix run and all child entities.
  Future<void> discardMatrixRun(String runId, String userId) async {
    await _matrixRepo.discardMatrixRun(runId, userId);
    _syncOrchestrator?.requestSync(SyncTrigger.postSession);
  }

  /// Create a performance snapshot from a completed run.
  Future<PerformanceSnapshot> createSnapshotFromRun(
    String runId,
    String userId, {
    String? label,
    bool setAsPrimary = false,
  }) async {
    return _snapshotRepo.createSnapshotFromRun(
      runId,
      userId,
      label: label,
      setAsPrimary: setAsPrimary,
    );
  }

  /// Designate a snapshot as the primary.
  Future<void> setPrimarySnapshot(String snapshotId, String userId) async {
    await _snapshotRepo.setPrimarySnapshot(snapshotId, userId);
  }

  /// Soft-delete a snapshot.
  Future<void> deleteSnapshot(String snapshotId) async {
    await _snapshotRepo.deleteSnapshot(snapshotId);
  }
}

/// Provider for MatrixActions coordinator.
final matrixActionsProvider = Provider<MatrixActions>((ref) {
  return MatrixActions(
    ref.watch(matrixRepositoryProvider),
    ref.watch(performanceSnapshotRepositoryProvider),
    ref.watch(syncOrchestratorProvider),
  );
});
