import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_completion_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

// Phase M5 — MatrixCompletionScreen widget tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRunWithDetails _makeCompletedRunDetails({
  List<String> clubs = const ['7-Iron', '8-Iron'],
  int shotTarget = 3,
}) {
  final run = MatrixRun(
    matrixRunId: 'mr-test',
    userId: 'test-user',
    matrixType: MatrixType.gappingChart,
    runNumber: 1,
    runState: RunState.completed,
    startTimestamp: _ts,
    endTimestamp: _ts.add(const Duration(hours: 1)),
    sessionShotTarget: shotTarget,
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

  final axisValues = clubs
      .asMap()
      .entries
      .map((e) => MatrixAxisValue(
            axisValueId: 'av-${e.key}',
            matrixAxisId: 'ma-test',
            label: e.value,
            sortOrder: e.key + 1,
            createdAt: _ts,
            updatedAt: _ts,
          ))
      .toList();

  final axes = [
    MatrixAxisWithValues(
      axis: MatrixAxis(
        matrixAxisId: 'ma-test',
        matrixRunId: 'mr-test',
        axisType: AxisType.club,
        axisName: 'Club',
        axisOrder: 1,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      values: axisValues,
    ),
  ];

  final cells = clubs.asMap().entries.map((e) {
    final baseCarry = 150.0 + e.key * 10;
    final attempts = List.generate(
      shotTarget,
      (i) => MatrixAttempt(
        matrixAttemptId: 'att-${e.key}-$i',
        matrixCellId: 'mc-${e.key}',
        attemptTimestamp: _ts.add(Duration(minutes: i)),
        carryDistanceMeters: baseCarry + i,
        totalDistanceMeters: baseCarry + 10 + i,
        leftDeviationMeters: null,
        rightDeviationMeters: null,
        rolloutDistanceMeters: null,
        createdAt: _ts,
        updatedAt: _ts,
      ),
    );
    return MatrixCellWithAttempts(
      cell: MatrixCell(
        matrixCellId: 'mc-${e.key}',
        matrixRunId: 'mr-test',
        axisValueIds: '["av-${e.key}"]',
        excludedFromRun: false,
        createdAt: _ts,
        updatedAt: _ts,
      ),
      attempts: attempts,
    );
  }).toList();

  return MatrixRunWithDetails(run: run, axes: axes, cells: cells);
}

void main() {
  group('MatrixCompletionScreen', () {
    testWidgets('shows run complete header', (tester) async {
      final details = _makeCompletedRunDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
            showHomeProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: MatrixCompletionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Run Complete'), findsOneWidget);
      expect(find.text('Run #1'), findsOneWidget);
    });

    testWidgets('shows distance summary table', (tester) async {
      final details = _makeCompletedRunDetails(clubs: ['PW']);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
            showHomeProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: MatrixCompletionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Distance Summary'), findsOneWidget);
      expect(find.text('Club'), findsOneWidget);
      expect(find.text('Carry'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('PW'), findsOneWidget);
    });

    testWidgets('shows snapshot creation section', (tester) async {
      final details = _makeCompletedRunDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
            showHomeProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: MatrixCompletionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save as Performance Snapshot'), findsOneWidget);
      expect(find.text('Save Snapshot'), findsOneWidget);
      expect(find.text('Set as Primary Snapshot'), findsOneWidget);
    });

    testWidgets('shows Done button', (tester) async {
      final details = _makeCompletedRunDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
            showHomeProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: MatrixCompletionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('distance averages computed correctly', (tester) async {
      // 1 club, 3 attempts: carry = 150, 151, 152 → avg = 151.0
      final details = _makeCompletedRunDetails(
        clubs: ['9-Iron'],
        shotTarget: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
            showHomeProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: MatrixCompletionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Average carry of 150, 151, 152 = 151.0
      expect(find.text('151.0'), findsOneWidget);
      // Average total of 160, 161, 162 = 161.0
      expect(find.text('161.0'), findsOneWidget);
    });
  });
}
