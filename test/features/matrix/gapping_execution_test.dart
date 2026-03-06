import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/matrix_repository.dart';
import 'package:zx_golf_app/features/matrix/screens/gapping_execution_screen.dart';
import 'package:zx_golf_app/features/matrix/widgets/matrix_execution_header.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

// Phase M5 — GappingExecutionScreen widget tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRunWithDetails _makeRunDetails({
  int shotTarget = 3,
  List<String> clubs = const ['7-Iron', '8-Iron'],
  List<List<MatrixAttempt>> cellAttempts = const [],
}) {
  final run = MatrixRun(
    matrixRunId: 'mr-test',
    userId: 'test-user',
    matrixType: MatrixType.gappingChart,
    runNumber: 1,
    runState: RunState.inProgress,
    startTimestamp: _ts,
    endTimestamp: null,
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
    final attempts =
        e.key < cellAttempts.length ? cellAttempts[e.key] : <MatrixAttempt>[];
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

MatrixAttempt _makeAttempt(int index, {double carry = 150.0}) => MatrixAttempt(
      matrixAttemptId: 'att-$index',
      matrixCellId: 'mc-0',
      attemptTimestamp: _ts,
      carryDistanceMeters: carry,
      totalDistanceMeters: carry + 10,
      leftDeviationMeters: null,
      rightDeviationMeters: null,
      rolloutDistanceMeters: null,
      createdAt: _ts,
      updatedAt: _ts,
    );

void main() {
  group('GappingExecutionScreen', () {
    testWidgets('renders header with run info', (tester) async {
      final details = _makeRunDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MatrixExecutionHeader), findsOneWidget);
      expect(find.textContaining('Gapping Chart'), findsOneWidget);
      expect(find.text('7-Iron'), findsOneWidget);
    });

    testWidgets('shows carry distance input field', (tester) async {
      final details = _makeRunDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carry Distance'), findsOneWidget);
      expect(find.text('Total Distance (Optional)'), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
    });

    testWidgets('shows recorded attempts', (tester) async {
      final attempts = [
        _makeAttempt(0, carry: 145.0),
        _makeAttempt(1, carry: 150.0),
      ];
      final details = _makeRunDetails(cellAttempts: [attempts]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('145.0'), findsOneWidget);
      expect(find.text('150.0'), findsOneWidget);
    });

    testWidgets('shows cell complete when shot target met', (tester) async {
      final attempts = List.generate(3, (i) => _makeAttempt(i));
      final details = _makeRunDetails(
        shotTarget: 3,
        clubs: ['7-Iron'],
        cellAttempts: [attempts],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Complete'), findsWidgets);
    });

    testWidgets('complete button disabled when not all cells done',
        (tester) async {
      final details = _makeRunDetails(); // No attempts = not complete.

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final completeButton =
          find.widgetWithText(FilledButton, 'Complete');
      expect(completeButton, findsOneWidget);
      final widget = tester.widget<FilledButton>(completeButton);
      expect(widget.onPressed, isNull);
    });

    testWidgets('discard button always visible', (tester) async {
      final details = _makeRunDetails();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('cell list toggle shows all cells', (tester) async {
      final details = _makeRunDetails(clubs: ['7-Iron', '8-Iron', '9-Iron']);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(details),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the list toggle button.
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();

      // All clubs should be visible in the cell list.
      // 7-Iron appears in header too, so use findsWidgets.
      expect(find.text('7-Iron'), findsWidgets);
      expect(find.text('8-Iron'), findsOneWidget);
      expect(find.text('9-Iron'), findsOneWidget);
    });

    testWidgets('null details shows not found', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunDetailsProvider.overrideWith(
              (ref, runId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(
            home: GappingExecutionScreen(
              matrixRunId: 'mr-test',
              userId: 'test-user',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Run not found'), findsOneWidget);
    });
  });
}
