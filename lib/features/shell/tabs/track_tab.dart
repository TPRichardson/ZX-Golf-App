import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';
import 'package:zx_golf_app/features/practice/screens/practice_queue_screen.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

// Phase 4 — Track tab: displays PracticePoolScreen + Start Practice button.
// S12 §12.3 — Track tab primary view.
// S13 §13.1 — "Start Practice" launches PracticeQueueScreen.

class TrackTab extends ConsumerWidget {
  const TrackTab({super.key});

  // Phase 3 stub — replaced when auth is wired.
  static const _userId = 'local-user';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const PracticePoolScreen(),
        // S13 §13.1 — Start Practice FAB overlay.
        Positioned(
          bottom: SpacingTokens.lg,
          right: SpacingTokens.lg,
          child: _StartPracticeButton(userId: _userId),
        ),
      ],
    );
  }
}

class _StartPracticeButton extends ConsumerWidget {
  final String userId;

  const _StartPracticeButton({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePb = ref.watch(activePracticeBlockProvider(userId));

    return activePb.when(
      data: (pb) {
        if (pb != null) {
          // Active practice block exists — resume.
          return FloatingActionButton.extended(
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
}
