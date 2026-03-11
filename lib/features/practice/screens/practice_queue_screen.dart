// Phase 4 — Practice Queue Screen.
// S13 §13.3 — Queue view: list practice entries, add/remove/reorder drills,
// start sessions, end practice block.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/features/drill/practice_pool_screen.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/screens/practice_summary_screen.dart';
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
    // Compute existing block stats for pick mode info bar.
    final pbData = ref.read(
        practiceBlockWithEntriesProvider(widget.practiceBlockId)).valueOrNull;
    int existDrills = 0;
    int existSets = 0;
    int existShots = 0;
    if (pbData != null) {
      existDrills = pbData.entries.length;
      for (final e in pbData.entries) {
        existSets += e.drill.requiredSetCount;
        existShots += e.drill.requiredSetCount *
            (e.drill.requiredAttemptsPerSet ?? 0);
      }
    }

    final drillIds = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => PracticePoolScreen(
          pickMode: true,
          existingDrillCount: existDrills,
          existingSets: existSets,
          existingShots: existShots,
        ),
      ),
    );
    if (drillIds != null && drillIds.isNotEmpty && mounted) {
      final repo = ref.read(practiceRepositoryProvider);
      for (final drillId in drillIds) {
        await repo.addDrillToQueue(widget.practiceBlockId, drillId);
      }
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

  Future<void> _endPracticeBlock(List<PracticeEntryWithDrill> entries) async {
    if (_endingBlock) return;

    final hasPending = entries.any(
        (e) => e.entry.entryType == PracticeEntryType.pendingDrill);

    if (hasPending) {
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
    }

    setState(() => _endingBlock = true);

    // Capture start timestamp before ending (block may become unavailable).
    final pbData = ref.read(
        practiceBlockWithEntriesProvider(widget.practiceBlockId)).valueOrNull;
    final startTimestamp = pbData?.practiceBlock.startTimestamp ?? DateTime.now();

    final actions = ref.read(practiceActionsProvider);
    await actions.endPracticeBlock(widget.practiceBlockId, widget.userId);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PracticeSummaryScreen(
            practiceBlockId: widget.practiceBlockId,
            startTimestamp: startTimestamp,
          ),
        ),
      );
    }
  }

  Future<void> _discardPracticeBlock() async {
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Discard Practice?',
      message: 'This will discard the entire practice block and all sessions.',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (confirmed && mounted) {
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
          _ElapsedTimeBadge(
            startTimestamp: pbStream.valueOrNull?.practiceBlock.startTimestamp ??
                DateTime.now(),
          ),
          const SizedBox(width: SpacingTokens.sm),
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
              // Stats bar — clock, environment, surface, weather, location.
              PracticeStatsBar(
                environmentType: pb.environmentType,
                surfaceType: pb.surfaceType,
                onEnvironmentTap: () => _changeEnvironment(pb.surfaceType),
                onSurfaceTap: () => _changeSurface(pb.environmentType),
              ),
              // Entry list or empty state.
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyState()
                    : _buildEntryList(completed, pending),
              ),
              // Bottom action bar — always visible.
              _buildBottomBar(entries),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add a drill to start practice.',
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: ColorTokens.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.lg),
            ZxPillButton(
              label: 'Add Drills',
              icon: Icons.playlist_add,
              variant: ZxPillVariant.primary,
              onTap: _addDrill,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryList(
    List<PracticeEntryWithDrill> completed,
    List<PracticeEntryWithDrill> pending,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.md,
      ),
      children: [
        // Completed section.
        if (completed.isNotEmpty)
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
        // UP NEXT divider — always shown when there are pending drills.
        if (pending.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: completed.isNotEmpty
                        ? ColorTokens.successDefault.withValues(alpha: 0.3)
                        : ColorTokens.surfaceBorder,
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

  Widget _buildBottomBar(List<PracticeEntryWithDrill> entries) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Routines + Add Drill row.
          Row(
            children: [
              // Routines popup button.
              Expanded(child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'saveAsRoutine') {
                    _saveAsRoutine(entries);
                  } else if (value == 'importRoutine') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Import routine coming soon')),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'importRoutine',
                    child: Text('Add Routine'),
                  ),
                  PopupMenuItem(
                    value: 'saveAsRoutine',
                    child: Text('Save as Routine'),
                  ),
                ],
                child: ZxPillButton(
                  label: 'Add Routine',
                  icon: Icons.playlist_add,
                  variant: ZxPillVariant.secondary,
                  expanded: true,
                  centered: true,
                  onTap: null,
                ),
              )),
              const SizedBox(width: SpacingTokens.sm),
              // Add Drill button — cyan pill matching Routines style.
              Expanded(
                child: ZxPillButton(
                  label: 'Add Drills',
                  icon: Icons.playlist_add,
                  variant: ZxPillVariant.primary,
                  expanded: true,
                  centered: true,
                  onTap: _addDrill,
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Finish Practice — pill style matching above buttons.
          ZxPillButton(
            label: 'Finish Practice',
            icon: Icons.check_circle_outline,
            variant: ZxPillVariant.progress,
            expanded: true,
            centered: true,
            isLoading: _endingBlock,
            onTap: _endingBlock ? null : () => _endPracticeBlock(entries),
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Settings cog + Discard row.
          Row(
            children: [
              ZxPillButton(
                label: '',
                icon: Icons.settings_outlined,
                variant: ZxPillVariant.tertiary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Practice settings coming soon')),
                  );
                },
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: ZxPillButton(
                  label: 'Discard Practice',
                  icon: Icons.delete_outline,
                  variant: ZxPillVariant.destructive,
                  centered: true,
                  iconRight: true,
                  onTap: _discardPracticeBlock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Live elapsed time shown in the app bar.
class _ElapsedTimeBadge extends StatefulWidget {
  final DateTime startTimestamp;

  const _ElapsedTimeBadge({required this.startTimestamp});

  @override
  State<_ElapsedTimeBadge> createState() => _ElapsedTimeBadgeState();
}

class _ElapsedTimeBadgeState extends State<_ElapsedTimeBadge> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    setState(() {
      _elapsed = DateTime.now().difference(widget.startTimestamp);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 14, color: ColorTokens.textTertiary),
        const SizedBox(width: SpacingTokens.xs),
        Text(
          _formatElapsed(_elapsed),
          style: TextStyle(
            fontSize: TypographyTokens.bodySize,
            fontWeight: FontWeight.w500,
            color: ColorTokens.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

