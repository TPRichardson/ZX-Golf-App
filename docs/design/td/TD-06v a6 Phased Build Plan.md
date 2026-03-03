TD-06 — Phased Build Plan

Version TD-06v.a6 — Canonical

Harmonised with: Section 0 (0v.f1), Section 1 (1v.g2), Section 2 (2v.f1), Section 3 (3v.g8), Section 4 (4v.g9), Section 5 (5v.d6), Section 6 (6v.b7), Section 7 (7v.b9), Section 8 (8v.a8), Section 9 (9v.a2), Section 10 (10v.a5), Section 11 (11v.a5), Section 12 (12v.a5), Section 13 (13v.a7), Section 14 (14v.a4), Section 15 (15v.a3), Section 16 (16v.a5), Section 17 (17v.a4), TD-01 (TD-01v.a4), TD-02 (TD-02v.a6), TD-03 (TD-03v.a5), TD-04 (TD-04v.a4), TD-05 (TD-05v.a3).

1. Purpose

This document divides the full ZX Golf App specification into buildable increments. Each phase produces a working, testable slice of the application. Claude Code receives the full specification suite as context but is scoped to one phase at a time. The plan defines what is built, what is stubbed, and what the acceptance criteria are for each phase.

TD-06 is the master sequencing document for all Claude Code sessions. No code is written outside the scope of the current phase. Phase boundaries are hard gates: a phase is not complete until all acceptance criteria and required test cases pass.

1.1 Design Decisions

Early Server Validation. The indicative structure in the Technical Design To-Do placed Offline & Sync at Phase 7. TD-06 introduces a Phase 2.5 (Server Foundation) immediately after the Pure Scoring Library and before the Reflow & Lock Layer. This validates Supabase connectivity, schema deployment, RLS join performance, and the upload/download round-trip on a proven scoring math foundation, before the orchestration layer adds complexity.

Design-Early Foundation. Rather than deferring all branding to a final polish phase, Phase 1 establishes the core design system from Section 15: colour tokens, typography scale, spacing grid, shape language, and base component library. Every subsequent phase builds against these tokens. The final phase (Phase 8) is refinement and polish, not a full reskin.

Automated Tests for Invisible Logic. Automated unit and integration tests are required for the scoring engine (Phase 2A), reflow orchestration (Phase 2B), state machine guards (Phases 3–4), sync merge logic (Phases 7A–7B), and completion matching (Phase 5). These layers are invisible to the user and their bugs are silent. UI-facing features use manual verification against defined acceptance criteria.

Performance Baseline. The target device for all performance validation is a Pixel 5a (2021 mid-range) or equivalent. All TD-01 §4.2 performance targets must be met on this device class. Performance is validated at the phase where each engine is built, not deferred to a later phase. Profiling methodology is defined alongside the targets.

Scoring Engine Split. The scoring engine is divided into Phase 2A (pure scoring functions, no side effects) and Phase 2B (reflow orchestration, locking, materialised writes). This reduces debugging surface: if a Phase 2A test fails, the fault is in scoring logic. If a Phase 2B test fails, the fault is in orchestration. Pure functions are proven correct before the state management layer wraps them.

Optimised Validation Ordering. Phase 2.5 (Server Foundation) is sequenced between Phase 2A and Phase 2B. Phase 2A validates scoring math. Phase 2.5 validates the server schema, DTO round-trip, and RLS policies. Phase 2B then builds reflow orchestration on both a validated scoring library and a validated server infrastructure. This prevents reflow bugs from producing false negatives during server validation, and ensures DTO serialisation issues are caught before orchestration adds complexity.

Sync Engine Split. The sync layer is divided into Phase 7A (transport, upload/download, DTO), Phase 7B (merge algorithm, completion matching, deterministic rebuild), and Phase 7C (conflict UI, offline hardening, token lifecycle). The sync layer is effectively a second engine with complexity comparable to the scoring engine. Splitting it reduces multi-dimensional debugging and allows each sub-layer to be proven independently.

Instrumentation-First. Developer instrumentation (logging scaffolding, materialised table inspector, reflow diagnostic console, profiling benchmark harness) is built as part of Phase 2B, not deferred to a later phase. These tools pay for themselves immediately by reducing debugging cost in every subsequent phase.

Sync Rollback Strategy. Phase 7A introduces a feature flag for sync enablement. If Phase 7B merge logic destabilises the system, sync can be disabled without code rollback. The application reverts to local-only operation (which is fully functional by end of Phase 6) while merge issues are resolved.

2. Phase Summary

The build is organised into twelve phases. Each phase produces a working, testable increment. The phases are strictly sequential: Phase N must pass all acceptance criteria before Phase N+1 begins.

Execution order: 1 → 2A → 2.5 → 2B → 3 → 4 → 5 → 6 → 7A → 7B → 7C → 8

  ------- --------------------------------- ----------------------------------------------------------------------------------------------- ----------------------------------
  Phase   Name                              Primary Deliverable                                                                             Spec Sections

  1       Data Foundation & Design System   DDL deployed, Drift schema, seed data, design tokens, base components                           S6, S15, S16, TD-01, TD-02

  2A      Pure Scoring Library              Scoring adapters, window composition, aggregation. All pure functions tested.                   S1, S2, TD-05

  2.5     Server Foundation                 Supabase round-trip validated, RLS confirmed, DTO layer proven                                  S16, S17, TD-01, TD-02, TD-03 §5

  2B      Reflow & Lock Layer               Reflow engine, locks, RebuildGuard, materialised writes, instrumentation, profiling             S7, TD-03 §4, TD-04 §3, TD-05

  3       Drill & Bag Configuration         Drill CRUD, Golf Bag, Club-to-Skill Area mapping, Practice Pool                                 S4, S9, S14, TD-04

  4       Live Practice                     PracticeBlock lifecycle, Session execution, Instance logging, TimerService, real-time scoring   S3, S4, S11, S13, S14, TD-04

  5       Planning Layer                    Routines, Schedules, Calendar, Slot management, completion matching                             S8, TD-04

  6       Review & Analysis                 SkillScore display, trends, Skill Area breakdowns, drill history, window visualisation          S5, S12

  7A      Sync Transport & DTO              Upload/download RPC, DTO layer, sync triggers, feature flag, batching                           S17, TD-01, TD-03 §5

  7B      Merge & Rebuild                   Full merge algorithm, LWW, delete-always-wins, Slot merge, randomised harness                   S17, TD-01 §2, TD-03 §5.4–5.5

  7C      Conflict UI & Offline Hardening   Conflict UI, offline indicators, token lifecycle, schema gating, storage monitoring             S17, TD-01 §2–3

  8       Polish & Hardening                Settings, integrity UI, accessibility audit, motion refinement, migration playbook              S10, S11, S15, S17
  ------- --------------------------------- ----------------------------------------------------------------------------------------------- ----------------------------------

