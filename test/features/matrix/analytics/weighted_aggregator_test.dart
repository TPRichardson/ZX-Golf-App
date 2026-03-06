import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/features/matrix/analytics/weighted_aggregator.dart';

// Phase M10 — Weighted aggregator tests (§9.4).

void main() {
  group('computeWeight', () {
    test('0 days returns 1.0', () {
      expect(computeWeight(0), 1.0);
    });

    test('negative days returns 1.0', () {
      expect(computeWeight(-5), 1.0);
    });

    test('365 days matches formula', () {
      // exp(-2.25 * sqrt(365/365)) = exp(-2.25)
      final expected = exp(-2.25);
      expect(computeWeight(365), closeTo(expected, 0.0001));
    });

    test('10 days matches formula', () {
      final expected = exp(-2.25 * sqrt(10 / 365));
      expect(computeWeight(10), closeTo(expected, 0.0001));
    });

    test('weight decreases with age', () {
      expect(computeWeight(10), greaterThan(computeWeight(30)));
      expect(computeWeight(30), greaterThan(computeWeight(90)));
      expect(computeWeight(90), greaterThan(computeWeight(365)));
    });
  });

  group('weightedAverage', () {
    test('equal weights produces arithmetic mean', () {
      final result = weightedAverage([10, 20, 30], [1, 1, 1]);
      expect(result, closeTo(20.0, 0.0001));
    });

    test('weighted towards higher-weight values', () {
      // Value 100 has weight 3, value 200 has weight 1.
      // (100*3 + 200*1) / (3+1) = 500/4 = 125
      final result = weightedAverage([100, 200], [3, 1]);
      expect(result, closeTo(125.0, 0.0001));
    });

    test('empty list returns 0', () {
      expect(weightedAverage([], []), 0.0);
    });

    test('all zero weights returns 0', () {
      expect(weightedAverage([10, 20], [0, 0]), 0.0);
    });

    test('single value returns that value', () {
      expect(weightedAverage([42], [1]), closeTo(42.0, 0.0001));
    });
  });

  group('rawAverage', () {
    test('arithmetic mean', () {
      expect(rawAverage([10, 20, 30]), closeTo(20.0, 0.0001));
    });

    test('empty list returns 0', () {
      expect(rawAverage([]), 0.0);
    });
  });

  group('standardDeviation', () {
    test('identical values returns 0', () {
      expect(standardDeviation([5, 5, 5]), closeTo(0.0, 0.0001));
    });

    test('known distribution', () {
      // [2, 4, 4, 4, 5, 5, 7, 9] → mean=5, variance=4, sd=2
      final result = standardDeviation([2, 4, 4, 4, 5, 5, 7, 9]);
      expect(result, closeTo(2.0, 0.0001));
    });

    test('single value returns 0', () {
      expect(standardDeviation([42]), 0.0);
    });

    test('empty list returns 0', () {
      expect(standardDeviation([]), 0.0);
    });
  });
}
