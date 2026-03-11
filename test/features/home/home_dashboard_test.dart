import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';
import 'package:zx_golf_app/providers/planning_providers.dart';
import 'package:zx_golf_app/providers/practice_providers.dart';
import 'package:zx_golf_app/providers/scoring_providers.dart';

// S12 §12.2 — Home Dashboard tests.
//
// HomeDashboardScreen has deep provider dependencies (database, repositories,
// sync engine). Rather than mocking the entire chain, we test:
// 1. Pure business logic (slot parsing, drill ID extraction).
// 2. Minimal reproduction widgets for rendering conditions.
// 3. showHomeProvider state transitions.

/// Minimal widget that mirrors HomeDashboardScreen's core rendering logic.
class _TestHomeDashboard extends ConsumerWidget {
  const _TestHomeDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overallAsync = ref.watch(overallScoreProvider('test-user'));
    final todayAsync = ref.watch(todayCalendarDayProvider('test-user'));
    final activePb = ref.watch(activePracticeBlockProvider('test-user'));
    final hasActivePb = activePb.valueOrNull != null;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Score section.
            overallAsync.when(
              data: (overall) => overall != null
                  ? Text('Score: ${overall.overallScore.round()}')
                  : const Text('No score'),
              loading: () => const Text('No score'),
              error: (_, _) => const Text('No score'),
            ),
            // Slot summary section.
            todayAsync.when(
              data: (day) {
                if (day == null) return const Text('Slots: 0 / 0 drills');
                final slots = parseSlotsFromJson(day.slots);
                final filled = slots.where((s) => s.isFilled).length;
                final completed = slots.where((s) => s.isCompleted).length;
                return Text('Slots: $completed / $filled drills');
              },
              loading: () => const Text('Slots: 0 / 0 drills'),
              error: (_, _) => const Text('Slots: 0 / 0 drills'),
            ),
            // Action buttons.
            if (hasActivePb)
              const FilledButton(
                onPressed: null,
                child: Text('Resume Practice'),
              ),
            if (!hasActivePb)
              todayAsync.when(
                data: (day) {
                  if (day == null) return const SizedBox.shrink();
                  final slots = parseSlotsFromJson(day.slots);
                  final filledDrillIds = slots
                      .where((s) => s.isFilled && !s.isCompleted)
                      .map((s) => s.drillId!)
                      .toList();
                  if (filledDrillIds.isNotEmpty) {
                    return FilledButton(
                      onPressed: () {},
                      child: Text(
                        'Start Today\'s Practice (${filledDrillIds.length} drills)',
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            if (!hasActivePb)
              const OutlinedButton(
                onPressed: null,
                child: Text('Start Clean Practice'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Minimal widget that mirrors ShellScreen's Home/Tab switching logic.
class _TestShellWithHome extends ConsumerWidget {
  const _TestShellWithHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHome = ref.watch(showHomeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZX Golf'),
        leading: showHome
            ? null
            : IconButton(
                icon: const Icon(Icons.home),
                onPressed: () =>
                    ref.read(showHomeProvider.notifier).state = true,
              ),
        actions: [
          if (showHome)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
        ],
      ),
      body: showHome
          ? const Center(child: Text('Home Dashboard'))
          : const Center(child: Text('Tab Content')),
      bottomNavigationBar: showHome
          ? null
          : BottomNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
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

DateTime _now() => DateTime.now();

CalendarDay _makeCalendarDay(String slotsJson) {
  final now = _now();
  return CalendarDay(
    calendarDayId: 'cd-1',
    userId: 'test-user',
    date: now,
    slotCapacity: 5,
    slots: slotsJson,
    createdAt: now,
    updatedAt: now,
  );
}

MaterialisedOverallScore _makeOverallScore(double score) {
  return MaterialisedOverallScore(
    userId: 'test-user',
    overallScore: score,
  );
}

PracticeBlock _makePracticeBlock() {
  final now = _now();
  return PracticeBlock(
    practiceBlockId: 'pb-test',
    userId: 'test-user',
    drillOrder: '[]',
    startTimestamp: now,
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Home Dashboard rendering', () {
    testWidgets('renders score and slot summary', (tester) async {
      final slotsJson = jsonEncode([
        const Slot(drillId: 'drill-a').toJson(),
        const Slot(
          drillId: 'drill-b',
          completionState: CompletionState.completedLinked,
        ).toJson(),
        const Slot().toJson(),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(_makeOverallScore(750)),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay(slotsJson)),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Score: 750'), findsOneWidget);
      expect(find.text('Slots: 1 / 2 drills'), findsOneWidget);
    });

    testWidgets('shows zero state when no score data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay('[]')),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No score'), findsOneWidget);
      expect(find.text('Slots: 0 / 0 drills'), findsOneWidget);
    });
  });

  group('Start Today\'s Practice visibility', () {
    testWidgets('visible when filled incomplete slots exist', (tester) async {
      final slotsJson = jsonEncode([
        const Slot(drillId: 'drill-a').toJson(),
        const Slot(drillId: 'drill-b').toJson(),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay(slotsJson)),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Start Today\'s Practice (2 drills)'),
        findsOneWidget,
      );
    });

    testWidgets('hidden when no filled slots', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay('[]')),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Start Today\'s Practice'), findsNothing);
    });

    testWidgets('hidden when all filled slots are completed', (tester) async {
      final slotsJson = jsonEncode([
        const Slot(
          drillId: 'drill-a',
          completionState: CompletionState.completedLinked,
        ).toJson(),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay(slotsJson)),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Start Today\'s Practice'), findsNothing);
    });
  });

