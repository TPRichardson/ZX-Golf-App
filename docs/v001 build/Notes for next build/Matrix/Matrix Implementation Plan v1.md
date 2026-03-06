# Matrix & Gapping System — Implementation Plan v1

**Source Spec:** `matrix combined spec 1v a2.md` (Sections 1–9)
**Date:** 2026-03-06
**Target:** ZX Golf App V2 feature addition

---

## Plan Structure & Context Window Strategy

This plan is divided into **10 self-contained phases**. Each phase is designed to:

1. **Fit within a single Claude Code context window** (~100K tokens including codebase context)
2. **Be independently executable** — each phase produces a compilable, testable increment
3. **Include its own test suite** — no deferred testing
4. **Reference only files created in prior phases** — dependency chain is linear

**To execute a phase:** Load this plan + the relevant section of `matrix combined spec 1v a2.md` + CLAUDE.md. The phase description includes all file paths and patterns needed.

---

## Codebase Survey Summary

**Current state (as of 2026-03-06):**

| Component | Status | Notes |
|-----------|--------|-------|
| Database schema | v4, 27 Drift tables | Need v5 migration for 7 new tables |
| Enums | 23 defined in `enums.dart` | Need ~6 new enums |
| Track tab | Has placeholder `_MatrixTab` in `track_tab.dart` | Ready for replacement |
| Review tab | 2 sub-tabs: Dashboard \| Analysis | Spec wants 3 sub-tabs with Matrices section |
| ClubPerformanceProfile table | Exists (`club_performance_profiles.dart`) | Spec introduces PerformanceSnapshot to *replace* it over time |
| Slot model | Has drillId, ownerType, completionState | Needs matrixRunId + matrixType fields for matrix slots |
| Practice workflow | PracticeRepository + PracticeActions + TimerService | Matrix mirrors this pattern exactly |
| SyncWriteGate | Enforced on 6 repositories | New MatrixRepository needs gate |
| DTO pattern | `toSyncDto()` extension + `fromSyncDto()` function | Need 7 new DTO files |
| Home Dashboard | Shows score + slots + practice actions | Needs matrix-aware actions |
| Mutual exclusivity | Not enforced (only one active PB checked per user) | Need cross-system check: PB ↔ MatrixRun |

---

## Phase M1 — Data Layer: Tables, Enums, Migration

**Goal:** Define all new database entities. Compilable with `flutter analyze` clean. No runtime behavior yet.

**Spec sections:** §1, §6, §8 (entity schemas)

### New Enums (add to `lib/data/enums.dart`)

| Enum | Values | Spec Ref |
|------|--------|----------|
| `MatrixType` | gappingChart, wedgeMatrix, chippingMatrix | §8.2.1 |
| `RunState` | inProgress, completed | §8.3.1 |
| `ShotOrderMode` | topToBottom, bottomToTop, random | §3.8, §8.3.1 |
| `AxisType` | club, effort, flight, carryDistance, custom | §8.3.2 |
| `EnvironmentType` | indoor, outdoor | §3.5.2, §8.3.1 |
| `SurfaceType` | grass, mat | §3.5.3, §8.3.1 |
| `GreenFirmness` | soft, medium, firm | §5.5, §8.3.1 |

All enums follow existing pattern: `TEXT` serialisation via `dbValue` getter + `fromString()` factory.

### New Drift Tables (create in `lib/data/tables/`)

**1. `matrix_runs.dart`** — `MatrixRuns` table

| Column | Type | Notes |
|--------|------|-------|
| MatrixRunID | TEXT PK | UUID |
| UserID | TEXT | FK to Users |
| MatrixType | TEXT | Enum: MatrixType |
| RunNumber | INTEGER | Sequential per user, globally unique |
| RunState | TEXT | Enum: RunState |
| StartTimestamp | DATETIME | |
| EndTimestamp | DATETIME nullable | |
| SessionShotTarget | INTEGER | ≥ 3 |
| ShotOrderMode | TEXT | Enum: ShotOrderMode |
| DispersionCaptureEnabled | BOOLEAN | Default false. Gapping/Wedge only. |
| MeasurementDevice | TEXT nullable | Free text |
| EnvironmentType | TEXT nullable | Enum: EnvironmentType |
| SurfaceType | TEXT nullable | Enum: SurfaceType |
| GreenSpeed | REAL nullable | 6.0–15.0 in 0.5 steps. Chipping only. |
| GreenFirmness | TEXT nullable | Enum: GreenFirmness. Chipping only. |
| IsDeleted | BOOLEAN | Default false |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

**2. `matrix_axes.dart`** — `MatrixAxes` table

| Column | Type | Notes |
|--------|------|-------|
| MatrixAxisID | TEXT PK | UUID |
| MatrixRunID | TEXT | FK to MatrixRuns |
| AxisType | TEXT | Enum: AxisType |
| AxisName | TEXT | User-defined label |
| AxisOrder | INTEGER | Position (1, 2, 3) |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

