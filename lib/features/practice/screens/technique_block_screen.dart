// Phase 4 — Technique Block execution screen.
// S14 §14.3 — Timer-only execution, no scoring.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zx_golf_app/core/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';
import 'package:zx_golf_app/features/practice/widgets/surface_picker.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/repository_providers.dart';

/// S14 §14.3 — Technique block: timer-only, single Instance with duration.
class TechniqueBlockScreen extends ConsumerStatefulWidget {
  final Drill drill;
  final Session session;
  final String userId;

  const TechniqueBlockScreen({
    super.key,
    required this.drill,
    required this.session,
    required this.userId,
  });

  @override
  ConsumerState<TechniqueBlockScreen> createState() =>
      _TechniqueBlockScreenState();
}

class _TechniqueBlockScreenState extends ConsumerState<TechniqueBlockScreen> {
  late SessionExecutionController _controller;
  bool _initialized = false;
  bool _running = false;
  bool _ending = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  late SurfaceType? _surfaceType = widget.session.surfaceType;

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
    if (mounted) {
      ref.read(practiceExecutionActiveProvider.notifier).state = true;
      setState(() => _initialized = true);
    }
  }

  @override
  void dispose() {
    ref.read(practiceExecutionActiveProvider.notifier).state = false;
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _changeSurface() async {
    final result = await showEnvironmentSurfacePicker(context);
    if (result != null && mounted) {
      await ref.read(practiceRepositoryProvider).updateSessionSurface(
          widget.session.sessionId, result.surface);
      setState(() => _surfaceType = result.surface);
    }
  }

  Future<void> _finishBlock() async {
    if (_ending) return;
    _stopTimer();
    setState(() => _ending = true);

    // Log single Instance with duration.
    final setId = _controller.currentSetId!;
    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: setId,
      selectedClub: 'N/A',
      rawMetrics: jsonEncode({'duration': _elapsedSeconds}),
    );

    await _controller.logInstance(data);

    // End session (technique blocks have no scoring).
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

  String _formatDuration(int totalSeconds) =>
      formatDuration(totalSeconds, padMinutes: true);

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: ColorTokens.surfaceBase,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: ColorTokens.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: const BoxDecoration(
                color: ColorTokens.surfaceRaised,
                border: Border(
                  bottom: BorderSide(color: ColorTokens.surfaceBorder),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.drill.name,
                      style: TextStyle(
                        fontSize: TypographyTokens.headerSize,
                        fontWeight: TypographyTokens.headerWeight,
                        color: ColorTokens.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: ColorTokens.surfaceModal,
                      borderRadius:
                          BorderRadius.circular(ShapeTokens.radiusGrid),
                    ),
                    child: Text(
                      'Technique',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodySmSize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Timer display.
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDuration(_elapsedSeconds),
                      style: const TextStyle(
                        fontSize: TypographyTokens.displayXxlSize,
                        fontWeight: TypographyTokens.displayXxlWeight,
                        color: ColorTokens.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.sm),
                    Text(
                      _running ? 'In progress...' : 'Ready to start',
                      style: TextStyle(
                        fontSize: TypographyTokens.bodyLgSize,
                        color: ColorTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Controls.
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (!_running && _elapsedSeconds == 0)
                        Expanded(
                          child: FilledButton(
                            onPressed: _startTimer,
                            style: FilledButton.styleFrom(
                              backgroundColor: ColorTokens.successDefault,
                              padding: const EdgeInsets.symmetric(
                                  vertical: SpacingTokens.md),
                            ),
                            child: const Text('Start'),
                          ),
                        )
                      else if (_running) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _stopTimer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ColorTokens.warningIntegrity,
                              side: const BorderSide(
                                  color: ColorTokens.warningIntegrity),
                              padding: const EdgeInsets.symmetric(
                                  vertical: SpacingTokens.md),
                            ),
                            child: const Text('Pause'),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: _finishBlock,
                            style: FilledButton.styleFrom(
                              backgroundColor: ColorTokens.primaryDefault,
                              padding: const EdgeInsets.symmetric(
                                  vertical: SpacingTokens.md),
                            ),
                            child: const Text('Finish'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _startTimer,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ColorTokens.successDefault,
                              side: const BorderSide(
                                  color: ColorTokens.successDefault),
                              padding: const EdgeInsets.symmetric(
                                  vertical: SpacingTokens.md),
                            ),
                            child: const Text('Resume'),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: _finishBlock,
                            style: FilledButton.styleFrom(
                              backgroundColor: ColorTokens.primaryDefault,
                              padding: const EdgeInsets.symmetric(
                                  vertical: SpacingTokens.md),
                            ),
                            child: const Text('Finish'),
                          ),
                        ),
                      ],
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
            ),
          ],
        ),
      ),
    );
  }
}
