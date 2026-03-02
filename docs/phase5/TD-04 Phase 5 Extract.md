# TD-04 Entity State Machines — Phase 5 Extract (TD-04v.a4)
Sections: §2.6 CalendarDay Slot, §2.8 Routine, §2.9 Schedule
============================================================

## §2.6 CalendarDay Slot

2.6 CalendarDay Slot

CalendarDay Slots are stored as a JSON array on the CalendarDay entity. Each Slot position has an independent lifecycle. Slot state is derived from the CompletionState enum field and the presence/absence of DrillID and SessionID.

2.6.1 State Definitions

  --------------------- ----------------- ---------- ----------- ----------------------------------------------------------------------
  State                 CompletionState   DrillID    SessionID   Description

  Empty                 N/A               NULL       NULL        Slot exists (capacity allocated) but no drill assigned.

  Filled (Incomplete)   Incomplete        NOT NULL   NULL        Drill assigned. Awaiting completion.

  Completed (Linked)    CompletedLinked   NOT NULL   NOT NULL    Matched to a Closed Session via completion matching.

  Completed (Manual)    CompletedManual   NOT NULL   NULL        User manually marked complete. No linked Session. No scoring impact.
  --------------------- ----------------- ---------- ----------- ----------------------------------------------------------------------

2.6.2 State Transitions

  --------------------- --------------------- ----------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------- --------------------------------
  From                  To                    Trigger                                                           Guard Conditions                                                                                                                                                     Side Effects                                                                                                                  Spec Reference

  Empty                 Filled (Incomplete)   Manual assignment, Routine application, or Schedule application   Slot position ≤ SlotCapacity.                                                                                                                                        DrillID set. OwnerType set (Manual, RoutineInstance, or ScheduleInstance). OwnerID set.                                       Section 8 §8.1; Section 8 §8.2

  Filled (Incomplete)   Completed (Linked)    Completion matching finds matching Closed Session                 Session.DrillID matches Slot.DrillID. Session CompletionTimestamp date (user timezone) matches CalendarDay date. This is earliest unmatched Slot for this DrillID.   CompletingSessionID = matched Session's ID. CompletionState = CompletedLinked.                                                Section 8 §8.3.2

  Filled (Incomplete)   Completed (Manual)    User manually marks complete                                      None.                                                                                                                                                                CompletionState = CompletedManual. No SessionID. No scoring impact.                                                           Section 8 §8.3.4

  Filled (Incomplete)   Empty                 User clears Slot assignment                                       None.                                                                                                                                                                DrillID cleared. OwnerType/OwnerID cleared.                                                                                   Section 8

  Completed (Linked)    Filled (Incomplete)   Linked Session deleted                                            None.                                                                                                                                                                CompletingSessionID cleared. CompletionState reverts to Incomplete. DrillID and ownership preserved.                          Section 8 §8.3.4

  Completed (Manual)    Filled (Incomplete)   User reverses manual completion                                   None.                                                                                                                                                                CompletionState = Incomplete.                                                                                                 Section 8 §8.3.4

  (Overflow creation)   Completed (Linked)    Completion overflow                                               No matching Slot exists and no empty Slots remain on CalendarDay.                                                                                                    New Slot created. SlotCapacity incremented by 1. DrillID set. CompletingSessionID set. Planned = false. OwnerType = Manual.   Section 8 §8.3.3
  --------------------- --------------------- ----------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------- --------------------------------

2.6.3 Slot-Level Sync Merge

CalendarDay is the sole exception to row-level LWW sync (TD-01 §2.4). Each Slot position is merged independently using SlotUpdatedAt. SlotCapacity uses standard row-level LWW. TD-03 §5.4.3 defines the merge algorithm. The server validates that no SlotUpdatedAt exceeds server time + 60 seconds (TD-03 §5.4.4).


## §2.8 Routine

2.8 Routine

Routine is a reusable blueprint with a simple Active/Retired/Deleted lifecycle. Routine state changes have no scoring impact.

2.8.1 State Transitions

  ---------------- ---------------- --------------------------------- ---------------------------------------------------------------------------- -------------------------------------------------------------------------------------------- ----------------------------------------------
  From             To               Trigger                           Guard Conditions                                                             Side Effects                                                                                 Spec Reference

  (None)           Active           User creates Routine              At least one entry (fixed DrillID or Generation Criterion).                  Routine row created. Status = Active.                                                        Section 8 §8.1.2; TD-03 §3.3.6 createRoutine

  Active           Retired          User retires Routine              None.                                                                        Status = Retired. Hidden from selection. Existing RoutineInstances unaffected.               Section 3 §3.1.2

  Retired          Active           User reactivates                  None.                                                                        Status = Active. Returns to selection.                                                       Section 3 §3.1.2

  Active/Retired   Deleted (soft)   User deletes Routine              None.                                                                        IsDeleted=true. RoutineInstance references preserved (self-sufficient). No scoring impact.   Section 3 §3.1.2; TD-03 §3.3.6 deleteRoutine

  Active           Deleted (auto)   All Drills removed from Routine   Drill deletion/retirement removes all fixed entries leaving Routine empty.   Routine auto-deleted. No scoring impact.                                                     Section 3 §3.1.2
  ---------------- ---------------- --------------------------------- ---------------------------------------------------------------------------- -------------------------------------------------------------------------------------------- ----------------------------------------------


## §2.9 Schedule

2.9 Schedule

Schedule follows the same lifecycle pattern as Routine. Application Mode (List or DayPlanning) is set at creation and is effectively immutable for the Schedule's lifetime.

2.9.1 State Transitions

  ---------------- ---------------- ----------------------- ------------------------------------------- --------------------------------------------------------------------------------- ---------------------------------------------
  From             To               Trigger                 Guard Conditions                            Side Effects                                                                      Spec Reference

  (None)           Active           User creates Schedule   At least one entry. Application Mode set.   Schedule row created. Status = Active.                                            Section 8 §8.2; TD-03 §3.3.6 createSchedule

  Active           Retired          User retires            None.                                       Status = Retired. Hidden from selection. Existing ScheduleInstances unaffected.   Section 8

  Retired          Active           User reactivates        None.                                       Status = Active.                                                                  Section 8

  Active/Retired   Deleted (soft)   User deletes            None.                                       IsDeleted=true. ScheduleInstance references preserved. No scoring impact.         TD-03 §3.3.6
  ---------------- ---------------- ----------------------- ------------------------------------------- --------------------------------------------------------------------------------- ---------------------------------------------

