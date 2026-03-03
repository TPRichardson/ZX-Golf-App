import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/scoring_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/providers/review_providers.dart';

// Fix 7 — Multi-Output drill-level display score.
// For dual-mapped drills, drill-level score = mean of subskill 0–5 outputs.

void main() {
  group('Fix 7: buildDrillLevelScoreMap', () {
    test('single-mapped session returns single score unchanged', () {
      // Simulate a single-mapped session appearing in one window.
      final windows = [
        _makeWindow(
          subskill: 'irons_direction_control',
          entries: [
            WindowEntry(
              sessionId: 'session-1',
              completionTimestamp: DateTime(2026, 3, 1),
              score: 3.5,
              occupancy: 1.0,
              isDualMapped: false,
            ),
          ],
        ),
      ];

      final map = buildDrillLevelScoreMap(windows);

      expect(map['session-1'], 3.5);
    });

    test('dual-mapped session averages scores across two windows', () {
      // Simulate a dual-mapped session appearing in two different subskill windows.
      final windows = [
        _makeWindow(
          subskill: 'irons_direction_control',
          entries: [
            WindowEntry(
              sessionId: 'session-dual',
              completionTimestamp: DateTime(2026, 3, 1),
              score: 3.0,
              occupancy: 0.5,
              isDualMapped: true,
            ),
          ],
        ),
        _makeWindow(
          subskill: 'irons_distance_control',
          entries: [
            WindowEntry(
              sessionId: 'session-dual',
              completionTimestamp: DateTime(2026, 3, 1),
              score: 5.0,
              occupancy: 0.5,
              isDualMapped: true,
            ),
          ],
        ),
      ];

      final map = buildDrillLevelScoreMap(windows);

      // Mean of 3.0 and 5.0 = 4.0.
      expect(map['session-dual'], 4.0);
    });

    test('mixed sessions: single and dual-mapped coexist correctly', () {
      final windows = [
        _makeWindow(
          subskill: 'irons_direction_control',
          entries: [
            WindowEntry(
              sessionId: 'session-single',
              completionTimestamp: DateTime(2026, 3, 1),
              score: 2.5,
              occupancy: 1.0,
              isDualMapped: false,
            ),
            WindowEntry(
              sessionId: 'session-dual',
              completionTimestamp: DateTime(2026, 3, 2),
              score: 4.0,
              occupancy: 0.5,
              isDualMapped: true,
            ),
          ],
        ),
        _makeWindow(
          subskill: 'irons_distance_control',
          entries: [
            WindowEntry(
              sessionId: 'session-dual',
              completionTimestamp: DateTime(2026, 3, 2),
              score: 2.0,
              occupancy: 0.5,
              isDualMapped: true,
            ),
          ],
        ),
      ];

      final map = buildDrillLevelScoreMap(windows);

      // Single-mapped: unchanged.
      expect(map['session-single'], 2.5);
      // Dual-mapped: mean of 4.0 and 2.0 = 3.0.
      expect(map['session-dual'], 3.0);
    });
  });
}

/// Create a fake MaterialisedWindowState with given entries.
MaterialisedWindowState _makeWindow({
  required String subskill,
  required List<WindowEntry> entries,
}) {
  final entriesJson = jsonEncode(entries
      .map((e) => {
            'sessionId': e.sessionId,
            'completionTimestamp': e.completionTimestamp.toIso8601String(),
            'score': e.score,
            'occupancy': e.occupancy,
            'isDualMapped': e.isDualMapped,
          })
      .toList());

  return MaterialisedWindowState(
    userId: 'test-user',
    skillArea: SkillArea.irons,
    subskill: subskill,
    practiceType: DrillType.transition,
    entries: entriesJson,
    totalOccupancy: entries.fold(0.0, (sum, e) => sum + e.occupancy),
    weightedSum: entries.fold(0.0, (sum, e) => sum + e.score * e.occupancy),
    windowAverage: entries.isEmpty
        ? 0.0
        : entries.fold(0.0, (sum, e) => sum + e.score * e.occupancy) /
            entries.fold(0.0, (sum, e) => sum + e.occupancy),
  );
}
