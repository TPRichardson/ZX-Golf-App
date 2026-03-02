import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/repositories/user_repository.dart';
import 'package:zx_golf_app/data/repositories/drill_repository.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/data/repositories/event_log_repository.dart';
import 'package:zx_golf_app/data/repositories/reference_repository.dart';
import 'database_providers.dart';
import 'scoring_providers.dart';
import 'sync_providers.dart';

// TD-03 §3.1 — One provider per repository, injecting the database.
// Phase 7B — SyncWriteGate injected into 6 gate-checked repositories.

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    ref.watch(databaseProvider),
    ref.watch(syncWriteGateProvider),
  );
});

// Phase 3 — DrillRepository with EventLogRepository and ReflowEngine DI.
// Phase 5 — PlanningRepository added for drill deletion cascade.
// Phase 7B — SyncWriteGate added.
final drillRepositoryProvider = Provider<DrillRepository>((ref) {
  return DrillRepository(
    ref.watch(databaseProvider),
    ref.watch(eventLogRepositoryProvider),
    ref.watch(reflowEngineProvider),
    ref.watch(syncWriteGateProvider),
    ref.watch(planningRepositoryProvider),
  );
});

// Phase 4 — PracticeRepository with ReflowEngine and EventLogRepository DI.
// Phase 7B — SyncWriteGate added.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepository(
    ref.watch(databaseProvider),
    ref.watch(reflowEngineProvider),
    ref.watch(eventLogRepositoryProvider),
    ref.watch(syncWriteGateProvider),
  );
});

// Phase 2A stub — scoring repository.
// Phase 7B — ScoringRepository exempt from gate (orchestrated by ReflowEngine).
final scoringRepositoryProvider = Provider<ScoringRepository>((ref) {
  return ScoringRepository(ref.watch(databaseProvider));
});

// Phase 7B — SyncWriteGate added.
final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(
    ref.watch(databaseProvider),
    ref.watch(syncWriteGateProvider),
  );
});

// Phase 7B — SyncWriteGate added.
final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  return PlanningRepository(
    ref.watch(databaseProvider),
    ref.watch(syncWriteGateProvider),
  );
});

// Phase 7B — SyncWriteGate added.
final eventLogRepositoryProvider = Provider<EventLogRepository>((ref) {
  return EventLogRepository(
    ref.watch(databaseProvider),
    ref.watch(syncWriteGateProvider),
  );
});

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository(ref.watch(databaseProvider));
});
