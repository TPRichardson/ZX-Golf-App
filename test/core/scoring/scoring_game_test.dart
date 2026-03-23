import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_helpers.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/session_scorer.dart';

// Tests for scoring game: +/- par scoring with negated anchor interpolation.
// Anchors: Min=-9 (+9 over par), Scratch=4 (-4 under), Pro=6 (-6 under).

const _scoringGameAnchors = Anchors(min: -9, scratch: 4, pro: 6);

void main() {
  group('scoreScoringGameSession', () {
    test('even par (36 strokes on 18 holes par 2) interpolates correctly', () {
      // 18 holes × 2 strokes = 36 total. +/- par = 0. Negated = 0.
      // 0 is between min (-9) and scratch (4): score = 3.5 * (0 - (-9)) / (4 - (-9))
      // = 3.5 * 9/13 ≈ 2.423
      final instances = List.generate(18, (_) => const RawInstanceInput(2));
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(3.5 * 9 / 13, 1e-9));
    });

    test('-4 under par maps to scratch (3.5)', () {
      // 18 holes, total strokes = 32. +/- par = -4. Negated = 4. = Scratch.
      // 14 holes at par 2, 4 holes at 1 stroke.
      final instances = [
        ...List.generate(14, (_) => const RawInstanceInput(2)),
        ...List.generate(4, (_) => const RawInstanceInput(1)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(3.5, 1e-9));
    });

    test('-6 under par maps to pro (5.0)', () {
      // 18 holes, total strokes = 30. +/- par = -6. Negated = 6. = Pro.
      final instances = [
        ...List.generate(12, (_) => const RawInstanceInput(2)),
        ...List.generate(6, (_) => const RawInstanceInput(1)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('+9 over par maps to min (0.0)', () {
      // 18 holes, total strokes = 45. +/- par = +9. Negated = -9. = Min.
      final instances = [
        ...List.generate(9, (_) => const RawInstanceInput(2)),
        ...List.generate(9, (_) => const RawInstanceInput(3)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('worse than +9 clamps to 0.0', () {
      // 18 holes, total strokes = 54. +/- par = +18. Negated = -18. < Min.
      final instances = List.generate(18, (_) => const RawInstanceInput(4));
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('better than -6 clamps to 5.0', () {
      // 18 holes all hole-in-one. Total = 18. +/- par = -18. Negated = 18. > Pro.
      final instances = List.generate(18, (_) => const RawInstanceInput(1));
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('empty instances returns 0.0', () {
      final result =
          scoreScoringGameSession([], 2, _scoringGameAnchors);
      expect(result, 0.0);
    });

    test('-5 under par is between scratch and pro', () {
      // Total strokes = 31. +/- par = -5. Negated = 5.
      // Between scratch (4) and pro (6): 3.5 + 1.5 * (5-4)/(6-4) = 3.5 + 0.75 = 4.25
      final instances = [
        ...List.generate(13, (_) => const RawInstanceInput(2)),
        ...List.generate(5, (_) => const RawInstanceInput(1)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(4.25, 1e-9));
    });
  });

  group('parseScoringAdapterBinding', () {
    test('parses camelCase scoring game binding', () {
      expect(
        parseScoringAdapterBinding('scoringGameInterpolation'),
        ScoringAdapterType.scoringGameInterpolation,
      );
    });

    test('parses PascalCase scoring game binding', () {
      expect(
        parseScoringAdapterBinding('ScoringGameInterpolation'),
        ScoringAdapterType.scoringGameInterpolation,
      );
    });
  });

  group('extractNumericValue with strokes', () {
    test('extracts strokes from scoring game rawMetrics', () {
      final value = extractNumericValue(
          '{"strokes": 3, "distance": 15, "category": "Medium"}');
      expect(value, 3.0);
    });
  });
}
