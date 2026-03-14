import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §3.3.5 — Club configuration repository.
// Manages: UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping.
// Phase 3: Full business methods with state machine guards,
// S09 §9.2.3 default mappings, mandatory mapping enforcement.

class ClubRepository {
  final AppDatabase _db;
  final SyncWriteGate _gate;

  static const _uuid = Uuid();

  ClubRepository(this._db, this._gate);

  // ---------------------------------------------------------------------------
  // S09 §9.2.3 — Default mapping configuration
  // ---------------------------------------------------------------------------

  // Mandatory mappings (cannot be removed).
  static const _mandatoryMappings = <ClubType, Set<SkillArea>>{
    ClubType.driver: {SkillArea.driving},
    ClubType.putter: {SkillArea.putting},
    // Irons i1–i9 are mandatory for Approach skill area.
    ClubType.i1: {SkillArea.approach},
    ClubType.i2: {SkillArea.approach},
    ClubType.i3: {SkillArea.approach},
    ClubType.i4: {SkillArea.approach},
    ClubType.i5: {SkillArea.approach},
    ClubType.i6: {SkillArea.approach},
    ClubType.i7: {SkillArea.approach},
    ClubType.i8: {SkillArea.approach},
    ClubType.i9: {SkillArea.approach},
  };

  // S09 §9.2.3 — Default modifiable mappings by club type category.
  static const _pitchingClubs = {
    ClubType.i9, ClubType.pw, ClubType.aw, ClubType.gw, ClubType.sw, ClubType.lw,
  };
  static const _chippingClubs = {
    ClubType.i7, ClubType.i8, ClubType.i9,
    ClubType.pw, ClubType.aw, ClubType.gw, ClubType.sw, ClubType.lw,
    ClubType.chipper,
  };
  static const _woodsClubs = {
    ClubType.w1, ClubType.w2, ClubType.w3, ClubType.w4, ClubType.w5,
    ClubType.w6, ClubType.w7, ClubType.w8, ClubType.w9,
    ClubType.h1, ClubType.h2, ClubType.h3, ClubType.h4, ClubType.h5,
    ClubType.h6, ClubType.h7, ClubType.h8, ClubType.h9,
  };
  static const _bunkerClubs = {
    ClubType.i7, ClubType.i8, ClubType.i9,
    ClubType.pw, ClubType.aw, ClubType.gw, ClubType.sw, ClubType.lw,
    ClubType.chipper,
  };

  // ---------------------------------------------------------------------------
  // UserClub business methods — TD-03 §3.3.5
  // ---------------------------------------------------------------------------

  // TD-03 §3.3.5 — Reactive stream of user's bag. Active by default.
  Stream<List<UserClub>> watchUserBag(
    String userId, {
    UserClubStatus? status,
  }) {
    final query = _db.select(_db.userClubs)
      ..where((t) => t.userId.equals(userId));
    if (status != null) {
      query.where((t) => t.status.equalsValue(status));
    }
    query.orderBy([
      (t) => OrderingTerm.asc(t.clubType),
    ]);
    return query.watch();
  }

  // TD-03 §3.3.5 — Add club to user's bag.
  // S09 §9.2.3 — Creates default skill area mappings.
  Future<UserClub> addClub(String userId, UserClubsCompanion data) async {
    await _gate.awaitGateRelease();
    final clubId = _uuid.v4();
    final clubType = data.clubType.value;

    final companion = data.copyWith(
      clubId: Value(clubId),
      userId: Value(userId),
      status: const Value(UserClubStatus.active),
    );

    try {
      return await _db.transaction(() async {
        final club =
            await _db.into(_db.userClubs).insertReturning(companion);

        // S09 §9.2.3 — Create default mappings for this club type.
        await _createDefaultMappings(userId, clubType);

        return club;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to add club',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.5 — Update club fields. Make, Model, Loft only.
  Future<UserClub> updateClub(String clubId, UserClubsCompanion data) async {
    await _gate.awaitGateRelease();
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.userClubs)
              ..where((t) => t.clubId.equals(clubId)))
            .writeReturning(data.copyWith(
          updatedAt: Value(DateTime.now()),
        ));
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Club not found after update',
            context: {'clubId': clubId},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update club',
        context: {'clubId': clubId, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.5 / TD-04 §2.10.1 — Retire club: Active→Retired.
  Future<UserClub> retireClub(String userId, String clubId) async {
    await _gate.awaitGateRelease();
    final existing = await _getClub(clubId);

    if (existing.userId != userId) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Cannot modify club owned by another user',
        context: {'clubId': clubId},
      );
    }

    if (existing.status != UserClubStatus.active) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message:
            'Cannot retire club: current status is ${existing.status.dbValue}',
        context: {'clubId': clubId, 'status': existing.status.dbValue},
      );
    }

    return _updateClubStatus(clubId, UserClubStatus.retired);
  }