**3. `matrix_axis_values.dart`** — `MatrixAxisValues` table

| Column | Type | Notes |
|--------|------|-------|
| AxisValueID | TEXT PK | UUID |
| MatrixAxisID | TEXT | FK to MatrixAxes |
| Label | TEXT | User-defined (e.g., "56°", "70%", "Low") |
| SortOrder | INTEGER | Display order within axis |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

**4. `matrix_cells.dart`** — `MatrixCells` table

| Column | Type | Notes |
|--------|------|-------|
| MatrixCellID | TEXT PK | UUID |
| MatrixRunID | TEXT | FK to MatrixRuns |
| AxisValueIDs | TEXT | JSON array of AxisValueID strings (§8.4) |
| ExcludedFromRun | BOOLEAN | Default false. Soft-exclusion (§6.8). |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

**5. `matrix_attempts.dart`** — `MatrixAttempts` table

| Column | Type | Notes |
|--------|------|-------|
| MatrixAttemptID | TEXT PK | UUID |
| MatrixCellID | TEXT | FK to MatrixCells |
| AttemptTimestamp | DATETIME | |
| CarryDistanceMeters | REAL nullable | All types |
| TotalDistanceMeters | REAL nullable | All types |
| LeftDeviationMeters | REAL nullable | Gapping + Wedge only |
| RightDeviationMeters | REAL nullable | Gapping + Wedge only |
| RolloutDistanceMeters | REAL nullable | Chipping only |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

**6. `performance_snapshots.dart`** — `PerformanceSnapshots` table (§1.9)

| Column | Type | Notes |
|--------|------|-------|
| SnapshotID | TEXT PK | UUID |
| UserID | TEXT | FK to Users |
| MatrixRunID | TEXT nullable | FK to MatrixRuns (null = manual snapshot) |
| MatrixType | TEXT nullable | Enum: MatrixType |
| IsPrimary | BOOLEAN | Default false. One primary per user. |
| Label | TEXT nullable | User-assigned label |
| SnapshotTimestamp | DATETIME | |
| IsDeleted | BOOLEAN | Default false |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

**7. `snapshot_clubs.dart`** — `SnapshotClubs` table (§1.9)

| Column | Type | Notes |
|--------|------|-------|
| SnapshotClubID | TEXT PK | UUID |
| SnapshotID | TEXT | FK to PerformanceSnapshots |
| ClubID | TEXT | FK to UserClubs |
| CarryDistanceMeters | REAL nullable | |
| TotalDistanceMeters | REAL nullable | |
| DispersionLeftMeters | REAL nullable | |
| DispersionRightMeters | REAL nullable | |
| RolloutDistanceMeters | REAL nullable | Chipping snapshots |
| CreatedAt | DATETIME | |
| UpdatedAt | DATETIME | |

### Database Registration

**Modify `lib/data/database.dart`:**
- Add 7 new table imports
- Add to `@DriftDatabase(tables: [...])` annotation
- Bump schema version: 4 → 5
- Add migration v4→v5: `CREATE TABLE` statements for all 7 tables
- Add index: `MatrixAttempts(MatrixCellID)`, `MatrixCells(MatrixRunID)`, `MatrixAxes(MatrixRunID)`, `SnapshotClubs(SnapshotID)`

### Extend Slot Model

**Modify `lib/features/planning/models/slot.dart`:**
- Add `String? matrixRunId` field
- Add `MatrixType? matrixType` field
- Update `toJson()` / `fromJson()` / `copyWith()`
- Add `isMatrixSlot` getter: `matrixType != null`

### Run `flutter pub run build_runner build` for Drift codegen

### Tests

**File:** `test/data/tables/matrix_tables_test.dart`
- Verify all 7 tables exist in schema (smoke test via DB open)
- Verify enum serialisation round-trips for all new enums
- Verify Slot model JSON round-trip with new matrix fields
- ~15 tests

---

## Phase M2 — Repository: MatrixRepository + PerformanceSnapshotRepository

**Goal:** Full business logic layer for matrix lifecycle. All state machine guards, cell generation, attempt CRUD, completion validation, snapshot creation.

**Spec sections:** §1 (lifecycle, editing, versioning), §6 (runtime model), §8.6 (CalendarSlot extension)

**Pattern to follow:** `lib/data/repositories/practice_repository.dart` — same SyncWriteGate, transaction, guard, and reflow-trigger patterns.

### Create `lib/data/repositories/matrix_repository.dart`

**Key methods (mirroring PracticeRepository pattern):**

