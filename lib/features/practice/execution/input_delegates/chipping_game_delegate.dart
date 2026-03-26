// Chipping scoring game input delegate — hole-by-hole chip + proximity entry.
// Each hole shows a randomised distance (yards). Player chips, then records
// proximity to hole (feet) or taps Holed/Can't Putt. System computes fractional
// strokes using PGA Tour strokes-gained putting data.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/scoring/strokes_gained_putting.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/features/practice/execution/execution_input_delegate.dart';
import 'package:zx_golf_app/features/practice/widgets/shot_record_button.dart';
import 'package:zx_golf_app/features/practice/execution/session_execution_controller.dart';

/// Penalty strokes for a chip that leaves the ball in an unputtable position.
const double kNotPuttablePenalty = 2.5;

/// Expected proximity to hole (feet) by chip distance (yards) for each level.
/// Estimates based on PGA Tour / amateur performance data.
double proProximityFeet(int chipDistanceYards) {
  // Pro: ~3ft at 5y, scaling to ~8ft at 20y.
  return 2.5 + chipDistanceYards * 0.3;
}

double scratchProximityFeet(int chipDistanceYards) {
  // Scratch: ~6ft at 5y, scaling to ~16ft at 20y.
  return 4.0 + chipDistanceYards * 0.6;
}

double hc25ProximityFeet(int chipDistanceYards) {
  // 25-hc: ~12ft at 5y, scaling to ~30ft at 20y.
  return 8.0 + chipDistanceYards * 1.1;
}

/// Compute dynamic par for a hole: 1 chip + expected putts from pro proximity.
double dynamicPar(int chipDistanceYards) {
  final proFeet = proProximityFeet(chipDistanceYards).round();
  return 1.0 + expectedPuttsFromDistance(proFeet);
}

/// A single hole in the chipping scoring game.
class ChippingGameHole {
  final int holeNumber;
  final String category;
  final int distanceYards;
  final double par;
  /// Computed total strokes: 1 (chip) + expected putts from proximity.
  double? strokes;
  /// Distance remaining to hole after chip (feet). Null if not yet recorded.
  /// 0 = holed, -1 = not puttable.
  int? proximityFeet;

  ChippingGameHole({
    required this.holeNumber,
    required this.category,
    required this.distanceYards,
    required this.par,
  });

  double get plusMinus => (strokes ?? par) - par;
  bool get isComplete => strokes != null;
  bool get isHoled => proximityFeet == 0;
  bool get isNotPuttable => proximityFeet == -1;
}

class ChippingGameDelegate extends ExecutionInputDelegate {
  final Drill? drill;
  late final List<ChippingGameHole> holes;
  int _currentHoleIndex = 0;
  int _selectedDistance = 10; // Default scroll position (feet).
  late FixedExtentScrollController _scrollCtrl;
  bool _showHoledPop = false;

  /// Running totals.
  double get totalStrokes =>
      holes.where((h) => h.isComplete).fold(0.0, (sum, h) => sum + h.strokes!);
  double get totalPar =>
      holes.where((h) => h.isComplete).fold(0.0, (sum, h) => sum + h.par);
  double get plusMinusPar => totalStrokes - totalPar;
  int get completedCount => holes.where((h) => h.isComplete).length;
  bool get isRoundComplete => completedCount >= holes.length;
  ChippingGameHole? get currentHole =>
      _currentHoleIndex < holes.length ? holes[_currentHoleIndex] : null;

  ChippingGameDelegate({this.drill}) {
    holes = _generateHoles();
    _scrollCtrl = FixedExtentScrollController(initialItem: _selectedDistance - 1);
  }

  @override
  double? get currentTargetDistance => currentHole?.distanceYards.toDouble();

  @override
  String? get statusLine {
    final hole = currentHole;
    if (hole == null) return null;
    return 'Hole ${hole.holeNumber}  •  Par ${hole.par.toStringAsFixed(2)}  •  ${hole.distanceYards}y';
  }

  @override
  Widget? get statusTrailing => _PlusMinusChip(value: plusMinusPar);

  List<ChippingGameHole> _generateHoles() {
    final config = _parseConfig();
    final rng = Random();
    final generated = <ChippingGameHole>[];
    var holeNum = 1;

    for (final cat in config.categories) {
      for (var i = 0; i < cat.holeCount; i++) {
        final dist = cat.minDistance +
            rng.nextInt(cat.maxDistance - cat.minDistance + 1);
        generated.add(ChippingGameHole(
          holeNumber: holeNum++,
          category: cat.name,
          distanceYards: dist,
          par: dynamicPar(dist),
        ));
      }
    }

    // Randomise order.
    generated.shuffle(rng);
    // Re-number after shuffle.
    for (var i = 0; i < generated.length; i++) {
      generated[i] = ChippingGameHole(
        holeNumber: i + 1,
        category: generated[i].category,
        distanceYards: generated[i].distanceYards,
        par: generated[i].par,
      );
    }
    return generated;
  }

  _RoundConfig _parseConfig() {
    return _RoundConfig(categories: [
      _CategoryConfig('Short', 5, 8, 6),
      _CategoryConfig('Medium', 9, 14, 6),
      _CategoryConfig('Long', 15, 20, 6),
    ]);
  }