3. Cross-Phase Infrastructure

The following infrastructure is established in Phase 1 and used by all subsequent phases. It is not re-established in later phases.

3.1 Flutter Project Structure

The project follows a feature-first directory structure with shared core modules. The structure is established in Phase 1 and expanded as phases add features.

-   lib/core/ — design tokens, theme, shared widgets, constants, error types

-   lib/core/scoring/ — pure scoring functions (Phase 2A), reflow orchestration (Phase 2B)

-   lib/core/sync/ — sync engine (Phase 2.5, expanded Phases 7A–7C)

-   lib/core/instrumentation/ — logging, diagnostics, profiling, dev tools (Phase 2B)

-   lib/core/services/ — TimerService and other shared service abstractions (Phase 4)

-   lib/data/ — Drift database, DAOs, repository layer

-   lib/data/dto/ — sync DTO serialisation (Phase 2.5)

-   lib/features/ — feature modules (drill/, practice/, planning/, review/, settings/)

-   lib/providers/ — Riverpod providers, organised by domain

-   test/ — mirrors lib/ structure for unit and integration tests

-   supabase/migrations/ — 001_create_schema.sql, 002_seed_reference_data.sql

3.2 Design System Foundation (Section 15)

Phase 1 establishes the design token architecture from Section 15. All values are drawn from the canonical branding specification. The token structure is:

-   Colour tokens: interaction (primary CTA, selected states), semantic performance (hit/miss/warning/destructive), heatmap (grey-to-green continuous opacity)

-   Typography: Technical Geometric Sans (Manrope as primary candidate), tabular lining numerals, text hierarchy per §15.5

-   Spacing: 4px base grid, all values multiples of 4, no arbitrary spacing

-   Shape: 8px container radius for segmented controls, no pill shapes, radius tokens per §15.7

-   Surface: dark-first interface, tonal elevation only, no shadows/glow/blur

-   Motion: max 200ms transitions, ease-in-out cubic only, haptic tick on grid tap

-   Base components: primary/secondary/destructive/text buttons, cards, input fields, app bar, segmented controls

Interaction and semantic colour layers are architecturally separate per §15.3. The interaction accent (cyan) is never used for scoring outcomes. Miss uses neutral cool grey, not red. All token names are product-name agnostic per §15.14.

3.3 Riverpod Provider Architecture

Riverpod providers are scoped to the authenticated user session. On logout, all providers are disposed and the local database is cleared (TD-03 §3.1). Providers are organised by domain repository.

3.4 Error Type Hierarchy

The ZxGolfAppException base class and subclasses (TD-03 §7.2) are established in Phase 1. All phases use the same error model. TD-07 will expand the error handling patterns; Phase 1 establishes the type structure.

3.5 Observability & Logging

A structured logging framework is established in Phase 2B and used by all subsequent phases. The framework provides:

-   Log levels: debug, info, warning, error. Debug and info suppressed in release builds.

-   Domain tagging: each log entry carries a domain tag (scoring, sync, practice, planning, repository) for filtering.

-   Reflow diagnostics: trigger type, affected subskills, duration, lock wait time, materialised row counts. Logged at info level on every reflow completion.

-   Sync diagnostics: upload/download payload sizes, merge conflict counts, rebuild duration, failure reasons. Logged at info level on every sync cycle completion.

-   Dev-mode materialised table inspector: a debug screen (hidden behind a developer toggle, not user-facing) that displays the current contents of all four materialised tables. Available from Phase 2B onward.

-   Profiling harness: a benchmark utility that executes reflow and rebuild at defined data volumes, logs percentile timings (p50, p95, p99) and peak heap allocation, and flags any run exceeding latency or memory targets. Used for performance validation in Phase 2B and subsequent phases.

Logging is lightweight and does not affect performance targets. Log output is directed to the platform console (Dart developer tools). No remote log aggregation in V1. EventLog (the database entity) is the persistent audit trail; the logging framework is the ephemeral developer tool.

3.6 Sync-Awareness Guidance for Pre-Sync Phases

Phases 3–6 build features against the local Drift database before the sync engine is complete. To avoid costly retrofitting in Phases 7A–7C, all pre-sync phases must observe the following constraints:

-   No assumptions about monotonic timestamps. Session ordering may change after merge introduces remotely-created Sessions with earlier CompletionTimestamps.

-   No assumptions about fixed window composition. Windows are rebuilt from raw data on every reflow. UI code must not cache window membership across navigation events.

-   All reads through reactive streams. UI code never snapshots a query result and assumes it remains valid. Drift streams automatically re-emit on data changes, including merge-induced changes.

-   No hardcoded single-device assumptions. Entity counts, ordering, and IDs may change after sync. UI code that displays lists must handle insertions and reordering gracefully.

These constraints are architectural, not sync-specific. They ensure correctness in the single-device case and prevent assumptions that break under multi-device merge.

3.7 SyncWriteGate Timeout Semantics

The SyncWriteGate (TD-03 §2.1.1) coordinates access between the Repository layer and the Sync merge phase. Its timeout behaviour must be unambiguous to prevent deadlock or data corruption:

-   Drain period (2 seconds): On acquireExclusive(), the gate waits up to 2 seconds for in-flight Repository write transactions to complete. If the drain period expires with an active write, sync defers to the next trigger. No merge begins.

-   Hard timeout (60 seconds): If the merge Drift transaction exceeds 60 seconds after gate acquisition, the timeout fires. The merge transaction is aborted. The Drift transaction rolls back completely — no partial state is committed. The gate force-releases. An error is logged (domain: sync, level: error, detail: merge timeout exceeded). Suspended Repository writes resume. Sync retries on the next trigger.

