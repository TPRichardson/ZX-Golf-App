// TD-03 §5.1 — Sync types for sync engine communication.

/// TD-03 §5.1 — Current state of the sync engine.
enum SyncStatus {
  idle,
  inProgress,
  failed,
  offline,
}

/// TD-03 §5.1 — What triggered a sync cycle.
enum SyncTrigger {
  manual,
  connectivity,
  periodic,
  postSession,
  forceFullSync,
}

/// TD-03 §5.1 — Sync feature flag keys stored in SyncMetadata.
class SyncMetadataKeys {
  static const deviceId = 'deviceId';
  static const lastSyncTimestamp = 'lastSyncTimestamp';
  static const consecutiveFailures = 'consecutiveFailures';
  static const syncEnabled = 'syncEnabled';
  static const schemaMismatchDetected = 'schemaMismatchDetected';
  // TD-07 §13.6 — Set 'true' before materialised state modification, cleared after.
  static const rebuildNeeded = 'rebuildNeeded';
}

/// TD-03 §5.1 — Result of a sync cycle.
class SyncResult {
  final bool success;
  final DateTime? serverTimestamp;
  final int uploadedCount;
  final int downloadedCount;
  final String? errorCode;
  final String? errorMessage;
  final List<Map<String, dynamic>> rejectedRows;

  const SyncResult._({
    required this.success,
    this.serverTimestamp,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.errorCode,
    this.errorMessage,
    this.rejectedRows = const [],
  });

  /// Successful sync cycle.
  const SyncResult.success({
    required DateTime serverTimestamp,
    int uploadedCount = 0,
    int downloadedCount = 0,
    List<Map<String, dynamic>> rejectedRows = const [],
  }) : this._(
          success: true,
          serverTimestamp: serverTimestamp,
          uploadedCount: uploadedCount,
          downloadedCount: downloadedCount,
          rejectedRows: rejectedRows,
        );

  /// Failed sync cycle.
  const SyncResult.failure({
    required String errorCode,
    required String errorMessage,
  }) : this._(
          success: false,
          errorCode: errorCode,
          errorMessage: errorMessage,
        );
}
