import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/review/cell_detail_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

// Phase M9 — Cell detail screen tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRunWithDetails _makeDetailsWithCell() {
  final run = MatrixRun(
    matrixRunId: 'mr-1',
    userId: 'test-user',
    matrixType: MatrixType.gappingChart,
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

  return MatrixRunWithDetails(
    run: run,
    axes: [
      MatrixAxisWithValues(
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
            axisValueId: 'v-7i',
            matrixAxisId: 'ax-1',
            label: '7-Iron',
            sortOrder: 0,
            createdAt: _ts,
            updatedAt: _ts,
          ),
        ],
      ),
    ],
    cells: [
      MatrixCellWithAttempts(
        cell: MatrixCell(
          matrixCellId: 'c-7i',
          matrixRunId: 'mr-1',
          axisValueIds: jsonEncode(['v-7i']),
          excludedFromRun: false,
          createdAt: _ts,
          updatedAt: _ts,
        ),
        attempts: [
          MatrixAttempt(
            matrixAttemptId: 'a-1',
            matrixCellId: 'c-7i',
            attemptTimestamp: _ts,
            carryDistanceMeters: 166,
            totalDistanceMeters: 175,
            leftDeviationMeters: null,
            rightDeviationMeters: null,
            rolloutDistanceMeters: null,
            createdAt: _ts,
            updatedAt: _ts,
          ),
          MatrixAttempt(
            matrixAttemptId: 'a-2',
            matrixCellId: 'c-7i',
            attemptTimestamp: _ts,
            carryDistanceMeters: 168,
            totalDistanceMeters: 177,
            leftDeviationMeters: null,
            rightDeviationMeters: null,
            rolloutDistanceMeters: null,
            createdAt: _ts,
            updatedAt: _ts,
          ),
          MatrixAttempt(
            matrixAttemptId: 'a-3',
            matrixCellId: 'c-7i',
            attemptTimestamp: _ts,
            carryDistanceMeters: 167,
            totalDistanceMeters: 176,
            leftDeviationMeters: null,
            rightDeviationMeters: null,
            rolloutDistanceMeters: null,
            createdAt: _ts,
            updatedAt: _ts,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('CellDetailScreen', () {
    testWidgets('shows attempt list with averages', (tester) async {
      final details = _makeDetailsWithCell();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: CellDetailScreen(
              matrixRunId: 'mr-1',
              cellId: 'c-7i',
              cellLabel: '7-Iron',
              matrixType: MatrixType.gappingChart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cell label in app bar.
      expect(find.text('7-Iron'), findsWidgets);

      // Attempts listed.
      expect(find.text('Attempt 1'), findsOneWidget);
      expect(find.text('Attempt 2'), findsOneWidget);
      expect(find.text('Attempt 3'), findsOneWidget);

      // Averages. Carry avg = (166+168+167)/3 = 167.0.
      expect(find.text('167.0'), findsOneWidget);
      // Total avg = (175+177+176)/3 = 176.0.
      expect(find.text('176.0'), findsOneWidget);
    });

    testWidgets('shows edit and delete buttons', (tester) async {
      final details = _makeDetailsWithCell();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: CellDetailScreen(
              matrixRunId: 'mr-1',
              cellId: 'c-7i',
              cellLabel: '7-Iron',
              matrixType: MatrixType.gappingChart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNWidgets(3));
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });

    testWidgets('shows attempt count', (tester) async {
      final details = _makeDetailsWithCell();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: CellDetailScreen(
              matrixRunId: 'mr-1',
              cellId: 'c-7i',
              cellLabel: '7-Iron',
              matrixType: MatrixType.gappingChart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final details = _makeDetailsWithCell();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: CellDetailScreen(
              matrixRunId: 'mr-1',
              cellId: 'c-7i',
              cellLabel: '7-Iron',
              matrixType: MatrixType.gappingChart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first delete button.
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Attempt'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows no attempts message for empty cell', (tester) async {
      final emptyDetails = MatrixRunWithDetails(
        run: MatrixRun(
          matrixRunId: 'mr-1',
          userId: 'test-user',
          matrixType: MatrixType.gappingChart,
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
        cells: [
          MatrixCellWithAttempts(
            cell: MatrixCell(
              matrixCellId: 'c-empty',
              matrixRunId: 'mr-1',
              axisValueIds: '[]',
              excludedFromRun: false,
              createdAt: _ts,
              updatedAt: _ts,
            ),
            attempts: [],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(emptyDetails),
            ),
          ],
          child: const MaterialApp(
            home: CellDetailScreen(
              matrixRunId: 'mr-1',
              cellId: 'c-empty',
              cellLabel: 'Empty Cell',
              matrixType: MatrixType.gappingChart,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No attempts recorded'), findsOneWidget);
    });
  });
}
