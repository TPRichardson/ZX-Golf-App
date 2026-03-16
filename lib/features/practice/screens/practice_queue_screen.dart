// Phase 4 — Practice Queue Screen.
// S13 §13.3 — Queue view: list practice entries, add/remove/reorder drills,
// start sessions, end practice block.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';
import 'package:zx_golf_app/core/widgets/zx_app_bar.dart';
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
import 'package:zx_golf_app/providers/sync_providers.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/features/drill/active_drills_screen.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/practice/practice_router.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';
import 'package:zx_golf_app/features/practice/screens/practice_summary_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/practice_entry_card.dart';
import 'package:zx_golf_app/features/practice/widgets/practice_stats_bar.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/database_providers.dart';
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
  DateTime? _startTimestamp;
  EnvironmentType? _environmentType;
  SurfaceType? _surfaceType;
  final _scrollController = ScrollController();

  /// Key for the UP NEXT divider to scroll to.
  final _upNextKey = GlobalKey();

  /// Whether the next build should scroll to the UP NEXT divider.
  bool _needsScrollToUpNext = true;

  /// Cached session scores loaded from EventLog metadata.
  final _sessionScores = <String, double>{};
  final _scoreLoadPending = <String>{};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll so the UP NEXT divider sits just below one visible completed drill.
  void _scrollToUpNext() {
    if (!_needsScrollToUpNext) return;
    _needsScrollToUpNext = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final keyContext = _upNextKey.currentContext;
      if (keyContext != null) {
        Scrollable.ensureVisible(
          keyContext,
          duration: MotionTokens.standard,
          curve: Curves.easeInOut,
          // 0.1 ≈ leaves room for one completed card above the divider.
          alignment: 0.1,
        );
      }
    });
  }

  /// Request a scroll to UP NEXT on the next build frame.
  void _requestScrollToUpNext() {
    _needsScrollToUpNext = true;
  }

  /// Load scores for completed sessions from EventLog, then rebuild.
  void _loadSessionScoresIfNeeded(List<PracticeEntryWithDrill> completed) {
    final sessionIds = completed
        .where((e) => e.session != null)
        .map((e) => e.session!.sessionId)
        .where((id) => !_sessionScores.containsKey(id) && !_scoreLoadPending.contains(id))
        .toSet();
    if (sessionIds.isEmpty) return;

    _scoreLoadPending.addAll(sessionIds);
    _doLoadScores(sessionIds);
  }

  Future<void> _doLoadScores(Set<String> sessionIds) async {
    final db = ref.read(databaseProvider);
    final logs = await (db.select(db.eventLogs)
          ..where((t) => t.eventTypeId.equals('SessionCompletion')))
        .get();

    bool found = false;
    for (final log in logs) {
      if (log.affectedEntityIds == null || log.metadata == null) continue;
      try {
        final entityIds = jsonDecode(log.affectedEntityIds!) as List;
        for (final id in sessionIds) {
          if (entityIds.contains(id)) {
            final meta = jsonDecode(log.metadata!) as Map<String, dynamic>;
            final score = (meta['sessionScore'] as num?)?.toDouble();
            if (score != null) {
              _sessionScores[id] = score;
              found = true;
            }
          }
        }
      } catch (_) {}
    }

    _scoreLoadPending.removeAll(sessionIds);
    if (found && mounted) setState(() {});
  }

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
        builder: (_) => ActiveDrillsScreen(
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
      _requestScrollToUpNext();
    }
  }

  Future<void> _removePendingEntry(String entryId) async {
    await ref.read(practiceRepositoryProvider).removePendingEntry(entryId);
  }

  /// View the summary for a completed session.
  /// Looks up the session score from the EventLog metadata.
  Future<void> _viewCompletedSession(PracticeEntryWithDrill ewd) async {
    double? score;
    bool integrityBreach = false;

    // Look up SessionCompletion event log for this session's score.
    final db = ref.read(databaseProvider);
    final logs = await (db.select(db.eventLogs)
          ..where((t) => t.eventTypeId.equals('SessionCompletion'))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .get();

    for (final log in logs) {
      if (log.affectedEntityIds != null && log.metadata != null) {
        try {
          final entityIds = jsonDecode(log.affectedEntityIds!) as List;
          if (entityIds.contains(ewd.session!.sessionId)) {
            final meta = jsonDecode(log.metadata!) as Map<String, dynamic>;
            score = (meta['sessionScore'] as num?)?.toDouble();
            integrityBreach = meta['integrityBreach'] as bool? ?? false;
            break;
          }
        } catch (_) {}
      }
    }

    if (!mounted) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PostSessionSummaryScreen(
        drill: ewd.drill,
        session: ewd.session!,
        sessionScore: score,
        integrityBreach: integrityBreach,
        practiceBlockId: widget.practiceBlockId,
        userId: widget.userId,
      ),
    ));
    if (mounted) _requestScrollToUpNext();
  }

  /// Remove a completed session entry (discard the session).
  Future<void> _removeCompletedEntry(PracticeEntryWithDrill ewd) async {
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Remove Completed Drill?',
      message: 'This will remove the completed drill from this practice block.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await ref
          .read(practiceRepositoryProvider)
          .removeCompletedEntry(ewd.entry.practiceEntryId, widget.userId);
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

    // Auto-discard session if user backed out with zero shots.
    if (mounted) {
      await _discardSessionIfEmpty(
        entryWithDrill.entry.practiceEntryId,
        session.sessionId,
      );
      _requestScrollToUpNext();
    }
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

    // Auto-discard session if user backed out with zero shots.
    if (mounted) {
      await _discardSessionIfEmpty(
        ewd.entry.practiceEntryId,
        ewd.session!.sessionId,
      );
      _requestScrollToUpNext();
    }
  }

  /// Discard a session if it has zero instances recorded.
  Future<void> _discardSessionIfEmpty(String entryId, String sessionId) async {
    final repo = ref.read(practiceRepositoryProvider);
    // Check if entry is still active (not already ended/discarded).
    final entry = await repo.getPracticeEntryById(entryId);
    if (entry == null || entry.entryType != PracticeEntryType.activeSession) {
      return;
    }
    // Check if the session has any instances.
    final currentSet = await repo.getCurrentSet(sessionId);
    if (currentSet == null) return;
    final instanceCount = await repo.getInstanceCount(currentSet.setId);
    final setCount = await repo.getSetCount(sessionId);
    // No instances across any set — discard.
    if (instanceCount == 0 && setCount <= 1) {
      await ref
          .read(practiceActionsProvider)
          .discardSession(entryId, sessionId);
    }
  }

  Future<void> _endPracticeBlock(List<PracticeEntryWithDrill> entries) async {
    if (_endingBlock) return;

    // Check for an active drill session.
    final activeEntry = entries.where(
        (e) => e.entry.entryType == PracticeEntryType.activeSession).firstOrNull;

    if (activeEntry != null) {
      // 'discard' = discard active drill and finish, 'resume' = go to drill.
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ColorTokens.surfaceModal,
          title: const Text('Active Drill In Progress',
              style: TextStyle(color: ColorTokens.textPrimary)),
          content: Text(
            '"${activeEntry.drill.name}" is still in progress. '
            'Discard it and finish practice, or resume the drill?',
            style: const TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              color: ColorTokens.textSecondary,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            SpacingTokens.md, 0, SpacingTokens.md, SpacingTokens.md,
          ),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ZxPillButton(
                  label: 'Resume Drill',
                  icon: Icons.play_arrow,
                  variant: ZxPillVariant.progress,
                  expanded: true,
                  centered: true,
                  onTap: () => Navigator.pop(ctx, 'resume'),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Row(
                  children: [
                    Expanded(
                      child: ZxPillButton(
                        label: 'Cancel',
                        icon: Icons.close,
                        variant: ZxPillVariant.tertiary,
                        expanded: true,
                        centered: true,
                        onTap: () => Navigator.pop(ctx, 'cancel'),
                      ),
                    ),
                    const SizedBox(width: SpacingTokens.sm),
                    Expanded(
                      child: ZxPillButton(
                        label: 'Discard',
                        icon: Icons.delete_outline,
                        variant: ZxPillVariant.destructive,
                        expanded: true,
                        centered: true,
                        onTap: () => Navigator.pop(ctx, 'discard'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'resume') {
        _resumeSession(activeEntry);
        return;
      }
      if (choice != 'discard') return;
      // Discard the active session before finishing.
      await ref
          .read(practiceActionsProvider)
          .discardSession(activeEntry.entry.practiceEntryId, activeEntry.session!.sessionId);
      await ref
          .read(practiceRepositoryProvider)
          .removePendingEntry(activeEntry.entry.practiceEntryId);
      if (!mounted) return;
    }

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
            'This will close the practice block. Pending drills will be discarded.',
            style: TextStyle(
              fontSize: TypographyTokens.bodyLgSize,
              color: ColorTokens.textSecondary,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            SpacingTokens.md, 0, SpacingTokens.md, SpacingTokens.md,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ZxPillButton(
                    label: 'Cancel',
                    icon: Icons.close,
                    variant: ZxPillVariant.tertiary,
                    expanded: true,
                    centered: true,
                    onTap: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Expanded(
                  child: ZxPillButton(
                    label: 'Finish',
                    icon: Icons.check_circle_outline,
                    variant: ZxPillVariant.primary,
                    expanded: true,
                    centered: true,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
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

  /// Discard only the active drill session, returning it to pending state.
  Future<void> _discardActiveSession(PracticeEntryWithDrill ewd) async {
    if (ewd.session == null) return;
    final confirmed = await showSoftConfirmation(
      context,
      title: 'Discard Active Drill?',
      message: 'This will discard the current session for "${ewd.drill.name}".',
      confirmLabel: 'Discard',
      isDestructive: true,
    );
    if (confirmed && mounted) {
      await ref
          .read(practiceActionsProvider)
          .discardSession(ewd.entry.practiceEntryId, ewd.session!.sessionId);
      // Also remove the entry from the queue (discardSession resets to pending).
      await ref
          .read(practiceRepositoryProvider)
          .removePendingEntry(ewd.entry.practiceEntryId);
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

    final bi = ref.watch(syncBannerInputProvider);
    final isAuthenticated = bi.isAuthenticated;

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        bottom: false,
        child: pbStream.when(
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

          // Cache values for the header bar.
          if (_startTimestamp != pb.startTimestamp ||
              _environmentType != pb.environmentType ||
              _surfaceType != pb.surfaceType) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _startTimestamp = pb.startTimestamp;
                  _environmentType = pb.environmentType;
                  _surfaceType = pb.surfaceType;
                });
              }
            });
          }

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
              ZxShellTopBar(
                onHomeTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                isAuthenticated: isAuthenticated,
              ),
              // Practice header bar — title, clock, environment/surface.
              Container(
                width: double.infinity,
                color: ColorTokens.surfacePrimary,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SpacingTokens.md, SpacingTokens.sm, SpacingTokens.md, 0,
                      ),
                      child: Row(
                        children: [
                          if (_startTimestamp != null)
                            _ElapsedTimeBadge(startTimestamp: _startTimestamp!),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Practice',
                                style: TextStyle(
                                  fontSize: TypographyTokens.headerSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          if (_startTimestamp != null)
                            const SizedBox(width: 72),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                      child: PracticeStatsBar(
                        environmentType: _environmentType,
                        surfaceType: _surfaceType,
                        onEnvironmentTap: () => _changeEnvironment(_surfaceType),
                        onSurfaceTap: () => _changeSurface(_environmentType),
                      ),
                    ),
                  ],
                ),
              ),
              // Entry list or empty state.
              Expanded(
                child: entries.isEmpty
                    ? _buildEmptyState()
                    : _buildEntryList(completed, pending),
              ),
              // Bottom action bar — always visible.
              _buildBottomBar(entries, pending),
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
    // Check if there's an active session — drives prominent display.
    final hasActive = pending.any(
        (e) => e.entry.entryType == PracticeEntryType.activeSession);

    // Load scores for completed sessions.
    if (completed.isNotEmpty) _loadSessionScoresIfNeeded(completed);

    // Auto-scroll to UP NEXT divider when completed drills exist.
    if (completed.isNotEmpty && pending.isNotEmpty) _scrollToUpNext();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.lg,
        vertical: SpacingTokens.md,
      ),
      children: [
        // Completed section.
        for (final ewd in completed)
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
            child: Opacity(
              opacity: hasActive ? 0.2 : 0.5,
              child: PracticeEntryCard(
                entryWithDrill: ewd,
                sessionScore: ewd.session != null
                    ? _sessionScores[ewd.session!.sessionId]
                    : null,
                onTap: hasActive || ewd.session == null
                    ? null
                    : () => _viewCompletedSession(ewd),
                onRemove: hasActive ? null : () => _removeCompletedEntry(ewd),
              ),
            ),
          ),
        // UP NEXT divider.
        if (pending.isNotEmpty)
          Padding(
            key: _upNextKey,
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
                    hasActive ? 'In Progress' : 'Up Next',
                    style: TextStyle(
                      fontSize: TypographyTokens.headerSize,
                      fontWeight: FontWeight.w600,
                      color: hasActive
                          ? ColorTokens.primaryDefault
                          : ColorTokens.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: hasActive
                        ? ColorTokens.primaryDefault.withValues(alpha: 0.3)
                        : ColorTokens.surfaceBorder,
                  ),
                ),
              ],
            ),
          ),
        // Pending / active section.
        for (final ewd in pending)
          _buildPendingEntry(ewd, hasActive),
        // Add Routine / Add Drills — only when no drill is active.
        if (!hasActive)
          Padding(
            padding: const EdgeInsets.only(top: SpacingTokens.md),
            child: Row(
              children: [
                Expanded(child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'saveAsRoutine') {
                      _saveAsRoutine([...completed, ...pending]);
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
                Expanded(
                  child: ZxPillButton(
                    label: 'Add Drills',
                    icon: Icons.playlist_add,
                    variant: ZxPillVariant.secondary,
                    expanded: true,
                    centered: true,
                    onTap: _addDrill,
                  ),
                ),
              ],
            ),
          ),
        // Bottom spacer ensures UP NEXT stays in a consistent position
        // even when there aren't enough pending drills to fill the screen.
        SizedBox(height: MediaQuery.of(context).size.height * 0.5),
      ],
    );
  }

  Widget _buildPendingEntry(PracticeEntryWithDrill ewd, bool hasActive) {
    final isActive = ewd.entry.entryType == PracticeEntryType.activeSession;
    final isDimmed = hasActive && !isActive;

    final card = PracticeEntryCard(
      entryWithDrill: ewd,
      onTap: ewd.entry.entryType == PracticeEntryType.pendingDrill
          ? () => _startSession(ewd)
          : isActive
              ? () => _resumeSession(ewd)
              : null,
      onRemove: ewd.entry.entryType == PracticeEntryType.pendingDrill && !hasActive
          ? () => _removePendingEntry(ewd.entry.practiceEntryId)
          : null,
    );

    if (isActive) {
      // Prominent active drill — extra spacing above and below.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
        child: card,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.sm),
      child: Opacity(
        opacity: isDimmed ? 0.2 : 1.0,
        child: card,
      ),
    );
  }

  Widget _buildBottomBar(List<PracticeEntryWithDrill> entries, List<PracticeEntryWithDrill> pending) {
    final activeEntry = pending.where(
        (e) => e.entry.entryType == PracticeEntryType.activeSession).firstOrNull;
    final hasActive = activeEntry != null;
    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfacePrimary,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Resume Active Drill — only shown when a drill is active.
          if (hasActive) ...[
            ZxPillButton(
              label: 'Resume Active Drill',
              icon: Icons.play_arrow,
              variant: ZxPillVariant.progress,
              expanded: true,
              centered: true,
              onTap: () => _resumeSession(activeEntry),
            ),
            const SizedBox(height: SpacingTokens.sm),
          ],
          // Settings + Next Drill / Discard Active row.
          Row(
            children: [
              if (!hasActive) ...[
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Practice settings coming soon')),
                    );
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: ColorTokens.textTertiary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                      border: Border.all(
                        color: ColorTokens.textTertiary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(Icons.settings_outlined,
                        size: 24,
                        color: ColorTokens.textTertiary),
                  ),
                ),
                const SizedBox(width: SpacingTokens.sm),
              ],
              if (hasActive)
                Expanded(
                  child: ZxPillButton(
                    label: 'Discard Active Drill',
                    icon: Icons.delete_outline,
                    variant: ZxPillVariant.destructive,
                    expanded: true,
                    centered: true,
                    onTap: () => _discardActiveSession(activeEntry),
                  ),
                )
              else if (pending.where(
                  (e) => e.entry.entryType == PracticeEntryType.pendingDrill).isNotEmpty)
                Expanded(
                  child: ZxPillButton(
                    label: 'Next Drill',
                    icon: Icons.play_arrow,
                    variant: ZxPillVariant.progress,
                    expanded: true,
                    centered: true,
                    onTap: () => _startSession(pending.firstWhere(
                        (e) => e.entry.entryType == PracticeEntryType.pendingDrill)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.sm),
          // Finish Practice + Discard row.
          Row(
            children: [
              GestureDetector(
                onTap: _discardPracticeBlock,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: ColorTokens.errorDestructive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                    border: Border.all(
                      color: ColorTokens.errorDestructive.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(Icons.delete_outline,
                      size: 24,
                      color: ColorTokens.errorDestructive),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: ZxPillButton(
                  label: 'Finish Practice',
                  icon: Icons.check_circle_outline,
                  variant: ZxPillVariant.primary,
                  expanded: true,
                  centered: true,
                  isLoading: _endingBlock,
                  onTap: _endingBlock
                      ? null
                      : () => _endPracticeBlock(entries),
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
        Icon(Icons.timer_outlined, size: 16, color: ColorTokens.textTertiary),
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

