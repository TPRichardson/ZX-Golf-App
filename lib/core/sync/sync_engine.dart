import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/dto/sync_dto.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'merge_algorithm.dart';
import 'sync_types.dart';
import 'sync_write_gate.dart';

// TD-03 §5.1 — Sync engine. Orchestrates upload/download cycles.
// Phase 2.5: basic upload/download with stub merge (insert-only).
// Phase 7A: batching, diagnostics, failure tracking, feature flag.
// Phase 7B: LWW merge, gate enforcement, post-merge rebuild.

class SyncEngine {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  final SyncWriteGate _gate;
  final SyncInstrumentation? _diagnostics;
  // Phase 7B — ReflowEngine for post-merge full rebuild.
  final ReflowEngine? _reflowEngine;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = SyncStatus.idle;

  /// Current sync status (synchronous read).
  SyncStatus get currentStatus => _currentStatus;

  // TD-07 §6.1.1 — Completer-based mutex for sync coalescing.
  Completer<SyncResult>? _activeSyncCompleter;
  bool _pendingSync = false;

  // TD-07 §6.2 — Consecutive failure counter.
  int _consecutiveFailures = 0;
  bool _failuresLoaded = false;

  // TD-03 §5.1 — Feature flag: enable/disable sync.
  bool _syncEnabled = true;
  bool _syncEnabledLoaded = false;

  // Phase 7C — Merge timeout counter (transient, not persisted). TD-07 §6.2.
  int _consecutiveMergeTimeouts = 0;

  // Phase 7C — Schema mismatch persistent flag. TD-07 §6.4.
  bool _schemaMismatchDetected = false;
  bool _schemaMismatchLoaded = false;

  // Phase 7C — Last error code from most recent failure.
  String? _lastErrorCode;

  // Phase 7C — Dual active session detection stream.
  final _dualActiveSessionController = StreamController<String>.broadcast();

  /// TD-07 §6.2 — Current consecutive failure count.
  int get consecutiveFailures => _consecutiveFailures;

  /// TD-03 §5.1 — Whether sync is enabled.
  bool get syncEnabled => _syncEnabled;

  /// Phase 7C — Current consecutive merge timeout count. TD-07 §6.2.
  int get consecutiveMergeTimeouts => _consecutiveMergeTimeouts;

  /// Phase 7C — Whether a schema mismatch has been detected. TD-07 §6.4.
  bool get schemaMismatchDetected => _schemaMismatchDetected;

  /// Phase 7C — Last error code from most recent failure, null if last cycle succeeded.
  String? get lastErrorCode => _lastErrorCode;

  /// Phase 7C — Stream emitting conflicting practiceBlockId when dual active sessions detected.
  Stream<String> get onDualActiveSessionDetected =>
      _dualActiveSessionController.stream;

  SyncEngine(this._supabase, this._db, this._gate,
      [this._diagnostics, this._reflowEngine]);

  /// TD-03 §5.1 — Stream of sync status changes.
  Stream<SyncStatus> getSyncStatus() => _statusController.stream;

