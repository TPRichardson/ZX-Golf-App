// Phase 7C — Pure banner priority resolution. TD-07 §6/§9/§12.
// No Flutter imports — testable as pure Dart.

import 'package:zx_golf_app/core/constants.dart';

/// TD-07 §6.2 — Banner type with descending priority.
enum SyncBannerType {
  autoDisabled, // Priority 1: >=5 failures, sync auto-disabled
  schemaMismatch, // Priority 2: server schema mismatch
  escalation, // Priority 3: >=3 failures
  mergeTimeout, // Priority 4: >=3 consecutive timeouts
  authRequired, // Priority 5: re-auth needed
  syncDisabled, // Priority 6: manually disabled (failures=0)
  offline, // Priority 7: no connectivity
  syncInProgress, // Priority 8: sync running
  lowStorage, // Priority 9: device storage low
}

/// Resolved banner state for display.
class SyncBannerState {
  final SyncBannerType type;
  final String message;
  final String? actionLabel;

  const SyncBannerState({
    required this.type,
    required this.message,
    this.actionLabel,
  });
}

/// Input parameters for banner resolution.
class SyncBannerInput {
  final bool syncEnabled;
  final int consecutiveFailures;
  final int consecutiveMergeTimeouts;
  final bool schemaMismatchDetected;
  final bool isAuthenticated;
  final bool isConnected;
  final bool isSyncing;
  final bool isStorageLow;

  const SyncBannerInput({
    required this.syncEnabled,
    required this.consecutiveFailures,
    required this.consecutiveMergeTimeouts,
    required this.schemaMismatchDetected,
    required this.isAuthenticated,
    required this.isConnected,
    required this.isSyncing,
    required this.isStorageLow,
  });
}

/// TD-07 §6.2/§6.4/§9 — Resolve highest-priority banner or null if all clear.
SyncBannerState? resolveBannerState(SyncBannerInput input) {
  // Priority 1: Auto-disabled (>=5 failures).
  if (!input.syncEnabled &&
      input.consecutiveFailures >= kSyncMaxConsecutiveFailures) {
    return const SyncBannerState(
      type: SyncBannerType.autoDisabled,
      message:
          'Sync has been temporarily disabled due to repeated errors. Your data is safe. Please update the app or contact support.',
    );
  }

  // Priority 2: Schema mismatch.
  if (input.schemaMismatchDetected) {
    return const SyncBannerState(
      type: SyncBannerType.schemaMismatch,
      message:
          'An app update is required to sync your data across devices. All your data is safe locally.',
    );
  }

  // Priority 3: Escalation (>=3 failures, but not yet auto-disabled).
  if (input.consecutiveFailures >= kSyncEscalationThreshold) {
    return const SyncBannerState(
      type: SyncBannerType.escalation,
      message:
          'Sync is experiencing repeated issues. Your data is safe locally. Please check for app updates.',
    );
  }

  // Priority 4: Merge timeout (>=3 consecutive timeouts).
  if (input.consecutiveMergeTimeouts >= kSyncMergeTimeoutThreshold) {
    return const SyncBannerState(
      type: SyncBannerType.mergeTimeout,
      message:
          'Sync is taking longer than expected. This may resolve as data volumes stabilise.',
    );
  }

  // Priority 5: Auth required.
  if (!input.isAuthenticated && input.syncEnabled) {
    return const SyncBannerState(
      type: SyncBannerType.authRequired,
      message:
          'Please sign in again to sync your data across devices. All your local data is safe.',
      actionLabel: 'Sign In',
    );
  }

  // Priority 6: Manually disabled (failures=0).
  if (!input.syncEnabled && input.consecutiveFailures == 0) {
    return const SyncBannerState(
      type: SyncBannerType.syncDisabled,
      message: 'Sync is disabled. Data is not shared across devices.',
    );
  }

  // Priority 7: Offline.
  if (!input.isConnected) {
    return const SyncBannerState(
      type: SyncBannerType.offline,
      message: 'Offline. Changes are saved locally.',
    );
  }

  // Priority 8: Sync in progress.
  if (input.isSyncing) {
    return const SyncBannerState(
      type: SyncBannerType.syncInProgress,
      message: 'Syncing...',
    );
  }

  // Priority 9: Low storage.
  if (input.isStorageLow) {
    return const SyncBannerState(
      type: SyncBannerType.lowStorage,
      message:
          'Device storage is low. Free up space to ensure data can be saved.',
    );
  }

  // All clear — no banner.
  return null;
}
