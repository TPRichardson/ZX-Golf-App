// Grid cell input delegate — 1×3, 3×1, 3×3 grid tap input.
// Extracted from grid_cell_screen.dart.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';

class GridCellDelegate extends ExecutionInputDelegate {
  final Drill drill;

  GridCellDelegate({required this.drill});

  List<_CellDef> get _cells {
    return switch (drill.gridType) {
      GridType.oneByThree || null => [
          _CellDef('Miss Left', false, Icons.arrow_back),
          _CellDef('Hit', true, Icons.gps_fixed),
          _CellDef('Miss Right', false, Icons.arrow_forward),
        ],
      GridType.threeByOne => [
          _CellDef('Miss Long', false, Icons.arrow_upward),
          _CellDef('Hit', true, Icons.gps_fixed),
          _CellDef('Miss Short', false, Icons.arrow_downward),
        ],
      GridType.threeByThree => [
          _CellDef('Long Left', false, Icons.north_west),
          _CellDef('Long', false, Icons.arrow_upward),
          _CellDef('Long Right', false, Icons.north_east),
          _CellDef('Left', false, Icons.arrow_back),
          _CellDef('Hit', true, Icons.gps_fixed),
          _CellDef('Right', false, Icons.arrow_forward),
          _CellDef('Short Left', false, Icons.south_west),
          _CellDef('Short', false, Icons.arrow_downward),
          _CellDef('Short Right', false, Icons.south_east),
        ],
    };
  }

  bool get _isVertical => drill.gridType == GridType.threeByOne;

  @override
  Widget buildInputArea({
    required BuildContext context,
    required ExecutionContext executionContext,
    required LogInstanceCallback onLogInstance,
    required VoidCallback requestRebuild,
  }) {
    final cells = _cells;
    final is3x3 = drill.gridType == GridType.threeByThree;

    return IgnorePointer(
      ignoring: executionContext.isLocked,
      child: Opacity(
        opacity: executionContext.isLocked ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: is3x3 ? _build3x3Grid(cells, executionContext, onLogInstance)
              : _build1x3Or3x1(cells, executionContext, onLogInstance),
        ),
      ),
    );
  }

  Widget _build1x3Or3x1(
    List<_CellDef> cells,
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) {
    final isVert = _isVertical;
    return Center(
      child: isVert
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) const SizedBox(height: SpacingTokens.sm),
                  _buildLabeledCell(cells[i], isVert, ctx, onLogInstance),
                ],
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                      child: _buildLabeledCell(
                          cells[i], isVert, ctx, onLogInstance)),
                ],
              ],
            ),
    );
  }

  Widget _build3x3Grid(
    List<_CellDef> cells,
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SpacingTokens.sm,
        crossAxisSpacing: SpacingTokens.sm,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return _buildLabeledCell(cells[index], false, ctx, onLogInstance);
      },
    );
  }

  Widget _buildLabeledCell(
    _CellDef cell,
    bool isVertical,
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) {
    final color =
        cell.isHit ? ColorTokens.successDefault : ColorTokens.missDefault;
    final borderColor =
        cell.isHit ? ColorTokens.successHover : ColorTokens.missBorder;

    final content = Material(
      color: color,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
      child: InkWell(
        onTap: () => _onCellTap(cell, ctx, onLogInstance),
        borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
        splashColor: cell.isHit
            ? ColorTokens.successActive.withValues(alpha: 0.3)
            : ColorTokens.missActive.withValues(alpha: 0.3),
        child: Container(
          height: isVertical ? 100 : null,
          constraints:
              isVertical ? null : const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cell.icon, color: ColorTokens.textPrimary, size: 28),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  cell.label,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isVertical) {
      return SizedBox(width: double.infinity, child: content);
    }
    return content;
  }

  Future<void> _onCellTap(
    _CellDef cell,
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) async {
    if (ctx.isEnding) return;
    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: ctx.currentSetId!,
      selectedClub: ctx.selectedClub,
      rawMetrics: jsonEncode({'hit': cell.isHit, 'label': cell.label}),
    );
    await onLogInstance(data);
  }

  @override
  List<Widget> buildBottomBarActions({
    required BuildContext context,
    required ExecutionContext executionContext,
    required BulkAddCallback onBulkAdd,
  }) {
    return [
      TextButton.icon(
        onPressed: () => _bulkAddHits(executionContext, onBulkAdd),
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Bulk Add'),
      ),
    ];
  }

  Future<void> _bulkAddHits(
      ExecutionContext ctx, BulkAddCallback onBulkAdd) async {
    await onBulkAdd(0, (i) {
      return InstancesCompanion.insert(
        instanceId: const Uuid().v4(),
        setId: ctx.currentSetId!,
        selectedClub: ctx.selectedClub,
        rawMetrics: jsonEncode({'hit': true, 'label': 'Hit'}),
      );
    });
  }
}

class _CellDef {
  final String label;
  final bool isHit;
  final IconData icon;
  const _CellDef(this.label, this.isHit, this.icon);
}
