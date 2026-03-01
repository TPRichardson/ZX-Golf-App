import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/session_scorer.dart';

import '../../fixtures/scoring_fixtures.dart';

void main() {
  // TD-05 §5 — Session Scoring Test Cases.

  group('§5.1 Grid Drill — Single Set', () {
    test('TC-5.1.1: Grid Drill Session Score — 70% hit-rate → 3.5', () {
      // 7 Centre out of 10. Hit-rate = 70%. Anchors: 30/70/90.
      final result = scoreHitRateSession(
        const HitRateSessionInput(totalHits: 7, totalAttempts: 10),
        kStandardDirectionAnchors,
      );
      expect(result, closeTo(3.5, 1e-9));
    });
  });

  group('§5.2 Raw Data Entry — Per-Instance Averaging', () {
    test('TC-5.2.1: 10 Instances with Varied Values → 3.12', () {
      // Driving Carry drill (1×10). Anchors: 180/250/300.
      final instances = [200, 230, 250, 260, 270, 240, 255, 280, 245, 220]
          .map((v) => RawInstanceInput(v.toDouble()))
          .toList();

      final result = scoreRawDataSession(instances, kDrivingCarryAnchors);
      // Per TD-05: sum = 31.2, average = 3.12.
      expect(result, closeTo(3.12, 1e-9));
    });
  });

  group('§5.3 Multi-Set Structured Drill', () {
    test('TC-5.3.1: Flat Average Across All Sets → 3.353333...', () {
      // 3×5 structure. Driving Carry anchors: 180/250/300.
      // Set 1: 250, 260, 270, 240, 255
      // Set 2: 200, 210, 230, 220, 215
      // Set 3: 280, 290, 300, 285, 295
      final instances = [
        250, 260, 270, 240, 255, // Set 1
        200, 210, 230, 220, 215, // Set 2
        280, 290, 300, 285, 295, // Set 3
      ].map((v) => RawInstanceInput(v.toDouble())).toList();

      final result = scoreRawDataSession(instances, kDrivingCarryAnchors);
      // Per TD-05: total = 50.3, session = 50.3 / 15 = 3.353333...
      expect(result, closeTo(50.3 / 15, 1e-9));
    });
  });

  group('§5.4 Single Instance — Unstructured', () {
    test('TC-5.4.1: Single Instance — 265 yards → 3.95', () {
      final result = scoreRawDataSession(
        [const RawInstanceInput(265)],
        kDrivingCarryAnchors,
      );
      expect(result, closeTo(3.95, 1e-9));
    });
  });

  group('Edge cases', () {
    test('scoreRawDataSession returns 0.0 for empty list', () {
      final result =
          scoreRawDataSession([], kDrivingCarryAnchors);
      expect(result, closeTo(0.0, 1e-9));
    });

    test('scoreHitRateSession returns 0.0 for zero attempts', () {
      final result = scoreHitRateSession(
        const HitRateSessionInput(totalHits: 0, totalAttempts: 0),
        kStandardDirectionAnchors,
      );
      expect(result, closeTo(0.0, 1e-9));
    });
  });
}
