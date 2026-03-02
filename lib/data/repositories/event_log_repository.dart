import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.2 — Event log repository.
// Manages: EventLog.
// Spec: S07 §7.9 — Append-only: create + watch. No update, no delete.
class EventLogRepository {
  final AppDatabase _db;
  final SyncWriteGate _gate;

  EventLogRepository(this._db, this._gate);

  // Spec: S07 §7.9 — Append event log entry. Append-only, no update.
  Future<EventLog> create(EventLogsCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.eventLogs).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create event log entry',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve event log by primary key.
  Future<EventLog?> getById(String id) {
    return (_db.select(_db.eventLogs)
          ..where((t) => t.eventLogId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of all event logs for a user.
  Stream<List<EventLog>> watchByUser(String userId) {
    return (_db.select(_db.eventLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  // TD-03 §3.2 — Reactive stream of all event logs.
  Stream<List<EventLog>> watchAll() {
    return (_db.select(_db.eventLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }

  // Spec: S07 §7.9 — Event logs by type.
  Stream<List<EventLog>> watchByEventType(String eventTypeId) {
    return (_db.select(_db.eventLogs)
          ..where((t) => t.eventTypeId.equals(eventTypeId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)]))
        .watch();
  }
}
