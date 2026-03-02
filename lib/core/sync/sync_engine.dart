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
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/dto/sync_dto.dart';
import 'sync_types.dart';
import 'sync_write_gate.dart';

// TD-03 §5.1 — Sync engine. Orchestrates upload/download cycles.
// Phase 2.5: basic upload/download with stub merge (insert-only).
// Phase 7A: batching, diagnostics, failure tracking, feature flag.
// Full LWW merge deferred to Phase 7B.

class SyncEngine {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  // Phase 7B — gate checked before repository writes during sync merge.
  // ignore: unused_field
  final SyncWriteGate _gate;
  final SyncInstrumentation? _diagnostics;

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

  /// TD-07 §6.2 — Current consecutive failure count.
  int get consecutiveFailures => _consecutiveFailures;

  /// TD-03 §5.1 — Whether sync is enabled.
  bool get syncEnabled => _syncEnabled;

  SyncEngine(this._supabase, this._db, this._gate, [this._diagnostics]);

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
    } catch (e) {
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
      final lastSync = reason == SyncTrigger.forceFullSync
          ? null
          : await getLastSyncTimestamp();

      // Step 1: Gather local changes and device ID
      final payload = await _buildUploadPayload(lastSync);
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
          final errorCode = lastUploadResponse['error_code'] as String?;
          if (errorCode == 'SCHEMA_VERSION_MISMATCH') {
            _setStatus(SyncStatus.failed);
            throw SyncException(
              code: SyncException.schemaMismatch,
              message: 'Server requires different schema version',
            );
          }
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

      // Step 4: Stub merge — insert-only (Phase 7B: full LWW)
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
      await _persistConsecutiveFailures();

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
    } on SyncException {
      await _incrementFailureCounter();
      _setStatus(SyncStatus.failed);

      final totalDuration = DateTime.now().difference(cycleStart);
      _diagnostics?.emitCycleSummary(
        trigger: reason,
        totalDuration: totalDuration,
        success: false,
        consecutiveFailures: _consecutiveFailures,
        errorCode: 'SyncException',
      );

      rethrow;
    } catch (e) {
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

    // Drill
    final drills = lastSync == null
        ? await _db.select(_db.drills).get()
        : await (_db.select(_db.drills)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (drills.isNotEmpty) {
      payload['Drill'] = drills.map((e) => e.toSyncDto()).toList();
    }

    // PracticeBlock
    final blocks = lastSync == null
        ? await _db.select(_db.practiceBlocks).get()
        : await (_db.select(_db.practiceBlocks)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (blocks.isNotEmpty) {
      payload['PracticeBlock'] = blocks.map((e) => e.toSyncDto()).toList();
    }

    // Session
    final sessions = lastSync == null
        ? await _db.select(_db.sessions).get()
        : await (_db.select(_db.sessions)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (sessions.isNotEmpty) {
      payload['Session'] = sessions.map((e) => e.toSyncDto()).toList();
    }

    // Set
    final sets = lastSync == null
        ? await _db.select(_db.sets).get()
        : await (_db.select(_db.sets)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (sets.isNotEmpty) {
      payload['Set'] = sets.map((e) => e.toSyncDto()).toList();
    }

    // Instance
    final instances = lastSync == null
        ? await _db.select(_db.instances).get()
        : await (_db.select(_db.instances)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
    if (instances.isNotEmpty) {
      payload['Instance'] = instances.map((e) => e.toSyncDto()).toList();
    }

    // PracticeEntry
    final entries = lastSync == null
        ? await _db.select(_db.practiceEntries).get()
        : await (_db.select(_db.practiceEntries)
              ..where((t) => t.updatedAt.isBiggerThanValue(lastSync)))
            .get();
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

    return payload;
  }

  /// Phase 2.5 stub merge: insertOrIgnore for downloaded rows.
  /// Phase 7B: full LWW merge.
  Future<int> _applyDownloadedChanges(Map changes) async {
    var count = 0;

    Future<void> insertTable<T extends Table, D>(
      TableInfo<T, D> table,
      List? rows,
      Insertable<D> Function(Map<String, dynamic>) fromDto,
    ) async {
      if (rows == null || rows.isEmpty) return;
      for (final row in rows) {
        await _db.into(table).insertOnConflictUpdate(
              fromDto(Map<String, dynamic>.from(row as Map)),
            );
        count++;
      }
    }

    // Phase 2.5 stub — insert each table from download response.
    await insertTable(_db.users, changes['User'] as List?,
        userFromSyncDto);
    await insertTable(_db.drills, changes['Drill'] as List?,
        drillFromSyncDto);
    await insertTable(_db.practiceBlocks,
        changes['PracticeBlock'] as List?, practiceBlockFromSyncDto);
    await insertTable(_db.sessions, changes['Session'] as List?,
        sessionFromSyncDto);
    await insertTable(
        _db.sets, changes['Set'] as List?, practiceSetFromSyncDto);
    await insertTable(_db.instances, changes['Instance'] as List?,
        instanceFromSyncDto);
    await insertTable(_db.practiceEntries,
        changes['PracticeEntry'] as List?, practiceEntryFromSyncDto);
    await insertTable(_db.userDrillAdoptions,
        changes['UserDrillAdoption'] as List?, userDrillAdoptionFromSyncDto);
    await insertTable(_db.userClubs, changes['UserClub'] as List?,
        userClubFromSyncDto);
    await insertTable(
        _db.clubPerformanceProfiles,
        changes['ClubPerformanceProfile'] as List?,
        clubPerformanceProfileFromSyncDto);
    await insertTable(
        _db.userSkillAreaClubMappings,
        changes['UserSkillAreaClubMapping'] as List?,
        userSkillAreaClubMappingFromSyncDto);
    await insertTable(_db.routines, changes['Routine'] as List?,
        routineFromSyncDto);
    await insertTable(_db.schedules, changes['Schedule'] as List?,
        scheduleFromSyncDto);
    await insertTable(_db.calendarDays,
        changes['CalendarDay'] as List?, calendarDayFromSyncDto);
    await insertTable(_db.routineInstances,
        changes['RoutineInstance'] as List?, routineInstanceFromSyncDto);
    await insertTable(_db.scheduleInstances,
        changes['ScheduleInstance'] as List?, scheduleInstanceFromSyncDto);
    await insertTable(_db.eventLogs, changes['EventLog'] as List?,
        eventLogFromSyncDto);
    await insertTable(_db.userDevices,
        changes['UserDevice'] as List?, userDeviceFromSyncDto);

    return count;
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
  }
}