-   Crash safety: The gate is an in-memory singleton, not persisted. If the app crashes while the gate is held, the gate resets on restart. The merge transaction (being a Drift transaction) is rolled back by SQLite’s journal recovery. No manual intervention required.

This specification eliminates ambiguity: the 60-second timeout always results in a full abort and rollback, never a partial merge or a gate release with an active transaction.

4. Phase 1 — Data Foundation & Design System

4.1 Scope

Phase 1 builds the data layer and visual foundation. No business logic beyond basic CRUD. No scoring. No sync. The goal is a running Flutter application with an initialised local database, seed data loaded, and the design system rendering correctly.

4.1.1 Spec Sections In Play

-   Section 6 (Data Model) — all entity definitions

-   Section 15 (Branding & Design System) — full design token architecture

-   Section 16 (Database Architecture) — table groups, indexes, constraints

-   TD-01 (Technology Stack) — Flutter project setup, Drift configuration, Riverpod scaffolding

-   TD-02 (Database DDL) — local Drift schema generation, seed data loading

4.1.2 Deliverables

-   Flutter project initialised with directory structure per §3.1

-   Drift schema generated from TD-02 DDL (28 tables, all enum types as TEXT with validation)

-   Seed data loaded: 16 EventTypes, 19 Subskills, 8 MetricSchemas, 28 System Drills, 1 SystemMaintenanceLock

-   Repository layer scaffolded with standard CRUD pattern (TD-03 §3.2)

-   Design token Dart file: colours, typography, spacing, shape, surface, motion constants

-   Base component library: buttons (primary, secondary, destructive, text), cards, input fields, app bar, segmented controls

-   Theme data class wrapping all tokens, applied to MaterialApp

-   Riverpod provider scaffolding (database provider, repository providers)

-   Error type hierarchy (ZxGolfAppException and subclasses)

-   A minimal shell screen demonstrating: theme applied, seed data queryable, design components rendering

4.2 Dependencies

None. Phase 1 is the starting point.

4.3 Stubs

-   ScoringRepository: empty class with method signatures, no implementation

-   SyncEngine: empty class, no network calls

-   Authentication: hardcoded local user ID for development

-   Navigation: placeholder shell with bottom navigation tabs (Plan, Track, Review)

4.4 Acceptance Criteria

-   Flutter app launches on Pixel 5a emulator in under 3 seconds

-   All 28 Drift tables created and queryable

-   All seed data present and correct (19 SubskillRef rows with allocations summing to 1000, 28 System Drills with deterministic UUIDs, 16 EventTypes, 8 MetricSchemas)

-   CRUD operations verified on at least 3 entity types (User, Drill, UserClub)

-   Nullable column audit: every NOT NULL column in TD-02 is NOT NULL in Drift schema. No nullable column allows an invalid domain state (e.g. a Drill with null SkillArea).

-   Design tokens render correctly: dark surface, interaction accent, semantic colours distinct, 4px grid spacing, typography hierarchy visible

-   Base components render and respond to interaction (button press darkens surface ~4%, no bounce)

-   Drift reactive streams emit when data changes (verified by inserting a row and observing stream emission)

4.5 Acceptance Test Cases

Manual verification against the criteria above. No automated tests required for Phase 1 beyond Drift schema generation validation (compile-time check).

5. Phase 2A — Pure Scoring Library

5.1 Scope

Phase 2A implements all scoring functions as pure, side-effect-free Dart functions. No database writes, no locks, no reflow orchestration, no repository dependencies. Each function takes input data and returns a computed result. This isolation guarantees that any test failure in Phase 2A is a scoring logic bug, not an orchestration or persistence bug.

5.1.1 Spec Sections In Play

-   Section 1 (Scoring Engine) — two-segment linear interpolation, window composition, aggregation

-   Section 2 (Skill Architecture) — subskill allocations, 65/35 weighting

-   TD-05 (Scoring Engine Test Cases) — Sections 4–9 (Instance, Session, Window, Subskill, Skill Area, Overall)

5.1.2 Deliverables

-   scoreInstance(rawMetrics, anchors, metricSchema) → double (0–5). Two-segment linear interpolation with hard cap at 5. Pure function.

-   Scoring adapters per MetricSchema: grid_1x3_direction, grid_3x1_distance, grid_3x3_multioutput, binary_hit_miss, raw_carry_distance, raw_ball_speed, raw_club_head_speed. Each adapter extracts the relevant metric from RawMetrics JSON and delegates to scoreInstance.

-   scoreSession(instances) → double. Simple average of all Instance 0–5 scores across all Sets. Pure function.

-   composeWindow(sessions, maxOccupancy) → WindowState. Orders by CompletionTimestamp DESC, SessionID DESC. Walks forward summing occupancy (1.0 single-mapped, 0.5 dual-mapped). Includes entries up to ≤ 25.0 occupancy. Handles partial roll-off (1.0 → 0.5 with score preserved). Returns entries list, totalOccupancy, weightedSum, windowAverage. Pure function.

-   scoreSubskill(transitionWindow, pressureWindow, allocation) → SubskillScore. WeightedAverage = (TransitionAvg × 0.35) + (PressureAvg × 0.65). SubskillPoints = Allocation × (WeightedAverage / 5). Handles empty windows (average = 0.0). Pure function.

-   scoreSkillArea(subskillScores) → double. Sum of SubskillPoints. Pure function.

-   scoreOverall(skillAreaScores) → double. Sum of all 7 Skill Area scores. Maximum 1000. Pure function.

-   evaluateIntegrity(instances, metricSchema) → bool. Checks HardMinInput/HardMaxInput bounds per Section 11. Grid Cell Selection and Binary Hit/Miss excluded. Values at boundary are not in breach. Pure function.

-   Automated test suite covering TD-05 Sections 4–9

5.2 Dependencies

Phase 1 (Drift schema for type definitions, seed data for SubskillRef allocations and System Drill anchors used in test fixtures).

5.3 Stubs

-   No database writes — all functions operate on in-memory data structures

-   No reflow — functions are called directly in tests with constructed inputs

-   No lock mechanics — pure functions have no concurrency concerns

