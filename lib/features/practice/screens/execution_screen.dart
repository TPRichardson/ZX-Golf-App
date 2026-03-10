// Unified execution screen for all instance-recording input modes.
// Replaces GridCellScreen, BinaryHitMissScreen, ContinuousMeasurementScreen,
// and RawDataEntryScreen with a single host + swappable input delegate.
// TechniqueBlockScreen remains separate (timer-based, no per-instance recording).

import 'dart:convert';
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
import 'package:zx_golf_app/features/practice/widgets/club_grid_picker.dart';
import 'package:zx_golf_app/features/practice/widgets/execution_header.dart';
import 'package:zx_golf_app/features/practice/widgets/practice_stats_bar.dart';
import 'package:zx_golf_app/features/practice/widgets/set_transition_overlay.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

/// Tracked shot entry for the shot log.
class _ShotEntry {
  final String label;
  final bool isHit;
  final String club;
  final double? score;

  const _ShotEntry({
    required this.label,
    required this.isHit,
    required this.club,
    this.score,
  });
}

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
  EnvironmentType? _environmentType;
  String _selectedClub = 'Putter';
  List<String> _availableClubs = [];
  final _random = Random();
  final List<_ShotEntry> _shotLog = [];
  final _shotListController = ScrollController();

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
    // Load environment type from practice block.
    final block = await ref
        .read(practiceRepositoryProvider)
        .getPracticeBlockById(widget.session.practiceBlockId);
    _environmentType = block?.environmentType;
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
    _shotListController.dispose();
    super.dispose();
  }

  /// Parse a shot entry from instance data for the shot log.
  _ShotEntry _parseShotEntry(InstancesCompanion data, InstanceResult result) {
    final metrics =
        jsonDecode(data.rawMetrics.value) as Map<String, dynamic>;
    // Grid or binary — has 'hit' field.
    if (metrics.containsKey('hit')) {
      final isHit = metrics['hit'] as bool;
      final label =
          metrics['label'] as String? ?? (isHit ? 'Hit' : 'Miss');
      return _ShotEntry(
        label: label,
        isHit: isHit,
        club: data.selectedClub.value,
        score: result.realtimeScore,
      );
    }
    // Raw/continuous — has 'value' field.
    if (metrics.containsKey('value')) {
      final value = (metrics['value'] as num).toDouble();
      return _ShotEntry(
        label: value.toStringAsFixed(1),
        isHit: (result.realtimeScore ?? 0) >= 2.5,
        club: data.selectedClub.value,
        score: result.realtimeScore,
      );
    }
    return _ShotEntry(
      label: '\u2014',
      isHit: false,
      club: data.selectedClub.value,
    );
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

    // Add to shot log.
    _shotLog.add(_parseShotEntry(data, result));

    // Reset inactivity timer.
    ref.read(timerServiceProvider).resetSessionInactivityTimer(
          widget.session.sessionId,
          const Duration(hours: 2),
        );

    _delegate.onInstanceLogged(result, data);
    setState(() {});

    // Auto-scroll shot list to bottom.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shotListController.hasClients) {
        _shotListController.animateTo(
          _shotListController.position.maxScrollExtent,
          duration: MotionTokens.fast,
          curve: Curves.easeInOut,
        );
      }
    });

    // S13 §13.7 — Auto-advance set if structured.
    await _handlePostInstanceAdvance();

    return result;
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
        // Clear shot log for new set.
        _shotLog.clear();
        if (mounted) setState(() {});
      }
    }
  }

  /// S14 §14.10 — Undo the last logged instance.
  Future<void> _undoLast() async {
    final deleted = await _controller.undoLastInstance();
    _delegate.onInstanceUndone(deleted);
    if (_shotLog.isNotEmpty) _shotLog.removeLast();
    if (mounted) setState(() {});
  }

  Future<void> _endSession() async {
    if (_ending) return;
    setState(() => _ending = true);
    await endSessionAndNavigate(context, ref,
        session: widget.session,
        drill: widget.drill,
        userId: widget.userId,
        practiceBlockId: widget.session.practiceBlockId);
  }

  /// Change environment type — updates practice block only.
  Future<void> _changeEnvironment() async {
    final env = await showEnvironmentPicker(context);
    if (env == null || !mounted) return;
    await ref.read(practiceRepositoryProvider).updateBlockEnvironmentAndSurface(
          widget.session.practiceBlockId,
          environmentType: env,
          surfaceType: _surfaceType ?? SurfaceType.mat,
        );
    setState(() => _environmentType = env);
  }

  /// Change surface type — updates both session and practice block.
  Future<void> _changeSurfaceType() async {
    final surface = await showSurfacePicker(context);
    if (surface == null || !mounted) return;
    await ref.read(practiceRepositoryProvider).updateBlockEnvironmentAndSurface(
          widget.session.practiceBlockId,
          environmentType: _environmentType ?? EnvironmentType.indoor,
          surfaceType: surface,
        );
    await ref
        .read(practiceRepositoryProvider)
        .updateSessionSurface(widget.session.sessionId, surface);
    setState(() => _surfaceType = surface);
  }

  /// Open club grid picker for user-led/guided modes.
  Future<void> _pickClub() async {
    final club = await showClubGridPicker(
      context,
      clubs: _availableClubs,
      selectedClub: _selectedClub,
      skillArea: widget.drill.skillArea,
      userId: widget.userId,
    );
    if (club != null && mounted) {
      setState(() => _selectedClub = club);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: ColorTokens.surfaceBase,
        appBar: ExecutionHeader(
          drill: widget.drill,
          currentSetIndex: 0,
          requiredSetCount: widget.drill.requiredSetCount,
          currentInstanceCount: 0,
          requiredAttemptsPerSet: widget.drill.requiredAttemptsPerSet,
        ),
        body: const Center(child: CircularProgressIndicator()),
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
      appBar: ExecutionHeader(
        drill: widget.drill,
        currentSetIndex: _controller.currentSetIndex,
        requiredSetCount: _controller.requiredSetCount,
        currentInstanceCount: _controller.currentSetInstanceCount,
        requiredAttemptsPerSet: _controller.requiredAttemptsPerSet,
      ),
      body: Column(
          children: [
            // Environment / Surface / Location bar.
            PracticeStatsBar(
              environmentType: _environmentType,
              surfaceType: _surfaceType,
              onEnvironmentTap: _changeEnvironment,
              onSurfaceTap: _changeSurfaceType,
            ),
            const SizedBox(height: SpacingTokens.sm),
            // Shot log + Club square section.
            _buildShotLogSection(),
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
            _buildBottomBar(),
          ],
        ),
    );
  }

  /// Shot log (left) + club square (right) section.
  Widget _buildShotLogSection() {
    final hasClubSelection = widget.drill.clubSelectionMode != null &&
        _availableClubs.isNotEmpty;
    final hitCount = _shotLog.where((s) => s.isHit).length;
    final totalCount = _shotLog.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg, SpacingTokens.xs, SpacingTokens.lg, 0,
      ),
      child: SizedBox(
      height: 128,
      child: Row(
        children: [
          // Shot log (left — 2/3 width).
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                border: Border.all(color: ColorTokens.surfaceBorder),
              ),
                child: Column(
              children: [
                // Scrollable shot list.
                Expanded(
                  child: _shotLog.isEmpty
                      ? Center(
                          child: Text(
                            'No shots recorded',
                            style: TextStyle(
                              fontSize: TypographyTokens.microSize,
                              color: ColorTokens.textTertiary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _shotListController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.md,
                            vertical: SpacingTokens.xs,
                          ),
                          itemCount: _shotLog.length,
                          itemBuilder: (context, index) {
                            final shot = _shotLog[index];
                            return _ShotLogRow(
                              index: index + 1,
                              shot: shot,
                            );
                          },
                        ),
                ),
                // Shot count + undo row.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SpacingTokens.md + 20, 0, SpacingTokens.md, 0,
                  ),
                  child: SizedBox(
                    height: 24,
                    child: Stack(
                      children: [
                        // Hits (left) + Undo (right).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$hitCount',
                                    style: TextStyle(
                                      fontSize: TypographyTokens.microSize,
                                      fontWeight: FontWeight.w500,
                                      color: ColorTokens.successDefault,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/$totalCount',
                                    style: TextStyle(
                                      fontSize: TypographyTokens.microSize,
                                      fontWeight: FontWeight.w500,
                                      color: ColorTokens.textSecondary,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (totalCount > 0)
                              Text(
                                ' hits',
                                style: TextStyle(
                                  fontSize: TypographyTokens.microSize,
                                  color: ColorTokens.textTertiary,
                                ),
                              ),
                            const Spacer(),
                            GestureDetector(
                                onTap: _controller.canUndo ? _undoLast : null,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.undo, size: 14,
                                        color: _controller.canUndo
                                            ? ColorTokens.textTertiary
                                            : ColorTokens.surfaceRaised),
                                    const SizedBox(width: SpacingTokens.xs),
                                    Text(
                                      'Undo',
                                      style: TextStyle(
                                        fontSize: TypographyTokens.microSize,
                                        color: _controller.canUndo
                                            ? ColorTokens.textTertiary
                                            : ColorTokens.surfaceRaised,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        // Set counter — always centered horizontally, aligned with row text.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Set ${_controller.currentSetIndex + 1}/${_controller.requiredSetCount}',
                                style: TextStyle(
                                  fontSize: TypographyTokens.microSize,
                                  color: ColorTokens.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          // Club square (right — 1/3 width).
          Expanded(
            child: _buildClubSquare(canChange: hasClubSelection),
          ),
        ],
      ),
      ),
    );
  }

  /// Abbreviate club name for the square display.
  static String _abbreviateClub(String name) {
    const abbreviations = {
      'Driver': 'Dr',
      'Putter': 'Pt',
      'Chipper': 'Ch',
    };
    return abbreviations[name] ?? name;
  }

  /// Large tappable club square — tap to open grid picker.
  Widget _buildClubSquare({bool canChange = true}) {
    final isRandom =
        widget.drill.clubSelectionMode == ClubSelectionMode.random;
    final isTappable = canChange && !isRandom;

    return GestureDetector(
      onTap: isTappable ? _pickClub : null,
      child: Container(
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Stack(
          children: [
            // Label pinned 4px from top.
            Positioned(
              left: 0,
              right: 0,
              top: SpacingTokens.xs,
              child: Text(
                'Active Club',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: TypographyTokens.microSize,
                  fontWeight: FontWeight.w500,
                  color: ColorTokens.textPrimary,
                ),
              ),
            ),
            // Club text centered.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: SpacingTokens.xs),
                    child: Text(
                      _abbreviateClub(_selectedClub),
                      style: TextStyle(
                        fontSize: TypographyTokens.displayXlSize,
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.primaryDefault,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isRandom) ...[
                    const SizedBox(height: SpacingTokens.xs),
                    Text(
                      'Random',
                      style: TextStyle(
                        fontSize: TypographyTokens.microSize,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_controller.isStructured) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.sm,
      ),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: FilledButton(
        onPressed: _endSession,
        style: FilledButton.styleFrom(
          backgroundColor: ColorTokens.primaryDefault,
        ),
        child: const Text('End Drill'),
      ),
    );
  }
}

/// Single row in the shot log.
class _ShotLogRow extends StatelessWidget {
  final int index;
  final _ShotEntry shot;

  const _ShotLogRow({required this.index, required this.shot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          // Shot number.
          SizedBox(
            width: 20,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: ColorTokens.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Hit/miss indicator dot.
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shot.isHit
                  ? ColorTokens.successDefault
                  : ColorTokens.missDefault,
            ),
          ),
          const SizedBox(width: SpacingTokens.xs),
          // Result label.
          Expanded(
            child: Text(
              shot.label,
              style: TextStyle(
                fontSize: TypographyTokens.microSize,
                color: shot.isHit
                    ? ColorTokens.successDefault
                    : ColorTokens.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Club name.
          Text(
            shot.club,
            style: TextStyle(
              fontSize: 10,
              color: ColorTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
