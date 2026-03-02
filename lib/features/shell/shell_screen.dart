import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'tabs/plan_tab.dart';
import 'tabs/track_tab.dart';
import 'tabs/review_tab.dart';

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
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
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
