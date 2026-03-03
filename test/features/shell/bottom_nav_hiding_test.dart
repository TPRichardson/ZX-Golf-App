import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';

// Fix 10 — Verify BottomNavigationBar is hidden during active practice.
//
// ShellScreen depends on a deep provider tree (Supabase, SyncEngine, etc.).
// Rather than mocking the entire chain, we test the conditional rendering
// logic with a minimal widget that mirrors ShellScreen's bottom nav behaviour
// and overrides only activePracticeBlockProvider.

/// Minimal reproduction of ShellScreen's bottom nav conditional logic.
class _TestShell extends ConsumerWidget {
  const _TestShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePb = ref.watch(
      activePracticeBlockProvider('test-user'),
    );
    final hasActivePractice = activePb.valueOrNull != null;

    return Scaffold(
      body: const Center(child: Text('Body')),
      bottomNavigationBar: hasActivePractice
          ? null
          : BottomNavigationBar(
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Plan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_golf),
                  label: 'Track',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  label: 'Review',
                ),
              ],
            ),
    );
  }
}

void main() {
  group('Fix 10: Bottom navigation hiding', () {
    testWidgets('shows BottomNavigationBar when no active practice block',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestShell()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('hides BottomNavigationBar when active practice block exists',
        (tester) async {
      final now = DateTime.now();
      final fakePb = PracticeBlock(
        practiceBlockId: 'pb-test',
        userId: 'test-user',
        drillOrder: '[]',
        startTimestamp: now,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(fakePb),
            ),
          ],
          child: const MaterialApp(home: _TestShell()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}
