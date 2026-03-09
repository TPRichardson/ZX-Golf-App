import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/subskill_scorer.dart';

void main() {
  // Accumulation model tests.
  // SubskillPoints = (allocation / (5 × windowSize)) × (0.65 × P_sum + 0.35 × T_sum)

  /// Helper to create an empty window.
  WindowState emptyWindow() => const WindowState(
        entries: [],
        totalOccupancy: 0,
        weightedSum: 0,
        windowAverage: 0,
      );

  /// Helper to create a window with a given weightedSum and occupancy.
  WindowState windowWith(double weightedSum, {double occupancy = 1.0}) =>
      WindowState(
        entries: [],
        totalOccupancy: occupancy,
        weightedSum: weightedSum,
        windowAverage: occupancy > 0 ? weightedSum / occupancy : 0.0,
      );

  group('Accumulation Scoring', () {
    test('TC-7.1.1: Both Windows Populated (1 session each)', () {
      // allocation=110, windowSize=25, T_sum=3.5, P_sum=4.0
      final result = scoreSubskill(
        transition: windowWith(3.5),
        pressure: windowWith(4.0),
        allocation: 110,
        windowSize: 25,
      );

      // combinedWeightedSum = 3.5×0.35 + 4.0×0.65 = 1.225 + 2.6 = 3.825
      // subskillPoints = (110 / 125) × 3.825 = 0.88 × 3.825 = 3.366
      expect(result.subskillPoints, closeTo(3.366, 1e-9));
      // weightedAverage = 3.825 / 25 = 0.153
      expect(result.weightedAverage, closeTo(0.153, 1e-9));
      expect(result.allocation, 110);
    });

    test('TC-7.1.2: Transition Only — Empty Pressure', () {
      // allocation=110, windowSize=25, T_sum=3.5, P_sum=0.0
      final result = scoreSubskill(
        transition: windowWith(3.5),
        pressure: emptyWindow(),
        allocation: 110,
        windowSize: 25,
      );

      // combinedWeightedSum = 3.5×0.35 + 0 = 1.225
      // subskillPoints = 0.88 × 1.225 = 1.078
      expect(result.subskillPoints, closeTo(1.078, 1e-9));
    });

    test('TC-7.1.3: Pressure Only — Empty Transition', () {
      // allocation=110, windowSize=25, T_sum=0.0, P_sum=4.0
      final result = scoreSubskill(
        transition: emptyWindow(),
        pressure: windowWith(4.0),
        allocation: 110,
        windowSize: 25,
      );

      // combinedWeightedSum = 0 + 4.0×0.65 = 2.6
      // subskillPoints = 0.88 × 2.6 = 2.288
      expect(result.subskillPoints, closeTo(2.288, 1e-9));
    });

    test('TC-7.1.4: Both Empty → 0.0', () {
      final result = scoreSubskill(
        transition: emptyWindow(),
        pressure: emptyWindow(),
        allocation: 110,
        windowSize: 25,
      );

      expect(result.weightedAverage, closeTo(0.0, 1e-9));
      expect(result.subskillPoints, closeTo(0.0, 1e-9));
    });

    test('TC-7.1.5: Full window at perfect score → equals allocation', () {
      // allocation=110, windowSize=25, fully saturated at 5.0
      // T_sum = 5.0 × 25 = 125.0, P_sum = 5.0 × 25 = 125.0
      final result = scoreSubskill(
        transition: windowWith(125.0, occupancy: 25.0),
        pressure: windowWith(125.0, occupancy: 25.0),
        allocation: 110,
        windowSize: 25,
      );

      // combinedWeightedSum = 125.0×0.35 + 125.0×0.65 = 43.75 + 81.25 = 125.0
      // subskillPoints = (110/125) × 125.0 = 110.0
      expect(result.subskillPoints, closeTo(110.0, 1e-9));
    });

    test('TC-7.1.6: Small Allocation + Small Window', () {
      // allocation=10, windowSize=3 (e.g. woods), T_sum=3.0, P_sum=4.0
      final result = scoreSubskill(
        transition: windowWith(3.0),
        pressure: windowWith(4.0),
        allocation: 10,
        windowSize: 3,
      );

      // combinedWeightedSum = 3.0×0.35 + 4.0×0.65 = 1.05 + 2.6 = 3.65
      // subskillPoints = (10 / 15) × 3.65 = 0.6667 × 3.65 ≈ 2.4333
      expect(result.subskillPoints, closeTo(2.43333333, 1e-4));
    });

    test('Accumulation: half-saturated window earns ~half points', () {
      // allocation=100, windowSize=20, half saturated at perfect score
      // T_sum = 5.0 × 10 = 50.0, P_sum = 5.0 × 10 = 50.0
      final result = scoreSubskill(
        transition: windowWith(50.0, occupancy: 10.0),
        pressure: windowWith(50.0, occupancy: 10.0),
        allocation: 100,
        windowSize: 20,
      );

      // combinedWeightedSum = 50.0×0.35 + 50.0×0.65 = 17.5 + 32.5 = 50.0
      // subskillPoints = (100/100) × 50.0 = 50.0 (half of 100)
      expect(result.subskillPoints, closeTo(50.0, 1e-9));
    });
  });
}
