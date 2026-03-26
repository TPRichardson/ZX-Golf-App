import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/strokes_gained_putting.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/session_scorer.dart';
import 'package:zx_golf_app/features/practice/execution/input_delegates/chipping_game_delegate.dart';

// Tests for chipping scoring game.
// Anchors: Min=-12 (+12 over), Scratch=-2 (+2 over), Pro=0 (even).
const _chippingAnchors = Anchors(min: -12, scratch: -2, pro: 0);

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
    // With dynamic par, strokes field = plusMinusPar (positive = over par).
    // scoreScoringGameSession with par=0: negated = -(sum).
    // Anchors: Min=-12, Scratch=-2, Pro=0.
    // Even par → sum=0, negated=0 → interpolate(0, {-12,-2,0}) = Pro = 5.0 ✓
    // +2 over → sum=+2, negated=-2 → interpolate(-2, {-12,-2,0}) = Scratch = 3.5 ✓
    // +12 over → sum=+12, negated=-12 → interpolate(-12, {-12,-2,0}) = Min = 0.0 ✓

    test('even par maps to pro (5.0)', () {
      final instances = List.generate(18, (_) => const RawInstanceInput(0.0));
      final result = scoreScoringGameSession(instances, 0, _chippingAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('+2 over par maps to scratch (3.5)', () {
      final perHole = 2.0 / 18;
      final instances = List.generate(18, (_) => RawInstanceInput(perHole));
      final result = scoreScoringGameSession(instances, 0, _chippingAnchors);
      expect(result, closeTo(3.5, 1e-9));
    });

    test('+12 over par maps to min (0.0)', () {
      final perHole = 12.0 / 18;
      final instances = List.generate(18, (_) => RawInstanceInput(perHole));
      final result = scoreScoringGameSession(instances, 0, _chippingAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('under par clamps to 5.0', () {
      // -2 under par → sum=-2, negated=2 → above Pro(0) → 5.0
      final instances = List.generate(18, (_) => const RawInstanceInput(-0.111));
      final result = scoreScoringGameSession(instances, 0, _chippingAnchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('worse than +12 clamps to 0.0', () {
      final perHole = 20.0 / 18;
      final instances = List.generate(18, (_) => RawInstanceInput(perHole));
      final result = scoreScoringGameSession(instances, 0, _chippingAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('fractional plus/minus interpolates correctly', () {
      // +7 over → sum=+7, negated=-7.
      // Between Min(-12) and Scratch(-2): 3.5 * (-7 - (-12)) / (-2 - (-12)) = 3.5 * 5/10 = 1.75
      final perHole = 7.0 / 18;
      final instances = List.generate(18, (_) => RawInstanceInput(perHole));
      final result = scoreScoringGameSession(instances, 0, _chippingAnchors);
      expect(result, closeTo(1.75, 1e-6));
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

    test('all holes have dynamic par based on distance', () {
      final delegate = ChippingGameDelegate();
      for (final hole in delegate.holes) {
        // Dynamic par = 1 + expectedPutts(proProximity(distance)).
        // Should be > 1.0 and < 3.0 for any reasonable distance.
        expect(hole.par, greaterThan(1.0));
        expect(hole.par, lessThan(3.0));
        expect(hole.par, dynamicPar(hole.distanceYards));
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
