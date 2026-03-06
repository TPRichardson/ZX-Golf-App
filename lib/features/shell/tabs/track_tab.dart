import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/bag/bag_screen.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/gapping_execution_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/gapping_setup_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/chipping_setup_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_execution_screen.dart';
import 'package:zx_golf_app/features/matrix/screens/wedge_setup_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

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
          shape: ZxTabBar.connectedHeaderShape,
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
        ),
        body: const Column(
          children: [
            ZxTabBar(tabs: [
              Tab(text: 'Track Drills'),
              Tab(text: 'Matrix'),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  PracticePoolScreen(embedded: true),
                  _MatrixTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matrix sub-tab: launch new matrix runs or resume an active one.
class _MatrixTab extends ConsumerWidget {
  const _MatrixTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const userId = kDevUserId;
    final activeRun = ref.watch(activeMatrixRunProvider(userId));

    return activeRun.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Text(
          'Error loading matrix data',
          style: TextStyle(color: ColorTokens.textTertiary),
        ),
      ),
      data: (run) {
        // Active run → show resume button.
        if (run != null) {
          final label = _matrixTypeLabel(run.matrixType);
          return Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: ColorTokens.primaryDefault,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    '$label in Progress',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  Text(
                    'Run #${run.runNumber}',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final screen =
                            run.matrixType == MatrixType.gappingChart
                                ? GappingExecutionScreen(
                                    matrixRunId: run.matrixRunId,
                                    userId: userId,
                                  ) as Widget
                                : MatrixExecutionScreen(
                                    matrixRunId: run.matrixRunId,
                                    userId: userId,
                                  );
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => screen));
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text('Resume $label'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorTokens.primaryDefault,
                        padding: const EdgeInsets.symmetric(
                            vertical: SpacingTokens.sm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // No active run → show launch buttons.
        return SingleChildScrollView(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Distance Calibration',
                style: TextStyle(
                  fontSize: TypographyTokens.headerSize,
                  fontWeight: TypographyTokens.headerWeight,
                  color: ColorTokens.textPrimary,
                ),
              ),
              const SizedBox(height: SpacingTokens.xs),
              Text(
                'Measure your distances to build a personal yardage profile.',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textSecondary,
                ),
              ),
              const SizedBox(height: SpacingTokens.lg),
              _MatrixLaunchCard(
                icon: Icons.grid_on,
                title: 'Gapping Chart',
                subtitle: 'One club at a time — measure carry and total.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => GappingSetupScreen(userId: userId),
                )),
              ),
              const SizedBox(height: SpacingTokens.md),
              _MatrixLaunchCard(
                icon: Icons.grid_view,
                title: 'Wedge Matrix',
                subtitle: 'Club × Effort × Flight — map your wedge system.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => WedgeSetupScreen(userId: userId),
                )),
              ),
              const SizedBox(height: SpacingTokens.md),
              _MatrixLaunchCard(
                icon: Icons.grid_3x3,
                title: 'Chipping Matrix',
                subtitle:
                    'Club × Distance × Flight — dial in short game accuracy.',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChippingSetupScreen(userId: userId),
                )),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _matrixTypeLabel(MatrixType type) {
    switch (type) {
      case MatrixType.gappingChart:
        return 'Gapping Chart';
      case MatrixType.wedgeMatrix:
        return 'Wedge Matrix';
      case MatrixType.chippingMatrix:
        return 'Chipping Matrix';
    }
  }
}

/// Card for launching a matrix workflow.
class _MatrixLaunchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MatrixLaunchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Row(
            children: [
              Icon(icon, size: 32, color: ColorTokens.primaryDefault),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodyLgSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ColorTokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
