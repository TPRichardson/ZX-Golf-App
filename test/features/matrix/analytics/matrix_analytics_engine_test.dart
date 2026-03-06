import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/analytics/analytics_types.dart';
import 'package:zx_golf_app/features/matrix/analytics/matrix_analytics_engine.dart';

// Phase M10 — Matrix analytics engine tests (§9.5–9.9).

final _refDate = DateTime.utc(2026, 3, 6);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MatrixRun _makeRun(String id, {int daysAgo = 0}) {
  final ts = _refDate.subtract(Duration(days: daysAgo));
  return MatrixRun(
    matrixRunId: id,
    userId: 'test-user',
    matrixType: MatrixType.gappingChart,
    runNumber: 1,
    runState: RunState.completed,
    startTimestamp: ts,
    endTimestamp: ts.add(const Duration(hours: 1)),
    sessionShotTarget: 5,
    shotOrderMode: ShotOrderMode.topToBottom,
    dispersionCaptureEnabled: false,
    measurementDevice: null,
    environmentType: null,
    surfaceType: null,
    greenSpeed: null,
    greenFirmness: null,
    isDeleted: false,
    createdAt: ts,
    updatedAt: ts,
  );
}

MatrixAttempt _makeAttempt(
  String cellId,
  int index, {
  required double carry,
  double? total,
  double? rollout,
}) {
  return MatrixAttempt(
    matrixAttemptId: '$cellId-a$index',
    matrixCellId: cellId,
    attemptTimestamp: _refDate,
    carryDistanceMeters: carry,
    totalDistanceMeters: total ?? carry + 8,
    leftDeviationMeters: null,
    rightDeviationMeters: null,
    rolloutDistanceMeters: rollout,
    createdAt: _refDate,
    updatedAt: _refDate,
  );
}

MatrixAxisWithValues _makeClubAxis(
  String runId,
  List<({String id, String label})> clubs,
) {
  return MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-club-$runId',
      matrixRunId: runId,
      axisType: AxisType.club,
      axisName: 'Club',
      axisOrder: 0,
      createdAt: _refDate,
      updatedAt: _refDate,
    ),
    values: clubs
        .asMap()
        .entries
        .map((e) => MatrixAxisValue(
              axisValueId: e.value.id,
              matrixAxisId: 'ax-club-$runId',
              label: e.value.label,
              sortOrder: e.key,
              createdAt: _refDate,
              updatedAt: _refDate,
            ))
        .toList(),
  );
}

MatrixCellWithAttempts _makeCell(
  String cellId,
  String runId,
  List<String> axisValueIds,
  List<MatrixAttempt> attempts, {
  bool excluded = false,
}) {
  return MatrixCellWithAttempts(
    cell: MatrixCell(
      matrixCellId: cellId,
      matrixRunId: runId,
      axisValueIds: jsonEncode(axisValueIds),
      excludedFromRun: excluded,
      createdAt: _refDate,
      updatedAt: _refDate,
    ),
    attempts: attempts,
  );
}

// ---------------------------------------------------------------------------
// §9.6 — Club Distance Analytics
// ---------------------------------------------------------------------------