  group('Start Clean Practice visibility', () {
    testWidgets('always visible when no active PB', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay('[]')),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start Clean Practice'), findsOneWidget);
    });

    testWidgets('hidden when active PB exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay('[]')),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(_makePracticeBlock()),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start Clean Practice'), findsNothing);
    });
  });

  group('Resume Practice visibility', () {
    testWidgets('shows Resume when active PB exists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            overallScoreProvider.overrideWith(
              (ref, userId) => Stream.value(null),
            ),
            todayCalendarDayProvider.overrideWith(
              (ref, userId) => Stream.value(_makeCalendarDay('[]')),
            ),
            activePracticeBlockProvider.overrideWith(
              (ref, userId) => Stream.value(_makePracticeBlock()),
            ),
          ],
          child: const MaterialApp(home: _TestHomeDashboard()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Resume Practice'), findsOneWidget);
    });
  });

  group('Home/Tab navigation', () {
    testWidgets('defaults to Home Dashboard on launch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(home: _TestShellWithHome()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home Dashboard'), findsOneWidget);
      expect(find.text('Tab Content'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('shows tab content when showHome is false', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showHomeProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(home: _TestShellWithHome()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tab Content'), findsOneWidget);
      expect(find.text('Home Dashboard'), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('tapping Home icon returns to Home Dashboard', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            showHomeProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(home: _TestShellWithHome()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we start on tab content.
      expect(find.text('Tab Content'), findsOneWidget);

      // Tap Home icon.
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Should now show Home Dashboard.
      expect(find.text('Home Dashboard'), findsOneWidget);
      expect(find.text('Tab Content'), findsNothing);
    });
  });

  group('Slot drill ID extraction', () {
    test('extracts filled incomplete drillIds in slot order', () {
      final slots = [
        const Slot(drillId: 'drill-c').toJson(),
        const Slot(drillId: 'drill-a').toJson(),
        const Slot().toJson(),
        const Slot(
          drillId: 'drill-b',
          completionState: CompletionState.completedLinked,
        ).toJson(),
      ];
      final slotsJson = jsonEncode(slots);
      final parsed = parseSlotsFromJson(slotsJson);
      final filledIncomplete = parsed
          .where((s) => s.isFilled && !s.isCompleted)
          .map((s) => s.drillId!)
          .toList();

      // drill-b is completed, should be excluded.
      expect(filledIncomplete, ['drill-c', 'drill-a']);
    });
  });
}
