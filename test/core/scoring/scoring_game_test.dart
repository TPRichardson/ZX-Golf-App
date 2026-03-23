import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_helpers.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/session_scorer.dart';

// Tests for scoring game: +/- par scoring with negated anchor interpolation.
// Raw targets: Pro=-5 under, Scratch=-3 under, Min=+3 over.
// After negation: Min=-3, Scratch=3, Pro=5.

const _scoringGameAnchors = Anchors(min: -3, scratch: 3, pro: 5);

void main() {
  group('scoreScoringGameSession', () {
    test('even par (36 strokes on 18 holes par 2) interpolates correctly', () {
      // 18 holes × 2 strokes = 36 total. +/- par = 0. Negated = 0.
      // 0 is between min (-3) and scratch (3): score = 3.5 * (0 - (-3)) / (3 - (-3))
      // = 3.5 * 3/6 = 1.75
      final instances = List.generate(18, (_) => const RawInstanceInput(2));
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(3.5 * 3 / 6, 1e-9));
    });

    test('-3 under par maps to scratch (3.5)', () {
      // 18 holes, total strokes = 33. +/- par = -3. Negated = 3. = Scratch.
      final instances = [
        ...List.generate(15, (_) => const RawInstanceInput(2)),
        ...List.generate(3, (_) => const RawInstanceInput(1)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(3.5, 1e-9));
    });

    test('-5 under par maps to pro (5.0)', () {
      // 18 holes, total strokes = 31. +/- par = -5. Negated = 5. = Pro.
      final instances = [
        ...List.generate(13, (_) => const RawInstanceInput(2)),
        ...List.generate(5, (_) => const RawInstanceInput(1)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('+3 over par maps to min (0.0)', () {
      // 18 holes, total strokes = 39. +/- par = +3. Negated = -3. = Min.
      final instances = [
        ...List.generate(15, (_) => const RawInstanceInput(2)),
        ...List.generate(3, (_) => const RawInstanceInput(3)),
      ];
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('worse than +3 clamps to 0.0', () {
      // 18 holes, total strokes = 54. +/- par = +18. Negated = -18. < Min.
      final instances = List.generate(18, (_) => const RawInstanceInput(4));
      final result = scoreScoringGameSession(instances, 2, _scoringGameAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('better than -5 clamps to 5.0', () {
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

    test('-4 under par is between scratch and pro', () {
      // Total strokes = 32. +/- par = -4. Negated = 4.
      // Between scratch (3) and pro (5): 3.5 + 1.5 * (4-3)/(5-3) = 3.5 + 0.75 = 4.25
      final instances = [
        ...List.generate(14, (_) => const RawInstanceInput(2)),
        ...List.generate(4, (_) => const RawInstanceInput(1)),
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
