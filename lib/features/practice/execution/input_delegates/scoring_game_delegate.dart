// Scoring game input delegate — hole-by-hole stroke entry for putting rounds.
// Each hole shows a randomised distance. Player taps stroke count to advance.
// Session auto-completes after the final hole.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/widgets/shot_record_button.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

/// A single hole in the scoring game round.
class ScoringGameHole {
  final int holeNumber;
  final String category;
  final int distanceFeet;
  final int par;
  int? strokes;

  ScoringGameHole({
    required this.holeNumber,
    required this.category,
    required this.distanceFeet,
    required this.par,
  });

  int get plusMinus => (strokes ?? par) - par;
  bool get isComplete => strokes != null;
}

class ScoringGameDelegate extends ExecutionInputDelegate {
  final Drill? drill;
  late final List<ScoringGameHole> holes;
  int _currentHoleIndex = 0;
  int _selectedStrokes = 2;

  /// Running totals.
  int get totalStrokes =>
      holes.where((h) => h.isComplete).fold(0, (sum, h) => sum + h.strokes!);
  int get totalPar =>
      holes.where((h) => h.isComplete).fold(0, (sum, h) => sum + h.par);
  int get plusMinusPar => totalStrokes - totalPar;
  int get completedCount => holes.where((h) => h.isComplete).length;
  bool get isRoundComplete => completedCount >= holes.length;
  ScoringGameHole? get currentHole =>
      _currentHoleIndex < holes.length ? holes[_currentHoleIndex] : null;

  ScoringGameDelegate({this.drill}) {
    holes = _generateHoles();
  }

  @override
  double? get currentTargetDistance => currentHole?.distanceFeet.toDouble();

  @override
  String? get statusLine {
    final hole = currentHole;
    if (hole == null) return null;
    return 'Hole ${hole.holeNumber}  •  Par ${hole.par}  •';
  }

  @override
  Widget? get statusTrailing => _PlusMinusChip(value: plusMinusPar);

  List<ScoringGameHole> _generateHoles() {
    final config = _parseConfig();
    final rng = Random();
    final generated = <ScoringGameHole>[];
    var holeNum = 1;

    for (final cat in config.categories) {
      for (var i = 0; i < cat.holeCount; i++) {
        final dist = cat.minDistance +
            rng.nextInt(cat.maxDistance - cat.minDistance + 1);
        generated.add(ScoringGameHole(
          holeNumber: holeNum++,
          category: cat.name,
          distanceFeet: dist,
          par: config.par,
        ));
      }
    }

    // Randomise order.
    generated.shuffle(rng);
    // Re-number after shuffle.
    for (var i = 0; i < generated.length; i++) {
      generated[i] = ScoringGameHole(
        holeNumber: i + 1,
        category: generated[i].category,
        distanceFeet: generated[i].distanceFeet,
        par: generated[i].par,
      );
    }
    return generated;
  }

  _RoundConfig _parseConfig() {
    final schema = drill?.metricSchemaId;
    // Default config for scoring_game_strokes.
    if (schema == null) {
      return _RoundConfig(par: 2, categories: [
        _CategoryConfig('Short', 6, 10, 6),
        _CategoryConfig('Medium', 11, 20, 6),
        _CategoryConfig('Long', 21, 40, 6),
      ]);
    }
    // Config would be parsed from MetricSchema validationRules at runtime.
    // For now use the hardcoded config matching the seed data.
    return _RoundConfig(par: 2, categories: [
      _CategoryConfig('Short', 6, 10, 6),
      _CategoryConfig('Medium', 11, 20, 6),
      _CategoryConfig('Long', 21, 40, 6),
    ]);
  }

