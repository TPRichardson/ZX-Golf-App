import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/integrity_evaluator.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';

void main() {
  // S11 — Integrity bounds evaluation tests.

  group('hitRateInterpolation adapter — excluded from integrity', () {
    test('always returns false regardless of bounds', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: -100,
        hardMinInput: 0,
        hardMaxInput: 100,
        adapterType: ScoringAdapterType.hitRateInterpolation,
      ));
      expect(result, false);
    });

    test('returns false even with null bounds', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 50,
        adapterType: ScoringAdapterType.hitRateInterpolation,
      ));
      expect(result, false);
    });
  });

  group('none adapter (Technique Block) — no integrity check', () {
    test('always returns false', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 0,
        adapterType: ScoringAdapterType.none,
      ));
      expect(result, false);
    });
  });

  group('linearInterpolation adapter — raw data drills', () {
    test('value within bounds → not in breach', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 250,
        hardMinInput: 0,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, false);
    });

    test('value at hardMinInput → not in breach (boundary inclusive)', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 0,
        hardMinInput: 0,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, false);
    });

    test('value at hardMaxInput → not in breach (boundary inclusive)', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 500,
        hardMinInput: 0,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, false);
    });

    test('value below hardMinInput → IN BREACH', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: -1,
        hardMinInput: 0,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, true);
    });

    test('value above hardMaxInput → IN BREACH', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 501,
        hardMinInput: 0,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, true);
    });

    test('no bounds defined → not in breach', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 999999,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, false);
    });

    test('only hardMinInput defined, value below → IN BREACH', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: -5,
        hardMinInput: 0,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, true);
    });

    test('only hardMaxInput defined, value above → IN BREACH', () {
      final result = evaluateIntegrity(const IntegrityInput(
        value: 600,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, true);
    });

    test('driving carry distance — typical valid value', () {
      // Typical carry: 250 yards. Bounds: 0–500.
      final result = evaluateIntegrity(const IntegrityInput(
        value: 250,
        hardMinInput: 0,
        hardMaxInput: 500,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, false);
    });

    test('ball speed — value at exact boundary', () {
      // Ball speed bounds: 50–250 mph.
      final result = evaluateIntegrity(const IntegrityInput(
        value: 50,
        hardMinInput: 50,
        hardMaxInput: 250,
        adapterType: ScoringAdapterType.linearInterpolation,
      ));
      expect(result, false);
    });
  });
}