| Method | Purpose | Guards | Spec Ref |
|--------|---------|--------|----------|
| `createMatrixRun(userId, matrixType, config)` | Create run + axes + cells | No active PB or MatrixRun for user | §6.1–6.4 |
| `getMatrixRun(runId)` | Fetch run with axes, values, cells | — | §6 |
| `watchMatrixRun(runId)` | Stream run + cells + attempts | — | §6 |
| `watchMatrixRunsByUser(userId)` | Stream all runs for user | — | §2.6 |
| `getActiveMatrixRun(userId)` | Find InProgress run | — | §2.4 |
| `logAttempt(cellId, data)` | Create MatrixAttempt | Run must be InProgress, cell not excluded | §6.5 |
| `updateAttempt(attemptId, data)` | Edit attempt | — | §6.10 |
| `deleteAttempt(attemptId)` | Delete attempt | — | §6.10 |
| `excludeCell(cellId)` | Soft-exclude from run | Run InProgress | §6.8 |
| `includeCell(cellId)` | Re-include in run | Run InProgress | §6.9 |
| `completeMatrixRun(runId, userId)` | Transition to Completed | All active cells meet min attempts | §6.11 |
| `discardMatrixRun(runId, userId)` | Soft-delete run | — | §1.6 |

**Cell generation logic (§6.3–6.4):**
```
Input: List<MatrixAxis> with their MatrixAxisValues
Output: Cartesian product → one MatrixCell per unique combination
  - 1-axis (Gapping): N cells (one per club)
  - 2-axis: N × M cells
  - 3-axis (Wedge/Chipping): N × M × P cells
Each cell.AxisValueIDs = [axis1ValueId, axis2ValueId, axis3ValueId]
```

**Completion validation (§6.11):**
```
For each cell where ExcludedFromRun = false:
  COUNT(attempts) >= SessionShotTarget
If any cell fails: throw ValidationException
```

**Mutual exclusivity enforcement:**
- `createMatrixRun`: Check `getActiveMatrixRun(userId)` == null AND no active PracticeBlock (query PracticeBlocks where userId matches, endTimestamp is null, isDeleted is false)
- Mirror check in `PracticeRepository.createPracticeBlock`: also check no active MatrixRun

### Create `lib/data/repositories/performance_snapshot_repository.dart`

| Method | Purpose | Spec Ref |
|--------|---------|----------|
| `createSnapshotFromRun(runId, userId)` | Generate PerformanceSnapshot + SnapshotClubs from completed run | §1.9 |
| `getSnapshot(snapshotId)` | Fetch snapshot with clubs | — |
| `watchSnapshotsByUser(userId)` | Stream all snapshots | — |
| `getPrimarySnapshot(userId)` | Get current primary | §1.9 |
| `setPrimarySnapshot(snapshotId, userId)` | Designate primary (unset previous) | §1.9 |
| `deleteSnapshot(snapshotId)` | Soft-delete | — |

**Snapshot creation from Gapping Chart (§1.9):**
```
For each club in completed run:
  SnapshotClub.CarryDistanceMeters = AVG(attempts.CarryDistanceMeters) for that cell
  SnapshotClub.TotalDistanceMeters = AVG(attempts.TotalDistanceMeters) for that cell
  SnapshotClub.DispersionLeftMeters = AVG(attempts.LeftDeviationMeters)
  SnapshotClub.DispersionRightMeters = AVG(attempts.RightDeviationMeters)
```

**Snapshot creation from Chipping Matrix:**
```
Same pattern but with RolloutDistanceMeters populated
```

**Derived pre-population (§1.9.3):**
```
When creating a new Gapping Chart run, pre-populate based on up to 3 most recent completed runs:
  weight(run) = exp(-2.25 × sqrt(age_days / 365))
  derived_value = Σ(value × weight) / Σ(weight)
```

### Extend `lib/data/repositories/planning_repository.dart`

- Add `completeMatrixSlot(userId, date, slotIndex, matrixRunId)` — mirrors existing `completeSlot()` but sets `completingMatrixRunId`
- Extend `assignMatrixToSlot(userId, date, slotIndex, matrixType)` — set slot's matrixType

### Register Providers

**Modify `lib/providers/repository_providers.dart`:**
- Add `matrixRepositoryProvider`
- Add `performanceSnapshotRepositoryProvider`
- Wire SyncWriteGate into MatrixRepository

### Tests

**File:** `test/data/repositories/matrix_repository_test.dart`
- State machine: create → complete, create → discard
- Cell generation: 1-axis, 2-axis, 3-axis Cartesian product
- Attempt CRUD: log, update, delete
- Cell exclusion/inclusion
- Completion validation: fails with insufficient attempts, passes with sufficient
- Mutual exclusivity: cannot create MatrixRun with active PB, and vice versa
- ~40 tests

**File:** `test/data/repositories/performance_snapshot_repository_test.dart`
- Snapshot creation from gapping chart run
- Primary snapshot designation (only one)
- Derived pre-population weight calculation
- ~15 tests

---

## Phase M3 — DTOs + Sync Integration

**Goal:** Sync-ready serialisation for all 7 new entities. Extend sync engine payload ordering.

