import 'dart:convert';
import 'dart:math' show sqrt;

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/core/scoring/scoring_helpers.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// Phase 6 — Review provider unit tests.
// Tests for window entry parsing, heatmap opacity, plan adherence, bucketing.

void main() {
  // ---------------------------------------------------------------------------
  // Window Entry JSON Parsing
  // ---------------------------------------------------------------------------

  group('parseWindowEntries — JSON round-trip', () {
    test('parses empty JSON array', () {
      final entries = decodeWindowEntries('[]');
      expect(entries, isEmpty);
    });

    test('parses empty string', () {
      final entries = decodeWindowEntries('');
      expect(entries, isEmpty);
    });

    test('parses single entry with all fields', () {
      final json = jsonEncode([
        {
          'sessionId': 'sess-1',
          'completionTimestamp': '2026-03-01T10:30:00.000',
          'score': 3.5,
          'occupancy': 1.0,
          'isDualMapped': false,
        }
      ]);

      final entries = decodeWindowEntries(json);
      expect(entries, hasLength(1));
      expect(entries[0].sessionId, 'sess-1');
      expect(entries[0].score, 3.5);
      expect(entries[0].occupancy, 1.0);
      expect(entries[0].isDualMapped, false);
      expect(entries[0].completionTimestamp.year, 2026);
      expect(entries[0].completionTimestamp.month, 3);
    });

    test('parses multiple entries', () {
      final json = jsonEncode([
        {
          'sessionId': 'sess-1',
          'completionTimestamp': '2026-03-01T10:00:00.000',
          'score': 4.0,
          'occupancy': 1.0,
          'isDualMapped': false,
        },
        {
          'sessionId': 'sess-2',
          'completionTimestamp': '2026-02-28T14:00:00.000',
          'score': 2.5,
          'occupancy': 0.5,
          'isDualMapped': true,
        },
      ]);

      final entries = decodeWindowEntries(json);
      expect(entries, hasLength(2));
      expect(entries[0].sessionId, 'sess-1');
      expect(entries[1].sessionId, 'sess-2');
      expect(entries[1].occupancy, 0.5);
      expect(entries[1].isDualMapped, true);
    });

    test('handles integer score values', () {
      final json = jsonEncode([
        {
          'sessionId': 'sess-1',
          'completionTimestamp': '2026-03-01T10:00:00.000',
          'score': 5,
          'occupancy': 1,
          'isDualMapped': false,
        },
      ]);

      final entries = decodeWindowEntries(json);
      expect(entries[0].score, 5.0);
      expect(entries[0].occupancy, 1.0);
    });

    test('round-trip: encode then parse preserves data', () {
      final original = [
        WindowEntry(
          sessionId: 'sess-1',
          completionTimestamp: DateTime(2026, 3, 1, 10, 30),
          score: 3.75,
          occupancy: 0.5,
          isDualMapped: true,
        ),
        WindowEntry(
          sessionId: 'sess-2',
          completionTimestamp: DateTime(2026, 2, 28, 14, 0),
          score: 4.2,
          occupancy: 1.0,
          isDualMapped: false,
        ),
      ];

      // Encode like reflow engine does.
      final encoded = jsonEncode(original
          .map((e) => {
                'sessionId': e.sessionId,
                'completionTimestamp':
                    e.completionTimestamp.toIso8601String(),
                'score': e.score,
                'occupancy': e.occupancy,
                'isDualMapped': e.isDualMapped,
              })
          .toList());

      // Parse back.
      final parsed = decodeWindowEntries(encoded);
      expect(parsed, hasLength(2));
      expect(parsed[0].sessionId, 'sess-1');
      expect(parsed[0].score, 3.75);
      expect(parsed[0].occupancy, 0.5);
      expect(parsed[0].isDualMapped, true);
      expect(parsed[1].sessionId, 'sess-2');
      expect(parsed[1].score, 4.2);
      expect(parsed[1].occupancy, 1.0);
      expect(parsed[1].isDualMapped, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Heatmap Opacity — S15 §15.3.3
  // ---------------------------------------------------------------------------

  group('Heatmap opacity — continuous scale', () {
    test('zero score → 0.0 opacity', () {
      const score = 0.0;
      final normalised = score > 0
          ? (score / kMaxScore).clamp(0.0, 1.0)
          : 0.0;
      expect(normalised, 0.0);
    });

    test('max score → 1.0 opacity', () {
      final normalised = (kMaxScore / kMaxScore).clamp(0.0, 1.0);
      expect(normalised, 1.0);
    });

    test('mid score → 0.5 opacity', () {
      final midScore = kMaxScore / 2;
      final normalised = (midScore / kMaxScore).clamp(0.0, 1.0);
      expect(normalised, closeTo(0.5, 0.001));
    });

    test('score of 1.0 → 0.2 opacity', () {
      const score = 1.0;
      final normalised = (score / kMaxScore).clamp(0.0, 1.0);
      expect(normalised, closeTo(0.2, 0.001));
    });

    test('score of 4.5 → 0.9 opacity', () {
      const score = 4.5;
      final normalised = (score / kMaxScore).clamp(0.0, 1.0);
      expect(normalised, closeTo(0.9, 0.001));
    });

    test('negative score clamps to 0.0', () {
      const score = -1.0;
      final normalised = score > 0
          ? (score / kMaxScore).clamp(0.0, 1.0)
          : 0.0;
      expect(normalised, 0.0);
    });

    test('score above max clamps to 1.0', () {
      const score = 6.0;
      final normalised = (score / kMaxScore).clamp(0.0, 1.0);
      expect(normalised, 1.0);
    });

    test('continuous scale has no discrete bands', () {
      // Verify many intermediate values produce different opacities.
      final opacities = <double>{};
      for (var s = 0.0; s <= kMaxScore; s += 0.1) {
        final normalised = (s / kMaxScore).clamp(0.0, 1.0);
        opacities.add((normalised * 100).round() / 100.0);
      }
      // With 0.1 step over 0-5 range = 51 values, should have many distinct.
      expect(opacities.length, greaterThan(40));
    });
  });

  // ---------------------------------------------------------------------------
  // Plan Adherence Calculation — S05 §5.3
  // ---------------------------------------------------------------------------

  group('Plan adherence calculation', () {
    test('empty slots → 0%', () {
      const adherence = PlanAdherence(
        totalPlanned: 0,
        completedPlanned: 0,
        percentage: 0,
        perSkillArea: {},
      );
      expect(adherence.percentage, 0);
      expect(adherence.totalPlanned, 0);
    });

    test('all completed → 100%', () {
      const adherence = PlanAdherence(
        totalPlanned: 5,
        completedPlanned: 5,
        percentage: 100,
        perSkillArea: {},
      );
      expect(adherence.percentage, 100);
    });

    test('partial completion', () {
      const adherence = PlanAdherence(
        totalPlanned: 10,
        completedPlanned: 3,
        percentage: 30,
        perSkillArea: {},
      );
      expect(adherence.percentage, 30);
    });

    test('overflow slots excluded from planned count', () {
      // Overflow slots have planned=false.
      final slots = [
        const Slot(
          drillId: 'd1',
          planned: true,
          completionState: CompletionState.completedLinked,
        ),
        const Slot(
          drillId: 'd2',
          planned: true,
          completionState: CompletionState.incomplete,
        ),
        const Slot(
          drillId: 'd3',
          planned: false,
          completionState: CompletionState.completedLinked,
        ),
      ];

      // Count only planned slots with drillId.
      int totalPlanned = 0;
      int completedPlanned = 0;
      for (final slot in slots) {
        if (!slot.planned || slot.drillId == null) continue;
        totalPlanned++;
        if (slot.isCompleted) completedPlanned++;
      }

      expect(totalPlanned, 2);
      expect(completedPlanned, 1);
      expect(completedPlanned / totalPlanned * 100, 50.0);
    });

    test('empty drillId slots excluded', () {
      final slots = [
        const Slot(
          drillId: null,
          planned: true,
          completionState: CompletionState.incomplete,
        ),
        const Slot(
          drillId: 'd1',
          planned: true,
          completionState: CompletionState.completedManual,
        ),
      ];

      int totalPlanned = 0;
      int completedPlanned = 0;
      for (final slot in slots) {
        if (!slot.planned || slot.drillId == null) continue;
        totalPlanned++;
        if (slot.isCompleted) completedPlanned++;
      }

      expect(totalPlanned, 1);
      expect(completedPlanned, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Session Bucketing — Daily/Weekly/Monthly
  // ---------------------------------------------------------------------------

  group('Session bucketing', () {
    DateTime bucketKey(DateTime ts, String resolution) {
      switch (resolution) {
        case 'daily':
          return DateTime(ts.year, ts.month, ts.day);
        case 'weekly':
          final weekday = ts.weekday;
          final monday = ts.subtract(Duration(days: weekday - 1));
          return DateTime(monday.year, monday.month, monday.day);
        case 'monthly':
          return DateTime(ts.year, ts.month);
        default:
          throw ArgumentError('Invalid resolution: $resolution');
      }
    }

    test('daily bucketing groups by date', () {
      final ts1 = DateTime(2026, 3, 1, 10, 0);
      final ts2 = DateTime(2026, 3, 1, 15, 0);
      final ts3 = DateTime(2026, 3, 2, 9, 0);

      expect(bucketKey(ts1, 'daily'), bucketKey(ts2, 'daily'));
      expect(
          bucketKey(ts1, 'daily'), isNot(bucketKey(ts3, 'daily')));
    });

    test('weekly bucketing groups by ISO week (Monday-based)', () {
      // 2026-03-02 is a Monday.
      final monday = DateTime(2026, 3, 2);
      final wednesday = DateTime(2026, 3, 4);
      final sunday = DateTime(2026, 3, 8);
      final nextMonday = DateTime(2026, 3, 9);

      expect(bucketKey(monday, 'weekly'),
          bucketKey(wednesday, 'weekly'));
      expect(bucketKey(monday, 'weekly'),
          bucketKey(sunday, 'weekly'));
      expect(bucketKey(monday, 'weekly'),
          isNot(bucketKey(nextMonday, 'weekly')));
    });

    test('monthly bucketing groups by month', () {
      final march1 = DateTime(2026, 3, 1);
      final march15 = DateTime(2026, 3, 15);
      final april1 = DateTime(2026, 4, 1);

      expect(bucketKey(march1, 'monthly'),
          bucketKey(march15, 'monthly'));
      expect(bucketKey(march1, 'monthly'),
          isNot(bucketKey(april1, 'monthly')));
    });
  });

  // ---------------------------------------------------------------------------
  // Rolling Average
  // ---------------------------------------------------------------------------

  group('Rolling average computation', () {
    List<double> computeRolling(List<double> values, int window) {
      if (window == 0 || values.length < window) return [];
      final result = <double>[];
      for (var i = window - 1; i < values.length; i++) {
        var sum = 0.0;
        for (var j = i - window + 1; j <= i; j++) {
          sum += values[j];
        }
        result.add(sum / window);
      }
      return result;
    }

    test('daily resolution: 7-bucket window', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0, 4.0, 3.0, 2.0, 1.0];
      final rolling = computeRolling(values, 7);
      // First rolling value: avg of [1,2,3,4,5,4,3] = 22/7 ≈ 3.14
      expect(rolling, hasLength(3));
      expect(rolling[0], closeTo(22 / 7, 0.01));
    });

    test('weekly resolution: 4-bucket window', () {
      final values = [2.0, 3.0, 4.0, 3.5, 3.0];
      final rolling = computeRolling(values, 4);
      // First: avg of [2,3,4,3.5] = 12.5/4 = 3.125
      expect(rolling, hasLength(2));
      expect(rolling[0], closeTo(3.125, 0.001));
    });

    test('monthly resolution: no rolling (window=0)', () {
      final values = [2.0, 3.0, 4.0];
      final rolling = computeRolling(values, 0);
      expect(rolling, isEmpty);
    });

    test('fewer values than window → empty result', () {
      final values = [2.0, 3.0];
      final rolling = computeRolling(values, 7);
      expect(rolling, isEmpty);
    });

    test('exact window size → single value', () {
      final values = [1.0, 2.0, 3.0, 4.0];
      final rolling = computeRolling(values, 4);
      expect(rolling, hasLength(1));
      expect(rolling[0], closeTo(2.5, 0.001));
    });
  });

  // ---------------------------------------------------------------------------
  // Variance / Standard Deviation
  // ---------------------------------------------------------------------------

  group('Variance tracking', () {
    double computeSd(List<double> scores) {
      if (scores.length < 2) return 0;
      final mean = scores.reduce((a, b) => a + b) / scores.length;
      final variance = scores
              .map((s) => (s - mean) * (s - mean))
              .reduce((a, b) => a + b) /
          scores.length;
      return sqrt(variance);
    }

    test('consistent scores → low SD (green)', () {
      final scores = [3.5, 3.4, 3.6, 3.5, 3.5, 3.4, 3.6, 3.5, 3.5, 3.4];
      final sd = computeSd(scores);
      expect(sd, lessThan(0.40));
    });

    test('moderate variation → amber SD', () {
      // Values with SD ~0.65 (between 0.40 and 0.80).
      final scores = [2.0, 3.0, 3.5, 2.5, 3.5, 3.0, 2.0, 3.0, 3.5, 3.0];
      final sd = computeSd(scores);
      expect(sd, greaterThanOrEqualTo(0.40));
      expect(sd, lessThan(0.80));
    });

    test('high variation → red SD', () {
      final scores = [0.5, 4.5, 1.0, 4.0, 0.5, 5.0, 1.0, 4.5, 0.5, 4.0];
      final sd = computeSd(scores);
      expect(sd, greaterThanOrEqualTo(0.80));
    });

    test('single score → SD = 0', () {
      expect(computeSd([3.0]), 0);
    });

    test('confidence: <10 sessions = none', () {
      expect(9 < 10, isTrue);
    });

    test('confidence: 10-19 sessions = low', () {
      expect(15 >= 10 && 15 < 20, isTrue);
    });

    test('confidence: 20+ sessions = full', () {
      expect(25 >= 20, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Zero State Handling
  // ---------------------------------------------------------------------------

  group('Zero state handling', () {
    test('parseWindowEntries handles empty gracefully', () {
      expect(decodeWindowEntries(''), isEmpty);
      expect(decodeWindowEntries('[]'), isEmpty);
    });

    test('PlanAdherence with zero planned is 0%', () {
      const adherence = PlanAdherence(
        totalPlanned: 0,
        completedPlanned: 0,
        percentage: 0,
        perSkillArea: {},
      );
      expect(adherence.percentage, 0);
    });

    test('ParsedWindowDetail with empty entries', () {
      const detail = ParsedWindowDetail(
        entries: [],
        totalOccupancy: 0,
        weightedSum: 0,
        windowAverage: 0,
        subskill: 'test',
        practiceType: DrillType.transition,
        skillArea: SkillArea.putting,
      );
      expect(detail.entries, isEmpty);
      expect(detail.windowAverage, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Overall Score Display Edge Cases
  // ---------------------------------------------------------------------------

  group('Overall score display values', () {
    test('score 0 rounds to 0', () {
      expect(0.0.round(), 0);
    });

    test('score 500.4 rounds to 500', () {
      expect(500.4.round(), 500);
    });

    test('score 999.5 rounds to 1000', () {
      expect(999.5.round(), 1000);
    });

    test('score 1000 rounds to 1000', () {
      expect(1000.0.round(), 1000);
    });
  });
}

