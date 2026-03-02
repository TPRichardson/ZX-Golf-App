import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/widgets/achievement_banner.dart';

// Phase 8 — Achievement banner tests.

void main() {
  group('AchievementBanner', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AchievementBanner(message: 'First session completed'),
        ),
      ));

      expect(find.text('First session completed'), findsOneWidget);

      // Pump past the 3s auto-dismiss + fade out to avoid pending timer.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('contains FadeTransition', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AchievementBanner(message: 'Test'),
        ),
      ));

      // Scope to the AchievementBanner subtree to avoid matching
      // FadeTransitions from MaterialPageRoute.
      final bannerFade = find.descendant(
        of: find.byType(AchievementBanner),
        matching: find.byType(FadeTransition),
      );
      expect(bannerFade, findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('calls onDismissed after auto-dismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AchievementBanner(
            message: 'Test',
            onDismissed: () => dismissed = true,
          ),
        ),
      ));

      // Before auto-dismiss.
      expect(dismissed, false);

      // Pump past the 3s auto-dismiss + slow fade out (200ms) + buffer.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });

    testWidgets('fade in animation starts at low opacity', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AchievementBanner(message: 'Test'),
        ),
      ));

      // Scope to AchievementBanner subtree.
      final bannerFadeFinder = find.descendant(
        of: find.byType(AchievementBanner),
        matching: find.byType(FadeTransition),
      );

      // At frame 0 the animation is at its initial value.
      final fade = tester.widget<FadeTransition>(bannerFadeFinder);
      expect(fade.opacity.value, lessThan(0.5));

      // After pumping the entry duration, should reach ~1.0.
      await tester.pump(const Duration(milliseconds: 150));
      expect(fade.opacity.value, closeTo(1.0, 0.15));

      // Clean up.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('message text is visible', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AchievementBanner(message: 'First routine applied'),
        ),
      ));

      final textFinder = find.text('First routine applied');
      expect(textFinder, findsOneWidget);

      // Clean up timer.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });
}
