import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_input_field.dart';

// S04 §4.5 — Anchor editor widget.
// Displays Min/Scratch/Pro fields per subskill with inline validation.

class AnchorEditor extends StatefulWidget {
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
  State<AnchorEditor> createState() => _AnchorEditorState();
}

class _AnchorEditorState extends State<AnchorEditor> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _scratchCtrl;
  late final TextEditingController _proCtrl;

  @override
  void initState() {
    super.initState();
    _minCtrl =
        TextEditingController(text: widget.minValue?.toStringAsFixed(0) ?? '');
    _scratchCtrl = TextEditingController(
        text: widget.scratchValue?.toStringAsFixed(0) ?? '');
    _proCtrl =
        TextEditingController(text: widget.proValue?.toStringAsFixed(0) ?? '');
  }

  @override
  void didUpdateWidget(AnchorEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller text when external values change, but only if the user
    // hasn't modified the field (controller text matches old external value).
    _syncController(_minCtrl, oldWidget.minValue, widget.minValue);
    _syncController(_scratchCtrl, oldWidget.scratchValue, widget.scratchValue);
    _syncController(_proCtrl, oldWidget.proValue, widget.proValue);
  }

  void _syncController(
      TextEditingController ctrl, double? oldVal, double? newVal) {
    if (oldVal != newVal) {
      final oldText = oldVal?.toStringAsFixed(0) ?? '';
      if (ctrl.text == oldText) {
        ctrl.text = newVal?.toStringAsFixed(0) ?? '';
      }
    }
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _scratchCtrl.dispose();
    _proCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final min = double.tryParse(_minCtrl.text);
    final scratch = double.tryParse(_scratchCtrl.text);
    final pro = double.tryParse(_proCtrl.text);
    if (min != null &&
        scratch != null &&
        pro != null &&
        widget.onChanged != null) {
      widget.onChanged!((min: min, scratch: scratch, pro: pro));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validation: Min < Scratch < Pro.
    String? validationError;
    if (widget.minValue != null &&
        widget.scratchValue != null &&
        widget.minValue! >= widget.scratchValue!) {
      validationError = 'Min must be less than Scratch';
    } else if (widget.scratchValue != null &&
        widget.proValue != null &&
        widget.scratchValue! >= widget.proValue!) {
      validationError = 'Scratch must be less than Pro';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.subskillLabel,
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
                controller: _minCtrl,
                keyboardType: TextInputType.number,
                enabled: widget.enabled,
                onChanged: (_) => _notifyChange(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxInputField(
                label: 'Scratch',
                controller: _scratchCtrl,
                keyboardType: TextInputType.number,
                enabled: widget.enabled,
                onChanged: (_) => _notifyChange(),
              ),
            ),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: ZxInputField(
                label: 'Pro',
                controller: _proCtrl,
                keyboardType: TextInputType.number,
                enabled: widget.enabled,
                onChanged: (_) => _notifyChange(),
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