**Pattern to follow:** `lib/data/dto/practice_block_dto.dart` — same `toSyncDto()` extension + `fromSyncDto()` function pattern.

### New DTO Files (create in `lib/data/dto/`)

| File | Entity | Parent FK | Key Fields |
|------|--------|-----------|------------|
| `matrix_run_dto.dart` | MatrixRun | UserID | All enums via `.dbValue` |
| `matrix_axis_dto.dart` | MatrixAxis | MatrixRunID | AxisType enum |
| `matrix_axis_value_dto.dart` | MatrixAxisValue | MatrixAxisID | — |
| `matrix_cell_dto.dart` | MatrixCell | MatrixRunID | AxisValueIDs as JSON array |
| `matrix_attempt_dto.dart` | MatrixAttempt | MatrixCellID | Nullable numeric fields |
| `performance_snapshot_dto.dart` | PerformanceSnapshot | UserID | IsPrimary bool |
| `snapshot_club_dto.dart` | SnapshotClub | SnapshotID | Nullable distances |

### Extend Sync Engine

**Modify `lib/core/sync/sync_engine.dart`:**
- Add 7 new entities to upload payload assembly (parent-before-child ordering):
  1. MatrixRuns (after PracticeBlocks)
  2. MatrixAxes
  3. MatrixAxisValues
  4. MatrixCells
  5. MatrixAttempts
  6. PerformanceSnapshots
  7. SnapshotClubs
- Add to download merge pipeline (same ordering)

**Modify `lib/data/dto/sync_dto.dart`** (barrel export):
- Export all 7 new DTO files

### Extend Merge Algorithm

**Modify `lib/core/sync/merge_algorithm.dart`:**
- Add LWW merge for all 7 new tables (standard row-level merge, no slot-level complexity)

### Tests

**File:** `test/data/dto/matrix_run_dto_test.dart` (+ 6 more DTO test files)
- Round-trip: create entity → toSyncDto → fromSyncDto → verify all fields match
- Nullable field handling
- Enum serialisation
- ~7 tests per DTO file = ~49 tests

---

## Phase M4 — Providers + Runtime Coordination

**Goal:** Riverpod providers for all matrix state. MatrixActions coordinator (mirrors PracticeActions). Mutual exclusivity at provider level.

**Pattern to follow:** `lib/providers/practice_providers.dart` — same coordinator pattern with TimerService integration.

### Create `lib/providers/matrix_providers.dart`

**State Providers:**

| Provider | Type | Purpose |
|----------|------|---------|
| `matrixRepositoryProvider` | (already in repo providers) | — |
| `activeMatrixRunProvider(userId)` | StreamProvider | Watch active InProgress run |
| `matrixRunHistoryProvider(userId)` | StreamProvider | All runs for user, most recent first |
| `matrixRunDetailProvider(runId)` | StreamProvider | Single run with cells + attempts |
| `matrixCellProgressProvider(runId)` | Provider | Computed: cells completed / total active cells |
| `matrixActionsProvider` | Provider | MatrixActions coordinator |
| `canStartExecutionProvider(userId)` | Provider | True if no active PB AND no active MatrixRun |

**MatrixActions Coordinator:**

```dart
class MatrixActions {
  final MatrixRepository _matrixRepo;
  final PerformanceSnapshotRepository _snapshotRepo;
  final PracticeRepository _practiceRepo; // for mutual exclusivity check
  final TimerService _timerService;
  final CompletionMatcher _completionMatcher; // for matrix slot matching
  final SyncOrchestrator? _syncOrchestrator;

  Future<MatrixRun> startGappingChart(userId, config) {...}
  Future<MatrixRun> startWedgeMatrix(userId, config) {...}
  Future<MatrixRun> startChippingMatrix(userId, config) {...}
  Future<void> logAttempt(cellId, data) {...}
  Future<void> completeRun(runId, userId) {...}  // + auto-create snapshot
  Future<void> discardRun(runId, userId) {...}
}
```

**TimerService integration:**
- 4h auto-end timer for MatrixRun (mirrors PracticeBlock 4h timer)
- No session-level inactivity timer (matrix has no sessions concept)

**Home Dashboard integration:**

**Modify `lib/features/home/home_dashboard_screen.dart`:**
- Watch `activeMatrixRunProvider(userId)` — show "Resume Matrix" button if active
- When active MatrixRun exists, hide "Start Today's Practice" and "Start Clean Practice"
- Add "Start Matrix" action (navigates to matrix type picker)

**Modify `lib/providers/practice_providers.dart`:**
- In `PracticeActions.startPracticeBlock()`: add guard checking no active MatrixRun

### Tests

**File:** `test/providers/matrix_providers_test.dart`
- MatrixActions: start run, log attempt, complete, discard
- Mutual exclusivity: start PB fails when MatrixRun active, start Matrix fails when PB active
- Timer: 4h auto-end fires
- `canStartExecutionProvider` reflects both PB and Matrix state
- ~25 tests

