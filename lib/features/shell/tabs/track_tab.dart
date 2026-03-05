import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/features/bag/bag_screen.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';

// S12 §12.3 — Track tab: Track Drills | Matrix dual-tab layout.

class TrackTab extends StatelessWidget {
  const TrackTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Start Training'),
          backgroundColor: ColorTokens.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: const Border(bottom: ZxTabBar.connectedAppBarBottom),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              tooltip: 'Golf Bag',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const BagScreen(),
                ));
              },
            ),
          ],
          bottom: const ZxTabBar(tabs: [
            Tab(text: 'Track Drills'),
            Tab(text: 'Matrix'),
          ]),
        ),
        body: const TabBarView(
          children: [
            PracticePoolScreen(embedded: true),
            _MatrixTab(),
          ],
        ),
      ),
    );
  }
}

/// Placeholder Matrix tab.
class _MatrixTab extends StatelessWidget {
  const _MatrixTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.grid_view,
            size: 48,
            color: ColorTokens.textTertiary,
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'Matrix',
            style: TextStyle(
              fontSize: TypographyTokens.headerSize,
              fontWeight: TypographyTokens.headerWeight,
              color: ColorTokens.textSecondary,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            'Coming soon',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
