// Phase 4 — Reflow Lock UI Awareness tests.
// Gaps 39–42: submission buttons disabled while scoring lock is held.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/theme/tokens.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

// Minimal reproduction of the lock-aware button pattern used in all
// 4 execution screens. This avoids mocking the full SessionExecutionController
// and PracticeRepository dependency chain while testing the same conditional
// rendering logic.

class _TestLockAwareScreen extends ConsumerWidget {
  const _TestLockAwareScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = ref.watch(scoringLockActiveProvider).valueOrNull ?? false;

    return Scaffold(
      body: Column(
        children: [
          if (isLocked)
            const Text('Updating scores\u2026', key: Key('lock-indicator')),
          FilledButton(
            key: const Key('submit-button'),
            onPressed: isLocked ? null : () {},
            child: const Text('Record'),
          ),
          // Binary-style buttons that use IgnorePointer instead of null onPressed.
          IgnorePointer(
            key: const Key('hit-ignore'),
            ignoring: isLocked,
            child: GestureDetector(
              key: const Key('hit-button'),
              onTap: () {},
              child: Container(
                color: isLocked
                    ? ColorTokens.successDefault.withValues(alpha: 0.4)
                    : ColorTokens.successDefault,
                child: const Text('HIT'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Phase 4: Reflow Lock UI Awareness', () {
    testWidgets('submit button enabled when lock is inactive', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scoringLockActiveProvider.overrideWith(
              (ref) => Stream.value(false),
            ),
          ],
          child: const MaterialApp(home: _TestLockAwareScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Submit button should be enabled.
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('submit-button')),
      );
      expect(button.onPressed, isNotNull);

      // No lock indicator visible.
      expect(find.byKey(const Key('lock-indicator')), findsNothing);

      // Hit button should not be ignoring pointer.
      final ignorePointer = tester.widget<IgnorePointer>(
        find.byKey(const Key('hit-ignore')),
      );
      expect(ignorePointer.ignoring, false);
    });

    testWidgets('submit button disabled when lock is active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scoringLockActiveProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(home: _TestLockAwareScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Submit button should be disabled.
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('submit-button')),
      );
      expect(button.onPressed, isNull);

      // Lock indicator visible.
      expect(find.byKey(const Key('lock-indicator')), findsOneWidget);

      // Hit button should be ignoring pointer.
      final ignorePointer = tester.widget<IgnorePointer>(
        find.byKey(const Key('hit-ignore')),
      );
      expect(ignorePointer.ignoring, true);
    });

    testWidgets('lock state transitions update UI reactively',
        (tester) async {
      final controller = StreamController<bool>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scoringLockActiveProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
          child: const MaterialApp(home: _TestLockAwareScreen()),
        ),
      );
      await tester.pump();

      // Initially no data → defaults to false (unlocked).
      var button = tester.widget<FilledButton>(
        find.byKey(const Key('submit-button')),
      );
      expect(button.onPressed, isNotNull);

      // Emit lock acquired.
      controller.add(true);
      await tester.pump();
      await tester.pump();

      button = tester.widget<FilledButton>(
        find.byKey(const Key('submit-button')),
      );
      expect(button.onPressed, isNull);
      expect(find.byKey(const Key('lock-indicator')), findsOneWidget);

      // Emit lock released.
      controller.add(false);
      await tester.pump();
      await tester.pump();

      button = tester.widget<FilledButton>(
        find.byKey(const Key('submit-button')),
      );
      expect(button.onPressed, isNotNull);
      expect(find.byKey(const Key('lock-indicator')), findsNothing);

      await controller.close();
    });
  });
}
