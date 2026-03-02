import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase 7A — Sync feature flag persistence tests.

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Sync feature flag', () {
    test('default value is enabled (no row means enabled)', () async {
      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.syncEnabled)))
          .getSingleOrNull();
      // No row means default: enabled.
      expect(row, isNull);
    });

    test('persist disabled toggle', () async {
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.syncEnabled,
              value: 'false',
            ),
          );

      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.syncEnabled)))
          .getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.value, 'false');
    });

    test('persist enabled toggle', () async {
      // First disable.
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.syncEnabled,
              value: 'false',
            ),
          );

      // Then re-enable.
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.syncEnabled,
              value: 'true',
            ),
          );

      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.syncEnabled)))
          .getSingleOrNull();
      expect(row!.value, 'true');
    });

    test('disable then enable round-trip', () async {
      // Enable → disable → enable.
      for (final value in ['true', 'false', 'true']) {
        await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
              SyncMetadataEntriesCompanion.insert(
                key: SyncMetadataKeys.syncEnabled,
                value: value,
              ),
            );

        final row = await (db.select(db.syncMetadataEntries)
              ..where((t) => t.key.equals(SyncMetadataKeys.syncEnabled)))
            .getSingleOrNull();
        expect(row!.value, value);
      }
    });

    test('consecutive failures persists alongside feature flag', () async {
      // Set both keys.
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.consecutiveFailures,
              value: '5',
            ),
          );
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.syncEnabled,
              value: 'false',
            ),
          );

      // Read both.
      final failures = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.consecutiveFailures)))
          .getSingleOrNull();
      final enabled = await (db.select(db.syncMetadataEntries)
            ..where((t) => t.key.equals(SyncMetadataKeys.syncEnabled)))
          .getSingleOrNull();

      expect(failures!.value, '5');
      expect(enabled!.value, 'false');
    });
  });
}
