import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';
import 'package:zx_golf_app/features/review/screens/review_dashboard_screen.dart';

// S12 §12.6 — Review tab: Dashboard | Analysis dual-tab layout.
// Same pattern as PlanTab (DefaultTabController + TabBar + TabBarView).

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Past Training'),
          backgroundColor: ColorTokens.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: const ZxTabBar(tabs: [
            Tab(text: 'Dashboard'),
            Tab(text: 'Analysis'),
          ]),
        ),
        body: const TabBarView(
          children: [
            ReviewDashboardScreen(),
            AnalysisScreen(),
          ],
        ),
      ),
    );
  }
}