void main() {
  group('clubDistanceAnalytics', () {
    test('computes correct averages for single run', () {
      final clubs = [
        (id: 'v-pw', label: 'PW'),
        (id: 'v-9i', label: '9i'),
      ];
      final run = MatrixRunWithDetails(
        run: _makeRun('run-1'),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw', 0, carry: 130),
            _makeAttempt('c-pw', 1, carry: 132),
            _makeAttempt('c-pw', 2, carry: 134),
            _makeAttempt('c-pw', 3, carry: 136),
            _makeAttempt('c-pw', 4, carry: 138),
          ]),
          _makeCell('c-9i', 'run-1', ['v-9i'], [
            _makeAttempt('c-9i', 0, carry: 145),
            _makeAttempt('c-9i', 1, carry: 147),
            _makeAttempt('c-9i', 2, carry: 149),
            _makeAttempt('c-9i', 3, carry: 151),
            _makeAttempt('c-9i', 4, carry: 153),
          ]),
        ],
      );

      final results = clubDistanceAnalytics(
        [run],
        referenceDate: _refDate,
      );

      expect(results.length, 2);
      // Sorted by avgCarry: PW first, then 9i.
      expect(results[0].clubLabel, 'PW');
      expect(results[1].clubLabel, '9i');

      // PW: trimmed [132, 134, 136] → avg 134
      expect(results[0].avgCarry, closeTo(134.0, 0.5));
      // 9i: trimmed [147, 149, 151] → avg 149
      expect(results[1].avgCarry, closeTo(149.0, 0.5));
    });

    test('computes distance gaps between clubs', () {
      final clubs = [(id: 'v-pw', label: 'PW'), (id: 'v-9i', label: '9i')];
      final run = MatrixRunWithDetails(
        run: _makeRun('run-1'),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw', 0, carry: 130),
            _makeAttempt('c-pw', 1, carry: 132),
            _makeAttempt('c-pw', 2, carry: 134),
            _makeAttempt('c-pw', 3, carry: 136),
            _makeAttempt('c-pw', 4, carry: 138),
          ]),
          _makeCell('c-9i', 'run-1', ['v-9i'], [
            _makeAttempt('c-9i', 0, carry: 145),
            _makeAttempt('c-9i', 1, carry: 147),
            _makeAttempt('c-9i', 2, carry: 149),
            _makeAttempt('c-9i', 3, carry: 151),
            _makeAttempt('c-9i', 4, carry: 153),
          ]),
        ],
      );

      final results = clubDistanceAnalytics(
        [run],
        referenceDate: _refDate,
      );

      // PW has gap to 9i.
      expect(results[0].distanceGap, isNotNull);
      expect(results[0].distanceGap!, closeTo(15.0, 1.0));
      // 9i is last — no gap.
      expect(results[1].distanceGap, isNull);
    });

    test('excludes cells with < 3 attempts', () {
      final clubs = [(id: 'v-pw', label: 'PW')];
      final run = MatrixRunWithDetails(
        run: _makeRun('run-1'),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw', 0, carry: 130),
            _makeAttempt('c-pw', 1, carry: 132),
          ]),
        ],
      );

      final results = clubDistanceAnalytics(
        [run],
        referenceDate: _refDate,
      );
      expect(results, isEmpty);
    });

    test('excluded cells are skipped', () {
      final clubs = [(id: 'v-pw', label: 'PW')];
      final run = MatrixRunWithDetails(
        run: _makeRun('run-1'),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw', 0, carry: 130),
            _makeAttempt('c-pw', 1, carry: 132),
            _makeAttempt('c-pw', 2, carry: 134),
          ], excluded: true),
        ],
      );

      final results = clubDistanceAnalytics(
        [run],
        referenceDate: _refDate,
      );
      expect(results, isEmpty);
    });

    test('aggregates across multiple runs', () {
      final clubs = [(id: 'v-pw', label: 'PW')];

      final run1 = MatrixRunWithDetails(
        run: _makeRun('run-1', daysAgo: 0),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw-1', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw-1', 0, carry: 130),
            _makeAttempt('c-pw-1', 1, carry: 132),
            _makeAttempt('c-pw-1', 2, carry: 134),
          ]),
        ],
      );

      final run2 = MatrixRunWithDetails(
        run: _makeRun('run-2', daysAgo: 30),
        axes: [_makeClubAxis('run-2', clubs)],
        cells: [
          _makeCell('c-pw-2', 'run-2', ['v-pw'], [
            _makeAttempt('c-pw-2', 0, carry: 140),
            _makeAttempt('c-pw-2', 1, carry: 142),
            _makeAttempt('c-pw-2', 2, carry: 144),
          ]),
        ],
      );

      final results = clubDistanceAnalytics(
        [run1, run2],
        referenceDate: _refDate,
      );

      expect(results.length, 1);
      expect(results[0].dataSources, 2);
      // 6 attempts total, trimmed to ~5.
      expect(results[0].attemptCount, greaterThanOrEqualTo(4));
    });

    test('raw mode gives equal weights', () {
      final clubs = [(id: 'v-pw', label: 'PW')];

      final run1 = MatrixRunWithDetails(
        run: _makeRun('run-1', daysAgo: 0),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw-1', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw-1', 0, carry: 130),
            _makeAttempt('c-pw-1', 1, carry: 132),
            _makeAttempt('c-pw-1', 2, carry: 134),
          ]),
        ],
      );

      final run2 = MatrixRunWithDetails(
        run: _makeRun('run-2', daysAgo: 365),
        axes: [_makeClubAxis('run-2', clubs)],
        cells: [
          _makeCell('c-pw-2', 'run-2', ['v-pw'], [
            _makeAttempt('c-pw-2', 0, carry: 140),
            _makeAttempt('c-pw-2', 1, carry: 142),
            _makeAttempt('c-pw-2', 2, carry: 144),
          ]),
        ],
      );

      final rawResults = clubDistanceAnalytics(
        [run1, run2],
        weighted: false,
        referenceDate: _refDate,
      );

      final weightedResults = clubDistanceAnalytics(
        [run1, run2],
        weighted: true,
        referenceDate: _refDate,
      );

      // Raw should give equal weight to both runs → avg closer to midpoint.
      // Weighted should favour run-1 (age 0) → avg closer to 132.
      expect(rawResults[0].avgCarry, greaterThan(weightedResults[0].avgCarry));
    });

    test('empty runs list returns empty', () {
      expect(clubDistanceAnalytics([], referenceDate: _refDate), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // §9.7 — Wedge Coverage Analytics
  // -------------------------------------------------------------------------

  group('wedgeCoverageAnalytics', () {
    test('computes coverage points sorted by carry', () {
      final ts = _refDate;
      final run = MatrixRunWithDetails(
        run: MatrixRun(
          matrixRunId: 'wr-1',
          userId: 'test-user',
          matrixType: MatrixType.wedgeMatrix,
          runNumber: 1,
          runState: RunState.completed,
          startTimestamp: ts,
          endTimestamp: ts.add(const Duration(hours: 1)),
          sessionShotTarget: 3,
          shotOrderMode: ShotOrderMode.topToBottom,
          dispersionCaptureEnabled: false,
          measurementDevice: null,
          environmentType: null,
          surfaceType: null,
          greenSpeed: null,
          greenFirmness: null,
          isDeleted: false,
          createdAt: ts,
          updatedAt: ts,
        ),
        axes: [
          MatrixAxisWithValues(
            axis: MatrixAxis(
              matrixAxisId: 'ax-club',
              matrixRunId: 'wr-1',
              axisType: AxisType.club,
              axisName: 'Club',
              axisOrder: 0,
              createdAt: ts,
              updatedAt: ts,
            ),
            values: [
              MatrixAxisValue(
                axisValueId: 'v-52',
                matrixAxisId: 'ax-club',
                label: '52°',
                sortOrder: 0,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
          MatrixAxisWithValues(
            axis: MatrixAxis(
              matrixAxisId: 'ax-effort',
              matrixRunId: 'wr-1',
              axisType: AxisType.effort,
              axisName: 'Effort',
              axisOrder: 1,
              createdAt: ts,
              updatedAt: ts,
            ),
            values: [
              MatrixAxisValue(
                axisValueId: 'v-50',
                matrixAxisId: 'ax-effort',
                label: '50%',
                sortOrder: 0,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
          MatrixAxisWithValues(
            axis: MatrixAxis(
              matrixAxisId: 'ax-flight',
              matrixRunId: 'wr-1',
              axisType: AxisType.flight,
              axisName: 'Flight',
              axisOrder: 2,
              createdAt: ts,
              updatedAt: ts,
            ),
            values: [
              MatrixAxisValue(
                axisValueId: 'v-low',
                matrixAxisId: 'ax-flight',
                label: 'Low',
                sortOrder: 0,
                createdAt: ts,
                updatedAt: ts,
              ),
              MatrixAxisValue(
                axisValueId: 'v-std',
                matrixAxisId: 'ax-flight',
                label: 'Standard',
                sortOrder: 1,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
        ],
        cells: [
          _makeCell('c-low', 'wr-1', ['v-52', 'v-50', 'v-low'], [
            _makeAttempt('c-low', 0, carry: 38),
            _makeAttempt('c-low', 1, carry: 40),
            _makeAttempt('c-low', 2, carry: 39),
          ]),
          _makeCell('c-std', 'wr-1', ['v-52', 'v-50', 'v-std'], [
            _makeAttempt('c-std', 0, carry: 42),
            _makeAttempt('c-std', 1, carry: 44),
            _makeAttempt('c-std', 2, carry: 43),
          ]),
        ],
      );

      final results = wedgeCoverageAnalytics(
        [run],
        referenceDate: _refDate,
      );

      expect(results.length, 2);
      // Sorted by avgCarry.
      expect(results[0].avgCarry, lessThan(results[1].avgCarry));
      expect(results[0].flightLabel, 'Low');
      expect(results[1].flightLabel, 'Standard');
    });

    test('empty runs returns empty', () {
      expect(wedgeCoverageAnalytics([], referenceDate: _refDate), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // §9.8 — Chipping Accuracy Analytics
  // -------------------------------------------------------------------------

  group('chippingAccuracyAnalytics', () {
    test('computes accuracy metrics', () {
      final ts = _refDate;
      final run = MatrixRunWithDetails(
        run: MatrixRun(
          matrixRunId: 'cr-1',
          userId: 'test-user',
          matrixType: MatrixType.chippingMatrix,
          runNumber: 1,
          runState: RunState.completed,
          startTimestamp: ts,
          endTimestamp: ts.add(const Duration(hours: 1)),
          sessionShotTarget: 3,
          shotOrderMode: ShotOrderMode.topToBottom,
          dispersionCaptureEnabled: false,
          measurementDevice: null,
          environmentType: null,
          surfaceType: null,
          greenSpeed: 10,
          greenFirmness: GreenFirmness.medium,
          isDeleted: false,
          createdAt: ts,
          updatedAt: ts,
        ),
        axes: [
          MatrixAxisWithValues(
            axis: MatrixAxis(
              matrixAxisId: 'ax-club',
              matrixRunId: 'cr-1',
              axisType: AxisType.club,
              axisName: 'Club',
              axisOrder: 0,
              createdAt: ts,
              updatedAt: ts,
            ),
            values: [
              MatrixAxisValue(
                axisValueId: 'v-sw',
                matrixAxisId: 'ax-club',
                label: 'SW',
                sortOrder: 0,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
          MatrixAxisWithValues(
            axis: MatrixAxis(
              matrixAxisId: 'ax-dist',
              matrixRunId: 'cr-1',
              axisType: AxisType.carryDistance,
              axisName: 'Target',
              axisOrder: 1,
              createdAt: ts,
              updatedAt: ts,
            ),
            values: [
              MatrixAxisValue(
                axisValueId: 'v-10',
                matrixAxisId: 'ax-dist',
                label: '10',
                sortOrder: 0,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
          MatrixAxisWithValues(
            axis: MatrixAxis(
              matrixAxisId: 'ax-flight',
              matrixRunId: 'cr-1',
              axisType: AxisType.flight,
              axisName: 'Flight',
              axisOrder: 2,
              createdAt: ts,
              updatedAt: ts,
            ),
            values: [
              MatrixAxisValue(
                axisValueId: 'v-low',
                matrixAxisId: 'ax-flight',
                label: 'Low',
                sortOrder: 0,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
        ],
        cells: [
          MatrixCellWithAttempts(
            cell: MatrixCell(
              matrixCellId: 'c-1',
              matrixRunId: 'cr-1',
              axisValueIds: jsonEncode(['v-sw', 'v-10', 'v-low']),
              excludedFromRun: false,
              createdAt: ts,
              updatedAt: ts,
            ),
            attempts: [
              // Target 10. Carry: 9.5, 10.2, 9.8. Rollout: 3.0, 3.5, 3.2.
              MatrixAttempt(
                matrixAttemptId: 'a-1',
                matrixCellId: 'c-1',
                attemptTimestamp: ts,
                carryDistanceMeters: 9.5,
                totalDistanceMeters: 12.5,
                leftDeviationMeters: null,
                rightDeviationMeters: null,
                rolloutDistanceMeters: 3.0,
                createdAt: ts,
                updatedAt: ts,
              ),
              MatrixAttempt(
                matrixAttemptId: 'a-2',
                matrixCellId: 'c-1',
                attemptTimestamp: ts,
                carryDistanceMeters: 10.2,
                totalDistanceMeters: 13.7,
                leftDeviationMeters: null,
                rightDeviationMeters: null,
                rolloutDistanceMeters: 3.5,
                createdAt: ts,
                updatedAt: ts,
              ),
              MatrixAttempt(
                matrixAttemptId: 'a-3',
                matrixCellId: 'c-1',
                attemptTimestamp: ts,
                carryDistanceMeters: 9.8,
                totalDistanceMeters: 13.0,
                leftDeviationMeters: null,
                rightDeviationMeters: null,
                rolloutDistanceMeters: 3.2,
                createdAt: ts,
                updatedAt: ts,
              ),
            ],
          ),
        ],
      );

      final results = chippingAccuracyAnalytics(
        [run],
        referenceDate: _refDate,
      );

      expect(results.length, 1);
      final r = results.first;

      expect(r.clubLabel, 'SW');
      expect(r.targetDistance, 10);
      // Avg carry ≈ (9.5+10.2+9.8)/3 = 9.833
      expect(r.avgCarry, closeTo(9.833, 0.1));
      // Avg error: (|9.5-10|+|10.2-10|+|9.8-10|)/3 = (0.5+0.2+0.2)/3 = 0.3
      expect(r.avgError, closeTo(0.3, 0.1));
      // Avg rollout: (3+3.5+3.2)/3 = 3.233
      expect(r.avgRollout, closeTo(3.233, 0.1));
      // Short bias: 2 out of 3 short (9.5 < 10, 9.8 < 10) = 0.667
      expect(r.shortBias, closeTo(0.667, 0.05));
    });

    test('empty runs returns empty', () {
      expect(
          chippingAccuracyAnalytics([], referenceDate: _refDate), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // §9.8.2 — Accuracy Overview
  // -------------------------------------------------------------------------

  group('chippingAccuracyOverview', () {
    test('aggregates by target distance', () {
      final results = [
        ChippingAccuracyResult(
          cellLabel: 'SW — 10 — Low',
          cellKey: '["v-sw","v-10","v-low"]',
          clubLabel: 'SW',
          targetDistance: 10,
          avgCarry: 9.8,
          avgError: 0.3,
          avgRollout: 3.2,
          avgTotal: 13.0,
          shortBias: 0.67,
          carryConsistency: 0.3,
          dataSources: 1,
          attemptCount: 3,
        ),
        ChippingAccuracyResult(
          cellLabel: 'LW — 10 — Low',
          cellKey: '["v-lw","v-10","v-low"]',
          clubLabel: 'LW',
          targetDistance: 10,
          avgCarry: 9.9,
          avgError: 0.5,
          avgRollout: 2.8,
          avgTotal: 12.7,
          shortBias: 0.50,
          carryConsistency: 0.4,
          dataSources: 1,
          attemptCount: 3,
        ),
      ];

      final overview = chippingAccuracyOverview(results);
      expect(overview.length, 1); // Both at target 10.
      expect(overview[0].targetDistance, 10);
      // Avg error across clubs: (0.3 + 0.5) / 2 = 0.4
      expect(overview[0].avgError, closeTo(0.4, 0.01));
      // Avg short bias: (0.67 + 0.50) / 2 ≈ 0.585
      expect(overview[0].shortBias, closeTo(0.585, 0.01));
    });
  });

  // -------------------------------------------------------------------------
  // §9.9 — Distance Trend
  // -------------------------------------------------------------------------

  group('distanceTrend', () {
    test('produces per-run points sorted by timestamp', () {
      final clubs = [(id: 'v-pw', label: 'PW')];
      final cellKey = jsonEncode(['v-pw']);

      final run1 = MatrixRunWithDetails(
        run: _makeRun('run-1', daysAgo: 60),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw-1', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw-1', 0, carry: 130),
            _makeAttempt('c-pw-1', 1, carry: 132),
            _makeAttempt('c-pw-1', 2, carry: 134),
          ]),
        ],
      );

      final run2 = MatrixRunWithDetails(
        run: _makeRun('run-2', daysAgo: 30),
        axes: [_makeClubAxis('run-2', clubs)],
        cells: [
          _makeCell('c-pw-2', 'run-2', ['v-pw'], [
            _makeAttempt('c-pw-2', 0, carry: 135),
            _makeAttempt('c-pw-2', 1, carry: 137),
            _makeAttempt('c-pw-2', 2, carry: 139),
          ]),
        ],
      );

      final points = distanceTrend(
        [run2, run1], // deliberately unordered
        cellKey,
        referenceDate: _refDate,
      );

      expect(points.length, 2);
      // Sorted by timestamp: run-1 (60 days ago) first.
      expect(points[0].matrixRunId, 'run-1');
      expect(points[1].matrixRunId, 'run-2');
      // Per-run averages (no trimming for 3 attempts).
      expect(points[0].avgCarry, closeTo(132, 0.5));
      expect(points[1].avgCarry, closeTo(137, 0.5));
    });

    test('excludes runs with < 3 attempts for cell', () {
      final clubs = [(id: 'v-pw', label: 'PW')];
      final cellKey = jsonEncode(['v-pw']);

      final run = MatrixRunWithDetails(
        run: _makeRun('run-1'),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-pw', 'run-1', ['v-pw'], [
            _makeAttempt('c-pw', 0, carry: 130),
            _makeAttempt('c-pw', 1, carry: 132),
          ]),
        ],
      );

      final points = distanceTrend(
        [run],
        cellKey,
        referenceDate: _refDate,
      );

      expect(points, isEmpty);
    });

    test('includes rollout for chipping trends', () {
      final clubs = [(id: 'v-sw', label: 'SW')];
      final cellKey = jsonEncode(['v-sw']);

      final run = MatrixRunWithDetails(
        run: _makeRun('run-1'),
        axes: [_makeClubAxis('run-1', clubs)],
        cells: [
          _makeCell('c-sw', 'run-1', ['v-sw'], [
            _makeAttempt('c-sw', 0, carry: 9.5, rollout: 3.0),
            _makeAttempt('c-sw', 1, carry: 10.2, rollout: 3.5),
            _makeAttempt('c-sw', 2, carry: 9.8, rollout: 3.2),
          ]),
        ],
      );

      final points = distanceTrend(
        [run],
        cellKey,
        referenceDate: _refDate,
      );

      expect(points.length, 1);
      expect(points[0].avgRollout, isNotNull);
      expect(points[0].avgRollout!, closeTo(3.233, 0.1));
    });
  });
}
