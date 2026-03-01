import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/scoring/reflow_engine.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';

// TD-03 §3.3.2 — Drill definition repository.
// Manages: Drill, UserDrillAdoption, MetricSchema (read-only).
// Phase 3: Full business methods with state machine guards,
// immutability enforcement, anchor governance, and reflow triggers.

/// Helper class for drill + adoption join results.
class DrillWithAdoption {
  final Drill drill;
  final UserDrillAdoption? adoption;

  const DrillWithAdoption({required this.drill, this.adoption});
}

class DrillRepository {
  final AppDatabase _db;
  final EventLogRepository _eventLogRepo;
  final ReflowEngine _reflowEngine;

  static const _uuid = Uuid();

  DrillRepository(this._db, this._eventLogRepo, this._reflowEngine);

  // ---------------------------------------------------------------------------
  // Drill business methods — TD-03 §3.3.2
  // ---------------------------------------------------------------------------

  // TD-03 §3.3.2 — Reactive stream of user's accessible drills.
  // Returns system drills (userId=null) + user's custom drills. Excludes isDeleted.
  Stream<List<Drill>> watchUserDrills(
    String userId, {
    SkillArea? filter,
    DrillStatus? status,
  }) {
    return _db.customSelect(
      'SELECT * FROM Drill WHERE IsDeleted = 0 '
      'AND (UserID IS NULL OR UserID = ?) '
      '${filter != null ? 'AND SkillArea = ? ' : ''}'
      '${status != null ? 'AND Status = ? ' : ''}'
      'ORDER BY Origin ASC, Name ASC',
      variables: [
        Variable.withString(userId),
        if (filter != null) Variable.withString(filter.dbValue),
        if (status != null) Variable.withString(status.dbValue),
      ],
      readsFrom: {_db.drills},
    ).watch().map((rows) => rows.map((row) {
          return _db.drills.map(row.data);
        }).toList());
  }

  // TD-03 §3.3.2 — Reactive stream of adopted drills.
  // JOIN Drills × UserDrillAdoptions where adoption.status=Active, isDeleted=false.
  Stream<List<DrillWithAdoption>> watchAdoptedDrills(
    String userId, {
    SkillArea? filter,
  }) {
    final query = _db.select(_db.drills).join([
      innerJoin(
        _db.userDrillAdoptions,
        _db.userDrillAdoptions.drillId.equalsExp(_db.drills.drillId),
      ),
    ]);
    query
      ..where(_db.userDrillAdoptions.userId.equals(userId))
      ..where(
          _db.userDrillAdoptions.status.equalsValue(AdoptionStatus.active))
      ..where(_db.userDrillAdoptions.isDeleted.equals(false))
      ..where(_db.drills.isDeleted.equals(false));
    if (filter != null) {
      query.where(_db.drills.skillArea.equalsValue(filter));
    }
    query.orderBy([OrderingTerm.asc(_db.drills.name)]);

    return query.watch().map((rows) => rows.map((row) {
          return DrillWithAdoption(
            drill: row.readTable(_db.drills),
            adoption: row.readTable(_db.userDrillAdoptions),
          );
        }).toList());
  }

  // TD-03 §3.3.2 — Reactive stream of user's practice pool.
  // Adopted system drills + active custom drills.
  Stream<List<DrillWithAdoption>> watchPracticePool(
    String userId, {
    SkillArea? filter,
  }) {
    // Custom active drills (no adoption needed).
    final customQuery = _db.select(_db.drills)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.isDeleted.equals(false))
      ..where((t) => t.status.equalsValue(DrillStatus.active))
      ..where((t) => t.origin.equalsValue(DrillOrigin.userCustom));
    if (filter != null) {
      customQuery.where((t) => t.skillArea.equalsValue(filter));
    }

    // Adopted system drills.
    final adoptedStream = watchAdoptedDrills(userId, filter: filter);
    final customStream = customQuery.watch();

