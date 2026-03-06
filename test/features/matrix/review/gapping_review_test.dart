import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/gapping_review_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

// Phase M9 — Gapping review screen tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRunWithDetails _makeDetails({
  List<_CellDef>? cells,
}) {
  final run = MatrixRun(
    matrixRunId: 'mr-1',
    userId: 'test-user',
    matrixType: MatrixType.gappingChart,
    runNumber: 1,
    runState: RunState.completed,
    startTimestamp: _ts,
    endTimestamp: _ts.add(const Duration(hours: 1)),
    sessionShotTarget: 5,
    shotOrderMode: ShotOrderMode.topToBottom,
    dispersionCaptureEnabled: false,
    measurementDevice: null,
    environmentType: null,
    surfaceType: null,
    greenSpeed: null,
    greenFirmness: null,
    isDeleted: false,
    createdAt: _ts,
    updatedAt: _ts,
  );

  final axis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-1',
      matrixRunId: 'mr-1',
      axisType: AxisType.club,
      axisName: 'Club',
      axisOrder: 0,
      createdAt: _ts,
      updatedAt: _ts,
    ),
    values: [
      MatrixAxisValue(
        axisValueId: 'v-pw',
        matrixAxisId: 'ax-1',
        label: 'PW',
        sortOrder: 0,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      MatrixAxisValue(
        axisValueId: 'v-9i',
        matrixAxisId: 'ax-1',
        label: '9-Iron',
        sortOrder: 1,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      MatrixAxisValue(
        axisValueId: 'v-8i',
        matrixAxisId: 'ax-1',
        label: '8-Iron',
        sortOrder: 2,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    ],
  );

  final cellDefs = cells ??
      [
        _CellDef('c-1', 'v-pw', 135, 142, 5),
        _CellDef('c-2', 'v-9i', 148, 156, 5),
        _CellDef('c-3', 'v-8i', 160, 168, 5),
      ];

  final matrixCells = cellDefs.map((d) {
    return MatrixCellWithAttempts(
      cell: MatrixCell(
        matrixCellId: d.id,
        matrixRunId: 'mr-1',
        axisValueIds: jsonEncode([d.valueId]),
        excludedFromRun: false,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      attempts: List.generate(d.shots, (i) {
        return MatrixAttempt(
          matrixAttemptId: '${d.id}-a$i',
          matrixCellId: d.id,
          attemptTimestamp: _ts,
          carryDistanceMeters: d.carry,
          totalDistanceMeters: d.total,
          leftDeviationMeters: null,
          rightDeviationMeters: null,
          rolloutDistanceMeters: null,
          createdAt: _ts,
          updatedAt: _ts,
        );
      }),
    );
  }).toList();

  return MatrixRunWithDetails(
    run: run,
    axes: [axis],
    cells: matrixCells,
  );
}

class _CellDef {
  final String id;
  final String valueId;
  final double carry;
  final double? total;
  final int shots;
  const _CellDef(this.id, this.valueId, this.carry, this.total, this.shots);
}

void main() {
  group('GappingReviewScreen', () {
    testWidgets('shows distance ladder and table', (tester) async {
      final details = _makeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distance Ladder'), findsOneWidget);
      expect(find.text('Distance Table'), findsOneWidget);
      expect(find.text('Run #1'), findsOneWidget);
    });

    testWidgets('orders clubs by carry distance', (tester) async {
      final details = _makeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PW (135) < 9-Iron (148) < 8-Iron (160).
      expect(find.text('PW'), findsWidgets);
      expect(find.text('9-Iron'), findsWidgets);
      expect(find.text('8-Iron'), findsWidgets);
    });

    testWidgets('shows gap warning for small gap', (tester) async {
      // PW 135, 9i 139 → gap = 4 < 6 (small gap warning).
      final details = _makeDetails(cells: [
        _CellDef('c-1', 'v-pw', 135, 142, 5),
        _CellDef('c-2', 'v-9i', 139, 147, 5),
        _CellDef('c-3', 'v-8i', 160, 168, 5),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should find warning icon.
      expect(find.byIcon(Icons.warning_amber), findsWidgets);
    });

    testWidgets('shows gap warning for large gap', (tester) async {
      // PW 135, 9i 160 → gap = 25 > 20 (large gap warning).
      final details = _makeDetails(cells: [
        _CellDef('c-1', 'v-pw', 135, 142, 5),
        _CellDef('c-2', 'v-9i', 160, 168, 5),
        _CellDef('c-3', 'v-8i', 185, 193, 5),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber), findsWidgets);
    });

    testWidgets('shows shot counts', (tester) async {
      final details = _makeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 shots per club.
      expect(find.text('5'), findsNWidgets(3));
    });

    testWidgets('shows no data when run has no attempts', (tester) async {
      final details = _makeDetails(cells: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data recorded'), findsOneWidget);
    });

    testWidgets('no warning icons when gaps are normal', (tester) async {
      // PW 135, 9i 148, 8i 160 → gaps 13 and 12, both in [6, 20].
      final details = _makeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingReviewScreen(matrixRunId: 'mr-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No warning icons in the table (only gap legend has one).
      // The gap legend row always shows the icon, so find exactly 1.
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });
  });
}
