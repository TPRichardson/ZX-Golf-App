// Unified execution screen for all instance-recording input modes.
// Replaces GridCellScreen, BinaryHitMissScreen, ContinuousMeasurementScreen,
// and RawDataEntryScreen with a single host + swappable input delegate.
// TechniqueBlockScreen remains separate (timer-based, no per-instance recording).

import 'dart:convert';
import 'package:drift/drift.dart' show Value;
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
import 'package:zx_golf_app/features/practice/widgets/edit_shot_dialog.dart';
import 'package:zx_golf_app/features/practice/widgets/next_target_dialog.dart';
import 'package:zx_golf_app/features/practice/widgets/shot_log_row.dart';
import 'package:zx_golf_app/features/practice/widgets/target_distance_picker_dialog.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/binary_hit_miss_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/continuous_measurement_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/grid_cell_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/raw_data_entry_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/scoring_game_delegate.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/chipping_game_delegate.dart';
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
  bool _dialogOpen = false;
  late SurfaceType? _surfaceType = widget.session.surfaceType;
  EnvironmentType? _environmentType;
  /// Currently selected club ID (UUID). Null for technique blocks.
  String? _selectedClubId;
  /// Available clubs for this drill's skill area.
  List<UserClub> _availableClubs = [];
  /// Lookup: clubId → clubType.dbValue for display.
  final Map<String, String> _clubIdToLabel = {};
  final _random = Random();
  final List<ShotEntry> _shotLog = [];
  final _shotListController = ScrollController();

  /// Carry distances keyed by ClubType dbValue (e.g. 'i7' → 155.0).
  /// Populated during init for drills using ClubCarry targeting.
  final Map<String, double> _clubCarryDistances = {};

  /// Current random target distance for RandomRange drills (yards).
  double? _currentRandomDistance;
  /// User override of the target distance (yards). Null = use default.
  double? _targetDistanceOverride;
  /// History of random distances for undo support.
  final List<double> _randomDistanceHistory = [];

  /// Whether the club was manually picked by the player (vs system suggested).
  bool _clubIsPlayerChoice = false;
  /// Whether the target distance was manually set by the player.
  bool _distanceIsPlayerChoice = false;

  /// Player-declared shot shape intent for the next shot.
  String? _shotShape;
  /// Player-declared effort percentage for the next shot.
  int? _shotEffort;
  /// Player-declared flight rating (1=low, 2=medium, 3=high) for chipping.
  int? _flight;

  /// Whether shot intent fields (shape + effort) are visible.
  bool _showShotIntent = false;

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
      InputMode.scoringGame =>
        widget.drill.metricSchemaId == 'chipping_game_strokes'
            ? ChippingGameDelegate(drill: widget.drill)
            : ScoringGameDelegate(drill: widget.drill),
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
    // Seed delegate-driven distance (e.g. scoring game first hole).
    _currentRandomDistance ??= _delegate.currentTargetDistance;
    _suggestRandomClubIfNeeded();
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
    _showShotIntent = prefs.showShotIntent;
    if (_screenAlwaysOn && _isMobilePlatform) WakelockPlus.enable();
    if (mounted) {
      _executionActiveNotifier.state = true;
      setState(() => _initialized = true);
      // Show initial target dialog for chipping game (club + flight selection).
      if (_delegate is ChippingGameDelegate && _currentRandomDistance != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showNextTargetDialog();
        });
      }
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
      final raw = inst.rawMetrics;
      final metrics = jsonDecode(raw) as Map<String, dynamic>;
      if (metrics.containsKey('hit')) {
        final isHit = metrics['hit'] as bool;
        final label =
            metrics['label'] as String? ?? (isHit ? 'Hit' : 'Miss');
        _shotLog.add(ShotEntry(
          instanceId: inst.instanceId,
          label: label,
          isHit: isHit,
          club: clubLabel,
          clubId: inst.selectedClub,
          rawMetrics: raw,
        ));
      } else if (metrics.containsKey('value')) {
        final value = (metrics['value'] as num).toDouble();
        _shotLog.add(ShotEntry(
          instanceId: inst.instanceId,
          label: value.toStringAsFixed(1),
          isHit: false,
          club: clubLabel,
          clubId: inst.selectedClub,
          rawMetrics: raw,
        ));
      } else {
        _shotLog.add(ShotEntry(
          instanceId: inst.instanceId,
          label: '\u2014',
          isHit: false,
          club: clubLabel,
          clubId: inst.selectedClub,
          rawMetrics: raw,
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
      // Free Practice (ClubCarry + UserLed): don't pre-select — user picks.
      if (mode == ClubSelectionMode.userLed &&
          widget.drill.targetDistanceMode == TargetDistanceMode.clubCarry) {
        _selectedClubId = null;
      } else {
        final pick = mode == ClubSelectionMode.random
            ? clubs[_random.nextInt(clubs.length)]
            : clubs.first;
        _selectedClubId = pick.clubId;
      }
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
        distMode != TargetDistanceMode.percentageOfClubCarry &&
        distMode != TargetDistanceMode.randomDistancePerSet) {
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

  /// Effective target distance: user override > random > carry > fixed.
  double? get _effectiveTargetDistance {
    if (_targetDistanceOverride != null) return _targetDistanceOverride;
    if (widget.drill.targetDistanceMode == TargetDistanceMode.randomRange) {
      return _currentRandomDistance;
    }
    if (widget.drill.targetDistanceMode == TargetDistanceMode.clubCarry) {
      return _currentCarryDistance;
    }
    return widget.drill.targetDistanceValue;
  }

  /// Min/max target distance range for user override.
  (double min, double max) get _targetDistanceRange {
    final carries = _clubCarryDistances.values;
    if (carries.isEmpty) return (50, 300);
    final lowest = carries.reduce((a, b) => a < b ? a : b);
    final highest = carries.reduce((a, b) => a > b ? a : b);
    return (lowest * 0.9, highest * 1.1);
  }

  /// Pick a new random target distance for RandomRange drills.
  /// Uses Target (min) and TargetDistanceValue (max) from the drill.
  /// Ensures the new distance differs from the previous by at least 5% of max.
  void _pickRandomDistanceIfNeeded() {
    if (widget.drill.targetDistanceMode != TargetDistanceMode.randomRange) {
      return;
    }
    // Scoring game manages its own per-hole distances via the delegate.
    if (widget.drill.inputMode == InputMode.scoringGame) return;
    // Save current distance to history before picking a new one.
    if (_currentRandomDistance != null) {
      _randomDistanceHistory.add(_currentRandomDistance!);
    }
    final min = widget.drill.target ?? 100;
    final max = widget.drill.targetDistanceValue ?? 200;
    final minDelta = max * 0.05;
    final previous = _currentRandomDistance;

    for (var attempt = 0; attempt < 20; attempt++) {
      final candidate = min + _random.nextDouble() * (max - min);
      if (previous == null || (candidate - previous).abs() >= minDelta) {
        _currentRandomDistance = candidate;
        return;
      }
    }
    // Fallback: accept whatever we get.
    _currentRandomDistance = min + _random.nextDouble() * (max - min);
  }

  /// Compute the target width for the currently selected club.
  /// Uses club tier percentage of carry distance.
  double? get _currentTargetWidth {
    // Fixed target size: return the raw value (e.g. 5cm gate).
    if (widget.drill.targetSizeMode == TargetSizeMode.fixed) {
      return widget.drill.targetSizeWidth;
    }

    // Percentage of target distance mode.
    if (widget.drill.targetSizeMode ==
        TargetSizeMode.percentageOfTargetDistance) {
      final dist = _effectiveTargetDistance;
      if (dist == null) return null;

      // If drill specifies a width percentage, use it.
      final fixedPercent = widget.drill.targetSizeWidth;
      if (fixedPercent != null) {
        return dist * fixedPercent / 100.0;
      }

      // Otherwise use club-tier banded percentage.
      try {
        final clubType = ClubType.fromString(_selectedClubLabel);
        final percent = targetWidthPercentForClub(clubType, skillArea: widget.drill.skillArea);
        return dist * percent / 100.0;
      } on ArgumentError {
        return null;
      }
    }
    return null;
  }

  /// Computed target depth (yards) for the vertical bar.
  /// For PercentageOfTargetDistance mode, uses drill-specified depth percentage
  /// if available, otherwise falls back to club-tier depth percentages.
  double? get _currentTargetDepth {
    // Fixed target size: return the raw value.
    if (widget.drill.targetSizeMode == TargetSizeMode.fixed) {
      return widget.drill.targetSizeDepth;
    }

    if (widget.drill.targetSizeMode !=
        TargetSizeMode.percentageOfTargetDistance) {
      return null;
    }
    final baseDistance = _effectiveTargetDistance;
    if (baseDistance == null) return null;

    // If drill specifies a depth percentage, use it.
    final fixedPercent = widget.drill.targetSizeDepth;
    if (fixedPercent != null) {
      return baseDistance * fixedPercent / 100.0;
    }

    // Otherwise use club-tier banded percentage.
    try {
      final clubType = ClubType.fromString(_selectedClubLabel);
      final percent = targetDepthPercentForClub(clubType, skillArea: widget.drill.skillArea);
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
  ShotEntry _parseShotEntry(InstancesCompanion data, InstanceResult result) {
    final clubLabel = _clubIdToLabel[data.selectedClub.value] ?? '';
    final raw = data.rawMetrics.value;
    final metrics = jsonDecode(raw) as Map<String, dynamic>;
    // Scoring game — has 'strokes' + 'par' fields.
    if (metrics.containsKey('strokes') && metrics.containsKey('par')) {
      final dist = (metrics['distance'] as num?)?.toInt();
      final holeNum = (metrics['holeNumber'] as num?)?.toInt();
      final isChipping = metrics.containsKey('proximityFeet');
      final holed = metrics['holed'] == true;
      final notPuttable = metrics['notPuttable'] == true;

      // Chipping stores +/- par in 'strokes' and total in 'rawStrokes'.
      // Putting stores actual strokes in 'strokes' with integer par.
      final double totalStrokes;
      final double diff;
      if (isChipping) {
        totalStrokes = (metrics['rawStrokes'] as num).toDouble();
        final par = (metrics['par'] as num).toDouble();
        diff = totalStrokes - par;
      } else {
        totalStrokes = (metrics['strokes'] as num).toDouble();
        final par = (metrics['par'] as num).toInt();
        diff = totalStrokes - par;
      }

      String diffLabel;
      String strokesLabel;
      String distLabel;
      if (isChipping) {
        distLabel = dist != null ? '${dist}y' : '';
        strokesLabel = totalStrokes.toStringAsFixed(2);
        diffLabel = diff.abs() < 0.005
            ? 'E'
            : diff > 0
                ? '+${diff.toStringAsFixed(2)}'
                : diff.toStringAsFixed(2);
      } else {
        distLabel = dist != null ? '${dist}ft' : '';
        strokesLabel = '${totalStrokes.toInt()}';
        final intDiff = diff.toInt();
        diffLabel = intDiff == 0 ? 'E' : intDiff > 0 ? '+$intDiff' : '$intDiff';
      }
      final label = 'Hole $holeNum  $distLabel  $strokesLabel ($diffLabel)';
      final color = diff < -0.05
          ? ColorTokens.successDefault
          : diff.abs() < 0.05
              ? ColorTokens.textSecondary
              : ColorTokens.errorDestructive;
      return ShotEntry(
        instanceId: result.instance.instanceId,
        label: label,
        isHit: diff < -0.05,
        club: isChipping ? clubLabel : '',
        clubId: isChipping ? data.selectedClub.value : null,
        rawMetrics: raw,
        score: result.realtimeScore,
        colorOverride: color,
      );
    }
    // Grid or binary — has 'hit' field.
    if (metrics.containsKey('hit')) {
      final isHit = metrics['hit'] as bool;
      final label =
          metrics['label'] as String? ?? (isHit ? 'Hit' : 'Miss');
      return ShotEntry(
        instanceId: result.instance.instanceId,
        label: label,
        isHit: isHit,
        club: clubLabel,
        clubId: data.selectedClub.value,
        rawMetrics: raw,
        score: result.realtimeScore,
      );
    }
    // Raw/continuous — has 'value' field.
    if (metrics.containsKey('value')) {
      final value = (metrics['value'] as num).toDouble();
      return ShotEntry(
        instanceId: result.instance.instanceId,
        label: value.toStringAsFixed(1),
        isHit: (result.realtimeScore ?? 0) >= 2.5,
        club: clubLabel,
        clubId: data.selectedClub.value,
        rawMetrics: raw,
        score: result.realtimeScore,
      );
    }
    return ShotEntry(
      instanceId: result.instance.instanceId,
      label: '\u2014',
      isHit: false,
      club: clubLabel,
      clubId: data.selectedClub.value,
      rawMetrics: raw,
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
    // Sync delegate distance after hole advance so the club bar updates.
    _currentRandomDistance = _delegate.currentTargetDistance ?? _currentRandomDistance;
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

    // Show inter-shot dialog for RandomRange drills (next target + intent).
    // Putting scoring game manages its own per-hole targets — no dialog needed.
    // Chipping scoring game needs the dialog for club selection + flight rating.
    final isChippingGame = _delegate is ChippingGameDelegate;
    final showTargetDialog =
        (widget.drill.targetDistanceMode == TargetDistanceMode.randomRange &&
            widget.drill.inputMode != InputMode.scoringGame) ||
        isChippingGame;
    if (showTargetDialog && !_ending && mounted) {
      // Update the random distance from the delegate's next hole.
      if (isChippingGame) {
        _currentRandomDistance = _delegate.currentTargetDistance;
      }
      if (_currentRandomDistance != null) {
        await _showNextTargetDialog();
      }
    }

    return result;
  }

  /// Inter-shot dialog for variable target drills.
  /// Shows next target distance, club picker, shape and effort selectors.
  /// For chipping games, shows flight (1/2/3) instead of shape/effort.
  Future<void> _showNextTargetDialog() async {
    String? shape = _shotShape;
    int? effort = _shotEffort;
    int? flightVal = _flight;
    String? clubId = _selectedClubId;
    final isChipping = _delegate is ChippingGameDelegate;

    // Build last hole summary for chipping game (3-box display).
    ({int hole, String par, String score, Color scoreColor})? lastHoleSummary;
    if (isChipping) {
      final chipping = _delegate as ChippingGameDelegate;
      final lastIdx = chipping.completedCount - 1;
      if (lastIdx >= 0) {
        final lastHole = chipping.holes[lastIdx];
        final strokes = lastHole.strokes ?? 0.0;
        final delta = strokes - lastHole.par;
        final scoreColor = delta < -0.05
            ? ColorTokens.successDefault
            : delta > 0.05
                ? ColorTokens.errorDestructive
                : ColorTokens.textPrimary;
        lastHoleSummary = (
          hole: lastHole.holeNumber,
          par: lastHole.par.toStringAsFixed(2),
          score: strokes.toStringAsFixed(2),
          scoreColor: scoreColor,
        );
      }
    }

    setState(() => _dialogOpen = true);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => NextTargetDialog(
        targetDistance: _currentRandomDistance?.round() ?? 0,
        initialShape: shape,
        initialEffort: effort,
        initialFlight: flightVal,
        initialClubLabel: _clubIdToLabel[clubId] ?? '',
        availableClubs: List.of(_availableClubs)
          ..sort((a, b) => a.clubType.index.compareTo(b.clubType.index)),
        clubIdToLabel: _clubIdToLabel,
        skillArea: widget.drill.skillArea,
        userId: widget.userId,
        showShotIntent: _showShotIntent,
        showFlightMode: isChipping,
        lastHoleSummary: lastHoleSummary,
        holePar: isChipping && (_delegate as ChippingGameDelegate).currentHole != null
            ? '${beatProximity((_delegate as ChippingGameDelegate).currentHole!.distanceYards)}ft'
            : null,
        onConfirm: (newClubId, newShape, newEffort, {int? flight}) {
          clubId = newClubId;
          shape = newShape;
          effort = newEffort;
          flightVal = flight;
        },
        onToggleShotIntent: (v) => _showShotIntent = v,
      ),
    );

    if (mounted) {
      setState(() {
        _dialogOpen = false;
        if (clubId != _selectedClubId) _clubIsPlayerChoice = true;
        _selectedClubId = clubId;
        _shotShape = shape;
        _shotEffort = effort;
        _flight = flightVal;
      });
    }
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
        // Suggest a random club at the start of each new set
        // for UserLed + ClubCarry transition drills.
        // Clear any target distance override for the new set
        // BEFORE suggesting a club (which may set a new override for
        // randomDistancePerSet drills).
        _targetDistanceOverride = null;
        _distanceIsPlayerChoice = false;
        _suggestRandomClubIfNeeded();
        if (mounted) setState(() {});
      }
    }
  }

  /// S14 §14.10 — Undo the last logged instance.
  Future<void> _undoLast() async {
    final deleted = await _controller.undoLastInstance();
    _delegate.onInstanceUndone(deleted);
    if (_shotLog.isNotEmpty) _shotLog.removeLast();
    // Restore previous random distance on undo.
    if (_randomDistanceHistory.isNotEmpty) {
      _currentRandomDistance = _randomDistanceHistory.removeLast();
    }
    if (mounted) setState(() {});
  }

  /// Edit a shot in the log — change zone (hit/miss label) or club.
  Future<void> _editShot(int index) async {
    final shot = _shotLog[index];
    final metrics = jsonDecode(shot.rawMetrics) as Map<String, dynamic>;
    final isGridDrill = metrics.containsKey('hit');

    // Build zone options from the drill's grid type.
    List<({String label, bool isHit})>? zoneOptions;
    if (isGridDrill) {
      zoneOptions = switch (widget.drill.gridType) {
        GridType.oneByThree => [
          (label: 'Miss Left', isHit: false),
          (label: 'Hit', isHit: true),
          (label: 'Miss Right', isHit: false),
        ],
        GridType.threeByOne => [
          (label: 'Miss Long', isHit: false),
          (label: 'Hit', isHit: true),
          (label: 'Miss Short', isHit: false),
        ],
        GridType.threeByThree => [
          (label: 'Long Left', isHit: false),
          (label: 'Long', isHit: false),
          (label: 'Long Right', isHit: false),
          (label: 'Left', isHit: false),
          (label: 'Hit', isHit: true),
          (label: 'Right', isHit: false),
          (label: 'Short Left', isHit: false),
          (label: 'Short', isHit: false),
          (label: 'Short Right', isHit: false),
        ],
        _ => null,
      };
    }

    String? newZoneLabel = shot.label;
    bool? newIsHit = shot.isHit;
    String? newClubId = shot.clubId;

    final changed = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditShotDialog(
        currentLabel: shot.label,
        currentClubId: shot.clubId,
        zoneOptions: zoneOptions,
        availableClubs: List.of(_availableClubs)
          ..sort((a, b) => a.clubType.index.compareTo(b.clubType.index)),
        clubIdToLabel: _clubIdToLabel,
        onConfirm: (label, isHit, clubId) {
          newZoneLabel = label;
          newIsHit = isHit;
          newClubId = clubId;
        },
      ),
    );

    if (changed != true || !mounted) return;

    // Build updated raw metrics.
    if (isGridDrill) {
      metrics['hit'] = newIsHit;
      metrics['label'] = newZoneLabel;
    }
    final newRawMetrics = jsonEncode(metrics);

    // Update the Instance in the DB.
    await ref.read(practiceRepositoryProvider).updateInstanceRaw(
          shot.instanceId,
          InstancesCompanion(
            rawMetrics: Value(newRawMetrics),
            selectedClub: Value(newClubId),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // Update the shot log entry.
    _shotLog[index] = ShotEntry(
      instanceId: shot.instanceId,
      label: newZoneLabel ?? shot.label,
      isHit: newIsHit ?? shot.isHit,
      club: _clubIdToLabel[newClubId] ?? shot.club,
      clubId: newClubId,
      rawMetrics: newRawMetrics,
      score: shot.score,
    );
    setState(() {});
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
    // Refresh clubs in case mappings were edited.
    await _loadClubs();
    await _loadCarryDistances();
    final sorted = List.of(_availableClubs)
      ..sort((a, b) => a.clubType.index.compareTo(b.clubType.index));
    final clubNames = sorted.map((c) => c.clubType.dbValue).toList();
    final isChipping = _delegate is ChippingGameDelegate;
    final result = await showClubGridPicker(
      context,
      clubs: clubNames,
      selectedClub: _selectedClubLabel,
      skillArea: widget.drill.skillArea,
      userId: widget.userId,
      showShotIntent: _showShotIntent,
      showFlightMode: isChipping,
      initialShape: _shotShape,
      initialEffort: _shotEffort,
      initialFlight: _flight,
      onToggleShotIntent: (v) => _showShotIntent = v,
    );
    if (result != null && mounted) {
      // Reload again in case "Edit Clubs" changed mappings during the dialog.
      await _loadClubs();
      await _loadCarryDistances();
      setState(() {
        _selectedClubId = result.clubId;
        _clubIsPlayerChoice = true;
        _shotShape = result.shotShape;
        _shotEffort = result.shotEffort;
        if (result.flight != null) _flight = result.flight;
      });
    }
  }

  /// Let the user override the target distance via a scroll wheel dialog.
  Future<void> _editTargetDistance() async {
    final range = _targetDistanceRange;
    final current = (_effectiveTargetDistance ?? range.$1).round();
    final min = range.$1.round();
    final max = range.$2.round();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => TargetDistancePickerDialog(
        current: current,
        min: min,
        max: max,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result < 0) {
          _targetDistanceOverride = null;
          _distanceIsPlayerChoice = false;
        } else {
          _targetDistanceOverride = result;
          _distanceIsPlayerChoice = true;
        }
      });
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
      dialogOpen: _dialogOpen,
      selectedClub: _selectedClubId,
      currentSetId: _controller.currentSetId,
      shotShape: _shotShape,
      shotEffort: _shotEffort,
      flight: _flight,
      resolvedTargetDistance: _effectiveTargetDistance,
      resolvedTargetWidth: _currentTargetWidth,
      resolvedTargetDepth: _currentTargetDepth,
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
                      // Sync delegate-driven target distance into the
                      // random distance slot so the distance box picks it up.
                      ..._syncDelegateTargetDistance(),
                      // Delegate status line — chipping uses 25/50/25 layout.
                      if (_delegate is ChippingGameDelegate && _delegate.statusLine != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.lg,
                            vertical: SpacingTokens.xs,
                          ),
                          child: Column(
                            children: [
                              // Labels row: 75 Current Hole | 25 Round Score.
                              Row(
                                children: [
                                  const Expanded(
                                    flex: 75,
                                    child: Text(
                                      'Current Hole',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: TypographyTokens.bodySmSize,
                                        fontWeight: FontWeight.w600,
                                        color: ColorTokens.textTertiary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 25,
                                    child: Text(
                                      'Round Score',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: TypographyTokens.bodySmSize,
                                        color: ColorTokens.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: SpacingTokens.xs),
                              // Values row: 75 Hole X • Par Y | 25 +/-.
                              Row(
                                children: [
                                  Expanded(
                                    flex: 75,
                                    child: Text(
                                      _delegate.statusLine!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: TypographyTokens.bodyLgSize,
                                        fontWeight: FontWeight.w600,
                                        color: ColorTokens.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 25,
                                    child: Center(
                                      child: _delegate.statusTrailing ?? const SizedBox(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      // Non-chipping status line (centered, trailing inline).
                      else if (_delegate.statusLine != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.lg,
                            vertical: SpacingTokens.xs,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _delegate.statusLine!,
                                style: TextStyle(
                                  fontSize: TypographyTokens.bodyLgSize,
                                  fontWeight: FontWeight.w600,
                                  color: ColorTokens.textSecondary,
                                ),
                              ),
                              if (_delegate.statusTrailing != null) ...[
                                const SizedBox(width: SpacingTokens.md),
                                _delegate.statusTrailing!,
                              ],
                            ],
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
    final isChipping = _delegate is ChippingGameDelegate;
    return Expanded(
      flex: isChipping ? 40 : 50, // Chipping: 40:60 with input area
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
                                widget.drill.inputMode == InputMode.scoringGame
                                    ? 'No holes recorded'
                                    : 'No shots recorded',
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
                                return GestureDetector(
                                  onTap: () => _editShot(index),
                                  child: ShotLogRow(
                                    index: index + 1,
                                    shot: shot,
                                  ),
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
                                    color: _muteCyan(ColorTokens.primaryDefault),
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
                            size: ZxPillSize.sm,
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

  /// For UserLed + RandomDistancePerSet drills, suggest a club and lock target.
  /// ClubCarry (Free Practice) drills start blank — user picks.
  /// Called at init and at the start of each new set.
  void _suggestRandomClubIfNeeded() {
    if (widget.drill.clubSelectionMode != ClubSelectionMode.userLed) return;
    if (widget.drill.targetDistanceMode != TargetDistanceMode.randomDistancePerSet) {
      return;
    }
    if (_availableClubs.isEmpty) return;
    final candidates = _availableClubs.length > 1
        ? _availableClubs.where((c) => c.clubId != _selectedClubId).toList()
        : _availableClubs;
    final pick = candidates[_random.nextInt(candidates.length)];
    _selectedClubId = pick.clubId;
    _clubIsPlayerChoice = false;

    // For randomDistancePerSet: lock the target distance from this club's carry ±2%.
    if (widget.drill.targetDistanceMode == TargetDistanceMode.randomDistancePerSet) {
      final carry = _clubCarryDistances[pick.clubId];
      if (carry != null) {
        final jitter = carry * 0.02 * (2 * _random.nextDouble() - 1);
        _targetDistanceOverride = carry + jitter;
        _distanceIsPlayerChoice = false;
      }
    }
  }

  void _showFixedMessage(String field) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$field is fixed for this drill'),
        duration: const Duration(seconds: 2),
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

    // Dynamic club status label.
    final ({String label, Color color}) clubStatus;
    if (isRandom) {
      clubStatus = (label: 'Fixed Random', color: ColorTokens.ragAmber);
    } else if (isGuided) {
      clubStatus = (label: 'Fixed Sequence', color: ColorTokens.ragAmber);
    } else if (_clubIsPlayerChoice || _delegate is ChippingGameDelegate) {
      clubStatus = (label: 'Player Choice', color: ColorTokens.successDefault);
    } else if (widget.drill.clubSelectionMode == ClubSelectionMode.userLed) {
      clubStatus = (label: 'Suggested', color: ColorTokens.primaryDefault);
    } else {
      clubStatus = (label: '', color: ColorTokens.textTertiary);
    }

    // Dynamic distance status label.
    final ({String label, Color color}) distanceStatus;
    if (widget.drill.targetDistanceMode == TargetDistanceMode.randomRange) {
      distanceStatus = (label: 'Fixed Random', color: ColorTokens.ragAmber);
    } else if (widget.drill.targetDistanceMode == TargetDistanceMode.randomDistancePerSet) {
      distanceStatus = (label: 'Fixed Static', color: ColorTokens.ragAmber);
    } else if (_distanceIsPlayerChoice) {
      distanceStatus = (label: 'Player Choice', color: ColorTokens.successDefault);
    } else if (widget.drill.targetDistanceMode == TargetDistanceMode.clubCarry) {
      distanceStatus = (label: 'Suggested', color: ColorTokens.primaryDefault);
    } else if (widget.drill.targetDistanceMode == TargetDistanceMode.fixed) {
      distanceStatus = (label: 'Fixed Static', color: ColorTokens.ragAmber);
    } else {
      distanceStatus = (label: 'Target Distance', color: ColorTokens.textTertiary);
    }

    return IntrinsicHeight(
      child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left half — target distance (tappable to override).
        Expanded(
          child: GestureDetector(
            onTap: (widget.drill.targetDistanceMode == TargetDistanceMode.randomRange ||
                    widget.drill.targetDistanceMode == TargetDistanceMode.randomDistancePerSet)
                ? () => _showFixedMessage('Target')
                : _editTargetDistance,
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
                if (distanceStatus.label.isNotEmpty)
                  Text(
                    distanceStatus.label,
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySize,
                      fontStyle: FontStyle.italic,
                      color: _muteCyan(distanceStatus.color),
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
                    color: (_effectiveTargetDistance != null &&
                            distanceStatus.color != ColorTokens.textTertiary &&
                            distanceStatus.color != ColorTokens.ragAmber)
                        ? _muteCyan(ColorTokens.primaryDefault)
                        : const Color(0xFF3A4048),
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
        ),
        const SizedBox(width: SpacingTokens.sm),
        // Right half — club selection.
        Expanded(
          child: GestureDetector(
            onTap: isTappable
                ? _pickClub
                : (isRandom || isGuided)
                    ? () => _showFixedMessage('Club')
                    : null,
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
                  if (clubStatus.label.isNotEmpty)
                    Text(
                      clubStatus.label,
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySize,
                        fontStyle: FontStyle.italic,
                        color: _muteCyan(clubStatus.color),
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
                      color: (isRandom || isGuided)
                          ? const Color(0xFF3A4048)
                          : _muteCyan(ColorTokens.primaryDefault),
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

  /// Sync delegate-driven target distance (e.g. scoring game hole distance)
  /// into `_currentRandomDistance` so the distance box displays it.
  List<Widget> _syncDelegateTargetDistance() {
    final delegateDist = _delegate.currentTargetDistance;
    if (delegateDist != null) {
      _currentRandomDistance = delegateDist;
    }
    return const [];
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
      _showShotIntent = prefs.showShotIntent;
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
          Vibration.vibrate(duration: 50, amplitude: 200);
        case 'hard':
          Vibration.vibrate(duration: 80, amplitude: 255);
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

    // For 1x3 (direction): the center 1/3 is the hit zone — show width bar.
    // For 3x1 (distance): no width bar — only vertical depth bar.
    // For 3x3: center column is the hit zone (1/3 width) — show width bar.
    if (gridType == GridType.threeByOne) {
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
    // Override takes priority.
    if (_targetDistanceOverride != null) {
      return '${_targetDistanceOverride!.round()}y';
    }

    double? value;
    DrillLengthUnit? unit;

    if (widget.drill.targetDistanceMode ==
        TargetDistanceMode.percentageOfClubCarry) {
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
      unit = widget.drill.targetDistanceUnit ?? DrillLengthUnit.yards;
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
    final unit = widget.drill.targetSizeUnit;
    // Use computed depth from club tier if available.
    final computed = _currentTargetDepth;
    if (computed != null) {
      return '${_formatYards(computed)}${_shortUnit(unit)}';
    }
    final value = widget.drill.targetSizeDepth;
    if (value == null) return _formatTargetDistance();
    return '${_formatYards(value)}${_shortUnit(unit)}';
  }

  /// Format target depth as half value for split vertical bar display.
  String _formatTargetDepthHalf() {
    final unit = widget.drill.targetSizeUnit;
    // Use computed depth from club tier if available.
    final computed = _currentTargetDepth;
    if (computed != null) {
      return '${_formatYards(computed / 2)}${_shortUnit(unit)}';
    }
    final value = widget.drill.targetSizeDepth;
    if (value == null) return '';
    return '${_formatYards(value / 2)}${_shortUnit(unit)}';
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
          ),
          // Center divider line.
          Container(
            height: 2,
            color: ColorTokens.successDefault.withValues(alpha: 0.6),
          ),
          // Bottom half: ↓ label (short side — arrow points down/outward)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
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
          ),
        ],
      ),
    );
  }

  /// Format target width value + unit for the horizontal target bar.
  /// For PercentageOfTargetDistance mode, computes from carry + club tier.
  String _formatTargetWidth() {
    final unit = widget.drill.targetSizeUnit;
    final computed = _currentTargetWidth;
    if (computed != null) {
      return '${_formatYards(computed)}${_shortUnit(unit)}';
    }

    final value = widget.drill.targetSizeWidth;
    if (value == null) return '';
    return '${_formatYards(value)}${_shortUnit(unit)}';
  }

  /// Format target width as half value for the split display.
  String _formatTargetWidthHalf() {
    final unit = widget.drill.targetSizeUnit;
    final computed = _currentTargetWidth;
    if (computed != null) {
      return '${_formatYards(computed / 2)}${_shortUnit(unit)}';
    }

    final value = widget.drill.targetSizeWidth;
    if (value == null) return '';
    return '${_formatYards(value / 2)}${_shortUnit(unit)}';
  }

  /// Format a yard value: under 10y rounds to nearest 0.5, 10+ rounds to int.
  /// Replace cyan with grey when a dialog is open over the execution screen.
  Color _muteCyan(Color color) {
    if (!_dialogOpen) return color;
    if (color == ColorTokens.primaryDefault) return ColorTokens.textTertiary;
    return color;
  }

  /// Format par value: show as x.0 or x.5.
  static String _formatPar(double? par) {
    if (par == null) return '';
    if (par == par.roundToDouble()) return par.toStringAsFixed(1);
    return par.toStringAsFixed(1);
  }

  static String _formatYards(double value) {
    if (value < 10) {
      final rounded = (value * 2).round() / 2;
      return rounded == rounded.roundToDouble()
          ? rounded.toInt().toString()
          : rounded.toStringAsFixed(1);
    }
    return value.round().toString();
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
          backgroundColor: _muteCyan(ColorTokens.primaryDefault),
        ),
        child: const Text('End Drill'),
      ),
    );
  }
}

