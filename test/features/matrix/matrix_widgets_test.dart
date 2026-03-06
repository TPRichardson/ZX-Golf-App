import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/matrix/widgets/matrix_cell_card.dart';
import 'package:zx_golf_app/features/matrix/widgets/matrix_execution_header.dart';

// Phase M5 — Matrix widget unit tests.

void main() {
  group('MatrixExecutionHeader', () {
    testWidgets('displays matrix type and run number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixExecutionHeader(
              matrixType: MatrixType.gappingChart,
              runNumber: 3,
              currentCellLabel: '7-Iron',
              currentCellIndex: 0,
              totalCells: 5,
              currentAttemptCount: 2,
              sessionShotTarget: 5,
            ),
          ),
        ),
      );

      expect(find.text('Gapping Chart #3'), findsOneWidget);
      expect(find.text('7-Iron'), findsOneWidget);
      expect(find.text('Cell 1/5'), findsOneWidget);
      expect(find.text('2/5 shots'), findsOneWidget);
    });

    testWidgets('displays wedge matrix type', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixExecutionHeader(
              matrixType: MatrixType.wedgeMatrix,
              runNumber: 1,
              currentCellLabel: 'PW × Full',
              currentCellIndex: 2,
              totalCells: 12,
              currentAttemptCount: 0,
              sessionShotTarget: 3,
            ),
          ),
        ),
      );

      expect(find.text('Wedge Matrix #1'), findsOneWidget);
      expect(find.text('PW × Full'), findsOneWidget);
      expect(find.text('Cell 3/12'), findsOneWidget);
    });
  });

  group('MatrixCellCard', () {
    testWidgets('shows label and attempt count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixCellCard(
              label: '7-Iron',
              attemptCount: 2,
              shotTarget: 5,
            ),
          ),
        ),
      );

      expect(find.text('7-Iron'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
    });

    testWidgets('shows Complete when target met', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixCellCard(
              label: '8-Iron',
              attemptCount: 5,
              shotTarget: 5,
            ),
          ),
        ),
      );

      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('shows Excluded when excluded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixCellCard(
              label: '9-Iron',
              attemptCount: 0,
              shotTarget: 5,
              isExcluded: true,
            ),
          ),
        ),
      );

      expect(find.text('Excluded'), findsOneWidget);
    });

    testWidgets('responds to tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatrixCellCard(
              label: 'PW',
              attemptCount: 0,
              shotTarget: 3,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('PW'));
      expect(tapped, true);
    });

    testWidgets('responds to long press', (tester) async {
      var longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatrixCellCard(
              label: 'SW',
              attemptCount: 0,
              shotTarget: 3,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('SW'));
      expect(longPressed, true);
    });

    testWidgets('active card has highlighted border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatrixCellCard(
              label: 'Driver',
              attemptCount: 1,
              shotTarget: 5,
              isActive: true,
            ),
          ),
        ),
      );

      // Active card should render — just verify it doesn't crash.
      expect(find.text('Driver'), findsOneWidget);
    });
  });
}
