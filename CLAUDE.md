# ZX Golf App — CLAUDE.md (v.a5)

> This file is the persistent context for all Claude Code sessions. It is loaded
> automatically at the start of every session. Maintain it per TD-08 §4.2.

---

## Project Identity

- **Application:** ZX Golf App — Golf practice performance tracking and scoring
- **Platform:** Android (Flutter). iOS deployment deferred to post-V1.
- **Backend:** Supabase (Postgres, Auth, Edge Functions, RLS)
- **Local Database:** Drift (SQLite) with code-generated typed Dart classes
- **State Management:** Riverpod
- **Architecture:** Offline-first. All operations execute locally. Sync is additive.
- **Scoring Model:** Deterministic merge-and-rebuild. No device holds authoritative scoring state. All devices converge from identical raw data.

---

## Spec Version Registry

Verify loaded context documents match these versions before starting work. Flag any mismatch.

| ID    | Document                                    | Version      |
|-------|---------------------------------------------|--------------|
| S00   | Canonical Terminology & Definitions         | 0v.f1        |
| S01   | Scoring Engine                              | 1v.g2        |
| S02   | Skill Architecture & Weighting Framework    | 2v.f1        |
| S03   | User Journey Architecture                   | 3v.g8        |
| S04   | Drill Entry System                          | 4v.g9        |
| S05   | Review: SkillScore & Analysis               | 5v.d6        |
| S06   | Data Model & Persistence Layer              | 6v.b7        |
| S07   | Reflow Governance System                    | 7v.b9        |
| S08   | Practice Planning Layer                     | 8v.a8        |
| S09   | Golf Bag & Club Configuration               | 9v.a2        |
| S10   | Settings & Configuration                    | 10v.a5       |
| S11   | Metrics Integrity & Safeguards              | 11v.a5       |
| S12   | UI/UX Structural Architecture               | 12v.a5       |
| S13   | Live Practice Workflow                      | 13v.a7       |
| S14   | Drill Entry Screens & System Drill Library  | 14v.a4       |
| S15   | Branding & Design System                    | 15v.a3       |
| S16   | Database Architecture                       | 16v.a5       |
| S17   | Real-World Application Layer                | 17v.a4       |
| TD-01 | Technology Stack Decisions                  | TD-01v.a4    |
| TD-02 | Database DDL Schema                         | TD-02v.a6    |
| TD-03 | API Contract Layer                          | TD-03v.a5    |
| TD-04 | Entity State Machines & Reflow Process      | TD-04v.a4    |
| TD-05 | Scoring Engine Test Cases                   | TD-05v.a3    |
| TD-06 | Phased Build Plan                           | TD-06v.a6    |
| TD-07 | Error Handling Patterns                     | TD-07v.a4    |
| TD-08 | Claude Code Prompt Architecture             | TD-08v.a3    |

---

## Source-of-Truth Hierarchy

When documents conflict, higher precedence wins:

1. **(Lowest)** Product Specification (S00–S17)
2. Technical Design documents (TD-01–TD-08)
3. CLAUDE.md Known Deviations
4. **(Highest)** Operator instruction in the current session

**Exception:** S00 (Canonical Definitions) governs terminology at all levels.

**Entity structure rule:** When entity definitions in S06 and TD-02 diverge (nullability, defaults, column types, constraints), TD-02 governs.

**Operator override rule:** Any operator instruction that contradicts a TD or Product Spec rule must be recorded in Known Deviations **before** implementation proceeds (TD-08 §4.2 Rule 3).

---

## Architectural Integrity Rules

- **No invented architecture.** Do not introduce new architectural layers, abstraction tiers, service wrappers, or structural patterns not explicitly defined in a TD document. Flag as an open issue if you believe one is needed (TD-08 §4.2 Rule 5).
- **CLAUDE.md scope restriction.** This file may only summarise existing spec/TD rules or record deviations. It must not create new behavioural rules or undocumented conventions (TD-08 §4.2 Rule 6).
- **SyncWriteGate awareness.** All Repository writes must be structured for gate compatibility from Phase 1 onward: writes through transactions, no long-held write locks, no assumptions about uninterrupted write access (TD-03 §2.1.1).

---

## Current Build Phase

> **Phase: [NOT STARTED]**
>
> Update this field at the start of each phase. Do not generate code outside this scope.

---

## Directory Architecture

