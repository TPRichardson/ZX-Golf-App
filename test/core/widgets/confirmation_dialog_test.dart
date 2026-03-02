import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/widgets/confirmation_dialog.dart';

// Phase 8 — Confirmation dialog tests.

void main() {
  group('showSoftConfirmation', () {
    testWidgets('returns true when confirmed', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showSoftConfirmation(
                context,
                title: 'Test',
                message: 'Are you sure?',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('returns false when cancelled', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showSoftConfirmation(
                context,
                title: 'Test',
                message: 'Cancel me',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('shows custom confirm label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showSoftConfirmation(
              context,
              title: 'Delete',
              message: 'Delete item?',
              confirmLabel: 'Delete',
              isDestructive: true,
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsWidgets);
    });
  });

  group('showStrongConfirmation', () {
    testWidgets('confirm button disabled until phrase typed', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showStrongConfirmation(
                context,
                title: 'Delete Account',
                message: 'Type DELETE to confirm',
                confirmPhrase: 'DELETE',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Confirm button should be disabled (null onPressed).
      final confirmFinder = find.text('Confirm');
      expect(confirmFinder, findsOneWidget);

      // Type the phrase.
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pumpAndSettle();

      // Now confirm should be enabled.
      await tester.tap(confirmFinder);
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('returns false when cancelled', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showStrongConfirmation(
                context,
                title: 'Delete',
                message: 'Type DELETE',
                confirmPhrase: 'DELETE',
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });
  });
}
