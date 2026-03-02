# TD-06 Phased Build Plan — Phase 5 Extract (TD-06v.a6)
Sections: §10 Phase 5 — Planning Layer
============================================================

10. Phase 5 — Planning Layer

10.1 Scope

Phase 5 implements the Planning Layer from Section 8: Routines, Schedules, the Calendar, Slot management, and completion matching. This phase connects the completion matching stub from Phase 4 to the real implementation.

10.1.1 Spec Sections In Play

-   Section 8 (Practice Planning Layer) — Routines, Schedules, Calendar, Slots, completion matching, assisted generation

-   TD-03 §3.3.6 (PlanningRepository)

-   TD-04 §2.6 (CalendarDay Slot), §2.8 (Routine), §2.9 (Schedule)

10.1.2 Deliverables

-   PlanningRepository with full CRUD for Routine, Schedule, CalendarDay, RoutineInstance, ScheduleInstance

-   Routine management UI: create, edit, delete. Fixed entries and generated entries.

-   Schedule management UI: List mode and DayPlanning mode (Section 8 §8.2)

-   Calendar UI: day view with Slots, slot capacity management, manual drill assignment

-   Routine instantiation: template → PracticeBlock snapshot, linkage severed

-   Schedule instantiation: template → CalendarDay Slots population

-   Completion matching (Section 8 §8.3.2): date-strict, DrillID matching, first-match ordering

-   Completion overflow (Section 8 §8.3.3)

-   Auto-deletion: empty Routines auto-deleted when referenced Drill is deleted/retired

-   CalendarDay Slot state transitions per TD-04 §2.6

10.2 Dependencies

Phase 4 (Sessions for completion matching). Phase 3 (drills for Routine entries and Slot assignments).

10.3 Stubs

-   Slot-level merge: CalendarDay Slots function locally. Cross-device Slot merge is Phase 7B.

10.4 Acceptance Criteria

-   User can create a Routine with fixed and generated entries

-   User can instantiate a Routine into a PracticeBlock (linkage severed)

-   User can create a Schedule in both List and DayPlanning modes

-   Calendar shows days with Slots; user can assign drills manually

-   Completion matching: closing a Session auto-matches to the first eligible Slot on the same date (user timezone)

-   Completion overflow handled correctly

-   Drill deletion cascades to Routine entries; empty Routines auto-delete

-   All Slot state transitions match TD-04 §2.6

-   All screens use design system tokens

10.5 Acceptance Test Cases

Automated (required): Completion matching tests: date-strict (correct timezone), DrillID matching, first-match ordering, duplicate handling, overflow. State machine guard tests for CalendarDay Slot, Routine, Schedule. Auto-deletion cascade test.

Manual (required): Routine creation and instantiation. Schedule creation in both modes. Calendar Slot assignment. Completion matching observed after Session close.

