import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

// S10 §10.5 — Reusable confirmation dialogs (soft and strong).

/// S10 §10.5 — Soft confirmation: simple yes/no dialog.
Future<bool> showSoftConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: isDestructive
                  ? ColorTokens.errorDestructive
                  : ColorTokens.primaryDefault,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// S10 §10.5 — Strong confirmation: type-to-confirm dialog.
Future<bool> showStrongConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmPhrase,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
        ),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: SpacingTokens.md),
            TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type $confirmPhrase',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: controller.text == confirmPhrase
                ? () => Navigator.pop(ctx, true)
                : null,
            child: Text(
              'Confirm',
              style: TextStyle(
                color: controller.text == confirmPhrase
                    ? ColorTokens.errorDestructive
                    : ColorTokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
