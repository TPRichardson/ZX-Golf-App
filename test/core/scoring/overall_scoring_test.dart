import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/overall_scorer.dart';

void main() {
  // TD-05 §9 — Overall SkillScore Test Cases.

  group('§9 Overall SkillScore', () {
    test('TC-9.1.1: All Areas Populated → 716.8', () {
      final result = scoreOverall([
        204.3, // Irons
        180.0, // Driving
        140.0, // Putting
        70.0, // Pitching
        65.0, // Chipping
        35.0, // Woods
        22.5, // Bunkers
      ]);

      expect(result, closeTo(716.8, 1e-9));
    });

    test('TC-9.1.2: Single Subskill Only → 26.95', () {
      // One Session for approach_direction_control (Transition), score 3.5.
      // All else empty. Overall = 26.95.
      final result = scoreOverall([
        26.95, // Irons (only direction control populated)
        0.0, // Driving
        0.0, // Putting
        0.0, // Pitching
        0.0, // Chipping
        0.0, // Woods
        0.0, // Bunkers
      ]);

      expect(result, closeTo(26.95, 1e-9));
    });

    test('TC-9.1.3: Perfect 1000', () {
      // All 19 subskills at WeightedAvg = 5.0. Sum of allocations = 1000.
      final result = scoreOverall([
        280.0, // Irons
        240.0, // Driving
        200.0, // Putting
        100.0, // Pitching
        100.0, // Chipping
        50.0, // Woods
        30.0, // Bunkers
      ]);

      expect(result, closeTo(1000.0, 1e-9));
    });

    test('TC-9.1.4: Zero — No Data → 0.0', () {
      final result = scoreOverall([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
      expect(result, closeTo(0.0, 1e-9));
    });
  });

  group('Edge cases', () {
    test('Empty list returns 0.0', () {
      expect(scoreOverall([]), closeTo(0.0, 1e-9));
    });

    test('Sum exceeding 1000 is capped', () {
      // Hypothetical: if inputs somehow exceed 1000.
      final result = scoreOverall([500.0, 500.0, 100.0]);
      expect(result, closeTo(1000.0, 1e-9));
    });
  });
}
