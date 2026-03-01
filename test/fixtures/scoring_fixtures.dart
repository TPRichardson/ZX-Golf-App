// Shared test fixtures for Phase 2A scoring tests.
// Anchor sets from S14 §14.3. Helpers for window entry generation.

import 'package:zx_golf_app/core/scoring/scoring_types.dart';

// S14 §14.3.1 — Standard direction anchors (Irons, Driving, Woods, Pitching).
const kStandardDirectionAnchors = Anchors(min: 30, scratch: 70, pro: 90);

// S14 §14.3.1 — Putting direction anchors.
const kPuttingDirectionAnchors = Anchors(min: 20, scratch: 60, pro: 80);

// S14 §14.3.1 — Bunkers direction anchors.
const kBunkersDirectionAnchors = Anchors(min: 10, scratch: 50, pro: 70);

// S14 §14.3.3 — Driving carry distance anchors.
const kDrivingCarryAnchors = Anchors(min: 180, scratch: 250, pro: 300);

// S14 §14.3.3 — Ball speed anchors.
const kBallSpeedAnchors = Anchors(min: 130, scratch: 155, pro: 170);

// S14 §14.3.3 — Club head speed anchors.
const kClubHeadSpeedAnchors = Anchors(min: 85, scratch: 105, pro: 115);

// TD-05 §4.6 — User custom drill anchors.
const kCustomDrillAnchors = Anchors(min: 20, scratch: 50, pro: 75);

// S14 §14.3.2 — Standard distance control anchors (Irons, Woods).
const kStandardDistanceAnchors = Anchors(min: 30, scratch: 70, pro: 90);

// S14 §14.3.2 — Putting distance control anchors.
const kPuttingDistanceAnchors = Anchors(min: 20, scratch: 60, pro: 80);

// S14 §14.3.2 — Chipping distance control anchors.
const kChippingDistanceAnchors = Anchors(min: 10, scratch: 50, pro: 70);

// S14 §14.3.2 — Bunkers distance control anchors.
const kBunkersDistanceAnchors = Anchors(min: 10, scratch: 40, pro: 60);

/// Creates a [WindowEntry] with sensible defaults for testing.
WindowEntry makeWindowEntry({
  required String sessionId,
  required double score,
  double occupancy = 1.0,
  bool isDualMapped = false,
  DateTime? completionTimestamp,
}) {
  return WindowEntry(
    sessionId: sessionId,
    completionTimestamp:
        completionTimestamp ?? DateTime(2026, 1, 1, 12, 0, 0),
    score: score,
    occupancy: occupancy,
    isDualMapped: isDualMapped,
  );
}

/// Generates [count] window entries with sequential timestamps and sessionIds.
/// Entries are generated oldest-first (S1 oldest, S[count] newest).
List<WindowEntry> generateEntries({
  required int count,
  required double score,
  double occupancy = 1.0,
  bool isDualMapped = false,
}) {
  return List.generate(count, (i) {
    final index = i + 1;
    return WindowEntry(
      sessionId: 'S$index',
      completionTimestamp:
          DateTime(2026, 1, 1, 12, 0, 0).add(Duration(minutes: index)),
      score: score,
      occupancy: occupancy,
      isDualMapped: isDualMapped,
    );
  });
}
