import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';
import 'package:zx_golf_app/features/review/screens/matrix_review_screen.dart';
import 'package:zx_golf_app/features/review/screens/review_dashboard_screen.dart';

// S12 §12.6 — Review tab: Dashboard | Analysis | Matrices tri-tab layout.
// Phase M8 — Added Matrices tab for matrix run history and snapshot management.

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Review Past Training'),
          backgroundColor: ColorTokens.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: ZxTabBar.connectedHeaderShape,
        ),
        body: const Column(
          children: [
            ZxTabBar(tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Analysis'),
              Tab(text: 'Matrices'),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  ReviewDashboardScreen(),
                  AnalysisScreen(),
                  MatrixReviewScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