5.4 Acceptance Criteria

-   All TD-05 test cases in Sections 4–9 pass (Instance scoring, Session scoring, window composition, subskill scoring, Skill Area scoring, Overall SkillScore)

-   scoreInstance produces exact results for all boundary cases: below Min (→0.0), at Min (→0.0), mid-range, at Scratch (→3.5), between Scratch and Pro, at Pro (→5.0), above Pro (→5.0 capped)

-   composeWindow handles: empty window, partial fill, full 25-unit fill, overflow eviction, dual-mapped 0.5 occupancy, mixed occupancy, boundary case (0.5 fits but 1.0 does not), partial roll-off (1.0 → 0.5)

-   All calculations use IEEE 754 double-precision. No intermediate rounding. Assertions use 1e-9 tolerance (TD-05 §2.2).

-   evaluateIntegrity correctly identifies breaches and non-breaches, excludes Grid/Binary schemas

5.5 Acceptance Test Cases

Automated (required): All TD-05 Sections 4–9 implemented as Dart unit tests. Each test case follows the Given → When → Then format from TD-05. Test runner must report 100% pass rate.

6. Phase 2.5 — Server Foundation

6.1 Scope

Phase 2.5 deploys the Supabase schema, validates server connectivity, and confirms that the sync round-trip works at a basic level. This is sequenced after Phase 2A and before Phase 2B so that the server infrastructure and DTO layer are validated on a proven scoring math foundation, before reflow orchestration adds complexity. Materialised tables are not populated at this point (reflow has not been built), but all source tables (PracticeBlock, Session, Set, Instance, Drill, etc.) are available for round-trip validation. Materialised tables are local-only and never synced (TD-01 §2.10), so their absence does not affect server validation.

6.1.1 Spec Sections In Play

-   Section 16 (Database Architecture) — Postgres DDL deployment, RLS policies, indexes

-   Section 17 (Real-World Application Layer) — sync transport basics

-   TD-01 (Technology Stack) — Supabase project setup, authentication

-   TD-02 (Database DDL) — 001_create_schema.sql, 002_seed_reference_data.sql deployed to Supabase

-   TD-03 §5 (Sync Transport Layer) — sync_upload and sync_download RPC functions, DTO layer

6.1.2 Deliverables

-   Supabase project created and configured

-   001_create_schema.sql executed against Supabase Postgres (28 tables, 21 enum types, 16 triggers, 41 indexes, 28 RLS policies)

-   002_seed_reference_data.sql executed (reference data and V1 System Drill Library)

-   Google Sign-In authentication flow functional (Supabase Auth)

-   sync_upload RPC function deployed and tested (TD-03 §5.2)

-   sync_download RPC function deployed and tested (TD-03 §5.3)

-   DTO serialisation layer (sync_dto.dart) for upload and download payloads (TD-03 §5.2.5)

-   Basic sync engine class with upload and download methods (full merge logic deferred to Phase 7B)

-   Schema version gating: client validates schema_version on sync (TD-01 §2.9)

6.2 Dependencies

Phase 2A (scoring math proven, type definitions available for DTO serialisation). Phase 1 (Drift schema, seed data).

6.3 Stubs

-   Merge algorithm: Phase 2.5 downloads remote changes but does not implement the full merge logic. Phase 7B completes this.

-   SyncWriteGate: class exists with acquire/release methods, but gating is not enforced until Phase 7B.

-   Sync triggers: manual only (button press). Automatic triggers deferred to Phase 7A.

-   Payload batching: single-batch upload only. 2MB batching logic deferred to Phase 7A.

6.4 Acceptance Criteria

-   Supabase schema deployed without errors (all 28 tables, 21 enum types, 16 triggers, 41 indexes, 28 RLS policies)

-   Seed data present on server (16 EventTypes, 19 Subskills, 8 MetricSchemas, 28 System Drills)

-   Google Sign-In completes and returns valid JWT

-   sync_upload accepts a payload with 1 PracticeBlock, 1 Session, 1 Set, and 3 Instances. Server confirms receipt. RLS passes.

-   sync_download returns the uploaded data for the authenticated user. No data from other users is returned.

-   RLS join performance validated: Instance query through 4-join chain (Instance → Set → Session → PracticeBlock → UserID) completes in < 50ms with 1,000 representative rows per table.

-   Schema version mismatch correctly returns SCHEMA_VERSION_MISMATCH error

-   Upload idempotency verified: same payload sent twice produces identical server state (TD-03 §5.2.3)

-   DTO round-trip verified: entity serialised to JSON, uploaded, downloaded, deserialised back to Drift entity with all fields matching

-   Synthetic bulk payload test: generate and upload a payload representing 100 Sessions with 1,000 Instances (10 Instances per Session). Validates payload serialisation performance, transport overhead, and server ingestion at a volume representative of a moderate practice history. This catches DTO performance and payload size issues before Phase 7A introduces real user-generated data at scale.

6.5 Acceptance Test Cases

Automated (required): DTO serialisation round-trip tests for all synced entity types. Upload idempotency test. Schema version validation test. RLS isolation test (two users, verify data isolation). Synthetic bulk payload test (100 Sessions / 1,000 Instances upload and download).

Manual (required): Google Sign-In flow on physical device. RLS join performance benchmark.

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

-   Peak heap allocation during full rebuild at 50K Instances does not exceed 256MB

-   Reflow is idempotent: running the same reflow twice produces identical materialised state (bit-level for non-numeric, 1e-9 tolerance for numeric columns)

-   Scoring lock blocks concurrent reflow and Instance logging (verified by concurrent test)

-   RebuildGuard defers scoped reflows and coalesces correctly on release

-   Session close pipeline writes to materialised tables without acquiring UserScoringLock

-   Crash recovery: expired lock triggers full rebuild on next launch, produces correct state

-   Dev instrumentation operational: materialised table inspector shows current state, reflow console triggers rebuild successfully, diagnostic logs emitted

7.5 Acceptance Test Cases

Automated (required): All TD-05 Sections 10–12. Lock acquisition tests (acquire, release, expiry, force-acquire). RebuildGuard tests (defer, coalesce, release). Session close pipeline integration test. Crash recovery test (insert expired lock, verify full rebuild on startup). Concurrent reflow blocking test.

