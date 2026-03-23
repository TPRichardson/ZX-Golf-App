import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';

// Read-only reference screen showing lateral (width) and carry (depth)
// target percentages used per skill area during drill execution.

class TargetPercentagesScreen extends StatelessWidget {
  const TargetPercentagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ZxShellTopBar(
              onHomeTap: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              title: 'Target Percentages',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md,
                  vertical: SpacingTokens.sm,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                    child: Text(
                      'Target zone as % of carry distance',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ),
                  // Driving — driver maps to long iron tier.
                  _SkillAreaCard(
                    skillArea: SkillArea.driving,
                    rows: [
                      _PercentageRow('Driver',
                          kLongIronTargetWidthPercent,
                          kLongIronTargetDepthPercent),
                    ],
                  ),
                  // Woods — all map to long iron tier.
                  _SkillAreaCard(
                    skillArea: SkillArea.woods,
                    rows: [
                      _PercentageRow('All Woods',
                          kLongIronTargetWidthPercent,
                          kLongIronTargetDepthPercent),
                    ],
                  ),
                  // Approach — club-tier banded.
                  _SkillAreaCard(
                    skillArea: SkillArea.approach,
                    rows: [
                      _PercentageRow('Short Irons',
                          kShortIronTargetWidthPercent,
                          kShortIronTargetDepthPercent),
                      _PercentageRow('Mid Irons',
                          kMidIronTargetWidthPercent,
                          kMidIronTargetDepthPercent),
                      _PercentageRow('Long Irons / Hybrids',
                          kLongIronTargetWidthPercent,
                          kLongIronTargetDepthPercent),
                    ],
                  ),
                  // Pitching — flat percentages.
                  _SkillAreaCard(
                    skillArea: SkillArea.pitching,
                    rows: const [
                      _PercentageRow('All Clubs', 12.0, 14.0),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm),
                    child: Text(
                      'Putting, Chipping, and Bunkers use fixed target sizes rather than carry percentages.',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        color: ColorTokens.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentageRow {
  final String label;
  final double lateral;
  final double carry;
  const _PercentageRow(this.label, this.lateral, this.carry);
}

class _SkillAreaCard extends StatelessWidget {
  final SkillArea skillArea;
  final List<_PercentageRow> rows;

  const _SkillAreaCard({
    required this.skillArea,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final color = ColorTokens.skillArea(skillArea);
    return Card(
      color: ColorTokens.surfaceRaised,
      margin: const EdgeInsets.only(bottom: SpacingTokens.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skill area header with colour indicator.
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusMicro),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  skillArea.dbValue,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpacingTokens.sm),
            // Column headers.
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: SpacingTokens.xs),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Club Tier',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Lateral',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Carry',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        fontWeight: FontWeight.w500,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: SpacingTokens.md),
            // Data rows.
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.xs,
                  vertical: SpacingTokens.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.label,
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          color: ColorTokens.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${row.lateral.toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${row.carry.toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
