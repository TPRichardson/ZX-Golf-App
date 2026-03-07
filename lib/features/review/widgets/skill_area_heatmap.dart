import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

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
    final windowStatsAsync =
        ref.watch(skillAreaWindowStatsProvider(widget.userId));
    final allocationsAsync =
        ref.watch(skillAreaAllocationsProvider);

    return windowStatsAsync.when(
      data: (windowStats) {
        final allocations = allocationsAsync.valueOrNull ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGrid(windowStats, allocations),
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
    Map<SkillArea, ({double totalPoints, double average})> windowStats,
    Map<SkillArea, int> allocations,
  ) {
    return Column(
      children: [
        // Row 1: Irons (full width).
        Row(children: [
          Expanded(
            child: _buildTileWidget(
                SkillArea.irons, windowStats, allocations),
          ),
        ]),
        const SizedBox(height: SpacingTokens.sm),
        // Row 2: Driving | Pitching | Woods.
        Row(children: [
          Expanded(
            flex: 50,
            child: _buildTileWidget(
                SkillArea.driving, windowStats, allocations),
          ),
          Expanded(
            flex: 30,
            child: _buildTileWidget(
                SkillArea.pitching, windowStats, allocations),
          ),
          Expanded(
            flex: 20,
            child: _buildTileWidget(
                SkillArea.woods, windowStats, allocations),
          ),
        ]),
        const SizedBox(height: SpacingTokens.sm),
        // Row 3: Putting | Chipping | Bunkers.
        Row(children: [
          Expanded(
            flex: 50,
            child: _buildTileWidget(
                SkillArea.putting, windowStats, allocations),
          ),
          Expanded(
            flex: 30,
            child: _buildTileWidget(
                SkillArea.chipping, windowStats, allocations),
          ),
          Expanded(
            flex: 20,
            child: _buildTileWidget(
                SkillArea.bunkers, windowStats, allocations),
          ),
        ]),
      ],
    );
  }

  Widget _buildTileWidget(
    SkillArea area,
    Map<SkillArea, ({double totalPoints, double average})> windowStats,
    Map<SkillArea, int> allocations,
  ) {
    final avg = windowStats[area]?.average ?? 0.0;
    final normalised = avg > 0 ? (avg / 5.0).clamp(0.0, 1.0) : 0.0;
    final allocation = allocations[area] ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SkillAreaTile(
        skillArea: area,
        normalisedScore: normalised,
        totalPoints: windowStats[area]?.totalPoints ?? 0.0,
        average: avg,
        allocation: allocation,
        isExpanded: _expandedArea == area,
        onTap: () {
          setState(() {
            _expandedArea = _expandedArea == area ? null : area;
          });
          widget.onExpandedChanged(_expandedArea);
        },
      ),
    );
  }
}