Performance (required): Profiling benchmark harness executed on Pixel 5a emulator. p50, p95, p99 timings and peak heap allocation recorded. All p95 values within TD-01 §4.2 targets. Peak heap within 256MB budget.

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

11. Phase 6 — Review & Analysis

11.1 Scope

Phase 6 builds the Review surface: SkillScore dashboard, subskill trends, Skill Area breakdowns, drill history, and window visualisation. This phase is read-only — it reads from materialised tables. No new write operations.

11.1.1 Spec Sections In Play

-   Section 5 (Review) — dashboard, Skill Area detail, subskill detail, drill history, window detail

-   Section 12 (UI/UX Structural Architecture) — Review tab structure, navigation patterns

11.1.2 Deliverables

-   SkillScore dashboard: Overall SkillScore (0–1000), 7 Skill Area scores, heatmap visualisation

-   Skill Area detail: subskill breakdown, allocation weights, Transition/Pressure split

-   Subskill detail: window contents, Session entries, occupancy visualisation

-   Window detail view: ordered entries with scores, occupancy, timestamps

-   Drill history: per-drill Session list with scores and dates

-   Trend visualisation: subskill score over time

-   Heatmap rendering: grey-to-green continuous opacity scaling per §15.3.3. No hard-banded tiers.

-   Score display: tabular lining numerals, no animated counting, neutral presentation (§15.2)

-   Zero state: dashboard displays correctly when no scoring data exists

-   IntegrityFlag indicators at Session level in drill history only (not in SkillScore views per §15.8.5)

-   All reads from materialised tables via ScoringRepository reactive streams

11.2 Dependencies

Phase 4 (closed Sessions populate materialised tables). Phase 2A/2B (scoring engine). Phase 1 (design system).

11.3 Stubs

None. Phase 6 consumes existing data.

11.4 Acceptance Criteria

-   Dashboard shows Overall SkillScore and all 7 Skill Area scores

-   Skill Area detail shows correct subskill breakdown matching SubskillRef seed data

-   Window detail shows entries ordered by CompletionTimestamp DESC with correct scores and occupancy

-   Heatmap uses continuous grey-to-green opacity (no discrete bands, no red)

-   Score communication is neutral: no celebratory text, no emotional framing (§15.2)

-   Zero state handled: empty dashboard renders correctly

-   Cold-start: dashboard loads in < 1 second from materialised tables on Pixel 5a (TD-01 §4.2)

-   WCAG AA minimum contrast on all surfaces, AAA on SkillScore and Subskill score displays

11.5 Acceptance Test Cases

Manual (required): Full Review navigation. Numeric verification against expected scoring. Heatmap visual verification. Zero state. Cold-start timing on Pixel 5a. Contrast verification (WCAG AAA on critical surfaces).

12. Phase 7A — Sync Transport & DTO

12.1 Scope

Phase 7A upgrades the basic sync engine from Phase 2.5 into a production-ready transport layer. It implements automatic sync triggers, payload batching, the sync feature flag, and sync diagnostic logging. No merge logic — downloaded data is stored but not merged. The goal is a reliable, observable transport pipe that Phase 7B can build merge logic on top of.

12.1.1 Spec Sections In Play

-   Section 17 (Real-World Application Layer) — sync triggers, connectivity handling

-   TD-01 §2 (Synchronisation Strategy) — sync pipeline Steps 1–2 (upload, download)

-   TD-03 §5 (Sync Transport Layer) — payload batching, upload idempotency, download performance

12.1.2 Deliverables

-   Automatic sync triggers: connectivity restored, periodic interval (5 minutes default), post-Session-close, post-reflow, manual pull-to-refresh

-   Payload batching (TD-03 §5.2.2): 2MB limit per request, parent-before-child table ordering, partial upload state tracking in SyncMetadata

-   Sync feature flag: boolean toggle (persisted in local settings) that enables/disables the entire sync pipeline. When disabled, app operates in local-only mode. Default: enabled. This provides the rollback mechanism if Phase 7B merge logic causes issues.

-   Sync diagnostic logging: upload/download payload sizes, request durations, HTTP status codes, retry counts, failure reasons. Logged via the instrumentation framework from Phase 2B.

-   Connectivity monitoring: detect online/offline transitions, trigger sync on reconnection

-   Retry logic: exponential backoff on upload/download failure (max 3 retries per sync cycle)

-   RLS performance validation at 100,000 Instances with cold Postgres cache (extends Phase 2.5 validation to production-representative volume)

12.2 Dependencies

Phase 2.5 (basic sync engine, RPC functions, DTO layer). All prior phases (all features produce data that needs syncing).

12.3 Stubs

-   Merge: downloaded data is stored in a staging area but not merged into the live database. Phase 7B implements merge.

-   SyncWriteGate: exists but not enforced. Phase 7B activates gating.

12.4 Acceptance Criteria

-   Sync triggers automatically on connectivity restore and periodic interval

-   Payload exceeding 2MB splits correctly with parent-child ordering

-   Partial upload failure: earlier batches committed, remaining batches retry on next sync

-   Sync feature flag: toggling off stops all sync activity; toggling on resumes normally

-   Sync diagnostic logs capture all transport events

-   RLS join performance at 100,000 Instances with cold cache: < 200ms per query

-   Retry logic: failed uploads retry with exponential backoff, max 3 attempts

12.5 Acceptance Test Cases

Automated (required): Payload batching tests (undersized, at limit, oversized). Parent-child ordering verification. Partial upload state persistence and resumption. Feature flag toggle test.

Manual (required): Connectivity toggle test (airplane mode on/off). Sync diagnostic log review. RLS performance benchmark at 100K Instances.

13. Phase 7B — Merge & Rebuild

13.1 Scope

Phase 7B implements the merge algorithm, the SyncWriteGate, the post-merge pipeline (completion matching + deterministic rebuild), and multi-device convergence verification. This is the highest architectural risk phase in the build. The merge logic must be proven correct by automated tests — including a randomised multi-edit sequence harness — before any manual multi-device testing begins.

13.1.1 Spec Sections In Play

-   Section 17 (Real-World Application Layer) — multi-device sync, convergence