  // TD-03 §3.3.5 / TD-04 §2.10.1 — Reactivate club: Retired→Active.
  Future<UserClub> reactivateClub(String userId, String clubId) async {
    await _gate.awaitGateRelease();
    final existing = await _getClub(clubId);

    if (existing.userId != userId) {
      throw ValidationException(
        code: ValidationException.invalidStructure,
        message: 'Cannot modify club owned by another user',
        context: {'clubId': clubId},
      );
    }

    if (existing.status != UserClubStatus.retired) {
      throw ValidationException(
        code: ValidationException.stateTransition,
        message:
            'Cannot reactivate club: current status is ${existing.status.dbValue}',
        context: {'clubId': clubId, 'status': existing.status.dbValue},
      );
    }

    return _updateClubStatus(clubId, UserClubStatus.active);
  }

  // ---------------------------------------------------------------------------
  // ClubPerformanceProfile — TD-03 §3.3.5
  // ---------------------------------------------------------------------------

  // TD-02 §3.10 — Insert new performance profile snapshot.
  // Spec: S09 §9.3 — Time-versioned, append-only.
  Future<ClubPerformanceProfile> addPerformanceProfile(
    String clubId,
    ClubPerformanceProfilesCompanion data,
  ) async {
    await _gate.awaitGateRelease();
    final profileId = _uuid.v4();
    final companion = data.copyWith(
      profileId: Value(profileId),
      clubId: Value(clubId),
    );

    try {
      return await _db.transaction(() async {
        return await _db
            .into(_db.clubPerformanceProfiles)
            .insertReturning(companion);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create club performance profile',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.3.5 — Get active profile: most recent EffectiveFromDate ≤ now.
  Future<ClubPerformanceProfile?> getActiveProfile(String clubId) {
    return (_db.select(_db.clubPerformanceProfiles)
          ..where((t) => t.clubId.equals(clubId))
          ..where(
              (t) => t.effectiveFromDate.isSmallerOrEqualValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveFromDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  // TD-03 §3.3.5 — All profiles for a club, ordered by effective date descending.
  Stream<List<ClubPerformanceProfile>> watchProfilesByClub(String clubId) {
    return (_db.select(_db.clubPerformanceProfiles)
          ..where((t) => t.clubId.equals(clubId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.effectiveFromDate),
          ]))
        .watch();
  }

  // ---------------------------------------------------------------------------
  // UserSkillAreaClubMapping — TD-03 §3.3.5
  // ---------------------------------------------------------------------------

  // TD-03 §3.3.5 — Active clubs mapped to a skill area.
  Stream<List<UserClub>> watchClubsForSkillArea(
    String userId,
    SkillArea skillArea,
  ) {
    final query = _db.select(_db.userClubs).join([
      innerJoin(
        _db.userSkillAreaClubMappings,
        _db.userSkillAreaClubMappings.clubType
                .equalsExp(_db.userClubs.clubType) &
            _db.userSkillAreaClubMappings.userId
                .equalsExp(_db.userClubs.userId),
      ),
    ]);
    query
      ..where(_db.userClubs.userId.equals(userId))
      ..where(_db.userClubs.status.equalsValue(UserClubStatus.active))
      ..where(
          _db.userSkillAreaClubMappings.skillArea.equalsValue(skillArea));
    query.orderBy([OrderingTerm.asc(_db.userClubs.clubType)]);

    return query.watch().map((rows) =>
        rows.map((row) => row.readTable(_db.userClubs)).toList());
  }

  // TD-03 §3.3.5 — Reactive stream of all mappings for a user.
  Stream<List<UserSkillAreaClubMapping>> watchMappingsByUser(String userId) {
    return (_db.select(_db.userSkillAreaClubMappings)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.3.5 — Update skill area mapping: create or delete.
  // S09 §9.2.3 — Mandatory mappings cannot be removed.
  Future<void> updateSkillAreaMapping(
    String userId,
    ClubType clubType,
    SkillArea skillArea,
    bool mapped,
  ) async {
    await _gate.awaitGateRelease();
    // Mandatory enforcement removed — users can freely toggle all mappings.

    final existing = await (_db.select(_db.userSkillAreaClubMappings)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.clubType.equalsValue(clubType))
          ..where((t) => t.skillArea.equalsValue(skillArea)))
        .getSingleOrNull();

    if (mapped && existing == null) {
      // Create mapping.
      final isMandatory = _mandatoryMappings[clubType]?.contains(skillArea) ?? false;
      await _db.into(_db.userSkillAreaClubMappings).insert(
            UserSkillAreaClubMappingsCompanion.insert(
              mappingId: _uuid.v4(),
              userId: userId,
              clubType: clubType,
              skillArea: skillArea,
              isMandatory: Value(isMandatory),
            ),
          );
    } else if (!mapped && existing != null) {
      // Delete mapping.
      await (_db.delete(_db.userSkillAreaClubMappings)
            ..where((t) => t.mappingId.equals(existing.mappingId)))
          .go();
    }
    // If mapped and exists, or !mapped and !exists, no-op.
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<UserClub> _getClub(String clubId) async {
    final club = await (_db.select(_db.userClubs)
          ..where((t) => t.clubId.equals(clubId)))
        .getSingleOrNull();
    if (club == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Club not found: $clubId',
        context: {'clubId': clubId},
      );
    }
    return club;
  }

  Future<UserClub> _updateClubStatus(
    String clubId,
    UserClubStatus status,
  ) async {
    final rows = await (_db.update(_db.userClubs)
          ..where((t) => t.clubId.equals(clubId)))
        .writeReturning(UserClubsCompanion(
      status: Value(status),
      updatedAt: Value(DateTime.now()),
    ));
    if (rows.isEmpty) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Club not found after status update',
        context: {'clubId': clubId},
      );
    }
    return rows.first;
  }

  // S09 §9.2.3 — Create default mappings for a club type.
  Future<void> _createDefaultMappings(
    String userId,
    ClubType clubType,
  ) async {
    final mappings = _getDefaultMappings(clubType);

    for (final entry in mappings.entries) {
      final skillArea = entry.key;
      final isMandatory = entry.value;

      // Check if mapping already exists (idempotent).
      final existing = await (_db.select(_db.userSkillAreaClubMappings)
            ..where((t) => t.userId.equals(userId))
            ..where((t) => t.clubType.equalsValue(clubType))
            ..where((t) => t.skillArea.equalsValue(skillArea)))
          .getSingleOrNull();

      if (existing == null) {
        await _db.into(_db.userSkillAreaClubMappings).insert(
              UserSkillAreaClubMappingsCompanion.insert(
                mappingId: _uuid.v4(),
                userId: userId,
                clubType: clubType,
                skillArea: skillArea,
                isMandatory: Value(isMandatory),
              ),
            );
      }
    }
  }

  // S09 §9.2.3 — Determine default mappings for a club type.
  // Returns Map<SkillArea, isMandatory>.
  Map<SkillArea, bool> _getDefaultMappings(ClubType clubType) {
    final result = <SkillArea, bool>{};

    // Mandatory mappings.
    final mandatory = _mandatoryMappings[clubType];
    if (mandatory != null) {
      for (final area in mandatory) {
        result[area] = true;
      }
    }

    // Default modifiable mappings.
    if (clubType == ClubType.driver) {
      result.putIfAbsent(SkillArea.driving, () => false);
    }
    if (clubType == ClubType.putter) {
      result.putIfAbsent(SkillArea.putting, () => false);
    }

    // Pitching defaults.
    if (_pitchingClubs.contains(clubType)) {
      result.putIfAbsent(SkillArea.pitching, () => false);
    }

    // Chipping defaults.
    if (_chippingClubs.contains(clubType)) {
      result.putIfAbsent(SkillArea.chipping, () => false);
    }

    // Woods defaults.
    if (_woodsClubs.contains(clubType)) {
      result.putIfAbsent(SkillArea.woods, () => false);
    }

    // Bunkers defaults.
    if (_bunkerClubs.contains(clubType)) {
      result.putIfAbsent(SkillArea.bunkers, () => false);
    }

    return result;
  }
}
