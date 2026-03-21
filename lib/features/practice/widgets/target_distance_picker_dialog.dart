import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Scroll wheel + tap-to-type dialog for target distance override.
class TargetDistancePickerDialog extends StatefulWidget {
  final int current;
  final int min;
  final int max;

  const TargetDistancePickerDialog({
    super.key,
    required this.current,
    required this.min,
    required this.max,
  });

  @override
  State<TargetDistancePickerDialog> createState() =>
      _TargetDistancePickerDialogState();
}

class _TargetDistancePickerDialogState
    extends State<TargetDistancePickerDialog> {
  late int _selectedValue;
  late FixedExtentScrollController _scrollCtrl;
  final _textCtrl = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.current.clamp(widget.min, widget.max);
    _scrollCtrl = FixedExtentScrollController(
      initialItem: _selectedValue - widget.min,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _commitTextEntry() {
    final v = int.tryParse(_textCtrl.text);
    if (v != null && v >= widget.min && v <= widget.max) {
      _selectedValue = v;
      _scrollCtrl.jumpToItem(v - widget.min);
    }
    _editing = false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Set Target Distance',
        style: TextStyle(color: ColorTokens.textPrimary),
      ),
      contentPadding: const EdgeInsets.all(SpacingTokens.md),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 180,
            child: Row(
              children: [
                // Left: display value — tap to type.
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _editing = true;
                        _textCtrl.text = '$_selectedValue';
                        _textCtrl.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _textCtrl.text.length,
                        );
                      });
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
                                style: const TextStyle(
                                  fontSize: TypographyTokens.displayXlSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.primaryDefault,
                                ),
                                decoration: const InputDecoration(
                                  suffixText: 'y',
                                  suffixStyle: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    color: ColorTokens.textTertiary,
                                  ),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) {
                                  setState(() => _commitTextEntry());
                                },
                              ),
                            )
                          : Text(
                              '${_selectedValue}y',
                              style: const TextStyle(
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
                      setState(() {
                        _selectedValue = widget.min + index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.max - widget.min + 1,
                      builder: (context, index) {
                        final value = widget.min + index;
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, -1.0),
          child: const Text('Reset',
              style: TextStyle(color: ColorTokens.textSecondary)),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, _selectedValue.toDouble()),
          style: FilledButton.styleFrom(
            backgroundColor: ColorTokens.primaryDefault,
            foregroundColor: ColorTokens.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            ),
          ),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
