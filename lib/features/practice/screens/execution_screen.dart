// Unified execution screen for all instance-recording input modes.
// Replaces GridCellScreen, BinaryHitMissScreen, ContinuousMeasurementScreen,
// and RawDataEntryScreen with a single host + swappable input delegate.
// TechniqueBlockScreen remains separate (timer-based, no per-instance recording).

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
import 'package:zx_golf_app/features/settings/settings_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/practice_stats_bar.dart';
import 'package:zx_golf_app/features/practice/widgets/set_transition_overlay.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';
import 'package:zx_golf_app/providers/settings_providers.dart';

/// True on Android/iOS where vibration and wakelock are supported.
final bool _isMobilePlatform = Platform.isAndroid || Platform.isIOS;

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

/// Minimum height per grid cell row before the shot log is hidden.
const _kMinGridCellHeight = 48.0;

class _ExecutionScreenState extends ConsumerState<ExecutionScreen> {
  late SessionExecutionController _controller;
  late ExecutionInputDelegate _delegate;
  bool _initialized = false;
  bool _ending = false;
  late SurfaceType? _surfaceType = widget.session.surfaceType;
  EnvironmentType? _environmentType;
  /// Currently selected club ID (UUID). Null for technique blocks.
  String? _selectedClubId;
  /// Available clubs for this drill's skill area.
  List<UserClub> _availableClubs = [];
  /// Lookup: clubId → clubType.dbValue for display.
  final Map<String, String> _clubIdToLabel = {};
  final _random = Random();
  final List<_ShotEntry> _shotLog = [];
  final _shotListController = ScrollController();

  /// Carry distances keyed by ClubType dbValue (e.g. 'i7' → 155.0).
  /// Populated during init for drills using ClubCarry targeting.
  final Map<String, double> _clubCarryDistances = {};

  /// Current random target distance for RandomRange drills (yards).
  double? _currentRandomDistance;

  /// Toggle: show total target width vs ± half-width from center.
  bool _showHalfWidth = false;

  /// Whether the screen wakelock is currently enabled.
  bool _screenAlwaysOn = false;

  /// Toggle: show total target depth vs ± half-depth on vertical bar.
  bool _showHalfDepth = false;

  /// Cached notifier for safe access in dispose (ref is unavailable there).
  late final StateController<bool> _executionActiveNotifier;

  @override
  void initState() {
    super.initState();
    _executionActiveNotifier =
        ref.read(practiceExecutionActiveProvider.notifier);
    _delegate = _createDelegate();
    // For 1x3 grids, remove top padding — target bar spacing handles it.
    if (_delegate is GridCellDelegate &&
        widget.drill.gridType == GridType.oneByThree) {
      (_delegate as GridCellDelegate).overridePadding =
          const EdgeInsets.fromLTRB(
            SpacingTokens.lg, 0, SpacingTokens.lg, 0,
          );
    }
    _initController();
  }

