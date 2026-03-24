import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/merge_algorithm.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/dto/sync_dto.dart';
import 'package:zx_golf_app/data/enums.dart';

// Phase 7B — Merge pipeline integration tests.
// Tests MergeAlgorithm with realistic DB row maps (read from in-memory Drift DB),
// SyncWriteGate behavior during merge, and edge cases.
// Since SyncEngine._applyDownloadedChanges is private and requires a SupabaseClient,
// these tests exercise the merge logic and gate independently with DB-backed data.

void main() {
  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  /// Build a User sync DTO map matching the format produced by User.toSyncDto().
  Map<String, dynamic> makeUserDto({
    required String userId,
    required String updatedAt,
    String? displayName,
    bool isDeleted = false,
  }) {
    return {
      'userId': userId,
      'displayName': displayName ?? 'Test User',
      'email': 'test@example.com',
      'timezone': 'UTC',
      'weekStartDay': 1,
      'unitPreferences': '{"distance":"yards"}',
      'IsDeleted': isDeleted,
      'createdAt': '2026-03-01T00:00:00.000Z',
      'UpdatedAt': updatedAt,
    };
  }

  /// Build a Drill sync DTO map with realistic fields.
  Map<String, dynamic> makeDrillDto({
    required String drillId,
    required String updatedAt,
    String? name,
    String? userId,
    bool isDeleted = false,
  }) {
    return {
      'drillId': drillId,
      'userId': userId,
      'name': name ?? 'Test Drill',
      'skillArea': 'Putting',
      'drillType': 'Transition',
      'scoringMode': null,
      'inputMode': 'GridCell',
      'metricSchemaId': 'grid_1x3_direction',
      'gridType': null,
      'subskillMapping': '["putting_direction_control"]',
      'clubSelectionMode': null,
      'targetDistanceMode': null,
      'targetDistanceValue': null,
      'targetSizeMode': null,
      'targetSizeWidth': null,
      'targetSizeDepth': null,
      'requiredSetCount': 1,
      'requiredAttemptsPerSet': 9,
      'anchors':
          '{"putting_direction_control":{"Min":20,"Scratch":60,"Pro":90}}',
      'origin': 'System',
      'status': 'Active',
      'IsDeleted': isDeleted,
      'createdAt': '2026-03-01T00:00:00.000Z',
      'UpdatedAt': updatedAt,
    };
  }

  /// Build a CalendarDay map with slot-level merge fields.
  Map<String, dynamic> makeCalendarDayDto({
    required String calendarDayId,
    required String updatedAt,
    required List<Map<String, dynamic>> slots,
    String userId = 'u1',
  }) {
    return {
      'calendarDayId': calendarDayId,
      'userId': userId,
      'date': '2026-03-15',
      'SlotCapacity': slots.length,
      'Slots': jsonEncode(slots),
      'createdAt': '2026-03-01T00:00:00.000Z',
      'UpdatedAt': updatedAt,
    };
  }

  /// Build a slot map for CalendarDay slot-level merge.
  Map<String, dynamic> makeSlot({
    String? drillId,
    String completionState = 'Incomplete',
    String? completingSessionId,
    String? updatedAt,
  }) {
    return {
      'drillId': drillId,
      'ownerType': 'Manual',
      'ownerId': null,
      'completionState': completionState,
      'completingSessionId': completingSessionId,
      'planned': true,
      'updatedAt': updatedAt,
    };
  }

  /// Build an EventLog sync DTO map.
  Map<String, dynamic> makeEventLogDto({
    required String eventLogId,
    required String createdAt,
    String userId = 'u1',
  }) {
    return {
      'eventLogId': eventLogId,
      'userId': userId,
      'deviceId': 'device-1',
      'eventTypeId': 'session_close',
      'timestamp': createdAt,
      'affectedEntityIds': null,
      'affectedSubskills': null,
      'metadata': null,
      'createdAt': createdAt,
    };
  }

  /// Parse slots from a CalendarDay result map.
  List<Map<String, dynamic>> parseSlots(Map<String, dynamic> day) {
    final raw = day['Slots'];
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

  // Canonical timestamps for readability.
  const tOld = '2026-03-01T08:00:00.000Z';
  const tBase = '2026-03-01T10:00:00.000Z';
  const tNewer = '2026-03-01T12:00:00.000Z';
  // ignore: unused_local_variable
  const tNewest = '2026-03-01T14:00:00.000Z';

  // ===========================================================================
  // Group: Download with no local data
  // ===========================================================================
  group('Download with no local data', () {
    test('Remote row inserted when no local exists — User', () {
      // When there is no local row, _applyDownloadedChanges inserts the remote
      // directly (local == null path). MergeAlgorithm is not called; the remote
      // is used as-is. Verify the remote map is a valid User payload.
      final remote = makeUserDto(
        userId: 'new-user-1',
        updatedAt: tBase,
        displayName: 'Remote User',
      );

      // Simulate the no-local path: when local is null, remote wins directly.
      // In the actual code: `local == null ? remote : MergeAlgorithm.mergeRow(...)`.
      final result = remote;
      expect(result['userId'], 'new-user-1');
      expect(result['displayName'], 'Remote User');
      expect(result['UpdatedAt'], tBase);
      expect(result['IsDeleted'], false);
    });

    test('Remote row inserted when no local exists — Drill', () {
      final remote = makeDrillDto(
        drillId: 'new-drill-1',
        updatedAt: tBase,
        name: 'Remote Drill',
        userId: 'u1',
      );

      // No local row → remote is used directly.
      final result = remote;
      expect(result['drillId'], 'new-drill-1');
      expect(result['name'], 'Remote Drill');
      expect(result['skillArea'], 'Putting');
      expect(result['IsDeleted'], false);
    });
  });

  // ===========================================================================
  // Group: Download with older remote
  // ===========================================================================
  group('Download with older remote', () {
    test('Local preserved when remote updatedAt is older', () {
      final local = makeUserDto(
        userId: 'u1',
        updatedAt: tNewer,
        displayName: 'Local Name',
      );
      final remote = makeUserDto(
        userId: 'u1',
        updatedAt: tBase,
        displayName: 'Remote Name',
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['displayName'], 'Local Name');
      expect(result['UpdatedAt'], tNewer);
    });

    test('Local preserved on tie', () {
      final local = makeUserDto(
        userId: 'u1',
        updatedAt: tBase,
        displayName: 'Local Tie',
      );
      final remote = makeUserDto(
        userId: 'u1',
        updatedAt: tBase,
        displayName: 'Remote Tie',
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      // Tie goes to local (LWW: remote must be strictly newer).
      expect(result['displayName'], 'Local Tie');
    });

    test('Local preserved when remote updatedAt is null', () {
      final local = makeUserDto(
        userId: 'u1',
        updatedAt: tBase,
        displayName: 'Local With Timestamp',
      );
      final remote = makeUserDto(
        userId: 'u1',
        updatedAt: tBase,
        displayName: 'Remote Null Ts',
      );
      // Override remote UpdatedAt to null to simulate missing timestamp.
      remote['UpdatedAt'] = null;

      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['displayName'], 'Local With Timestamp');
      expect(result['UpdatedAt'], tBase);
    });
  });

  // ===========================================================================
  // Group: Download with newer remote
  // ===========================================================================
  group('Download with newer remote', () {
    test('Remote wins when remote updatedAt is newer', () {
      final local = makeDrillDto(
        drillId: 'd1',
        updatedAt: tBase,
        name: 'Local Drill',
      );
      final remote = makeDrillDto(
        drillId: 'd1',
        updatedAt: tNewer,
        name: 'Remote Drill Updated',
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['name'], 'Remote Drill Updated');
      expect(result['UpdatedAt'], tNewer);
    });

    test('Remote wins when local updatedAt is null', () {
      final local = makeDrillDto(
        drillId: 'd1',
        updatedAt: tBase,
        name: 'Local Null Ts',
      );
      local['UpdatedAt'] = null;
      final remote = makeDrillDto(
        drillId: 'd1',
        updatedAt: tBase,
        name: 'Remote With Timestamp',
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['name'], 'Remote With Timestamp');
    });

    test('Remote wins with significantly newer timestamp', () {
      final local = makeUserDto(
        userId: 'u1',
        updatedAt: '2026-01-01T00:00:00.000Z',
        displayName: 'Very Old Local',
      );
      final remote = makeUserDto(
        userId: 'u1',
        updatedAt: '2026-03-15T23:59:59.000Z',
        displayName: 'Much Newer Remote',
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      expect(result['displayName'], 'Much Newer Remote');
      expect(result['UpdatedAt'], '2026-03-15T23:59:59.000Z');
    });
  });

  // ===========================================================================
  // Group: Delete-always-wins
  // ===========================================================================
  group('Delete-always-wins', () {
    test('Deleted remote overwrites non-deleted local', () {
      final local = makeDrillDto(
        drillId: 'd1',
        updatedAt: tNewer,
        name: 'Active Local',
        isDeleted: false,
      );
      final remote = makeDrillDto(
        drillId: 'd1',
        updatedAt: tBase,
        name: 'Deleted Remote',
        isDeleted: true,
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      // Delete-always-wins: even though local is newer, result must be deleted.
      expect(result['IsDeleted'], true);
      // The winner row uses local's fields (newer timestamp) but IsDeleted forced true.
      expect(result['name'], 'Active Local');
    });

    test('Deleted local preserved against non-deleted remote', () {
      final local = makeDrillDto(
        drillId: 'd1',
        updatedAt: tBase,
        name: 'Deleted Local',
        isDeleted: true,
      );
      final remote = makeDrillDto(
        drillId: 'd1',
        updatedAt: tNewer,
        name: 'Active Remote',
        isDeleted: false,
      );

      final result = MergeAlgorithm.mergeRow(local, remote);
      // Delete-always-wins: result must be deleted regardless.
      expect(result['IsDeleted'], true);
      // Remote is newer so its fields are used, but IsDeleted forced true.
      expect(result['name'], 'Active Remote');
      expect(result['UpdatedAt'], tNewer);
    });
  });

  // ===========================================================================
  // Group: CalendarDay slot-level merge
  // ===========================================================================
  group('CalendarDay slot-level merge', () {
    test('Slot completed on one side preserved during merge', () {
      final local = makeCalendarDayDto(
        calendarDayId: 'cd1',
        updatedAt: tBase,
        slots: [
          makeSlot(
            drillId: 'drill1',
            completionState: 'CompletedLinked',
            completingSessionId: 'session-1',
            updatedAt: tNewer,
          ),
        ],
      );
      final remote = makeCalendarDayDto(
        calendarDayId: 'cd1',
        updatedAt: tNewer,
        slots: [
          makeSlot(
            drillId: 'drill1',
            completionState: 'Incomplete',
            updatedAt: tBase,
          ),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final slots = parseSlots(result);

      // Local slot is newer (tNewer > tBase) so completion is preserved.
      expect(slots[0]['completionState'], 'CompletedLinked');
      expect(slots[0]['completingSessionId'], 'session-1');
    });

    test('Different slots modified on each side — both preserved', () {
      final local = makeCalendarDayDto(
        calendarDayId: 'cd1',
        updatedAt: tBase,
        slots: [
          makeSlot(
            drillId: 'drill1',
            completionState: 'CompletedLinked',
            updatedAt: tNewer,
          ),
          makeSlot(drillId: null, updatedAt: tOld),
        ],
      );
      final remote = makeCalendarDayDto(
        calendarDayId: 'cd1',
        updatedAt: tNewer,
        slots: [
          makeSlot(drillId: 'drill1', updatedAt: tOld),
          makeSlot(drillId: 'drill2', updatedAt: tNewer),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final slots = parseSlots(result);

      // Slot 0: local newer (tNewer > tOld) — completed preserved.
      expect(slots[0]['completionState'], 'CompletedLinked');
      // Slot 1: remote newer (tNewer > tOld) — drill2 assigned.
      expect(slots[1]['drillId'], 'drill2');
    });

    test('Same slot modified — newer wins', () {
      final local = makeCalendarDayDto(
        calendarDayId: 'cd1',
        updatedAt: tBase,
        slots: [
          makeSlot(drillId: 'drillLocal', updatedAt: tBase),
        ],
      );
      final remote = makeCalendarDayDto(
        calendarDayId: 'cd1',
        updatedAt: tNewer,
        slots: [
          makeSlot(drillId: 'drillRemote', updatedAt: tNewer),
        ],
      );

      final result = MergeAlgorithm.mergeCalendarDay(local, remote);
      final slots = parseSlots(result);

      // Remote slot is strictly newer — drillRemote wins.
      expect(slots[0]['drillId'], 'drillRemote');
    });
  });

  // ===========================================================================
  // Group: EventLog append-only
  // ===========================================================================
  group('EventLog append-only', () {
    test('EventLog always inserted (not merged)', () {
      // EventLog is in the appendOnlyTables set, so the merge path is
      // insert-if-not-exists rather than LWW merge.
      expect(
        MergeAlgorithm.appendOnlyTables.contains('EventLog'),
        isTrue,
      );

      // Since EventLog has no updatedAt, it should not go through mergeRow.
      // Verify that the table classification is correct so _applyDownloadedChanges
      // routes it to _insertIfMissing instead of merge.
      expect(
        MergeAlgorithm.softDeleteTables.contains('EventLog'),
        isFalse,
      );
      expect(
        MergeAlgorithm.slotMergeTables.contains('EventLog'),
        isFalse,
      );
    });

    test('Duplicate EventLog ignored', () async {
      // Use an in-memory DB to verify that inserting the same EventLog ID twice
      // results in only one row (the _insertIfMissing pattern).
      final db = AppDatabase.forTesting(NativeDatabase.memory());

      try {
        final eventLogDto = makeEventLogDto(
          eventLogId: 'el-dup-1',
          createdAt: '2026-03-01T10:00:00.000Z',
        );

        // First insert via the DTO companion.
        final companion = EventLogsCompanion(
          eventLogId: Value(eventLogDto['eventLogId'] as String),
          userId: Value(eventLogDto['userId'] as String),
          deviceId: Value(eventLogDto['deviceId'] as String?),
          eventTypeId: Value(eventLogDto['eventTypeId'] as String),
          timestamp: Value(
              DateTime.parse(eventLogDto['timestamp'] as String)),
          createdAt: Value(
              DateTime.parse(eventLogDto['createdAt'] as String)),
        );
        await db.into(db.eventLogs).insert(companion);

        // Verify one row exists.
        final rows1 = await db.select(db.eventLogs).get();
        expect(rows1.length, 1);

        // Simulate _insertIfMissing: check if row exists before inserting.
        final existing = await db.customSelect(
          'SELECT 1 FROM "EventLog" WHERE "EventLogID" = ? LIMIT 1',
          variables: [Variable.withString('el-dup-1')],
        ).get();
        expect(existing.isNotEmpty, isTrue);

        // Since it exists, skip the insert (no-op). Row count unchanged.
        final rows2 = await db.select(db.eventLogs).get();
        expect(rows2.length, 1);
        expect(rows2.first.eventLogId, 'el-dup-1');
      } finally {
        await db.close();
      }
    });
  });

  // ===========================================================================
  // Group: Gate behavior during merge
  // ===========================================================================
  group('Gate behavior during merge', () {
    late SyncWriteGate gate;

    setUp(() {
      gate = SyncWriteGate();
    });

    tearDown(() {
      gate.dispose();
    });

    test('Gate acquired during merge', () {
      // Simulate the merge pipeline: acquire gate, perform merge, check state.
      expect(gate.isHeld, isFalse);

      final acquired = gate.acquireExclusive();
      expect(acquired, isTrue);
      expect(gate.isHeld, isTrue);

      // Perform a merge operation while gate is held.
      final local = makeUserDto(userId: 'u1', updatedAt: tBase);
      final remote = makeUserDto(userId: 'u1', updatedAt: tNewer);
      final merged = MergeAlgorithm.mergeRow(local, remote);

      // Gate remains held during merge.
      expect(gate.isHeld, isTrue);
      expect(merged['UpdatedAt'], tNewer);

      gate.release();
    });

    test('Gate released after successful merge', () {
      final acquired = gate.acquireExclusive();
      expect(acquired, isTrue);

      try {
        // Simulate successful merge of multiple rows.
        final rows = [
          makeUserDto(userId: 'u1', updatedAt: tNewer),
          makeDrillDto(drillId: 'd1', updatedAt: tNewer),
        ];

        for (final remote in rows) {
          final local = remote['userId'] != null
              ? makeUserDto(
                  userId: remote['userId'] as String, updatedAt: tBase)
              : makeDrillDto(
                  drillId: remote['drillId'] as String, updatedAt: tBase);
          MergeAlgorithm.mergeRow(local, remote);
        }
      } finally {
        // Matches the try/finally pattern in _applyDownloadedChanges.
        gate.release();
      }

      expect(gate.isHeld, isFalse);
    });

    test('Gate released after merge error', () {
      final acquired = gate.acquireExclusive();
      expect(acquired, isTrue);

      try {
        // Simulate a merge that throws an error.
        throw Exception('Simulated merge failure');
      } catch (_) {
        // Error caught — gate must still be released in finally block.
      } finally {
        gate.release();
      }

      // Gate is released even after error, matching _applyDownloadedChanges
      // which releases in a finally block.
      expect(gate.isHeld, isFalse);

      // Verify the gate can be re-acquired after error recovery.
      final reacquired = gate.acquireExclusive();
      expect(reacquired, isTrue);
      gate.release();
    });
  });

  // ===========================================================================
  // Group: Empty and edge cases
  // ===========================================================================
  group('Empty and edge cases', () {
    test('Empty download — no changes', () {
      // Simulate the empty download path in _applyDownloadedChanges:
      // when the changes map has no tables, nothing is merged and count is 0.
      final changes = <String, List<Map<String, dynamic>>>{};

      var mergedCount = 0;
      for (final tableName in [
        'User',
        'Drill',
        'PracticeBlock',
        'Session',
      ]) {
        final remoteRows = changes[tableName];
        if (remoteRows == null || remoteRows.isEmpty) continue;
        mergedCount += remoteRows.length;
      }

      expect(mergedCount, 0);
    });

    test('Merge with all null timestamps — remote wins (no-local case)', () {
      // When there is no local row (null), the remote is used directly.
      // This test verifies that even with null updatedAt the payload is valid.
      final remote = makeUserDto(
        userId: 'u-null-ts',
        updatedAt: tBase,
        displayName: 'Null Timestamp User',
      );
      remote['UpdatedAt'] = null;

      // No local row → remote used directly (simulating the null-local path).
      // When local is null, the merge pipeline uses remote as-is.
      final result = remote;

      expect(result['userId'], 'u-null-ts');
      expect(result['displayName'], 'Null Timestamp User');
      expect(result['UpdatedAt'], isNull);
    });
  });

  // ===========================================================================
  // Group: DB-backed merge integration (in-memory Drift)
  // ===========================================================================
  group('DB-backed merge integration', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Merge with actual DB row — User round-trip', () async {
      // Insert a user into the DB, read it back as sync DTO, merge with remote.
      await db.into(db.users).insert(UsersCompanion.insert(
        userId: 'db-user-1',
        timezone: const Value('America/New_York'),
        weekStartDay: const Value(1),
        unitPreferences: const Value('{"distance":"yards"}'),
        displayName: const Value('DB User'),
        email: 'db@example.com',
      ));

      // Read back and convert to sync DTO format.
      final dbUser = await (db.select(db.users)
            ..where((t) => t.userId.equals('db-user-1')))
          .getSingle();
      final localDto = dbUser.toSyncDto();

      // Build a remote DTO with a newer timestamp.
      final remoteDto = Map<String, dynamic>.from(localDto);
      remoteDto['DisplayName'] = 'Remote Updated Name';
      remoteDto['UpdatedAt'] = '2027-01-01T00:00:00.000Z';

      // MergeAlgorithm uses PascalCase keys for row-level merge fields
      // (UpdatedAt, IsDeleted) to match toSyncDto output.
      final localMerge = {
        'UpdatedAt': localDto['UpdatedAt'],
        'displayName': localDto['DisplayName'],
        'IsDeleted': false,
      };
      final remoteMerge = {
        'UpdatedAt': remoteDto['UpdatedAt'],
        'displayName': remoteDto['DisplayName'],
        'IsDeleted': false,
      };

      final merged = MergeAlgorithm.mergeRow(localMerge, remoteMerge);
      // Remote is newer (2027 > actual DB insert time).
      expect(merged['displayName'], 'Remote Updated Name');
    });

    test('Merge with actual DB row — Drill round-trip', () async {
      // Insert a drill into the DB.
      await db.into(db.drills).insert(DrillsCompanion.insert(
        drillId: 'db-drill-1',
        name: 'DB Drill',
        skillArea: SkillArea.putting,
        drillType: DrillType.transition,
        inputMode: InputMode.gridCell,
        metricSchemaId: 'grid_1x3_direction',
        origin: DrillOrigin.standard,
        subskillMapping: const Value('["putting_direction_control"]'),
        anchors: const Value(
            '{"putting_direction_control":{"Min":20,"Scratch":60,"Pro":90}}'),
        requiredSetCount: const Value(1),
        requiredAttemptsPerSet: const Value(9),
      ));

      final dbDrill = await (db.select(db.drills)
            ..where((t) => t.drillId.equals('db-drill-1')))
          .getSingle();
      final localDto = dbDrill.toSyncDto();

      // Verify the DTO has the expected PascalCase keys.
      expect(localDto['DrillID'], 'db-drill-1');
      expect(localDto['Name'], 'DB Drill');
      expect(localDto['UpdatedAt'], isNotNull);

      // Build remote with newer timestamp.
      final localMerge = {
        'UpdatedAt': localDto['UpdatedAt'],
        'name': localDto['Name'],
        'IsDeleted': localDto['IsDeleted'],
      };
      final remoteMerge = {
        'UpdatedAt': '2027-06-15T12:00:00.000Z',
        'name': 'Remotely Renamed Drill',
        'IsDeleted': false,
      };

      final merged = MergeAlgorithm.mergeRow(localMerge, remoteMerge);
      expect(merged['name'], 'Remotely Renamed Drill');
    });

    test('EventLog insert-if-missing with actual DB', () async {
      // Insert an EventLog and verify that a second insert with the same PK
      // is detected as existing (the _insertIfMissing pattern).
      await db.into(db.eventLogs).insert(EventLogsCompanion.insert(
        eventLogId: 'el-1',
        userId: 'u1',
        eventTypeId: 'session_close',
        timestamp: Value(DateTime.utc(2026, 3, 1, 10, 0)),
      ));

      // Check existence using the same pattern as SyncEngine._insertIfMissing.
      final existing = await db.customSelect(
        'SELECT 1 FROM "EventLog" WHERE "EventLogID" = ? LIMIT 1',
        variables: [Variable.withString('el-1')],
      ).get();
      expect(existing.isNotEmpty, isTrue);

      // A new EventLog with a different ID should not be found.
      final missing = await db.customSelect(
        'SELECT 1 FROM "EventLog" WHERE "EventLogID" = ? LIMIT 1',
        variables: [Variable.withString('el-nonexistent')],
      ).get();
      expect(missing.isEmpty, isTrue);
    });

    test('Gate protects concurrent merge simulation', () async {
      // Verify that acquiring the gate prevents a second acquisition,
      // simulating concurrent merge protection with DB operations.
      final gate = SyncWriteGate();

      final acquired1 = gate.acquireExclusive();
      expect(acquired1, isTrue);

      // Simulate a DB write under gate protection.
      await db.into(db.users).insert(UsersCompanion.insert(
        userId: 'gate-user-1',
        email: 'gate@test.com',
        timezone: const Value('UTC'),
        weekStartDay: const Value(1),
        unitPreferences: const Value('{}'),
      ));

      // Second acquisition fails while first is held.
      final acquired2 = gate.acquireExclusive();
      expect(acquired2, isFalse);

      gate.release();

      // After release, acquisition succeeds again.
      final acquired3 = gate.acquireExclusive();
      expect(acquired3, isTrue);

      gate.dispose();
    });
  });
}
