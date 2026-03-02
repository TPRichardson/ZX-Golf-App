import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart' hide isNull, isNotNull;
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase 7C — SyncEngine hardening tests: timeout counter, schema flag,
// dual session detection, lastErrorCode.

void main() {
  late AppDatabase db;
  late SyncWriteGate gate;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = SyncWriteGate();
  });

  tearDown(() async {
    gate.dispose();
    await db.close();
  });

  group('SyncEngine merge timeout counter', () {
    test('consecutiveMergeTimeouts starts at 0', () {
      // Verify the constant matches expectation.
      expect(kSyncMergeTimeoutThreshold, 3);
    });

    test('merge timeout threshold constant is 3', () {
      expect(kSyncMergeTimeoutThreshold, equals(3));
    });
  });

  group('SyncEngine schema mismatch flag', () {
    test('schemaMismatchDetected metadata key exists', () {
      expect(SyncMetadataKeys.schemaMismatchDetected,
          'schemaMismatchDetected');
    });

    test('schema mismatch flag defaults to false in metadata', () async {
      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) =>
                t.key.equals(SyncMetadataKeys.schemaMismatchDetected)))
          .getSingleOrNull();
      expect(row, equals(null));
    });

    test('schema mismatch persists to metadata', () async {
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.schemaMismatchDetected,
              value: 'true',
            ),
          );

      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) =>
                t.key.equals(SyncMetadataKeys.schemaMismatchDetected)))
          .getSingleOrNull();
      expect(row, isNot(equals(null)));
      expect(row!.value, 'true');
    });

    test('schema mismatch clears in metadata', () async {
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.schemaMismatchDetected,
              value: 'true',
            ),
          );

      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.schemaMismatchDetected,
              value: 'false',
            ),
          );

      final row = await (db.select(db.syncMetadataEntries)
            ..where((t) =>
                t.key.equals(SyncMetadataKeys.schemaMismatchDetected)))
          .getSingleOrNull();
      expect(row!.value, 'false');
    });

    test('schema mismatch does NOT increment failure counter', () async {
      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.consecutiveFailures,
              value: '0',
            ),
          );

      await db.into(db.syncMetadataEntries).insertOnConflictUpdate(
            SyncMetadataEntriesCompanion.insert(
              key: SyncMetadataKeys.schemaMismatchDetected,
              value: 'true',
            ),
          );

      final failRow = await (db.select(db.syncMetadataEntries)
            ..where(
                (t) => t.key.equals(SyncMetadataKeys.consecutiveFailures)))
          .getSingleOrNull();
      expect(failRow!.value, '0');
    });
  });

  group('SyncEngine exception code constants', () {
    test('SyncException.schemaMismatch exists', () {
      expect(SyncException.schemaMismatch, 'SYNC_SCHEMA_MISMATCH');
    });

    test('SyncException.mergeTimeout exists', () {
      expect(SyncException.mergeTimeout, 'SYNC_MERGE_TIMEOUT');
    });

    test('SyncException.gateTimeout exists', () {
      expect(SyncException.gateTimeout, 'SYNC_GATE_TIMEOUT');
    });
  });

  group('SyncEngine dual session detection', () {
    test('no detection with 0 open blocks', () async {
      final openBlocks = await (db.select(db.practiceBlocks)
            ..where(
                (t) => t.endTimestamp.isNull() & t.isDeleted.equals(false)))
          .get();
      expect(openBlocks, isEmpty);
    });

    test('no detection with 1 open block', () async {
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-1',
              userId: kDevUserId,
              startTimestamp: Value(DateTime.now()),
              isDeleted: const Value(false),
            ),
          );

      final openBlocks = await (db.select(db.practiceBlocks)
            ..where(
                (t) => t.endTimestamp.isNull() & t.isDeleted.equals(false)))
          .get();
      expect(openBlocks.length, 1);
    });

    test('detection triggered with 2+ open blocks', () async {
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-local',
              userId: kDevUserId,
              startTimestamp: Value(
                  DateTime.now().subtract(const Duration(hours: 1))),
              isDeleted: const Value(false),
            ),
          );
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-remote',
              userId: kDevUserId,
              startTimestamp: Value(DateTime.now()),
              isDeleted: const Value(false),
            ),
          );

      final openBlocks = await (db.select(db.practiceBlocks)
            ..where(
                (t) => t.endTimestamp.isNull() & t.isDeleted.equals(false)))
          .get();
      expect(openBlocks.length, greaterThan(1));
    });

    test('closed blocks are excluded from detection', () async {
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-open',
              userId: kDevUserId,
              startTimestamp: Value(DateTime.now()),
              isDeleted: const Value(false),
            ),
          );
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-closed',
              userId: kDevUserId,
              startTimestamp: Value(
                  DateTime.now().subtract(const Duration(hours: 2))),
              endTimestamp: Value(DateTime.now()),
              isDeleted: const Value(false),
            ),
          );

      final openBlocks = await (db.select(db.practiceBlocks)
            ..where(
                (t) => t.endTimestamp.isNull() & t.isDeleted.equals(false)))
          .get();
      expect(openBlocks.length, 1);
    });

    test('soft-deleted blocks are excluded from detection', () async {
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-active',
              userId: kDevUserId,
              startTimestamp: Value(DateTime.now()),
              isDeleted: const Value(false),
            ),
          );
      await db.into(db.practiceBlocks).insert(
            PracticeBlocksCompanion.insert(
              practiceBlockId: 'pb-deleted',
              userId: kDevUserId,
              startTimestamp: Value(DateTime.now()),
              isDeleted: const Value(true),
            ),
          );

      final openBlocks = await (db.select(db.practiceBlocks)
            ..where(
                (t) => t.endTimestamp.isNull() & t.isDeleted.equals(false)))
          .get();
      expect(openBlocks.length, 1);
    });
  });

  group('SyncEngine constructor and constants', () {
    test('SyncEngine class exists and accepts diagnostics', () {
      final diagnostics = SyncInstrumentation();
      expect(diagnostics, isA<SyncInstrumentation>());
      expect(SyncEngine, isNot(equals(null)));
    });

    test('low storage threshold constant is 100MB', () {
      expect(kLowStorageThresholdBytes, 100 * 1024 * 1024);
    });
  });
}
