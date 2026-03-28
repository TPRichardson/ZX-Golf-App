import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';

/// Shown once after a fresh login while the first sync completes.
/// Ensures the user sees their data before landing on the main app.
class PostLoginSyncScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const PostLoginSyncScreen({super.key, required this.onComplete});

  @override
  ConsumerState<PostLoginSyncScreen> createState() =>
      _PostLoginSyncScreenState();
}

class _PostLoginSyncScreenState extends ConsumerState<PostLoginSyncScreen> {
  static const _timeout = Duration(seconds: 15);
  Timer? _timeoutTimer;
  StreamSubscription<SyncStatus>? _statusSub;
  String _statusMessage = 'Preparing...';
  bool _syncStarted = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(_timeout, _finish);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  Future<void> _startSync() async {
    // Provision user record (same as ShellScreen — idempotent).
    await _ensureUserProvisioned();
    if (!mounted) return;

    setState(() => _statusMessage = 'Connecting...');

    // Listen for status changes before starting the orchestrator.
    _listenForSync();

    // Start sync orchestrator (idempotent — ShellScreen will call again harmlessly).
    ref.read(syncOrchestratorProvider).start();
  }

  Future<void> _ensureUserProvisioned() async {
    final authService = ref.read(authServiceProvider);
    final userId = authService.currentUserId;
    if (userId == null) return;
    final userRepo = ref.read(userRepositoryProvider);
    final existing = await userRepo.getById(userId);
    if (existing == null) {
      final profile = ref.read(authProfileProvider);
      await userRepo.create(UsersCompanion.insert(
        userId: userId,
        email: profile.email ?? '$userId@unknown.local',
        displayName: drift.Value(profile.displayName),
      ));
    }
    try {
      await ref.read(drillRepositoryProvider).autoAdoptAllSystemDrills(userId);
    } catch (e) {
      debugPrint('[PostLoginSync] Auto-adopt failed: $e');
    }
  }

  void _listenForSync() {
    final engine = ref.read(syncEngineProvider);
    _statusSub = engine.getSyncStatus().listen((status) {
      if (!mounted || _finished) return;
      switch (status) {
        case SyncStatus.inProgress:
          _syncStarted = true;
          setState(() => _statusMessage = 'Syncing your data...');
        case SyncStatus.idle:
          if (_syncStarted) {
            setState(() => _statusMessage = 'Done!');
            // Brief pause so user sees "Done!" before transition.
            Future.delayed(const Duration(milliseconds: 400), _finish);
          }
        case SyncStatus.failed:
          if (_syncStarted) _finish();
        case SyncStatus.offline:
          _finish();
      }
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timeoutTimer?.cancel();
    _statusSub?.cancel();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ZX Golf',
                style: TextStyle(
                  color: ColorTokens.textPrimary,
                  fontSize: TypographyTokens.displayXlSize,
                  fontWeight: TypographyTokens.displayXlWeight,
                  height: TypographyTokens.displayXlHeight,
                ),
              ),
              const SizedBox(height: SpacingTokens.xxl),
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ColorTokens.primaryDefault,
                ),
              ),
              const SizedBox(height: SpacingTokens.lg),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: TypographyTokens.bodyLgSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
