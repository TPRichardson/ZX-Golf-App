import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/merge_algorithm.dart';

/// Phase 7B — Two-device convergence tests.
/// Verifies that when two devices independently edit the same data and then
/// merge each other's changes, they converge to identical state.
void main() {
  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Simulates a row on a device with the given field values and timestamp.
  Map<String, dynamic> makeRow({
    required String id,
    required String name,
    required String updatedAt,
    String? description,
    bool isDeleted = false,
  }) {
    return {
      'id': id,
      'name': name,
      'description': description ?? 'desc',
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }

  Map<String, dynamic> makeDay({
    required String id,
    required String updatedAt,
    required List<Map<String, dynamic>> slots,
  }) {
    return {
      'calendarDayId': id,
      'userId': 'u1',
      'date': '2026-03-01',
      'slotCapacity': slots.length,
      'slots': jsonEncode(slots),
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> makeSlot({
    String? drillId,
    String completionState = 'Incomplete',
    String? updatedAt,
  }) {
    return {
      'drillId': drillId,
      'ownerType': 'Manual',
      'ownerId': null,
      'completionState': completionState,
      'completingSessionId': null,
      'planned': true,
      'updatedAt': updatedAt,
    };
  }

  /// Parses the merged slots JSON string back to a list of maps.
  List<Map<String, dynamic>> parseSlots(Map<String, dynamic> day) {
    final raw = day['slots'];
    if (raw is String) {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  // -------------------------------------------------------------------------
  // Timestamps used throughout tests
  // -------------------------------------------------------------------------
  const t1 = '2026-03-01T10:00:00.000Z';
  const t2 = '2026-03-01T12:00:00.000Z';
  const t3 = '2026-03-01T14:00:00.000Z';

  // =========================================================================
  // Group 1: Two-device convergence — row-level
  // =========================================================================
  group('Two-device convergence — row-level', () {
    test('Edit same field on both devices — newer wins on both sides', () {
      // Device A edits name at T1.
      final deviceA = makeRow(id: 'r1', name: 'A-name', updatedAt: t1);
      // Device B edits name at T2 (T2 > T1).
      final deviceB = makeRow(id: 'r1', name: 'B-name', updatedAt: t2);

      // Device A merges B's changes (local=A, remote=B).
      final resultOnA = MergeAlgorithm.mergeRow(deviceA, deviceB);
      // Device B merges A's changes (local=B, remote=A).
      final resultOnB = MergeAlgorithm.mergeRow(deviceB, deviceA);

      // Both devices should converge to B's value since T2 > T1.
      expect(resultOnA['name'], 'B-name');
      expect(resultOnB['name'], 'B-name');

      // Full convergence: both maps are identical.
      expect(resultOnA['name'], resultOnB['name']);
      expect(resultOnA['updatedAt'], resultOnB['updatedAt']);
    });

    test('Edit different fields on both devices — LWW resolves consistently',
        () {
      // Device A edits name at T1.
      final deviceA = makeRow(
        id: 'r1',
        name: 'A-name',
        description: 'original-desc',
        updatedAt: t1,
      );
      // Device B edits description at T2 (T2 > T1). Row-level LWW means
      // the entire row with the newer timestamp wins, not field-by-field.
      final deviceB = makeRow(
        id: 'r1',
        name: 'original-name',
        description: 'B-desc',
        updatedAt: t2,
      );

      final resultOnA = MergeAlgorithm.mergeRow(deviceA, deviceB);
      final resultOnB = MergeAlgorithm.mergeRow(deviceB, deviceA);

      // B's entire row wins because T2 > T1. A's name edit is lost.
      // This is expected LWW behavior: row-level, not field-level merge.
      expect(resultOnA['name'], 'original-name');
      expect(resultOnA['description'], 'B-desc');
      expect(resultOnB['name'], 'original-name');
      expect(resultOnB['description'], 'B-desc');

      // Full convergence.
      expect(resultOnA['name'], resultOnB['name']);
      expect(resultOnA['description'], resultOnB['description']);
    });

    test('Concurrent edits with same timestamp — local wins on both sides',
        () {
      // Both devices edit at the exact same timestamp T1.
      final deviceA = makeRow(id: 'r1', name: 'A-name', updatedAt: t1);
      final deviceB = makeRow(id: 'r1', name: 'B-name', updatedAt: t1);

      final resultOnA = MergeAlgorithm.mergeRow(deviceA, deviceB);
      final resultOnB = MergeAlgorithm.mergeRow(deviceB, deviceA);

      // LWW tie-breaking: local wins. So A keeps A's value, B keeps B's value.
      // This means they do NOT converge — each device retains its own value.
      // This is expected LWW behavior with equal timestamps. In practice,
      // millisecond-precision timestamps make true ties extremely rare.
      // A real deployment could add a device-ID tiebreaker, but the current
      // spec uses simple "local wins on tie" semantics.
      expect(resultOnA['name'], 'A-name');
      expect(resultOnB['name'], 'B-name');

      // Explicitly document that this is a known non-convergence case.
      expect(resultOnA['name'] == resultOnB['name'], isFalse,
          reason: 'Same-timestamp edits do not converge with local-wins tie-breaking');
    });
  });

  // =========================================================================
  // Group 2: Two-device convergence — delete
  // =========================================================================
  group('Two-device convergence — delete', () {
    test('Delete on A, edit on B — both converge to deleted', () {
      // Device A deletes the row at T1.
      final deviceA = makeRow(
        id: 'r1',
        name: 'A-deleted',
        updatedAt: t1,
        isDeleted: true,
      );
      // Device B edits the row at T2 (T2 > T1), unaware of the delete.
      final deviceB = makeRow(
        id: 'r1',
        name: 'B-edited',
        updatedAt: t2,
        isDeleted: false,
      );

      final resultOnA = MergeAlgorithm.mergeRow(deviceA, deviceB);
      final resultOnB = MergeAlgorithm.mergeRow(deviceB, deviceA);

      // Delete-always-wins: both sides converge to deleted.
      expect(resultOnA['isDeleted'], true);
      expect(resultOnB['isDeleted'], true);

      // Both use the later timestamp's fields but with isDeleted forced true.
      expect(resultOnA['isDeleted'], resultOnB['isDeleted']);
    });

    test('Edit on A, delete on B — both converge to deleted', () {
      // Device A edits the row at T1.
      final deviceA = makeRow(
        id: 'r1',
        name: 'A-edited',
        updatedAt: t1,
        isDeleted: false,
      );
      // Device B deletes the row at T2.
      final deviceB = makeRow(
        id: 'r1',
        name: 'B-deleted',
        updatedAt: t2,
        isDeleted: true,
      );

      final resultOnA = MergeAlgorithm.mergeRow(deviceA, deviceB);
      final resultOnB = MergeAlgorithm.mergeRow(deviceB, deviceA);

      // Delete-always-wins: both sides converge to deleted.
      expect(resultOnA['isDeleted'], true);
      expect(resultOnB['isDeleted'], true);

      // Convergence: both results agree on deleted state.
      expect(resultOnA['isDeleted'], resultOnB['isDeleted']);
    });
  });

  // =========================================================================
  // Group 3: Two-device convergence — CalendarDay slots
  // =========================================================================
  group('Two-device convergence — CalendarDay slots', () {
    test(
        'Slot completed on A, different slot assigned on B — both preserved',
        () {
      // Initial state: two empty slots.
      // Device A completes slot[0] at T2.
      final deviceA = makeDay(
        id: 'cd1',
        updatedAt: t2,
        slots: [
          makeSlot(
            drillId: 'drill1',
            completionState: 'CompletedLinked',
            updatedAt: t2,
          ),
          makeSlot(drillId: null, updatedAt: t1),
        ],
      );

      // Device B assigns a drill to slot[1] at T3.
      final deviceB = makeDay(
        id: 'cd1',
        updatedAt: t3,
        slots: [
          makeSlot(drillId: 'drill1', completionState: 'Incomplete', updatedAt: t1),
          makeSlot(drillId: 'drill2', completionState: 'Incomplete', updatedAt: t3),
        ],
      );

      // Merge A <- B (on device A: local=A, remote=B).
      final resultOnA = MergeAlgorithm.mergeCalendarDay(deviceA, deviceB);
      // Merge B <- A (on device B: local=B, remote=A).
      final resultOnB = MergeAlgorithm.mergeCalendarDay(deviceB, deviceA);

      final slotsOnA = parseSlots(resultOnA);
      final slotsOnB = parseSlots(resultOnB);

      // Slot 0: A's version (T2) is newer than B's (T1) — completed preserved.
      expect(slotsOnA[0]['completionState'], 'CompletedLinked');
      expect(slotsOnB[0]['completionState'], 'CompletedLinked');

      // Slot 1: B's version (T3) is newer than A's (T1) — drill2 assigned.
      expect(slotsOnA[1]['drillId'], 'drill2');
      expect(slotsOnB[1]['drillId'], 'drill2');

      // Full convergence at slot level.
      expect(slotsOnA[0]['completionState'], slotsOnB[0]['completionState']);
      expect(slotsOnA[1]['drillId'], slotsOnB[1]['drillId']);
    });

    test('Same slot edited on both — newer wins consistently', () {
      // Both devices edit slot[0]. Device B's edit is newer.
      final deviceA = makeDay(
        id: 'cd1',
        updatedAt: t1,
        slots: [
          makeSlot(drillId: 'drillA', updatedAt: t1),
        ],
      );
      final deviceB = makeDay(
        id: 'cd1',
        updatedAt: t2,
        slots: [
          makeSlot(drillId: 'drillB', updatedAt: t2),
        ],
      );

      final resultOnA = MergeAlgorithm.mergeCalendarDay(deviceA, deviceB);
      final resultOnB = MergeAlgorithm.mergeCalendarDay(deviceB, deviceA);

      final slotsOnA = parseSlots(resultOnA);
      final slotsOnB = parseSlots(resultOnB);

      // B's slot is newer, so drillB wins on both devices.
      expect(slotsOnA[0]['drillId'], 'drillB');
      expect(slotsOnB[0]['drillId'], 'drillB');

      // Convergence.
      expect(slotsOnA[0]['drillId'], slotsOnB[0]['drillId']);
    });

    test('Slot edited on A, row-level edit on B — correct merge', () {
      // Device A edits slot[0] at T3 (slot-level newer).
      // Device B only changes the row-level updatedAt at T2 (e.g., slotCapacity
      // change or other row-level field), but slot[0] was last touched at T1.
      final deviceA = makeDay(
        id: 'cd1',
        updatedAt: t1,
        slots: [
          makeSlot(drillId: 'drillA', updatedAt: t3),
          makeSlot(drillId: null, updatedAt: t1),
        ],
      );
      final deviceB = makeDay(
        id: 'cd1',
        updatedAt: t2,
        slots: [
          makeSlot(drillId: 'drillB', updatedAt: t1),
          makeSlot(drillId: 'drillB2', updatedAt: t2),
        ],
      );

      final resultOnA = MergeAlgorithm.mergeCalendarDay(deviceA, deviceB);
      final resultOnB = MergeAlgorithm.mergeCalendarDay(deviceB, deviceA);

      final slotsOnA = parseSlots(resultOnA);
      final slotsOnB = parseSlots(resultOnB);

      // Slot 0: A's slot (T3) is newer than B's slot (T1) — drillA wins.
      expect(slotsOnA[0]['drillId'], 'drillA');
      expect(slotsOnB[0]['drillId'], 'drillA');

      // Slot 1: B's slot (T2) is newer than A's slot (T1) — drillB2 wins.
      expect(slotsOnA[1]['drillId'], 'drillB2');
      expect(slotsOnB[1]['drillId'], 'drillB2');

      // Convergence.
      expect(slotsOnA[0]['drillId'], slotsOnB[0]['drillId']);
      expect(slotsOnA[1]['drillId'], slotsOnB[1]['drillId']);
    });
  });

  // =========================================================================
  // Group 4: Multi-step convergence
  // =========================================================================
  group('Multi-step convergence', () {
    test('Three-step edit chain converges', () {
      // Step 1: Device A edits at T1 (name='A-v1').
      // Step 2: Device B edits at T2 (name='B-v1').
      // Step 3: Device A edits again at T3 (name='A-v2').
      // After the chain, Device A holds stateA2(T3), Device B holds stateB1(T2).
      final stateB1 = makeRow(id: 'r1', name: 'B-v1', updatedAt: t2);
      final stateA2 = makeRow(id: 'r1', name: 'A-v2', updatedAt: t3);

      // Merge on Device A: local=A2(T3), remote=B1(T2). A2 wins.
      final resultOnA = MergeAlgorithm.mergeRow(stateA2, stateB1);
      // Merge on Device B: local=B1(T2), remote=A2(T3). A2 wins.
      final resultOnB = MergeAlgorithm.mergeRow(stateB1, stateA2);

      // T3 is the newest — A-v2 wins on both sides.
      expect(resultOnA['name'], 'A-v2');
      expect(resultOnB['name'], 'A-v2');

      // Convergence.
      expect(resultOnA['name'], resultOnB['name']);
      expect(resultOnA['updatedAt'], resultOnB['updatedAt']);
    });

    test('Delete followed by remote edit — delete wins', () {
      // Device A deletes the row at T1.
      final deviceA = makeRow(
        id: 'r1',
        name: 'deleted',
        updatedAt: t1,
        isDeleted: true,
      );

      // Device B, unaware of the delete, edits the row at T2.
      final deviceB = makeRow(
        id: 'r1',
        name: 'B-edited',
        updatedAt: t2,
        isDeleted: false,
      );

      // Merge on Device A: local=deleted(T1), remote=edit(T2).
      final resultOnA = MergeAlgorithm.mergeRow(deviceA, deviceB);
      // Merge on Device B: local=edit(T2), remote=deleted(T1).
      final resultOnB = MergeAlgorithm.mergeRow(deviceB, deviceA);

      // Delete-always-wins regardless of timestamps.
      expect(resultOnA['isDeleted'], true);
      expect(resultOnB['isDeleted'], true);

      // Convergence on delete state.
      expect(resultOnA['isDeleted'], resultOnB['isDeleted']);
    });
  });
}
