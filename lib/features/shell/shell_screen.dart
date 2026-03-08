import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/features/home/home_dashboard_screen.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/core/widgets/golf_club_plus_icon.dart';
import 'package:zx_golf_app/features/bag/bag_screen.dart';
import 'package:zx_golf_app/features/settings/settings_screen.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'tabs/plan_tab.dart';
import 'tabs/track_tab.dart';
import 'tabs/review_tab.dart';
import 'widgets/dual_active_session_dialog.dart';
import 'widgets/sync_status_banner.dart';
import 'widgets/system_maintenance_banner.dart';

/// Whether the auth-required sync banner has been dismissed this session.
final authBannerDismissedProvider = StateProvider<bool>((ref) => false);

// TD-06 §4.3 — Shell app with bottom navigation: Plan, Track, Review.
// S12 §12.2 — Home Dashboard sits above tabs as persistent launch layer.

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 1; // Start on Track tab

  // Nested navigators for each tab — keeps shell AppBar + bottom nav visible.
  final _navigatorKeys = List.generate(3, (_) => GlobalKey<NavigatorState>());

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
      _checkDeferredSummary();
    });
  }

  // 6D — Check for deferred post-session summary after auto-end.
  Future<void> _checkDeferredSummary() async {
    final repo = ref.read(practiceRepositoryProvider);
    final pending = await repo.getPendingSummary();
    if (pending == null) return;

    await repo.clearPendingSummary();

    final blockId = pending['blockId'] as String?;
    if (blockId == null) return;

    // Look up sessions for this block.
    final sessions =
        await repo.watchSessionsByBlock(blockId).first;
    if (sessions.isEmpty) {
      // 0 Sessions — show passive snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your practice session ended with no completed drills.'),
          ),
        );
      }
      return;
    }

    // Show summary for the last completed session.
    final sessionId = pending['sessionId'] as String?;
    final targetSession = sessionId != null
        ? sessions.firstWhere((s) => s.sessionId == sessionId,
            orElse: () => sessions.last)
        : sessions.last;

    final drill = await ref
        .read(drillRepositoryProvider)
        .getById(targetSession.drillId);
    if (drill == null || !mounted) return;

    final score = pending['sessionScore'] as num?;
    final integrity = pending['integrityBreach'] as bool? ?? false;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostSessionSummaryScreen(
          drill: drill,
          session: targetSession,
          sessionScore: score?.toDouble(),
          integrityBreach: integrity,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Phase 7A — Stop sync orchestrator on shell dispose.
    ref.read(syncOrchestratorProvider).stop();
    super.dispose();
  }

  void _goHome() {
    ref.read(showHomeProvider.notifier).state = true;
  }

  void _goToTab(int index) {
    ref.read(showHomeProvider.notifier).state = false;
    // Always pop nested navigator to root when selecting a tab.
    _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  void _resumePractice(String practiceBlockId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeQueueScreen(
        practiceBlockId: practiceBlockId,
        userId: kDevUserId,
      ),
    ));
  }

  Future<void> _discardPracticeBlock(String practiceBlockId) async {
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Discard Practice?',
      message: 'This will end the current practice block and discard '
          'any in-progress session.',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final actions = ref.read(practiceActionsProvider);
    await actions.discardPracticeBlock(practiceBlockId, kDevUserId);
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

    // S12 §12.2 — showHomeProvider controls Home vs Tab display.
    final showHome = ref.watch(showHomeProvider);

    // Active practice block for persistent resume bar.
    final activePb = ref.watch(activePracticeBlockProvider(kDevUserId));
    final activePbData = activePb.valueOrNull;

    // Auth state for top-bar sign-in action.
    final bi = ref.watch(syncBannerInputProvider);
    final isAuthenticated = bi.isAuthenticated;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (showHome) return;
        final nav = _navigatorKeys[_currentIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else {
          _goHome();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: const SizedBox.shrink(),
        backgroundColor: ColorTokens.surfaceBase,
        leading: Padding(
          padding: const EdgeInsets.only(left: SpacingTokens.xs),
          child: IconButton(
            icon: Icon(
              Icons.home,
              size: 40,
              color: showHome
                  ? ColorTokens.primaryDefault
                  : ColorTokens.textSecondary,
            ),
            onPressed: _goHome,
          ),
        ),
        leadingWidth: 60,
        actions: [
          // Golf Bag button.
          IconButton(
            icon: GolfClubPlusIcon(
              size: 32,
              clubColor: ColorTokens.textSecondary,
              plusColor: ColorTokens.primaryDefault,
            ),
            tooltip: 'Golf Bag',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BagScreen()),
            ),
          ),
          // Sign In prompt when not authenticated.
          if (!isAuthenticated)
            TextButton(
              onPressed: () {
                // TODO: navigate to sign-in flow.
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorTokens.primaryDefault,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 19),
              ),
            ),
          // Account button — always visible.
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              size: 32,
              color: isAuthenticated
                  ? ColorTokens.textSecondary
                  : ColorTokens.textTertiary,
            ),
            tooltip: isAuthenticated ? 'Account' : 'Not signed in',
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
          // Gap 43 — Maintenance banner (trigger deferred to post-V1).
          const SystemMaintenanceBanner(),
          Expanded(
            child: showHome
                ? HomeDashboardScreen(onGoToTab: _goToTab)
                : IndexedStack(
                    index: _currentIndex,
                    children: [
                      for (int i = 0; i < _tabs.length; i++)
                        Navigator(
                          key: _navigatorKeys[i],
                          onGenerateRoute: (_) => MaterialPageRoute(
                            builder: (_) => _tabs[i],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Persistent resume bar when a practice block is active.
          if (activePbData != null)
            Container(
              color: ColorTokens.surfaceRaised,
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              child: Row(
                children: [
                  // Delete (discard) button.
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => _discardPracticeBlock(
                        activePbData.practiceBlockId,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Discard'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorTokens.errorDestructive,
                        side: const BorderSide(
                          color: ColorTokens.errorDestructive,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  // Resume button.
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: () => _resumePractice(
                          activePbData.practiceBlockId,
                        ),
                        icon: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 20),
                        label: const Text(
                          'Resume Practice',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorTokens.successDefault,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: ColorTokens.surfacePrimary,
              surfaceTintColor: Colors.transparent,
              indicatorColor: showHome
                  ? Colors.transparent
                  : ColorTokens.surfaceRaised,
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(
                    color: showHome
                        ? ColorTokens.textSecondary
                        : ColorTokens.primaryDefault,
                  );
                }
                return const IconThemeData(
                  color: ColorTokens.textSecondary,
                );
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    color: showHome
                        ? ColorTokens.textSecondary
                        : ColorTokens.primaryDefault,
                    fontSize: TypographyTokens.microSize,
                  );
                }
                return TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: TypographyTokens.microSize,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _goToTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.calendar_today),
                  label: 'Plan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_golf),
                  label: 'Practice',
                ),
                NavigationDestination(
                  icon: Icon(Icons.analytics_outlined),
                  label: 'Review',
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