-   TD-01 §2.3–2.6 (Merge Precedence, CalendarDay Merge, Sync Pipeline, Atomicity)

-   TD-03 §5.4–5.5 (Merge Algorithm, Post-Merge Pipeline)

13.1.2 Deliverables

-   Full merge algorithm (TD-03 §5.4): LWW resolution (later UpdatedAt wins), local-wins-tie, additive merge for execution data

-   Delete-always-wins enforcement (TD-01 §2.3): IsDeleted = true on either side produces IsDeleted = true regardless of timestamp

-   CalendarDay Slot-level merge (TD-01 §2.4, TD-03 §5.4.3): per-position independent merge using SlotUpdatedAt

-   SyncWriteGate enforcement (TD-03 §2.1.1): exclusive gate during merge, 2-second drain period, 60-second hard timeout with abort/rollback semantics per §3.7

-   Post-merge pipeline (TD-03 §5.5): completion matching re-run on merged Sessions, deterministic full rebuild (executeFullRebuild via RebuildGuard), SyncMetadata update

-   Merge transaction atomicity: entire merge within single Drift transaction. Failure rolls back completely.

-   Cross-device Session concurrency: dual-Active-Session resolution (later UpdatedAt wins, loser hard-deleted per TD-04 §2.2.3)

-   Server-side SlotUpdatedAt validation (TD-03 §5.4.4): reject future timestamps beyond 60-second tolerance

-   Sync diagnostic logging: merge conflict counts, resolution outcomes, rebuild duration

-   Randomised multi-edit merge harness: An automated test harness that generates N random edit sequences (entity creates, updates, deletes, anchor edits, Slot assignments) on two simulated devices, executes M merge cycles in alternating directions, and asserts deterministic convergence (identical materialised state to 1e-9 tolerance) after each cycle. The harness covers: interleaved delete/update sequences, mixed structural + execution edits, clock skew simulation (± 5 seconds), 3+ sequential edits to the same entity, and CalendarDay Slot conflicts across multiple positions. Default configuration: 100 random sequences, 5 merge cycles each. This tests stability of the rule system under complex interaction, not just correctness of individual rules.

13.2 Dependencies

Phase 7A (transport layer, feature flag). Phase 2B (executeFullRebuild, RebuildGuard). Phase 5 (completion matching for post-merge re-run).

13.3 Stubs

-   Conflict UI: merge executes silently. User-facing conflict indicators deferred to Phase 7C.

-   Offline hardening: basic offline operation works (app is offline-first). Explicit offline indicator UI deferred to Phase 7C.

13.4 Acceptance Criteria

-   LWW merge: later UpdatedAt wins for structural entities. Local wins on exact tie.

-   Delete-always-wins: all four scenarios from TD-01 §2.3 merge precedence table produce correct results

-   CalendarDay Slot merge: independent per-position merge using SlotUpdatedAt

-   Multi-device convergence (deterministic tests): two simulated devices with defined edit sequences produce identical materialised scoring state after sync (verified to 1e-9 tolerance)

-   Multi-device convergence (randomised harness): 100 random edit sequences across two simulated devices produce identical materialised state after 5 merge cycles each. Zero convergence failures.

-   SyncWriteGate: Repository writes suspend during merge phase, resume after release, never blocked longer than 60 seconds. Timeout triggers full abort and rollback per §3.7.

-   SyncWriteGate timeout end-to-end validation: test that (a) gate timeout during post-merge pipeline triggers clean abort; (b) Drift transaction rolls back preserving pre-merge state; (c) EventLog entry with SyncGateTimeout is written; (d) next sync re-executes full pipeline from Step 4. Per TD-03 §5.5.

-   Merge transaction atomicity: simulated failure mid-merge produces complete rollback, no partial state

-   Post-merge completion matching correctly re-evaluates newly merged Sessions

-   Post-merge deterministic rebuild produces correct materialised state

-   If merge destabilises system, sync feature flag (Phase 7A) can be toggled off and app reverts to stable local-only operation

13.5 Acceptance Test Cases

Automated (required): LWW resolution tests (both directions, tie-break). Delete-always-wins (all 4 scenarios from TD-01 §2.3). CalendarDay Slot-level merge (independent positions, conflicting positions, mixed). Deterministic multi-device convergence test: two defined edit sequences, verify identical materialised state. Randomised multi-edit merge harness: 100 random sequences, 5 merge cycles each, zero convergence failures. SyncWriteGate concurrent access test. SyncWriteGate timeout test: simulate merge exceeding 60 seconds, verify abort, rollback, and gate release. Merge transaction rollback test. Post-merge rebuild correctness test.

Manual (required): Two physical devices with different offline edits. Sync both. Verify identical scores on both devices. Feature flag rollback test.

14. Phase 7C — Conflict UI & Offline Hardening

14.1 Scope

Phase 7C completes the sync layer with user-facing elements: offline indicator, sync progress UI, schema version gating UI, token lifecycle management, and storage monitoring integration. This phase does not introduce new merge logic — it surfaces the existing merge behaviour to the user and hardens edge cases.

14.1.1 Spec Sections In Play

-   Section 17 (Real-World Application Layer) — offline indicator, storage warning, schema gating UI

-   TD-01 §2.9 (Schema Version Gating) — user message on mismatch

-   TD-01 §3.3 (Token Lifecycle) — refresh, re-authentication prompt

14.1.2 Deliverables

-   Offline indicator: clear UI signal when operating without connectivity

-   Sync progress UI: visual indicator during extended downloads

-   Schema version gating UI: "App update required to sync" message (TD-01 §2.9). App continues offline.

-   Token lifecycle management (TD-01 §3.3): automatic refresh on reconnection, re-authentication prompt on expired refresh token, no data loss during re-auth

-   Cross-device active Session warning (TD-01 §2.7): online conflict detection, confirmation dialog, hard-discard of previous Session on confirmation

-   Storage monitoring integration (Section 17 §17.3.5): low-storage warning when device storage is critically low. No auto-deletion.

-   Sync status: last sync timestamp visible in settings or status bar

-   Sync-disabled indicator: when the sync feature flag (§17.1) is off, a persistent UI message in Settings and/or the status area states "Sync disabled — data not shared across devices." This prevents users on multiple devices from assuming data consistency when sync is inactive.

