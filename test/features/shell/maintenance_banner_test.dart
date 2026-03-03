// Phase 4 — SystemMaintenanceBanner tests.
// Gap 43: banner shown when systemMaintenanceActiveProvider is true.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/features/shell/widgets/system_maintenance_banner.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

void main() {
  group('Phase 4: SystemMaintenanceBanner', () {
    testWidgets('hidden when systemMaintenanceActiveProvider is false',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            systemMaintenanceActiveProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SystemMaintenanceBanner()),
          ),
        ),
      );
      await tester.pump();

      // Banner should render as SizedBox.shrink (no visible content).
      expect(find.textContaining('Scores are being updated'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shown when systemMaintenanceActiveProvider is true',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            systemMaintenanceActiveProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SystemMaintenanceBanner()),
          ),
        ),
      );
      // Use pump() instead of pumpAndSettle() — CircularProgressIndicator
      // animates indefinitely and never settles.
      await tester.pump();

      expect(
        find.textContaining('Scores are being updated'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
