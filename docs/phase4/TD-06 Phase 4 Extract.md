# TD-06 Phased Build Plan — Phase 4 Extract (TD-06v.a6)
Sections: §9 Phase 4 — Live Practice
============================================================

9. Phase 4 — Live Practice

9.1 Scope

Phase 4 is the largest feature phase. It implements the full Live Practice workflow from Section 13: PracticeBlock lifecycle, PracticeEntry queue management, Session execution (structured, unstructured, and Technique Block), Instance logging with real-time scoring feedback, and the Session close scoring pipeline. This phase introduces multiple time-dependent behaviours (auto-close timers, inactivity timers, lock-gated operations). All timer logic is encapsulated in a single TimerService abstraction, tested in isolation, before UI integration.

9.1.1 Spec Sections In Play

-   Section 3 (User Journey Architecture) — practice session flow, single-active-Session rule

-   Section 4 (Drill Entry System) — Instance logging per input mode

-   Section 11 (Metrics Integrity & Safeguards) — IntegrityFlag detection

-   Section 13 (Live Practice Workflow) — full workflow

-   Section 14 (Drill Entry Screens) — per-schema entry screens

-   TD-03 §3.3.3 (PracticeRepository), §4.4 (Session Close Scoring Pipeline)

-   TD-04 §2.1–2.3 (PracticeEntry, Session, PracticeBlock State Machines)

9.1.2 Deliverables

-   TimerService abstraction: A single injectable service managing all time-dependent behaviours: 2-hour Session inactivity timer, 4-hour PracticeBlock auto-end timer, and timer suspension/resumption during scoring lock (TD-04 §2.3.4). The TimerService is mockable, accepts a clock dependency for testing, and is tested in complete isolation before integration with Session/PracticeBlock state machines. Timer logic is never embedded directly in UI widgets or Repository methods.

-   PracticeRepository with all composite operations (TD-03 §3.3.3)

-   PracticeEntry queue UI: add from Practice Pool, remove, reorder

-   Session execution screens per input mode: Grid Cell Selection (1×3, 3×1, 3×3), Continuous Measurement, Raw Data Entry, Binary Hit/Miss, Technique Block (timer only)

-   Target definition display: resolved target distance and target box size per Instance

-   Club selection per Instance: Random, Guided, User Led modes

-   Real-time scoring feedback: Instance 0–5 score displayed after each attempt

-   Structured completion: auto-close on final Instance of final Set

-   Unstructured completion: manual End Drill button

-   Auto-close: 2-hour Session inactivity, 4-hour PracticeBlock inactivity (via TimerService)

-   Session close scoring pipeline (TD-03 §4.4)

-   Session discard: hard-delete with no scoring trace

-   Post-close editing: Instance value edit, Instance deletion (unstructured only), Session deletion. All trigger reflow.

-   PracticeBlock closure: manual end, auto-end, empty block cleanup

-   Post-Session Summary screen (Section 13 §13.13)

-   IntegrityFlag detection on Session close

9.2 Dependencies

Phase 3 (drills and clubs must exist). Phase 2B (scoring engine and reflow for Session close pipeline).

9.3 Stubs

-   Completion matching: stub records call, does not perform Calendar matching (Phase 5)

-   Planning integration: PracticeBlocks are standalone, not linked to Routines or Schedules

9.4 Acceptance Criteria

-   User can start a PracticeBlock, add drills to queue, and execute them sequentially

-   All six input mode screens functional

-   Structured drill auto-completes on final Instance of final Set

-   Unstructured drill requires manual End Drill

-   Technique Block shows timer only, no scoring

-   Real-time scoring: Instance 0–5 score visible after each attempt

-   Session close triggers scoring pipeline: materialised tables updated within 200ms

-   Session discard leaves no trace in materialised tables

-   Post-close Instance edit triggers reflow

-   Single-active-Session rule enforced

-   PracticeBlock auto-ends after 4 hours without new Session (via TimerService)

-   Session auto-closes after 2 hours of inactivity (via TimerService)

-   Timer suspension: timers pause during scoring lock, resume with preserved remaining duration

-   IntegrityFlag set correctly on boundary breach

-   Post-Session Summary shows all Sessions with scores, deltas, and integrity flags

-   Grid cell tap: 120ms colour flash, single haptic tick (Section 15 §15.8.3)

-   All screens use design system tokens

9.5 Acceptance Test Cases

Automated (required): TimerService isolation tests (tested before UI integration): 2-hour timer fires at correct time, 4-hour timer fires at correct time, timer pauses on lock acquisition, timer resumes with exact remaining duration on lock release, timer does not fire during pause period, multiple concurrent timers do not interfere, clock dependency injection allows deterministic testing without real delays. State machine guard tests for every transition in TD-04 §2.1 (PracticeEntry), §2.2 (Session), §2.3 (PracticeBlock). Session close scoring pipeline integration test. IntegrityFlag detection boundary tests.

Manual (required): Full Live Practice flow end-to-end for each drill type. Auto-close timers (accelerated via injected clock for testing). Post-close editing. Queue management. Design system visual verification.