```
lib/
├── core/
│   ├── constants.dart              # App-wide constants (kMaxWindowOccupancy, etc.)
│   ├── error_types.dart            # ZxGolfAppException hierarchy (TD-03 §7, TD-07 §2)
│   ├── theme/
│   │   ├── tokens.dart             # Colour, typography, spacing, shape tokens (S15)
│   │   └── zx_theme.dart           # ThemeData wrapper
│   ├── widgets/                    # Shared base components (buttons, cards, inputs)
│   ├── scoring/                    # [Phase 2A] Pure scoring functions
│   │   ├── instance_scorer.dart
│   │   ├── session_scorer.dart
│   │   ├── window_composer.dart
│   │   ├── subskill_scorer.dart
│   │   ├── skill_area_scorer.dart
│   │   ├── overall_scorer.dart
│   │   ├── integrity_evaluator.dart
│   │   └── reflow_engine.dart      # [Phase 2B] Reflow orchestration
│   ├── sync/                       # [Phase 2.5] Sync engine
│   │   ├── sync_engine.dart
│   │   ├── sync_write_gate.dart
│   │   └── merge_algorithm.dart    # [Phase 7B]
│   ├── instrumentation/            # [Phase 2B] Logging, diagnostics, profiling
│   └── services/                   # [Phase 4] TimerService, shared services
├── data/
│   ├── database.dart               # Drift database class
│   ├── database.g.dart             # Drift generated code
│   ├── tables/                     # Drift table definitions (one per entity)
│   ├── daos/                       # Drift DAOs
│   ├── repositories/               # Repository implementations
│   │   ├── user_repository.dart
│   │   ├── drill_repository.dart
│   │   ├── practice_repository.dart
│   │   ├── scoring_repository.dart
│   │   ├── club_repository.dart
│   │   ├── planning_repository.dart
│   │   └── event_log_repository.dart
│   └── dto/                        # [Phase 2.5] Sync DTO serialisation
├── features/
│   ├── drill/                      # [Phase 3] Drill browsing, creation, editing
│   ├── bag/                        # [Phase 3] Golf bag configuration
│   ├── practice/                   # [Phase 4] Live practice workflow
│   ├── planning/                   # [Phase 5] Routines, Schedules, Calendar
│   ├── review/                     # [Phase 6] SkillScore dashboard, analysis
│   └── settings/                   # [Phase 8] Settings screens
├── providers/                      # Riverpod providers by domain
│   ├── database_providers.dart
│   ├── repository_providers.dart
│   ├── scoring_providers.dart
│   └── sync_providers.dart         # [Phase 2.5]
└── main.dart

test/
├── core/scoring/                   # [Phase 2A/2B] Scoring + reflow tests
├── data/repositories/              # Repository tests
├── features/                       # Feature-level tests
├── fixtures/                       # Shared test data builders
└── integration/                    # Cross-module integration tests

supabase/
└── migrations/
    ├── 001_create_schema.sql       # [Phase 2.5]
    └── 002_seed_reference_data.sql # [Phase 2.5]
```

Update this tree when a phase adds new directories.

---

## Naming Conventions

| Element              | Convention                                    | Example                              |
|----------------------|-----------------------------------------------|--------------------------------------|
| Dart files           | `snake_case.dart`. One public class per file. | `scoring_repository.dart`            |
| Classes / types      | `UpperCamelCase` + purpose suffix.            | `ScoringRepository`, `DrillWidget`   |
| Functions            | `lowerCamelCase`. Verb-first for actions.     | `closeSession()`, `getDrillById()`   |
| Variables / fields   | `lowerCamelCase`. No abbreviations.           | `sessionScore`, `practiceBlock`      |
| Constants            | `lowerCamelCase` with `k` prefix.             | `kMaxWindowOccupancy = 25.0`         |
| Riverpod providers   | `lowerCamelCase` + `Provider`.                | `scoringRepositoryProvider`          |
| Drift tables (Dart)  | `UpperCamelCase` plural.                      | `class Sessions extends Table {}`    |
| DB columns           | `UpperCamelCase` per S06.                     | `UserID`, `CompletionTimestamp`      |
| Supabase RPCs        | `snake_case`. Verb_noun.                      | `sync_upload`, `sync_download`       |
| Test files           | `snake_case_test.dart`.                       | `instance_scoring_test.dart`         |
| JSON keys            | `camelCase` per TD-03 §9.                     | `hitRate`, `minAnchor`               |
| Feature branches     | `phase/N-short-description`.                  | `phase/2a-pure-scoring`              |

---

## Code Comment Conventions

| Type              | Format                                                                 | When Required                                     |
|-------------------|------------------------------------------------------------------------|---------------------------------------------------|
| Spec reference    | `// Spec: S07 §7.2 — Reflow trigger: anchor edit`                     | Every method implementing a specific spec rule.   |
| TD reference      | `// TD-04 §3.2 Step 4 — Scope determination`                          | Every method implementing a specific TD decision. |
| Deviation note    | `// DEVIATION: [description]. See CLAUDE.md Known Deviations.`         | Every deviation from spec.                        |
| Phase stub        | `// Phase 3 stub — replaced in Phase 5 (completion matching)`          | Every stub for a future phase.                    |
| Non-obvious logic | `// Dual-mapped drills contribute 0.5 to each subskill window`         | Complex business logic.                           |

Do not comment obvious code. Target ~1 spec/TD reference per public repository/scoring method.

---

## Design Token Reference

> [PLACEHOLDER — populated after Phase 1 establishes the design system from S15]

---

## Error Handling Quick Reference

> [PLACEHOLDER — populated after Phase 1 establishes the error hierarchy from TD-07 §2]

Base class: `ZxGolfAppException`
Subclasses: `ValidationException`, `StateTransitionException`, `ScoringException`, `SyncException`, `DatabaseException`, `AuthenticationException`

Propagation: Repository → throws `ZxGolfAppException` → Provider catches + exposes via `AsyncValue.error` → UI renders per TD-07 §10.

---

## Phase Completion Log

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| —    | —     | —      | —     |

---

## Known Deviations

| Spec Reference | Deviation | Rationale | Date |
|----------------|-----------|-----------|------|
| —              | —         | —         | —    |
