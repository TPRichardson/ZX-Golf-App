import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

// Phase 7C — Cross-device active session conflict dialog.
// TD-07 §12, S17 §17.3.

class DualActiveSessionDialog extends ConsumerWidget {
  final String conflictingBlockId;

  const DualActiveSessionDialog({
    super.key,
    required this.conflictingBlockId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: ColorTokens.surfaceModal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShapeTokens.radiusModal),
      ),
      title: const Text(
        'Active Practice on Another Device',
        style: TextStyle(
          color: ColorTokens.textPrimary,
          fontSize: TypographyTokens.headerSize,
          fontWeight: TypographyTokens.headerWeight,
        ),
      ),
      content: const Text(
        'An active practice session was detected from another device. '
        'Only one practice session can be active at a time. '
        'Continuing will discard the other session. '
        'All completed sessions are safe.',
        style: TextStyle(
          color: ColorTokens.textSecondary,
          fontSize: TypographyTokens.bodySize,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await ref
                .read(practiceRepositoryProvider)
                .softDeletePracticeBlock(conflictingBlockId);
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: ColorTokens.primaryDefault,
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
