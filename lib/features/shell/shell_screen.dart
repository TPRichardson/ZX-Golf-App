import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/settings/settings_screen.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'tabs/plan_tab.dart';
import 'tabs/track_tab.dart';
import 'tabs/review_tab.dart';
import 'widgets/dual_active_session_dialog.dart';
import 'widgets/sync_status_banner.dart';

// TD-06 §4.3 — Shell app with bottom navigation: Plan, Track, Review.

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 1; // Start on Track tab

  static const _tabs = [
    PlanTab(),
    TrackTab(),
    ReviewTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Phase 7A — Start sync orchestrator on app launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOrchestratorProvider).start();
    });
  }

  @override
  void dispose() {
    // Phase 7A — Stop sync orchestrator on shell dispose.
    ref.read(syncOrchestratorProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Phase 7C — Listen for dual active session conflicts.
    ref.listen<AsyncValue<String>>(dualActiveSessionProvider, (_, next) {
      next.whenData((blockId) {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                DualActiveSessionDialog(conflictingBlockId: blockId),
          );
        }
      });
    });

    // Fix 10 — Hide bottom navigation during live practice.
    final activePb = ref.watch(activePracticeBlockProvider(kDevUserId));
    final hasActivePractice = activePb.valueOrNull != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZX Golf'),
        backgroundColor: ColorTokens.surfacePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: ColorTokens.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(child: _tabs[_currentIndex]),
        ],
      ),
      bottomNavigationBar: hasActivePractice
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Plan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_golf),
                  label: 'Track',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  label: 'Review',
                ),
              ],
              backgroundColor: ColorTokens.surfacePrimary,
              selectedItemColor: ColorTokens.primaryDefault,
              unselectedItemColor: ColorTokens.textSecondary,
            ),
    );
  }
}
