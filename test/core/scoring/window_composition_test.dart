import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/core/scoring/window_composer.dart';

import '../../fixtures/scoring_fixtures.dart';

void main() {
  // TD-05 §6 — Window Composition Test Cases.

  group('§6.1 Basic Window Fill', () {
    test('TC-6.1.1: 5 Single-Mapped Sessions → WindowAverage 3.45', () {
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = [
        makeWindowEntry(
            sessionId: 'S1',
            score: 3.5,
            completionTimestamp: base.add(const Duration(minutes: 1))),
        makeWindowEntry(
            sessionId: 'S2',
            score: 4.0,
            completionTimestamp: base.add(const Duration(minutes: 2))),
        makeWindowEntry(
            sessionId: 'S3',
            score: 2.5,
            completionTimestamp: base.add(const Duration(minutes: 3))),
        makeWindowEntry(
            sessionId: 'S4',
            score: 3.0,
            completionTimestamp: base.add(const Duration(minutes: 4))),
        makeWindowEntry(
            sessionId: 'S5',
            score: 4.25,
            completionTimestamp: base.add(const Duration(minutes: 5))),
      ];

      final result = composeWindow(entries);

      expect(result.totalOccupancy, closeTo(5.0, 1e-9));
      expect(result.weightedSum, closeTo(17.25, 1e-9));
      expect(result.windowAverage, closeTo(3.45, 1e-9));
      expect(result.entries.length, 5);
    });
  });

  group('§6.2 Full Window — 25 Units', () {
    test('TC-6.2.1: 25 Sessions, All Score 3.0 → WindowAverage 3.0', () {
      final entries = generateEntries(count: 25, score: 3.0);

      final result = composeWindow(entries);

      expect(result.totalOccupancy, closeTo(25.0, 1e-9));
      expect(result.weightedSum, closeTo(75.0, 1e-9));
      expect(result.windowAverage, closeTo(3.0, 1e-9));
      expect(result.entries.length, 25);
    });
  });

  group('§6.3 Overflow — Eviction', () {
    test('TC-6.3.1: 26th Session Evicts Oldest → WindowAverage 3.08', () {
      // Caller handles roll-off: passes S2..S25 + S26 (S1 evicted).
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = <WindowEntry>[];

      // S2..S25: 24 sessions scoring 3.0.
      for (var i = 2; i <= 25; i++) {
        entries.add(makeWindowEntry(
          sessionId: 'S$i',
          score: 3.0,
          completionTimestamp: base.add(Duration(minutes: i)),
        ));
      }
      // S26: newest, score 5.0.
      entries.add(makeWindowEntry(
        sessionId: 'S26',
        score: 5.0,
        completionTimestamp: base.add(const Duration(minutes: 26)),
      ));

      final result = composeWindow(entries);

      expect(result.totalOccupancy, closeTo(25.0, 1e-9));
      expect(result.weightedSum, closeTo(77.0, 1e-9));
      expect(result.windowAverage, closeTo(3.08, 1e-9));
      expect(result.entries.length, 25);
    });
  });

  group('§6.4 Dual-Mapped — 0.5 Occupancy', () {
    test('TC-6.4.1: Dual-Mapped Session has 0.5 occupancy per window', () {
      final entry = makeWindowEntry(
        sessionId: 'S1',
        score: 4.0,
        occupancy: 0.5,
        isDualMapped: true,
      );

      final result = composeWindow([entry]);

      expect(result.totalOccupancy, closeTo(0.5, 1e-9));
      expect(result.entries.length, 1);
      expect(result.entries.first.score, closeTo(4.0, 1e-9));
      expect(result.entries.first.occupancy, closeTo(0.5, 1e-9));
    });
  });

  group('§6.5 Mixed Occupancy', () {
    test('TC-6.5.1: Window with 1.0 and 0.5 Entries → WindowAverage 3.5',
        () {
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = [
        makeWindowEntry(
            sessionId: 'S1',
            score: 3.0,
            completionTimestamp: base.add(const Duration(minutes: 1))),
        makeWindowEntry(
            sessionId: 'S2',
            score: 3.5,
            completionTimestamp: base.add(const Duration(minutes: 2))),
        makeWindowEntry(
            sessionId: 'S3',
            score: 4.0,
            completionTimestamp: base.add(const Duration(minutes: 3))),
        makeWindowEntry(
            sessionId: 'S4',
            score: 2.5,
            occupancy: 0.5,
            isDualMapped: true,
            completionTimestamp: base.add(const Duration(minutes: 4))),
        makeWindowEntry(
            sessionId: 'S5',
            score: 4.5,
            occupancy: 0.5,
            isDualMapped: true,
            completionTimestamp: base.add(const Duration(minutes: 5))),
      ];

      final result = composeWindow(entries);

      // TotalOccupancy = 3×1.0 + 2×0.5 = 4.0
      expect(result.totalOccupancy, closeTo(4.0, 1e-9));
      // WeightedSum = 3.0 + 3.5 + 4.0 + (2.5×0.5) + (4.5×0.5) = 14.0
      expect(result.weightedSum, closeTo(14.0, 1e-9));
      // WindowAverage = 14.0 / 4.0 = 3.5
      expect(result.windowAverage, closeTo(3.5, 1e-9));
    });
  });

  group('§6.6 Boundary — 0.5 Fits, 1.0 Does Not', () {
    test('TC-6.6.1: At 24.5 — Session A (1.0) excluded, Session B (0.5) included',
        () {
      // 24.5 occupancy of newer entries fills first. Then two older candidates:
      // Session A (1.0, more recent of the two) → 24.5+1.0=25.5>25 → excluded.
      // Session B (0.5, older of the two) → 24.5+0.5=25.0≤25 → included.
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = <WindowEntry>[];

      // Session A: 1.0 occupancy, older candidate (more recent than B).
      entries.add(makeWindowEntry(
        sessionId: 'S-A',
        score: 4.0,
        completionTimestamp: base.add(const Duration(minutes: 2)),
      ));

      // Session B: 0.5 occupancy, oldest candidate.
      entries.add(makeWindowEntry(
        sessionId: 'S-B',
        score: 3.0,
        occupancy: 0.5,
        isDualMapped: true,
        completionTimestamp: base.add(const Duration(minutes: 1)),
      ));

      // 24 single-mapped entries (newest, fill first) = 24.0 occupancy.
      for (var i = 1; i <= 24; i++) {
        entries.add(makeWindowEntry(
          sessionId: 'S${i + 100}',
          score: 3.0,
          completionTimestamp: base.add(Duration(minutes: 10 + i)),
        ));
      }

      // 0.5 entry to reach 24.5 (also newer than A and B).
      entries.add(makeWindowEntry(
        sessionId: 'S-Half',
        score: 3.0,
        occupancy: 0.5,
        isDualMapped: true,
        completionTimestamp: base.add(const Duration(minutes: 35)),
      ));

      final result = composeWindow(entries);

      expect(result.totalOccupancy, closeTo(25.0, 1e-9));
      final sessionIds = result.entries.map((e) => e.sessionId).toSet();
      expect(sessionIds, isNot(contains('S-A')));
      expect(sessionIds, contains('S-B'));
    });
  });

  group('§6.7 Partial Roll-Off', () {
    test('TC-6.7.1: 1.0 Entry Partially Rolled Off to 0.5 → WindowAverage 3.05',
        () {
      // TD-05: Prior WeightedSum = 75.0 with 25 occupancy.
      // S1 (score 2.0) rolled from 1.0 → 0.5. S26 (0.5, score 4.5) added.
      // New sum = 75.0 − (2.0×0.5) + (4.5×0.5) = 75.0 − 1.0 + 2.25 = 76.25.
      // New average = 76.25 / 25.0 = 3.05.
      //
      // Construct entries matching prior sum = 75.0:
      // S1(2.0×1.0=2.0) + S2(4.0×1.0=4.0) + S3..S25(23×3.0=69.0) = 75.0.
      // After roll-off: S1 occupancy → 0.5. Caller passes adjusted entries.
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = <WindowEntry>[];

      // S1: reduced to 0.5 occupancy, score preserved at 2.0.
      entries.add(makeWindowEntry(
        sessionId: 'S1',
        score: 2.0,
        occupancy: 0.5,
        completionTimestamp: base.add(const Duration(minutes: 1)),
      ));

      // S2: score 4.0 (makes collective sum correct).
      entries.add(makeWindowEntry(
        sessionId: 'S2',
        score: 4.0,
        completionTimestamp: base.add(const Duration(minutes: 2)),
      ));

      // S3..S25: 23 sessions at score 3.0.
      for (var i = 3; i <= 25; i++) {
        entries.add(makeWindowEntry(
          sessionId: 'S$i',
          score: 3.0,
          completionTimestamp: base.add(Duration(minutes: i)),
        ));
      }

      // S26: dual-mapped, 0.5 occupancy, score 4.5.
      entries.add(makeWindowEntry(
        sessionId: 'S26',
        score: 4.5,
        occupancy: 0.5,
        isDualMapped: true,
        completionTimestamp: base.add(const Duration(minutes: 26)),
      ));

      final result = composeWindow(entries);

      expect(result.totalOccupancy, closeTo(25.0, 1e-9));
      expect(result.weightedSum, closeTo(76.25, 1e-9));
      expect(result.windowAverage, closeTo(3.05, 1e-9));

      // S1 score preserved at 2.0 with 0.5 occupancy.
      final s1 = result.entries.firstWhere((e) => e.sessionId == 'S1');
      expect(s1.score, closeTo(2.0, 1e-9));
      expect(s1.occupancy, closeTo(0.5, 1e-9));
    });

    test('TC-6.7.2: Full Roll-Off — 0.5 Entry Removed, Next Entry Reduced',
        () {
      // S1 (0.5, score 2.0) removed entirely. S2 (1.0) reduced to 0.5.
      // S26 (1.0, score 4.0) inserted. Caller provides pre-adjusted entries.
      //
      // Original: S1(0.5) + S2(1.0) + S3..S25(23×1.0) = 24.5.
      // Need 25.0, so add another 0.5 entry: S-extra(0.5).
      // Total: 0.5 + 1.0 + 23.0 + 0.5 = 25.0. ✓
      //
      // After: S1 removed, S2 → 0.5, S26(1.0) added.
      // Remaining: S2(0.5) + S3..S25(23.0) + S-extra(0.5) + S26(1.0) = 25.0.
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = <WindowEntry>[];

      // S2: reduced to 0.5, score preserved at 3.0.
      entries.add(makeWindowEntry(
        sessionId: 'S2',
        score: 3.0,
        occupancy: 0.5,
        completionTimestamp: base.add(const Duration(minutes: 2)),
      ));

      // S3..S25: 23 sessions at 1.0 occupancy, score 3.0.
      for (var i = 3; i <= 25; i++) {
        entries.add(makeWindowEntry(
          sessionId: 'S$i',
          score: 3.0,
          completionTimestamp: base.add(Duration(minutes: i)),
        ));
      }

      // S-extra: 0.5 occupancy, score 3.0 (was in original window).
      entries.add(makeWindowEntry(
        sessionId: 'S-extra',
        score: 3.0,
        occupancy: 0.5,
        isDualMapped: true,
        completionTimestamp: base.add(const Duration(minutes: 0)),
      ));

      // S26: single-mapped, 1.0 occupancy, score 4.0.
      entries.add(makeWindowEntry(
        sessionId: 'S26',
        score: 4.0,
        completionTimestamp: base.add(const Duration(minutes: 26)),
      ));

      final result = composeWindow(entries);

      // TotalOccupancy = 0.5 + 23.0 + 0.5 + 1.0 = 25.0
      expect(result.totalOccupancy, closeTo(25.0, 1e-9));

      // S1 removed, S2 at 0.5 (score preserved), S26 included.
      final sessionIds = result.entries.map((e) => e.sessionId).toSet();
      expect(sessionIds, isNot(contains('S1')));
      expect(sessionIds, contains('S2'));
      expect(sessionIds, contains('S26'));

      final s2 = result.entries.firstWhere((e) => e.sessionId == 'S2');
      expect(s2.occupancy, closeTo(0.5, 1e-9));
      expect(s2.score, closeTo(3.0, 1e-9));
    });

    test('TC-6.7.3: 0.5 Entry Swapped for 0.5 Entry → WindowAverage 3.04',
        () {
      // TD-05: Prior sum = 75.0 at 25.0 occupancy. S1 (0.5, score 2.0) removed.
      // S26 (0.5, score 4.0) inserted.
      // New sum = 75.0 − 1.0 + 2.0 = 76.0. Average = 76.0/25.0 = 3.04.
      //
      // Prior: S1(0.5, 2.0) + others summing to 74.0 over 24.5 occupancy.
      // Use: S2(0.5, 4.0) + S3..S26orig(24×1.0, 3.0) = 2.0 + 72.0 = 74.0. ✓
      final base = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = <WindowEntry>[];

      // S1 removed (not in entries).

      // S2: 0.5 occupancy, score 4.0.
      entries.add(makeWindowEntry(
        sessionId: 'S2',
        score: 4.0,
        occupancy: 0.5,
        isDualMapped: true,
        completionTimestamp: base.add(const Duration(minutes: 2)),
      ));

      // S3..S26orig: 24 sessions at 1.0 occupancy, score 3.0.
      for (var i = 3; i <= 26; i++) {
        entries.add(makeWindowEntry(
          sessionId: 'S$i',
          score: 3.0,
          completionTimestamp: base.add(Duration(minutes: i)),
        ));
      }

      // S27 (the "S26" in TD-05 notation): 0.5 occupancy, score 4.0.
      entries.add(makeWindowEntry(
        sessionId: 'S27',
        score: 4.0,
        occupancy: 0.5,
        isDualMapped: true,
        completionTimestamp: base.add(const Duration(minutes: 27)),
      ));

      final result = composeWindow(entries);

      // TotalOccupancy = 0.5 + 24×1.0 + 0.5 = 25.0
      expect(result.totalOccupancy, closeTo(25.0, 1e-9));
      // WeightedSum = 4.0×0.5 + 24×3.0 + 4.0×0.5 = 2.0 + 72.0 + 2.0 = 76.0
      expect(result.weightedSum, closeTo(76.0, 1e-9));
      // WindowAverage = 76.0/25.0 = 3.04
      expect(result.windowAverage, closeTo(3.04, 1e-9));
    });
  });

  group('§6.8 Deterministic Ordering', () {
    test('TC-6.8.1: Tiebreak on SessionID DESC', () {
      final ts = DateTime(2026, 1, 1, 12, 0, 0);
      final entries = [
        makeWindowEntry(
            sessionId: 'S-AAA', score: 3.0, completionTimestamp: ts),
        makeWindowEntry(
            sessionId: 'S-ZZZ', score: 4.0, completionTimestamp: ts),
      ];

      final result = composeWindow(entries);

      expect(result.entries[0].sessionId, 'S-ZZZ');
      expect(result.entries[1].sessionId, 'S-AAA');
    });
  });

  group('Edge cases', () {
    test('Empty entries returns zero window', () {
      final result = composeWindow([]);
      expect(result.totalOccupancy, closeTo(0.0, 1e-9));
      expect(result.weightedSum, closeTo(0.0, 1e-9));
      expect(result.windowAverage, closeTo(0.0, 1e-9));
      expect(result.entries, isEmpty);
    });
  });
}
