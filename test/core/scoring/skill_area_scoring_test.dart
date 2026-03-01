import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/skill_area_scorer.dart';

void main() {
  // TD-05 §8 — Skill Area Scoring Test Cases.

  /// Helper to create a SubskillScore with given points.
  SubskillScore subskillWith(double points, {int allocation = 110}) =>
      SubskillScore(
        transitionAverage: 0,
        pressureAverage: 0,
        weightedAverage: 0,
        subskillPoints: points,
        allocation: allocation,
      );

  group('§8 Skill Area Scoring', () {
    test('TC-8.1.1: Irons — All Subskills Populated → 204.3', () {
      // Distance Control: 84.15, Direction Control: 84.15, Shape Control: 36.0.
      final result = scoreSkillArea([
        subskillWith(84.15),
        subskillWith(84.15),
        subskillWith(36.0, allocation: 60),
      ]);

      expect(result, closeTo(204.3, 1e-9));
    });

    test('TC-8.1.2: Irons — One Subskill Empty → 168.3', () {
      // Distance Control: 84.15, Direction Control: 84.15, Shape Control: 0.0.
      final result = scoreSkillArea([
        subskillWith(84.15),
        subskillWith(84.15),
        subskillWith(0.0, allocation: 60),
      ]);

      expect(result, closeTo(168.3, 1e-9));
    });

    test('TC-8.1.3: Bunkers — Two Subskills → 22.5', () {
      // Distance Control: 10.5, Direction Control: 12.0.
      final result = scoreSkillArea([
        subskillWith(10.5, allocation: 15),
        subskillWith(12.0, allocation: 15),
      ]);

      expect(result, closeTo(22.5, 1e-9));
    });
  });
}
