# TD-03 API Contract Layer — Phase 5 Extract (TD-03v.a5)
Sections: §3.3.6 PlanningRepository
============================================================

3.3.6 PlanningRepository

  --------------------------- ---------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                      Signature                                                                                      Description

  watchRoutines               Stream<List<Routine>> watchRoutines({RoutineStatus? status})                                   Watches user’s Routines. Default: Active.

  createRoutine               Future<Routine> createRoutine(String name, List<RoutineEntry> entries)                         Creates a Routine with ordered entries. Each entry is either a fixed DrillID or a Generation Criterion.

  updateRoutine               Future<Routine> updateRoutine(String routineId, {String? name, List<RoutineEntry>? entries})   Updates Routine name or entry list. No scoring impact.

  deleteRoutine               Future<void> deleteRoutine(String routineId)                                                   Soft deletes. Cascading: RoutineInstance references set to null. Empty Routines auto-deleted (Section 3, §3.1.2).

  watchSchedules              Stream<List<Schedule>> watchSchedules({ScheduleStatus? status})                                Watches user’s Schedules.

  createSchedule              Future<Schedule> createSchedule(ScheduleCompanion data)                                        Creates a Schedule (List or DayPlanning mode).

  applySchedule               Future<List<CalendarDay>> applySchedule(String scheduleId, Date startDate, Date endDate)       Instantiates a Schedule across a date range. Creates/updates CalendarDay rows with Slot assignments. Creates ScheduleInstance tracking record.

  watchCalendarDays           Stream<List<CalendarDay>> watchCalendarDays(Date start, Date end)                              Watches CalendarDay rows in a date range. Primary source for Calendar view.

  updateCalendarDay           Future<CalendarDay> updateCalendarDay(String dayId, {int? slotCapacity, List<Slot>? slots})    Updates SlotCapacity or individual Slot assignments on a CalendarDay.

  executeCompletionMatching   Future<void> executeCompletionMatching(String sessionId)                                       Runs completion matching for a closed Session against today’s CalendarDay. Date-strict in user timezone. DrillID matching. First-match ordering. Overflow handling per Section 8 §8.3.3.
  --------------------------- ---------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

