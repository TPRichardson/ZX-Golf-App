// Phase 4 — Binary Hit/Miss execution screen.
// S14 §14.3 — Two-button Hit/Miss input.

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
import 'package:zx_golf_app/features/practice/widgets/bulk_entry_dialog.dart';
import 'package:zx_golf_app/features/practice/widgets/club_selector.dart';
import 'package:zx_golf_app/features/practice/widgets/execution_header.dart';
import 'package:zx_golf_app/features/practice/widgets/set_transition_overlay.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

/// S14 §14.3 — Binary hit/miss input screen.
class BinaryHitMissScreen extends ConsumerStatefulWidget {
  final Drill drill;
  final Session session;
  final String userId;

  const BinaryHitMissScreen({
    super.key,
    required this.drill,
    required this.session,
    required this.userId,
  });

  @override
  ConsumerState<BinaryHitMissScreen> createState() =>
      _BinaryHitMissScreenState();
}

class _BinaryHitMissScreenState extends ConsumerState<BinaryHitMissScreen> {
  late SessionExecutionController _controller;
  bool _initialized = false;
  bool _ending = false;
  int _hitCount = 0;
  int _missCount = 0;
  String _selectedClub = 'Putter';
  List<String> _availableClubs = [];
  late SurfaceType? _surfaceType = widget.session.surfaceType;
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

  Future<void> _recordHitMiss(bool isHit) async {
    if (!_initialized || _ending) return;

    HapticFeedback.lightImpact();

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
      rawMetrics: jsonEncode({'hit': isHit}),
    );

    await _controller.logInstance(data);

    ref.read(timerServiceProvider).resetSessionInactivityTimer(
          widget.session.sessionId,
          const Duration(hours: 2),
        );

    setState(() {
      if (isHit) {
        _hitCount++;
      } else {
        _missCount++;
      }
    });

    if (_controller.isCurrentSetComplete()) {
      if (_controller.isSessionAutoComplete()) {
        await _endSession();
      } else {
        // S14 §14.10 — Set transition interstitial.
        if (mounted) {
          await SetTransitionOverlay.show(context,
              completedSetIndex: _controller.currentSetIndex);
        }
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

    // Gap 39–42 — Disable submission while scoring lock is held.
    final isLocked = ref.watch(scoringLockActiveProvider).valueOrNull ?? false;

    final total = _hitCount + _missCount;
    final hitRate = total > 0 ? (_hitCount / total * 100).round() : 0;

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
              if (widget.drill.clubSelectionMode != null &&
                  _availableClubs.isNotEmpty)
                ClubSelector(
                  mode: widget.drill.clubSelectionMode!,
                  availableClubs: _availableClubs,
                  selectedClub: _selectedClub,
                  onClubSelected: (club) =>
                      setState(() => _selectedClub = club),
                ),
              // Running stats.
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatBox(label: 'Hits', value: '$_hitCount',
                        color: ColorTokens.successDefault),
                    _StatBox(label: 'Misses', value: '$_missCount',
                        color: ColorTokens.missDefault),
                    _StatBox(label: 'Rate', value: '$hitRate%',
                        color: ColorTokens.primaryDefault),
                  ],
                ),
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
              // Hit/Miss buttons.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HitMissButton(
                          label: 'MISS',
                          color: isLocked
                              ? ColorTokens.missDefault
                                  .withValues(alpha: 0.4)
                              : ColorTokens.missDefault,
                          borderColor: ColorTokens.missBorder,
                          onTap: isLocked
                              ? () {}
                              : () => _recordHitMiss(false),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.md),
                      Expanded(
                        child: _HitMissButton(
                          label: 'HIT',
                          color: isLocked
                              ? ColorTokens.successDefault
                                  .withValues(alpha: 0.4)
                              : ColorTokens.successDefault,
                          borderColor: ColorTokens.successActive,
                          onTap: isLocked
                              ? () {}
                              : () => _recordHitMiss(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      );
  }

  // Fix 4 — Bulk add hits or misses.
  Future<void> _bulkAdd(bool isHit) async {
    if (!_initialized || _ending) return;
    final count = await showBulkEntryDialog(
      context,
      maxCount: _controller.remainingSetCapacity,
      title: isHit ? 'Bulk Add Hits' : 'Bulk Add Misses',
    );
    if (count == null || count <= 0) return;

    final setId = _controller.currentSetId!;
    final added = await _controller.logBulkInstances(count, (i) {
      return InstancesCompanion.insert(
        instanceId: const Uuid().v4(),
        setId: setId,
        selectedClub: _selectedClub,
        rawMetrics: jsonEncode({'hit': isHit}),
      );
    });

    if (!mounted) return;
    setState(() {
      if (isHit) {
        _hitCount += added;
      } else {
        _missCount += added;
      }
    });

    if (_controller.isCurrentSetComplete()) {
      if (_controller.isSessionAutoComplete()) {
        await _endSession();
      } else {
        // S14 §14.10 — Set transition interstitial.
        if (mounted) {
          await SetTransitionOverlay.show(context,
              completedSetIndex: _controller.currentSetIndex);
        }
        await _controller.advanceSet();
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _changeSurface() async {
    final newSurface = await showSurfacePicker(context);
    if (newSurface != null && mounted) {
      await ref.read(practiceRepositoryProvider).updateSessionSurface(
          widget.session.sessionId, newSurface);
      setState(() => _surfaceType = newSurface);
    }
  }

  /// S14 §14.10 — Undo the last logged instance.
  Future<void> _undoLast() async {
    final deleted = await _controller.undoLastInstance();
    if (deleted == null || !mounted) return;

    final metrics = jsonDecode(deleted.rawMetrics) as Map<String, dynamic>;
    final wasHit = metrics['hit'] as bool? ?? false;
    setState(() {
      if (wasHit) {
        _hitCount = (_hitCount - 1).clamp(0, _hitCount);
      } else {
        _missCount = (_missCount - 1).clamp(0, _missCount);
      }
    });
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
              // Fix 4 — Bulk add buttons.
              TextButton.icon(
                onPressed: () => _bulkAdd(true),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Bulk Hits'),
              ),
              TextButton.icon(
                onPressed: () => _bulkAdd(false),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Bulk Misses'),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: TypographyTokens.displayLgSize,
            fontWeight: TypographyTokens.displayLgWeight,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: TypographyTokens.microSize,
            color: ColorTokens.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HitMissButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _HitMissButton({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: TypographyTokens.displayLgSize,
                fontWeight: TypographyTokens.displayLgWeight,
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
