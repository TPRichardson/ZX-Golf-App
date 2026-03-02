// Phase 5 — Planning workflow Riverpod providers.
// S08 — Practice Planning Layer.
// Bridges PlanningRepository + business logic to UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/completion_matching.dart';
import 'package:zx_golf_app/features/planning/models/planning_types.dart';
import 'package:zx_golf_app/features/planning/routine_application.dart';
import 'package:zx_golf_app/features/planning/schedule_application.dart';
import 'package:zx_golf_app/features/planning/weakness_detection.dart';
import 'repository_providers.dart';

// ---------------------------------------------------------------------------
// Core singletons
// ---------------------------------------------------------------------------

/// S08 §8.3.2 — CompletionMatcher singleton.
final completionMatcherProvider = Provider<CompletionMatcher>((ref) {
  return CompletionMatcher(ref.watch(planningRepositoryProvider));
});

/// S08 §8.2.2 — RoutineApplicator singleton.
final routineApplicatorProvider = Provider<RoutineApplicator>((ref) {
  return RoutineApplicator(ref.watch(planningRepositoryProvider));
});

/// S08 §8.2.3 — ScheduleApplicator singleton.
final scheduleApplicatorProvider = Provider<ScheduleApplicator>((ref) {
  return ScheduleApplicator(ref.watch(planningRepositoryProvider));
});

/// S08 §8.7 — WeaknessDetectionEngine singleton (pure computation).
final weaknessDetectionEngineProvider =
    Provider<WeaknessDetectionEngine>((ref) {
  return WeaknessDetectionEngine();
});

// ---------------------------------------------------------------------------
// Stream providers
// ---------------------------------------------------------------------------

/// S08 §8.1.2 — Active routines for a user.
final routinesProvider =
    StreamProvider.family<List<Routine>, String>((ref, userId) {
  return ref.watch(planningRepositoryProvider).watchRoutines(
    userId,
    status: RoutineStatus.active,
  );
});

/// S08 §8.1.3 — Active schedules for a user.
final schedulesProvider =
    StreamProvider.family<List<Schedule>, String>((ref, userId) {
  return ref.watch(planningRepositoryProvider).watchSchedules(
    userId,
    status: ScheduleStatus.active,
  );
});

/// S08 §8.13 — CalendarDays for a date range.
/// Parameter: (userId, startDate, endDate).
final calendarDaysProvider = StreamProvider.family<List<CalendarDay>,
    ({String userId, DateTime start, DateTime end})>((ref, params) {
  return ref.watch(planningRepositoryProvider).watchCalendarDaysByUser(
    params.userId,
    from: params.start,
    to: params.end,
  );
});

/// S08 §8.13 — Today's CalendarDay for quick access.
final todayCalendarDayProvider =
    FutureProvider.family<CalendarDay, String>((ref, userId) {
  return ref
      .watch(planningRepositoryProvider)
      .getOrCreateCalendarDay(userId, DateTime.now());
});

// ---------------------------------------------------------------------------
// PlanningActions coordinator
// ---------------------------------------------------------------------------

/// Phase 5 — Coordinator for planning actions that bridge repository + business logic.
/// Same pattern as PracticeActions from Phase 4.
class PlanningActions {
  final PlanningRepository _repo;
  final RoutineApplicator _routineApplicator;
  final ScheduleApplicator _scheduleApplicator;

  PlanningActions(this._repo, this._routineApplicator, this._scheduleApplicator);

  // ---------------------------------------------------------------------------
  // Routine CRUD + cascade
  // ---------------------------------------------------------------------------

  Future<Routine> createRoutine(
    String userId,
    String name,
    List<RoutineEntry> entries,
  ) => _repo.createRoutineWithEntries(userId, name, entries);

  Future<Routine> updateRoutineEntries(
    String routineId,
    List<RoutineEntry> entries,
  ) => _repo.updateRoutineEntries(routineId, entries);

  Future<Routine> retireRoutine(String routineId) =>
      _repo.retireRoutine(routineId);

  Future<Routine> reactivateRoutine(String routineId) =>
      _repo.reactivateRoutine(routineId);

  Future<void> deleteRoutine(String routineId) =>
      _repo.deleteRoutine(routineId);

  // ---------------------------------------------------------------------------
  // Schedule CRUD + cascade
  // ---------------------------------------------------------------------------

  Future<Schedule> createSchedule(
    String userId,
    String name,
    ScheduleAppMode appMode,
    String entriesJson,
  ) => _repo.createScheduleWithEntries(userId, name, appMode, entriesJson);

  Future<Schedule> updateScheduleEntries(
    String scheduleId,
    String entriesJson,
  ) => _repo.updateScheduleEntries(scheduleId, entriesJson);

  Future<Schedule> retireSchedule(String scheduleId) =>
      _repo.retireSchedule(scheduleId);

  Future<Schedule> reactivateSchedule(String scheduleId) =>
      _repo.reactivateSchedule(scheduleId);

  Future<void> deleteSchedule(String scheduleId) =>
      _repo.deleteSchedule(scheduleId);

  // ---------------------------------------------------------------------------
  // Routine application
  // ---------------------------------------------------------------------------

  Future<RoutineInstance> applyRoutine(
    String userId,
    String routineId,
    DateTime date,
    List<String> resolvedDrillIds,
  ) => _routineApplicator.confirmApplication(
      userId, routineId, date, resolvedDrillIds);

  Future<void> unapplyRoutineInstance(String routineInstanceId) =>
      _routineApplicator.unapplyRoutineInstance(routineInstanceId);

  // ---------------------------------------------------------------------------
  // Schedule application
  // ---------------------------------------------------------------------------

  Future<ScheduleInstance> applySchedule(
    String userId,
    String scheduleId,
    DateTime startDate,
    DateTime endDate,
    SchedulePreview resolvedMap,
  ) => _scheduleApplicator.confirmApplication(
      userId, scheduleId, startDate, endDate, resolvedMap);

  Future<void> unapplyScheduleInstance(String scheduleInstanceId) =>
      _scheduleApplicator.unapplyScheduleInstance(scheduleInstanceId);

  // ---------------------------------------------------------------------------
  // Slot management
  // ---------------------------------------------------------------------------

  Future<CalendarDay> assignDrillToSlot(
    String userId, DateTime date, int slotIndex, String drillId,
  ) => _repo.assignDrillToSlot(userId, date, slotIndex, drillId);

  Future<CalendarDay> clearSlot(
    String userId, DateTime date, int slotIndex,
  ) => _repo.clearSlot(userId, date, slotIndex);

  Future<CalendarDay> updateSlotCapacity(
    String userId, DateTime date, int newCapacity,
  ) => _repo.updateSlotCapacity(userId, date, newCapacity);

  Future<CalendarDay> markSlotManualComplete(
    String calendarDayId, int slotIndex,
  ) => _repo.markSlotManualComplete(calendarDayId, slotIndex);

  Future<CalendarDay> revertSlotCompletion(
    String calendarDayId, int slotIndex,
  ) => _repo.revertSlotCompletion(calendarDayId, slotIndex);
}

/// Phase 5 — Provider for PlanningActions coordinator.
final planningActionsProvider = Provider<PlanningActions>((ref) {
  return PlanningActions(
    ref.watch(planningRepositoryProvider),
    ref.watch(routineApplicatorProvider),
    ref.watch(scheduleApplicatorProvider),
  );
});