  ExecutionInputDelegate _createDelegate() {
    return switch (widget.drill.inputMode) {
      InputMode.gridCell => GridCellDelegate(drill: widget.drill),
      InputMode.binaryHitMiss => BinaryHitMissDelegate(),
      InputMode.continuousMeasurement => ContinuousMeasurementDelegate(),
      InputMode.rawDataEntry => RawDataEntryDelegate(drill: widget.drill),
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
    _pickRandomDistanceIfNeeded();
    // Rebuild shot log from existing instances in the current set.
    await _restoreShotLog();
    // Load environment type from practice block.
    final block = await ref
        .read(practiceRepositoryProvider)
        .getPracticeBlockById(widget.session.practiceBlockId);
    _environmentType = block?.environmentType;
    // Read user preferences for execution defaults.
    final prefs = ref.read(userPreferencesProvider);
    _screenAlwaysOn = prefs.screenAlwaysOn;
    _showHalfWidth = prefs.targetBarSplitView;
    _showHalfDepth = prefs.targetBarSplitView;
    if (_screenAlwaysOn && _isMobilePlatform) WakelockPlus.enable();
    if (mounted) {
      _executionActiveNotifier.state = true;
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
      final clubLabel = _clubIdToLabel[inst.selectedClub] ?? '';
      final metrics =
          jsonDecode(inst.rawMetrics) as Map<String, dynamic>;
      if (metrics.containsKey('hit')) {
        final isHit = metrics['hit'] as bool;
        final label =
            metrics['label'] as String? ?? (isHit ? 'Hit' : 'Miss');
        _shotLog.add(_ShotEntry(
          label: label,
          isHit: isHit,
          club: clubLabel,
        ));
      } else if (metrics.containsKey('value')) {
        final value = (metrics['value'] as num).toDouble();
        _shotLog.add(_ShotEntry(
          label: value.toStringAsFixed(1),
          isHit: false,
          club: clubLabel,
        ));
      } else {
        _shotLog.add(_ShotEntry(
          label: '\u2014',
          isHit: false,
          club: clubLabel,
        ));
      }
    }
  }

  // TD-06 §9.1.2 — Load clubs for this drill's skill area.
  Future<void> _loadClubs() async {
    final mode = widget.drill.clubSelectionMode;
    if (mode == null) {
      // No club selection — e.g. putting drills with putter implicit.
      // Find the user's putter club ID if available.
      final allClubs = await ref
          .read(clubsForSkillAreaProvider(
              (widget.userId, widget.drill.skillArea))
              .future);
      for (final c in allClubs) {
        _clubIdToLabel[c.clubId] = c.clubType.dbValue;
      }
      final putter = allClubs.where((c) => c.clubType == ClubType.putter).firstOrNull;
      _selectedClubId = putter?.clubId;
      if (putter != null) {
        _clubIdToLabel[putter.clubId] = putter.clubType.dbValue;
      }
      return;
    }
    final clubs = await ref
        .read(clubsForSkillAreaProvider(
            (widget.userId, widget.drill.skillArea))
            .future);
    _availableClubs = clubs;
    for (final c in clubs) {
      _clubIdToLabel[c.clubId] = c.clubType.dbValue;
    }
    if (clubs.isNotEmpty) {
      final pick = mode == ClubSelectionMode.random
          ? clubs[_random.nextInt(clubs.length)]
          : clubs.first;
      _selectedClubId = pick.clubId;
    }
  }

  /// Display label for the currently selected club.
  String get _selectedClubLabel {
    if (_selectedClubId == null) {
      // Driving drills with no club selection default to "Driver".
      if (widget.drill.clubSelectionMode == null &&
          widget.drill.skillArea == SkillArea.driving) {
        return 'Driver';
      }
      return '';
    }
    return _clubIdToLabel[_selectedClubId] ?? '';
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
    for (final club in _availableClubs) {
      final profile = await clubRepo.getActiveProfile(club.clubId);
      if (profile?.carryDistance != null) {
        _clubCarryDistances[club.clubId] = profile!.carryDistance!;
      }
    }
  }

  /// Get the carry distance for the currently selected club.
  double? get _currentCarryDistance => _clubCarryDistances[_selectedClubId];

  /// Pick a new random target distance for RandomRange drills.
  /// Uses Target (min) and TargetDistanceValue (max) from the drill.
  void _pickRandomDistanceIfNeeded() {
    if (widget.drill.targetDistanceMode != TargetDistanceMode.randomRange) {
      return;
    }
    final min = widget.drill.target ?? 100;
    final max = widget.drill.targetDistanceValue ?? 200;
    _currentRandomDistance = min + _random.nextDouble() * (max - min);
  }

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
        final clubType = ClubType.fromString(_selectedClubLabel);
        final percent = targetWidthPercentForClub(clubType);
        return carry * percent / 100.0;
      } on ArgumentError {
        return null;
      }
    }
    return null;
  }

  /// Computed target depth (yards) for the vertical bar.
  /// For PercentageOfTargetDistance mode, uses club-tier depth percentages.
  double? get _currentTargetDepth {
    if (widget.drill.targetSizeMode !=
        TargetSizeMode.percentageOfTargetDistance) {
      return null;
    }
    // Determine the base distance (carry or random).
    double? baseDistance;
    if (widget.drill.targetDistanceMode == TargetDistanceMode.randomRange) {
      baseDistance = _currentRandomDistance;
    } else {
      baseDistance = _currentCarryDistance;
    }
    if (baseDistance == null) return null;

    try {
      final clubType = ClubType.fromString(_selectedClubLabel);
      final percent = targetDepthPercentForClub(clubType);
      return baseDistance * percent / 100.0;
    } on ArgumentError {
      return null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executionActiveNotifier.state = false;
    });
    if (_isMobilePlatform) WakelockPlus.disable();
    _delegate.dispose();
    _shotListController.dispose();
    super.dispose();
  }

  /// Parse a shot entry from instance data for the shot log.
  _ShotEntry _parseShotEntry(InstancesCompanion data, InstanceResult result) {
    final clubLabel = _clubIdToLabel[data.selectedClub.value] ?? '';
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
        club: clubLabel,
        score: result.realtimeScore,
      );
    }
    // Raw/continuous — has 'value' field.
    if (metrics.containsKey('value')) {
      final value = (metrics['value'] as num).toDouble();
      return _ShotEntry(
        label: value.toStringAsFixed(1),
        isHit: (result.realtimeScore ?? 0) >= 2.5,
        club: clubLabel,
        score: result.realtimeScore,
      );
    }
    return _ShotEntry(
      label: '\u2014',
      isHit: false,
      club: clubLabel,
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
          selectedClub: null,
          rawMetrics: '{}',
          timestamp: now,
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // Haptic + sound feedback based on user preferences.
    _playShotFeedback();

    // TD-06 §9.1.2 — Random mode picks a new club per instance.
    // Avoid picking the same club consecutively (unless only 1 club available).
    if (widget.drill.clubSelectionMode == ClubSelectionMode.random &&
        _availableClubs.isNotEmpty) {
      final candidates = _availableClubs.length > 1
          ? _availableClubs.where((c) => c.clubId != _selectedClubId).toList()
          : _availableClubs;
      final pick = candidates[_random.nextInt(candidates.length)];
      _selectedClubId = pick.clubId;
    }

    // RandomRange mode picks a new distance per shot.
    _pickRandomDistanceIfNeeded();

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
    final clubNames = _availableClubs.map((c) => c.clubType.dbValue).toList();
    final picked = await showClubGridPicker(
      context,
      clubs: clubNames,
      selectedClub: _selectedClubLabel,
      skillArea: widget.drill.skillArea,
      userId: widget.userId,
    );
    if (picked != null && mounted) {
      // Find the UserClub matching the picked type name.
      final club = _availableClubs.firstWhere(
        (c) => c.clubType.dbValue == picked,
      );
      setState(() => _selectedClubId = club.clubId);
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
      selectedClub: _selectedClubId,
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
        onSettingsTap: _openPracticeSettings,
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
            // Shot log + input area — LayoutBuilder measures available
            // height and hides the shot log when grid cells would be
            // shorter than _kMinGridCellHeight.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showShotLog = _shouldShowShotLog(constraints.maxHeight);
                  final isCompact = constraints.maxHeight < 500;
                  return Column(
                    children: [
                      // Shot log + Club bar section.
                      if (showShotLog) _buildShotLogSection(compact: isCompact),  // flex 40 (or 50 compact)
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
                      // Target width bar sits just above the input for 1x3/3x3 grids.
                      // For 3x1 grids, a vertical target depth bar sits on the left.
                      // Pre-set grid padding before building the delegate so the
                      // vertical target bar wrapper doesn't lag by one frame.
                      ..._applyVerticalBarPaddingOverride(),
                      Expanded(
                        flex: showShotLog
                            ? 50
                            : 1,
                        child: Column(
                          children: [
                            // Target width indicator bar (horizontal, for 1x3/3x3 grids).
                            const SizedBox(height: 4),
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
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _buildBottomBar(),
          ],
        ),
    );
  }

  /// Club bar (full width) + shot log (full width) stacked section.
  /// Uses Expanded so the input area below gets ~1/3 of the screen.
  /// Returns false when available height is too small for the grid cells
  /// at their minimum height — the shot log should be hidden.
  bool _shouldShowShotLog(double availableHeight) {
    final is3x3 = widget.drill.gridType == GridType.threeByThree;
    if (!is3x3) return true;
    // 3 rows of cells + 2 gaps + target bar (~30px) + spacing (8px).
    // If 65% of available height can't fit 3 rows at min height, hide log.
    final gridAreaHeight = availableHeight * 0.65;
    final gridContentHeight = gridAreaHeight - 38; // target bar + spacing
    final cellHeight = (gridContentHeight - 2 * SpacingTokens.sm) / 3;
    return cellHeight >= _kMinGridCellHeight;
  }

  Widget _buildShotLogSection({bool compact = false}) {
    final hasClubSelection = widget.drill.clubSelectionMode != null &&
        _availableClubs.isNotEmpty;
    return Expanded(
      flex: 50,
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
                    // Divider above shot count + undo row.
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: ColorTokens.textTertiary.withValues(alpha: 0.3),
                    ),
                    // Shot count + undo row.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        SpacingTokens.md, 6, SpacingTokens.md, 2,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Set counter (left): "Set A of BxC"
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
                                  text: ' of ${_controller.requiredSetCount}x${_controller.requiredAttemptsPerSet}',
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
                          ZxPillButton(
                            label: 'Undo',
                            icon: Icons.undo,
                            variant: ZxPillVariant.secondary,
                            size: ZxPillSize.xs,
                            onTap: _controller.canUndo ? _undoLast : () {},
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
      null => widget.drill.skillArea == SkillArea.driving ? 'Fixed' : '',
    };

    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left half — target distance.
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SpacingTokens.xs),
            decoration: BoxDecoration(
              color: ColorTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
              border: Border.all(color: ColorTokens.surfaceBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Distance',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w600,
                    color: ColorTokens.textPrimary,
                  ),
                ),
                Text(
                  'Target Distance',
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontStyle: FontStyle.italic,
                    color: ColorTokens.textTertiary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.md,
                    vertical: SpacingTokens.xs,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A4048),
                    borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                  ),
                  child: Text(
                    _formatTargetDistance(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        // Right half — club selection.
        Expanded(
          child: GestureDetector(
            onTap: isTappable ? _pickClub : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(SpacingTokens.xs),
              decoration: BoxDecoration(
                color: ColorTokens.surfaceRaised,
                borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                border: Border.all(color: ColorTokens.surfaceBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Club',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontWeight: FontWeight.w600,
                      color: ColorTokens.textPrimary,
                    ),
                  ),
                  if (modeLabel.isNotEmpty)
                    Text(
                      modeLabel,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        fontStyle: FontStyle.italic,
                        color: ColorTokens.textTertiary,
                      ),
                    ),
                  const SizedBox(height: SpacingTokens.xs),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: ColorTokens.primaryDefault,
                      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
                    ),
                    child: Text(
                      _abbreviateClub(_selectedClubLabel),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  /// Set grid padding override before the delegate builds, so the vertical
  /// target bar gap is correct on the very first frame.
  List<Widget> _applyVerticalBarPaddingOverride() {
    if (widget.drill.inputMode == InputMode.gridCell &&
        (widget.drill.gridType == GridType.threeByOne ||
            widget.drill.gridType == GridType.threeByThree) &&
        _delegate is GridCellDelegate) {
      (_delegate as GridCellDelegate).overridePadding =
          const EdgeInsets.fromLTRB(
            SpacingTokens.xs, 0, SpacingTokens.lg, 0,
          );
    }
    return const [];
  }

  /// Navigate to settings, then re-apply practice preferences on return.
  Future<void> _openPracticeSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(scrollToSection: 'practice'),
      ),
    );
    if (!mounted) return;
    final prefs = ref.read(userPreferencesProvider);
    setState(() {
      _screenAlwaysOn = prefs.screenAlwaysOn;
      _showHalfWidth = prefs.targetBarSplitView;
      _showHalfDepth = prefs.targetBarSplitView;
    });
    if (_isMobilePlatform) {
      if (_screenAlwaysOn) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    }
  }

  /// Play haptic and/or sound feedback on shot input per user preferences.
  void _playShotFeedback() {
    final prefs = ref.read(userPreferencesProvider);
    if (_isMobilePlatform) {
      switch (prefs.shotInputVibration) {
        case 'soft':
          Vibration.vibrate(duration: 20, amplitude: 40);
        case 'medium':
          Vibration.vibrate(duration: 30, amplitude: 128);
        case 'hard':
          Vibration.vibrate(duration: 50, amplitude: 255);
        default:
          break; // 'off'
      }
    }
    if (prefs.shotInputSound) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Wraps the input area with a vertical target depth bar for 3x1 grids.
  Widget _wrapWithVerticalTargetBar(Widget inputArea) {
    if (widget.drill.inputMode != InputMode.gridCell) return inputArea;
    final gridType = widget.drill.gridType;
    if (gridType != GridType.threeByOne && gridType != GridType.threeByThree) {
      return inputArea;
    }

    return Row(
      children: [
        // Vertical target bar on the left — match grid input padding.
        Padding(
          padding: const EdgeInsets.only(
            left: SpacingTokens.lg,
          ),
          child: SizedBox(
            width: 48,
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
                // Hit zone (middle) — tap to toggle total vs ± half depth.
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showHalfDepth = !_showHalfDepth),
                    child: _showHalfDepth
                        ? _buildSplitDepthZone()
                        : Container(
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
                                _formatTargetDepth(),
                                style: TextStyle(
                                  fontSize: TypographyTokens.headerSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.successDefault,
                                ),
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
        // Input area fills the rest (grid's own left padding provides the gap).
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

    final widthLabel = _showHalfWidth
        ? _formatTargetWidthHalf()
        : _formatTargetWidth();

    // For 3x3/3x1 grids with a vertical target bar, offset the left edge
    // to align with the grid: lg (bar padding) + 48 (bar width) + xs (grid gap).
    final hasVerticalBar =
        gridType == GridType.threeByThree || gridType == GridType.threeByOne;
    final leftPad = hasVerticalBar
        ? SpacingTokens.lg + 48 + SpacingTokens.xs
        : SpacingTokens.lg;

    return GestureDetector(
      onTap: () => setState(() => _showHalfWidth = !_showHalfWidth),
      child: Padding(
        padding: EdgeInsets.only(left: leftPad, right: SpacingTokens.lg),
        child: SizedBox(
          height: 48,
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
              // Center hit zone — shows target width or ± half-width split.
              Expanded(
                child: _showHalfWidth
                    ? _buildSplitHitZone()
                    : Container(
                        decoration: BoxDecoration(
                          color: ColorTokens.successDefault
                              .withValues(alpha: 0.15),
                          border: Border.all(
                            color: ColorTokens.successDefault
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widthLabel,
                          style: TextStyle(
                            fontSize: TypographyTokens.headerSize,
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
      ),
    );
  }

  /// Split hit zone: two halves with a center divider, each showing ±half.
  Widget _buildSplitHitZone() {
    final halfLabel = _formatTargetWidthHalf();
    final borderColor = ColorTokens.successDefault.withValues(alpha: 0.5);
    final bgColor = ColorTokens.successDefault.withValues(alpha: 0.15);
    final textStyle = TextStyle(
      fontSize: TypographyTokens.headerSize,
      fontWeight: FontWeight.w600,
      color: ColorTokens.successDefault,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Left half: ← label
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('< ', style: textStyle),
                  Text(halfLabel, style: textStyle),
                ],
              ),
            ),
          ),
          // Center divider line.
          Container(
            width: 2,
            color: ColorTokens.successDefault.withValues(alpha: 0.6),
          ),
          // Right half: label →
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(halfLabel, style: textStyle),
                  Text(' >', style: textStyle),
                ],
              ),
            ),
          ),
        ],
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

    if (widget.drill.targetDistanceMode ==
        TargetDistanceMode.percentageOfClubCarry) {
      // Target is a percentage of carry — show the computed distance.
      final carry = _currentCarryDistance;
      final percent = widget.drill.targetDistanceValue;
      if (carry != null && percent != null) {
        value = carry * percent / 100.0;
      }
      unit = DrillLengthUnit.yards;
    } else if (widget.drill.targetDistanceMode ==
        TargetDistanceMode.clubCarry) {
      value = _currentCarryDistance;
      unit = DrillLengthUnit.yards;
    } else if (widget.drill.targetDistanceMode ==
        TargetDistanceMode.randomRange) {
      value = _currentRandomDistance;
      unit = DrillLengthUnit.yards;
    } else {
      value = widget.drill.targetDistanceValue;
      unit = widget.drill.targetDistanceUnit;
    }

    if (value == null) return 'None';
    final rounded = value.round();
    return unit != null ? '$rounded${_shortUnit(unit)}' : '$rounded';
  }

  /// Format target depth for the vertical target bar (miss long / hit / miss short).
  String _formatTargetDepth() {
    // Use computed depth from club tier if available.
    final computed = _currentTargetDepth;
    if (computed != null) {
      final rounded = computed.round();
      return '$rounded yds';
    }
    final value = widget.drill.targetSizeDepth;
    final unit = widget.drill.targetSizeUnit;
    if (value == null) return _formatTargetDistance();
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return unit != null ? '$formatted ${unit.dbValue}' : formatted;
  }

  /// Format target depth as half value for split vertical bar display.
  String _formatTargetDepthHalf() {
    // Use computed depth from club tier if available.
    final computed = _currentTargetDepth;
    if (computed != null) {
      final half = computed / 2;
      final formatted = half == half.roundToDouble()
          ? half.toInt().toString()
          : half.toStringAsFixed(1);
      return '${formatted}y';
    }
    final value = widget.drill.targetSizeDepth;
    final unit = widget.drill.targetSizeUnit;
    if (value == null) return '';
    final half = value / 2;
    final formatted = half == half.roundToDouble()
        ? half.toInt().toString()
        : half.toStringAsFixed(1);
    return '$formatted${_shortUnit(unit)}';
  }

  /// Split depth zone: top half (long) and bottom half (short) with divider.
  Widget _buildSplitDepthZone() {
    final halfLabel = _formatTargetDepthHalf();
    final borderColor = ColorTokens.successDefault.withValues(alpha: 0.5);
    final bgColor = ColorTokens.successDefault.withValues(alpha: 0.15);
    final textStyle = TextStyle(
      fontSize: TypographyTokens.headerSize,
      fontWeight: FontWeight.w600,
      color: ColorTokens.successDefault,
    );

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Top half: label ↑ (long side — arrow points up/outward)
          Expanded(
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(halfLabel, style: textStyle),
                    Text(' >', style: textStyle),
                  ],
                ),
              ),
            ),
          ),
          // Center divider line.
          Container(
            height: 2,
            color: ColorTokens.successDefault.withValues(alpha: 0.6),
          ),
          // Bottom half: ↓ label (short side — arrow points down/outward)
          Expanded(
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('< ', style: textStyle),
                    Text(halfLabel, style: textStyle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  /// Format target width as half value for the split display.
  String _formatTargetWidthHalf() {
    final computed = _currentTargetWidth;
    if (computed != null) {
      final half = (computed / 2).round();
      return '${half}y';
    }

    final value = widget.drill.targetSizeWidth;
    final unit = widget.drill.targetSizeUnit;
    if (value == null) return '';
    final half = value / 2;
    final formatted = half == half.roundToDouble()
        ? half.toInt().toString()
        : half.toStringAsFixed(1);
    return '$formatted${_shortUnit(unit)}';
  }

  /// Short unit suffix for compact display.
  static String _shortUnit(DrillLengthUnit? unit) {
    return switch (unit) {
      DrillLengthUnit.yards => 'y',
      DrillLengthUnit.m => 'm',
      DrillLengthUnit.feet => 'ft',
      DrillLengthUnit.cm => 'cm',
      DrillLengthUnit.mm => 'mm',
      DrillLengthUnit.inches => 'in',
      null => '',
    };
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
