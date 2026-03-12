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

## Workflow Rules

- **NEVER use compound shell commands.** `&&`, `;`, and `||` are **forbidden** in all Bash tool calls. This is a hard rule, not a suggestion.
  - **Wrong:** `cd /c/development/projects/claudecode/zx-golf-app && git status`
  - **Right:** `git -C /c/development/projects/claudecode/zx-golf-app status`
  - For non-git commands, issue separate Bash tool calls instead of chaining.
- **Git workflow.** Batch changes into meaningful commits — do not commit/push after every small change. Stage only files relevant to the work done (don't include unrelated changes). Commit and push when explicitly asked.

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
- **Cross-screen deduplication.** When implementing 3+ screens with the same parent concept (e.g. execution screens for different input modes), extract shared scaffolding into a single host widget with swappable content. Do not duplicate controller init, state management, navigation, or chrome across sibling screens. After completing a group of related screens, perform a structural review pass to identify and extract shared logic.

---

## Current Build Phase

> **Complete (V1 + Matrix & Gapping System)**
>
> All 8 core phases + 10 matrix phases implemented. Matrix & Gapping System adds
> distance calibration workflows (Gapping Chart, Wedge Matrix, Chipping Matrix),
> cross-run analytics with outlier trimming and weighted aggregation, and automated
> insights. 1104 tests passing.

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
│   │   ├── confirmation_dialog.dart # [Phase 8] Soft/strong confirmation dialogs (S10 §10.5)
│   │   └── achievement_banner.dart  # [Phase 8] Achievement banner (S15 §15.8.4)
│   ├── startup_checks.dart          # [Phase 8] 4 startup integrity checks (TD-07 §13.6)
│   ├── scoring/                    # [Phase 2A/2B] Pure scoring + reflow orchestration
│   │   ├── instance_scorer.dart
│   │   ├── session_scorer.dart
│   │   ├── window_composer.dart
│   │   ├── subskill_scorer.dart
│   │   ├── skill_area_scorer.dart
│   │   ├── overall_scorer.dart
│   │   ├── integrity_evaluator.dart
│   │   ├── scoring_helpers.dart
│   │   ├── scoring_types.dart
│   │   ├── reflow_types.dart        # [Phase 2B] ReflowTrigger, ReflowResult
│   │   ├── reflow_engine.dart       # [Phase 2B] 10-step orchestrator
│   │   ├── rebuild_guard.dart       # [Phase 2B] In-memory mutex
│   │   └── scope_resolver.dart      # [Phase 2B] Trigger scope determination
│   ├── sync/                       # [Phase 2.5+7A] Sync engine + orchestration
│   │   ├── sync_types.dart
│   │   ├── sync_write_gate.dart
│   │   ├── auth_service.dart
│   │   ├── sync_engine.dart
│   │   ├── connectivity_monitor.dart # [Phase 7A] Connectivity stream wrapper
│   │   ├── sync_orchestrator.dart    # [Phase 7A] Trigger coordination
│   │   ├── merge_algorithm.dart    # [Phase 7B]
│   │   └── storage_monitor.dart    # [Phase 7C] Storage check stub
│   ├── instrumentation/            # [Phase 2B+7A] Logging, diagnostics, profiling
│   │   ├── reflow_diagnostics.dart  # ReflowDiagnostic, ReflowInstrumentation
│   │   └── sync_diagnostics.dart    # [Phase 7A] SyncDiagnostic, SyncInstrumentation
│   └── services/                   # [Phase 4] TimerService, shared services
├── data/
│   ├── enums.dart                  # 30 enum types with TEXT serialisation
│   ├── converters.dart             # Drift TypeConverters for enum↔TEXT
│   ├── database.dart               # Drift database class (34 tables)
│   ├── database.g.dart             # Drift generated code
│   ├── seed_data.dart              # Reference data seeding (onCreate)
│   ├── tables/                     # Drift table definitions (one per entity)
│   ├── daos/                       # Drift DAOs
│   ├── models/                     # [Phase 8] Pure Dart data models
│   │   └── user_preferences.dart    # UserPreferences JSON model (S10)
│   ├── repositories/               # Repository implementations
│   │   ├── user_repository.dart
│   │   ├── drill_repository.dart
│   │   ├── practice_repository.dart
│   │   ├── scoring_repository.dart # [Phase 2B] Full implementation
│   │   ├── club_repository.dart
│   │   ├── planning_repository.dart
│   │   ├── event_log_repository.dart
│   │   ├── reference_repository.dart
│   │   ├── matrix_repository.dart              # [Matrix M1] Matrix run, axis, cell, attempt CRUD
│   │   └── performance_snapshot_repository.dart # [Matrix M2] Snapshot + derived distances
│   └── dto/                        # [Phase 2.5] Sync DTO serialisation
│       ├── sync_dto.dart           # Barrel export
│       ├── user_dto.dart
│       ├── drill_dto.dart
│       ├── practice_block_dto.dart
│       ├── session_dto.dart
│       ├── set_dto.dart
│       ├── instance_dto.dart
│       ├── practice_entry_dto.dart
│       ├── user_drill_adoption_dto.dart
│       ├── user_club_dto.dart
│       ├── club_performance_profile_dto.dart
│       ├── user_skill_area_club_mapping_dto.dart
│       ├── routine_dto.dart
│       ├── schedule_dto.dart
│       ├── calendar_day_dto.dart
│       ├── routine_instance_dto.dart
│       ├── schedule_instance_dto.dart
│       ├── event_log_dto.dart
│       ├── user_device_dto.dart
│       ├── matrix_run_dto.dart             # [Matrix M3]
│       ├── matrix_axis_dto.dart            # [Matrix M3]
│       ├── matrix_axis_value_dto.dart      # [Matrix M3]
│       ├── matrix_cell_dto.dart            # [Matrix M3]
│       ├── matrix_attempt_dto.dart         # [Matrix M3]
│       └── performance_snapshot_dto.dart   # [Matrix M3]
├── features/
│   ├── home/
│   │   └── home_dashboard_screen.dart  # S12 §12.2 — Home Dashboard (score + slots + actions)
│   ├── shell/
│   │   ├── shell_screen.dart       # Home/Tab navigator (Plan/Play/Review)
│   │   ├── tabs/                   # Tab screens (Play has Practice + Gapping sub-tabs)
│   │   └── widgets/                # [Phase 7C] Shell-level widgets
│   │       └── dual_active_session_dialog.dart # Cross-device conflict dialog
│   ├── drill/                      # [Phase 3] Drill browsing, creation, editing
│   │   ├── practice_pool_screen.dart   # Main drill hub (Play → Practice tab)
│   │   ├── add_drills_screen.dart      # Add Drills chooser (ZX library or custom)
│   │   ├── drill_library_screen.dart   # System Drill catalogue (28 drills)
│   │   ├── drill_detail_screen.dart    # View/edit drill properties + anchors
│   │   ├── drill_create_screen.dart    # Multi-step custom drill creation
│   │   └── widgets/
│   │       ├── drill_card.dart         # Drill list item with skill area badge
│   │       ├── anchor_editor.dart      # Min/Scratch/Pro field group
│   │       └── skill_area_picker.dart  # Horizontal chip filter
│   ├── bag/                        # [Phase 3] Golf bag configuration
│   │   ├── bag_screen.dart             # Club list grouped by category
│   │   ├── club_detail_screen.dart     # Edit club properties + performance
│   │   ├── skill_area_mapping_screen.dart # Club-to-SkillArea mappings
│   │   └── widgets/
│   │       └── club_card.dart          # Club list item
│   ├── practice/                   # [Phase 4] Live practice workflow
│   │   ├── practice_router.dart        # InputMode → execution screen routing
│   │   ├── execution/
│   │   │   ├── session_execution_controller.dart  # Structured/unstructured/technique completion
│   │   │   ├── execution_helpers.dart             # Shared endSession/changeSurface helpers
│   │   │   ├── execution_input_delegate.dart      # Abstract delegate interface + ExecutionContext
│   │   │   └── input_delegates/                   # Per-InputMode swappable input widgets
│   │   │       ├── grid_cell_delegate.dart        # 1×3/3×1/3×3 grid tap
│   │   │       ├── binary_hit_miss_delegate.dart  # Hit/Miss buttons + counters
│   │   │       ├── continuous_measurement_delegate.dart  # Numeric distance/deviation
│   │   │       └── raw_data_entry_delegate.dart   # General numeric + real-time score
│   │   ├── screens/
│   │   │   ├── practice_queue_screen.dart          # Queue: add/remove/reorder drills
│   │   │   ├── execution_screen.dart               # Unified host for all input modes
│   │   │   ├── technique_block_screen.dart         # Timer only (separate — no per-instance recording)
│   │   │   ├── post_session_summary_screen.dart    # Score + integrity summary
│   │   │   └── practice_summary_screen.dart        # Full practice block summary
│   │   └── widgets/
│   │       ├── execution_header.dart               # Drill name, set/instance progress
│   │       ├── club_selector.dart                  # Club dropdown per ClubSelectionMode
│   │       ├── score_flash.dart                    # 120ms color flash animation
│   │       ├── practice_entry_card.dart            # Queue entry card
│   │       ├── anchor_score_bar.dart               # Min/Scratch/Pro gradient bar
│   │       ├── practice_stats_bar.dart             # Environment + surface badges
│   │       └── surface_picker.dart                 # Indoor/Outdoor + Grass/Mat picker
│   ├── planning/                   # [Phase 5] Routines, Schedules, Calendar
│   │   ├── models/
│   │   │   ├── slot.dart               # Slot data class with JSON serialization
│   │   │   └── planning_types.dart     # RoutineEntry, GenerationCriterion, TemplateDay
│   │   ├── completion_matching.dart    # Session → Slot auto-matching (S08 §8.3.2)
│   │   ├── routine_application.dart    # Routine → CalendarDay applicator (S08 §8.2.2)
│   │   ├── schedule_application.dart   # Schedule → date range applicator (S08 §8.2.3)
│   │   ├── weakness_detection.dart     # WeaknessIndex ranking + drill selection (S08 §8.7)
│   │   ├── screens/
│   │   │   ├── calendar_screen.dart              # 3-day rolling + 2-week toggle
│   │   │   ├── calendar_day_detail_screen.dart   # Slot list with actions
│   │   │   ├── routine_list_screen.dart          # User's routines
│   │   │   ├── routine_create_screen.dart        # Name → entries → save
│   │   │   ├── routine_detail_screen.dart        # View/edit entries + lifecycle
│   │   │   ├── routine_apply_screen.dart         # Preview + confirm/reroll
│   │   │   ├── schedule_list_screen.dart         # User's schedules
│   │   │   ├── schedule_create_screen.dart       # Mode → entries → save
│   │   │   ├── schedule_detail_screen.dart       # View schedule + lifecycle
│   │   │   └── schedule_apply_screen.dart        # Date range → apply
│   │   └── widgets/
│   │       ├── planning_actions_sheet.dart       # Shared routine/schedule picker sheets
│   │       ├── slot_tile.dart                    # Slot with state indicators
│   │       ├── adherence_badge.dart              # 4-week adherence percentage
│   │       ├── routine_entry_card.dart           # Fixed or criterion display
│   │       ├── criterion_editor.dart             # Generation criterion form
│   │       └── template_day_editor.dart          # DayPlanning per-day editor
│   ├── review/                     # [Phase 6] SkillScore dashboard, analysis
│   │   ├── screens/
│   │   │   ├── review_dashboard_screen.dart  # Overall Score + heatmap + trend + CTA
│   │   │   ├── analysis_screen.dart          # Filter row + chart toggle + charts
│   │   │   ├── window_detail_screen.dart     # Ordered entries for single window
│   │   │   ├── subskill_detail_screen.dart   # Transition + Pressure windows
│   │   │   ├── weakness_ranking_screen.dart  # Ranked subskills by WeaknessIndex
│   │   │   ├── session_history_screen.dart   # All sessions for a drill
│   │   │   ├── session_detail_screen.dart    # Single session breakdown
│   │   │   ├── plan_adherence_screen.dart    # Weekly/monthly adherence rollups
│   │   │   └── matrix_review_screen.dart    # [Matrix M8] Run history + type filter
│   │   └── widgets/
│   │       ├── overall_score_display.dart     # 0–1000 score with tabular numerals
│   │       ├── skill_area_heatmap.dart        # 7 tiles, grey-to-green opacity
│   │       ├── skill_area_tile.dart           # Single heatmap tile
│   │       ├── subskill_breakdown.dart        # Expanded subskill rows
│   │       ├── trend_snapshot.dart            # Compact sparkline + last value
│   │       ├── plan_adherence_badge.dart      # Headline % on Dashboard
│   │       ├── performance_chart.dart         # Line chart (0–5 score trends)
│   │       ├── volume_chart.dart              # Stacked bar chart (session counts)
│   │       └── analysis_filters.dart          # Scope, DrillType, Resolution filters
│   ├── matrix/                     # [Matrix M4-M10] Matrix & Gapping System
│   │   ├── screens/                    # Setup, execution, completion screens
│   │   │   ├── matrix_setup_screen.dart          # Unified setup for all matrix types
│   │   │   ├── gapping_execution_screen.dart
│   │   │   ├── matrix_execution_screen.dart
│   │   │   └── matrix_completion_screen.dart
│   │   ├── review/                     # [M8-M9] Type-specific review screens
│   │   │   ├── gapping_review_screen.dart
│   │   │   ├── gapping_comparison_screen.dart
│   │   │   ├── wedge_review_screen.dart
│   │   │   ├── chipping_review_screen.dart
│   │   │   └── cell_detail_screen.dart
│   │   ├── analytics/                  # [M10] Cross-run analytics engine
│   │   │   ├── analytics_types.dart
│   │   │   ├── outlier_trimmer.dart
│   │   │   ├── weighted_aggregator.dart
│   │   │   ├── matrix_analytics_engine.dart
│   │   │   └── insight_generator.dart
│   │   └── widgets/
│   │       ├── matrix_execution_header.dart
│   │       └── matrix_cell_card.dart
│   └── settings/                   # [Phase 8] Settings screens
│       ├── settings_screen.dart        # Settings hub (S10)
│       ├── execution_defaults_screen.dart  # Per-SkillArea club selection defaults
│       └── calendar_defaults_screen.dart   # 7-day slot capacity pattern
├── providers/                      # Riverpod providers by domain
│   ├── database_providers.dart
│   ├── repository_providers.dart
│   ├── scoring_providers.dart
│   ├── sync_providers.dart         # [Phase 2.5+7A] Sync engine, orchestrator, connectivity, instrumentation
│   ├── drill_providers.dart        # [Phase 3] System drills, adopted drills, practice pool
│   ├── bag_providers.dart          # [Phase 3] User bag, club mappings
│   ├── planning_providers.dart     # [Phase 5] Routines, schedules, calendar, PlanningActions
│   ├── review_providers.dart      # [Phase 6] Heatmap, window detail, weakness, sessions, adherence
│   ├── settings_providers.dart    # [Phase 8] User preferences, currentUser
│   ├── matrix_providers.dart      # [Matrix M4] Matrix runs, details, actions, snapshots
│   └── matrix_analytics_providers.dart # [Matrix M10] Analytics + insights
└── main.dart

test/
├── core/scoring/                   # [Phase 2A/2B] Scoring + reflow tests
├── core/sync/                      # [Phase 2.5] Sync engine + gate tests
├── data/dto/                       # [Phase 2.5] DTO round-trip tests (18 files)
├── data/repositories/              # Repository tests
│   ├── drill_repository_test.dart  # [Phase 3] 33 tests: state machines, immutability, anchors
│   └── club_repository_test.dart   # [Phase 3] 23 tests: state machines, mappings, profiles
├── features/                       # Feature-level tests
├── fixtures/                       # Shared test data builders
│   ├── scoring_fixtures.dart
│   └── dto_fixtures.dart
└── integration/                    # Cross-module integration tests

supabase/
└── migrations/
    ├── 001_create_schema.sql
    ├── 002_seed_reference_data.sql
    ├── 003_sync_upload.sql
    ├── 004_sync_download.sql
    ├── 005_matrix_schema.sql       # [Matrix M1] 7 matrix tables
    ├── 006_matrix_tables.sql       # [Matrix M3] Server-side matrix tables
    └── 007_sync_matrix.sql         # [Matrix M3] Matrix sync RPCs
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
| Non-obvious logic | `// Dual-mapped drills contribute 0.5 to each subskill window`         | Complex business logic.                           |

Do not comment obvious code. Target ~1 spec/TD reference per public repository/scoring method.

---

## Design Token Reference

Source: `lib/core/theme/tokens.dart` (S15 §15.3–15.10)

**Colour tokens — semantic groups:**

| Group | Token | Hex | Usage |
|-------|-------|-----|-------|
| Primary (cyan) | `primaryDefault` / `Hover` / `Active` | `#00B3C6` / `#00C8DD` / `#007C7F` | Primary actions, selected states |
| Success (green) | `successDefault` / `Hover` / `Active` | `#1FA463` / `#23B26C` / `#15804A` | Scoring hits, progress actions |
| Miss (grey) | `missDefault` / `Active` / `Border` | `#3A3F46` / `#2C3036` / `#4A5058` | Neutral miss (not red) |
| Warning | `warningIntegrity` / `Muted` | `#F5A623` / `#C88719` | Integrity warnings |
| Error (red) | `errorDestructive` / `Hover` / `Active` | `#D64545` / `#E05858` / `#B63737` | Destructive actions |
| Achievement | `achievementGold` | `#FFD700` | Star ratings |
| RAG | `ragRed` / `ragAmber` / `ragGreen` / `ragPurple` | `#E05252` / `#E8A830` / `#22C55E` / `#9333EA` | Scoring visualisation |
| Surface | `surfaceBase` → `Primary` → `Raised` → `Modal` | `#0F1115` → `#171A1F` → `#1E232A` → `#242A32` | Dark elevation stack |
| Text | `textPrimary` / `Secondary` / `Tertiary` | `#FFF` / 70% / 50% | Text hierarchy |

**Skill area colours (warm→cool):** Putting `#D4A535` → Chipping `#E67E22` → Pitching `#E05858` → Bunkers `#C74882` → Irons `#8E5BB5` → Woods `#5B6ABF` → Driving `#3A7BD5`

**Environment/Surface colours** (in `surface_picker.dart`): Indoor `#9B72B0` (plum), Outdoor `#F5A623` (gold), Grass `#1FA463` (green), Mat `#C4956A` (amber/brown)

**Button variants (ZxPillButton):**

| Variant | Colour | Usage |
|---------|--------|-------|
| `primary` | Cyan | Default actions (Add Drills, Add Routine) |
| `progress` | Green | Begin Practice, Resume, Next Drill |
| `secondary` | Outlined | Secondary actions, Clear Filter |
| `tertiary` | Muted grey | Disabled / low-priority |
| `destructive` | Red | Discard, Delete |

**Typography:** Manrope (Google Fonts), tabular lining numerals.

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `displayXxl` | 64px | w600 | Timer, score hero |
| `displayXl` | 36px | w600 | Page titles |
| `displayLg` | 24px | w600 | Section headers |
| `header` | 20px | w500 | Card titles, tab labels |
| `bodyLg` | 18px | w400 | Button labels (md), subtitles |
| `body` | 16px | w400 | Body text, button labels (sm) |
| `bodySm` | 14px | w400 | Captions, tertiary text |

**Spacing:** xs=4, sm=8, md=16, lg=24, xl=32, xxl=48.

**Shape:** micro=2, badge=4, grid=6, card=8, input=8, segmented=8, modal=10.

**Motion:** fast=120ms, standard=150ms, slow=200ms. Curve: easeInOut.

---

## Error Handling Quick Reference

Source: `lib/core/error_types.dart` (TD-07 §2)

Base class: `ZxGolfAppException` (`code`, `message`, `context`)

| Subclass                    | Static code constants                                                             |
|-----------------------------|-----------------------------------------------------------------------------------|
| `ValidationException`       | `requiredField`, `rangeViolation`, `invalidFormat`, `businessRule`                |
| `ReflowException`           | `scopeDetermination`, `windowComposition`, `scorePropagation`, `timeout`          |
| `SyncException`             | `networkError`, `authExpired`, `mergeConflict`, `serverError`, `gateTimeout`     |
| `SystemException`           | `databaseCorruption`, `migrationFailure`, `referentialIntegrity`, `unexpectedState` |
| `ConflictException`         | `lockContention`, `concurrentWrite`, `staleData`, `versionMismatch`              |
| `AuthenticationException`   | `invalidCredentials`, `sessionExpired`, `insufficientPermissions`, `accountLocked` |

Propagation: Repository → throws `ZxGolfAppException` → Provider catches + exposes via `AsyncValue.error` → UI renders per TD-07 §10.

---

## Phase Completion Log

| Date       | Phase   | Status    | Notes                                                                 |
|------------|---------|-----------|-----------------------------------------------------------------------|
| 2026-02-27 | Phase 1 | Complete  | 27 Drift tables, 21 enums, seed data, 8 repos, design system, shell app. `flutter analyze` clean. |
| 2026-03-01 | Phase 2A | Complete | 9 pure scoring functions, 8 test files, 91 tests. `flutter analyze` clean, 100% pass rate. No Drift imports in scoring library. |
| 2026-03-01 | Phase 2.5 | Complete | 18 DTO files + barrel, 4 sync core files, 4 SQL migrations, Supabase init, providers. 77 unit tests + 6 server acceptance tests (all 6 TD-06 §6.4 criteria passing). `flutter analyze` clean. |
| 2026-03-01 | Phase 2B | Complete | ReflowEngine (10-step orchestrator + bulk rebuild), RebuildGuard, ScopeResolver, ScoringRepository full impl, ReflowInstrumentation, 8 Riverpod providers, profiling harness. 253 tests passing. Scoped reflow p95=99ms (<150ms target), full rebuild p95=198ms (<1s target). `flutter analyze` clean. |
| 2026-03-01 | Phase 3 | Complete | DrillRepository (11 business methods, state machines, immutability, anchor governance, reflow triggers), ClubRepository (9 methods, S09 §9.2.3 default/mandatory mappings), 56 repo tests (33 drill + 23 club), drill providers + bag providers, 7 drill screens/widgets (practice pool, library, detail, create, drill card, anchor editor, skill area picker), 4 bag screens/widgets (bag, club detail, skill area mapping, club card), shell integration. 317 total tests passing. `flutter analyze` clean. |
| 2026-03-01 | Phase 4 | Complete | TimerService (2h/4h with suspend/resume), PracticeRepository (18 business methods, TD-04 state machine guards), practice providers + PracticeActions coordination, SessionExecutionController (structured/unstructured/technique completion, real-time scoring), 7 execution screens (grid cell, continuous measurement, raw data entry, binary hit/miss, technique block, practice queue, post-session summary), 4 widgets (execution header, club selector, score flash, practice entry card), practice router, session close pipeline integration (<200ms), post-close editing with reflow. 388 total tests passing. `flutter analyze` clean. |
| 2026-03-02 | Phase 5 | Complete | PlanningRepository (slot management, routine/schedule lifecycle, cascade deletions), Slot model + planning types, CompletionMatcher (session→slot matching with overflow), RoutineApplicator, ScheduleApplicator (List/DayPlanning modes), WeaknessDetectionEngine (WeaknessIndex ranking, 4 selection modes), planning providers + PlanningActions coordination, Calendar UI (3-day/2-week toggle, day detail, slot tiles, adherence badge), Routine UI (list/create/detail/apply), Schedule UI (list/create/detail/apply, template day editor), criterion editor, drill deletion cascade to routines/schedules. 102 planning tests, 490 total tests passing. `flutter analyze` clean. |
| 2026-03-02 | Phase 6 | Complete | Review providers (heatmap opacity, window detail parser, weakness ranking, sessions, plan adherence), Dashboard (Overall Score, Skill Area heatmap with accordion, subskill breakdown, trend snapshot, plan adherence badge), Window Detail (parsed entries, roll-off boundary, saturation header), Subskill Detail (Transition + Pressure windows), Weakness Ranking (ranked subskills with WI, allocation, saturation), Analysis tab (filter row with Scope/DrillType/Resolution/DateRange, Performance line chart with rolling overlay via fl\_chart, Volume stacked bar by SkillArea), Session History (variance tracking with SD RAG thresholds, confidence levels), Session Detail, Plan Adherence (weekly/monthly rollups, SkillArea breakdown), Review tab dual-tab shell (Dashboard \| Analysis). 41 review tests, 531 total tests passing. `flutter analyze` clean. |
| 2026-03-02 | Phase 7A | Complete | ConnectivityMonitor (stream-based with injectable test stream), SyncOrchestrator (periodic 5min timer, connectivity-restored trigger, post-session trigger, 500ms debounce, auth guard, feature flag guard), SyncEngine enhancements (payload batching with 2MB limit and parent-before-child ordering, SyncDiagnostics injection, consecutive failure counter with auto-disable at 5, feature flag toggle, setOffline), SyncMetadataKeys constants, SyncInstrumentation (follows ReflowInstrumentation pattern), post-session sync trigger in PracticeActions, shell lifecycle wiring, 6 new Riverpod providers. 58 new tests, 589 total tests passing. `flutter analyze` clean. |
| 2026-03-02 | Phase 7B | Complete | MergeAlgorithm (row-level LWW + delete-always-wins + CalendarDay slot-level merge), Slot.updatedAt for per-slot timestamps, executeFullRebuildInternal (gate-free rebuild for merge pipeline), SyncWriteGate enforcement on 6 repositories (User, Drill, Practice, Club, Planning, EventLog — ScoringRepository exempt), SyncEngine merge pipeline with post-merge full rebuild, provider wiring (SyncWriteGate into repos, ReflowEngine into SyncEngine). 79 new tests (30 merge algorithm + 5 reflow internal + 15 gate repo + 24 merge integration + 10 convergence — note: 5 convergence tests are pure algorithm tests not counted as DB tests), 668 total tests passing. `flutter analyze` clean. |
| 2026-03-02 | Phase 7C | Complete | SyncEngine hardening (merge timeout counter, schema mismatch persistent flag, dual active session detection, lastErrorCode, exception handler routing by code), StorageMonitor (injectable stub), SyncBannerState (pure priority resolution with 9 banner types), SyncStatusBanner (composite widget with accent stripes, progress indicator, schema mismatch dialog), DualActiveSessionDialog (cross-device conflict), ShellScreen wiring (banner + dual session listener), replaced 2 orphaned StateProviders + 7 new providers (consecutiveMergeTimeouts, connectivityStatus, lastSyncTimestamp, schemaMismatchDetected, dualActiveSession, storageMonitor, isStorageLow). 52 new tests (20 banner state + 15 engine hardening + 5 storage monitor + 12 provider wiring), 720 total tests passing. `flutter analyze` clean. |
| 2026-03-02 | Phase 8 | Complete | UserPreferences model (JSON serialization, 2 new enums), Settings hub + 2 sub-screens (execution defaults, calendar defaults), confirmation dialogs (soft/strong), IntegritySuppressed toggle UI + bug fix (session_history_screen), StartupChecks (4 checks: rebuildNeeded, lock expiry, allocation invariant, FK check), migration infrastructure (onUpgrade handler), achievement banners (S15 §15.8.4), rebuildNeeded staleness indicator (dimmed opacity), settings providers, AppBar gear icon in shell. 55 new tests (11 user_preferences + 5 confirmation_dialog + 5 achievement_banner + 8 startup_checks + 10 integrity_suppression + 5 migration + 12 settings), 775 total tests passing. `flutter analyze` clean. |
| 2026-03-06 | Matrix M1-M3 | Complete | 7 Drift tables (MatrixRun, MatrixAxis, MatrixAxisValue, MatrixCell, MatrixAttempt, PerformanceSnapshot, PerformanceClubData), 7 enums (MatrixType, RunState, ShotOrderMode, AxisType, EnvironmentType, SurfaceType, GreenFirmness), MatrixRepository (17 methods), PerformanceSnapshotRepository, 6 DTOs, 2 SQL migrations. `flutter analyze` clean. |
| 2026-03-06 | Matrix M4-M7 | Complete | Matrix providers + MatrixActions coordinator, gapping/wedge/chipping setup screens, gapping execution screen (1D), matrix execution screen (2D/3D), matrix completion screen (snapshot creation), Review tab matrix integration (MatrixReviewScreen), matrix execution header + cell card widgets. `flutter analyze` clean. |
| 2026-03-06 | Matrix M8 | Complete | MatrixReviewScreen with run history filters and ChoiceChip type selector, snapshot banner, tap navigation to type-specific review screens. 1028 total tests passing. |
| 2026-03-06 | Matrix M9 | Complete | GappingReviewScreen (distance ladder + table + gap warnings), GappingComparisonScreen (multi-run overlay up to 3), WedgeReviewScreen (flight-coloured ladder + axis filtering), ChippingReviewScreen (accuracy overview + expandable club sections), CellDetailScreen (attempt list + edit/delete). 23 review tests (7 gapping + 5 wedge + 6 chipping + 5 cell detail), 1051 total tests passing. `flutter analyze` clean. |
| 2026-03-06 | Matrix M10 | Complete | Outlier trimmer (10% symmetric trim §9.3.3), weighted aggregator (exp decay §9.4), matrix analytics engine (club distance, wedge coverage, chipping accuracy, distance trend — pure functions §9.5-9.9), insight generator (max 3, ranked by magnitude §9.10), analytics types, 8 Riverpod providers with weighted/raw toggle. 53 new tests (8 trimmer + 12 aggregator + 15 engine + 14 insight + 4 overview/trend), 1104 total tests passing. `flutter analyze` clean. |

---

## Known Deviations

| Spec Reference | Deviation | Rationale | Date |
|----------------|-----------|-----------|------|
| TD-06 §4.4 "28 Drift tables" | 34 Drift tables (26 from DDL + SyncMetadata + 7 matrix tables). SystemMaintenanceLock and MigrationLog excluded. | TD-02 §8 specifies these are server-only. Matrix tables added in Matrix M1-M3. | 2026-02-27 |
| TD-02 §3.5 `Sets` table | Generated data class renamed to `PracticeSet` via `@DataClassName('PracticeSet')`. | Drift generates singular `Set` from `Sets`, clashing with `dart:core.Set`. | 2026-02-27 |
| Phase 7C StorageMonitor | `StorageMonitor._defaultCheck()` returns `false` (stub). No real disk space detection. | `dart:io` doesn't expose free space without FFI/native plugin. Infrastructure wired for Phase 8 activation. | 2026-03-02 |
| S10 §10.10 Notifications | Reminder toggle + time picker persist preferences but do not schedule system notifications. | `flutter_local_notifications` deferred to post-V1 to avoid native dependency complexity. | 2026-03-02 |
| S10 §10.5 Account Deletion | Local cascade deletion only. Server-side Supabase data not deleted. | Server-side cascade requires Supabase Edge Function (deferred to post-V1). | 2026-03-02 |
| S10 §10.11 Data Export | Data export (JSON) stubbed — settings screen shows placeholder. | `share_plus` dependency deferred to post-V1. | 2026-03-02 |
| Riverpod `.autoDispose` | 16 family providers across review, scoring, practice, planning, bag, and drill providers lack `.autoDispose`. Provider instances accumulate when family parameters change. | Adding `.autoDispose` risks breaking `ref.read()` call sites that access providers after the last watcher disposes. Requires case-by-case audit. Must be addressed before production release. | 2026-03-03 |
| TD-02 `MatrixAxes` table | Generated data class renamed to `MatrixAxis` via `@DataClassName('MatrixAxis')`. | Drift generates 'MatrixAxe' from 'MatrixAxes', which is an incorrect singularization of the irregular plural 'Axes'. | 2026-03-06 |
| S01 §1.11 Scoring model | Accumulation model replaces averaging. `SubskillPoints = (allocation / (5 × windowSize)) × (0.65 × P_sum + 0.35 × T_sum)`. Variable per-subskill window sizes in `SubskillRef.WindowSize` replace global `kMaxWindowOccupancy = 25`. | Averaging model meant 1 drill at 3/5 = same score as 25 drills at 3/5. Accumulation rewards practice volume. | 2026-03-09 |
