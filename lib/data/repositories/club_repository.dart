import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.2 — Club configuration repository.
// Manages: UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping.
class ClubRepository {
  final AppDatabase _db;

  ClubRepository(this._db);

  // ---------------------------------------------------------------------------
  // UserClub CRUD
  // ---------------------------------------------------------------------------

  // TD-03 §3.2 — Create club in user's bag.
  // Spec: S09 §9.1 — Golf bag configuration.
  Future<UserClub> create(UserClubsCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.userClubs).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create club',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve club by primary key.
  Future<UserClub?> getById(String id) {
    return (_db.select(_db.userClubs)
          ..where((t) => t.clubId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of all clubs for a user.
  Stream<List<UserClub>> watchByUser(String userId) {
    return (_db.select(_db.userClubs)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.2 — Update club fields.
  // Spec: TD-03 §2.1.1 — SyncWriteGate compatible: writes through transaction.
  Future<UserClub> update(String id, UserClubsCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.userClubs)
              ..where((t) => t.clubId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Club not found after update',
            context: {'clubId': id},
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
        context: {'clubId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete club. Permanent removal.
  Future<void> hardDelete(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.userClubs)
              ..where((t) => t.clubId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Club not found for hard delete',
            context: {'clubId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete club',
        context: {'clubId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ClubPerformanceProfile — insert-only (time-versioned, no update)
  // ---------------------------------------------------------------------------

  // TD-02 §3.10 — Insert new performance profile snapshot.
  // Spec: S09 §9.3 — Time-versioned, append-only.
  Future<ClubPerformanceProfile> createProfile(
      ClubPerformanceProfilesCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db
            .into(_db.clubPerformanceProfiles)
            .insertReturning(data);
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

  // TD-03 §3.2 — Retrieve profile by primary key.
  Future<ClubPerformanceProfile?> getProfileById(String id) {
    return (_db.select(_db.clubPerformanceProfiles)
          ..where((t) => t.profileId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — All profiles for a club, ordered by effective date descending.
  Stream<List<ClubPerformanceProfile>> watchProfilesByClub(String clubId) {
    return (_db.select(_db.clubPerformanceProfiles)
          ..where((t) => t.clubId.equals(clubId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.effectiveFromDate),
          ]))
        .watch();
  }

  // TD-03 §3.2 — Latest profile for a club (most recent effectiveFromDate).
  Future<ClubPerformanceProfile?> getLatestProfileByClub(String clubId) {
    return (_db.select(_db.clubPerformanceProfiles)
          ..where((t) => t.clubId.equals(clubId))
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveFromDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  // ---------------------------------------------------------------------------
  // UserSkillAreaClubMapping CRUD
  // ---------------------------------------------------------------------------

  // TD-02 §3.11 — Create skill area club mapping.
  Future<UserSkillAreaClubMapping> createMapping(
      UserSkillAreaClubMappingsCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db
            .into(_db.userSkillAreaClubMappings)
            .insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create skill area club mapping',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve mapping by primary key.
  Future<UserSkillAreaClubMapping?> getMappingById(String id) {
    return (_db.select(_db.userSkillAreaClubMappings)
          ..where((t) => t.mappingId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — All mappings for a user.
  Stream<List<UserSkillAreaClubMapping>> watchMappingsByUser(String userId) {
    return (_db.select(_db.userSkillAreaClubMappings)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.2 — Update mapping fields.
  Future<UserSkillAreaClubMapping> updateMapping(
      String id, UserSkillAreaClubMappingsCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.userSkillAreaClubMappings)
              ..where((t) => t.mappingId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Skill area club mapping not found after update',
            context: {'mappingId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update skill area club mapping',
        context: {'mappingId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete mapping.
  Future<void> hardDeleteMapping(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.userSkillAreaClubMappings)
              ..where((t) => t.mappingId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Skill area club mapping not found for hard delete',
            context: {'mappingId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete skill area club mapping',
        context: {'mappingId': id, 'error': e.toString()},
      );
    }
  }
}