  /// Compute total strokes for a hole given proximity in feet.
  /// holed (0ft) = 1.0, not puttable (-1) = 1 + penalty.
  static double computeHoleStrokes(int proximityFeet) {
    if (proximityFeet == 0) return 1.0; // Holed.
    if (proximityFeet < 0) return 1.0 + kNotPuttablePenalty; // Not puttable.
    return 1.0 + expectedPuttsFromDistance(proximityFeet);
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

    final isLocked = executionContext.isLocked;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.lg),
      child: Column(
        children: [
          const SizedBox(height: SpacingTokens.sm),
          // Quick-action buttons: Holed + Can't Putt.
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  label: _showHoledPop ? 'Holed!' : 'Holed',
                  icon: Icons.golf_course,
                  color: _showHoledPop
                      ? ColorTokens.successDefault
                      : ColorTokens.successDefault.withValues(alpha: 0.8),
                  isHighlighted: _showHoledPop,
                  onTap: isLocked
                      ? null
                      : () => _recordProximity(
                            0, executionContext, onLogInstance, requestRebuild),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Expanded(
                child: _QuickActionButton(
                  label: "Can't Putt",
                  icon: Icons.block,
                  color: ColorTokens.errorDestructive.withValues(alpha: 0.8),
                  onTap: isLocked
                      ? null
                      : () => _recordProximity(
                            -1, executionContext, onLogInstance, requestRebuild),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          // Scroll wheel for distance remaining (feet).
          Expanded(
            child: Center(
              child: SizedBox(
                height: 180,
                child: Row(
                  children: [
                    // Left: live display value.
                    Expanded(
                      child: Center(
                        child: Text(
                          '${_selectedDistance}ft',
                          style: TextStyle(
                            fontSize: TypographyTokens.displayXlSize,
                            fontWeight: FontWeight.w600,
                            color: ColorTokens.primaryDefault,
                          ),
                        ),
                      ),
                    ),
                    // Right: scroll wheel (1–50ft).
                    SizedBox(
                      width: 80,
                      child: ListWheelScrollView.useDelegate(
                        controller: _scrollCtrl,
                        itemExtent: 36,
                        physics: const FixedExtentScrollPhysics(),
                        diameterRatio: 1.6,
                        perspective: 0.003,
                        onSelectedItemChanged: (index) {
                          _selectedDistance = index + 1;
                          requestRebuild();
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          childCount: 50,
                          builder: (context, index) {
                            final value = index + 1;
                            final isSelected = value == _selectedDistance;
                            return Center(
                              child: Text(
                                '$value',
                                style: TextStyle(
                                  fontSize: isSelected
                                      ? TypographyTokens.displayLgSize
                                      : TypographyTokens.bodyLgSize,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? ColorTokens.textPrimary
                                      : ColorTokens.textTertiary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
                : () => _recordProximity(
                      _selectedDistance,
                      executionContext,
                      onLogInstance,
                      requestRebuild,
                    ),
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

  Future<void> _recordProximity(
    int proximityFeet,
    ExecutionContext ctx,
    LogInstanceCallback onLogInstance,
    VoidCallback requestRebuild,
  ) async {
    if (ctx.isEnding || isRoundComplete) return;
    final hole = currentHole!;

    final totalStrokesForHole = computeHoleStrokes(proximityFeet);

    // Brief "Holed!" pop for holed chips.
    if (proximityFeet == 0) {
      _showHoledPop = true;
      requestRebuild();
      await Future.delayed(const Duration(milliseconds: 400));
      _showHoledPop = false;
    }

    final plusMinusPar = totalStrokesForHole - hole.par;

    final data = InstancesCompanion.insert(
      instanceId: const Uuid().v4(),
      setId: ctx.currentSetId!,
      selectedClub: Value(ctx.selectedClub),
      rawMetrics: jsonEncode({
        'strokes': plusMinusPar, // Plus/minus dynamic par (positive = over par).
        'rawStrokes': totalStrokesForHole,
        'proximityFeet': proximityFeet,
        'distance': hole.distanceYards,
        'category': hole.category,
        'par': hole.par,
        'holeNumber': hole.holeNumber,
        'holed': proximityFeet == 0,
        'notPuttable': proximityFeet < 0,
      }),
      resolvedTargetDistance: Value(hole.distanceYards.toDouble()),
      flight: Value(ctx.flight),
    );
    await onLogInstance(data);
  }

  @override
  void onInstanceLogged(InstanceResult result, InstancesCompanion data) {
    if (_currentHoleIndex < holes.length) {
      final metrics =
          jsonDecode(data.rawMetrics.value) as Map<String, dynamic>;
      final strokes = (metrics['strokes'] as num).toDouble();
      final proximity = (metrics['proximityFeet'] as num).toInt();
      holes[_currentHoleIndex].strokes = strokes;
      holes[_currentHoleIndex].proximityFeet = proximity;
      _currentHoleIndex++;
      _selectedDistance = 10; // Reset scroll for next hole.
      _scrollCtrl.jumpToItem(9); // 0-indexed: item 9 = 10ft.
    }
  }

  @override
  void onInstanceUndone(Instance? deleted) {
    if (deleted == null || _currentHoleIndex <= 0) return;
    _currentHoleIndex--;
    holes[_currentHoleIndex].strokes = null;
    holes[_currentHoleIndex].proximityFeet = null;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
  }
}

class _RoundConfig {
  final List<_CategoryConfig> categories;
  const _RoundConfig({required this.categories});
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
  final double value;
  const _PlusMinusChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final rounded = value.abs() < 0.05
        ? 'E'
        : (value > 0
            ? '+${value.toStringAsFixed(1)}'
            : value.toStringAsFixed(1));
    final color = value < -0.05
        ? ColorTokens.successDefault
        : value.abs() < 0.05
            ? ColorTokens.textPrimary
            : ColorTokens.errorDestructive;
    return Text(
      rounded,
      style: TextStyle(
        fontSize: TypographyTokens.bodyLgSize,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isHighlighted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHighlighted
          ? color
          : color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ShapeTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.md,
            horizontal: SpacingTokens.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isHighlighted ? Colors.white : color,
              ),
              const SizedBox(width: SpacingTokens.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: TypographyTokens.bodySize,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
