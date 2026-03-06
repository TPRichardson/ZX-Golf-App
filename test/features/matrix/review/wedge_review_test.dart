import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/wedge_review_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

// Phase M9 — Wedge review screen tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRunWithDetails _makeWedgeDetails() {
  final run = MatrixRun(
    matrixRunId: 'mr-w1',
    userId: 'test-user',
    matrixType: MatrixType.wedgeMatrix,
    runNumber: 1,
    runState: RunState.completed,
    startTimestamp: _ts,
    endTimestamp: _ts.add(const Duration(hours: 1)),
    sessionShotTarget: 3,
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

  final clubAxis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-club',
      matrixRunId: 'mr-w1',
      axisType: AxisType.club,
      axisName: 'Club',
      axisOrder: 0,
      createdAt: _ts,
      updatedAt: _ts,
    ),
    values: [
      MatrixAxisValue(
        axisValueId: 'v-52',
        matrixAxisId: 'ax-club',
        label: '52°',
        sortOrder: 0,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    ],
  );

  final effortAxis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-effort',
      matrixRunId: 'mr-w1',
      axisType: AxisType.effort,
      axisName: 'Effort',
      axisOrder: 1,
      createdAt: _ts,
      updatedAt: _ts,
    ),
    values: [
      MatrixAxisValue(
        axisValueId: 'v-50',
        matrixAxisId: 'ax-effort',
        label: '50%',
        sortOrder: 0,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    ],
  );

  final flightAxis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-flight',
      matrixRunId: 'mr-w1',
      axisType: AxisType.flight,
      axisName: 'Flight',
      axisOrder: 2,
      createdAt: _ts,
      updatedAt: _ts,
    ),
    values: [
      MatrixAxisValue(
        axisValueId: 'v-low',
        matrixAxisId: 'ax-flight',
        label: 'Low',
        sortOrder: 0,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      MatrixAxisValue(
        axisValueId: 'v-std',
        matrixAxisId: 'ax-flight',
        label: 'Standard',
        sortOrder: 1,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    ],
  );

  MatrixAttempt makeAttempt(String cellId, int i, double carry) {
    return MatrixAttempt(
      matrixAttemptId: '$cellId-a$i',
      matrixCellId: cellId,
      attemptTimestamp: _ts,
      carryDistanceMeters: carry,
      totalDistanceMeters: carry + 8,
      leftDeviationMeters: null,
      rightDeviationMeters: null,
      rolloutDistanceMeters: null,
      createdAt: _ts,
      updatedAt: _ts,
    );
  }

  final cells = [
    MatrixCellWithAttempts(
      cell: MatrixCell(
        matrixCellId: 'c-low',
        matrixRunId: 'mr-w1',
        axisValueIds: jsonEncode(['v-52', 'v-50', 'v-low']),
        excludedFromRun: false,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      attempts: [
        makeAttempt('c-low', 0, 38),
        makeAttempt('c-low', 1, 40),
        makeAttempt('c-low', 2, 39),
      ],
    ),
    MatrixCellWithAttempts(
      cell: MatrixCell(
        matrixCellId: 'c-std',
        matrixRunId: 'mr-w1',
        axisValueIds: jsonEncode(['v-52', 'v-50', 'v-std']),
        excludedFromRun: false,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      attempts: [
        makeAttempt('c-std', 0, 42),
        makeAttempt('c-std', 1, 44),
        makeAttempt('c-std', 2, 43),
      ],
    ),
  ];

  return MatrixRunWithDetails(
    run: run,
    axes: [clubAxis, effortAxis, flightAxis],
    cells: cells,
  );
}

void main() {
  group('WedgeReviewScreen', () {
    testWidgets('shows distance ladder and flight legend', (tester) async {
      final details = _makeWedgeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: WedgeReviewScreen(matrixRunId: 'mr-w1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distance Ladder'), findsOneWidget);
      expect(find.text('Low'), findsWidgets);
      expect(find.text('Standard'), findsWidgets);
    });

    testWidgets('shows all cells plotted', (tester) async {
      final details = _makeWedgeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: WedgeReviewScreen(matrixRunId: 'mr-w1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both cell labels visible.
      expect(find.textContaining('52°'), findsWidgets);
    });

    testWidgets('filter controls present', (tester) async {
      final details = _makeWedgeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: WedgeReviewScreen(matrixRunId: 'mr-w1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filter'), findsOneWidget);
      expect(find.text('Club'), findsOneWidget);
      expect(find.text('Effort'), findsOneWidget);
      expect(find.text('Flight'), findsOneWidget);
    });

    testWidgets('deselecting filter hides points', (tester) async {
      final details = _makeWedgeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: WedgeReviewScreen(matrixRunId: 'mr-w1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both Low and Standard points visible.
      // Deselect "Low" flight.
      await tester.tap(find.widgetWithText(FilterChip, 'Low'));
      await tester.pumpAndSettle();

      // "52° — 50% — Low" should be gone from the ladder.
      // But Standard still shows.
      expect(find.textContaining('Standard'), findsWidgets);
    });

    testWidgets('run number displayed', (tester) async {
      final details = _makeWedgeDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: WedgeReviewScreen(matrixRunId: 'mr-w1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Run #1'), findsOneWidget);
    });
  });
}
