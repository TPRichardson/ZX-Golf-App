// Raw data entry input delegate — numeric input with real-time 0–5 score.
// Extracted from raw_data_entry_screen.dart.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

class RawDataEntryDelegate extends ExecutionInputDelegate {
  final _valueController = TextEditingController();
  double? lastScore;
  final List<double> recentScores = [];

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
          // Real-time score display.
          if (lastScore != null) ...[
            Text(
              lastScore!.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 64,
                fontWeight: TypographyTokens.displayXlWeight,
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
          // Value input.
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
              hintText: 'Enter value',
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
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLocked
                  ? null
                  : () => _submit(executionContext, onLogInstance),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primaryDefault,
                padding: const EdgeInsets.symmetric(
                    vertical: SpacingTokens.md),
              ),
              child: const Text('Record'),
            ),
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
      selectedClub: ctx.selectedClub,
      rawMetrics: jsonEncode({'value': value}),
    );
    await onLogInstance(data);
  }

  @override
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {
    lastScore = result.realtimeScore;
    if (result.realtimeScore != null) {
      recentScores.add(result.realtimeScore!);
    }
    _valueController.clear();
  }

  @override
  void dispose() {
    _valueController.dispose();
  }
}