---

## Phase M5 — Gapping Chart Workflow Screens

**Goal:** Complete Gapping Chart creation, execution, and completion flow. First playable matrix type.

**Spec sections:** §3 (Gapping Chart Workflow)

### New Files (create in `lib/features/matrix/`)

```
lib/features/matrix/
├── screens/
│   ├── matrix_type_picker_screen.dart    # Choose Gapping/Wedge/Chipping
│   ├── gapping_setup_screen.dart         # Club selection, shot target, options
│   ├── gapping_execution_screen.dart     # Attempt entry per club (carry + total + deviation)
│   └── matrix_completion_screen.dart     # Summary + snapshot creation prompt
├── widgets/
│   ├── club_picker_chips.dart            # Multi-select club chips from user's bag
│   ├── attempt_entry_form.dart           # Carry/Total/Deviation numeric inputs
│   ├── cell_progress_indicator.dart      # N/target attempts per cell
│   └── shot_order_indicator.dart         # Current cell in sequence
└── models/
    └── matrix_config.dart                # Config data classes per MatrixType
```

**Screen flow:**
1. `MatrixTypePickerScreen` → user picks Gapping Chart → navigate to `GappingSetupScreen`
2. `GappingSetupScreen`:
   - Club selection from bag (multi-select chips, §3.2)
   - Session shot target (stepper, default 5, min 3, §3.3)
   - Environment/Surface/Device options (optional, §3.5)
   - Shot order mode (§3.8)
   - Dispersion capture toggle (§3.4)
   - → "Start" creates MatrixRun + navigates to execution
3. `GappingExecutionScreen`:
   - Shows current club (from shot order)
   - Attempt entry: Carry Distance (required), Total Distance (optional), Left/Right Deviation (if dispersion enabled)
   - Progress: N/target per cell, cells completed / total
   - "Next Cell" when current cell meets target (or manual skip)
   - "Complete" when all active cells meet minimum
4. `MatrixCompletionScreen`:
   - Summary: clubs tested, total attempts, duration
   - "Save as Snapshot" → creates PerformanceSnapshot
   - "Set as Primary Snapshot" toggle
   - "Done" → set showHomeProvider = true, popUntil first route

### Modify Track Tab

**Modify `lib/features/shell/tabs/track_tab.dart`:**
- Replace `_MatrixTab` placeholder with `MatrixHomepageScreen` (created in Phase M8)
- For now (Phase M5), replace with a simpler list: active run resume + "Start New" button

### Tests

**File:** `test/features/matrix/gapping_workflow_test.dart`
- Setup screen renders club selection from bag
- Shot target validation (min 3)
- Execution screen shows correct cell sequence
- Attempt logging updates progress
- Completion blocked when cells below minimum
- Completion succeeds when all cells meet target
- Snapshot created on completion
- ~20 tests

---

## Phase M6 — Wedge Matrix Workflow Screens

**Goal:** Complete Wedge Matrix flow. 3-axis setup with checkpoints and templates.

**Spec sections:** §4 (Wedge Matrix Workflow)

### New Files

```
lib/features/matrix/screens/
├── wedge_setup_screen.dart           # 3-axis setup: Club × Effort × Flight
├── wedge_execution_screen.dart       # Cell-by-cell attempt entry
└── wedge_checkpoint_editor.dart      # Axis checkpoint configuration
```

**Setup flow (§4.1–4.11):**
1. Club selection (same as Gapping, multi-select from bag)
2. Effort axis: name + checkpoints (default: "50%, 75%, 100%", §4.6–4.7)
3. Flight axis: name + checkpoints (default: "Low, Standard, High", §4.6–4.7)
4. Template support: "Standard 3×3" preset loads defaults (§4.9)
5. Cell preview: shows N×M×P matrix grid before start (§4.10)
6. Session options: shot target, order mode, environment, dispersion

**Execution (§4.12–4.18):**
- Same attempt entry form as Gapping (carry + total + deviation)
- Cell navigation with picklist (§4.17): quick-jump to any cell
- Cell exclusion during run (§4.18)
- Progress tracking per cell and overall

**Completion:**
- Same `MatrixCompletionScreen` from Phase M5 (reused)
- Snapshot creation logic handles Wedge Matrix type

### Tests

**File:** `test/features/matrix/wedge_workflow_test.dart`
- 3-axis cell generation (N clubs × M efforts × P flights)
- Checkpoint editor validation (min 2 per axis)
- Template loads correct defaults
- Cell navigation/picklist
- Cell exclusion/re-inclusion during run
- ~20 tests

---

## Phase M7 — Chipping Matrix Workflow Screens

**Goal:** Complete Chipping Matrix flow with green conditions and rollout capture.

**Spec sections:** §5 (Chipping Matrix Workflow), §7.8–7.9 (rollout data model)

### New Files

