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
import 'package:zx_golf_app/core/validation/club_tiers.dart';
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
import 'package:zx_golf_app/core/widgets/zx_pill_button.dart';
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

  /// Carry distances keyed by ClubType dbValue (e.g. 'i7' → 155.0).
  /// Populated during init for drills using ClubCarry targeting.
  final Map<String, double> _clubCarryDistances = {};

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
    await _loadCarryDistances();
    // Rebuild shot log from existing instances in the current set.
    await _restoreShotLog();
    // Load environment type from practice block.
    final block = await ref
        .read(practiceRepositoryProvider)
        .getPracticeBlockById(widget.session.practiceBlockId);
    _environmentType = block?.environmentType;
    if (mounted) {
      ref.read(practiceExecutionActiveProvider.notifier).state = true;
      setState(() => _initialized = true);
    }
  }

  /// Restore the shot log from persisted instances in the current set.
  Future<void> _restoreShotLog() async {
    final setId = _controller.currentSetId;
    if (setId == null) return;
    final repo = ref.read(practiceRepositoryProvider);
    final instances = await repo.watchInstancesBySet(setId).first;
    for (final inst in instances) {
      final metrics =
          jsonDecode(inst.rawMetrics) as Map<String, dynamic>;
      if (metrics.containsKey('hit')) {
        final isHit = metrics['hit'] as bool;
        final label =
            metrics['label'] as String? ?? (isHit ? 'Hit' : 'Miss');
        _shotLog.add(_ShotEntry(
          label: label,
          isHit: isHit,
          club: inst.selectedClub,
        ));
      } else if (metrics.containsKey('value')) {
        final value = (metrics['value'] as num).toDouble();
        _shotLog.add(_ShotEntry(
          label: value.toStringAsFixed(1),
          isHit: false,
          club: inst.selectedClub,
        ));
      } else {
        _shotLog.add(_ShotEntry(
          label: '\u2014',
          isHit: false,
          club: inst.selectedClub,
        ));
      }
    }
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

  /// Load carry distances for each active club in this drill's skill area.
  /// Only needed for drills using ClubCarry/PercentageOfClubCarry targeting.
  Future<void> _loadCarryDistances() async {
    final distMode = widget.drill.targetDistanceMode;
    if (distMode != TargetDistanceMode.clubCarry &&
        distMode != TargetDistanceMode.percentageOfClubCarry) {
      return;
    }
    final clubRepo = ref.read(clubRepositoryProvider);
    final clubs = await ref
        .read(clubsForSkillAreaProvider(
            (widget.userId, widget.drill.skillArea))
            .future);
    for (final club in clubs) {
      final profile = await clubRepo.getActiveProfile(club.clubId);
      if (profile?.carryDistance != null) {
        _clubCarryDistances[club.clubType.dbValue] = profile!.carryDistance!;
      }
    }
  }

  /// Get the carry distance for the currently selected club.
  double? get _currentCarryDistance => _clubCarryDistances[_selectedClub];

  /// Compute the target width for the currently selected club.
  /// Uses club tier percentage of carry distance.
  double? get _currentTargetWidth {
    final carry = _currentCarryDistance;
    if (carry == null) return null;

    // If drill specifies a fixed TargetSizeWidth, use that percentage.
    final fixedPercent = widget.drill.targetSizeWidth;
    if (fixedPercent != null) {
      return carry * fixedPercent / 100.0;
    }

    // Otherwise use club-tier banded percentage.
    if (widget.drill.targetSizeMode ==
        TargetSizeMode.percentageOfTargetDistance) {
      try {
        final clubType = ClubType.fromString(_selectedClub);
        final percent = targetWidthPercentForClub(clubType);
        return carry * percent / 100.0;
      } on ArgumentError {
        return null;
      }
    }
    return null;
  }

  @override
  void dispose() {
    ref.read(practiceExecutionActiveProvider.notifier).state = false;
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
          onInfoTap: widget.drill.description != null
              ? () => _showDrillInfo(context)
              : null,
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
        onInfoTap: widget.drill.description != null
            ? () => _showDrillInfo(context)
            : null,
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
            // Shot log + Club bar section (~2/3 of remaining space).
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
            // Input area — varies by delegate (~65% of remaining space).
            // Target width bar sits just above the input for 1x3/3x3 grids.
            // For 3x1 grids, a vertical target depth bar sits on the left.
            Expanded(
              flex: 65,
              child: Column(
                children: [
                  // Target width indicator bar (horizontal, for 1x3/3x3 grids).
                  _buildTargetWidthBar(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _wrapWithVerticalTargetBar(
                      _delegate.buildInputArea(
                        context: context,
                        executionContext: executionContext,
                        onLogInstance: _onLogInstance,
                        requestRebuild: () => setState(() {}),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
    );
  }

  /// Club bar (full width) + shot log (full width) stacked section.
  /// Uses Expanded so the input area below gets ~1/3 of the screen.
  Widget _buildShotLogSection() {
    final hasClubSelection = widget.drill.clubSelectionMode != null &&
        _availableClubs.isNotEmpty;
    final hitCount = _shotLog.where((s) => s.isHit).length;
    final totalCount = _shotLog.length;

    return Expanded(
      flex: 35,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.lg, SpacingTokens.xs, SpacingTokens.lg, 0,
        ),
        child: Column(
          children: [
            // Club bar (full width, doubled size).
            _buildClubBar(canChange: hasClubSelection),
            const SizedBox(height: SpacingTokens.sm),
            // Shot log (fills remaining space).
            Expanded(
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
                                  fontSize: TypographyTokens.bodyLgSize,
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
                        SpacingTokens.md, 0, SpacingTokens.md, SpacingTokens.sm,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Hits counter (left).
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$hitCount',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    fontWeight: FontWeight.w500,
                                    color: ColorTokens.successDefault,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                TextSpan(
                                  text: '/$totalCount',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    fontWeight: FontWeight.w500,
                                    color: ColorTokens.textSecondary,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            ' Hits',
                            style: TextStyle(
                              fontSize: TypographyTokens.bodyLgSize,
                              color: ColorTokens.textTertiary,
                            ),
                          ),
                          const Spacer(),
                          // Set counter (center).
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Set ',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    color: ColorTokens.textTertiary,
                                  ),
                                ),
                                TextSpan(
                                  text: '${_controller.currentSetIndex + 1}',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    fontWeight: FontWeight.w500,
                                    color: ColorTokens.primaryDefault,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                                TextSpan(
                                  text: '/${_controller.requiredSetCount}',
                                  style: TextStyle(
                                    fontSize: TypographyTokens.bodyLgSize,
                                    color: ColorTokens.textTertiary,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Undo button (right).
                          Padding(
                            padding: const EdgeInsets.only(right: SpacingTokens.sm),
                            child: ZxPillButton(
                              label: 'Undo',
                              icon: Icons.undo,
                              variant: ZxPillVariant.secondary,
                              size: ZxPillSize.sm,
                              onTap: _controller.canUndo ? _undoLast : () {},
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
    );
  }

  /// Abbreviate long club names for compact display.
  static String _abbreviateClub(String name) {
    return switch (name) {
      'Driver' => 'Dr',
      'Putter' => 'Pu',
      'Chipper' => 'Ch',
      _ => name,
    };
  }

  /// Full-width club bar — tap to open grid picker. Centered, large text.
  Widget _buildClubBar({bool canChange = true}) {
    final isRandom =
        widget.drill.clubSelectionMode == ClubSelectionMode.random;
    final isGuided =
        widget.drill.clubSelectionMode == ClubSelectionMode.guided;
    final isTappable = canChange && !isRandom && !isGuided;

    final modeLabel = switch (widget.drill.clubSelectionMode) {
      ClubSelectionMode.userLed => 'Players Choice',
      ClubSelectionMode.random => 'Fixed Random',
      ClubSelectionMode.guided => 'Fixed Sequence',
      _ => '',
    };

    return GestureDetector(
      onTap: isTappable ? _pickClub : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          SpacingTokens.md, SpacingTokens.xs, SpacingTokens.sm, SpacingTokens.xs,
        ),
        decoration: BoxDecoration(
          color: ColorTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
          border: Border.all(color: ColorTokens.surfaceBorder),
        ),
        child: Row(
          children: [
            if (modeLabel.isNotEmpty)
              Text(
                modeLabel,
                style: TextStyle(
                  fontSize: TypographyTokens.bodyLgSize,
                  color: ColorTokens.textTertiary,
                ),
              ),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                  vertical: SpacingTokens.xs,
                ),
                decoration: BoxDecoration(
                  color: ColorTokens.primaryDefault.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                  border: Border.all(
                    color: ColorTokens.primaryDefault.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  _abbreviateClub(_selectedClub),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: TypographyTokens.displayXlSize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.primaryDefault,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps the input area with a vertical target depth bar for 3x1 grids.
  Widget _wrapWithVerticalTargetBar(Widget inputArea) {
    if (widget.drill.inputMode != InputMode.gridCell ||
        widget.drill.gridType != GridType.threeByOne) {
      return inputArea;
    }

    // Reduce grid left padding so the 4px gap between bar and input is tight.
    if (_delegate is GridCellDelegate) {
      (_delegate as GridCellDelegate).overridePadding =
          const EdgeInsets.fromLTRB(
            SpacingTokens.xs, SpacingTokens.md, SpacingTokens.lg, SpacingTokens.lg,
          );
    }

    return Row(
      children: [
        // Vertical target bar on the left — match grid input padding.
        Padding(
          padding: const EdgeInsets.only(
            left: SpacingTokens.lg,
            top: SpacingTokens.md,
            bottom: SpacingTokens.lg,
          ),
          child: SizedBox(
            width: 28,
            child: Column(
              children: [
                // Miss long zone (top).
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorTokens.missDefault.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(ShapeTokens.radiusGrid),
                      ),
                      border: Border.all(
                        color: ColorTokens.missDefault.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                // Hit zone (middle) — shows target depth.
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorTokens.successDefault.withValues(alpha: 0.15),
                      border: Border.all(
                        color: ColorTokens.successDefault.withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        _formatTargetDistance(),
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySmSize,
                          fontWeight: FontWeight.w600,
                          color: ColorTokens.successDefault,
                        ),
                      ),
                    ),
                  ),
                ),
                // Miss short zone (bottom).
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorTokens.missDefault.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(ShapeTokens.radiusGrid),
                      ),
                      border: Border.all(
                        color: ColorTokens.missDefault.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.xs),
        // Input area fills the rest.
        Expanded(child: inputArea),
      ],
    );
  }

  /// Visual bar showing the target width aligned to the grid input below.
  Widget _buildTargetWidthBar() {
    // Only show for grid-based drills with a target width.
    if (widget.drill.inputMode != InputMode.gridCell) {
      return const SizedBox.shrink();
    }

    final gridType = widget.drill.gridType;

    // For 1x3 (direction): the center 1/3 is the hit zone.
    // For 3x1 (distance): show width bar if computed target width is available
    //   (e.g. PercentageOfTargetDistance drills with club-tier banding).
    // For 3x3: center column is the hit zone (1/3 width).
    if (gridType == GridType.threeByOne && _currentTargetWidth == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            // Left miss zone.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorTokens.missDefault.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(ShapeTokens.radiusGrid),
                  ),
                  border: Border.all(
                    color: ColorTokens.missDefault.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            // Center hit zone — shows target width.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorTokens.successDefault.withValues(alpha: 0.15),
                  border: Border.all(
                    color: ColorTokens.successDefault.withValues(alpha: 0.5),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _formatTargetWidth(),
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySmSize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.successDefault,
                  ),
                ),
              ),
            ),
            // Right miss zone.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ColorTokens.missDefault.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(ShapeTokens.radiusGrid),
                  ),
                  border: Border.all(
                    color: ColorTokens.missDefault.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDrillInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorTokens.surfaceModal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ShapeTokens.radiusModal),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setup Instructions',
              style: TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                fontWeight: TypographyTokens.displayLgWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              widget.drill.description!,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
            const SizedBox(height: SpacingTokens.lg),
          ],
        ),
      ),
    );
  }

  /// Format target distance value + unit for the vertical target bar.
  /// For ClubCarry mode, uses the selected club's carry distance.
  String _formatTargetDistance() {
    double? value;
    DrillLengthUnit? unit;

    if (widget.drill.targetDistanceMode == TargetDistanceMode.clubCarry ||
        widget.drill.targetDistanceMode ==
            TargetDistanceMode.percentageOfClubCarry) {
      value = _currentCarryDistance;
      // Carry distances are stored in yards by default.
      unit = DrillLengthUnit.yards;
    } else {
      value = widget.drill.targetDistanceValue;
      unit = widget.drill.targetDistanceUnit;
    }

    if (value == null) return '';
    final rounded = value.round();
    return unit != null ? '$rounded ${unit.dbValue}' : '$rounded';
  }

  /// Format target width value + unit for the horizontal target bar.
  /// For PercentageOfTargetDistance mode, computes from carry + club tier.
  String _formatTargetWidth() {
    final computed = _currentTargetWidth;
    if (computed != null) {
      final rounded = computed.round();
      return '$rounded yds';
    }

    final value = widget.drill.targetSizeWidth;
    final unit = widget.drill.targetSizeUnit;
    if (value == null) return '';
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return unit != null ? '$formatted ${unit.dbValue}' : formatted;
  }

  Widget _buildBottomBar() {
    if (_controller.isStructured) {
      return SizedBox(height: MediaQuery.of(context).padding.bottom);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.sm,
        SpacingTokens.md,
        SpacingTokens.sm + MediaQuery.of(context).padding.bottom,
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Shot number.
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: ColorTokens.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          // Hit/miss indicator dot.
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: shot.isHit
                  ? ColorTokens.successDefault
                  : ColorTokens.missDefault,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          // Result label.
          Expanded(
            child: Text(
              shot.label,
              style: TextStyle(
                fontSize: TypographyTokens.bodyLgSize,
                color: shot.isHit
                    ? ColorTokens.successDefault
                    : ColorTokens.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Club name.
          Padding(
            padding: const EdgeInsets.only(right: SpacingTokens.xl + SpacingTokens.sm),
            child: Text(
              shot.club,
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
