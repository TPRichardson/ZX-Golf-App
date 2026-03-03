# TD-06 Phased Build Plan — Phase 2B Extract (TD-06v.a6)
Sections: §7 Phase 2B — Reflow & Lock Layer
============================================================

7. Phase 2B — Reflow & Lock Layer

7.1 Scope

Phase 2B wraps the pure scoring functions from Phase 2A in the reflow orchestration engine. This phase introduces database writes (materialised tables), lock acquisition, the RebuildGuard, the Session close scoring pipeline, deferred reflow coalescing, developer instrumentation, and a profiling benchmark harness. The pure functions are proven correct (Phase 2A). The server infrastructure and DTO layer are proven sound (Phase 2.5). This phase proves the orchestration is correct.

7.1.1 Spec Sections In Play

-   Section 7 (Reflow Governance) — reflow trigger catalogue, lock semantics, side effects

-   TD-03 §4 (Reflow Process Contract) — executeReflow, executeFullRebuild, RebuildGuard, scoring pipeline

-   TD-04 §3 (Reflow Algorithm) — 10-step scoped reflow, full rebuild, deferred coalescing

-   TD-05 (Scoring Engine Test Cases) — Sections 10–12 (reflow scenarios, edge cases, determinism)

7.1.2 Deliverables

-   ScoringRepository with full implementation of executeReflow (TD-03 §4.2, TD-04 §3.2) and executeFullRebuild (TD-04 §3.3)

-   UserScoringLock acquisition and release with 30-second expiry (Step 1 / Step 10)

-   Scope determination: single-mapped (1 subskill), dual-mapped (2), allocation change (all in Skill Area), full rebuild (all 19)

-   Materialised table writes within Drift transactions: MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore

-   RebuildGuard coordination mechanism (TD-03 §4.5): in-memory singleton, 30-second timeout, deferred reflow queue

-   Deferred reflow coalescing (TD-04 §3.3.3): merge pending triggers by subskill union, single execution

-   Session close scoring pipeline (TD-03 §4.4, TD-04 §3.1.4): runs outside UserScoringLock, appends to window, recomputes subskill chain

-   IntegritySuppressed reset on reflow (Section 11 §11.6.3, TD-04 §3.2 Step 9)

-   EventLog emission for ReflowComplete

-   Crash recovery: expired lock detection on startup, automatic full rebuild

-   Developer instrumentation:

    -   Structured logging framework with domain tags and log levels

    -   Reflow diagnostic logging: trigger, scope, duration, lock wait, row counts

    -   Dev-mode materialised table inspector (debug screen, not user-facing)

    -   Dev-mode reflow trigger console: manually fire scoped and full reflows, inspect before/after state

-   Profiling benchmark harness:

    -   Automated benchmark that populates Drift with defined data volumes (500/5K, 5K/50K Sessions/Instances) and executes scoped reflow and full rebuild

    -   Logs p50, p95, and p99 durations over 10 consecutive runs

    -   Records peak heap allocation during each run (via Dart ProcessInfo or equivalent). Flags any run exceeding 256MB peak heap on Pixel 5a class device.

    -   Flags any single run exceeding TD-01 §4.2 targets (150ms scoped, 1s full rebuild)

    -   Reusable in later phases: Phase 4 can run the harness after adding live practice data, Phase 7B after merge

-   Automated test suite covering TD-05 Sections 10–12 plus lock and orchestration tests

7.2 Dependencies

Phase 2A (pure scoring functions). Phase 2.5 (DTO layer validated, server schema deployed). Phase 1 (Drift schema, seed data).

7.3 Stubs

-   No UI for reflow — all verification via automated tests and dev instrumentation

-   Test data fixtures: pre-built Instance, Session, Set, PracticeBlock rows inserted directly into Drift for test setup

-   Completion matching in Session close pipeline: stub that records the call but does not match (Phase 5)

7.4 Acceptance Criteria

-   All TD-05 test cases in Sections 10–12 pass (reflow scenarios, edge cases, determinism verification)

-   Scoped reflow completes in < 150ms on Pixel 5a with 500 Sessions and 5,000 Instances (TD-01 §4.2)

-   Full rebuild completes in < 1 second on Pixel 5a with 5,000 Sessions and 50,000 Instances

-   Profiling harness reports p95 within target on 10 consecutive runs

