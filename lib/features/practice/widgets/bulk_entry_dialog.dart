// Fix 4 — Bulk entry count picker dialog.
// Used across all execution screens (except technique block).

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';

/// Fix 4 — Shows a dialog to pick bulk entry count.
/// Returns the selected count, or null if cancelled.
/// [maxCount] caps the picker for structured drills (null = unlimited, defaults to 50).
Future<int?> showBulkEntryDialog(
  BuildContext context, {
  int? maxCount,
  String title = 'Bulk Add',
}) async {
  final effectiveMax = maxCount ?? 50;
  if (effectiveMax <= 0) return null;

  int count = 5.clamp(1, effectiveMax);

  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: Text(title, style: const TextStyle(color: ColorTokens.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How many instances to add?',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: count > 1
                      ? () => setDialogState(() => count--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: ColorTokens.primaryDefault,
                ),
                const SizedBox(width: SpacingTokens.md),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: TypographyTokens.displayLgSize,
                    fontWeight: TypographyTokens.displayLgWeight,
                    color: ColorTokens.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: SpacingTokens.md),
                IconButton(
                  onPressed: count < effectiveMax
                      ? () => setDialogState(() => count++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: ColorTokens.primaryDefault,
                ),
              ],
            ),
            if (maxCount != null)
              Padding(
                padding: const EdgeInsets.only(top: SpacingTokens.sm),
                child: Text(
                  'Max: $maxCount remaining',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(count),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
            ),
            child: Text('Add $count'),
          ),
        ],
      ),
    ),
  );
}
