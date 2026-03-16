// Raw data entry input delegate — scroll wheel numeric input with real-time 0–5 score.
// Uses the same scroll wheel picker pattern as the carry distance input on the golf bag.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

class RawDataEntryDelegate extends ExecutionInputDelegate {
  final Drill? drill;
  double? lastScore;
  final List<double> recentScores = [];
  final List<double> _recordedValues = [];
  bool get _isBestOfSet => drill?.metricSchemaId == 'driver_club_speed' ||
      drill?.metricSchemaId == 'driver_ball_speed' ||
      drill?.metricSchemaId == 'driver_total_distance';

  late final int _min;
  late final int _max;
  late final int _initial;
  late final String _suffix;
  late FixedExtentScrollController _scrollCtrl;
  late int _selectedValue;
  bool _editing = false;
  final _textCtrl = TextEditingController();

  RawDataEntryDelegate({this.drill}) {
    final range = _rangeForMetric(drill?.metricSchemaId);
    _min = range.min;
    _max = range.max;
    _initial = range.initial;
    _suffix = range.suffix;
    _selectedValue = _initial;
    _scrollCtrl = FixedExtentScrollController(
      initialItem: _initial - _min,
    );
  }

  /// Determine sensible min/max/initial/suffix based on MetricSchemaID.
  static ({int min, int max, int initial, String suffix}) _rangeForMetric(
      String? schemaId) {
    return switch (schemaId) {
      'raw_club_head_speed' || 'driver_club_speed' =>
        (min: 50, max: 150, initial: 95, suffix: 'mph'),
      'raw_ball_speed' || 'driver_ball_speed' =>
        (min: 80, max: 200, initial: 140, suffix: 'mph'),
      'raw_total_distance' || 'driver_total_distance' =>
        (min: 100, max: 400, initial: 230, suffix: 'yds'),
      'raw_carry_distance' => (min: 50, max: 350, initial: 200, suffix: 'yds'),
      _ => (min: 0, max: 500, initial: 100, suffix: ''),
    };
  }

  @override
  Widget buildInputArea({
    required BuildContext context,
    required ExecutionContext executionContext,
    required LogInstanceCallback onLogInstance,
    required VoidCallback requestRebuild,
  }) {
    final isLocked = executionContext.isLocked;

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        children: [
          // Score/value display.
          if (!_isBestOfSet && lastScore != null) ...[
            Text(
              lastScore!.toStringAsFixed(1),
              style: TextStyle(
                fontSize: TypographyTokens.displayXxlSize,
                fontWeight: TypographyTokens.displayXxlWeight,
                color: scoreColor(lastScore!),
              ),
            ),
            const SizedBox(height: SpacingTokens.xs),
            Text(
              'out of 5.0',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            if (recentScores.length > 1) ...[
              const SizedBox(height: SpacingTokens.sm),
              Text(
                'Avg: ${(recentScores.reduce((a, b) => a + b) / recentScores.length).toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: SpacingTokens.xl),
          ],
          // Scroll wheel + display — vertically centred in available space.
          Expanded(
            child: Center(
              child: SizedBox(
                height: 180,
                child: Row(
              children: [
                // Left: live display value — tap to type.
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _editing = true;
                      _textCtrl.text = '$_selectedValue';
                      _textCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _textCtrl.text.length,
                      );
                      requestRebuild();
                    },
                    child: Center(
                      child: _editing
                          ? SizedBox(
                              width: 120,
                              child: TextField(
                                controller: _textCtrl,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: TypographyTokens.displayXlSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.primaryDefault,
                                ),
                                decoration: InputDecoration(
                                  suffixText: _suffix,
                                  suffixStyle: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    color: ColorTokens.textTertiary,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) {
                                  _commitTextEntry();
                                  requestRebuild();
                                },
                              ),
                            )
                          : Text(
                              '$_selectedValue$_suffix',
                              style: TextStyle(
                                fontSize: TypographyTokens.displayXlSize,
                                fontWeight: FontWeight.w600,
                                color: ColorTokens.primaryDefault,
                              ),
                            ),
                    ),
                  ),
                ),
                // Right: scroll wheel.
                SizedBox(
                  width: 80,
                  child: ListWheelScrollView.useDelegate(
                    controller: _scrollCtrl,
                    itemExtent: 36,
                    physics: const FixedExtentScrollPhysics(),
                    diameterRatio: 1.6,
                    perspective: 0.003,
                    onSelectedItemChanged: (index) {
                      _selectedValue = _min + index;
                      requestRebuild();
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _max - _min + 1,
                      builder: (context, index) {
                        final value = _min + index;
                        final isSelected = value == _selectedValue;
                        return Center(
                          child: Text(
                            '$value',
                            style: TextStyle(
                              fontSize: isSelected
                                  ? TypographyTokens.displayLgSize
                                  : TypographyTokens.bodyLgSize,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? ColorTokens.textPrimary
                                  : ColorTokens.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLocked
                    ? null
                    : () => _submit(executionContext, onLogInstance),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorTokens.primaryDefault,
                  padding: const EdgeInsets.symmetric(
                      vertical: SpacingTokens.md),
                  textStyle: const TextStyle(
                    fontSize: TypographyTokens.bodyLgSize,
                  ),
                ),
                child: const Text('Record'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _commitTextEntry() {
    final v = int.tryParse(_textCtrl.text);
    if (v == null || v < _min || v > _max) {
      _editing = false;
      return;
    }
    _selectedValue = v;
    _editing = false;
    _scrollCtrl.animateToItem(
      v - _min,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit(
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) async {
    if (ctx.isEnding) return;

    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: ctx.currentSetId!,
      selectedClub: Value(ctx.selectedClub),
      rawMetrics: jsonEncode({'value': _selectedValue.toDouble()}),
    );
    await onLogInstance(data);
  }

  @override
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {
    // Track raw value for best-of-set display.
    final metrics = jsonDecode(data.rawMetrics.value) as Map<String, dynamic>;
    final value = (metrics['value'] as num?)?.toDouble();
    if (value != null) _recordedValues.add(value);

    if (!_isBestOfSet) {
      lastScore = result.realtimeScore;
      if (result.realtimeScore != null) {
        recentScores.add(result.realtimeScore!);
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
  }
}
