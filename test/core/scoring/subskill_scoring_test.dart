import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/subskill_scorer.dart';

void main() {
  // TD-05 §7 — Subskill Scoring Test Cases.

  /// Helper to create an empty window.
  WindowState emptyWindow() => const WindowState(
        entries: [],
        totalOccupancy: 0,
        weightedSum: 0,
        windowAverage: 0,
      );

  /// Helper to create a window with a given average.
  WindowState windowWith(double average) => WindowState(
        entries: [],
        totalOccupancy: 1,
        weightedSum: average,
        windowAverage: average,
      );

  group('§7 Subskill Scoring', () {
    test('TC-7.1.1: Both Windows Populated → 84.15', () {
      // Allocation=110. TransitionAvg=3.5. PressureAvg=4.0.
      final result = scoreSubskill(
        transition: windowWith(3.5),
        pressure: windowWith(4.0),
        allocation: 110,
      );

      // WeightedAvg = (3.5 × 0.35) + (4.0 × 0.65) = 1.225 + 2.6 = 3.825
      expect(result.weightedAverage, closeTo(3.825, 1e-9));
      // SubskillPoints = 110 × (3.825 / 5) = 84.15
      expect(result.subskillPoints, closeTo(84.15, 1e-9));
      expect(result.allocation, 110);
    });

    test('TC-7.1.2: Transition Only — Empty Pressure → 26.95', () {
      // Allocation=110. TransitionAvg=3.5. PressureAvg=0.0.
      final result = scoreSubskill(
        transition: windowWith(3.5),
        pressure: emptyWindow(),
        allocation: 110,
      );

      // WeightedAvg = (3.5 × 0.35) + (0.0 × 0.65) = 1.225
      expect(result.weightedAverage, closeTo(1.225, 1e-9));
      // SubskillPoints = 110 × (1.225 / 5) = 26.95
      expect(result.subskillPoints, closeTo(26.95, 1e-9));
    });

    test('TC-7.1.3: Pressure Only — Empty Transition → 57.2', () {
      // Allocation=110. TransitionAvg=0.0. PressureAvg=4.0.
      final result = scoreSubskill(
        transition: emptyWindow(),
        pressure: windowWith(4.0),
        allocation: 110,
      );

      // WeightedAvg = 0.0 + (4.0 × 0.65) = 2.6
      expect(result.weightedAverage, closeTo(2.6, 1e-9));
      // SubskillPoints = 110 × (2.6 / 5) = 57.2
      expect(result.subskillPoints, closeTo(57.2, 1e-9));
    });

    test('TC-7.1.4: Both Empty → 0.0', () {
      final result = scoreSubskill(
        transition: emptyWindow(),
        pressure: emptyWindow(),
        allocation: 110,
      );

      expect(result.weightedAverage, closeTo(0.0, 1e-9));
      expect(result.subskillPoints, closeTo(0.0, 1e-9));
    });

    test('TC-7.1.5: Perfect Score → 110.0 (equals Allocation)', () {
      // Allocation=110. TransitionAvg=5.0. PressureAvg=5.0.
      final result = scoreSubskill(
        transition: windowWith(5.0),
        pressure: windowWith(5.0),
        allocation: 110,
      );

      // WeightedAvg = 1.75 + 3.25 = 5.0
      expect(result.weightedAverage, closeTo(5.0, 1e-9));
      // SubskillPoints = 110 × 1.0 = 110.0
      expect(result.subskillPoints, closeTo(110.0, 1e-9));
    });

    test('TC-7.1.6: Small Allocation — Woods Shape Control → 7.3', () {
      // Allocation=10. TransitionAvg=3.0. PressureAvg=4.0.
      final result = scoreSubskill(
        transition: windowWith(3.0),
        pressure: windowWith(4.0),
        allocation: 10,
      );

      // WeightedAvg = (3.0 × 0.35) + (4.0 × 0.65) = 1.05 + 2.6 = 3.65
      expect(result.weightedAverage, closeTo(3.65, 1e-9));
      // SubskillPoints = 10 × (3.65 / 5) = 7.3
      expect(result.subskillPoints, closeTo(7.3, 1e-9));
    });
  });
}
