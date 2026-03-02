import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/review/screens/window_detail_screen.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S05 §5.1 — Subskill detail: shows both Transition and Pressure windows.
// Tap either → Window Detail Screen.

class SubskillDetailScreen extends ConsumerWidget {
  final String userId;
  final String subskillId;

  const SubskillDetailScreen({
    super.key,
    required this.userId,
    required this.subskillId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refsAsync = ref.watch(allSubskillRefsProvider);
    final subskillName = refsAsync.whenOrNull(
      data: (refs) =>
          refs.where((r) => r.subskillId == subskillId).firstOrNull?.name,
    ) ?? subskillId;

    final transitionAsync = ref.watch(windowDetailProvider(
      (userId: userId, subskill: subskillId, practiceType: DrillType.transition),
    ));
    final pressureAsync = ref.watch(windowDetailProvider(
      (userId: userId, subskill: subskillId, practiceType: DrillType.pressure),
    ));

    return Scaffold(
      appBar: ZxAppBar(title: subskillName),
      body: ListView(
        padding: const EdgeInsets.all(SpacingTokens.md),
        children: [
          _buildWindowCard(
            context,
            'Transition Window',
            transitionAsync,
            DrillType.transition,
          ),
          const SizedBox(height: SpacingTokens.md),
          _buildWindowCard(
            context,
            'Pressure Window',
            pressureAsync,
            DrillType.pressure,
          ),
        ],
      ),
    );
  }

  Widget _buildWindowCard(
    BuildContext context,
    String title,
    AsyncValue<ParsedWindowDetail?> windowAsync,
    DrillType practiceType,
  ) {
    return windowAsync.when(
      data: (detail) {
        final hasData = detail != null && detail.entries.isNotEmpty;

        return GestureDetector(
          onTap: hasData
              ? () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => WindowDetailScreen(
                      userId: userId,
                      subskillId: subskillId,
                      practiceType: practiceType,
                    ),
                  ));
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            decoration: BoxDecoration(
              color: ColorTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              border: Border.all(color: ColorTokens.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: TypographyTokens.headerSize,
                          fontWeight: TypographyTokens.headerWeight,
                          color: ColorTokens.textPrimary,
                        ),
                      ),
                    ),
                    if (hasData)
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: ColorTokens.textTertiary,
                      ),
                  ],
                ),
                const SizedBox(height: SpacingTokens.sm),
                if (!hasData)
                  Text(
                    'No data yet',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textTertiary,
                    ),
                  )
                else ...[
                  // Saturation.
                  Text(
                    'Saturation: ${detail.totalOccupancy.toStringAsFixed(1)} / '
                    '${kMaxWindowOccupancy.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  // Window average.
                  Text(
                    'Average: ${detail.windowAverage.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    '${detail.entries.length} entries',
                    style: TextStyle(
                      fontSize: TypographyTokens.microSize,
                      color: ColorTokens.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Error loading window',
        style: TextStyle(color: ColorTokens.errorDestructive),
      ),
    );
  }
}
