import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

import 'skill_area_tile.dart';
import 'subskill_breakdown.dart';

// S15 §15.3.3 — Skill Area heatmap: 7 tiles sized proportionally to allocation.
// Tap → accordion expand inline showing subskills.

class SkillAreaHeatmap extends ConsumerStatefulWidget {
  final String userId;
  final ValueChanged<SkillArea?> onExpandedChanged;
  final void Function(String subskillId) onSubskillTap;

  const SkillAreaHeatmap({
    super.key,
    required this.userId,
    required this.onExpandedChanged,
    required this.onSubskillTap,
  });

  @override
  ConsumerState<SkillAreaHeatmap> createState() => _SkillAreaHeatmapState();
}

class _SkillAreaHeatmapState extends ConsumerState<SkillAreaHeatmap> {
  SkillArea? _expandedArea;

  @override
  Widget build(BuildContext context) {
    final heatmapAsync =
        ref.watch(skillAreaHeatmapProvider(widget.userId));
    final scoresAsync =
        ref.watch(skillAreaScoresProvider(widget.userId));

    return heatmapAsync.when(
      data: (heatmap) {
        final scores = scoresAsync.valueOrNull ?? [];
        final scoreMap = {for (final s in scores) s.skillArea: s};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGrid(heatmap, scoreMap),
            // Accordion content when expanded.
            if (_expandedArea != null)
              AnimatedSize(
                duration: MotionTokens.standard,
                curve: MotionTokens.curve,
                child: Container(
                  margin: const EdgeInsets.only(top: SpacingTokens.sm),
                  decoration: BoxDecoration(
                    color: ColorTokens.surfaceRaised,
                    borderRadius:
                        BorderRadius.circular(ShapeTokens.radiusCard),
                    border: Border.all(color: ColorTokens.surfaceBorder),
                  ),
                  child: SubskillBreakdown(
                    userId: widget.userId,
                    skillArea: _expandedArea!,
                    onSubskillTap: widget.onSubskillTap,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Error loading heatmap',
        style: TextStyle(color: ColorTokens.errorDestructive),
      ),
    );
  }

  Widget _buildGrid(
    Map<SkillArea, double> heatmap,
    Map<SkillArea, MaterialisedSkillAreaScore> scoreMap,
  ) {
    final areas = SkillArea.values;
    // 4 tiles on first row, 3 on second.
    final firstRow = areas.take(4).toList();
    final secondRow = areas.skip(4).toList();

    return Column(
      children: [
        _buildRow(firstRow, heatmap, scoreMap),
        const SizedBox(height: SpacingTokens.sm),
        _buildRow(secondRow, heatmap, scoreMap),
      ],
    );
  }

  Widget _buildRow(
    List<SkillArea> areas,
    Map<SkillArea, double> heatmap,
    Map<SkillArea, MaterialisedSkillAreaScore> scoreMap,
  ) {
    return Row(
      children: areas.map((area) {
        final normalised = heatmap[area] ?? 0.0;
        final score = scoreMap[area];
        final allocation = score?.allocation ?? 0;
        // Use allocation as flex; minimum 1 to avoid zero-flex.
        final flex = allocation > 0 ? allocation : 1;
        return Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SkillAreaTile(
              skillArea: area,
              normalisedScore: normalised,
              rawScore: score?.skillAreaScore ?? 0,
              allocation: allocation,
              isExpanded: _expandedArea == area,
              onTap: () {
                setState(() {
                  if (_expandedArea == area) {
                    _expandedArea = null;
                  } else {
                    _expandedArea = area;
                  }
                });
                widget.onExpandedChanged(_expandedArea);
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}
