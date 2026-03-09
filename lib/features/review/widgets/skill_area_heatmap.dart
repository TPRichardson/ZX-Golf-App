import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

import 'skill_area_tile.dart';
import 'subskill_breakdown.dart';

// S15 §15.3.3 — Skill Area heatmap: 3-row layout with inline subskill expand.
// Tap a tile → subskills appear full-width below the row.
// Cyan border wraps the selected tile (top+sides) and subskills (sides+bottom).

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

  static const _row1 = [SkillArea.irons];
  static const _row1Flex = [100];
  static const _row2 = [SkillArea.driving, SkillArea.pitching, SkillArea.woods];
  static const _row2Flex = [50, 30, 20];
  static const _row3 = [SkillArea.putting, SkillArea.chipping, SkillArea.bunkers];
  static const _row3Flex = [50, 30, 20];

  int? get _expandedRow => _expandedArea == null
      ? null
      : _rowForArea(_expandedArea!);

  static int _rowForArea(SkillArea area) {
    if (_row1.contains(area)) return 1;
    if (_row2.contains(area)) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final windowStatsAsync =
        ref.watch(skillAreaWindowStatsProvider(widget.userId));
    final allocationsAsync = ref.watch(skillAreaAllocationsProvider);

    return windowStatsAsync.when(
      data: (windowStats) {
        final allocations = allocationsAsync.valueOrNull ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(1, _row1, _row1Flex, windowStats, allocations),
            const SizedBox(height: 4),
            _buildRow(2, _row2, _row2Flex, windowStats, allocations),
            const SizedBox(height: 4),
            _buildRow(3, _row3, _row3Flex, windowStats, allocations),
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

  Widget _buildRow(
    int rowIndex,
    List<SkillArea> areas,
    List<int> flexValues,
    Map<SkillArea, ({double totalPoints, double average, double totalOccupancy, double windowCapacity})> windowStats,
    Map<SkillArea, int> allocations,
  ) {
    final isExpanded = _expandedRow == rowIndex;
    final expandedIndex = isExpanded ? areas.indexOf(_expandedArea!) : -1;

    // When a tile in a multi-tile row is expanded, it takes 80% width
    // and siblings collapse to 10% each.
    final effectiveFlex = <int>[];
    if (isExpanded && areas.length > 1) {
      for (int i = 0; i < areas.length; i++) {
        effectiveFlex.add(i == expandedIndex ? 70 : 15);
      }
    } else {
      effectiveFlex.addAll(flexValues);
    }

    final tileRow = Row(
      children: [
        for (int i = 0; i < areas.length; i++)
          Expanded(
            flex: effectiveFlex[i],
            child: _buildTileWidget(
              areas[i], windowStats, allocations,
              hasLeft: i > 0,
              hasRight: i < areas.length - 1,
              isCollapsed: isExpanded && i != expandedIndex,
            ),
          ),
      ],
    );

    if (!isExpanded) return tileRow;

    // Tile row + full-width subskills below.
    // The selected tile has its own top+sides border (from SkillAreaTile).
    // The subskill panel has sides+bottom border, spanning full width.
    // A top-border row bridges the gap between the tile's sides and the
    // subskill panel edges where non-selected tiles sit above.
    final leftFlex =
        effectiveFlex.sublist(0, expandedIndex).fold<int>(0, (a, b) => a + b);
    final selectedFlex = effectiveFlex[expandedIndex];
    final rightFlex =
        effectiveFlex.sublist(expandedIndex + 1).fold<int>(0, (a, b) => a + b);

    const borderSide = BorderSide(
      color: ColorTokens.primaryDefault,
      width: 1.5,
    );

    return Column(
      children: [
        tileRow,
        // Pull the border row up to close sub-pixel gap at the join.
        // Pad horizontally by 2px to align with the tile's padding.
        Transform.translate(
          offset: const Offset(0, -1.5),
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(children: [
        // Top border segments with rounded outer corners.
        Row(
          children: [
            if (leftFlex > 0)
              Expanded(
                flex: leftFlex,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: ColorTokens.primaryDefault,
                    borderRadius: expandedIndex > 0
                        ? BorderRadius.only(
                            topLeft: Radius.circular(ShapeTokens.radiusCard),
                          )
                        : null,
                  ),
                ),
              ),
            Expanded(flex: selectedFlex, child: const SizedBox(height: 1.5)),
            if (rightFlex > 0)
              Expanded(
                flex: rightFlex,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: ColorTokens.primaryDefault,
                    borderRadius: expandedIndex < areas.length - 1
                        ? BorderRadius.only(
                            topRight: Radius.circular(ShapeTokens.radiusCard),
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border(
              left: borderSide,
              right: borderSide,
              bottom: borderSide,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(ShapeTokens.radiusCard),
              bottomRight: Radius.circular(ShapeTokens.radiusCard),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(ShapeTokens.radiusCard - 1),
              bottomRight: Radius.circular(ShapeTokens.radiusCard - 1),
            ),
            child: SubskillBreakdown(
              userId: widget.userId,
              skillArea: _expandedArea!,
              onSubskillTap: widget.onSubskillTap,
            ),
          ),
        ),
        ]))),
      ],
    );
  }

  Widget _buildTileWidget(
    SkillArea area,
    Map<SkillArea, ({double totalPoints, double average, double totalOccupancy, double windowCapacity})> windowStats,
    Map<SkillArea, int> allocations, {
    bool hasLeft = false,
    bool hasRight = false,
    bool isCollapsed = false,
  }) {
    final stats = windowStats[area];
    final avg = stats?.average ?? 0.0;
    final normalised = avg > 0 ? (avg / 5.0).clamp(0.0, 1.0) : 0.0;
    final allocation = allocations[area] ?? 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SkillAreaTile(
        skillArea: area,
        normalisedScore: normalised,
        totalPoints: stats?.totalPoints ?? 0.0,
        average: avg,
        allocation: allocation,
        totalOccupancy: stats?.totalOccupancy ?? 0.0,
        windowCapacity: stats?.windowCapacity ?? 0.0,
        isExpanded: _expandedArea == area,
        isCollapsed: isCollapsed,
        hasLeft: hasLeft,
        hasRight: hasRight,
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

