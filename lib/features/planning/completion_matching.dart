import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// S08 §8.3.2 — Completion matching: auto-match closed sessions to CalendarDay slots.
// Called from PracticeActions.endSession() after scoring completes.

class CompletionMatcher {
  final PlanningRepository _planningRepo;

  CompletionMatcher(this._planningRepo);

  /// S08 §8.3.2 — Execute completion matching for a closed session.
  /// Finds first Incomplete slot with matching drillId on the same date
  /// and marks it CompletedLinked. If no match, creates overflow slot.
  Future<void> executeCompletionMatching(
    String sessionId,
    String drillId,
    String userId,
    DateTime completionTimestamp,
  ) async {
    final dateOnly = DateTime(
      completionTimestamp.year,
      completionTimestamp.month,
      completionTimestamp.day,
    );

    // 1. Get CalendarDay for that date (may not exist).
    var day = await _planningRepo.getCalendarDayByDate(userId, dateOnly);

    if (day != null) {
      final slots = _planningRepo.parseSlots(day.slots);

      // 2. Find first Incomplete slot with matching drillId.
      for (var i = 0; i < slots.length; i++) {
        if (slots[i].drillId == drillId &&
            slots[i].completionState == CompletionState.incomplete) {
          await _planningRepo.markSlotComplete(
              day.calendarDayId, i, sessionId);
          return;
        }
      }
    }

    // S08 §8.3.3 — Completion overflow: no matching slot found.
    // Ensure CalendarDay exists with default slots, then append overflow.
    day ??= await _planningRepo.getOrCreateCalendarDay(userId, dateOnly);

    final slots = _planningRepo.parseSlots(day.slots);
    slots.add(Slot(
      drillId: drillId,
      ownerType: SlotOwnerType.manual,
      completionState: CompletionState.completedLinked,
      completingSessionId: sessionId,
      planned: false,
    ));

    await _planningRepo.updateCalendarDay(
      day.calendarDayId,
      CalendarDaysCompanion(
        slotCapacity: Value(slots.length),
        slots: Value(_planningRepo.serializeSlots(slots)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// S08 §8.3.4 — Revert completion match when a session is deleted.
  /// Finds slot with matching completingSessionId and reverts to Incomplete.
  Future<void> revertCompletionForSession(
    String sessionId,
    String userId,
    DateTime sessionDate,
  ) async {
    final dateOnly = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );

    final day = await _planningRepo.getCalendarDayByDate(userId, dateOnly);
    if (day == null) return;

    final slots = _planningRepo.parseSlots(day.slots);
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].completingSessionId == sessionId) {
        await _planningRepo.revertSlotCompletion(day.calendarDayId, i);
        return;
      }
    }
  }
}