  /// TD-03 §5.1 — Read last sync timestamp from SyncMetadata.
  Future<DateTime?> getLastSyncTimestamp() async {
    final row = await (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.key.equals(SyncMetadataKeys.lastSyncTimestamp)))
        .getSingleOrNull();
    if (row == null) return null;
    return DateTime.parse(row.value);
  }

  /// TD-03 §5.1 — Force a full sync (ignore last sync timestamp).
  Future<SyncResult> forceFullSync() {
    return triggerSync(reason: SyncTrigger.forceFullSync);
  }

  /// TD-07 §6.2 — Set sync enabled/disabled and persist.
  Future<void> setSyncEnabled(bool enabled) async {
    _syncEnabled = enabled;
    _syncEnabledLoaded = true;
    await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion.insert(
            key: SyncMetadataKeys.syncEnabled,
            value: enabled.toString(),
          ),
        );
  }

  /// TD-07 §6.2 — Reset failure counter to 0, re-enable sync, persist.
  Future<void> resetFailureCounter() async {
    _consecutiveFailures = 0;
    _syncEnabled = true;
    await _persistConsecutiveFailures();
    await setSyncEnabled(true);
  }

  /// S17 §17.4 — Set offline/online status.
  void setOffline(bool offline) {
    if (offline) {
      _setStatus(SyncStatus.offline);
    } else if (_currentStatus == SyncStatus.offline) {
      _setStatus(SyncStatus.idle);
    }
  }

  /// TD-03 §5.1 — Trigger a sync cycle with coalescing mutex.
  Future<SyncResult> triggerSync({required SyncTrigger reason}) async {
    // TD-07 §6.2 — Load persisted state on first use.
    await _ensureStateLoaded();

    // TD-03 §5.1 — Short-circuit if sync disabled.
    if (!_syncEnabled) {
      debugPrint('[SyncEngine] Sync disabled (failures=$_consecutiveFailures). Call resetFailureCounter() to re-enable.');
      return SyncResult.failure(
        errorCode: SyncException.networkUnavailable,
        errorMessage:
            'Sync disabled after $kSyncMaxConsecutiveFailures consecutive failures',
      );
    }

    // TD-07 §6.1.1 — If a sync is active, coalesce into pending.
    if (_activeSyncCompleter != null) {
      _pendingSync = true;
      return _activeSyncCompleter!.future;
    }

    _activeSyncCompleter = Completer<SyncResult>();

    try {
      final result = await _executeSyncCycle(reason);
      _activeSyncCompleter!.complete(result);
      return result;
    } catch (e, st) {
      debugPrint('[SyncEngine] triggerSync error: $e');
      debugPrint('[SyncEngine] Stack trace:\n$st');
      final failure = SyncResult.failure(
        errorCode: SyncException.uploadFailed,
        errorMessage: e.toString(),
      );
      _activeSyncCompleter!.complete(failure);
      return failure;
    } finally {
      final hadPending = _pendingSync;
      _pendingSync = false;
      _activeSyncCompleter = null;

      // If a sync was queued while we were running, trigger another.
      if (hadPending) {
        triggerSync(reason: reason);
      }
    }
  }

  Future<SyncResult> _executeSyncCycle(SyncTrigger reason) async {
    final cycleStart = DateTime.now();
    _setStatus(SyncStatus.inProgress);
    _diagnostics?.emit('sync_cycle_start', Duration.zero, {
      'trigger': reason.name,
      'consecutiveFailures': _consecutiveFailures,
    });

    try {
      final rawLastSync = reason == SyncTrigger.forceFullSync
          ? null
          : await getLastSyncTimestamp();
      // Subtract 1 second to create an overlap window — prevents missing rows
      // with UpdatedAt equal to the saved timestamp. Duplicate uploads are
      // harmless (server upserts).
      final lastSync = rawLastSync?.subtract(const Duration(seconds: 1));
      // Step 1: Gather local changes and device ID
      debugPrint('[SyncEngine] Building upload payload (lastSync=$lastSync)');
      final payload = await _buildUploadPayload(lastSync);
      debugPrint('[SyncEngine] Payload tables: ${payload.keys.toList()}, counts: ${payload.map((k, v) => MapEntry(k, v.length))}');
      final deviceId = await _getOrCreateDeviceId();

      // Step 2: Batch and upload with retry
      final batches = batchPayload(payload);
      final uploadStart = DateTime.now();
      int totalUploaded = 0;
      dynamic lastUploadResponse;

      for (final batch in batches) {
        lastUploadResponse = await _callWithRetry(
          () => _supabase.rpc('sync_upload', params: {
            'schema_version': kSyncSchemaVersion,
            'device_id': deviceId,
            'changes': batch,
          }),
        );
        if (lastUploadResponse is Map &&
            lastUploadResponse['success'] != true) {
          final errorCode = lastUploadResponse['error_code'] as String? ?? 'UPLOAD_FAILED';
          final errorMsg = lastUploadResponse['error_message'] as String? ?? 'Upload failed';
          debugPrint('[SyncEngine] Upload failed: $errorCode — $errorMsg');
          throw SyncException(
            code: errorCode == 'SCHEMA_VERSION_MISMATCH'
                ? SyncException.schemaMismatch
                : SyncException.uploadFailed,
            message: errorMsg,
          );
        }

        totalUploaded += batch.values
            .fold<int>(0, (sum, list) => sum + list.length);
      }

      final uploadDuration = DateTime.now().difference(uploadStart);
      _diagnostics?.emit('sync_upload_complete', uploadDuration, {
        'uploadedCount': totalUploaded,
        'batchCount': batches.length,
      });

      // Step 3: Download with retry
      final downloadStart = DateTime.now();
      final downloadResponse = await _callWithRetry(
        () => _supabase.rpc('sync_download', params: {
          'schema_version': kSyncSchemaVersion,
          'last_sync_timestamp': lastSync?.toUtc().toIso8601String(),
        }),
      );
      // Fail the cycle if download returned an error.
      if (downloadResponse is Map && downloadResponse['success'] == false) {
        final errorCode = downloadResponse['error_code'] as String? ?? 'DOWNLOAD_FAILED';
        final errorMsg = downloadResponse['error_message'] as String? ?? 'Download failed';
        debugPrint('[SyncEngine] Download failed: $errorCode — $errorMsg');
        throw SyncException(
          code: SyncException.downloadFailed,
          message: errorMsg,
        );
      }

      // Step 4: LWW merge (Phase 7B).
      int downloadedCount = 0;
      if (downloadResponse is Map && downloadResponse['changes'] != null) {
        downloadedCount =
            await _applyDownloadedChanges(downloadResponse['changes'] as Map);
      }
      final downloadDuration = DateTime.now().difference(downloadStart);
      _diagnostics?.emit('sync_download_complete', downloadDuration, {
        'downloadedCount': downloadedCount,
      });

      // Step 5: Update last sync timestamp
      final serverTimestamp = lastUploadResponse is Map
          ? DateTime.parse(
              lastUploadResponse['server_timestamp'] as String? ??
                  DateTime.now().toUtc().toIso8601String())
          : DateTime.now().toUtc();

      await _updateLastSyncTimestamp(serverTimestamp);

      // TD-07 §6.2 — Reset failure counter on success.
      _consecutiveFailures = 0;
      _consecutiveMergeTimeouts = 0;
      _lastErrorCode = null;
      await _persistConsecutiveFailures();

      // Phase 7C — Clear schema mismatch on successful sync. TD-07 §6.4.
      if (_schemaMismatchDetected) {
        await _setSchemaMismatchDetected(false);
      }

      _setStatus(SyncStatus.idle);

      final rejectedRows = lastUploadResponse is Map
          ? (lastUploadResponse['rejected_rows'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              []
          : <Map<String, dynamic>>[];

      final totalDuration = DateTime.now().difference(cycleStart);
      final payloadBytes = _estimatePayloadBytes(payload);
      _diagnostics?.emitCycleSummary(
        trigger: reason,
        totalDuration: totalDuration,
        success: true,
        uploadedCount: totalUploaded,
        downloadedCount: downloadedCount,
        payloadBytes: payloadBytes,
        batchCount: batches.length,
        consecutiveFailures: 0,
      );

      return SyncResult.success(
        serverTimestamp: serverTimestamp,
        uploadedCount: totalUploaded,
        downloadedCount: downloadedCount,
        rejectedRows: rejectedRows,
      );
    } on SyncException catch (e) {
      // Phase 7C — Route exception by code per TD-07 §6.2/§6.4.
      if (e.code == SyncException.schemaMismatch) {
        // TD-07 §6.4 — Schema mismatch: do NOT increment failure counter.
        await _setSchemaMismatchDetected(true);
      } else if (e.code == SyncException.mergeTimeout) {
        // TD-07 §6.2 — Timeout: increment timeout counter, not failure counter.
        _consecutiveMergeTimeouts++;
      } else {
        await _incrementFailureCounter();
        _consecutiveMergeTimeouts = 0; // Reset timeout counter on non-timeout failure.
      }
      _lastErrorCode = e.code;
      _setStatus(SyncStatus.failed);

      final totalDuration = DateTime.now().difference(cycleStart);
      _diagnostics?.emitCycleSummary(
        trigger: reason,
        totalDuration: totalDuration,
        success: false,
        consecutiveFailures: _consecutiveFailures,
        errorCode: e.code,
      );

      rethrow;
    } catch (e, st) {
      debugPrint('[SyncEngine] _executeSyncCycle error: $e');
      debugPrint('[SyncEngine] Stack trace:\n$st');
      await _incrementFailureCounter();
      _setStatus(SyncStatus.failed);

      final totalDuration = DateTime.now().difference(cycleStart);
      _diagnostics?.emitCycleSummary(
        trigger: reason,
        totalDuration: totalDuration,
        success: false,
        consecutiveFailures: _consecutiveFailures,
        errorCode: SyncException.uploadFailed,
      );

      throw SyncException(
        code: SyncException.uploadFailed,
        message: 'Sync cycle failed: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // TD-03 §5.2 — Payload batching
  // ---------------------------------------------------------------------------

  /// TD-03 §5.2 — Table upload ordering: parent tables before child tables.
  static const tableUploadOrder = [
    'User',
    'Drill',
    'PracticeBlock',
    'Session',
    'Set',
    'Instance',
    'PracticeEntry',
    'UserDrillAdoption',
    'UserClub',
    'UserTrainingItem',
    'ClubPerformanceProfile',
    'UserSkillAreaClubMapping',
    'Routine',
    'Schedule',
    'CalendarDay',
    'RoutineInstance',
    'ScheduleInstance',
    'EventLog',
    'UserDevice',
  ];

  /// TD-03 §5.2 — Split payload into batches respecting 2MB limit.
  /// Parent tables come before child tables. Never splits mid-table.
  @visibleForTesting
  List<Map<String, List<Map<String, dynamic>>>> batchPayload(
    Map<String, List<Map<String, dynamic>>> payload,
  ) => staticBatchPayload(payload);

  /// Static version for direct testing without SyncEngine instance.
  @visibleForTesting
  static List<Map<String, List<Map<String, dynamic>>>> staticBatchPayload(
    Map<String, List<Map<String, dynamic>>> payload,
  ) {
    if (payload.isEmpty) return [payload];

    final totalBytes = _estimatePayloadBytes(payload);
    if (totalBytes <= kSyncMaxPayloadBytes) return [payload];

    // Sort tables by upload order.
    final orderedKeys = payload.keys.toList()
      ..sort((a, b) {
        final indexA = tableUploadOrder.indexOf(a);
        final indexB = tableUploadOrder.indexOf(b);
        return (indexA == -1 ? 999 : indexA)
            .compareTo(indexB == -1 ? 999 : indexB);
      });

    final batches = <Map<String, List<Map<String, dynamic>>>>[];
    var currentBatch = <String, List<Map<String, dynamic>>>{};
    var currentSize = 0;

    for (final table in orderedKeys) {
      final rows = payload[table]!;
      final tableSize = _estimateTableBytes(table, rows);

      if (currentBatch.isNotEmpty &&
          currentSize + tableSize > kSyncMaxPayloadBytes) {
        batches.add(currentBatch);
        currentBatch = {};
        currentSize = 0;
      }

      currentBatch[table] = rows;
      currentSize += tableSize;
    }

    if (currentBatch.isNotEmpty) {
      batches.add(currentBatch);
    }

    return batches.isEmpty ? [{}] : batches;
  }

  /// Estimate payload size in bytes (UTF-8 approximation via jsonEncode).
  static int _estimatePayloadBytes(
      Map<String, List<Map<String, dynamic>>> payload) {
    if (payload.isEmpty) return 2; // '{}'
    return jsonEncode(payload).length;
  }

  /// Estimate size of a single table's data.
  static int _estimateTableBytes(
      String table, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return table.length + 4; // '"Table":[]'
    return jsonEncode({table: rows}).length;
  }

  // ---------------------------------------------------------------------------
  // TD-07 §6.2 — Consecutive failure tracking
  // ---------------------------------------------------------------------------

  /// Lazy-load persisted state from SyncMetadata.
  Future<void> _ensureStateLoaded() async {
    if (!_failuresLoaded) {
      final row = await (_db.select(_db.syncMetadataEntries)
            ..where(
                (t) => t.key.equals(SyncMetadataKeys.consecutiveFailures)))
          .getSingleOrNull();
      if (row != null) {
        _consecutiveFailures = int.tryParse(row.value) ?? 0;
      }
      _failuresLoaded = true;
    }
    if (!_syncEnabledLoaded) {
      final row = await (_db.select(_db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.syncEnabled)))
          .getSingleOrNull();
      if (row != null) {
        _syncEnabled = row.value == 'true';
      }
      _syncEnabledLoaded = true;
    }
    // Phase 7C — Load schema mismatch flag. TD-07 §6.4.
    if (!_schemaMismatchLoaded) {
      final row = await (_db.select(_db.syncMetadataEntries)
            ..where(
                (t) => t.key.equals(SyncMetadataKeys.schemaMismatchDetected)))
          .getSingleOrNull();
      if (row != null) {
        _schemaMismatchDetected = row.value == 'true';
      }
      _schemaMismatchLoaded = true;
    }
  }

  /// Increment failure counter and auto-disable at threshold.
  Future<void> _incrementFailureCounter() async {
    _consecutiveFailures++;
    await _persistConsecutiveFailures();

    // TD-07 §6.2 — Auto-disable sync after kSyncMaxConsecutiveFailures.
    if (_consecutiveFailures >= kSyncMaxConsecutiveFailures) {
      _syncEnabled = false;
      await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.syncEnabled,
              value: 'false',
            ),
          );
      debugPrint(
          '[SyncEngine] Auto-disabled: $_consecutiveFailures consecutive failures');
    }
  }

  /// Phase 7C — Persist schema mismatch flag to SyncMetadata. TD-07 §6.4.
  Future<void> _setSchemaMismatchDetected(bool detected) async {
    _schemaMismatchDetected = detected;
    _schemaMismatchLoaded = true;
    await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion.insert(
            key: SyncMetadataKeys.schemaMismatchDetected,
            value: detected.toString(),
          ),
        );
  }

  /// Persist failure count to SyncMetadata.
  Future<void> _persistConsecutiveFailures() async {
    await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion.insert(
            key: SyncMetadataKeys.consecutiveFailures,
            value: _consecutiveFailures.toString(),
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Payload building (unchanged from Phase 2.5)
  // ---------------------------------------------------------------------------

  /// Build the upload payload: query each synced table for changes since lastSync.
  Future<Map<String, List<Map<String, dynamic>>>> _buildUploadPayload(
      DateTime? lastSync) async {
    final payload = <String, List<Map<String, dynamic>>>{};

    // User
    final users = lastSync == null
        ? await _db.select(_db.users).get()
        : await (_db.select(_db.users)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (users.isNotEmpty) {
      payload['User'] = users.map((e) => e.toSyncDto()).toList();
    }

    // Drill — exclude standard drills (server-authoritative, never uploaded).
    final allDrills = lastSync == null
        ? await _db.select(_db.drills).get()
        : await (_db.select(_db.drills)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    final drills = allDrills
        .where((d) => d.origin != DrillOrigin.standard)
        .toList();
    if (drills.isNotEmpty) {
      payload['Drill'] = drills.map((e) => e.toSyncDto()).toList();
    }

    // PracticeBlock — only upload finished blocks (endTimestamp set).
    final blockQuery = _db.select(_db.practiceBlocks)
      ..where((t) => t.endTimestamp.isNotNull());
    if (lastSync != null) {
      blockQuery.where((t) => t.updatedAt.isBiggerThanValue(lastSync));
    }
    final blocks = await blockQuery.get();
    if (blocks.isNotEmpty) {
      payload['PracticeBlock'] = blocks.map((e) => e.toSyncDto()).toList();
    }

    // Collect active (unfinished) block IDs to exclude their child data.
    final activeBlockIds = (await (_db.select(_db.practiceBlocks)
          ..where((t) => t.endTimestamp.isNull())
          ..where((t) => t.isDeleted.equals(false)))
        .get())
        .map((b) => b.practiceBlockId)
        .toSet();

    // Session — exclude sessions belonging to active blocks.
    final allSessions = lastSync == null
        ? await _db.select(_db.sessions).get()
        : await (_db.select(_db.sessions)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    final sessions = allSessions
        .where((s) => !activeBlockIds.contains(s.practiceBlockId))
        .toList();
    if (sessions.isNotEmpty) {
      payload['Session'] = sessions.map((e) => e.toSyncDto()).toList();
    }

    // Collect session IDs that are excluded (belong to active blocks).
    final excludedSessionIds = allSessions
        .where((s) => activeBlockIds.contains(s.practiceBlockId))
        .map((s) => s.sessionId)
        .toSet();

    // Set — exclude sets belonging to excluded sessions.
    final allSets = lastSync == null
        ? await _db.select(_db.sets).get()
        : await (_db.select(_db.sets)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    final sets = allSets
        .where((s) => !excludedSessionIds.contains(s.sessionId))
        .toList();

    // Ensure parent sessions for uploading sets are included (FK integrity).
    final uploadingSessionIds = sessions.map((s) => s.sessionId).toSet();
    final missingSessionIds = sets
        .map((s) => s.sessionId)
        .where((id) => !uploadingSessionIds.contains(id))
        .toSet();
    if (missingSessionIds.isNotEmpty) {
      final missingSessions = await (_db.select(_db.sessions)
            ..where((t) => t.sessionId.isIn(missingSessionIds)))
          .get();
      final filtered = missingSessions
          .where((s) => !activeBlockIds.contains(s.practiceBlockId));
      for (final s in filtered) {
        sessions.add(s);
      }
      // Also ensure parent blocks are included.
      final uploadingBlockIds = blocks.map((b) => b.practiceBlockId).toSet();
      final missingBlockIds = filtered
          .map((s) => s.practiceBlockId)
          .where((id) => !uploadingBlockIds.contains(id))
          .toSet();
      if (missingBlockIds.isNotEmpty) {
        final missingBlocks = await (_db.select(_db.practiceBlocks)
              ..where((t) => t.practiceBlockId.isIn(missingBlockIds))
              ..where((t) => t.endTimestamp.isNotNull()))
            .get();
        blocks.addAll(missingBlocks);
      }
      // Rebuild payload for Session and PracticeBlock.
      if (sessions.isNotEmpty) {
        payload['Session'] = sessions.map((e) => e.toSyncDto()).toList();
      }
      if (blocks.isNotEmpty) {
        payload['PracticeBlock'] = blocks.map((e) => e.toSyncDto()).toList();
      }
    }

    if (sets.isNotEmpty) {
      payload['Set'] = sets.map((e) => e.toSyncDto()).toList();
    }

    // Collect set IDs that are excluded.
    final excludedSetIds = allSets
        .where((s) => excludedSessionIds.contains(s.sessionId))
        .map((s) => s.setId)
        .toSet();

    // Instance — exclude instances belonging to excluded sets.
    final allInstances = lastSync == null
        ? await _db.select(_db.instances).get()
        : await (_db.select(_db.instances)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    final instances = allInstances
        .where((i) => !excludedSetIds.contains(i.setId))
        .toList();
    if (instances.isNotEmpty) {
      payload['Instance'] = instances.map((e) => e.toSyncDto()).toList();
    }

    // PracticeEntry — exclude entries belonging to active blocks.
    final allEntries = lastSync == null
        ? await _db.select(_db.practiceEntries).get()
        : await (_db.select(_db.practiceEntries)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    final entries = allEntries
        .where((e) => !activeBlockIds.contains(e.practiceBlockId))
        .toList();
    if (entries.isNotEmpty) {
      payload['PracticeEntry'] = entries.map((e) => e.toSyncDto()).toList();
    }

    // UserDrillAdoption
    final adoptions = lastSync == null
        ? await _db.select(_db.userDrillAdoptions).get()
        : await (_db.select(_db.userDrillAdoptions)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (adoptions.isNotEmpty) {
      payload['UserDrillAdoption'] =
          adoptions.map((e) => e.toSyncDto()).toList();
    }

    // UserClub
    final clubs = lastSync == null
        ? await _db.select(_db.userClubs).get()
        : await (_db.select(_db.userClubs)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (clubs.isNotEmpty) {
      payload['UserClub'] = clubs.map((e) => e.toSyncDto()).toList();
    }

    // UserTrainingItem
    final kitItems = lastSync == null
        ? await _db.select(_db.userTrainingItems).get()
        : await (_db.select(_db.userTrainingItems)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (kitItems.isNotEmpty) {
      payload['UserTrainingItem'] =
          kitItems.map((e) => e.toSyncDto()).toList();
    }

    // ClubPerformanceProfile
    final profiles = lastSync == null
        ? await _db.select(_db.clubPerformanceProfiles).get()
        : await (_db.select(_db.clubPerformanceProfiles)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (profiles.isNotEmpty) {
      payload['ClubPerformanceProfile'] =
          profiles.map((e) => e.toSyncDto()).toList();
    }

    // UserSkillAreaClubMapping
    final mappings = lastSync == null
        ? await _db.select(_db.userSkillAreaClubMappings).get()
        : await (_db.select(_db.userSkillAreaClubMappings)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (mappings.isNotEmpty) {
      payload['UserSkillAreaClubMapping'] =
          mappings.map((e) => e.toSyncDto()).toList();
    }

    // Routine
    final routines = lastSync == null
        ? await _db.select(_db.routines).get()
        : await (_db.select(_db.routines)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (routines.isNotEmpty) {
      payload['Routine'] = routines.map((e) => e.toSyncDto()).toList();
    }

    // Schedule
    final schedules = lastSync == null
        ? await _db.select(_db.schedules).get()
        : await (_db.select(_db.schedules)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (schedules.isNotEmpty) {
      payload['Schedule'] = schedules.map((e) => e.toSyncDto()).toList();
    }

    // CalendarDay
    final calendarDays = lastSync == null
        ? await _db.select(_db.calendarDays).get()
        : await (_db.select(_db.calendarDays)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (calendarDays.isNotEmpty) {
      payload['CalendarDay'] =
          calendarDays.map((e) => e.toSyncDto()).toList();
    }

    // RoutineInstance
    final routineInstances = lastSync == null
        ? await _db.select(_db.routineInstances).get()
        : await (_db.select(_db.routineInstances)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (routineInstances.isNotEmpty) {
      payload['RoutineInstance'] =
          routineInstances.map((e) => e.toSyncDto()).toList();
    }

    // ScheduleInstance
    final scheduleInstances = lastSync == null
        ? await _db.select(_db.scheduleInstances).get()
        : await (_db.select(_db.scheduleInstances)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (scheduleInstances.isNotEmpty) {
      payload['ScheduleInstance'] =
          scheduleInstances.map((e) => e.toSyncDto()).toList();
    }

    // EventLog — uses CreatedAt instead of UpdatedAt (append-only).
    final eventLogs = lastSync == null
        ? await _db.select(_db.eventLogs).get()
        : await (_db.select(_db.eventLogs)
              ..where((t) => t.createdAt.isBiggerThanValue(lastSync)))
            .get();
    if (eventLogs.isNotEmpty) {
      payload['EventLog'] = eventLogs.map((e) => e.toSyncDto()).toList();
    }

    // UserDevice
    final devices = lastSync == null
        ? await _db.select(_db.userDevices).get()
        : await (_db.select(_db.userDevices)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (devices.isNotEmpty) {
      payload['UserDevice'] = devices.map((e) => e.toSyncDto()).toList();
    }

    // Phase M3 — Matrix tables (parent-before-child order).
    final matrixRuns = lastSync == null
        ? await _db.select(_db.matrixRuns).get()
        : await (_db.select(_db.matrixRuns)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (matrixRuns.isNotEmpty) {
      payload['MatrixRun'] =
          matrixRuns.map((e) => e.toSyncDto()).toList();
    }

    final matrixAxes = lastSync == null
        ? await _db.select(_db.matrixAxes).get()
        : await (_db.select(_db.matrixAxes)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (matrixAxes.isNotEmpty) {
      payload['MatrixAxis'] =
          matrixAxes.map((e) => e.toSyncDto()).toList();
    }

    final matrixAxisValues = lastSync == null
        ? await _db.select(_db.matrixAxisValues).get()
        : await (_db.select(_db.matrixAxisValues)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (matrixAxisValues.isNotEmpty) {
      payload['MatrixAxisValue'] =
          matrixAxisValues.map((e) => e.toSyncDto()).toList();
    }

    final matrixCells = lastSync == null
        ? await _db.select(_db.matrixCells).get()
        : await (_db.select(_db.matrixCells)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (matrixCells.isNotEmpty) {
      payload['MatrixCell'] =
          matrixCells.map((e) => e.toSyncDto()).toList();
    }

    final matrixAttempts = lastSync == null
        ? await _db.select(_db.matrixAttempts).get()
        : await (_db.select(_db.matrixAttempts)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (matrixAttempts.isNotEmpty) {
      payload['MatrixAttempt'] =
          matrixAttempts.map((e) => e.toSyncDto()).toList();
    }

    final perfSnapshots = lastSync == null
        ? await _db.select(_db.performanceSnapshots).get()
        : await (_db.select(_db.performanceSnapshots)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (perfSnapshots.isNotEmpty) {
      payload['PerformanceSnapshot'] =
          perfSnapshots.map((e) => e.toSyncDto()).toList();
    }

    final snapClubs = lastSync == null
        ? await _db.select(_db.snapshotClubs).get()
        : await (_db.select(_db.snapshotClubs)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (snapClubs.isNotEmpty) {
      payload['SnapshotClub'] =
          snapClubs.map((e) => e.toSyncDto()).toList();
    }

    return payload;
  }

  /// TD-03 §5 — Phase 7B: LWW merge with gate enforcement and post-merge rebuild.
  Future<int> _applyDownloadedChanges(Map changes) async {
    final mergeStart = DateTime.now();

    // 1. Acquire SyncWriteGate.
    final gateAcquired = _gate.acquireExclusive();
    if (!gateAcquired) {
      throw SyncException(
        code: SyncException.gateTimeout,
        message: 'SyncWriteGate already held during merge',
      );
    }

    try {
      var mergedCount = 0;
      final affectedUserIds = <String>{};
      var tablesAffected = 0;
      // Track standard drills whose anchors changed during merge.
      final standardDrillsWithAnchorChanges = <String>{};

      // 2. For each table in upload order (parent before child):
      for (final tableName in tableUploadOrder) {
        final remoteRows = changes[tableName] as List?;
        if (remoteRows == null || remoteRows.isEmpty) continue;
        tablesAffected++;

        for (final remoteRow in remoteRows) {
          final remote = Map<String, dynamic>.from(remoteRow as Map);

          if (MergeAlgorithm.appendOnlyTables.contains(tableName)) {
            // EventLog: insert if not exists.
            await _insertIfMissing(tableName, remote);
          } else {
            // Fetch local row by PK, apply merge.
            final local = await _fetchLocalRow(tableName, remote);

            // Detect anchor changes on standard drills before merge.
            if (tableName == 'Drill' && local != null) {
              final origin = remote['Origin'] as String?;
              if (origin == 'System') {
                final oldAnchors = local['Anchors'];
                final newAnchors = remote['Anchors'];
                final oldStr = oldAnchors is String
                    ? oldAnchors
                    : jsonEncode(oldAnchors);
                final newStr = newAnchors is String
                    ? newAnchors
                    : jsonEncode(newAnchors);
                if (oldStr != newStr) {
                  final drillId = remote['DrillID'] as String;
                  standardDrillsWithAnchorChanges.add(drillId);
                }
              }
            }

            final merged = local == null
                ? remote
                : MergeAlgorithm.slotMergeTables.contains(tableName)
                    ? MergeAlgorithm.mergeCalendarDay(local, remote)
                    : MergeAlgorithm.mergeRow(local, remote);
            await _upsertMergedRow(tableName, merged);
          }
          mergedCount++;

          // Track affected users for post-merge rebuild.
          final userId = (remote['UserID'] ?? remote['userId']) as String?;
          if (userId != null) affectedUserIds.add(userId);
        }
      }

      // Flag adopted standard drills with anchor changes as hasUnseenUpdate.
      if (standardDrillsWithAnchorChanges.isNotEmpty) {
        for (final drillId in standardDrillsWithAnchorChanges) {
          await (_db.update(_db.userDrillAdoptions)
                ..where((t) =>
                    t.drillId.equals(drillId) &
                    t.isDeleted.equals(false)))
              .write(UserDrillAdoptionsCompanion(
            hasUnseenUpdate: const Value(true),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }

      // 3. Post-merge pipeline: full rebuild for each affected user.
      // Rebuild also covers standard drill anchor changes (reflow via full rebuild).
      final rebuildTriggered = affectedUserIds.isNotEmpty &&
          _reflowEngine != null;
      if (rebuildTriggered) {
        for (final userId in affectedUserIds) {
          await _reflowEngine.executeFullRebuildInternal(userId);
        }
      }

      // Phase 7C — Dual active session detection.
      // Local enforcement prevents this device from having 2 open blocks.
      // Multiple open blocks = remote device has an active session.
      final openBlocks = await (_db.select(_db.practiceBlocks)
            ..where(
                (t) => t.endTimestamp.isNull() & t.isDeleted.equals(false)))
          .get();
      if (openBlocks.length > 1) {
        _dualActiveSessionController.add(openBlocks.last.practiceBlockId);
      }

      final mergeDuration = DateTime.now().difference(mergeStart);
      _diagnostics?.emitMergeSummary(
        totalDuration: mergeDuration,
        mergedCount: mergedCount,
        tablesAffected: tablesAffected,
        affectedUsers: affectedUserIds.length,
        rebuildTriggered: rebuildTriggered,
      );

      return mergedCount;
    } finally {
      _gate.release();
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 7B — Merge helper methods
  // ---------------------------------------------------------------------------

  /// Primary key column name(s) for each table.
  static const _tablePrimaryKeys = <String, String>{
    'User': 'userId',
    'Drill': 'drillId',
    'PracticeBlock': 'practiceBlockId',
    'Session': 'sessionId',
    'Set': 'setId',
    'Instance': 'instanceId',
    'PracticeEntry': 'practiceEntryId',
    'UserDrillAdoption': 'userDrillAdoptionId',
    'UserClub': 'clubId',
    'UserTrainingItem': 'itemId',
    'ClubPerformanceProfile': 'profileId',
    'UserSkillAreaClubMapping': 'mappingId',
    'Routine': 'routineId',
    'Schedule': 'scheduleId',
    'CalendarDay': 'calendarDayId',
    'RoutineInstance': 'routineInstanceId',
    'ScheduleInstance': 'scheduleInstanceId',
    'EventLog': 'eventLogId',
    'UserDevice': 'deviceId',
    // Phase M3 — Matrix tables.
    'MatrixRun': 'matrixRunId',
    'MatrixAxis': 'matrixAxisId',
    'MatrixAxisValue': 'axisValueId',
    'MatrixCell': 'matrixCellId',
    'MatrixAttempt': 'matrixAttemptId',
    'PerformanceSnapshot': 'snapshotId',
    'SnapshotClub': 'snapshotClubId',
  };

  /// DB table names (SQL) mapped from logical names.
  static const _tableDbNames = <String, String>{
    'User': 'User',
    'Drill': 'Drill',
    'PracticeBlock': 'PracticeBlock',
    'Session': 'Session',
    'Set': 'Sets',
    'Instance': 'Instance',
    'PracticeEntry': 'PracticeEntry',
    'UserDrillAdoption': 'UserDrillAdoption',
    'UserClub': 'UserClub',
    'UserTrainingItem': 'UserTrainingItem',
    'ClubPerformanceProfile': 'ClubPerformanceProfile',
    'UserSkillAreaClubMapping': 'UserSkillAreaClubMapping',
    'Routine': 'Routine',
    'Schedule': 'Schedule',
    'CalendarDay': 'CalendarDay',
    'RoutineInstance': 'RoutineInstance',
    'ScheduleInstance': 'ScheduleInstance',
    'EventLog': 'EventLog',
    'UserDevice': 'UserDevice',
    // Phase M3 — Matrix tables.
    'MatrixRun': 'MatrixRun',
    'MatrixAxis': 'MatrixAxis',
    'MatrixAxisValue': 'MatrixAxisValue',
    'MatrixCell': 'MatrixCell',
    'MatrixAttempt': 'MatrixAttempt',
    'PerformanceSnapshot': 'PerformanceSnapshot',
    'SnapshotClub': 'SnapshotClub',
  };

  /// DB primary key column names (SQL) mapped from logical names.
  static const _tableDbPrimaryKeys = <String, String>{
    'User': 'UserID',
    'Drill': 'DrillID',
    'PracticeBlock': 'PracticeBlockID',
    'Session': 'SessionID',
    'Set': 'SetID',
    'Instance': 'InstanceID',
    'PracticeEntry': 'PracticeEntryID',
    'UserDrillAdoption': 'UserDrillAdoptionID',
    'UserClub': 'ClubID',
    'UserTrainingItem': 'ItemID',
    'ClubPerformanceProfile': 'ProfileID',
    'UserSkillAreaClubMapping': 'MappingID',
    'Routine': 'RoutineID',
    'Schedule': 'ScheduleID',
    'CalendarDay': 'CalendarDayID',
    'RoutineInstance': 'RoutineInstanceID',
    'ScheduleInstance': 'ScheduleInstanceID',
    'EventLog': 'EventLogID',
    'UserDevice': 'DeviceID',
    // Phase M3 — Matrix tables.
    'MatrixRun': 'MatrixRunID',
    'MatrixAxis': 'MatrixAxisID',
    'MatrixAxisValue': 'AxisValueID',
    'MatrixCell': 'MatrixCellID',
    'MatrixAttempt': 'MatrixAttemptID',
    'PerformanceSnapshot': 'SnapshotID',
    'SnapshotClub': 'SnapshotClubID',
  };

  /// Fetch a local row by primary key, returning it as a Map (DTO format)
  /// or null if not found.
  Future<Map<String, dynamic>?> _fetchLocalRow(
    String tableName,
    Map<String, dynamic> remote,
  ) async {
    final pkField = _tablePrimaryKeys[tableName];
    final dbTable = _tableDbNames[tableName];
    final dbPk = _tableDbPrimaryKeys[tableName];
    if (pkField == null || dbTable == null || dbPk == null) return null;

    final pkValue = remote[pkField] as String?;
    if (pkValue == null) return null;

    final results = await _db.customSelect(
      'SELECT * FROM "$dbTable" WHERE "$dbPk" = ?',
      variables: [Variable.withString(pkValue)],
    ).get();

    if (results.isEmpty) return null;

    // Convert the DB row to DTO format using the existing toSyncDto extensions.
    return _dbRowToSyncDto(tableName, results.first);
  }

  /// Convert a Drift QueryRow to sync DTO Map format.
  Map<String, dynamic>? _dbRowToSyncDto(String tableName, QueryRow row) {
    // Use the typed table mapping to convert.
    switch (tableName) {
      case 'User':
        return _db.users.map(row.data).toSyncDto();
      case 'Drill':
        return _db.drills.map(row.data).toSyncDto();
      case 'PracticeBlock':
        return _db.practiceBlocks.map(row.data).toSyncDto();
      case 'Session':
        return _db.sessions.map(row.data).toSyncDto();
      case 'Set':
        return _db.sets.map(row.data).toSyncDto();
      case 'Instance':
        return _db.instances.map(row.data).toSyncDto();
      case 'PracticeEntry':
        return _db.practiceEntries.map(row.data).toSyncDto();
      case 'UserDrillAdoption':
        return _db.userDrillAdoptions.map(row.data).toSyncDto();
      case 'UserClub':
        return _db.userClubs.map(row.data).toSyncDto();
      case 'UserTrainingItem':
        return _db.userTrainingItems.map(row.data).toSyncDto();
      case 'ClubPerformanceProfile':
        return _db.clubPerformanceProfiles.map(row.data).toSyncDto();
      case 'UserSkillAreaClubMapping':
        return _db.userSkillAreaClubMappings.map(row.data).toSyncDto();
      case 'Routine':
        return _db.routines.map(row.data).toSyncDto();
      case 'Schedule':
        return _db.schedules.map(row.data).toSyncDto();
      case 'CalendarDay':
        return _db.calendarDays.map(row.data).toSyncDto();
      case 'RoutineInstance':
        return _db.routineInstances.map(row.data).toSyncDto();
      case 'ScheduleInstance':
        return _db.scheduleInstances.map(row.data).toSyncDto();
      case 'EventLog':
        return _db.eventLogs.map(row.data).toSyncDto();
      case 'UserDevice':
        return _db.userDevices.map(row.data).toSyncDto();
      // Phase M3 — Matrix tables.
      case 'MatrixRun':
        return _db.matrixRuns.map(row.data).toSyncDto();
      case 'MatrixAxis':
        return _db.matrixAxes.map(row.data).toSyncDto();
      case 'MatrixAxisValue':
        return _db.matrixAxisValues.map(row.data).toSyncDto();
      case 'MatrixCell':
        return _db.matrixCells.map(row.data).toSyncDto();
      case 'MatrixAttempt':
        return _db.matrixAttempts.map(row.data).toSyncDto();
      case 'PerformanceSnapshot':
        return _db.performanceSnapshots.map(row.data).toSyncDto();
      case 'SnapshotClub':
        return _db.snapshotClubs.map(row.data).toSyncDto();
      default:
        return null;
    }
  }

  /// Upsert merged row using existing DTO fromSyncDto functions.
  Future<void> _upsertMergedRow(
    String tableName,
    Map<String, dynamic> merged,
  ) async {
    switch (tableName) {
      case 'User':
        await _db.into(_db.users).insertOnConflictUpdate(
              userFromSyncDto(merged));
      case 'Drill':
        await _db.into(_db.drills).insertOnConflictUpdate(
              drillFromSyncDto(merged));
      case 'PracticeBlock':
        await _db.into(_db.practiceBlocks).insertOnConflictUpdate(
              practiceBlockFromSyncDto(merged));
      case 'Session':
        await _db.into(_db.sessions).insertOnConflictUpdate(
              sessionFromSyncDto(merged));
      case 'Set':
        await _db.into(_db.sets).insertOnConflictUpdate(
              practiceSetFromSyncDto(merged));
      case 'Instance':
        await _db.into(_db.instances).insertOnConflictUpdate(
              instanceFromSyncDto(merged));
      case 'PracticeEntry':
        await _db.into(_db.practiceEntries).insertOnConflictUpdate(
              practiceEntryFromSyncDto(merged));
      case 'UserDrillAdoption':
        await _db.into(_db.userDrillAdoptions).insertOnConflictUpdate(
              userDrillAdoptionFromSyncDto(merged));
      case 'UserClub':
        await _db.into(_db.userClubs).insertOnConflictUpdate(
              userClubFromSyncDto(merged));
      case 'UserTrainingItem':
        await _db.into(_db.userTrainingItems).insertOnConflictUpdate(
              userTrainingItemFromSyncDto(merged));
      case 'ClubPerformanceProfile':
        await _db.into(_db.clubPerformanceProfiles).insertOnConflictUpdate(
              clubPerformanceProfileFromSyncDto(merged));
      case 'UserSkillAreaClubMapping':
        await _db.into(_db.userSkillAreaClubMappings).insertOnConflictUpdate(
              userSkillAreaClubMappingFromSyncDto(merged));
      case 'Routine':
        await _db.into(_db.routines).insertOnConflictUpdate(
              routineFromSyncDto(merged));
      case 'Schedule':
        await _db.into(_db.schedules).insertOnConflictUpdate(
              scheduleFromSyncDto(merged));
      case 'CalendarDay':
        await _db.into(_db.calendarDays).insertOnConflictUpdate(
              calendarDayFromSyncDto(merged));
      case 'RoutineInstance':
        await _db.into(_db.routineInstances).insertOnConflictUpdate(
              routineInstanceFromSyncDto(merged));
      case 'ScheduleInstance':
        await _db.into(_db.scheduleInstances).insertOnConflictUpdate(
              scheduleInstanceFromSyncDto(merged));
      case 'UserDevice':
        await _db.into(_db.userDevices).insertOnConflictUpdate(
              userDeviceFromSyncDto(merged));
      // Phase M3 — Matrix tables.
      case 'MatrixRun':
        await _db.into(_db.matrixRuns).insertOnConflictUpdate(
              matrixRunFromSyncDto(merged));
      case 'MatrixAxis':
        await _db.into(_db.matrixAxes).insertOnConflictUpdate(
              matrixAxisFromSyncDto(merged));
      case 'MatrixAxisValue':
        await _db.into(_db.matrixAxisValues).insertOnConflictUpdate(
              matrixAxisValueFromSyncDto(merged));
      case 'MatrixCell':
        await _db.into(_db.matrixCells).insertOnConflictUpdate(
              matrixCellFromSyncDto(merged));
      case 'MatrixAttempt':
        await _db.into(_db.matrixAttempts).insertOnConflictUpdate(
              matrixAttemptFromSyncDto(merged));
      case 'PerformanceSnapshot':
        await _db.into(_db.performanceSnapshots).insertOnConflictUpdate(
              performanceSnapshotFromSyncDto(merged));
      case 'SnapshotClub':
        await _db.into(_db.snapshotClubs).insertOnConflictUpdate(
              snapshotClubFromSyncDto(merged));
    }
  }

  /// Insert if not exists (for append-only tables like EventLog).
  Future<void> _insertIfMissing(
    String tableName,
    Map<String, dynamic> row,
  ) async {
    final pkField = _tablePrimaryKeys[tableName];
    final dbTable = _tableDbNames[tableName];
    final dbPk = _tableDbPrimaryKeys[tableName];
    if (pkField == null || dbTable == null || dbPk == null) return;

    final pkValue = row[pkField] as String?;
    if (pkValue == null) return;

    // Check existence first to avoid overwriting.
    final existing = await _db.customSelect(
      'SELECT 1 FROM "$dbTable" WHERE "$dbPk" = ? LIMIT 1',
      variables: [Variable.withString(pkValue)],
    ).get();

    if (existing.isEmpty) {
      // Insert the row using the appropriate fromSyncDto.
      switch (tableName) {
        case 'EventLog':
          await _db.into(_db.eventLogs).insert(
                eventLogFromSyncDto(row));
      }
    }
  }

  /// TD-07 §6.1 — Exponential backoff retry with jitter.
  Future<dynamic> _callWithRetry(Future<dynamic> Function() rpcCall) async {
    final random = Random();
    for (var attempt = 0; attempt <= kSyncRetryDelays.length; attempt++) {
      try {
        return await rpcCall();
      } catch (e) {
        if (attempt >= kSyncRetryDelays.length) rethrow;

        final delay = kSyncRetryDelays[attempt];
        final jitterMs =
            random.nextInt(kSyncRetryJitter.inMilliseconds * 2) -
                kSyncRetryJitter.inMilliseconds;
        final totalDelay = delay + Duration(milliseconds: jitterMs);

        debugPrint('[SyncEngine] Retry attempt ${attempt + 1} '
            'after ${totalDelay.inMilliseconds}ms');
        await Future.delayed(totalDelay);
      }
    }
    throw StateError('Unreachable');
  }

  /// Read or create a device ID in SyncMetadata.
  Future<String> _getOrCreateDeviceId() async {
    final row = await (_db.select(_db.syncMetadataEntries)
          ..where((t) => t.key.equals(SyncMetadataKeys.deviceId)))
        .getSingleOrNull();
    if (row != null) return row.value;

    final deviceId = const Uuid().v4();
    await _db.into(_db.syncMetadataEntries).insert(
          SyncMetadataEntriesCompanion.insert(
            key: SyncMetadataKeys.deviceId,
            value: deviceId,
          ),
        );
    return deviceId;
  }

  /// Update the lastSyncTimestamp in SyncMetadata.
  Future<void> _updateLastSyncTimestamp(DateTime timestamp) async {
    await _db.into(_db.syncMetadataEntries).insertOnConflictUpdate(
          SyncMetadataEntriesCompanion.insert(
            key: SyncMetadataKeys.lastSyncTimestamp,
            value: timestamp.toUtc().toIso8601String(),
          ),
        );
  }

  void _setStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Clean up resources.
  void dispose() {
    _statusController.close();
    _dualActiveSessionController.close();
  }
}
