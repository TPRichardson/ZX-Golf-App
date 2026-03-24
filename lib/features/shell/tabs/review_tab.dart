import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';
import 'package:zx_golf_app/features/review/screens/matrix_review_screen.dart';

// S12 §12.6 — Review tab: Analysis | Gapping dual-tab layout.
// Dashboard moved to home screen.

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        primary: false,
        body: Column(
          children: [
            const ZxSimpleTabBar(tabs: [
              Tab(text: 'Analysis'),
              Tab(text: 'Gapping'),
            ]),
            Expanded(
              child: TabBarView(
                children: [
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
