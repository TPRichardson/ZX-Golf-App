import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/bag/bag_screen.dart';
import 'package:zx_golf_app/features/home/home_dashboard_screen.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'tabs/plan_tab.dart';
import 'tabs/track_tab.dart';
import 'tabs/review_tab.dart';
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

  static const _tabTitles = ['Plan', 'Play', 'Review'];

  @override
  void initState() {
    super.initState();
    // Phase 7A — Start sync orchestrator on app launch.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _ensureUserProvisioned();
      ref.read(syncOrchestratorProvider).start();
      _checkDeferredSummary();
      _checkBagSetup();
    });
  }

  /// Auto-provision a local User record when authenticated via OAuth.
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
    // Auto-adopt all system drills for this user (idempotent).
    try {
      await ref.read(drillRepositoryProvider).autoAdoptAllSystemDrills(userId);
    } catch (e) {
      debugPrint('[ShellScreen] Auto-adopt failed: $e');
    }
  }

  /// Prompt user to set up their bag if no clubs exist.
  Future<void> _checkBagSetup() async {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) return;
    final clubs = await ref.read(clubRepositoryProvider).watchUserBag(
      userId,
      status: UserClubStatus.active,
    ).first;
    if (clubs.isNotEmpty || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Set Up Your Golf Bag',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: const Text(
          'Add the clubs you carry to get started. '
          'This lets ZX Golf tailor targets to your game.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
            SpacingTokens.lg, 0, SpacingTokens.lg, SpacingTokens.lg),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ZxPillButton(
                label: 'Set Up Bag',
                icon: Icons.golf_course,
                variant: ZxPillVariant.primary,
                expanded: true,
                centered: true,
                onTap: () {
                  Navigator.pop(dialogCtx);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BagScreen()),
                  );
                },
              ),
              const SizedBox(height: SpacingTokens.sm),
              ZxPillButton(
                label: 'Later',
                variant: ZxPillVariant.tertiary,
                expanded: true,
                centered: true,
                onTap: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
        ],
      ),
    );
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
    // Cache ref before super.dispose() makes it unavailable.
    try {
      ref.read(syncOrchestratorProvider).stop();
    } catch (_) {
      // Widget already disposed — orchestrator will clean up on its own.
    }
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
    final userId = ref.read(currentUserIdProvider);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeQueueScreen(
        practiceBlockId: practiceBlockId,
        userId: userId,
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

    final userId = ref.read(currentUserIdProvider);
    final actions = ref.read(practiceActionsProvider);
    await actions.discardPracticeBlock(practiceBlockId, userId);
  }

  @override
  Widget build(BuildContext context) {
    // S12 §12.2 — showHomeProvider controls Home vs Tab display.
    final showHome = ref.watch(showHomeProvider);

    // Active practice block for persistent resume bar.
    final userId = ref.watch(currentUserIdProvider);
    final activePb = ref.watch(activePracticeBlockProvider(userId));
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
      child: Listener(
        onPointerDown: (_) => ref.read(syncOrchestratorProvider).recordUserActivity(),
        child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
        children: [
          Column(
            children: [
              ZxShellTopBar(
                onHomeTap: _goHome,
                isHomeHighlighted: showHome,
                isAuthenticated: isAuthenticated,
                title: showHome ? 'Home' : _tabTitles[_currentIndex],
              ),
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
        ],
      ),
      ),
      bottomNavigationBar: Material(
        color: ColorTokens.surfacePrimary,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resume bar when a practice block is active
          // but user is NOT on the execution screen.
          if (activePbData != null &&
              !ref.watch(practiceExecutionActiveProvider))
            GestureDetector(
              onTap: () => _resumePractice(activePbData.practiceBlockId),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.md,
                ),
                decoration: const BoxDecoration(
                  color: ColorTokens.surfaceRaised,
                  border: Border(
                    bottom: BorderSide(color: ColorTokens.surfaceBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _PulsingDot(),
                          const SizedBox(width: SpacingTokens.sm),
                          Text(
                            'Practice Session Live',
                            style: TextStyle(
                              fontSize: TypographyTokens.headerSize,
                              fontWeight: FontWeight.w600,
                              color: ColorTokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _discardPracticeBlock(
                        activePbData.practiceBlockId,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ColorTokens.errorDestructive
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(ShapeTokens.radiusCard),
                          border: Border.all(
                            color: ColorTokens.errorDestructive
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: ColorTokens.errorDestructive,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    fontSize: TypographyTokens.bodyLgSize,
                  );
                }
                return TextStyle(
                  color: ColorTokens.textSecondary,
                  fontSize: TypographyTokens.bodyLgSize,
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
                  label: 'Play',
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
      ),
      ),
    );
  }
}

/// Gently pulsing green dot for the "Practice in progress" bar.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Icon(
        Icons.fiber_manual_record,
        size: 16,
        color: ColorTokens.successDefault,
      ),
    );
  }
}
