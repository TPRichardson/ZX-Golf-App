// Phase 4 — Practice Queue Screen.
// S13 §13.3 — Queue view: list practice entries, add/remove/reorder drills,
// start sessions, end practice block.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/widgets/practice_entry_card.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

/// S13 §13.3 — Practice queue management screen.
class PracticeQueueScreen extends ConsumerStatefulWidget {
  final String practiceBlockId;
  final String userId;

  const PracticeQueueScreen({
    super.key,
    required this.practiceBlockId,
    required this.userId,
  });

  @override
  ConsumerState<PracticeQueueScreen> createState() =>
      _PracticeQueueScreenState();
}

class _PracticeQueueScreenState extends ConsumerState<PracticeQueueScreen> {
  bool _endingBlock = false;

  Future<void> _addDrill() async {
    // Navigate to practice pool to pick a drill.
    final drillId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const PracticePoolScreen(pickMode: true),
      ),
    );
    if (drillId != null && mounted) {
      await ref
          .read(practiceRepositoryProvider)
          .addDrillToQueue(widget.practiceBlockId, drillId);
    }
  }

  Future<void> _removePendingEntry(String entryId) async {
    await ref.read(practiceRepositoryProvider).removePendingEntry(entryId);
  }

  Future<void> _startSession(PracticeEntryWithDrill entryWithDrill) async {
    final actions = ref.read(practiceActionsProvider);
    final session = await actions.startSession(
      entryWithDrill.entry.practiceEntryId,
      widget.userId,
    );

    if (!mounted) return;

    // Route to execution screen.
    final screen = PracticeRouter.routeToExecutionScreen(
      drill: entryWithDrill.drill,
      session: session,
      userId: widget.userId,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _endPracticeBlock() async {
    if (_endingBlock) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('End Practice?',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: const Text(
          'This will close the practice block. Pending drills will be removed.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
            ),
            child: const Text('End Practice'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _endingBlock = true);
    final actions = ref.read(practiceActionsProvider);
    await actions.endPracticeBlock(widget.practiceBlockId, widget.userId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pbStream =
        ref.watch(practiceBlockWithEntriesProvider(widget.practiceBlockId));

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      appBar: ZxAppBar(
        title: 'Practice',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Drill',
            onPressed: _addDrill,
          ),
        ],
      ),
      body: pbStream.when(
        data: (pbWithEntries) {
          if (pbWithEntries == null) {
            return const Center(
              child: Text(
                'Practice block not found',
                style: TextStyle(color: ColorTokens.textSecondary),
              ),
            );
          }

          final entries = pbWithEntries.entries;

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.playlist_add,
                    size: 48,
                    color: ColorTokens.textTertiary,
                  ),
                  const SizedBox(height: SpacingTokens.md),
                  Text(
                    'No drills in queue',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodyLgSize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  FilledButton.icon(
                    onPressed: _addDrill,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Drill'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorTokens.primaryDefault,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: SpacingTokens.sm),
                  itemBuilder: (context, index) {
                    final ewd = entries[index];
                    return PracticeEntryCard(
                      entryWithDrill: ewd,
                      onTap: ewd.entry.entryType ==
                              PracticeEntryType.pendingDrill
                          ? () => _startSession(ewd)
                          : null,
                      onRemove:
                          ewd.entry.entryType == PracticeEntryType.pendingDrill
                              ? () => _removePendingEntry(
                                  ewd.entry.practiceEntryId)
                              : null,
                    );
                  },
                ),
              ),
              // Bottom actions bar.
              Container(
                padding: const EdgeInsets.all(SpacingTokens.md),
                decoration: const BoxDecoration(
                  color: ColorTokens.surfaceRaised,
                  border: Border(
                    top: BorderSide(color: ColorTokens.surfaceBorder),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _endingBlock ? null : _endPracticeBlock,
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorTokens.primaryDefault,
                      padding: const EdgeInsets.symmetric(
                          vertical: SpacingTokens.sm),
                    ),
                    child: _endingBlock
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('End Practice'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: ColorTokens.errorDestructive),
          ),
        ),
      ),
    );
  }
}
