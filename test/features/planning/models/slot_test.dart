import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

void main() {
  group('Slot JSON round-trip', () {
    test('empty slot serializes and deserializes', () {
      const slot = Slot();

      final json = slot.toJson();
      final restored = Slot.fromJson(json);

      expect(restored.drillId, isNull);
      expect(restored.ownerType, SlotOwnerType.manual);
      expect(restored.ownerId, isNull);
      expect(restored.completionState, CompletionState.incomplete);
      expect(restored.completingSessionId, isNull);
      expect(restored.planned, isTrue);
      expect(restored, equals(slot));
    });

    test('filled slot serializes and deserializes', () {
      const slot = Slot(
        drillId: 'drill-1',
        ownerType: SlotOwnerType.routineInstance,
        ownerId: 'ri-1',
        completionState: CompletionState.completedLinked,
        completingSessionId: 'session-1',
        planned: true,
      );

      final json = slot.toJson();
      final restored = Slot.fromJson(json);

      expect(restored, equals(slot));
    });

    test('overflow slot with planned=false round-trips', () {
      const slot = Slot(
        drillId: 'drill-2',
        ownerType: SlotOwnerType.manual,
        completionState: CompletionState.completedLinked,
        completingSessionId: 'session-2',
        planned: false,
      );

      final jsonStr = jsonEncode(slot.toJson());
      final restored = Slot.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

      expect(restored.planned, isFalse);
      expect(restored, equals(slot));
    });

    test('list of slots round-trips through JSON string', () {
      const slots = [
        Slot(drillId: 'drill-1'),
        Slot(),
        Slot(
          drillId: 'drill-2',
          completionState: CompletionState.completedManual,
        ),
      ];

      final jsonStr =
          jsonEncode(slots.map((s) => s.toJson()).toList());
      final restored = (jsonDecode(jsonStr) as List<dynamic>)
          .map((e) => Slot.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(restored.length, 3);
      expect(restored[0].drillId, 'drill-1');
      expect(restored[1].isEmpty, isTrue);
      expect(restored[2].isCompleted, isTrue);
    });
  });

  group('Slot properties', () {
    test('isEmpty and isFilled', () {
      const empty = Slot();
      const filled = Slot(drillId: 'drill-1');

      expect(empty.isEmpty, isTrue);
      expect(empty.isFilled, isFalse);
      expect(filled.isEmpty, isFalse);
      expect(filled.isFilled, isTrue);
    });

    test('isCompleted for each state', () {
      const incomplete = Slot(completionState: CompletionState.incomplete);
      const linked = Slot(completionState: CompletionState.completedLinked);
      const manual = Slot(completionState: CompletionState.completedManual);

      expect(incomplete.isCompleted, isFalse);
      expect(linked.isCompleted, isTrue);
      expect(manual.isCompleted, isTrue);
    });
  });

  group('Slot copyWith', () {
    test('preserves values when nothing changes', () {
      const slot = Slot(
        drillId: 'drill-1',
        ownerType: SlotOwnerType.routineInstance,
        ownerId: 'ri-1',
        completionState: CompletionState.incomplete,
        planned: true,
      );

      final copy = slot.copyWith();
      expect(copy, equals(slot));
    });

    test('sets nullable fields to null', () {
      const slot = Slot(
        drillId: 'drill-1',
        ownerId: 'ri-1',
        completingSessionId: 'session-1',
      );

      final cleared = slot.copyWith(
        drillId: () => null,
        ownerId: () => null,
        completingSessionId: () => null,
      );

      expect(cleared.drillId, isNull);
      expect(cleared.ownerId, isNull);
      expect(cleared.completingSessionId, isNull);
    });
  });
}
