import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/chipping_review_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

// Phase M9 — Chipping review screen tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRunWithDetails _makeChippingDetails() {
  final run = MatrixRun(
    matrixRunId: 'mr-c1',
    userId: 'test-user',
    matrixType: MatrixType.chippingMatrix,
    runNumber: 2,
    runState: RunState.completed,
    startTimestamp: _ts,
    endTimestamp: _ts.add(const Duration(hours: 1)),
    sessionShotTarget: 3,
    shotOrderMode: ShotOrderMode.topToBottom,
    dispersionCaptureEnabled: false,
    measurementDevice: null,
    environmentType: null,
    surfaceType: null,
    greenSpeed: 10,
    greenFirmness: GreenFirmness.medium,
    isDeleted: false,
    createdAt: _ts,
    updatedAt: _ts,
  );

  final clubAxis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-club',
      matrixRunId: 'mr-c1',
      axisType: AxisType.club,
      axisName: 'Club',
      axisOrder: 0,
      createdAt: _ts,
      updatedAt: _ts,
    ),
    values: [
      MatrixAxisValue(
        axisValueId: 'v-sw',
        matrixAxisId: 'ax-club',
        label: 'SW',
        sortOrder: 0,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    ],
  );

  final distAxis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-dist',
      matrixRunId: 'mr-c1',
      axisType: AxisType.carryDistance,
      axisName: 'Target',
      axisOrder: 1,
      createdAt: _ts,
      updatedAt: _ts,
    ),
    values: [
      MatrixAxisValue(
        axisValueId: 'v-10',
        matrixAxisId: 'ax-dist',
        label: '10',
        sortOrder: 0,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    ],
  );

  final flightAxis = MatrixAxisWithValues(
    axis: MatrixAxis(
      matrixAxisId: 'ax-flight',
      matrixRunId: 'mr-c1',
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
    ],
  );

  // SW — 10 — Low cell with 3 attempts.
  // Target 10. Carry: 9.5, 10.2, 9.8. Rollout: 3.0, 3.5, 3.2.
  final cells = [
    MatrixCellWithAttempts(
      cell: MatrixCell(
        matrixCellId: 'c-1',
        matrixRunId: 'mr-c1',
        axisValueIds: jsonEncode(['v-sw', 'v-10', 'v-low']),
        excludedFromRun: false,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      attempts: [
        MatrixAttempt(
          matrixAttemptId: 'a-1',
          matrixCellId: 'c-1',
          attemptTimestamp: _ts,
          carryDistanceMeters: 9.5,
          totalDistanceMeters: 12.5,
          leftDeviationMeters: null,
          rightDeviationMeters: null,
          rolloutDistanceMeters: 3.0,
          createdAt: _ts,
          updatedAt: _ts,
        ),
        MatrixAttempt(
          matrixAttemptId: 'a-2',
          matrixCellId: 'c-1',
          attemptTimestamp: _ts,
          carryDistanceMeters: 10.2,
          totalDistanceMeters: 13.7,
          leftDeviationMeters: null,
          rightDeviationMeters: null,
          rolloutDistanceMeters: 3.5,
          createdAt: _ts,
          updatedAt: _ts,
        ),
        MatrixAttempt(
          matrixAttemptId: 'a-3',
          matrixCellId: 'c-1',
          attemptTimestamp: _ts,
          carryDistanceMeters: 9.8,
          totalDistanceMeters: 13.0,
          leftDeviationMeters: null,
          rightDeviationMeters: null,
          rolloutDistanceMeters: 3.2,
          createdAt: _ts,
          updatedAt: _ts,
        ),
      ],
    ),
  ];

  return MatrixRunWithDetails(
    run: run,
    axes: [clubAxis, distAxis, flightAxis],
    cells: cells,
  );
}

void main() {
  group('ChippingReviewScreen', () {
    testWidgets('shows accuracy overview', (tester) async {
      final details = _makeChippingDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: ChippingReviewScreen(matrixRunId: 'mr-c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distance Accuracy Overview'), findsOneWidget);
      expect(find.text('Run #2'), findsOneWidget);
    });

    testWidgets('shows club section collapsed by default', (tester) async {
      final details = _makeChippingDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: ChippingReviewScreen(matrixRunId: 'mr-c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Club name visible.
      expect(find.text('SW'), findsOneWidget);
      // Collapsed arrow.
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
      // Accuracy metrics not visible yet (collapsed).
      expect(find.text('Avg Carry'), findsNothing);
    });

    testWidgets('expands club section on tap', (tester) async {
      final details = _makeChippingDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: ChippingReviewScreen(matrixRunId: 'mr-c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to expand.
      await tester.tap(find.text('SW'));
      await tester.pumpAndSettle();

      // Expanded arrow.
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      // Now shows accuracy metrics.
      expect(find.text('Avg Carry'), findsWidgets);
      expect(find.text('Avg Error'), findsWidgets);
    });

    testWidgets('shows short bias percentage', (tester) async {
      final details = _makeChippingDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: ChippingReviewScreen(matrixRunId: 'mr-c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expand to see short bias.
      await tester.tap(find.text('SW'));
      await tester.pumpAndSettle();

      // 2 out of 3 attempts are short (9.5, 9.8 < 10) = 67%.
      expect(find.text('67%'), findsWidgets);
    });

    testWidgets('shows distance target in overview', (tester) async {
      final details = _makeChippingDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: ChippingReviewScreen(matrixRunId: 'mr-c1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Target distance "10" visible in overview.
      expect(find.text('10'), findsWidgets);
    });

    testWidgets('shows no data for empty run', (tester) async {
      final emptyDetails = MatrixRunWithDetails(
        run: MatrixRun(
          matrixRunId: 'mr-empty',
          userId: 'test-user',
          matrixType: MatrixType.chippingMatrix,
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
        ),
        axes: [],
        cells: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(emptyDetails),
            ),
          ],
          child: const MaterialApp(
            home: ChippingReviewScreen(matrixRunId: 'mr-empty'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data recorded'), findsOneWidget);
    });
  });
}
