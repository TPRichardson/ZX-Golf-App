// Continuous measurement input delegate — numeric distance/deviation entry.
// Extracted from continuous_measurement_screen.dart.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/practice/widgets/shot_record_button.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

class ContinuousMeasurementDelegate extends ExecutionInputDelegate {
  final _valueController = TextEditingController();
  double? lastScore;

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lastScore != null) ...[
            Text(
              lastScore!.toStringAsFixed(1),
              style: TextStyle(
                fontSize: TypographyTokens.displayXlSize,
                fontWeight: TypographyTokens.displayXlWeight,
                color: ColorTokens.successDefault,
              ),
            ),
            Text(
              'Last Score',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.xl),
          ],
          TextField(
            controller: _valueController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            style: TextStyle(
              fontSize: TypographyTokens.displayLgSize,
              color: ColorTokens.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Enter measurement',
              hintStyle: TextStyle(color: ColorTokens.textTertiary),
              filled: true,
              fillColor: ColorTokens.surfacePrimary,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide:
                    const BorderSide(color: ColorTokens.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide:
                    const BorderSide(color: ColorTokens.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(ShapeTokens.radiusInput),
                borderSide:
                    const BorderSide(color: ColorTokens.primaryDefault),
              ),
            ),
            textAlign: TextAlign.center,
            onSubmitted: (_) =>
                _submit(executionContext, onLogInstance),
          ),
          const SizedBox(height: SpacingTokens.md),
          ShotRecordButton(
            label: 'Record',
            onPressed: isLocked
                ? null
                : () => _submit(executionContext, onLogInstance),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) async {
    final text = _valueController.text.trim();
    if (text.isEmpty || ctx.isEnding) return;
    final value = double.tryParse(text);
    if (value == null) return;

    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: ctx.currentSetId!,
      selectedClub: Value(ctx.selectedClub),
      rawMetrics: jsonEncode({'value': value}),
      resolvedTargetDistance: Value(ctx.resolvedTargetDistance),
      resolvedTargetWidth: Value(ctx.resolvedTargetWidth),
      resolvedTargetDepth: Value(ctx.resolvedTargetDepth),
    );
    await onLogInstance(data);
  }

  @override
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {
    lastScore = result.realtimeScore;
    _valueController.clear();
  }

  @override
  void dispose() {
    _valueController.dispose();
  }
}
