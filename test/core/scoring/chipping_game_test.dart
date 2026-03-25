import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/strokes_gained_putting.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/session_scorer.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/chipping_game_delegate.dart';

// Tests for chipping scoring game.
// Anchors: Min=-5 (+5 over), Scratch=3 (-3 under), Pro=7 (-7 under).
const _chippingAnchors = Anchors(min: -5, scratch: 3, pro: 7);

void main() {
  group('strokes-gained putting lookup', () {
    test('holed (0ft) returns 0.0 expected putts', () {
      expect(expectedPuttsFromDistance(0), 0.0);
    });

    test('1ft returns ~1.001', () {
      expect(expectedPuttsFromDistance(1), closeTo(1.001, 1e-6));
    });

    test('10ft returns ~1.39', () {
      expect(expectedPuttsFromDistance(10), closeTo(1.390, 1e-6));
    });

    test('20ft returns ~1.61', () {
      expect(expectedPuttsFromDistance(20), closeTo(1.610, 1e-6));
    });

    test('50ft returns ~1.87', () {
      expect(expectedPuttsFromDistance(50), closeTo(1.870, 1e-6));
    });

    test('beyond 50ft clamps to 50ft value', () {
      expect(expectedPuttsFromDistance(100), closeTo(1.870, 1e-6));
    });

    test('negative distance returns 0.0', () {
      expect(expectedPuttsFromDistance(-5), 0.0);
    });
  });

  group('ChippingGameDelegate.computeHoleStrokes', () {
    test('holed = 1.0 stroke', () {
      expect(ChippingGameDelegate.computeHoleStrokes(0), 1.0);
    });

    test('not puttable = 1 + 2.5 = 3.5 strokes', () {
      expect(ChippingGameDelegate.computeHoleStrokes(-1), 3.5);
    });

    test('3ft proximity = 1 + 1.04 = 2.04', () {
      expect(ChippingGameDelegate.computeHoleStrokes(3), closeTo(2.040, 1e-6));
    });

    test('10ft proximity = 1 + 1.39 = 2.39', () {
      expect(ChippingGameDelegate.computeHoleStrokes(10), closeTo(2.390, 1e-6));
    });

    test('20ft proximity = 1 + 1.61 = 2.61', () {
      expect(ChippingGameDelegate.computeHoleStrokes(20), closeTo(2.610, 1e-6));
    });

    test('50ft proximity = 1 + 1.87 = 2.87', () {
      expect(ChippingGameDelegate.computeHoleStrokes(50), closeTo(2.870, 1e-6));
    });
  });

  group('chipping game scoring via scoreScoringGameSession', () {
    test('all holed (-18 under) clamps to pro (5.0)', () {
      // 18 × 1.0 = 18. +/- par = 18 - 36 = -18. Negated = 18. > Pro(7). → 5.0
      final instances = List.generate(18, (_) => const RawInstanceInput(1.0));
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('all par (average ~2.0 per hole) maps between min and scratch', () {
      // 18 × 2.0 = 36. +/- par = 0. Negated = 0.
      // Between min(-5) and scratch(3): 3.5 * (0 - (-5)) / (3 - (-5)) = 3.5 * 5/8 = 2.1875
      final instances = List.generate(18, (_) => const RawInstanceInput(2.0));
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      expect(result, closeTo(3.5 * 5 / 8, 1e-9));
    });

    test('-3 under par maps to scratch (3.5)', () {
      // Total = 33. +/- par = -3. Negated = 3. = Scratch.
      // 15 holes at 2.0, 3 holes at 1.0 → total = 30 + 3 = 33.
      final instances = [
        ...List.generate(15, (_) => const RawInstanceInput(2.0)),
        ...List.generate(3, (_) => const RawInstanceInput(1.0)),
      ];
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      expect(result, closeTo(3.5, 1e-9));
    });

    test('-7 under par maps to pro (5.0)', () {
      // Total = 29. +/- par = -7. Negated = 7. = Pro.
      // 11 holes at 2.0, 7 holes at 1.0 → total = 22 + 7 = 29.
      final instances = [
        ...List.generate(11, (_) => const RawInstanceInput(2.0)),
        ...List.generate(7, (_) => const RawInstanceInput(1.0)),
      ];
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('+5 over par maps to min (0.0)', () {
      // Total = 41. +/- par = +5. Negated = -5. = Min.
      final totalTarget = 41.0;
      // 18 holes averaging 41/18 ≈ 2.278 each.
      final perHole = totalTarget / 18;
      final instances = List.generate(18, (_) => RawInstanceInput(perHole));
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('worse than +5 clamps to 0.0', () {
      // 18 × 3.5 = 63. +/- par = +27. Negated = -27. < Min(-5). → 0.0
      final instances = List.generate(18, (_) => const RawInstanceInput(3.5));
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('fractional strokes interpolate correctly', () {
      // 18 holes at 1.83 each = 32.94 total. +/- par = -3.06. Negated = 3.06.
      // Between scratch(3) and pro(7): 3.5 + 1.5 * (3.06-3)/(7-3) = 3.5 + 1.5 * 0.015 = 3.5225
      final instances = List.generate(18, (_) => const RawInstanceInput(1.83));
      final result = scoreScoringGameSession(instances, 2, _chippingAnchors);
      final totalStrokes = 18 * 1.83;
      final plusMinus = totalStrokes - 36;
      final negated = -plusMinus;
      final expected = 3.5 + 1.5 * (negated - 3) / (7 - 3);
      expect(result, closeTo(expected, 1e-6));
    });

    test('empty instances returns 0.0', () {
      final result = scoreScoringGameSession([], 2, _chippingAnchors);
      expect(result, 0.0);
    });
  });

  group('ChippingGameDelegate hole generation', () {
    test('generates 18 holes', () {
      final delegate = ChippingGameDelegate();
      expect(delegate.holes.length, 18);
    });

    test('6 holes per category', () {
      final delegate = ChippingGameDelegate();
      final short = delegate.holes.where((h) => h.category == 'Short').length;
      final medium = delegate.holes.where((h) => h.category == 'Medium').length;
      final long = delegate.holes.where((h) => h.category == 'Long').length;
      expect(short, 6);
      expect(medium, 6);
      expect(long, 6);
    });

    test('all holes are par 2', () {
      final delegate = ChippingGameDelegate();
      for (final hole in delegate.holes) {
        expect(hole.par, 2);
      }
    });

    test('short holes are 5-8 yards', () {
      final delegate = ChippingGameDelegate();
      for (final h in delegate.holes.where((h) => h.category == 'Short')) {
        expect(h.distanceYards, inInclusiveRange(5, 8));
      }
    });

    test('medium holes are 9-14 yards', () {
      final delegate = ChippingGameDelegate();
      for (final h in delegate.holes.where((h) => h.category == 'Medium')) {
        expect(h.distanceYards, inInclusiveRange(9, 14));
      }
    });

    test('long holes are 15-20 yards', () {
      final delegate = ChippingGameDelegate();
      for (final h in delegate.holes.where((h) => h.category == 'Long')) {
        expect(h.distanceYards, inInclusiveRange(15, 20));
      }
    });

    test('holes are numbered 1-18', () {
      final delegate = ChippingGameDelegate();
      final numbers = delegate.holes.map((h) => h.holeNumber).toList();
      expect(numbers, List.generate(18, (i) => i + 1));
    });

    test('initial state: no holes complete', () {
      final delegate = ChippingGameDelegate();
      expect(delegate.completedCount, 0);
      expect(delegate.isRoundComplete, false);
      expect(delegate.plusMinusPar, 0.0);
    });
  });
}
