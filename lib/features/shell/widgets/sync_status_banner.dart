import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'sync_banner_state.dart';

// Phase 7C — Composite sync status banner. TD-07 §6/§9/§12, S15.

/// One-time dialog guard per app session. TD-07 §6.4.
final schemaMismatchDialogShownProvider = StateProvider<bool>((ref) => false);

/// Sync status banner displayed at top of shell.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncEnabled = ref.watch(syncEnabledProvider);
    final failureCount = ref.watch(syncFailureCountProvider);
    final mergeTimeouts = ref.watch(consecutiveMergeTimeoutsProvider);
    final schemaMismatch = ref.watch(schemaMismatchDetectedProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final storageLow = ref.watch(isStorageLowProvider);
    final authState = ref.watch(authStateProvider);

    final isSyncing = syncStatus.whenOrNull(data: (s) => s) ==
        SyncStatus.inProgress;
    final isConnected = connectivity.whenOrNull(data: (c) => c) ?? true;
    final isStorageLow = storageLow.whenOrNull(data: (s) => s) ?? false;
    final isAuthenticated =
        authState.whenOrNull(data: (a) => a.session != null) ?? true;

    final input = SyncBannerInput(
      syncEnabled: syncEnabled,
      consecutiveFailures: failureCount,
      consecutiveMergeTimeouts: mergeTimeouts,
      schemaMismatchDetected: schemaMismatch,
      isAuthenticated: isAuthenticated,
      isConnected: isConnected,
      isSyncing: isSyncing,
      isStorageLow: isStorageLow,
    );

    final bannerState = resolveBannerState(input);

    // TD-07 §6.4 — One-time schema mismatch dialog per app session.
    if (schemaMismatch) {
      final dialogShown = ref.read(schemaMismatchDialogShownProvider);
      if (!dialogShown) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ref.read(schemaMismatchDialogShownProvider.notifier).state = true;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                backgroundColor: ColorTokens.surfaceModal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
                ),
                title: const Text(
                  'App Update Required',
                  style: TextStyle(
                    color: ColorTokens.textPrimary,
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: TypographyTokens.headerWeight,
                  ),
                ),
                content: const Text(
                  'An app update is required to sync your data across devices. All your data is safe locally.',
                  style: TextStyle(
                    color: ColorTokens.textSecondary,
                    fontSize: TypographyTokens.bodySize,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
      }
    }

    if (bannerState == null) return const SizedBox.shrink();

    return AnimatedSize(
      duration: MotionTokens.standard,
      curve: MotionTokens.curve,
      child: _BannerContent(state: bannerState, ref: ref),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final SyncBannerState state;
  final WidgetRef ref;

  const _BannerContent({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor(state.type);
    final icon = _icon(state.type);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.sm,
        horizontal: SpacingTokens.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: Text(
                  state.message,
                  style: const TextStyle(
                    color: ColorTokens.textPrimary,
                    fontSize: TypographyTokens.bodySize,
                  ),
                ),
              ),
              if (state.actionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: SpacingTokens.sm),
                  child: TextButton(
                    onPressed: () => _onAction(context),
                    style: TextButton.styleFrom(
                      foregroundColor: ColorTokens.primaryDefault,
                      padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm,
                      ),
                    ),
                    child: Text(state.actionLabel!),
                  ),
                ),
            ],
          ),
          if (state.type == SyncBannerType.syncInProgress)
            Padding(
              padding: const EdgeInsets.only(top: SpacingTokens.xs),
              child: LinearProgressIndicator(
                backgroundColor: ColorTokens.surfacePrimary,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ColorTokens.primaryDefault,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _accentColor(SyncBannerType type) {
    switch (type) {
      case SyncBannerType.autoDisabled:
      case SyncBannerType.schemaMismatch:
      case SyncBannerType.escalation:
        return ColorTokens.errorDestructive;
      case SyncBannerType.mergeTimeout:
      case SyncBannerType.lowStorage:
        return ColorTokens.warningIntegrity;
      case SyncBannerType.authRequired:
      case SyncBannerType.syncDisabled:
      case SyncBannerType.syncInProgress:
        return ColorTokens.primaryDefault;
      case SyncBannerType.offline:
        return ColorTokens.textTertiary;
    }
  }

  IconData _icon(SyncBannerType type) {
    switch (type) {
      case SyncBannerType.autoDisabled:
      case SyncBannerType.escalation:
        return Icons.error_outline;
      case SyncBannerType.schemaMismatch:
        return Icons.system_update;
      case SyncBannerType.mergeTimeout:
        return Icons.hourglass_top;
      case SyncBannerType.authRequired:
        return Icons.lock_outline;
      case SyncBannerType.syncDisabled:
        return Icons.sync_disabled;
      case SyncBannerType.offline:
        return Icons.cloud_off;
      case SyncBannerType.syncInProgress:
        return Icons.sync;
      case SyncBannerType.lowStorage:
        return Icons.storage;
    }
  }

  void _onAction(BuildContext context) {
    if (state.type == SyncBannerType.authRequired) {
      // Phase 8 — Navigate to sign-in screen.
      // Stub: action handled by settings screen.
    }
  }
}
