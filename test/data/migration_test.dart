import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase 8 — Migration infrastructure tests. TD-06 §18.

void main() {
  group('Migration Infrastructure', () {
    test('schemaVersion is 8 after window size migration', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      expect(db.schemaVersion, 8);
    });

    test('onCreate creates all tables and seeds reference data', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Verify reference data was seeded.
      final subskillRefs = await db.select(db.subskillRefs).get();
      expect(subskillRefs.length, 19);

      final eventTypeRefs = await db.select(db.eventTypeRefs).get();
      expect(eventTypeRefs.length, 16);
    });

    test('allocation invariant holds after fresh creation', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      final refs = await db.select(db.subskillRefs).get();
      final totalAllocation =
          refs.fold<int>(0, (sum, r) => sum + r.allocation);
      expect(totalAllocation, 1000);
    });

    test('all 34 tables are created', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      // Query sqlite_master for table count.
      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      ).get();

      // 34 Drift tables (26 from DDL + SyncMetadata + 7 Matrix tables).
      expect(tables.length, 34);
    });

    test('migration strategy has onUpgrade handler', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() => db.close());

      // The migration strategy is set — this test verifies it compiles
      // and the handler is defined (future migrations will add cases).
      expect(db.migration, isNotNull);
    });
  });
}
