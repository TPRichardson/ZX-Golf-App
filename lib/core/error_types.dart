// TD-07 §2 — Error type hierarchy.
// All application errors extend ZxGolfAppException.

class ZxGolfAppException implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? context;

  const ZxGolfAppException({
    required this.code,
    required this.message,
    this.context,
  });

  @override
  String toString() => 'ZxGolfAppException($code): $message';
}

// TD-07 §2.2 — Validation errors (VALIDATION_* prefix).
class ValidationException extends ZxGolfAppException {
  const ValidationException({
    required super.code,
    required super.message,
    super.context,
  });

  // TD-07 §2.3 — Exception codes.
  static const invalidAnchors = 'VALIDATION_INVALID_ANCHORS';
  static const invalidStructure = 'VALIDATION_INVALID_STRUCTURE';
  static const requiredField = 'VALIDATION_REQUIRED_FIELD';
  static const stateTransition = 'VALIDATION_STATE_TRANSITION';
  static const duplicateEntry = 'VALIDATION_DUPLICATE_ENTRY';
  static const singleActiveSession = 'VALIDATION_SINGLE_ACTIVE_SESSION';
}

// TD-07 §2.2 — Scoring pipeline failures (REFLOW_* prefix).
class ReflowException extends ZxGolfAppException {
  const ReflowException({
    required super.code,
    required super.message,
    super.context,
  });

  static const lockTimeout = 'REFLOW_LOCK_TIMEOUT';
  static const transactionFailed = 'REFLOW_TRANSACTION_FAILED';
  static const rebuildTimeout = 'REFLOW_REBUILD_TIMEOUT';
}

// TD-07 §2.2 — Sync transport/merge failures (SYNC_* prefix).
class SyncException extends ZxGolfAppException {
  const SyncException({
    required super.code,
    required super.message,
    super.context,
  });

  static const uploadFailed = 'SYNC_UPLOAD_FAILED';
  static const downloadFailed = 'SYNC_DOWNLOAD_FAILED';
  static const mergeFailed = 'SYNC_MERGE_FAILED';
  static const mergeTimeout = 'SYNC_MERGE_TIMEOUT';
  static const schemaMismatch = 'SYNC_SCHEMA_MISMATCH';
  static const payloadTooLarge = 'SYNC_PAYLOAD_TOO_LARGE';
  static const networkUnavailable = 'SYNC_NETWORK_UNAVAILABLE';
  static const gateTimeout = 'SYNC_GATE_TIMEOUT';
}

// TD-07 §2.2 — Infrastructure failures (SYSTEM_* prefix).
class SystemException extends ZxGolfAppException {
  const SystemException({
    required super.code,
    required super.message,
    super.context,
  });

  static const databaseCorrupt = 'SYSTEM_DATABASE_CORRUPT';
  static const storageFull = 'SYSTEM_STORAGE_FULL';
  static const outOfMemory = 'SYSTEM_OUT_OF_MEMORY';
  static const migrationFailed = 'SYSTEM_MIGRATION_FAILED';
  static const referentialIntegrity = 'SYSTEM_REFERENTIAL_INTEGRITY';
}

// TD-07 §2.2 — Cross-device conflicts (CONFLICT_* prefix).
class ConflictException extends ZxGolfAppException {
  const ConflictException({
    required super.code,
    required super.message,
    super.context,
  });

  static const dualActiveSession = 'CONFLICT_DUAL_ACTIVE_SESSION';
  static const structuralDivergence = 'CONFLICT_STRUCTURAL_DIVERGENCE';
  static const slotCollision = 'CONFLICT_SLOT_COLLISION';
}

// TD-07 §2.2 — Auth failures (AUTH_* prefix).
class AuthenticationException extends ZxGolfAppException {
  const AuthenticationException({
    required super.code,
    required super.message,
    super.context,
  });

  static const tokenExpired = 'AUTH_TOKEN_EXPIRED';
  static const refreshFailed = 'AUTH_REFRESH_FAILED';
  static const sessionRevoked = 'AUTH_SESSION_REVOKED';
}
