import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/instance_scorer.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';

import '../../fixtures/scoring_fixtures.dart';

void main() {
  // TD-05 §4 — Instance Scoring Test Cases.
  // All assertions use closeTo(expected, 1e-9) per TD-05 §2.2.

  group('§4.1 Grid Cell Selection (Hit-Rate) — Irons Direction anchors', () {
    // Anchors: Min=30, Scratch=70, Pro=90.
    // Note: For grid drills, the hit-rate % is the "instance" value interpolated.
    const anchors = kStandardDirectionAnchors;

    test('TC-4.1.1: Exactly at Minimum — 30% → 0.0', () {
      final result = scoreInstance(const RawInstanceInput(30), anchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('TC-4.1.2: Below Minimum — 20% → 0.0', () {
      final result = scoreInstance(const RawInstanceInput(20), anchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('TC-4.1.3: Mid-Range Between Min and Scratch — 50% → 1.75', () {
      final result = scoreInstance(const RawInstanceInput(50), anchors);
      expect(result, closeTo(1.75, 1e-9));
    });

    test('TC-4.1.4: Exactly at Scratch — 70% → 3.5', () {
      final result = scoreInstance(const RawInstanceInput(70), anchors);
      expect(result, closeTo(3.5, 1e-9));
    });

    test('TC-4.1.5: Between Scratch and Pro — 80% → 4.25', () {
      final result = scoreInstance(const RawInstanceInput(80), anchors);
      expect(result, closeTo(4.25, 1e-9));
    });

    test('TC-4.1.6: Exactly at Pro — 90% → 5.0', () {
      final result = scoreInstance(const RawInstanceInput(90), anchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('TC-4.1.7: Above Pro (Cap) — 100% → 5.0', () {
      final result = scoreInstance(const RawInstanceInput(100), anchors);
      expect(result, closeTo(5.0, 1e-9));
    });
  });

  group('§4.2 Grid — Bunkers Direction (Different Anchors)', () {
    // Anchors: Min=10, Scratch=50, Pro=70.
    const anchors = kBunkersDirectionAnchors;

    test('TC-4.2.1: Below Min — 5% → 0.0', () {
      final result = scoreInstance(const RawInstanceInput(5), anchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('TC-4.2.2: Mid-Range — 30% → 1.75', () {
      final result = scoreInstance(const RawInstanceInput(30), anchors);
      expect(result, closeTo(1.75, 1e-9));
    });

    test('TC-4.2.3: Above Scratch — 60% → 4.25', () {
      final result = scoreInstance(const RawInstanceInput(60), anchors);
      expect(result, closeTo(4.25, 1e-9));
    });
  });

  group('§4.3 Raw Data Entry — Driving Carry', () {
    // Anchors: Min=180, Scratch=250, Pro=300.
    const anchors = kDrivingCarryAnchors;

    test('TC-4.3.1: Below Min — 160 yards → 0.0', () {
      final result = scoreInstance(const RawInstanceInput(160), anchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('TC-4.3.2: At Min — 180 → 0.0', () {
      final result = scoreInstance(const RawInstanceInput(180), anchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('TC-4.3.3: Quarter Between Min and Scratch — 197.5 → 0.875', () {
      final result = scoreInstance(const RawInstanceInput(197.5), anchors);
      expect(result, closeTo(0.875, 1e-9));
    });

    test('TC-4.3.4: At Scratch — 250 → 3.5', () {
      final result = scoreInstance(const RawInstanceInput(250), anchors);
      expect(result, closeTo(3.5, 1e-9));
    });

    test('TC-4.3.5: Between Scratch and Pro — 275 → 4.25', () {
      final result = scoreInstance(const RawInstanceInput(275), anchors);
      expect(result, closeTo(4.25, 1e-9));
    });

    test('TC-4.3.6: At Pro — 300 → 5.0', () {
      final result = scoreInstance(const RawInstanceInput(300), anchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('TC-4.3.7: Above Pro — 320 → 5.0', () {
      final result = scoreInstance(const RawInstanceInput(320), anchors);
      expect(result, closeTo(5.0, 1e-9));
    });
  });

  group('§4.4 Raw Data Entry — Ball Speed', () {
    // Anchors: Min=130, Scratch=155, Pro=170.
    const anchors = kBallSpeedAnchors;

    test('TC-4.4.1: Mid-Range — 142.5 mph → 1.75', () {
      final result = scoreInstance(const RawInstanceInput(142.5), anchors);
      expect(result, closeTo(1.75, 1e-9));
    });

    test('TC-4.4.2: Above Scratch — 162.5 → 4.25', () {
      final result = scoreInstance(const RawInstanceInput(162.5), anchors);
      expect(result, closeTo(4.25, 1e-9));
    });
  });

  group('§4.5 Binary Hit/Miss', () {
    // Same scoring as grid. Anchors: Min=30, Scratch=70, Pro=90.
    const anchors = kStandardDirectionAnchors;

    test('TC-4.5.1: 6 of 10 Hits — 60% → 2.625', () {
      final result = scoreInstance(const RawInstanceInput(60), anchors);
      expect(result, closeTo(2.625, 1e-9));
    });

    test('TC-4.5.2: All Hits — 100% → 5.0 (capped)', () {
      final result = scoreInstance(const RawInstanceInput(100), anchors);
      expect(result, closeTo(5.0, 1e-9));
    });

    test('TC-4.5.3: Zero Hits — 0% → 0.0', () {
      final result = scoreInstance(const RawInstanceInput(0), anchors);
      expect(result, closeTo(0.0, 1e-9));
    });
  });

  group('§4.6 User Custom Drill — Non-Standard Anchors', () {
    // Anchors: Min=20, Scratch=50, Pro=75.
    const anchors = kCustomDrillAnchors;

    test('TC-4.6.1: Custom Anchors — Mid-Range — 35% → 1.75', () {
      final result = scoreInstance(const RawInstanceInput(35), anchors);
      expect(result, closeTo(1.75, 1e-9));
    });

    test('TC-4.6.2: Custom Anchors — Above Scratch — 62.5% → 4.25', () {
      final result = scoreInstance(const RawInstanceInput(62.5), anchors);
      expect(result, closeTo(4.25, 1e-9));
    });
  });
}
