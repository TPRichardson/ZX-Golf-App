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
import 'package:zx_golf_app/features/practice/widgets/practice_stats_bar.dart';
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

  /// Change environment only (Indoor/Outdoor). Surface stays as-is.
  Future<void> _changeEnvironment(SurfaceType? currentSurface) async {
    final env = await showEnvironmentPicker(context);
    if (env == null || !mounted) return;
    await ref
        .read(practiceRepositoryProvider)
        .updateBlockEnvironmentAndSurface(
          widget.practiceBlockId,
          environmentType: env,
          surfaceType: currentSurface ?? SurfaceType.mat,
        );
    ref.invalidate(practiceBlockWithEntriesProvider(widget.practiceBlockId));
  }

  /// Change surface only (Grass/Mat). Environment stays as-is.
  Future<void> _changeSurface(EnvironmentType? currentEnv) async {
    final surface = await showSurfacePicker(context);
    if (surface == null || !mounted) return;
    await ref
        .read(practiceRepositoryProvider)
        .updateBlockEnvironmentAndSurface(
          widget.practiceBlockId,
          environmentType: currentEnv ?? EnvironmentType.indoor,
          surfaceType: surface,
        );
    ref.invalidate(practiceBlockWithEntriesProvider(widget.practiceBlockId));
  }

  Future<void> _addDrill() async {
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

  /// Remove a completed session entry (discard the session).
  Future<void> _removeCompletedEntry(PracticeEntryWithDrill ewd) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Remove Completed Drill?',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: const Text(
          'This will remove the completed drill from this practice block.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.errorDestructive,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (ewd.session != null) {
        await ref
            .read(practiceActionsProvider)
            .discardSession(ewd.entry.practiceEntryId, ewd.session!.sessionId);
      }
    }
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
    );

    if (!mounted) return;

    final screen = PracticeRouter.routeToExecutionScreen(
      drill: entryWithDrill.drill,
      session: session,
      userId: widget.userId,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Resume an active session that's already in progress.
  Future<void> _resumeSession(PracticeEntryWithDrill ewd) async {
    if (ewd.session == null) return;

    final screen = PracticeRouter.routeToExecutionScreen(
      drill: ewd.drill,
      session: ewd.session!,
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
        title: const Text('Finish Practice?',
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
            child: const Text('Finish'),
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

  Future<void> _discardPracticeBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorTokens.surfaceModal,
        title: const Text('Discard Practice?',
            style: TextStyle(color: ColorTokens.textPrimary)),
        content: const Text(
          'This will discard the entire practice block and all sessions.',
          style: TextStyle(color: ColorTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorTokens.errorDestructive,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(practiceActionsProvider)
          .discardPracticeBlock(widget.practiceBlockId, widget.userId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// S04 §4.3 — Prompt user for their intention.
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
          // Routines dropdown.
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Routines',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down,
                      color: ColorTokens.textSecondary),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'saveAsRoutine') {
                final entries = pbStream.valueOrNull?.entries ?? [];
                _saveAsRoutine(entries);
              } else if (value == 'importRoutine') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import routine coming soon')),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'importRoutine',
                child: Text('Import Routine'),
              ),
              PopupMenuItem(
                value: 'saveAsRoutine',
                child: Text('Save as Routine'),
              ),
            ],
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
          final pb = pbWithEntries.practiceBlock;

          // Partition entries: completed first, then pending/active.
          final completed = entries
              .where(
                  (e) => e.entry.entryType == PracticeEntryType.completedSession)
              .toList();
          final pending = entries
              .where(
                  (e) => e.entry.entryType != PracticeEntryType.completedSession)
              .toList();

          return Column(
            children: [
              // Environment + surface tiles — always visible.
              _EnvironmentSurfaceBar(
                environmentType: pb.environmentType,
                surfaceType: pb.surfaceType,
                onEnvironmentTap: () => _changeEnvironment(pb.surfaceType),
                onSurfaceTap: () => _changeSurface(pb.environmentType),
              ),
              // Stats bar — clock, weather, location.
              PracticeStatsBar(
                startTimestamp: pb.startTimestamp,
                environmentType: pb.environmentType,
              ),
              // Entry list or empty state.
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyState()
                    : _buildEntryList(completed, pending),
              ),
              // Bottom action bar — always visible.
              _buildBottomBar(entries.isNotEmpty),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Text(
          'Add a drill to start practice.',
          style: TextStyle(
            fontSize: TypographyTokens.bodyLgSize,
            color: ColorTokens.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEntryList(
    List<PracticeEntryWithDrill> completed,
    List<PracticeEntryWithDrill> pending,
  ) {
    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      children: [
        // Completed section.
        if (completed.isNotEmpty) ...[
          for (final ewd in completed)
            Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
              child: PracticeEntryCard(
                entryWithDrill: ewd,
                sessionScore: ewd.session != null ? null : null,
                // TODO: fetch session scores for completed entries.
                onRemove: () => _removeCompletedEntry(ewd),
              ),
            ),
          // Styled separator between completed and pending.
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: ColorTokens.successDefault.withValues(alpha: 0.3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.sm),
                    child: Text(
                      'UP NEXT',
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: ColorTokens.surfaceBorder,
                    ),
                  ),
                ],
              ),
            ),
        ],
        // Pending / active section.
        for (final ewd in pending)
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: PracticeEntryCard(
              entryWithDrill: ewd,
              onTap: ewd.entry.entryType == PracticeEntryType.pendingDrill
                  ? () => _startSession(ewd)
                  : ewd.entry.entryType == PracticeEntryType.activeSession
                      ? () => _resumeSession(ewd)
                      : null,
              onRemove: ewd.entry.entryType == PracticeEntryType.pendingDrill
                  ? () => _removePendingEntry(ewd.entry.practiceEntryId)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(bool hasEntries) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add Drill button — primary solid cyan, chunky.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addDrill,
              icon: const Icon(Icons.add),
              label: const Text('Add Drill'),
              style: FilledButton.styleFrom(
                backgroundColor: ColorTokens.primaryDefault,
                padding: const EdgeInsets.symmetric(
                  vertical: SpacingTokens.sm + 4,
                ),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Finish Practice — secondary reversed-out, double horizontal padding.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _endingBlock ? null : _endPracticeBlock,
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorTokens.primaryDefault,
                side: const BorderSide(color: ColorTokens.primaryDefault),
                padding: const EdgeInsets.symmetric(
                  vertical: SpacingTokens.sm + 4,
                  horizontal: SpacingTokens.xl,
                ),
              ),
              child: _endingBlock
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Finish Practice'),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Practice Settings + Discard row.
          Row(
            children: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Practice settings coming soon')),
                  );
                },
                child: Text(
                  'Practice Settings',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _discardPracticeBlock,
                icon: Icon(Icons.delete_outline,
                    size: 16, color: ColorTokens.errorDestructive),
                label: Text(
                  'Discard Practice',
                  style: TextStyle(
                    fontSize: TypographyTokens.microSize,
                    color: ColorTokens.errorDestructive,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Large full-width environment + surface tiles for the queue screen header.
class _EnvironmentSurfaceBar extends StatelessWidget {
  final EnvironmentType? environmentType;
  final SurfaceType? surfaceType;
  final VoidCallback onEnvironmentTap;
  final VoidCallback onSurfaceTap;

  const _EnvironmentSurfaceBar({
    required this.environmentType,
    required this.surfaceType,
    required this.onEnvironmentTap,
    required this.onSurfaceTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutdoor = environmentType != null
        ? environmentType == EnvironmentType.outdoor
        : surfaceType == SurfaceType.grass;
    final env = EnvironmentSurfaceStyles.environment(
        isOutdoor ? EnvironmentType.outdoor : EnvironmentType.indoor);
    final surf = EnvironmentSurfaceStyles.surface(surfaceType);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _BlockTile(
              label: env.label,
              icon: env.icon,
              color: env.color,
              onTap: onEnvironmentTap,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: _BlockTile(
              label: surf.label,
              icon: surf.icon,
              iconScale: surf.iconScale,
              color: surf.color,
              fillColor: surf.fillColor,
              borderColor: surf.borderColor,
              onTap: onSurfaceTap,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single large tile for environment or surface display.
class _BlockTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final double iconScale;
  final Color color;
  final Color? fillColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _BlockTile({
    required this.label,
    required this.icon,
    this.iconScale = 1.0,
    required this.color,
    this.fillColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.sm + 2,
        ),
        decoration: BoxDecoration(
          color: fillColor ?? color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border:
              Border.all(color: borderColor ?? color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20 * iconScale, color: color),
            const SizedBox(width: SpacingTokens.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
