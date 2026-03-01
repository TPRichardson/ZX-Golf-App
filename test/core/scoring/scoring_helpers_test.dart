import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/scoring/scoring_helpers.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';

import '../../fixtures/scoring_fixtures.dart';

void main() {
  group('validateAnchors', () {
    test('accepts valid anchors (min < scratch < pro)', () {
      expect(
        () => validateAnchors(kStandardDirectionAnchors),
        returnsNormally,
      );
    });

    test('throws on min == scratch', () {
      expect(
        () => validateAnchors(const Anchors(min: 30, scratch: 30, pro: 90)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws on scratch == pro', () {
      expect(
        () => validateAnchors(const Anchors(min: 30, scratch: 90, pro: 90)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws on min > scratch', () {
      expect(
        () => validateAnchors(const Anchors(min: 80, scratch: 70, pro: 90)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws on scratch > pro', () {
      expect(
        () => validateAnchors(const Anchors(min: 30, scratch: 95, pro: 90)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws on non-finite min (NaN)', () {
      expect(
        () => validateAnchors(
            Anchors(min: double.nan, scratch: 70, pro: 90)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws on non-finite scratch (infinity)', () {
      expect(
        () => validateAnchors(
            Anchors(min: 30, scratch: double.infinity, pro: 90)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('throws on non-finite pro (negative infinity)', () {
      expect(
        () => validateAnchors(
            Anchors(min: 30, scratch: 70, pro: double.negativeInfinity)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('exception code is VALIDATION_INVALID_ANCHORS', () {
      try {
        validateAnchors(const Anchors(min: 90, scratch: 70, pro: 30));
        fail('Should have thrown');
      } on ValidationException catch (e) {
        expect(e.code, ValidationException.invalidAnchors);
      }
    });
  });

  group('parseScoringAdapterBinding', () {
    test('parses hitRateInterpolation', () {
      expect(
        parseScoringAdapterBinding('hitRateInterpolation'),
        ScoringAdapterType.hitRateInterpolation,
      );
    });

    test('parses linearInterpolation', () {
      expect(
        parseScoringAdapterBinding('linearInterpolation'),
        ScoringAdapterType.linearInterpolation,
      );
    });

    test('parses none', () {
      expect(
        parseScoringAdapterBinding('none'),
        ScoringAdapterType.none,
      );
    });

    test('throws on unknown binding', () {
      expect(
        () => parseScoringAdapterBinding('unknown'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('interpolate', () {
    // Spec: S01 §1.4 — Using standard direction anchors (30/70/90).
    const anchors = kStandardDirectionAnchors;

    test('below min returns 0.0', () {
      expect(interpolate(20, anchors), closeTo(0.0, 1e-9));
    });

    test('at min returns 0.0', () {
      expect(interpolate(30, anchors), closeTo(0.0, 1e-9));
    });

    test('mid-range between min and scratch', () {
      // 3.5 × (50 − 30) / (70 − 30) = 1.75
      expect(interpolate(50, anchors), closeTo(1.75, 1e-9));
    });

    test('at scratch returns 3.5', () {
      expect(interpolate(70, anchors), closeTo(3.5, 1e-9));
    });

    test('between scratch and pro', () {
      // 3.5 + 1.5 × (80 − 70) / (90 − 70) = 4.25
      expect(interpolate(80, anchors), closeTo(4.25, 1e-9));
    });

    test('at pro returns 5.0', () {
      expect(interpolate(90, anchors), closeTo(5.0, 1e-9));
    });

    test('above pro returns 5.0 (hard cap)', () {
      expect(interpolate(100, anchors), closeTo(5.0, 1e-9));
    });

    test('works with driving carry anchors (180/250/300)', () {
      const driving = kDrivingCarryAnchors;
      // 3.5 × (197.5 − 180) / (250 − 180) = 0.875
      expect(interpolate(197.5, driving), closeTo(0.875, 1e-9));
    });

    test('works with bunkers direction anchors (10/50/70)', () {
      const bunkers = kBunkersDirectionAnchors;
      // 3.5 × (30 − 10) / (50 − 10) = 1.75
      expect(interpolate(30, bunkers), closeTo(1.75, 1e-9));
    });
  });
}
