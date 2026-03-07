import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/matrix/screens/matrix_setup_screen.dart';
import 'package:zx_golf_app/providers/bag_providers.dart';

// Phase M5 — GappingSetupScreen widget tests.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);

UserClub _makeClub(String id, ClubType type) => UserClub(
      clubId: id,
      userId: 'test-user',
      clubType: type,
      make: 'Titleist',
      model: 'T200',
      loft: 34.0,
      status: UserClubStatus.active,
      createdAt: _ts,
      updatedAt: _ts,
    );

void main() {
  group('GappingSetupScreen', () {
    testWidgets('renders club list from bag', (tester) async {
      final clubs = [
        _makeClub('c1', ClubType.i7),
        _makeClub('c2', ClubType.i8),
        _makeClub('c3', ClubType.i9),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBagProvider.overrideWith(
              (ref, userId) => Stream.value(clubs),
            ),
          ],
          child: const MaterialApp(
            home: MatrixSetupScreen(userId: 'test-user', matrixType: MatrixType.gappingChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Clubs'), findsOneWidget);
      expect(find.text('i7'), findsOneWidget);
      expect(find.text('i8'), findsOneWidget);
      expect(find.text('i9'), findsOneWidget);
    });

    testWidgets('start button disabled when no clubs selected',
        (tester) async {
      final clubs = [_makeClub('c1', ClubType.i7)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBagProvider.overrideWith(
              (ref, userId) => Stream.value(clubs),
            ),
          ],
          child: const MaterialApp(
            home: MatrixSetupScreen(userId: 'test-user', matrixType: MatrixType.gappingChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Start button — should be disabled.
      final button = find.widgetWithText(FilledButton, 'Start Gapping (0 clubs)');
      expect(button, findsOneWidget);
      final buttonWidget = tester.widget<FilledButton>(button);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('Select All selects all clubs', (tester) async {
      final clubs = [
        _makeClub('c1', ClubType.i7),
        _makeClub('c2', ClubType.i8),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBagProvider.overrideWith(
              (ref, userId) => Stream.value(clubs),
            ),
          ],
          child: const MaterialApp(
            home: MatrixSetupScreen(userId: 'test-user', matrixType: MatrixType.gappingChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      // Button text should show 2 clubs.
      expect(find.textContaining('2 clubs'), findsOneWidget);
    });

    testWidgets('empty bag shows placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBagProvider.overrideWith(
              (ref, userId) => Stream.value(<UserClub>[]),
            ),
          ],
          child: const MaterialApp(
            home: MatrixSetupScreen(userId: 'test-user', matrixType: MatrixType.gappingChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No clubs in bag'), findsOneWidget);
    });

    testWidgets('shows shot target input', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBagProvider.overrideWith(
              (ref, userId) => Stream.value(<UserClub>[]),
            ),
          ],
          child: const MaterialApp(
            home: MatrixSetupScreen(userId: 'test-user', matrixType: MatrixType.gappingChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shots Per Club'), findsOneWidget);
      // Default value should be 5.
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows environment picker', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userBagProvider.overrideWith(
              (ref, userId) => Stream.value(<UserClub>[]),
            ),
          ],
          child: const MaterialApp(
            home: MatrixSetupScreen(userId: 'test-user', matrixType: MatrixType.gappingChart),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Environment'), findsOneWidget);
      expect(find.text('Not set'), findsOneWidget);
    });
  });
}
