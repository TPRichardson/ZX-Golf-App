// Phase 4 — Continuous Measurement execution screen.
// S14 §14.3 — Numeric input for distance/deviation measurements.

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
import 'package:zx_golf_app/providers/bag_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

/// S14 §14.3 — Continuous measurement input (distance/deviation).
class ContinuousMeasurementScreen extends ConsumerStatefulWidget {
  final Drill drill;
  final Session session;
  final String userId;

  const ContinuousMeasurementScreen({
    super.key,
    required this.drill,
    required this.session,
    required this.userId,
  });

  @override
  ConsumerState<ContinuousMeasurementScreen> createState() =>
      _ContinuousMeasurementScreenState();
}

class _ContinuousMeasurementScreenState
    extends ConsumerState<ContinuousMeasurementScreen> {
  late SessionExecutionController _controller;
  final _valueController = TextEditingController();
  bool _initialized = false;
  bool _ending = false;
  double? _lastScore;
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
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _submitValue() async {
    final text = _valueController.text.trim();
    if (text.isEmpty || _ending) return;

    final value = double.tryParse(text);
    if (value == null) return;

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
      rawMetrics: jsonEncode({'value': value}),
    );

    final result = await _controller.logInstance(data);
    _valueController.clear();

    ref.read(timerServiceProvider).resetSessionInactivityTimer(
          widget.session.sessionId,
          const Duration(hours: 2),
        );

    setState(() => _lastScore = result.realtimeScore);

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_lastScore != null) ...[
                      Text(
                        _lastScore!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: TypographyTokens.displayXlSize,
                          fontWeight: TypographyTokens.displayXlWeight,
                          color: ColorTokens.successDefault,
                        ),
                      ),
                      Text(
                        'Last Score',
                        style: TextStyle(
                          fontSize: TypographyTokens.bodySize,
                          color: ColorTokens.textSecondary,
                        ),
                      ),
                      const SizedBox(height: SpacingTokens.xl),
                    ],
                    TextField(
                      controller: _valueController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$')),
                      ],
                      style: TextStyle(
                        fontSize: TypographyTokens.displayLgSize,
                        color: ColorTokens.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter measurement',
                        hintStyle: TextStyle(
                          color: ColorTokens.textTertiary,
                        ),
                        filled: true,
                        fillColor: ColorTokens.surfacePrimary,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(ShapeTokens.radiusInput),
                          borderSide:
                              const BorderSide(color: ColorTokens.surfaceBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(ShapeTokens.radiusInput),
                          borderSide:
                              const BorderSide(color: ColorTokens.surfaceBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(ShapeTokens.radiusInput),
                          borderSide: const BorderSide(
                              color: ColorTokens.primaryDefault),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      onSubmitted: (_) => _submitValue(),
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    // Gap 42 — Inline lock indicator.
                    if (isLocked)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: SpacingTokens.sm),
                        child: Text(
                          'Updating scores\u2026',
                          style: TextStyle(
                            fontSize: TypographyTokens.bodySize,
                            color: ColorTokens.textTertiary,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLocked ? null : _submitValue,
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorTokens.primaryDefault,
                          padding: const EdgeInsets.symmetric(
                              vertical: SpacingTokens.md),
                        ),
                        child: const Text('Record'),
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

  // Fix 4 — Bulk add instances with the current input value.
  Future<void> _bulkAdd() async {
    final text = _valueController.text.trim();
    if (text.isEmpty || _ending) return;
    final value = double.tryParse(text);
    if (value == null) return;

    final count = await showBulkEntryDialog(
      context,
      maxCount: _controller.remainingSetCapacity,
    );
    if (count == null || count <= 0) return;

    final setId = _controller.currentSetId!;
    await _controller.logBulkInstances(count, (i) {
      return InstancesCompanion.insert(
        instanceId: const Uuid().v4(),
        setId: setId,
        selectedClub: _selectedClub,
        rawMetrics: jsonEncode({'value': value}),
      );
    });

    _valueController.clear();
    if (!mounted) return;
    setState(() {});

    if (_controller.isCurrentSetComplete()) {
      if (_controller.isSessionAutoComplete()) {
        await _endSession();
      } else {
        await _controller.advanceSet();
        if (mounted) setState(() {});
      }
    }
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
          // Fix 4 — Bulk add button.
          TextButton.icon(
            onPressed: _bulkAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Bulk Add'),
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
    );
  }
}
