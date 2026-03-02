import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';

// Phase 7A — SyncEngine payload batching tests.
// Pure Dart tests — no mocks needed.

void main() {
  group('SyncEngine.batchPayload', () {
    // Helper: create a payload with a given table and row count.
    Map<String, List<Map<String, dynamic>>> makePayload(
      Map<String, int> tableCounts, {
      int rowSizeChars = 100,
    }) {
      final payload = <String, List<Map<String, dynamic>>>{};
      for (final entry in tableCounts.entries) {
        payload[entry.key] = List.generate(
          entry.value,
          (i) => {
            'id': 'row-$i',
            'data': 'x' * rowSizeChars,
          },
        );
      }
      return payload;
    }

    test('empty payload returns single batch', () {
      final batches = SyncEngine.staticBatchPayload({});
      expect(batches, hasLength(1));
      expect(batches.first, isEmpty);
    });

    test('small payload stays in single batch', () {
      final payload = makePayload({'User': 5, 'Drill': 3});
      final batches = SyncEngine.staticBatchPayload(payload);
      expect(batches, hasLength(1));
      expect(batches.first.keys, containsAll(['User', 'Drill']));
    });

    test('payload under 2MB limit is single batch', () {
      // Each row ~120 chars, 100 rows per table, 5 tables = ~60KB
      final payload = makePayload({
        'User': 100,
        'Drill': 100,
        'Session': 100,
        'Instance': 100,
        'PracticeEntry': 100,
      });
      final totalSize = jsonEncode(payload).length;
      expect(totalSize, lessThan(kSyncMaxPayloadBytes));

      final batches = SyncEngine.staticBatchPayload(payload);
      expect(batches, hasLength(1));
    });

    test('large payload splits into multiple batches', () {
      // Create payload > 2MB by making large rows.
      // 2MB = 2097152 bytes. Make 3 tables each ~1MB.
      final payload = makePayload(
        {'User': 100, 'Drill': 100, 'Session': 100},
        rowSizeChars: 8000,
      );
      final totalSize = jsonEncode(payload).length;
      expect(totalSize, greaterThan(kSyncMaxPayloadBytes));

      final batches = SyncEngine.staticBatchPayload(payload);
      expect(batches.length, greaterThan(1));

      // All tables are present across all batches.
      final allKeys = batches.expand((b) => b.keys).toSet();
      expect(allKeys, containsAll(['User', 'Drill', 'Session']));
    });

    test('tables never split mid-table', () {
      final payload = makePayload(
        {'User': 200, 'Drill': 200},
        rowSizeChars: 8000,
      );

      final batches = SyncEngine.staticBatchPayload(payload);
      for (final batch in batches) {
        for (final table in batch.keys) {
          // Each table should have its full row count.
          expect(batch[table]!.length, equals(200));
        }
      }
    });

    test('parent tables come before child tables in ordering', () {
      final payload = makePayload(
        {
          'Instance': 10,
          'User': 10,
          'Session': 10,
          'Drill': 10,
          'PracticeBlock': 10,
        },
        rowSizeChars: 200000, // Make each table ~2MB to force multi-batch
      );

      final batches = SyncEngine.staticBatchPayload(payload);

      // Collect table order across all batches.
      final tableOrder = <String>[];
      for (final batch in batches) {
        tableOrder.addAll(batch.keys);
      }

      // User should appear before Drill, Drill before Session, etc.
      final userIdx = tableOrder.indexOf('User');
      final drillIdx = tableOrder.indexOf('Drill');
      final blockIdx = tableOrder.indexOf('PracticeBlock');
      final sessionIdx = tableOrder.indexOf('Session');
      final instanceIdx = tableOrder.indexOf('Instance');

      expect(userIdx, lessThan(drillIdx));
      expect(drillIdx, lessThan(blockIdx));
      expect(blockIdx, lessThan(sessionIdx));
      expect(sessionIdx, lessThan(instanceIdx));
    });

    test('tableUploadOrder has all 18 synced tables', () {
      expect(SyncEngine.tableUploadOrder, hasLength(18));
      expect(SyncEngine.tableUploadOrder, contains('User'));
      expect(SyncEngine.tableUploadOrder, contains('UserDevice'));
      expect(SyncEngine.tableUploadOrder, contains('EventLog'));
    });

    test('single table over limit gets its own batch', () {
      final payload = makePayload(
        {'User': 500},
        rowSizeChars: 5000,
      );
      final totalSize = jsonEncode(payload).length;
      expect(totalSize, greaterThan(kSyncMaxPayloadBytes));

      final batches = SyncEngine.staticBatchPayload(payload);
      // Even though one table is > 2MB, it can't be split, so it goes alone.
      expect(batches, hasLength(1));
      expect(batches.first.containsKey('User'), isTrue);
    });

    test('unknown tables sort to end', () {
      final payload = makePayload(
        {
          'UnknownTable': 5,
          'User': 5,
          'Drill': 5,
        },
        rowSizeChars: 200000, // Force multi-batch
      );

      final batches = SyncEngine.staticBatchPayload(payload);
      final tableOrder = <String>[];
      for (final batch in batches) {
        tableOrder.addAll(batch.keys);
      }

      final unknownIdx = tableOrder.indexOf('UnknownTable');
      final userIdx = tableOrder.indexOf('User');
      expect(unknownIdx, greaterThan(userIdx));
    });

    test('preserves all rows across batches', () {
      final payload = makePayload(
        {'User': 50, 'Drill': 30, 'Session': 20},
        rowSizeChars: 50000,
      );

      final batches = SyncEngine.staticBatchPayload(payload);

      var totalUserRows = 0;
      var totalDrillRows = 0;
      var totalSessionRows = 0;
      for (final batch in batches) {
        totalUserRows += (batch['User']?.length ?? 0);
        totalDrillRows += (batch['Drill']?.length ?? 0);
        totalSessionRows += (batch['Session']?.length ?? 0);
      }

      expect(totalUserRows, 50);
      expect(totalDrillRows, 30);
      expect(totalSessionRows, 20);
    });
  });
}
