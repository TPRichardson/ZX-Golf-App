import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.2 — Scoring materialised state repository.
// Phase 2A stub — method signatures only, no implementation.
//
// Manages: MaterialisedWindowState, MaterialisedSubskillScore,
//          MaterialisedSkillAreaScore, MaterialisedOverallScore,
//          UserScoringLock.
class ScoringRepository {
  // Phase 2A stub — _db will be used when methods are implemented.
  // ignore: unused_field
  final AppDatabase _db;

  ScoringRepository(this._db);

  // ---------------------------------------------------------------------------
  // MaterialisedWindowState
  // Phase 2A stub — replaced in Phase 2A (scoring engine).
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Retrieve window states for a user.
  Stream<List<MaterialisedWindowState>> watchWindowStatesByUser(
      String userId) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.watchWindowStatesByUser');
  }

  // Spec: S16 §16.1.6 — Upsert window state row.
  Future<void> upsertWindowState(MaterialisedWindowStatesCompanion data) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.upsertWindowState');
  }

  // ---------------------------------------------------------------------------
  // MaterialisedSubskillScore
  // Phase 2A stub — replaced in Phase 2A (scoring engine).
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Retrieve subskill scores for a user.
  Stream<List<MaterialisedSubskillScore>> watchSubskillScoresByUser(
      String userId) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.watchSubskillScoresByUser');
  }

  // Spec: S16 §16.1.6 — Upsert subskill score row.
  Future<void> upsertSubskillScore(
      MaterialisedSubskillScoresCompanion data) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.upsertSubskillScore');
  }

  // ---------------------------------------------------------------------------
  // MaterialisedSkillAreaScore
  // Phase 2A stub — replaced in Phase 2A (scoring engine).
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Retrieve skill area scores for a user.
  Stream<List<MaterialisedSkillAreaScore>> watchSkillAreaScoresByUser(
      String userId) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.watchSkillAreaScoresByUser');
  }

  // Spec: S16 §16.1.6 — Upsert skill area score row.
  Future<void> upsertSkillAreaScore(
      MaterialisedSkillAreaScoresCompanion data) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.upsertSkillAreaScore');
  }

  // ---------------------------------------------------------------------------
  // MaterialisedOverallScore
  // Phase 2A stub — replaced in Phase 2A (scoring engine).
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.1.6 — Retrieve overall score for a user.
  Stream<MaterialisedOverallScore?> watchOverallScoreByUser(String userId) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.watchOverallScoreByUser');
  }

  // Spec: S16 §16.1.6 — Upsert overall score row.
  Future<void> upsertOverallScore(MaterialisedOverallScoresCompanion data) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.upsertOverallScore');
  }

  // ---------------------------------------------------------------------------
  // UserScoringLock
  // Phase 2A stub — replaced in Phase 2A (scoring engine).
  // ---------------------------------------------------------------------------

  // Spec: S16 §16.4.3 — Acquire scoring lock for reflow serialisation.
  Future<bool> acquireLock(String userId) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.acquireLock');
  }

  // Spec: S16 §16.4.3 — Release scoring lock after reflow.
  Future<void> releaseLock(String userId) {
    // Phase 2A stub — replaced in Phase 2A (scoring engine).
    throw UnimplementedError('ScoringRepository.releaseLock');
  }
}