    // Merge both streams.
    return adoptedStream.asyncMap((adopted) async {
      final custom = await customStream.first;
      final merged = <DrillWithAdoption>[
        ...adopted,
        ...custom.map((d) => DrillWithAdoption(drill: d)),
      ];
      merged.sort((a, b) => a.drill.name.compareTo(b.drill.name));
      return merged;
    });
  }

  // TD-03 §3.3.2 — Create a user custom drill.
  // Spec: S04 §4.2 — Validates subskill mapping, metric schema, anchors, structure.
  Future<Drill> createCustomDrill(String userId, DrillsCompanion data) async {
    // Validate subskill mapping references valid SubskillRef IDs for selected SkillArea.
    final skillArea = data.skillArea.value;
    final subskillMapping = data.subskillMapping.present
        ? _parseSubskillMapping(data.subskillMapping.value)
        : <String>{};

    if (subskillMapping.isNotEmpty) {
      final validRefs = await (_db.select(_db.subskillRefs)
            ..where((t) => t.skillArea.equalsValue(skillArea)))
          .get();
      final validIds = validRefs.map((r) => r.subskillId).toSet();
      for (final id in subskillMapping) {
        if (!validIds.contains(id)) {
          throw ValidationException(
            code: ValidationException.invalidStructure,
            message:
                'SubskillMapping references invalid subskill "$id" for SkillArea ${skillArea.dbValue}',
            context: {'subskillId': id, 'skillArea': skillArea.dbValue},
          );
        }
      }
    }

    // Validate MetricSchemaID references valid schema.
    final metricSchemaId = data.metricSchemaId.value;
    final schema = await (_db.select(_db.metricSchemas)
          ..where((t) => t.metricSchemaId.equals(metricSchemaId)))
        .getSingleOrNull();
    if (schema == null) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'MetricSchemaID "$metricSchemaId" not found',
        context: {'metricSchemaId': metricSchemaId},
      );
    }

    // Spec: S04 — TechniqueBlock validation.
    final drillType = data.drillType.value;
    if (drillType == DrillType.techniqueBlock) {
      if (data.requiredSetCount.present && data.requiredSetCount.value != 1) {
        throw ValidationException(
          code: ValidationException.invalidStructure,
          message: 'TechniqueBlock drills must have RequiredSetCount=1',
        );
      }
      if (data.requiredAttemptsPerSet.present &&
          data.requiredAttemptsPerSet.value != null) {
        throw ValidationException(
          code: ValidationException.invalidStructure,
          message:
              'TechniqueBlock drills must have RequiredAttemptsPerSet=null',
        );
      }
    }

    // Validate anchors for scored drills (Transition/Pressure).
    if (drillType != DrillType.techniqueBlock &&
        data.anchors.present &&
        data.anchors.value != '{}') {
      _validateAnchors(data.anchors.value, subskillMapping);
    }

    final drillId = _uuid.v4();
    final companion = data.copyWith(
      drillId: Value(drillId),
      userId: Value(userId),
      origin: const Value(DrillOrigin.userCustom),
      status: const Value(DrillStatus.active),
      isDeleted: const Value(false),
    );

    try {
      return await _db.transaction(() async {
        return await _db.into(_db.drills).insertReturning(companion);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create custom drill',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.2 — Update drill fields.
  // TD-04 §2.4.2 — Immutability enforcement: reject changes to structural fields.
  // S04 anchor governance — Anchor edit on Retired drill → throw.
  Future<Drill> updateDrill(
    String userId,
    String drillId,
    DrillsCompanion data,
  ) async {
    final existing = await _getActiveDrill(drillId);

    // Guard: must be user-owned custom drill.
    if (existing.origin == DrillOrigin.system) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Cannot update system drill',
        context: {'drillId': drillId},
      );
    }
    if (existing.userId != userId) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Cannot update drill owned by another user',
        context: {'drillId': drillId},
      );
    }

    // TD-04 §2.4.2 — Immutability checks.
    _rejectImmutableFieldChanges(data);

    // S04 anchor governance — Anchor edit on Retired drill → throw.
    final anchorsChanged = data.anchors.present && data.anchors.value != existing.anchors;
    if (anchorsChanged && existing.status == DrillStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Cannot edit anchors on a Retired drill',
        context: {'drillId': drillId, 'status': existing.status.dbValue},
      );
    }

    // Validate anchors if changed.
    if (anchorsChanged) {
      final subskillMapping = _parseSubskillMapping(existing.subskillMapping);
      _validateAnchors(data.anchors.value, subskillMapping);
    }

    try {
      final updated = await _db.transaction(() async {
        final rows = await (_db.update(_db.drills)
              ..where((t) => t.drillId.equals(drillId)))
            .writeReturning(data.copyWith(
          updatedAt: Value(DateTime.now()),
        ));
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Drill not found after update',
            context: {'drillId': drillId},
          );
        }
        return rows.first;
      });

      // Spec: S04 — Anchor edit triggers scoped reflow.
      if (anchorsChanged) {
        final subskillMapping = _parseSubskillMapping(existing.subskillMapping);
        if (subskillMapping.isNotEmpty) {
          await _eventLogRepo.create(EventLogsCompanion.insert(
            eventLogId: _uuid.v4(),
            userId: userId,
            eventTypeId: 'AnchorEdit',
            affectedEntityIds: Value(jsonEncode([drillId])),
            affectedSubskills:
                Value(jsonEncode(subskillMapping.toList())),
            metadata: Value(jsonEncode({
              'drillName': existing.name,
            })),
          ));

          await _reflowEngine.executeReflow(ReflowTrigger(
            type: ReflowTriggerType.anchorEdit,
            userId: userId,
            affectedSubskillIds: subskillMapping,
            drillId: drillId,
          ));
        }
      }

      return updated;
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update drill',
        context: {'drillId': drillId, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.2 / TD-04 §2.4.1 — Retire drill: Active→Retired.
  Future<Drill> retireDrill(String userId, String drillId) async {
    final existing = await _getActiveDrill(drillId);
    _guardOwnership(existing, userId);

    if (existing.status != DrillStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message:
            'Cannot retire drill: current status is ${existing.status.dbValue}',
        context: {'drillId': drillId, 'status': existing.status.dbValue},
      );
    }

    final updated = await _updateDrillStatus(drillId, DrillStatus.retired);

    // EventLog: drill retired.
    await _eventLogRepo.create(EventLogsCompanion.insert(
      eventLogId: _uuid.v4(),
      userId: userId,
      eventTypeId: 'DrillDeletion',
      affectedEntityIds: Value(jsonEncode([drillId])),
      metadata: Value(jsonEncode({
        'action': 'retire',
        'drillName': existing.name,
      })),
    ));

    return updated;
  }

  // TD-03 §3.3.2 / TD-04 §2.4.1 — Reactivate drill: Retired→Active.
  Future<Drill> reactivateDrill(String userId, String drillId) async {
    final existing = await _getActiveDrill(drillId);
    _guardOwnership(existing, userId);

    if (existing.status != DrillStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message:
            'Cannot reactivate drill: current status is ${existing.status.dbValue}',
        context: {'drillId': drillId, 'status': existing.status.dbValue},
      );
    }

    return _updateDrillStatus(drillId, DrillStatus.active);
  }

  // TD-03 §3.3.2 / TD-04 §2.4.1 — Delete drill: Active|Retired→Deleted (soft).
  // Custom only. Cascades soft-delete to adoptions. Triggers full reflow.
  Future<void> deleteDrill(String userId, String drillId) async {
    final existing = await _getActiveDrill(drillId);

    if (existing.origin == DrillOrigin.system) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Cannot delete system drill',
        context: {'drillId': drillId},
      );
    }
    _guardOwnership(existing, userId);

    if (existing.status == DrillStatus.deleted) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message: 'Drill is already deleted',
        context: {'drillId': drillId},
      );
    }

    await _db.transaction(() async {
      // Soft-delete the drill.
      await (_db.update(_db.drills)
            ..where((t) => t.drillId.equals(drillId)))
          .write(DrillsCompanion(
        status: const Value(DrillStatus.deleted),
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      // Cascade soft-delete adoptions.
      await (_db.update(_db.userDrillAdoptions)
            ..where((t) => t.drillId.equals(drillId)))
          .write(UserDrillAdoptionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));
    });

    // EventLog: drill deleted.
    await _eventLogRepo.create(EventLogsCompanion.insert(
      eventLogId: _uuid.v4(),
      userId: userId,
      eventTypeId: 'DrillDeletion',
      affectedEntityIds: Value(jsonEncode([drillId])),
      metadata: Value(jsonEncode({
        'action': 'delete',
        'drillName': existing.name,
      })),
    ));

    // Trigger full reflow.
    final subskillMapping = _parseSubskillMapping(existing.subskillMapping);
    if (subskillMapping.isNotEmpty) {
      await _reflowEngine.executeFullRebuild(userId);
    }
  }

  // TD-03 §3.3.2 / TD-04 §2.5.1 — Adopt a system drill. Idempotent.
  Future<UserDrillAdoption> adoptDrill(String userId, String drillId) async {
    final drill = await _getActiveDrill(drillId);

    // Check for existing adoption.
    final existing = await (_db.select(_db.userDrillAdoptions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.drillId.equals(drillId)))
        .getSingleOrNull();

    if (existing != null) {
      if (existing.isDeleted) {
        // Re-adopt: un-delete and set Active.
        final rows = await (_db.update(_db.userDrillAdoptions)
              ..where(
                  (t) => t.userDrillAdoptionId.equals(existing.userDrillAdoptionId)))
            .writeReturning(UserDrillAdoptionsCompanion(
          status: const Value(AdoptionStatus.active),
          isDeleted: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
        return rows.first;
      }
      if (existing.status == AdoptionStatus.retired) {
        // Re-adopt from Retired→Active.
        final rows = await (_db.update(_db.userDrillAdoptions)
              ..where(
                  (t) => t.userDrillAdoptionId.equals(existing.userDrillAdoptionId)))
            .writeReturning(UserDrillAdoptionsCompanion(
          status: const Value(AdoptionStatus.active),
          updatedAt: Value(DateTime.now()),
        ));
        return rows.first;
      }
      // Already Active — idempotent no-op.
      return existing;
    }

    // Create new adoption.
    try {
      return await _db.transaction(() async {
        return await _db
            .into(_db.userDrillAdoptions)
            .insertReturning(UserDrillAdoptionsCompanion.insert(
          userDrillAdoptionId: _uuid.v4(),
          userId: userId,
          drillId: drill.drillId,
        ));
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create drill adoption',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.2 / TD-04 §2.5.1 — Retire adoption: Active→Retired.
  Future<UserDrillAdoption> retireAdoption(
    String userId,
    String drillId,
  ) async {
    final existing = await _getAdoption(userId, drillId);

    if (existing.status != AdoptionStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message:
            'Cannot retire adoption: current status is ${existing.status.dbValue}',
        context: {
          'drillId': drillId,
          'status': existing.status.dbValue,
        },
      );
    }

    final rows = await (_db.update(_db.userDrillAdoptions)
          ..where(
              (t) => t.userDrillAdoptionId.equals(existing.userDrillAdoptionId)))
        .writeReturning(UserDrillAdoptionsCompanion(
      status: const Value(AdoptionStatus.retired),
      updatedAt: Value(DateTime.now()),
    ));
    return rows.first;
  }

  // TD-03 §3.3.2 — Soft-delete adoption + trigger full reflow.
  Future<void> deleteAdoption(String userId, String drillId) async {
    final existing = await _getAdoption(userId, drillId);

    await _db.transaction(() async {
      await (_db.update(_db.userDrillAdoptions)
            ..where(
                (t) => t.userDrillAdoptionId.equals(existing.userDrillAdoptionId)))
          .write(UserDrillAdoptionsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));
    });

    // EventLog.
    await _eventLogRepo.create(EventLogsCompanion.insert(
      eventLogId: _uuid.v4(),
      userId: userId,
      eventTypeId: 'DrillDeletion',
      affectedEntityIds: Value(jsonEncode([drillId])),
      metadata: Value(jsonEncode({
        'action': 'deleteAdoption',
      })),
    ));

    // Trigger full reflow.
    await _reflowEngine.executeFullRebuild(userId);
  }

  // TD-03 §3.3.2 — Duplicate drill: copy structural fields, new ID, Origin=UserCustom.
  Future<Drill> duplicateDrill(String userId, String sourceDrillId) async {
    final source = await _getActiveDrill(sourceDrillId);
    final newDrillId = _uuid.v4();

    final companion = DrillsCompanion.insert(
      drillId: newDrillId,
      userId: Value(userId),
      name: '${source.name} (Copy)',
      skillArea: source.skillArea,
      drillType: source.drillType,
      scoringMode: Value(source.scoringMode),
      inputMode: source.inputMode,
      metricSchemaId: source.metricSchemaId,
      gridType: Value(source.gridType),
      subskillMapping: Value(source.subskillMapping),
      clubSelectionMode: Value(source.clubSelectionMode),
      targetDistanceMode: Value(source.targetDistanceMode),
      targetDistanceValue: Value(source.targetDistanceValue),
      targetSizeMode: Value(source.targetSizeMode),
      targetSizeWidth: Value(source.targetSizeWidth),
      targetSizeDepth: Value(source.targetSizeDepth),
      requiredSetCount: Value(source.requiredSetCount),
      requiredAttemptsPerSet: Value(source.requiredAttemptsPerSet),
      anchors: Value(source.anchors),
      origin: DrillOrigin.userCustom,
      status: Value(DrillStatus.active),
      isDeleted: const Value(false),
    );

    try {
      return await _db.transaction(() async {
        return await _db.into(_db.drills).insertReturning(companion);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to duplicate drill',
        context: {'sourceDrillId': sourceDrillId, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Read-only queries (retained from Phase 1)
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Retrieve drill by primary key. Filters IsDeleted = false.
  Future<Drill?> getById(String id) {
    return (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // Spec: S04 §4.2 — System drills (UserID IS NULL, origin = system).
  Stream<List<Drill>> watchSystemDrills() {
    return (_db.select(_db.drills)
          ..where((t) => t.userId.isNull())
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  // ---------------------------------------------------------------------------
  // MetricSchema — read-only
  // ---------------------------------------------------------------------------

  // Spec: S04 §4.3 — Metric schema lookup by ID.
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
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<Drill> _getActiveDrill(String drillId) async {
    final drill = await (_db.select(_db.drills)
          ..where((t) => t.drillId.equals(drillId)))
        .getSingleOrNull();
    if (drill == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Drill not found: $drillId',
        context: {'drillId': drillId},
      );
    }
    return drill;
  }

  Future<UserDrillAdoption> _getAdoption(
    String userId,
    String drillId,
  ) async {
    final adoption = await (_db.select(_db.userDrillAdoptions)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.drillId.equals(drillId))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
    if (adoption == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Adoption not found for user=$userId, drill=$drillId',
        context: {'userId': userId, 'drillId': drillId},
      );
    }
    return adoption;
  }

  void _guardOwnership(Drill drill, String userId) {
    if (drill.origin == DrillOrigin.system) return;
    if (drill.userId != userId) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Cannot modify drill owned by another user',
        context: {'drillId': drill.drillId},
      );
    }
  }

  Future<Drill> _updateDrillStatus(String drillId, DrillStatus status) async {
    final rows = await (_db.update(_db.drills)
          ..where((t) => t.drillId.equals(drillId)))
        .writeReturning(DrillsCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
    ));
    if (rows.isEmpty) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Drill not found after status update',
        context: {'drillId': drillId},
      );
    }
    return rows.first;
  }

  // TD-04 §2.4.2 — Reject changes to immutable structural fields.
  void _rejectImmutableFieldChanges(DrillsCompanion data) {
    if (data.subskillMapping.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'SubskillMapping is immutable after drill creation',
      );
    }
    if (data.metricSchemaId.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'MetricSchemaID is immutable after drill creation',
      );
    }
    if (data.drillType.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'DrillType is immutable after drill creation',
      );
    }
    if (data.requiredSetCount.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'RequiredSetCount is immutable after drill creation',
      );
    }
    if (data.requiredAttemptsPerSet.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'RequiredAttemptsPerSet is immutable after drill creation',
      );
    }
    if (data.clubSelectionMode.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'ClubSelectionMode is immutable after drill creation',
      );
    }
    if (data.targetDistanceMode.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'TargetDistanceMode is immutable after drill creation',
      );
    }
    if (data.targetDistanceValue.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'TargetDistanceValue is immutable after drill creation',
      );
    }
    if (data.targetSizeMode.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'TargetSizeMode is immutable after drill creation',
      );
    }
    if (data.targetSizeWidth.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'TargetSizeWidth is immutable after drill creation',
      );
    }
    if (data.targetSizeDepth.present) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'TargetSizeDepth is immutable after drill creation',
      );
    }
  }

  // S04 §4.5 — Validate anchors: Min < Scratch < Pro for each subskill.
  void _validateAnchors(String anchorsJson, Set<String> subskillMapping) {
    if (anchorsJson == '{}' || anchorsJson.isEmpty) return;

    final Map<String, dynamic> anchorsMap;
    try {
      anchorsMap = jsonDecode(anchorsJson) as Map<String, dynamic>;
    } on FormatException {
      throw ValidationException(
        code: ValidationException.invalidAnchors,
        message: 'Invalid anchors JSON format',
      );
    }

    for (final entry in anchorsMap.entries) {
      final anchor = entry.value as Map<String, dynamic>;
      final min = (anchor['Min'] as num?)?.toDouble();
      final scratch = (anchor['Scratch'] as num?)?.toDouble();
      final pro = (anchor['Pro'] as num?)?.toDouble();

      if (min == null || scratch == null || pro == null) {
        throw ValidationException(
          code: ValidationException.invalidAnchors,
          message: 'Anchors for "${entry.key}" must have Min, Scratch, and Pro',
          context: {'subskill': entry.key},
        );
      }

      if (min >= scratch) {
        throw ValidationException(
          code: ValidationException.invalidAnchors,
          message:
              'Anchor Min ($min) must be less than Scratch ($scratch) for "${entry.key}"',
          context: {'subskill': entry.key, 'min': min, 'scratch': scratch},
        );
      }

      if (scratch >= pro) {
        throw ValidationException(
          code: ValidationException.invalidAnchors,
          message:
              'Anchor Scratch ($scratch) must be less than Pro ($pro) for "${entry.key}"',
          context: {'subskill': entry.key, 'scratch': scratch, 'pro': pro},
        );
      }
    }
  }

  Set<String> _parseSubskillMapping(String json) {
    if (json == '[]' || json.isEmpty) return {};
    final List<dynamic> list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => e as String).toSet();
  }
}
