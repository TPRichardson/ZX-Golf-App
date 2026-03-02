// Phase 4 — Grid Cell execution screen.
// S14 §14.3 — Grid cell input for direction (1×3) and distance (3×1) drills.
// 1×3: [Miss Left] [Hit] [Miss Right] — horizontal row, single tap.
// 3×1: [Miss Long] [Hit] [Miss Short] — vertical column, single tap.
// S15 §15.8.3 — 120ms successDefault flash on hit, haptic tick.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/club_selector.dart';
import 'package:zx_golf_app/features/practice/widgets/execution_header.dart';
import 'package:zx_golf_app/features/practice/widgets/score_flash.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

/// S14 §14.3 — Grid cell input screen.
/// 1×3 direction: 3 cells in a row — Miss Left, Hit, Miss Right.
/// 3×1 distance: 3 cells in a column — Miss Long, Hit, Miss Short.
/// Single tap on any cell logs that outcome.
class GridCellScreen extends ConsumerStatefulWidget {
  final Drill drill;
  final Session session;
  final String userId;

  const GridCellScreen({
    super.key,
    required this.drill,
    required this.session,
    required this.userId,
  });

  @override
  ConsumerState<GridCellScreen> createState() => _GridCellScreenState();
}

class _GridCellScreenState extends ConsumerState<GridCellScreen> {
  late SessionExecutionController _controller;
  bool _initialized = false;
  bool _lastHit = false;
  bool _showFlash = false;
  bool _ending = false;
  String _selectedClub = 'Putter';
  List<String> _availableClubs = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _initController();
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

  /// Cell definitions for the current grid type.
  List<_CellDef> get _cells {
    return switch (widget.drill.gridType) {
      GridType.oneByThree || null => [
          _CellDef('Miss Left', false, Icons.arrow_back),
          _CellDef('Hit', true, Icons.gps_fixed),
          _CellDef('Miss Right', false, Icons.arrow_forward),
        ],
      GridType.threeByOne => [
          _CellDef('Miss Long', false, Icons.arrow_upward),
          _CellDef('Hit', true, Icons.gps_fixed),
          _CellDef('Miss Short', false, Icons.arrow_downward),
        ],
      GridType.threeByThree => _build3x3Cells(),
    };
  }

  List<_CellDef> _build3x3Cells() {
    return [
      _CellDef('Long Left', false, Icons.north_west),
      _CellDef('Long', false, Icons.arrow_upward),
      _CellDef('Long Right', false, Icons.north_east),
      _CellDef('Left', false, Icons.arrow_back),
      _CellDef('Hit', true, Icons.gps_fixed),
      _CellDef('Right', false, Icons.arrow_forward),
      _CellDef('Short Left', false, Icons.south_west),
      _CellDef('Short', false, Icons.arrow_downward),
      _CellDef('Short Right', false, Icons.south_east),
    ];
  }

  bool get _isVertical => widget.drill.gridType == GridType.threeByOne;

  Future<void> _onCellTap(_CellDef cell) async {
    if (!_initialized || _ending) return;

    // S15 §15.8.3 — Haptic tick.
    HapticFeedback.lightImpact();

    // TD-06 §9.1.2 — Random mode picks a new club per instance.
    if (widget.drill.clubSelectionMode == ClubSelectionMode.random &&
        _availableClubs.isNotEmpty) {
      setState(() {
        _selectedClub =
            _availableClubs[_random.nextInt(_availableClubs.length)];
      });
    }

    final setId = _controller.currentSetId!;
    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: setId,
      selectedClub: _selectedClub,
      rawMetrics: jsonEncode({
        'hit': cell.isHit,
        'label': cell.label,
      }),
    );

    await _controller.logInstance(data);

    // Reset inactivity timer.
    ref.read(timerServiceProvider).resetSessionInactivityTimer(
          widget.session.sessionId,
          const Duration(hours: 2),
        );