14.2 Dependencies

Phase 7B (merge logic must be complete and stable). Phase 7A (transport and feature flag).

14.3 Stubs

None. Phase 7C completes the sync layer.

14.4 Acceptance Criteria

-   Offline indicator appears when connectivity is lost, disappears on reconnection

-   Sync progress shown during extended downloads

-   Schema version mismatch: clear message displayed, sync blocked, app continues offline

-   Token refresh: seamless on reconnection. Expired refresh token: re-auth prompt, no data loss.

-   Cross-device active Session: warning displayed, confirmation required, previous Session discarded on confirmation

-   Low-storage warning displayed when appropriate. No data auto-deleted.

-   All sync-related UI uses design system tokens

-   Sync feature flag off: "Sync disabled" message clearly visible in Settings and/or status area

14.5 Acceptance Test Cases

Manual (required): Airplane mode toggle: offline indicator and sync-on-reconnect. Schema version mismatch simulation. Token expiry simulation (extended offline period). Cross-device active Session conflict on two devices. Low-storage simulation.

15. Phase 8 — Polish & Hardening

15.1 Scope

Phase 8 is the final phase. It covers Settings screens, integrity safeguards UI (suppression toggle), accessibility audit, motion refinement, data migration playbook, and any remaining Section 15 polish. This phase does not introduce new core features — it refines everything built in Phases 1–7C.

15.1.1 Spec Sections In Play

-   Section 10 (Settings & Configuration) — all settings screens

-   Section 11 (Metrics Integrity & Safeguards) — integrity UI: suppression toggle

-   Section 15 (Branding & Design System) — final polish: motion, haptics, accessibility

-   Section 17 (Real-World Application Layer) — environmental edge cases

15.1.2 Deliverables

-   Settings screens (Section 10): all user-configurable settings

-   IntegritySuppressed toggle UI (Section 11 §11.6): per-Session, observational language only

-   Motion refinement: verify all transitions ≤ 200ms, ease-in-out cubic, haptic tick on grid tap

-   Achievement banners (§15.8.4): fade in 150ms, fade out 200ms, factual text, no celebratory effects

-   Accessibility audit: WCAG AA global, AAA on designated critical surfaces, outdoor readability for drill entry screens

-   Error messaging review: all messages factual and actionable (§15.2)

-   Edge case hardening: app crash mid-reflow recovery, empty database cold start, schema migration on update

-   Font finalisation: confirm Technical Geometric Sans choice, tabular numeral verification

-   Product-name agnosticism verification: no brand/title identifiers in tokens, classes, or database identifiers (§15.12, §15.14)

-   Data migration playbook:

    -   Schema evolution strategy: how Drift migrations are written, tested, and deployed

    -   Backwards compatibility test: raw execution data logged under current schema remains valid after migration

    -   Migration timing budget: migrations must complete within 1-second budget or display progress indicator (TD-01 §4.3)

    -   Rollback path: if migration fails, app remains on previous schema version with clear user messaging

    -   Test matrix: migration tested from V1 schema to V1.1 schema with representative data volumes (1K, 10K, 100K Instances)

15.2 Dependencies

All prior phases (1–7C). Phase 8 touches every surface.

15.3 Stubs

None. Phase 8 is the final phase. All stubs from prior phases are resolved or listed in Section 19 (Deferred Items).

15.4 Acceptance Criteria

-   All Settings screens functional per Section 10

-   IntegritySuppressed toggle works per-Session with observational language

-   All transitions verified ≤ 200ms, no prohibited motion patterns (§15.10.4)

-   WCAG AA met on all surfaces, AAA on designated critical surfaces (§15.13)

-   App survives crash mid-reflow: restart triggers full rebuild, scores correct

-   Empty database cold start: dashboard shows zero state in < 1 second

-   No product name or brand identifiers in codebase tokens or database identifiers

-   All error messages factual and actionable

-   Data migration playbook documented and tested at representative volumes

-   Full end-to-end journey: sign in → configure bag → browse drills → plan practice → execute practice → review scores → sync across devices

15.5 Acceptance Test Cases

Manual (required): Full end-to-end journey on Pixel 5a. Settings walkthrough. Integrity suppression toggle. Crash recovery test (force-kill during reflow). Accessibility audit with TalkBack. Motion timing verification. Product-name audit. Migration test at 1K, 10K, 100K Instances.

16. Testing Strategy Summary

Automated tests cover invisible logic layers. Manual verification covers visible UI.

  --------------------------------------- ------------------------------ ----------- ----------------------------------------------------
  Layer                                   Test Type                      Phase       Coverage

  Instance/Session/Window scoring         Automated unit                 2A          100% of TD-05 §4–9

  DTO serialisation round-trip            Automated unit                 2.5         All synced entity types + 100-Session bulk payload

  Reflow orchestration & locks            Automated unit + integration   2B          100% of TD-05 §10–12, lock/guard mechanics

  Performance profiling                   Automated benchmark            2B          p50/p95/p99 latency + peak heap allocation

  State machine guards (Drill, Club)      Automated unit                 3           Every TD-04 §2.4–2.5, §2.10 transition

  State machine guards (Practice)         Automated unit                 4           Every TD-04 §2.1–2.3 transition

  TimerService (auto-close, inactivity)   Automated unit                 4           Fire, pause, resume, boundary, concurrency

  Completion matching                     Automated unit                 5           All Section 8 §8.3 rules

  Payload batching & transport            Automated unit                 7A          Size limits, ordering, partial state

  Merge algorithm (deterministic)         Automated unit + integration   7B          All TD-01 §2.3 scenarios, Slot merge

  Merge algorithm (randomised)            Automated harness              7B          100 random sequences, 5 cycles, zero failures

  Multi-device convergence                Automated integration          7B          Identical state to 1e-9 tolerance

  SyncWriteGate timeout                   Automated unit                 7B          Abort, rollback, gate release on timeout

  UI flows and screens                    Manual verification            3–8         Per-phase acceptance criteria

  Performance targets                     Manual benchmark               2B, 6, 7A   TD-01 §4.2 on Pixel 5a

  Accessibility                           Manual audit                   8           WCAG AA global, AAA designated

  Data migration                          Manual                         8           1K, 10K, 100K volumes
  --------------------------------------- ------------------------------ ----------- ----------------------------------------------------

