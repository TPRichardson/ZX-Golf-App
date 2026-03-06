import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/review/screens/matrix_review_screen.dart';
import 'package:zx_golf_app/providers/matrix_providers.dart';

// Phase M8 — MatrixReviewScreen widget tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

MatrixRun _makeRun({
  String id = 'mr-1',
  int runNumber = 1,
  MatrixType type = MatrixType.gappingChart,
  RunState state = RunState.completed,
}) =>
    MatrixRun(
      matrixRunId: id,
      userId: 'test-user',
      matrixType: type,
      runNumber: runNumber,
      runState: state,
      startTimestamp: _ts,
      endTimestamp: state == RunState.completed
          ? _ts.add(const Duration(hours: 1))
          : null,
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

PerformanceSnapshot _makeSnapshot({
  bool isPrimary = true,
  String? label,
}) =>
    PerformanceSnapshot(
      snapshotId: 'ps-1',
      userId: 'test-user',
      matrixRunId: 'mr-1',
      matrixType: MatrixType.gappingChart,
      isPrimary: isPrimary,
      label: label ?? 'Test snapshot',
      snapshotTimestamp: _ts,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

void main() {
  group('MatrixReviewScreen', () {
    testWidgets('shows zero state when no runs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunsProvider.overrideWith(
              (ref, userId) => Stream.value(<MatrixRun>[]),
            ),
            snapshotsProvider.overrideWith(
              (ref, userId) =>
                  Stream.value(<PerformanceSnapshot>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MatrixReviewScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No matrix runs yet'), findsOneWidget);
    });

    testWidgets('shows completed run card', (tester) async {
      final runs = [_makeRun()];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunsProvider.overrideWith(
              (ref, userId) => Stream.value(runs),
            ),
            snapshotsProvider.overrideWith(
              (ref, userId) =>
                  Stream.value(<PerformanceSnapshot>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MatrixReviewScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gapping Chart #1'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('shows primary snapshot banner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunsProvider.overrideWith(
              (ref, userId) => Stream.value(<MatrixRun>[]),
            ),
            snapshotsProvider.overrideWith(
              (ref, userId) =>
                  Stream.value([_makeSnapshot(label: 'March gapping')]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MatrixReviewScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('March gapping'), findsOneWidget);
    });

    testWidgets('filter chips filter by matrix type', (tester) async {
      final runs = [
        _makeRun(id: 'mr-1', type: MatrixType.gappingChart),
        _makeRun(
            id: 'mr-2', runNumber: 2, type: MatrixType.wedgeMatrix),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunsProvider.overrideWith(
              (ref, userId) => Stream.value(runs),
            ),
            snapshotsProvider.overrideWith(
              (ref, userId) =>
                  Stream.value(<PerformanceSnapshot>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MatrixReviewScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both runs visible initially.
      expect(find.text('Gapping Chart #1'), findsOneWidget);
      expect(find.text('Wedge Matrix #2'), findsOneWidget);

      // Filter to Gapping only.
      await tester.tap(find.text('Gapping'));
      await tester.pumpAndSettle();

      expect(find.text('Gapping Chart #1'), findsOneWidget);
      expect(find.text('Wedge Matrix #2'), findsNothing);
    });

    testWidgets('shows multiple run types', (tester) async {
      final runs = [
        _makeRun(id: 'mr-1', type: MatrixType.gappingChart),
        _makeRun(
            id: 'mr-2',
            runNumber: 1,
            type: MatrixType.chippingMatrix),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matrixRunsProvider.overrideWith(
              (ref, userId) => Stream.value(runs),
            ),
            snapshotsProvider.overrideWith(
              (ref, userId) =>
                  Stream.value(<PerformanceSnapshot>[]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: MatrixReviewScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gapping Chart #1'), findsOneWidget);
      expect(find.text('Chipping Matrix #1'), findsOneWidget);
    });
  });
}
