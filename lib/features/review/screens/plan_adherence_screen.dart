import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// S05 §5.3 — Plan Adherence detail screen.
// Weekly/monthly rollups, SkillArea breakdown.

class PlanAdherenceScreen extends ConsumerStatefulWidget {
  final String userId;

  const PlanAdherenceScreen({super.key, required this.userId});

  @override
  ConsumerState<PlanAdherenceScreen> createState() =>
      _PlanAdherenceScreenState();
}

class _PlanAdherenceScreenState
    extends ConsumerState<PlanAdherenceScreen> {
  // Default: last 4 weeks.
  int _weekRange = 4;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: _weekRange * 7));
    final adherenceAsync = ref.watch(planAdherenceProvider(
      (userId: widget.userId, start: start, end: now),
    ));

    return Scaffold(
      appBar: const ZxAppBar(title: 'Plan Adherence'),
      body: Column(
        children: [
          // Date range selector.
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 4, label: Text('4 Weeks')),
                ButtonSegment(value: 12, label: Text('3 Months')),
                ButtonSegment(value: 26, label: Text('6 Months')),
              ],
              selected: {_weekRange},
              onSelectionChanged: (s) =>
                  setState(() => _weekRange = s.first),
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return ColorTokens.primaryDefault;
                  }
                  return ColorTokens.surfaceRaised;
                }),
              ),
            ),
          ),
          Expanded(
            child: adherenceAsync.when(
              data: (adherence) {
                return ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md),
                  children: [
                    // Headline.
                    _HeadlineCard(adherence: adherence),
                    const SizedBox(height: SpacingTokens.md),

                    // Skill area breakdown.
                    Text(
                      'By Skill Area',
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    if (adherence.perSkillArea.isEmpty)
                      Text(
                        'No planned slots in this period',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textTertiary,
                        ),
                      )
                    else
                      ...adherence.perSkillArea.entries.map((entry) {
                        final area = entry.key;
                        final data = entry.value;
                        final pct = data.total > 0
                            ? (data.completed / data.total * 100)
                            : 0.0;
                        return _SkillAreaRow(
                          skillArea: area,
                          completed: data.completed,
                          total: data.total,
                          percentage: pct,
                        );
                      }),
                  ],
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error loading adherence data',
                  style: TextStyle(
                      color: ColorTokens.errorDestructive),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final PlanAdherence adherence;

  const _HeadlineCard({required this.adherence});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      decoration: BoxDecoration(
        color: ColorTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        border: Border.all(color: ColorTokens.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            '${adherence.percentage.round()}%',
            style: TextStyle(
              fontSize: TypographyTokens.displayXlSize,
              fontWeight: TypographyTokens.displayXlWeight,
              color: ColorTokens.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            '${adherence.completedPlanned} of ${adherence.totalPlanned} planned slots completed',
            style: TextStyle(
              fontSize: TypographyTokens.bodySize,
              color: ColorTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillAreaRow extends StatelessWidget {
  final SkillArea skillArea;
  final int completed;
  final int total;
  final double percentage;

  const _SkillAreaRow({
    required this.skillArea,
    required this.completed,
    required this.total,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.sm),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skillArea.dbValue,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: TypographyTokens.headerWeight,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  // Progress bar.
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusGrid),
                    child: LinearProgressIndicator(
                      value: total > 0 ? completed / total : 0,
                      backgroundColor: ColorTokens.surfaceModal,
                      valueColor: const AlwaysStoppedAnimation(
                          ColorTokens.primaryDefault),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SpacingTokens.md),
            Text(
              '$completed/$total',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Text(
              '${percentage.round()}%',
              style: TextStyle(
                fontSize: TypographyTokens.headerSize,
                fontWeight: TypographyTokens.headerWeight,
                color: ColorTokens.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
