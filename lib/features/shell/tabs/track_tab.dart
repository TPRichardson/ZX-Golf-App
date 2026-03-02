import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

// Phase 4 — Track tab: displays PracticePoolScreen + Start Practice button.
// S12 §12.3 — Track tab primary view.
// S13 §13.1 — "Start Practice" launches PracticeQueueScreen.

class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  // Phase 1 stub — replaced when auth is wired. Uses kDevUserId for consistency.
  static const _userId = kDevUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const PracticePoolScreen(),
        // S13 §13.1 — Start/Resume Practice FAB + Discard button overlay.
        Positioned(
          bottom: SpacingTokens.lg,
          right: SpacingTokens.lg,
          child: _PracticeControls(userId: _userId),
        ),
      ],
    );
  }
}

class _PracticeControls extends ConsumerWidget {
  final String userId;

  const _PracticeControls({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePb = ref.watch(activePracticeBlockProvider(userId));

    return activePb.when(
      data: (pb) {
        if (pb != null) {
          // Active practice block exists — show Resume + Discard.
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: SpacingTokens.sm,
            children: [
              // Discard button.
              FloatingActionButton.small(
                heroTag: 'discard_practice',
                onPressed: () => _confirmDiscard(context, ref, pb.practiceBlockId),
                backgroundColor: ColorTokens.errorDestructive,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              // Resume button.
              FloatingActionButton.extended(
                heroTag: 'resume_practice',
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PracticeQueueScreen(
                      practiceBlockId: pb.practiceBlockId,
                      userId: userId,
                    ),
                  ));
                },
                backgroundColor: ColorTokens.successDefault,
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text('Resume Practice',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }

        // No active PB — start new.
        return FloatingActionButton.extended(
          heroTag: 'start_practice',
          onPressed: () => _startPractice(context, ref),
          backgroundColor: ColorTokens.primaryDefault,
          icon: const Icon(Icons.sports_golf, color: Colors.white),
          label: const Text('Start Practice',
              style: TextStyle(color: Colors.white)),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Future<void> _startPractice(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(practiceActionsProvider);
    final pb = await actions.startPracticeBlock(userId);

    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PracticeQueueScreen(
          practiceBlockId: pb.practiceBlockId,
          userId: userId,
        ),
      ));
    }
  }

  Future<void> _confirmDiscard(
      BuildContext context, WidgetRef ref, String pbId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Discard Practice?',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: const Text(
          'This will delete all sessions and data from this practice block. This cannot be undone.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.errorDestructive,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final actions = ref.read(practiceActionsProvider);
      await actions.discardPracticeBlock(pbId, userId);
    }
  }
}
