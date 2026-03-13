import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/practice/screens/post_session_summary_screen.dart';

// Fix 11 — Verify that Done/Close in PostSessionSummaryScreen routes back
// to the first route (Home), not just one pop.

void main() {
  final now = DateTime.now();

  final fakeDrill = Drill(
    drillId: 'drill-exit-test',
    name: 'Exit Route Drill',
    skillArea: SkillArea.putting,
    drillType: DrillType.transition,
    inputMode: InputMode.binaryHitMiss,
    metricSchemaId: 'grid_1x3_direction',
    subskillMapping: '["putting_direction_control"]',
    requiredSetCount: 1,
    anchors: '{}',
    origin: DrillOrigin.standard,
    status: DrillStatus.active,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );

  final fakeSession = Session(
    sessionId: 'session-exit-test',
    drillId: 'drill-exit-test',
    practiceBlockId: 'pb-exit-test',
    status: SessionStatus.closed,
    integrityFlag: false,
    integritySuppressed: false,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );

  group('Fix 11: Exit routing to Home', () {
    testWidgets('Practice Overview button pops one route', (tester) async {
      // Build nav stack: Home → Intermediate → PostSessionSummary.
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                // Push an intermediate route, then the summary screen.
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: Builder(
                      builder: (ctx2) => ElevatedButton(
                        key: const Key('push-summary'),
                        onPressed: () {
                          Navigator.of(ctx2).push(MaterialPageRoute(
                            builder: (_) => PostSessionSummaryScreen(
                              drill: fakeDrill,
                              session: fakeSession,
                              sessionScore: 3.5,
                            ),
                          ));
                        },
                        child: const Text('Push Summary'),
                      ),
                    ),
                  ),
                ));
              },
              child: const Text('Go Intermediate'),
            ),
          ),
        ),
      )));

      // Navigate: Home → Intermediate.
      await tester.tap(find.text('Go Intermediate'));
      await tester.pumpAndSettle();

      // Navigate: Intermediate → PostSessionSummary.
      await tester.tap(find.byKey(const Key('push-summary')));
      await tester.pumpAndSettle();

      // Verify we're on the summary screen.
      expect(find.text('Session Complete'), findsOneWidget);
      expect(find.text('Practice Overview'), findsOneWidget);

      // Tap Practice Overview — should pop back one route to Intermediate.
      await tester.tap(find.text('Practice Overview'));
      await tester.pumpAndSettle();

      // Verify we're at the Intermediate screen (not Home).
      expect(find.text('Push Summary'), findsOneWidget);
      expect(find.text('Session Complete'), findsNothing);
    });

    testWidgets('Close (X) button pops to first route', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PostSessionSummaryScreen(
                    drill: fakeDrill,
                    session: fakeSession,
                    sessionScore: 4.0,
                  ),
                ));
              },
              child: const Text('Go Summary'),
            ),
          ),
        ),
      )));

      // Navigate: Home → PostSessionSummary.
      await tester.tap(find.text('Go Summary'));
      await tester.pumpAndSettle();

      expect(find.text('Session Complete'), findsOneWidget);

      // Tap close (X) icon button.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Back at Home.
      expect(find.text('Go Summary'), findsOneWidget);
      expect(find.text('Session Complete'), findsNothing);
    });
  });
}