```
lib/features/matrix/screens/
├── chipping_setup_screen.dart         # Club × CarryDistance × Flight + green conditions
├── chipping_execution_screen.dart     # Attempt entry with rollout field
└── chipping_attempt_form.dart         # Carry + Rollout + Total entry (§7.8.2)
```

**Setup flow (§5.1–5.11):**
1. Club selection (chipping clubs from bag)
2. Carry Distance axis: target distances (e.g., 5y, 10y, 15y, 20y) — custom values allowed
3. Flight axis: same as Wedge (Low, Standard, High)
4. Green conditions (§5.5): Speed (6.0–15.0 in 0.5 steps), Firmness (Soft/Medium/Firm)
5. Session options: shot target, order mode

**Execution (§5.12–5.16):**
- Attempt entry: Carry Distance + Rollout Distance + Total Distance
- Validity rule: at least one of Carry/Rollout/Total must be populated (§7.8.2)
- Cell navigation same as Wedge
- Progress tracking same pattern

**Completion:**
- Same `MatrixCompletionScreen` (reused)
- Snapshot creation includes rollout data in SnapshotClubs

### Tests

**File:** `test/features/matrix/chipping_workflow_test.dart`
- Green condition storage (speed, firmness)
- Rollout field entry and validation
- Attempt validity (at least one distance required)
- Snapshot creation with rollout data
- ~15 tests

---

## Phase M8 — Matrix Homepage + Navigation Integration

**Goal:** Full Matrix Homepage (§2), floating resume banner, Track tab integration, Home Dashboard matrix awareness.

**Spec sections:** §2 (Matrix Homepage)

### New Files

```
lib/features/matrix/screens/
├── matrix_homepage_screen.dart        # Main matrix hub (§2.2)
└── matrix_run_review_screen.dart      # Per-run summary (§2.7, stub for Phase M9)

lib/features/matrix/widgets/
├── matrix_run_card.dart               # Run list item with type, date, status
└── matrix_type_badge.dart             # Coloured badge per MatrixType
```

**Matrix Homepage (§2.2):**
- Start Matrix section: 3 cards (Gapping Chart, Wedge Matrix, Chipping Matrix) → navigate to setup
- Active Run section (§2.4): if InProgress run exists, show prominent resume card
- History section (§2.6): reverse-chronological list of completed runs, grouped by type
- "Compare" action on Gapping Chart runs (stub for Phase M9)

**Navigation integration:**

**Modify `lib/features/shell/tabs/track_tab.dart`:**
- Replace temporary Matrix content with `MatrixHomepageScreen(embedded: true)`

**Modify `lib/features/shell/shell_screen.dart`:**
- "Resume Matrix" bar in bottom nav area (mirrors "Resume Practice" bar)
- Active MatrixRun detection: watch `activeMatrixRunProvider(userId)`

**Modify `lib/features/home/home_dashboard_screen.dart`:**
- "Resume Matrix" button when active run exists
- Matrix-aware action zone: mutual exclusivity reflected in button visibility

**Post-completion routing:**
- `MatrixCompletionScreen` Done → set `showHomeProvider = true` + `popUntil(isFirst)`
- Same pattern as `PostSessionSummaryScreen`

### Calendar Integration

**Modify `lib/features/planning/screens/calendar_day_detail_screen.dart`:**
- Support matrix-type slots: show MatrixType badge instead of drill name
- "Start Matrix" action on unfulfilled matrix slots

**Modify `lib/features/planning/completion_matching.dart`:**
- Add matrix completion matching: when MatrixRun completes, find matching unfulfilled matrix slot for today

### Tests

**File:** `test/features/matrix/matrix_homepage_test.dart`
- Homepage renders start cards for all 3 types
- Active run shows resume card
- History list shows completed runs
- Resume banner visible when active run exists
- Mutual exclusivity: practice active → matrix start cards disabled
- ~15 tests

---

## Phase M9 — Review Pages

**Goal:** All matrix review visualisations. Gapping ladder + gap highlighting + comparison. Wedge distance ladder. Chipping accuracy charts. Cell detail views.

**Spec sections:** §7 (Review Pages)

### New Files

```
lib/features/matrix/review/
├── gapping_review_screen.dart         # Distance ladder + table (§7.4)
├── gapping_comparison_screen.dart     # Multi-run overlay (§7.6)
├── wedge_review_screen.dart           # Distance ladder with flight colours (§7.7)
├── chipping_review_screen.dart        # Accuracy overview + club sections (§7.8)
├── cell_detail_screen.dart            # Attempt list with edit/delete (§7.4.4, §7.7.5, §7.8.7)

lib/features/matrix/review/widgets/
├── distance_ladder_chart.dart         # Horizontal ladder visualisation
├── gap_warning_indicator.dart         # Gap threshold warnings (§7.5)
├── comparison_table.dart              # Multi-run comparison table (§7.6.3)
├── chipping_accuracy_table.dart       # Target vs actual overview (§7.8.4)
├── chipping_mini_chart.dart           # Per-cell target line + scatter (§7.8.5)
└── flight_colour_legend.dart          # Low/Standard/High colour key (§7.7.3)
```

