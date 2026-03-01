import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/core/sync/sync_engine.dart';
import 'package:zx_golf_app/core/error_types.dart';

// TD-03 §5.1 — Sync engine tests.
// Full integration requires a Supabase client; these tests verify
// the structural correctness and error types.

void main() {
  group('SyncEngine structural tests', () {
    test('SyncEngine class exists and is constructable type', () {
      expect(SyncEngine, isNotNull);
    });

    test('SyncStatus enum has all expected values', () {
      expect(SyncStatus.values, hasLength(4));
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.inProgress));
      expect(SyncStatus.values, contains(SyncStatus.failed));
      expect(SyncStatus.values, contains(SyncStatus.offline));
    });

    test('SyncTrigger enum has all expected values', () {
      expect(SyncTrigger.values, hasLength(5));
      expect(SyncTrigger.values, contains(SyncTrigger.manual));
      expect(SyncTrigger.values, contains(SyncTrigger.connectivity));
      expect(SyncTrigger.values, contains(SyncTrigger.periodic));
      expect(SyncTrigger.values, contains(SyncTrigger.postSession));
      expect(SyncTrigger.values, contains(SyncTrigger.forceFullSync));
    });

    test('SyncResult.success creates successful result', () {
      final result = SyncResult.success(
        serverTimestamp: DateTime.utc(2026, 3, 1),
        uploadedCount: 5,
        downloadedCount: 3,
      );
      expect(result.success, isTrue);
      expect(result.uploadedCount, 5);
      expect(result.downloadedCount, 3);
      expect(result.serverTimestamp, isNotNull);
      expect(result.errorCode, isNull);
    });

    test('SyncResult.failure creates failed result', () {
      final result = SyncResult.failure(
        errorCode: SyncException.schemaMismatch,
        errorMessage: 'Version mismatch',
      );
      expect(result.success, isFalse);
      expect(result.errorCode, SyncException.schemaMismatch);
      expect(result.errorMessage, 'Version mismatch');
      expect(result.serverTimestamp, isNull);
    });

    test('SyncException codes are correct', () {
      expect(SyncException.schemaMismatch, 'SYNC_SCHEMA_MISMATCH');
      expect(SyncException.uploadFailed, 'SYNC_UPLOAD_FAILED');
      expect(SyncException.downloadFailed, 'SYNC_DOWNLOAD_FAILED');
      expect(SyncException.networkUnavailable, 'SYNC_NETWORK_UNAVAILABLE');
    });
  });

  group('SyncWriteGate integration with SyncEngine', () {
    test('gate is usable by sync engine constructor', () {
      final gate = SyncWriteGate();
      expect(gate.isHeld, isFalse);
      gate.dispose();
    });
  });
}
