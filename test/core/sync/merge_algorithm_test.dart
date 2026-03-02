import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/merge_algorithm.dart';

void main() {
  group('MergeAlgorithm — Table Classification', () {
    test('softDeleteTables contains expected entities', () {
      expect(MergeAlgorithm.softDeleteTables, contains('User'));
      expect(MergeAlgorithm.softDeleteTables, contains('Drill'));
      expect(MergeAlgorithm.softDeleteTables, contains('Session'));
      expect(MergeAlgorithm.softDeleteTables, contains('UserDevice'));
      expect(MergeAlgorithm.softDeleteTables.length, 16);
    });

    test('appendOnlyTables contains EventLog', () {
      expect(MergeAlgorithm.appendOnlyTables, equals({'EventLog'}));
    });

    test('slotMergeTables contains CalendarDay', () {
      expect(MergeAlgorithm.slotMergeTables, equals({'CalendarDay'}));
    });
  });

  group('MergeAlgorithm.mergeRow — LWW', () {
    test('remote newer wins', () {
      final local = {
        'userId': 'u1',
        'name': 'local-name',
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'isDeleted': false,
      };
      final remote = {
        'userId': 'u1',
        'name': 'remote-name',
        'updatedAt': '2026-03-01T12:00:00.000Z',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['name'], 'remote-name');
    });

    test('remote strictly newer by 1ms wins', () {
      final local = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.001Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'remote');
    });

    test('remote with DateTime objects works', () {
      final local = {
        'updatedAt': DateTime.utc(2026, 3, 1, 10, 0),
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': DateTime.utc(2026, 3, 1, 12, 0),
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'remote');
    });

    test('local newer wins', () {
      final local = {
        'updatedAt': '2026-03-01T14:00:00.000Z',
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'local');
    });

    test('tie goes to local', () {
      final ts = '2026-03-01T10:00:00.000Z';
      final local = {
        'updatedAt': ts,
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': ts,
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'local');
    });

    test('local null timestamp — remote wins', () {
      final local = {
        'updatedAt': null,
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'remote');
    });
  });

  group('MergeAlgorithm.mergeRow — Delete-always-wins', () {
    test('local deleted, remote not — result is deleted', () {
      final local = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'local',
        'isDeleted': true,
      };
      final remote = {
        'updatedAt': '2026-03-01T12:00:00.000Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['isDeleted'], true);
    });

    test('remote deleted, local not — result is deleted', () {
      final local = {
        'updatedAt': '2026-03-01T12:00:00.000Z',
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'remote',
        'isDeleted': true,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['isDeleted'], true);
    });

    test('both deleted — result is deleted with latest timestamp', () {
      final local = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'local',
        'isDeleted': true,
      };
      final remote = {
        'updatedAt': '2026-03-01T14:00:00.000Z',
        'value': 'remote',
        'isDeleted': true,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['isDeleted'], true);
      expect(result['value'], 'remote');
    });

    test('local deleted newer — uses local fields but isDeleted=true', () {
      final local = {
        'updatedAt': '2026-03-01T14:00:00.000Z',
        'value': 'local',
        'isDeleted': true,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['isDeleted'], true);
      expect(result['value'], 'local');
    });
  });

  group('MergeAlgorithm.mergeRow — Edge cases', () {
    test('both timestamps null — local wins', () {
      final local = {'updatedAt': null, 'value': 'local', 'isDeleted': false};
      final remote = {'updatedAt': null, 'value': 'remote', 'isDeleted': false};
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'local');
    });

    test('empty payloads — returns local copy', () {
      final local = <String, dynamic>{'isDeleted': false};
      final remote = <String, dynamic>{'isDeleted': false};
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result, isA<Map<String, dynamic>>());
    });

    test('result is a new map (not same reference as input)', () {
      final local = {
        'updatedAt': '2026-03-01T14:00:00.000Z',
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(identical(result, local), false);
    });

    test('invalid timestamp string — treated as null', () {
      final local = {
        'updatedAt': 'not-a-date',
        'value': 'local',
        'isDeleted': false,
      };
      final remote = {
        'updatedAt': '2026-03-01T10:00:00.000Z',
        'value': 'remote',
        'isDeleted': false,
      };
      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['value'], 'remote');
    });
  });

  group('MergeAlgorithm.mergeCalendarDay — Slot-level merge', () {
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

    test('position-by-position merge — remote slot newer wins', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(drillId: 'localDrill', updatedAt: '2026-03-01T09:00:00.000Z'),
          makeSlot(drillId: null, updatedAt: '2026-03-01T08:00:00.000Z'),
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(drillId: 'remoteDrill', updatedAt: '2026-03-01T11:00:00.000Z'),
          makeSlot(drillId: 'remoteDrill2', updatedAt: '2026-03-01T07:00:00.000Z'),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;

      // Slot 0: remote newer → remoteDrill
      expect(resultSlots[0]['drillId'], 'remoteDrill');
      // Slot 1: local newer → null (local was empty but newer)
      expect(resultSlots[1]['drillId'], null);
    });

    test('local slot newer wins at position', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(drillId: 'localDrill', updatedAt: '2026-03-01T15:00:00.000Z'),
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(drillId: 'remoteDrill', updatedAt: '2026-03-01T11:00:00.000Z'),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;
      expect(resultSlots[0]['drillId'], 'localDrill');
    });

    test('different capacities — slots only in one side included', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(drillId: 'local0', updatedAt: '2026-03-01T09:00:00.000Z'),
          makeSlot(drillId: 'local1', updatedAt: '2026-03-01T09:00:00.000Z'),
          makeSlot(drillId: 'local2', updatedAt: '2026-03-01T09:00:00.000Z'),
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(drillId: 'remote0', updatedAt: '2026-03-01T11:00:00.000Z'),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;

      expect(resultSlots.length, 3);
      // Position 0: remote newer
      expect(resultSlots[0]['drillId'], 'remote0');
      // Positions 1,2: only in local
      expect(resultSlots[1]['drillId'], 'local1');
      expect(resultSlots[2]['drillId'], 'local2');
    });

    test('remote has more slots — extra remote slots included', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(drillId: 'local0', updatedAt: '2026-03-01T09:00:00.000Z'),
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(drillId: 'remote0', updatedAt: '2026-03-01T11:00:00.000Z'),
          makeSlot(drillId: 'remote1', updatedAt: '2026-03-01T11:00:00.000Z'),
          makeSlot(drillId: 'remote2', updatedAt: '2026-03-01T11:00:00.000Z'),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;

      expect(resultSlots.length, 3);
      expect(resultSlots[1]['drillId'], 'remote1');
      expect(resultSlots[2]['drillId'], 'remote2');
    });

    test('missing updatedAt on both slots — falls back to row-level winner', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(drillId: 'localDrill'), // no updatedAt
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(drillId: 'remoteDrill'), // no updatedAt
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;

      // Remote row is newer → remote slot wins as fallback.
      expect(resultSlots[0]['drillId'], 'remoteDrill');
    });

    test('missing updatedAt on remote slot only — local wins', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(drillId: 'localDrill', updatedAt: '2026-03-01T09:00:00.000Z'),
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(drillId: 'remoteDrill'), // no updatedAt
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;

      // Local slot has updatedAt, remote doesn't → local wins.
      expect(resultSlots[0]['drillId'], 'localDrill');
    });

    test('null slots on both sides — preserves base structure', () {
      final local = {
        'calendarDayId': 'cd1',
        'userId': 'u1',
        'date': '2026-03-01',
        'slotCapacity': 5,
        'slots': null,
        'updatedAt': '2026-03-01T10:00:00.000Z',
      };
      final remote = {
        'calendarDayId': 'cd1',
        'userId': 'u1',
        'date': '2026-03-01',
        'slotCapacity': 5,
        'slots': null,
        'updatedAt': '2026-03-01T12:00:00.000Z',
      };

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      expect(result['calendarDayId'], 'cd1');
    });

    test('slot completed on A, different slot assigned on B — both preserved', () {
      final local = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T10:00:00.000Z',
        slots: [
          makeSlot(
            drillId: 'drill1',
            completionState: 'CompletedLinked',
            updatedAt: '2026-03-01T11:00:00.000Z',
          ),
          makeSlot(updatedAt: '2026-03-01T08:00:00.000Z'),
        ],
      );
      final remote = makeDay(
        id: 'cd1',
        updatedAt: '2026-03-01T12:00:00.000Z',
        slots: [
          makeSlot(
            drillId: 'drill1',
            completionState: 'Incomplete',
            updatedAt: '2026-03-01T09:00:00.000Z',
          ),
          makeSlot(
            drillId: 'drill2',
            updatedAt: '2026-03-01T11:30:00.000Z',
          ),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final resultSlots = jsonDecode(result['slots'] as String) as List;

      // Slot 0: local newer (11:00 > 09:00) → CompletedLinked
      expect(resultSlots[0]['completionState'], 'CompletedLinked');
      // Slot 1: remote newer (11:30 > 08:00) → drill2 assigned
      expect(resultSlots[1]['drillId'], 'drill2');
    });
  });
}
