import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/features/review/screens/analysis_screen.dart';
import 'package:zx_golf_app/features/review/screens/matrix_review_screen.dart';
import 'package:zx_golf_app/features/review/screens/review_dashboard_screen.dart';

// S12 §12.6 — Review tab: Dashboard | Analysis | Gapping tri-tab layout.
// Phase M8 — Added Gapping tab for matrix run history and snapshot management.

class ReviewTab extends StatelessWidget {
  const ReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        primary: false,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              decoration: const BoxDecoration(
                color: ColorTokens.surfacePrimary,
                border: Border(
                  top: BorderSide(color: ColorTokens.primaryDefault, width: 2),
                  left: BorderSide(color: ColorTokens.primaryDefault, width: 2),
                  right: BorderSide(color: ColorTokens.primaryDefault, width: 2),
                ),
              ),
              child: const Center(
                child: Text(
                  'Review Training',
                  style: TextStyle(
                    fontSize: TypographyTokens.headerSize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ),
            ),
            const ZxTabBar(tabs: [
              Tab(text: 'Dashboard'),
              Tab(text: 'Analysis'),
              Tab(text: 'Gapping'),
            ]),
            SizedBox(height: SpacingTokens.sm),
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