    setState(() {
      _lastHit = cell.isHit;
      _showFlash = true;
    });

    // Clear flash after animation completes.
    Future.delayed(MotionTokens.fast, () {
      if (mounted) setState(() => _showFlash = false);
    });

    // S13 §13.7 — Auto-advance set if structured.
    if (_controller.isCurrentSetComplete()) {
      if (_controller.isSessionAutoComplete()) {
        await _endSession();
      } else {
        await _controller.advanceSet();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _endSession() async {
    if (_ending) return;
    setState(() => _ending = true);
    final actions = ref.read(practiceActionsProvider);
    final result =
        await actions.endSession(widget.session.sessionId, widget.userId);

    if (!mounted) return;

    // S13 §13.13 — Show post-session summary.
    final closedSession = await ref
        .read(practiceRepositoryProvider)
        .getSessionById(widget.session.sessionId);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PostSessionSummaryScreen(
          drill: widget.drill,
          session: closedSession ?? widget.session,
          sessionScore: result.sessionScore,
          integrityBreach: result.integrityBreach,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: ColorTokens.surfaceBase,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cells = _cells;
    final is3x3 = widget.drill.gridType == GridType.threeByThree;

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: ScoreFlash(
          isHit: _lastHit,
          key: ValueKey(
              _showFlash ? DateTime.now().microsecondsSinceEpoch : 0),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: is3x3
                      ? _build3x3Grid(cells)
                      : _build1x3Or3x1(cells),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// 1×3 (horizontal row) or 3×1 (vertical column) with 3 labeled cells.
  Widget _build1x3Or3x1(List<_CellDef> cells) {
    final isVert = _isVertical;

    return Center(
      child: isVert
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) const SizedBox(height: SpacingTokens.sm),
                  _buildLabeledCell(cells[i], isVert),
                ],
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) const SizedBox(width: SpacingTokens.sm),
                  Expanded(child: _buildLabeledCell(cells[i], isVert)),
                ],
              ],
            ),
    );
  }

  Widget _buildLabeledCell(_CellDef cell, bool isVertical) {
    final color =
        cell.isHit ? ColorTokens.successDefault : ColorTokens.missDefault;
    final borderColor =
        cell.isHit ? ColorTokens.successHover : ColorTokens.missBorder;

    final content = Material(
      color: color,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
      child: InkWell(
        onTap: () => _onCellTap(cell),
        borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
        splashColor: cell.isHit
            ? ColorTokens.successActive.withValues(alpha: 0.3)
            : ColorTokens.missActive.withValues(alpha: 0.3),
        child: Container(
          height: isVertical ? 100 : null,
          constraints: isVertical
              ? null
              : const BoxConstraints(minHeight: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusGrid),
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cell.icon, color: ColorTokens.textPrimary, size: 28),
                const SizedBox(height: SpacingTokens.xs),
                Text(
                  cell.label,
                  style: TextStyle(
                    fontSize: TypographyTokens.bodySize,
                    fontWeight: FontWeight.w500,
                    color: ColorTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isVertical) {
      return SizedBox(
        width: double.infinity,
        child: content,
      );
    }
    return content;
  }

  /// 3×3 grid using GridView.
  Widget _build3x3Grid(List<_CellDef> cells) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: SpacingTokens.sm,
        crossAxisSpacing: SpacingTokens.sm,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        final cell = cells[index];
        return _buildLabeledCell(cell, false);
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      decoration: const BoxDecoration(
        color: ColorTokens.surfaceRaised,
        border: Border(
          top: BorderSide(color: ColorTokens.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Tap the cell matching your shot result',
              style: TextStyle(
                fontSize: TypographyTokens.bodySize,
                color: ColorTokens.textSecondary,
              ),
            ),
          ),
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
    );
  }
}

/// Describes a single cell in the grid.
class _CellDef {
  final String label;
  final bool isHit;
  final IconData icon;

  const _CellDef(this.label, this.isHit, this.icon);
}
