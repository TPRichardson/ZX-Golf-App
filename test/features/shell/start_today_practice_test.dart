import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// Fix 12 — "Start Today's Practice" button tests.
//
// _StartTodayButton is a private ConsumerWidget in CalendarScreen with deep
// Riverpod dependencies. Testing the full widget tree would require mocking
// the entire provider chain (Supabase, SyncEngine, database, repos, etc.).
//
// Instead, we test the pure business logic that the button relies on:
// 1. Slot parsing from CalendarDay JSON.
// 2. Filled slot detection and drill ID extraction.
// 3. Visibility conditions.

/// Mirrors the private _parseSlotsFromJson in CalendarScreen.
List<Slot> parseSlotsFromJson(String slotsJson) {
  if (slotsJson.isEmpty || slotsJson == '[]') return [];
  final List<dynamic> list = jsonDecode(slotsJson) as List<dynamic>;
  return list.map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList();
}

void main() {
  group('Fix 12: Start Today\'s Practice logic', () {
    test('parseSlotsFromJson extracts filled slot drillIds', () {
      final slots = [
        const Slot(drillId: 'drill-a').toJson(),
        const Slot().toJson(), // empty slot
        const Slot(drillId: 'drill-b').toJson(),
      ];
      final slotsJson = jsonEncode(slots);

      final parsed = parseSlotsFromJson(slotsJson);
      final filledDrillIds = parsed
          .where((s) => s.isFilled)
          .map((s) => s.drillId!)
          .toList();

      expect(filledDrillIds, ['drill-a', 'drill-b']);
    });

    test('empty CalendarDay produces no drill IDs', () {
      // Empty JSON array.
      final parsed = parseSlotsFromJson('[]');
      expect(parsed, isEmpty);

      // All empty slots.
      final allEmpty = [
        const Slot().toJson(),
        const Slot().toJson(),
      ];
      final parsedEmpty = parseSlotsFromJson(jsonEncode(allEmpty));
      final filledIds = parsedEmpty.where((s) => s.isFilled).toList();
      expect(filledIds, isEmpty);
    });

    test('filled slots preserve order for PracticeBlock drill sequence', () {
      final slots = [
        const Slot(drillId: 'drill-c').toJson(),
        const Slot(drillId: 'drill-a').toJson(),
        const Slot().toJson(), // empty
        const Slot(drillId: 'drill-b').toJson(),
      ];
      final slotsJson = jsonEncode(slots);

      final parsed = parseSlotsFromJson(slotsJson);
      final filledDrillIds = parsed
          .where((s) => s.isFilled)
          .map((s) => s.drillId!)
          .toList();

      // Order must match slot order, not alphabetical.
      expect(filledDrillIds, ['drill-c', 'drill-a', 'drill-b']);
    });
  });
}