**Review Tab Restructure (Decision #2 — confirmed):**

**Modify `lib/features/shell/tabs/review_tab.dart`:**
- Current: 2 tabs (Dashboard | Analysis)
- After: **3 tabs** (Practice | Matrices | Analysis)
  - "Practice" = current `ReviewDashboardScreen` (renamed tab label)
  - "Matrices" = new `MatrixReviewHubScreen` (links to per-type review pages)
  - "Analysis" = existing `AnalysisScreen` (unchanged)
- Update `DefaultTabController(length: 3)` and add third `Tab` + `TabBarView` child

**Gapping Review (§7.3–7.5):**
- Distance ladder chart: clubs ordered by carry distance, horizontal bars
- Numerical table: Club | Avg Carry | Avg Total | Shots
- Gap highlighting: configurable min/max thresholds (default 6/20 in user's unit)
- Club detail: tap row → attempt list with edit/delete

**Gapping Comparison (§7.6):**
- Select up to 3 runs → overlay ladder + comparison table
- Most recent first

**Wedge Review (§7.7):**
- Distance ladder: all Club × Effort × Flight combos plotted by carry
- Flight colour differentiation (Low=Blue, Standard=Green, High=Orange)
- Filtering by any axis (checkbox chips)
- Tap point → cell detail

**Chipping Review (§7.8):**
- Distance Accuracy Overview table (per target distance)
- Club sections (expandable, collapsed by default)
- Per-cell mini-chart: target line + scatter dots
- Accuracy metrics: avg carry, avg error, avg rollout, short bias

**Gap threshold settings:**
- Store in UserPreferences JSON (extends existing S10 model)
- Fields: `gapMinThreshold`, `gapMaxThreshold` (in user's DistanceUnit)

### Tests

**File:** `test/features/matrix/review/gapping_review_test.dart`
- Ladder chart orders clubs by carry distance
- Gap warning shown when gap < min or > max threshold
- Club detail shows attempt list
- ~10 tests

**File:** `test/features/matrix/review/wedge_review_test.dart`
- All cells plotted on ladder
- Flight colours applied correctly
- Filtering hides/shows correct points
- ~10 tests

**File:** `test/features/matrix/review/chipping_review_test.dart`
- Accuracy overview aggregates correctly
- Club sections expandable
- Rollout displayed
- ~10 tests

---

## Phase M10 — Analytics Integration

**Goal:** Cross-run analytics with outlier trimming, weighted aggregation, trend charts, and automated insights.

**Spec sections:** §9 (Analytics Integration)

### New Files

```
lib/features/matrix/analytics/
├── matrix_analytics_engine.dart       # Pure computation functions
├── outlier_trimmer.dart               # 10% symmetric trim (§9.3.3)
├── weighted_aggregator.dart           # exp(-2.25 × √(age/365)) decay (§9.4)
├── insight_generator.dart             # Automated insight rules (§9.10)
└── analytics_types.dart               # Result data classes

lib/providers/matrix_analytics_providers.dart  # Riverpod providers for analytics
```

**Analytics Engine (pure functions):**

| Function | Input | Output | Spec Ref |
|----------|-------|--------|----------|
| `trimOutliers(attempts, trimPercent)` | List<double>, 0.10 | Trimmed list | §9.3.3 |
| `computeWeight(runAge)` | int days | double weight | §9.4.2 |
| `weightedAverage(values, weights)` | Lists | double | §9.4.3 |
| `clubDistanceAnalytics(runs)` | Gapping runs | ClubDistanceResult[] | §9.6 |
| `wedgeCoverageAnalytics(runs)` | Wedge runs | WedgeCoverageResult[] | §9.7 |
| `chippingAccuracyAnalytics(runs)` | Chipping runs | ChippingAccuracyResult[] | §9.8 |
| `distanceTrend(runs, cellKey)` | Runs + cell ID | TrendPoint[] | §9.9 |
| `generateInsights(analytics)` | Any analytics result | List<Insight> (max 3) | §9.10 |

**Analytics categories (§9.5):**
1. Club Distance (Gapping): avg carry, avg total, consistency (StdDev), gap analysis
2. Wedge Coverage: coverage points, gap detection, overlap detection
3. Chipping Accuracy: avg error, short bias, rollout by green condition
4. Distance Trend: per-run averages plotted over time (all types)

**Weighted vs Raw toggle (§9.4.4):**
- UI toggle on each analytics view
- Session-scoped state (does not persist)

**Insight rules (§9.10.3):**
- Gapping: small gap warning, large gap warning, high inconsistency
- Wedge: coverage gap, distance overlap
- Chipping: consistent short bias, high error at distance, rollout variance by condition
- Max 3 per page, ranked by magnitude

### Integration Points

**Modify matrix review screens (from Phase M9):**
- Add analytics sections below per-run data
- Add "All Runs" analytics tab on review hub
- Add weighted/raw toggle
- Add insight display (inline with relevant chart)

### Tests

**File:** `test/features/matrix/analytics/outlier_trimmer_test.dart`
- 5 attempts: removes 1 from each end
- 10 attempts: removes 1 from each end
- 3 attempts: no trimming (too few)
- ~8 tests

**File:** `test/features/matrix/analytics/weighted_aggregator_test.dart`
- Weight at 0 days ≈ 1.0
- Weight at 365 days ≈ 0.32
- Weighted average correctness
- ~6 tests

**File:** `test/features/matrix/analytics/insight_generator_test.dart`
- Gapping: small gap insight generated
- Wedge: coverage gap insight generated
- Chipping: short bias insight generated
- Max 3 insights enforced
- Ranked by magnitude
- ~12 tests

**File:** `test/features/matrix/analytics/matrix_analytics_engine_test.dart`
- Club distance analytics: correct averages, consistency, gaps
- Wedge coverage: correct plotting, gap detection
- Chipping accuracy: correct error, rollout, short bias
- Distance trend: correct per-run points
- ~15 tests

---

## Supabase Migration (Cross-Cutting — Execute With Phase M1)

### Create `supabase/migrations/006_matrix_tables.sql`

DDL for server-side tables matching Drift schema:
- `MatrixRuns`, `MatrixAxes`, `MatrixAxisValues`, `MatrixCells`, `MatrixAttempts`
- `PerformanceSnapshots`, `SnapshotClubs`
- RLS policies (same pattern as existing tables)
- Indexes matching Drift indexes

### Create `supabase/migrations/007_sync_matrix.sql`

Extend `sync_upload` and `sync_download` RPCs to include matrix entities.

---

## Dependency Graph

```
M1 (Tables/Enums/Migration)
 └─ M2 (Repository)
     ├─ M3 (DTOs/Sync)
     └─ M4 (Providers/Coordination)
         ├─ M5 (Gapping Screens)
         │   └─ M6 (Wedge Screens)
         │       └─ M7 (Chipping Screens)
         ├─ M8 (Homepage/Navigation)
         └─ M9 (Review Pages)
             └─ M10 (Analytics)
```

**Critical path:** M1 → M2 → M4 → M5 → M6 → M7

**Parallelisable after M2:** M3 (DTOs) can run in parallel with M4.

**Parallelisable after M4:** M5/M6/M7 (workflows) and M8 (navigation) can interleave.

---

## Estimated New Code

| Phase | New Files | Modified Files | Est. Tests |
|-------|-----------|----------------|------------|
| M1 | 9 (7 tables + migration + enums) | 3 (database.dart, enums.dart, slot.dart) | ~15 |
| M2 | 2 (repos) | 3 (planning_repo, practice_repo, repo_providers) | ~55 |
| M3 | 7 (DTOs) | 3 (sync_engine, merge_algorithm, barrel) | ~49 |
| M4 | 1 (providers) | 3 (practice_providers, home_dashboard, repo_providers) | ~25 |
| M5 | 8 (screens + widgets + models) | 1 (track_tab) | ~20 |
| M6 | 3 (screens) | 0 | ~20 |
| M7 | 3 (screens) | 0 | ~15 |
| M8 | 4 (screens + widgets) | 4 (track_tab, shell, home, calendar) | ~15 |
| M9 | 11 (screens + widgets) | 2 (review_tab, user_prefs) | ~30 |
| M10 | 5 (analytics + providers) | ~3 (review screens) | ~41 |
| **Total** | **~53** | **~22** | **~285** |

---

## CLAUDE.md Updates Required

After all phases complete:
- Add `features/matrix/` to directory tree
- Add new tables to table count (27 → 34)
- Add new enums to enum count (23 → 30)
- Add phase completion log entries
- Add schema version note (v4 → v5)
- Update Known Deviations if any arise

---

## Resolved Decisions

| # | Question | Decision | Date |
|---|----------|----------|------|
| 1 | PerformanceSnapshot vs ClubPerformanceProfile migration | **Keep both.** Add PerformanceSnapshot alongside CPP. Drill target resolution checks PerformanceSnapshot first → falls back to CPP. Non-breaking, preserves existing data. | 2026-03-06 |
| 2 | Review tab restructure | **Add 3rd tab.** Review tab becomes 3 inner tabs: Practice \| Matrices \| Analysis. "Practice" = current Dashboard content (renamed). "Matrices" = new MatrixReviewHubScreen. "Analysis" = unchanged. | 2026-03-06 |
| 3 | RunNumber scope | **Per-user sequential.** Computed as `MAX(RunNumber) + 1` for that user at creation time. Offline-first compatible. | 2026-03-06 |
