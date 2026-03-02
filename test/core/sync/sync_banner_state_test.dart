import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/features/shell/widgets/sync_banner_state.dart';

// Phase 7C — Pure Dart tests of resolveBannerState().

/// All-clear baseline input.
const _allClear = SyncBannerInput(
  syncEnabled: true,
  consecutiveFailures: 0,
  consecutiveMergeTimeouts: 0,
  schemaMismatchDetected: false,
  isAuthenticated: true,
  isConnected: true,
  isSyncing: false,
  isStorageLow: false,
);

void main() {
  group('resolveBannerState', () {
    test('returns null when all clear', () {
      expect(resolveBannerState(_allClear), isNull);
    });

    // -----------------------------------------------------------------------
    // Priority 1: autoDisabled
    // -----------------------------------------------------------------------
    test('returns autoDisabled when sync disabled with >=5 failures', () {
      final input = SyncBannerInput(
        syncEnabled: false,
        consecutiveFailures: kSyncMaxConsecutiveFailures,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.autoDisabled);
      expect(result.actionLabel, isNull);
    });

    test('autoDisabled message matches TD-07', () {
      final input = SyncBannerInput(
        syncEnabled: false,
        consecutiveFailures: 5,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.message, contains('temporarily disabled'));
      expect(result.message, contains('update the app'));
    });

    // -----------------------------------------------------------------------
    // Priority 2: schemaMismatch
    // -----------------------------------------------------------------------
    test('returns schemaMismatch when flag is set', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: true,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.schemaMismatch);
      expect(result.message, contains('app update is required'));
    });

    // -----------------------------------------------------------------------
    // Priority 3: escalation
    // -----------------------------------------------------------------------
    test('returns escalation at 3 failures', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: kSyncEscalationThreshold,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.escalation);
      expect(result.message, contains('repeated issues'));
    });

    test('returns escalation at 4 failures', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 4,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.escalation);
    });

    // -----------------------------------------------------------------------
    // Priority 4: mergeTimeout
    // -----------------------------------------------------------------------
    test('returns mergeTimeout at 3 consecutive timeouts', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: kSyncMergeTimeoutThreshold,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.mergeTimeout);
      expect(result.message, contains('taking longer than expected'));
    });

    // -----------------------------------------------------------------------
    // Priority 5: authRequired
    // -----------------------------------------------------------------------
    test('returns authRequired when not authenticated', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: false,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.authRequired);
      expect(result.actionLabel, 'Sign In');
      expect(result.message, contains('sign in again'));
    });

    // -----------------------------------------------------------------------
    // Priority 6: syncDisabled (manual, failures=0)
    // -----------------------------------------------------------------------
    test('returns syncDisabled when manually disabled', () {
      final input = SyncBannerInput(
        syncEnabled: false,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.syncDisabled);
      expect(result.message, contains('Sync is disabled'));
    });

    // -----------------------------------------------------------------------
    // Priority 7: offline
    // -----------------------------------------------------------------------
    test('returns offline when not connected', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: false,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.offline);
      expect(result.message, contains('Offline'));
    });

    // -----------------------------------------------------------------------
    // Priority 8: syncInProgress
    // -----------------------------------------------------------------------
    test('returns syncInProgress when syncing', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: true,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.syncInProgress);
      expect(result.message, 'Syncing...');
    });

    // -----------------------------------------------------------------------
    // Priority 9: lowStorage
    // -----------------------------------------------------------------------
    test('returns lowStorage when storage is low', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: true,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.lowStorage);
      expect(result.message, contains('storage is low'));
    });

    // -----------------------------------------------------------------------
    // Priority ordering
    // -----------------------------------------------------------------------
    test('autoDisabled beats schemaMismatch', () {
      final input = SyncBannerInput(
        syncEnabled: false,
        consecutiveFailures: 5,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: true,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.autoDisabled);
    });

    test('schemaMismatch beats escalation', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 3,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: true,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.schemaMismatch);
    });

    test('escalation beats mergeTimeout', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 3,
        consecutiveMergeTimeouts: 5,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.escalation);
    });

    test('offline beats syncInProgress', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: false,
        isSyncing: true,
        isStorageLow: false,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.offline);
    });

    test('syncInProgress beats lowStorage', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: true,
        isStorageLow: true,
      );
      final result = resolveBannerState(input)!;
      expect(result.type, SyncBannerType.syncInProgress);
    });

    // -----------------------------------------------------------------------
    // Boundary conditions
    // -----------------------------------------------------------------------
    test('no banner at 2 failures (below escalation threshold)', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 2,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      expect(resolveBannerState(input), isNull);
    });

    test('no banner at 2 timeouts (below timeout threshold)', () {
      final input = SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 2,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
      expect(resolveBannerState(input), isNull);
    });

    test('action label only present for authRequired', () {
      // Verify no other type has an action label.
      for (final type in SyncBannerType.values) {
        final input = _inputForType(type);
        final result = resolveBannerState(input);
        if (result != null && result.type != SyncBannerType.authRequired) {
          expect(result.actionLabel, isNull,
              reason: '${result.type} should not have action label');
        }
      }
    });
  });
}

/// Helper: produce an input that triggers the given banner type.
SyncBannerInput _inputForType(SyncBannerType type) {
  switch (type) {
    case SyncBannerType.autoDisabled:
      return const SyncBannerInput(
        syncEnabled: false,
        consecutiveFailures: 5,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.schemaMismatch:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: true,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.escalation:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 3,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.mergeTimeout:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 3,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.authRequired:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: false,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.syncDisabled:
      return const SyncBannerInput(
        syncEnabled: false,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.offline:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: false,
        isSyncing: false,
        isStorageLow: false,
      );
    case SyncBannerType.syncInProgress:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: true,
        isStorageLow: false,
      );
    case SyncBannerType.lowStorage:
      return const SyncBannerInput(
        syncEnabled: true,
        consecutiveFailures: 0,
        consecutiveMergeTimeouts: 0,
        schemaMismatchDetected: false,
        isAuthenticated: true,
        isConnected: true,
        isSyncing: false,
        isStorageLow: true,
      );
  }
}
