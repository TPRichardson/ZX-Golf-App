// Binary hit/miss input delegate — two large Hit/Miss buttons.
// Extracted from binary_hit_miss_screen.dart.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

class BinaryHitMissDelegate extends ExecutionInputDelegate {
  int hitCount = 0;
  int missCount = 0;

  @override
  Widget buildInputArea({
    required BuildContext context,
    required ExecutionContext executionContext,
    required LogInstanceCallback onLogInstance,
    required VoidCallback requestRebuild,
  }) {
    final isLocked = executionContext.isLocked;
    final total = hitCount + missCount;
    final hitRate = total > 0 ? (hitCount / total * 100).round() : 0;

    return Column(
      children: [
        // Running stats.
        Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(
                  label: 'Hits',
                  value: '$hitCount',
                  color: ColorTokens.successDefault),
              _StatBox(
                  label: 'Misses',
                  value: '$missCount',
                  color: ColorTokens.missDefault),
              _StatBox(
                  label: 'Rate',
                  value: '$hitRate%',
                  color: ColorTokens.primaryDefault),
            ],
          ),
        ),
        // Hit/Miss buttons.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.lg),
            child: Row(
              children: [
                Expanded(
                  child: _HitMissButton(
                    label: 'MISS',
                    color: isLocked
                        ? ColorTokens.missDefault.withValues(alpha: 0.4)
                        : ColorTokens.missDefault,
                    borderColor: ColorTokens.missBorder,
                    onTap: isLocked
                        ? () {}
                        : () => _record(false, executionContext, onLogInstance),
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                Expanded(
                  child: _HitMissButton(
                    label: 'HIT',
                    color: isLocked
                        ? ColorTokens.successDefault.withValues(alpha: 0.4)
                        : ColorTokens.successDefault,
                    borderColor: ColorTokens.successActive,
                    onTap: isLocked
                        ? () {}
                        : () => _record(true, executionContext, onLogInstance),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _record(
    bool isHit,
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) async {
    if (ctx.isEnding) return;
    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: ctx.currentSetId!,
      selectedClub: ctx.selectedClub,
      rawMetrics: jsonEncode({'hit': isHit}),
    );
    await onLogInstance(data);
  }

  @override
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {
    final metrics =
        jsonDecode(data.rawMetrics.value) as Map<String, dynamic>;
    final isHit = metrics['hit'] as bool? ?? false;
    if (isHit) {
      hitCount++;
    } else {
      missCount++;
    }
  }

  @override
  void onInstanceUndone(Instance? deleted) {
    if (deleted == null) return;
    final metrics =
        jsonDecode(deleted.rawMetrics) as Map<String, dynamic>;
    final wasHit = metrics['hit'] as bool? ?? false;
    if (wasHit) {
      hitCount = (hitCount - 1).clamp(0, hitCount);
    } else {
      missCount = (missCount - 1).clamp(0, missCount);
    }
  }

}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: TypographyTokens.displayLgSize,
            fontWeight: TypographyTokens.displayLgWeight,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.microSize,
            color: ColorTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HitMissButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _HitMissButton({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                fontWeight: TypographyTokens.displayLgWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