  @override
  Widget buildInputArea({
    required BuildContext context,
    required ExecutionContext executionContext,
    required LogInstanceCallback onLogInstance,
    required VoidCallback requestRebuild,
  }) {
    if (isRoundComplete) {
      return _buildRoundComplete(context);
    }

    final hole = currentHole!;
    final isLocked = executionContext.isLocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      child: Column(
        children: [
          // Stroke selector — vertically centred.
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Strokes',
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySmSize,
                      color: ColorTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.sm),
                  // Stroke buttons row.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StrokeAdjustButton(
                        icon: Icons.remove,
                        onTap: isLocked
                            ? null
                            : () {
                                if (_selectedStrokes > 1) {
                                  _selectedStrokes--;
                                  requestRebuild();
                                }
                              },
                      ),
                      const SizedBox(width: SpacingTokens.lg),
                      Text(
                        '$_selectedStrokes',
                        style: TextStyle(
                          fontSize: TypographyTokens.displayXxlSize,
                          fontWeight: TypographyTokens.displayXxlWeight,
                          color: _strokeColor(_selectedStrokes, hole.par),
                        ),
                      ),
                      const SizedBox(width: SpacingTokens.lg),
                      _StrokeAdjustButton(
                        icon: Icons.add,
                        onTap: isLocked
                            ? null
                            : () {
                                _selectedStrokes++;
                                requestRebuild();
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.xs),
                  Text(
                    _strokeLabel(_selectedStrokes, hole.par),
                    style: TextStyle(
                      fontSize: TypographyTokens.bodySmSize,
                      color: _strokeColor(_selectedStrokes, hole.par),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confirm button.
          ShotRecordButton(
            label: _currentHoleIndex < holes.length - 1
                ? 'Next Hole'
                : 'Finish Round',
            onPressed: isLocked
                ? null
                : () => _recordHole(executionContext, onLogInstance),
          ),
          SizedBox(height: SpacingTokens.lg + 8),
        ],
      ),
    );
  }

  Widget _buildRoundComplete(BuildContext context) {
    return Center(
      child: Text(
        'Round complete',
        style: TextStyle(
          fontSize: TypographyTokens.bodySize,
          color: ColorTokens.textSecondary,
        ),
      ),
    );
  }

  Future<void> _recordHole(
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
  ) async {
    if (ctx.isEnding || isRoundComplete) return;
    final hole = currentHole!;

    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: ctx.currentSetId!,
      selectedClub: const Value(null),
      rawMetrics: jsonEncode({
        'strokes': _selectedStrokes,
        'distance': hole.distanceFeet,
        'category': hole.category,
        'par': hole.par,
        'holeNumber': hole.holeNumber,
      }),
      resolvedTargetDistance: Value(hole.distanceFeet.toDouble()),
    );
    await onLogInstance(data);
  }

  @override
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {
    if (_currentHoleIndex < holes.length) {
      final metrics =
          jsonDecode(data.rawMetrics.value) as Map<String, dynamic>;
      holes[_currentHoleIndex].strokes = (metrics['strokes'] as num).toInt();
      _currentHoleIndex++;
      _selectedStrokes = 2; // Reset to par for next hole.
    }
  }

  @override
  void onInstanceUndone(Instance? deleted) {
    if (deleted == null || _currentHoleIndex <= 0) return;
    _currentHoleIndex--;
    holes[_currentHoleIndex].strokes = null;
  }

  Color _strokeColor(int strokes, int par) {
    if (strokes < par) return ColorTokens.successDefault;
    if (strokes == par) return ColorTokens.textPrimary;
    return ColorTokens.errorDestructive;
  }

  String _strokeLabel(int strokes, int par) {
    final diff = strokes - par;
    if (diff == 0) return 'Par';
    if (diff < 0) return '$diff (under)';
    return '+$diff (over)';
  }
}

class _RoundConfig {
  final int par;
  final List<_CategoryConfig> categories;
  const _RoundConfig({required this.par, required this.categories});
}

class _CategoryConfig {
  final String name;
  final int minDistance;
  final int maxDistance;
  final int holeCount;
  const _CategoryConfig(
      this.name, this.minDistance, this.maxDistance, this.holeCount);
}

class _PlusMinusChip extends StatelessWidget {
  final int value;
  const _PlusMinusChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final label = value == 0 ? 'E' : (value > 0 ? '+$value' : '$value');
    final color = value < 0
        ? ColorTokens.successDefault
        : value == 0
            ? ColorTokens.textPrimary
            : ColorTokens.errorDestructive;
    return Text(
      label,
      style: TextStyle(
        fontSize: TypographyTokens.bodyLgSize,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _StrokeAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StrokeAdjustButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorTokens.surfaceRaised,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            color: onTap != null
                ? ColorTokens.textPrimary
                : ColorTokens.textTertiary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
