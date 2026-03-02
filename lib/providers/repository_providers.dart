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

// TD-03 §3.1 — One provider per repository, injecting the database.

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(databaseProvider));
});

// Phase 3 — DrillRepository with EventLogRepository and ReflowEngine DI.
// Phase 5 — PlanningRepository added for drill deletion cascade.
final drillRepositoryProvider = Provider<DrillRepository>((ref) {
  return DrillRepository(
    ref.watch(databaseProvider),
    ref.watch(eventLogRepositoryProvider),
    ref.watch(reflowEngineProvider),
    ref.watch(planningRepositoryProvider),
  );
});

// Phase 4 — PracticeRepository with ReflowEngine and EventLogRepository DI.
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepository(
    ref.watch(databaseProvider),
    ref.watch(reflowEngineProvider),
    ref.watch(eventLogRepositoryProvider),
  );
});

// Phase 2A stub — scoring repository.
final scoringRepositoryProvider = Provider<ScoringRepository>((ref) {
  return ScoringRepository(ref.watch(databaseProvider));
});

final clubRepositoryProvider = Provider<ClubRepository>((ref) {
  return ClubRepository(ref.watch(databaseProvider));
});

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  return PlanningRepository(ref.watch(databaseProvider));
});

final eventLogRepositoryProvider = Provider<EventLogRepository>((ref) {
  return EventLogRepository(ref.watch(databaseProvider));
});

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return ReferenceRepository(ref.watch(databaseProvider));
});
