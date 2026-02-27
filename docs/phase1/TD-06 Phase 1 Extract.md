TD-06 Phased Build Plan — Phase 1 Extract (TD-06v.a6)
Sections: §3 Cross-Phase Infrastructure, §4 Phase 1 — Data Foundation & Design System
============================================================

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

