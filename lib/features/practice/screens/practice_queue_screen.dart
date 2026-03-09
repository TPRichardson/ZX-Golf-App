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
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/widgets/practice_entry_card.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
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

  /// S13 §13.12 — Save current queue as a Routine.
  Future<void> _saveAsRoutine(List<PracticeEntryWithDrill> entries) async {
    final drillIds = entries.map((e) => e.drill.drillId).toList();
    if (drillIds.isEmpty) return;

    final planningRepo = ref.read(planningRepositoryProvider);
    final routine = await planningRepo.createRoutineWithEntries(
      widget.userId,
      'Practice ${DateTime.now().month}/${DateTime.now().day}',
      drillIds.map((id) => RoutineEntry.fixed(id)).toList(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved as "${routine.name}"')),
    );
  }

  Future<void> _startSession(PracticeEntryWithDrill entryWithDrill) async {
    final drill = entryWithDrill.drill;

    // Check if drill requires clubs the user doesn't have in their bag.
    if (drill.clubSelectionMode != null) {
      final clubs = await ref
          .read(clubsForSkillAreaProvider((widget.userId, drill.skillArea))
              .future);
      if (clubs.isEmpty && mounted) {
        final proceed = await _showNoClubsWarning(drill.skillArea);
        if (proceed != true || !mounted) return;
      }
    }

    // Prompt for environment/surface before starting.
    if (!mounted) return;
    final envSurface = await showEnvironmentSurfacePicker(context);
    if (envSurface == null || !mounted) return;

    final actions = ref.read(practiceActionsProvider);

    // S04 §4.3 — Prompt for intention declaration on Binary Hit/Miss drills.
    String? userDeclaration;
    if (entryWithDrill.drill.inputMode == InputMode.binaryHitMiss) {
      userDeclaration = await _promptForDeclaration();
      if (userDeclaration != null && userDeclaration.trim().isEmpty) {
        userDeclaration = null;
      }
    }

    final session = await actions.startSession(
      entryWithDrill.entry.practiceEntryId,
      widget.userId,
      userDeclaration: userDeclaration,
      surfaceType: envSurface.surface,
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

  /// S04 §4.3 — Prompt user for their intention (e.g. "Hit fairway", "Draw").
  Future<String?> _promptForDeclaration() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Session Declaration',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: ColorTokens.textPrimary),
          decoration: InputDecoration(
            hintText: 'What are you aiming for? (e.g. "Hit fairway")',
            hintStyle: TextStyle(color: ColorTokens.textTertiary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.primaryDefault,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  /// Warning when drill requires clubs but user has none for that skill area.
  Future<bool?> _showNoClubsWarning(SkillArea skillArea) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('No Clubs Configured',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: Text(
          'This drill requires clubs for ${skillArea.dbValue}, '
          'but you have none in your bag. '
          'Add clubs in Settings → Golf Bag before starting this drill.',
          style: const TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.warningIntegrity,
            ),
            child: const Text('Start Anyway'),
          ),
        ],
      ),
    );
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
          // S13 §13.12 — Save queue as Routine (overflow menu).
          pbStream.when(
            data: (pb) {
              final hasEntries = pb != null && pb.entries.isNotEmpty;
              if (!hasEntries) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'saveAsRoutine') {
                    _saveAsRoutine(pb.entries);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'saveAsRoutine',
                    child: Text('Save as Routine'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
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
