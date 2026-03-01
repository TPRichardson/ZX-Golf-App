import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_input_field.dart';

// S04 §4.5 — Anchor editor widget.
// Displays Min/Scratch/Pro fields per subskill with inline validation.

class AnchorEditor extends StatelessWidget {
  final String subskillId;
  final String subskillLabel;
  final double? minValue;
  final double? scratchValue;
  final double? proValue;
  final ValueChanged<({double min, double scratch, double pro})>? onChanged;
  final bool enabled;

  const AnchorEditor({
    super.key,
    required this.subskillId,
    required this.subskillLabel,
    this.minValue,
    this.scratchValue,
    this.proValue,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final minCtrl =
        TextEditingController(text: minValue?.toStringAsFixed(0) ?? '');
    final scratchCtrl =
        TextEditingController(text: scratchValue?.toStringAsFixed(0) ?? '');
    final proCtrl =
        TextEditingController(text: proValue?.toStringAsFixed(0) ?? '');

    // Validation: Min < Scratch < Pro.
    String? validationError;
    if (minValue != null && scratchValue != null && minValue! >= scratchValue!) {
      validationError = 'Min must be less than Scratch';
    } else if (scratchValue != null &&
        proValue != null &&
        scratchValue! >= proValue!) {
      validationError = 'Scratch must be less than Pro';
    }

    void notifyChange() {
      final min = double.tryParse(minCtrl.text);
      final scratch = double.tryParse(scratchCtrl.text);
      final pro = double.tryParse(proCtrl.text);
      if (min != null && scratch != null && pro != null && onChanged != null) {
        onChanged!((min: min, scratch: scratch, pro: pro));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subskillLabel,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ColorTokens.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: SpacingTokens.sm),
        Row(
          children: [
            Expanded(
              child: ZxInputField(
                label: 'Min',
                controller: minCtrl,
                keyboardType: TextInputType.number,
                enabled: enabled,
                onChanged: (_) => notifyChange(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxInputField(
                label: 'Scratch',
                controller: scratchCtrl,
                keyboardType: TextInputType.number,
                enabled: enabled,
                onChanged: (_) => notifyChange(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxInputField(
                label: 'Pro',
                controller: proCtrl,
                keyboardType: TextInputType.number,
                enabled: enabled,
                onChanged: (_) => notifyChange(),
              ),
            ),
          ],
        ),
        if (validationError != null) ...[
          const SizedBox(height: SpacingTokens.xs),
          Text(
            validationError,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ColorTokens.errorDestructive,
                ),
          ),
        ],
      ],
    );
  }
}
