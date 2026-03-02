import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/data/seed_data.dart';

// TD-07 §13.6 — Startup integrity checks run before UI is populated.

class StartupChecks {
  final AppDatabase _db;
  final ScoringRepository _scoringRepo;
  final ReflowEngine _reflowEngine;

  StartupChecks(this._db, this._scoringRepo, this._reflowEngine);

  /// Run all startup integrity checks in sequence.
  /// Returns true if a full rebuild was triggered.
  Future<bool> runAll(String userId) async {
    var rebuildTriggered = false;

    // 8a. RebuildNeeded flag check.
    if (await _checkRebuildNeeded(userId)) {
      rebuildTriggered = true;
    }

    // 8b. Scoring lock expiry check.
    if (await _checkScoringLockExpiry(userId)) {
      rebuildTriggered = true;
    }

    // 8c. Allocation invariant check.
    await _checkAllocationInvariant();

    // 8d. Referential integrity check (only if last error was RI).
    await _checkReferentialIntegrity();

    return rebuildTriggered;
  }

  /// TD-07 §13.6 8a — If rebuildNeeded is 'true', trigger a full rebuild.
  Future<bool> _checkRebuildNeeded(String userId) async {
    final row = await (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.key.equals(SyncMetadataKeys.rebuildNeeded)))
        .getSingleOrNull();

    if (row != null && row.value == 'true') {
      debugPrint('[StartupChecks] rebuildNeeded flag detected — triggering full rebuild');
      try {
        await _reflowEngine.executeFullRebuild(userId);
      } catch (e) {
        debugPrint('[StartupChecks] Full rebuild failed: $e');
      }
      return true;
    }
    return false;
  }

  /// TD-07 §13.6 8b — If a scoring lock is held and expired, force-acquire
  /// and trigger a full rebuild.
  Future<bool> _checkScoringLockExpiry(String userId) async {
    if (await _scoringRepo.hasExpiredLock(userId)) {
      debugPrint('[StartupChecks] Expired scoring lock detected — force-releasing and rebuilding');
      await _scoringRepo.releaseLock(userId);
      try {
        await _reflowEngine.executeFullRebuild(userId);
      } catch (e) {
        debugPrint('[StartupChecks] Full rebuild after lock expiry failed: $e');
      }
      return true;
    }
    return false;
  }

  /// TD-07 §13.6 8c — Verify SUM(Allocation) == 1000 across all SubskillRefs.
  /// If not, re-seed reference data.
  Future<void> _checkAllocationInvariant() async {
    final refs = await _scoringRepo.getAllSubskillRefs();
    final totalAllocation = refs.fold<int>(0, (sum, r) => sum + r.allocation);

    if (totalAllocation != kTotalAllocation) {
      debugPrint('[StartupChecks] Allocation invariant violated: '
          'sum=$totalAllocation, expected=$kTotalAllocation — re-seeding');
      await reseedSubskillRefs(_db);
    }
  }

  /// TD-07 §13.6 8d — Check for referential integrity errors.
  /// Only runs if last EventLog error was SYSTEM_REFERENTIAL_INTEGRITY.
  Future<void> _checkReferentialIntegrity() async {
    // Check last event log for referential integrity errors.
    final lastEvents = await (_db.select(_db.eventLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(1))
        .get();

    if (lastEvents.isEmpty) return;
    final lastEvent = lastEvents.first;

    if (lastEvent.eventTypeId == 'RebuildStorageFailure') {
      debugPrint('[StartupChecks] Last event was RebuildStorageFailure — running FK check');
      try {
        final result = await _db.customSelect('PRAGMA foreign_key_check').get();
        if (result.isNotEmpty) {
          debugPrint('[StartupChecks] FK violations found: ${result.length}');
        }
      } catch (e) {
        debugPrint('[StartupChecks] FK check failed: $e');
      }
    }
  }
}
