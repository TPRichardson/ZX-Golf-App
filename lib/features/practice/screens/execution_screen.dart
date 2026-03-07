// Unified execution screen for all instance-recording input modes.
// Replaces GridCellScreen, BinaryHitMissScreen, ContinuousMeasurementScreen,
// and RawDataEntryScreen with a single host + swappable input delegate.
// TechniqueBlockScreen remains separate (timer-based, no per-instance recording).

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/execution/execution_helpers.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/binary_hit_miss_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/continuous_measurement_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/grid_cell_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/raw_data_entry_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';
import 'package:zx_golf_app/features/practice/widgets/bulk_entry_dialog.dart';
import 'package:zx_golf_app/features/practice/widgets/club_selector.dart';
import 'package:zx_golf_app/features/practice/widgets/execution_header.dart';
import 'package:zx_golf_app/features/practice/widgets/set_transition_overlay.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

/// Unified execution screen for grid, binary, continuous, and raw input modes.
class ExecutionScreen extends ConsumerStatefulWidget {
  final Drill drill;
  final Session session;
  final String userId;

  const ExecutionScreen({
    super.key,
    required this.drill,
    required this.session,
    required this.userId,
  });

  @override
  ConsumerState<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  late SessionExecutionController _controller;
  late ExecutionInputDelegate _delegate;
  bool _initialized = false;
  bool _ending = false;
  late SurfaceType? _surfaceType = widget.session.surfaceType;
  String _selectedClub = 'Putter';
  List<String> _availableClubs = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _delegate = _createDelegate();
    _initController();
  }

  ExecutionInputDelegate _createDelegate() {
    return switch (widget.drill.inputMode) {
      InputMode.gridCell => GridCellDelegate(drill: widget.drill),
      InputMode.binaryHitMiss => BinaryHitMissDelegate(),
      InputMode.continuousMeasurement => ContinuousMeasurementDelegate(),
      InputMode.rawDataEntry => RawDataEntryDelegate(),
    };
  }

  Future<void> _initController() async {
    _controller = SessionExecutionController(
      repository: ref.read(practiceRepositoryProvider),
      session: widget.session,
      drill: widget.drill,
    );
    await _controller.initialize();
    await _loadClubs();
    if (mounted) setState(() => _initialized = true);
  }

  // TD-06 §9.1.2 — Load clubs for this drill's skill area.
  Future<void> _loadClubs() async {
    final mode = widget.drill.clubSelectionMode;
    if (mode == null) {
      _selectedClub = 'Putter';
      return;
    }
    final clubs = await ref
        .read(clubsForSkillAreaProvider(
            (widget.userId, widget.drill.skillArea))
            .future);
    final names = clubs.map((c) => c.clubType.dbValue).toList();
    _availableClubs = names;
    if (names.isNotEmpty) {
      _selectedClub = mode == ClubSelectionMode.random
          ? names[_random.nextInt(names.length)]
          : names.first;
    }
  }

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  /// Unified instance-logging pipeline. Delegates call this via the
  /// LogInstanceCallback. Handles haptics, club rotation, timer reset,
  /// delegate notification, and set auto-advance.
  Future<InstanceResult> _onLogInstance(InstancesCompanion data) async {
    if (!_initialized || _ending) {
      final now = DateTime.now();
      return InstanceResult(
        instance: Instance(
          instanceId: '',
          setId: '',
          selectedClub: '',
          rawMetrics: '{}',
          timestamp: now,
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // S15 §15.8.3 — Haptic tick.
    HapticFeedback.lightImpact();

    // TD-06 §9.1.2 — Random mode picks a new club per instance.
    if (widget.drill.clubSelectionMode == ClubSelectionMode.random &&
        _availableClubs.isNotEmpty) {
      _selectedClub =
          _availableClubs[_random.nextInt(_availableClubs.length)];
    }

    final result = await _controller.logInstance(data);

    // Reset inactivity timer.
    ref.read(timerServiceProvider).resetSessionInactivityTimer(
          widget.session.sessionId,
          const Duration(hours: 2),
        );

    _delegate.onInstanceLogged(result, data);
    setState(() {});

    // S13 §13.7 — Auto-advance set if structured.
    await _handlePostInstanceAdvance();

    return result;
  }

  /// Unified bulk-add pipeline. The `requestedCount` param from the delegate
  /// is ignored — we show the bulk entry dialog here.
  Future<void> _onBulkAdd(
    int _,
    InstancesCompanion Function(int index) builder,
  ) async {
    if (!_initialized || _ending) return;

    final count = await showBulkEntryDialog(
      context,
      maxCount: _controller.remainingSetCapacity,
    );
    if (count == null || count <= 0) return;

    final added = await _controller.logBulkInstances(count, builder);

    // Notify delegate about each bulk instance for counter updates.
    for (var i = 0; i < added; i++) {
      final sampleData = builder(i);
      final now = DateTime.now();
      _delegate.onInstanceLogged(
        InstanceResult(
          instance: Instance(
            instanceId: '',
            setId: '',
            selectedClub: '',
            rawMetrics: sampleData.rawMetrics.value,
            timestamp: now,
            isDeleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        sampleData,
      );
    }

    if (!mounted) return;
    setState(() {});

    await _handlePostInstanceAdvance();
  }

  /// S13 §13.7 — Check and handle set/session auto-completion.
  Future<void> _handlePostInstanceAdvance() async {
    if (_controller.isCurrentSetComplete()) {
      if (_controller.isSessionAutoComplete()) {
        await _endSession();
      } else {
        if (mounted) {
          await SetTransitionOverlay.show(context,
              completedSetIndex: _controller.currentSetIndex);
        }
        await _controller.advanceSet();
        if (mounted) setState(() {});
      }
    }
  }

  /// S14 §14.10 — Undo the last logged instance.
  Future<void> _undoLast() async {
    final deleted = await _controller.undoLastInstance();
    _delegate.onInstanceUndone(deleted);
    if (mounted) setState(() {});
  }

  Future<void> _endSession() async {
    if (_ending) return;
    setState(() => _ending = true);
    await endSessionAndNavigate(context, ref,
        session: widget.session,
        drill: widget.drill,
        userId: widget.userId);
  }

  Future<void> _changeSurface() async {
    final newSurface = await changeSurface(context, ref,
        sessionId: widget.session.sessionId);
    if (newSurface != null && mounted) {
      setState(() => _surfaceType = newSurface);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: ColorTokens.surfaceBase,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Gap 39–42 — Disable submission while scoring lock is held.
    final isLocked =
        ref.watch(scoringLockActiveProvider).valueOrNull ?? false;

    final executionContext = ExecutionContext(
      isLocked: isLocked,
      isEnding: _ending,
      selectedClub: _selectedClub,
      currentSetId: _controller.currentSetId,
    );

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            ExecutionHeader(
              drill: widget.drill,
              currentSetIndex: _controller.currentSetIndex,
              requiredSetCount: _controller.requiredSetCount,
              currentInstanceCount: _controller.currentSetInstanceCount,
              requiredAttemptsPerSet: _controller.requiredAttemptsPerSet,
            ),
            // TD-06 §9.1.2 — Club selector (hidden for putting).
            if (widget.drill.clubSelectionMode != null &&
                _availableClubs.isNotEmpty)
              ClubSelector(
                mode: widget.drill.clubSelectionMode!,
                availableClubs: _availableClubs,
                selectedClub: _selectedClub,
                onClubSelected: (club) =>
                    setState(() => _selectedClub = club),
              ),
            // Gap 42 — Inline lock indicator.
            if (isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md),
                child: Text(
                  'Updating scores\u2026',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    color: ColorTokens.textTertiary,
                  ),
                ),
              ),
            // Input area — varies by delegate.
            Expanded(
              child: _delegate.buildInputArea(
                context: context,
                executionContext: executionContext,
                onLogInstance: _onLogInstance,
                requestRebuild: () => setState(() {}),
              ),
            ),
            _buildBottomBar(executionContext),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(ExecutionContext executionContext) {
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
          Row(
            children: [
              // S14 §14.10 — Undo last instance.
              if (_controller.canUndo)
                TextButton.icon(
                  onPressed: _undoLast,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Undo'),
                ),
              // Delegate-specific bulk add buttons.
              ..._delegate.buildBottomBarActions(
                context: context,
                executionContext: executionContext,
                onBulkAdd: _onBulkAdd,
              ),
              const Spacer(),
              if (!_controller.isStructured)
                FilledButton(
                  onPressed: _endSession,
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorTokens.primaryDefault,
                  ),
                  child: const Text('End Drill'),
                ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: SurfaceBadge(
              surfaceType: _surfaceType,
              onTap: _changeSurface,
            ),
          ),
        ],
      ),
    );
  }
}
