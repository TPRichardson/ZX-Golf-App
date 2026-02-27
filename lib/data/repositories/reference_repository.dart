import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §3.2 — Reference data repository.
// Manages: EventTypeRef, MetricSchema, SubskillRef.
// Read-only: watchAll, getById for each. No create/update/delete.
// Reference data is seeded at database creation (see seed_data.dart).
class ReferenceRepository {
  final AppDatabase _db;

  ReferenceRepository(this._db);

  // ---------------------------------------------------------------------------
  // EventTypeRef — read-only
  // ---------------------------------------------------------------------------

  // Spec: S07 §7.9 — Retrieve event type by primary key.
  Future<EventTypeRef?> getEventTypeById(String id) {
    return (_db.select(_db.eventTypeRefs)
          ..where((t) => t.eventTypeId.equals(id)))
        .getSingleOrNull();
  }

  // Spec: S07 §7.9 — Reactive stream of all event types.
  Stream<List<EventTypeRef>> watchAllEventTypes() {
    return _db.select(_db.eventTypeRefs).watch();
  }

  // ---------------------------------------------------------------------------
  // MetricSchema — read-only
  // ---------------------------------------------------------------------------

  // Spec: S04 §4.3 — Retrieve metric schema by primary key.
  Future<MetricSchema?> getMetricSchemaById(String id) {
    return (_db.select(_db.metricSchemas)
          ..where((t) => t.metricSchemaId.equals(id)))
        .getSingleOrNull();
  }

  // Spec: S04 §4.3 — Reactive stream of all metric schemas.
  Stream<List<MetricSchema>> watchAllMetricSchemas() {
    return _db.select(_db.metricSchemas).watch();
  }

  // ---------------------------------------------------------------------------
  // SubskillRef — read-only
  // ---------------------------------------------------------------------------

  // Spec: S02 §2.3 — Retrieve subskill reference by primary key.
  Future<SubskillRef?> getSubskillById(String id) {
    return (_db.select(_db.subskillRefs)
          ..where((t) => t.subskillId.equals(id)))
        .getSingleOrNull();
  }

  // Spec: S02 §2.3 — Reactive stream of all subskill references.
  Stream<List<SubskillRef>> watchAllSubskills() {
    return _db.select(_db.subskillRefs).watch();
  }

  // Spec: S02 §2.3 — Subskill references filtered by skill area.
  Stream<List<SubskillRef>> watchSubskillsBySkillArea(SkillArea skillArea) {
    return (_db.select(_db.subskillRefs)
          ..where((t) => t.skillArea.equalsValue(skillArea)))
        .watch();
  }
}