17. Rollback Strategy

The sync layer (Phases 7A–7C) is the highest-risk addition to a system that is fully functional in local-only mode by end of Phase 6. The rollback strategy ensures that sync issues do not destabilise the working application.

17.1 Sync Feature Flag

Phase 7A introduces a sync feature flag (boolean, persisted in local settings, default: enabled). When disabled:

-   All sync triggers are suppressed. No upload, download, or merge executes.

-   The app operates in local-only mode, identical to end-of-Phase-6 behaviour.

-   All features (practice, planning, review, scoring) function normally.

-   The flag can be toggled by the developer during testing or by a future admin mechanism.

-   When disabled, the Phase 7C sync-disabled indicator (“Sync disabled — data not shared across devices”) is displayed to prevent users from assuming cross-device consistency.

This provides a zero-code rollback path. If Phase 7B merge logic introduces regressions, disabling the flag immediately restores stability while the merge logic is fixed.

17.2 Merge Isolation

The merge algorithm (Phase 7B) executes within a single Drift transaction. If the transaction fails or the SyncWriteGate timeout fires (§3.7), the entire merge rolls back. No partial state is committed. The device continues with its pre-merge local state.

17.3 Phase 7 Sub-Phase Independence

The three sync sub-phases are designed to be independently stable:

-   After Phase 7A only: transport works, data uploads/downloads, but no merge executes. App is functionally local-only with backup to server.

-   After Phase 7B: full merge works. If conflict UI is missing, merge still executes correctly — it is just not surfaced to the user.

-   Phase 7C adds user-facing elements. It cannot destabilise merge logic because it does not modify it.

18. Data Migration Strategy

Schema evolution is inevitable. The deterministic rebuild architecture provides a strong foundation: materialised tables can always be rebuilt from raw data. However, migration errors on raw execution data are unrecoverable. This section defines the migration governance.

18.1 Principles

-   Raw execution data is sacred. Migrations must never delete, truncate, or reinterpret Instance, Set, Session, or PracticeBlock rows. Column additions are safe. Column type changes require explicit data transformation with rollback path.

-   Materialised tables are disposable. Any migration that affects scoring structure can safely truncate all four materialised tables. A full rebuild will repopulate them correctly.

-   Seed data is additive. New SubskillRef, MetricSchema, or EventTypeRef rows can be added. Existing rows must not be modified without a migration that also updates all referencing entities.

-   Schema version gating (TD-01 §2.9) prevents sync between mismatched versions. The app continues offline until updated.

18.2 Migration Timing Budget

Drift runs schema migrations on app launch, before the UI is populated. Migrations must complete within the 1-second cold-start budget (TD-01 §4.3). If a migration is expected to exceed this budget (e.g. backfilling a new column across 100K+ rows), the app must display a one-time migration progress indicator.

18.3 Test Matrix

Every schema migration must be tested against three volume tiers before release:

-   Tier 1: 1,000 Instances (typical new user after 1–2 months)

-   Tier 2: 10,000 Instances (active user after 6–12 months)

-   Tier 3: 100,000 Instances (heavy user at realistic ceiling)

Each tier test verifies: migration completes without error, raw data is preserved, materialised tables rebuild correctly, and timing is within budget.

19. Deferred Items

The following items are explicitly out of scope for all V1 phases. They are documented here to prevent scope creep and to provide a clear V2 backlog.

-   Real-time Supabase subscriptions (TD-01 §2.11)

-   Field-level merge beyond CalendarDay (TD-01 §2.11)

-   EventLog archival to cold storage (Section 16 §16.7.4)

-   Batch Instance logging / launch monitor paste (TD-03 §10)

-   Push notification triggers via Edge Functions (TD-03 §10)

-   Server-side SlotUpdatedAt normalisation (TD-03 §5.4.4, V2)

-   Soft-delete partial indexes (TD-02 §10)

-   GIN indexes on JSON columns (TD-02 §10)

-   Snapshot immutability triggers (TD-02 §10)

-   Advisory locks for performance optimisation (TD-02 §10)

-   Multi-user / Coach access (Section 17 §17.6)

-   Undo support for state transitions (TD-04 §5)

-   Drill version history (TD-04 §5)

-   iOS deployment (TD-01 §1.2 — Flutter supports iOS; platform-specific setup deferred)

-   Remote log aggregation (V1 uses platform console only)

20. Dependency Map

TD-06 is consumed by:

-   TD-07 (Error Handling Patterns): Phase boundaries define which error scenarios are relevant per phase.

-   TD-08 (Claude Code Prompt Architecture): Phase definitions determine document groupings per Claude Code session. The always-loaded context and phase-specific context are derived from the scope columns in the Phase Summary table (§2).

21. Version History

  ----------- ------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Version     Date         Changes

  TD-06v.a1   2026-02-26   Initial draft. Nine-phase structure with early server validation, design-early foundation, automated testing for invisible logic.

  TD-06v.a2   2026-02-26   Twelve-phase structure. Scoring engine split (2A/2B). Sync layer split (7A/7B/7C). Added observability, sync-awareness guidance, rollback strategy, data migration strategy.

  TD-06v.a3   2026-02-26   Phase reordering: 2.5 moved before 2B. TimerService abstraction (Phase 4). Randomised merge harness (Phase 7B). SyncWriteGate timeout semantics (§3.7). Profiling benchmark harness (Phase 2B).

  TD-06v.a4   2026-02-26   Three targeted additions: (1) synthetic bulk payload test in Phase 2.5 (100 Sessions / 1,000 Instances upload) to validate DTO performance and transport overhead before Phase 7A; (2) peak heap allocation tracking added to Phase 2B profiling harness (256MB budget); (3) sync-disabled indicator in Phase 7C UI when feature flag is off.

  TD-06v.a6   2026-02-27   Stage 4 verification fix: corrected EventTypeRef count from 13 to 16 in three locations (Phase 1 deliverables, Phase 1 acceptance criteria, Phase 2.5 acceptance criteria). Actual seed SQL contains 16 EventType rows.
  ----------- ------------ -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End of TD-06 — Phased Build Plan (TD-06v.a6 Canonical)
