# TD-06 Phased Build Plan — Phase 3 Extract (TD-06v.a6)
Sections: §8 Phase 3 — Drill & Bag Configuration
============================================================

8. Phase 3 — Drill & Bag Configuration

8.1 Scope

Phase 3 builds the Drill management system and Golf Bag configuration. The user can browse System Drills, create User Custom Drills, configure their bag, and set up Club-to-Skill Area mappings. This phase introduces the first entity state machines (Drill, UserDrillAdoption, UserClub).

8.1.1 Spec Sections In Play

-   Section 4 (Drill Entry System) — drill creation, editing, structural identity rules

-   Section 9 (Golf Bag & Club Configuration) — club management, Skill Area mapping, ClubPerformanceProfile

-   Section 14 (System Drill Library) — V1 drill browsing, adoption

-   TD-04 §2.4 (Drill State Machine), §2.5 (UserDrillAdoption), §2.10 (UserClub)

8.1.2 Deliverables

-   DrillRepository with full CRUD (TD-03 §3.3.2): create User Custom Drill, edit anchors (triggers reflow), retire, delete (soft-delete + cascade), duplicate, browse System Drills

-   Drill creation UI: Skill Area selection, subskill mapping, drill type, scoring mode, input mode, metric schema, target definition, club selection mode, anchor entry, set structure

-   Drill immutability enforcement post-creation (TD-04 §2.4.2)

-   System Drill library browsing screen with adoption management

-   Practice Pool view: all Active adopted System Drills and Active User Custom Drills

-   ClubRepository with full CRUD (TD-03 §3.3.5): add club, retire club, set carry distances, Skill Area mapping

-   Golf Bag configuration UI (Section 9)

-   UserSkillAreaClubMapping enforcement: eligible clubs per Skill Area

-   State machine guards for Drill, UserDrillAdoption, and UserClub transitions

8.2 Dependencies

Phase 2B (scoring engine, for anchor-edit reflow trigger). Phase 1 (Drift schema, design system).

8.3 Stubs

-   Live Practice: drills are browsable and configurable but cannot be executed yet

-   Planning: drills appear in the Practice Pool but cannot be added to Routines or Schedules

8.4 Acceptance Criteria

-   User can browse all 28 V1 System Drills organised by Skill Area

-   User can adopt/retire System Drills, affecting Practice Pool membership

-   User can create a User Custom Drill with all required fields

-   Anchor edit on User Custom Drill triggers reflow (verified by materialised table update via dev inspector)

-   Drill deletion soft-deletes and cascades per Section 6 cascade rules

-   Immutable fields cannot be edited post-creation (UI enforces, repository guard enforces)

-   Golf Bag: user can add clubs, set carry distances, map clubs to Skill Areas

-   Putting drills auto-select Putter with no selector displayed (TD-02 §3.7)

-   All state machine transitions match TD-04 tables exactly

-   All screens use Phase 1 design tokens

8.5 Acceptance Test Cases

Automated (required): State machine guard tests for every transition in TD-04 §2.4 (Drill), §2.5 (UserDrillAdoption), §2.10 (UserClub). Both permitted and prohibited transitions. Drill immutability enforcement. Anchor edit reflow trigger.

Manual (required): Drill creation flow end-to-end. System Drill browsing and adoption. Golf Bag configuration. Design system visual verification.

