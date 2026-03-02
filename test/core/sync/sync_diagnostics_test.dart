import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/instrumentation/sync_diagnostics.dart';
import 'package:zx_golf_app/core/sync/sync_types.dart';

// Phase 7A — SyncDiagnostics tests.

void main() {
  group('SyncDiagnostic', () {
    test('toString formats with elapsed and event', () {
      final diag = SyncDiagnostic(
        timestamp: DateTime.utc(2026, 3, 2),
        event: 'test_event',
        elapsed: const Duration(milliseconds: 42),
      );
      expect(diag.toString(), '[42ms] test_event');
    });

    test('toString includes data when present', () {
      final diag = SyncDiagnostic(
        timestamp: DateTime.utc(2026, 3, 2),
        event: 'upload',
        elapsed: const Duration(milliseconds: 100),
        data: {'count': 5},
      );
      expect(diag.toString(), contains('upload'));
      expect(diag.toString(), contains('{count: 5}'));
    });
  });

  group('SyncInstrumentation', () {
    late SyncInstrumentation instrumentation;

    setUp(() {
      instrumentation = SyncInstrumentation();
    });

    test('starts with empty diagnostics', () {
      expect(instrumentation.diagnostics, isEmpty);
    });

    test('record adds diagnostic', () {
      instrumentation.record(SyncDiagnostic(
        timestamp: DateTime.now(),
        event: 'test',
        elapsed: Duration.zero,
      ));
      expect(instrumentation.diagnostics, hasLength(1));
      expect(instrumentation.diagnostics.first.event, 'test');
    });

    test('emit creates and records diagnostic', () {
      instrumentation.emit('sync_start', const Duration(milliseconds: 10), {
        'trigger': 'manual',
      });
      expect(instrumentation.diagnostics, hasLength(1));
      expect(instrumentation.diagnostics.first.event, 'sync_start');
      expect(instrumentation.diagnostics.first.data['trigger'], 'manual');
    });

    test('emitCycleSummary records comprehensive summary', () {
      instrumentation.emitCycleSummary(
        trigger: SyncTrigger.postSession,
        totalDuration: const Duration(seconds: 2),
        success: true,
        uploadedCount: 10,
        downloadedCount: 5,
        payloadBytes: 1024,
        batchCount: 1,
        consecutiveFailures: 0,
      );

      expect(instrumentation.diagnostics, hasLength(1));
      final diag = instrumentation.diagnostics.first;
      expect(diag.event, 'sync_cycle_complete');
      expect(diag.data['trigger'], 'postSession');
      expect(diag.data['success'], true);
      expect(diag.data['uploadedCount'], 10);
      expect(diag.data['downloadedCount'], 5);
      expect(diag.data['payloadBytes'], 1024);
    });

    test('emitCycleSummary includes errorCode when provided', () {
      instrumentation.emitCycleSummary(
        trigger: SyncTrigger.periodic,
        totalDuration: const Duration(seconds: 1),
        success: false,
        errorCode: 'SYNC_UPLOAD_FAILED',
      );

      final diag = instrumentation.diagnostics.first;
      expect(diag.data['errorCode'], 'SYNC_UPLOAD_FAILED');
      expect(diag.data['success'], false);
    });

    test('clear removes all diagnostics', () {
      instrumentation.emit('a', Duration.zero);
      instrumentation.emit('b', Duration.zero);
      expect(instrumentation.diagnostics, hasLength(2));

      instrumentation.clear();
      expect(instrumentation.diagnostics, isEmpty);
    });

    test('enabled toggle works', () {
      expect(instrumentation.enabled, false);
      instrumentation.enabled = true;
      expect(instrumentation.enabled, true);
    });

    test('diagnostics list is unmodifiable', () {
      instrumentation.emit('test', Duration.zero);
      expect(
        () => instrumentation.diagnostics.add(SyncDiagnostic(
          timestamp: DateTime.now(),
          event: 'illegal',
          elapsed: Duration.zero,
        )),
        throwsUnsupportedError,
      );
    });
  });
}
