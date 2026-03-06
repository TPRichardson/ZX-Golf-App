# Section 1 — Matrix & Gapping System Architecture (1v.a6 Draft)

This document defines the **Matrix & Gapping System** within the ZX Golf App.
It introduces structured workflows for capturing **distance calibration datasets** such as club gapping charts and distance matrices. The system operates alongside the Drill system but serves a fundamentally different purpose.

This section establishes the **conceptual architecture, runtime model, lifecycle rules, and integration points** for matrices.

The Matrix system is fully harmonised with:

- Section 3 — User Journey Architecture
- Section 5 — Review: SkillScore & Analysis
- Section 6 — Data Model & Persistence Layer
- Section 9 — Golf Bag & Club Configuration
- Canonical Definitions (0v.f1)

---

## X.1 System Purpose

The Matrix & Gapping system exists to build and maintain a **reference dataset describing the player's real-world shot distances**.

Matrices are not training drills. They are **measurement workflows** designed to capture reliable calibration data.

The primary purposes are:

1. Build a **reference dataset of club distances**
2. Help players understand their **distance control patterns**
3. Provide a **decision-support reference during play**

Matrices therefore answer a different question from drills.

> Drills → "How well did I execute?"
> Matrices → "What does my shot actually do?"

Matrices provide the empirical data that defines the player's **personal yardage model**.

---

## X.2 System Position Within ZX

Matrices operate as a **separate tracking subsystem** parallel to the Drill system.

They share the **Track surface** but do not reuse the Drill runtime architecture.

```
Track
 ├── Drills
 └── Matrices & Gapping
```

### Key Architectural Separation

Matrices are **not implemented as drills**.

They do not generate:

- Drill Sessions
- Sets
- Instances
- Subskill window entries
- 0–5 scoring events

This separation protects the integrity of the **scoring engine**, which is designed exclusively for performance evaluation.

### Architectural Decision Point — Requires Technical Review

The decision to implement matrices as a separate runtime system (rather than reusing the Drill architecture) is the correct initial direction and is the basis on which this specification is written.

However, this decision carries trade-offs that must be explicitly reviewed during the technical build-out phase.

**Arguments for separation (current direction):**

- The Drill system is tightly coupled to the scoring engine. Forcing matrices into the Drill runtime would produce meaningless 0–5 scores, pollute subskill windows, and distort the Overall Score.
- Matrix structures (e.g. Club × Swing Length grids) do not map cleanly to the Session → Set → Instance hierarchy.
- Matrices are long-lived reference datasets, not discrete practice sessions. This is a fundamentally different object lifecycle.
- UX clarity: users benefit from a clear conceptual distinction between training (drills) and measurement (matrices).

**Arguments for reuse that must be evaluated:**

- The Drill system already handles attempt tracking, instance editing, timestamp logic, session lifecycle, offline behaviour, and sync. Reusing it reduces engineering complexity.
- A parallel runtime system introduces new entities, new persistence rules, additional sync logic, and additional review visualisations.
- Consistency of tracking UX — users may expect all shot logging in Track to behave similarly.

**Instruction for technical specification phase:**

The implementing engineer must explicitly evaluate whether a shared runtime foundation is achievable without compromising the separation of matrices from the scoring engine. The final technical specification must document the rationale for the chosen implementation path.

---

## X.3 Matrix Types

The system launches with **three fixed matrix workflows**.

These workflows are system-defined and **not user-configurable templates**.

### Supported Matrix Types

**1. Gapping Chart**

Measures carry distance for each club in the user's bag. Optionally captures dispersion data during the same workflow.

**2. Wedge Matrix**

Measures distance produced by partial wedge swings.

Typical structure: Club × Swing Length

**3. Chipping Matrix**

Measures distance behaviour around the green.

Typical structure: Club × Target Distance

The architecture must support future matrix types being added, but users cannot create custom matrix structures in V1.

---

## X.4 Matrix Runtime Model

Matrices introduce a runtime hierarchy separate from drills.

```
MatrixRun
 └── MatrixCell
      └── MatrixAttempt
```

### MatrixRun

Represents one execution of a matrix workflow.

Examples:

```
Wedge Matrix — 2026-03-01
Wedge Matrix — 2026-06-15
```

A MatrixRun contains multiple MatrixCells.

### MatrixCell

Represents a single **measurement unit** within the matrix. The definition of a measurement unit varies by matrix type.

| Matrix Type | Measurement Unit |
|---|---|
| Gapping Chart | Club |
| Wedge Matrix | Club × Swing Length |
| Chipping Matrix | Club × Target Distance |

Examples:

```
Wedge Matrix cell: 56° × 50% Swing
Chipping Matrix cell: PW × 10 yards
```

Each MatrixCell contains multiple MatrixAttempts.

### MatrixAttempt

Represents a single recorded shot within a MatrixCell.

MatrixAttempts store the **raw measurement data** used to derive averages and dispersion metrics.

---

## X.5 Attempt Capture Model

Matrix workflows record **every individual shot attempt**.

Attempts are not aggregated at entry time.

Example:

```
MatrixCell: 56° × 50% Swing
 └── MatrixAttempts
      • Distance = 84y
      • Distance = 82y
      • Distance = 86y
```

Aggregated values — such as average distance, variance, and dispersion — are **derived values** calculated from stored attempts. They are not stored as authoritative fields.

This design allows full recalculation if attempts are edited later.

---

## X.6 Minimum Attempt Requirement

All matrix measurements require a **minimum of three attempts per measurement unit** before the matrix run may be completed.

| Matrix Type | Measurement Unit | Minimum Attempts |
|---|---|---|
| Gapping Chart | Club | 3 |
| Wedge Matrix | Club × Swing Length | 3 |
| Chipping Matrix | Club × Target Distance | 3 |

Example progress indicators:

```
56° – 50% Swing    Attempts: 3 / 3  ✓
56° – 75% Swing    Attempts: 2 / 3  ✗
```

The **Finish Session** action is only enabled when all required measurement units have met the minimum attempt count. The system must enforce this with a hard block — partial completion is not permitted.

Users may record additional attempts beyond the minimum. All attempts contribute equally to derived averages.

---

## X.7 Matrix Run Lifecycle

Matrix runs use a **manual completion** model. A MatrixRun remains active until the user explicitly ends the workflow.

### States

```
MatrixRunState
 • InProgress
 • Completed
```

### Execution Flow

```
Start Matrix
      ↓
MatrixRun created (StartTimestamp recorded)
      ↓
MatrixAttempts logged across MatrixCells
      ↓
All measurement units reach minimum attempt count
      ↓
"Finish Session" action becomes available
      ↓
User presses Finish Session
      ↓
EndTimestamp recorded
      ↓
Duration calculated
      ↓
MatrixRun state → Completed
```

Manual completion allows the user to add additional attempts beyond the minimum before finalising the dataset. This is intentional — users may wish to record five or six shots per cell for greater confidence in the averages.

---

## X.8 Incomplete Run Behaviour

Matrix runs are **never discarded automatically by the system**.

If a user exits the matrix workflow before pressing Finish Session, the run is saved in an InProgress state and may be resumed at any time.

```
MatrixRun
 State: InProgress
 Attempts: 18 / 36
```

The incomplete run appears in the Track → Matrices & Gapping homepage as a resumable activity.

Users may:

- **Resume** — continue logging attempts from where they left off
- **Discard** — permanently delete the run via an explicit user action

Only **Completed MatrixRuns** contribute to reference datasets, analytics calculations, or ClubPerformanceProfile updates.

---

## X.9 Editing Behaviour

Users may edit MatrixAttempts **after a MatrixRun is completed**.

### Editable Fields

- Measured distance
- Dispersion values (if captured)
- Club selection (if mislogged)

### Immutable Fields

The following fields are structurally immutable after a MatrixRun is created and cannot be changed:

- Matrix type
- MatrixCell structure (the grid of measurement units)
- StartTimestamp (used for recency weighting)

Structural changes require creating a new MatrixRun.

### Recalculation Cascade

When an attempt is edited:

```
MatrixAttempt edited
      ↓
MatrixCell averages recalculated
      ↓
MatrixRun aggregates updated
      ↓
Reference dataset recalculated (if this run contributes to ClubPerformanceProfile)
```

---

## X.10 Session Duration Tracking

Each MatrixRun records execution time passively.

Stored fields:

```
StartTimestamp   (recorded when the run begins)
EndTimestamp     (recorded when Finish Session is pressed)
Duration         (EndTimestamp − StartTimestamp)
```

Duration tracking has **no scoring impact** and does not trigger any recalculation. It may appear in analytics for time-based practice breakdowns.

---

## X.11 Versioning and Historical Runs

Matrices are **versioned through repeated runs**.

Each time a user completes a matrix workflow, a new MatrixRun record is created. All historical runs are permanently preserved.

Example:

```
Wedge Matrix
 ├── Run — 2026-03-01  (Completed)
 ├── Run — 2026-06-15  (Completed)
 └── Run — 2026-09-10  (Completed)
```

This versioning model supports:

- Seasonal recalibration as distances change with course conditions or equipment
- Tracking the effect of equipment changes over time
- Long-term trend analysis
- Historical comparison in Review

---

## X.12 Performance Snapshot Model

The authoritative source of club performance data used by the drill architecture is the **PerformanceSnapshot**.

A PerformanceSnapshot is a saved record of the user's club distances and dispersion values at a point in time. It is the single entity the drill system reads from when resolving target distances, target box sizes, and club carry values. Matrix data does not feed the drill system directly — it feeds snapshot creation.

### Snapshot Structure

A snapshot contains one row per club in the user's bag at the time of creation. Each row holds the following optional fields:

```
PerformanceSnapshot
 └── SnapshotClub (one per club in bag)
      ├── ClubID
      ├── CarryDistance        (optional)
      ├── TotalDistance        (optional)
      ├── DispersionLeft       (optional)
      ├── DispersionRight      (optional)
      ├── DispersionShort      (optional)
      └── DispersionLong       (optional)
```

All measurement fields are optional. A snapshot may be saved with partial data — for example, carry distances only, with no dispersion values.

### Snapshot States

Each snapshot exists in one of two states:

```
SnapshotState
 • Active
 • Retired
```

At any point in time, one Active snapshot may be designated as the **Primary** snapshot. The Primary snapshot is the one the drill system uses. Only one snapshot may be Primary at a time.

Users may hold multiple Active snapshots simultaneously — for example, a summer distances snapshot and a winter distances snapshot — with only one designated as Primary. Managing which snapshot is Primary and which snapshots are retired is the user's responsibility. The system does not automatically retire snapshots when a new Primary is set.

### Integration with the Drill Architecture

The drill system reads exclusively from the Primary snapshot. If no Primary snapshot exists, the Club Carry and Percentage of Club Carry target distance modes defined in Section 4 (§4.4) are unavailable. Those modes are greyed out and inaccessible until a Primary snapshot is set.

If a field within the Primary snapshot is unpopulated for a given club, that specific capability is unavailable for that club only. Other clubs with populated fields are unaffected.

---

## X.13 Snapshot Creation Flow

Users create snapshots manually. The creation flow pre-populates all fields from matrix data to reduce manual effort, but every field remains editable before saving.

### Pre-Population Source

When opening the snapshot creation screen, the user chooses which matrix data to use for pre-population:

```
Pre-population source
 ├── Derived (recency-weighted calculation across up to 3 MatrixRuns)
 └── Last Session (values from the single most recent completed MatrixRun)
```

Both options are only available if the relevant matrix data exists. If no matrix data exists for a club, that club's fields are left blank in the creation form.

### Derived Pre-Population — Recency-Weighted Formula

When the user selects Derived as the pre-population source, values are calculated from the **three most recent completed MatrixRuns** using an exponential decay weighting model.

**Eligibility rules:**

1. Only Completed MatrixRuns are eligible. InProgress runs are excluded.
2. Only the 3 most recent eligible runs are used.
3. Any run with an age greater than **365 days** is excluded from the calculation.
4. Exception — if all available completed runs are older than 365 days, the single most recent run is used with a weight of 1.0.
5. If no completed runs exist, the field is left blank.

**Weighting formula:**

For each eligible run, a raw weight is calculated using:

```
w_i = exp( −2.25 × √( age_i / 365 ) )
```

Where `age_i` is the number of calendar days between the run's CompletionTimestamp and the current date.

Weights are normalised so they sum to 1.0:

```
W_i = w_i / ( w_1 + w_2 + w_3 )
```

The pre-populated value for any field is then:

```
Pre-populated Value = ( W_1 × value_1 ) + ( W_2 × value_2 ) + ( W_3 × value_3 )
```

**Worked examples:**

All three runs completed within the same week (ages 0, 3, 7 days):

| Run | Age | Raw Weight | Normalised Weight |
|---|---|---|---|
| Most recent | 0 days | 1.000 | 39.2% |
| Previous | 3 days | 0.816 | 32.0% |
| Oldest | 7 days | 0.733 | 28.8% |

Result: approximately equal weights with a slight recency edge.

Runs spread across the year (ages 0, 91, 274 days):

| Run | Age | Raw Weight | Normalised Weight |
|---|---|---|---|
| Most recent | Today | 1.000 | 68% |
| Previous | 3 months ago | 0.325 | 22% |
| Oldest | 9 months ago | 0.142 | 10% |

Result: most recent session contributes approximately 70%, with older sessions providing diminishing but non-zero influence.

### User Override

Once fields are pre-populated, the user may edit any value before saving. There is no distinction between a matrix-derived value and a manually entered value once the snapshot is saved — all values in a saved snapshot are treated as authoritative user data.

### Saving and Setting as Primary

On saving a new snapshot the user may:

- **Save** — snapshot is saved in Active state. Primary designation is unchanged.
- **Save and Set as Primary** — snapshot is saved in Active state and designated as the new Primary. The previous Primary remains Active but loses the Primary designation.

### Snapshot Naming

Each snapshot is given a user-defined name at creation time (e.g. "Summer 2026", "After new irons"). Names are editable after creation.

---

## X.14 Optional Dispersion Capture

The **Gapping Chart workflow** optionally captures dispersion data alongside carry distance measurements.

### Dispersion Axes

When dispersion capture is enabled, each MatrixAttempt may record values across two independent axes:

| Axis | Values |
|---|---|
| Lateral deviation | Left deviation, Right deviation |
| Depth deviation | Long deviation, Short deviation |

These four values are optional and independent. A user may capture lateral deviation without capturing depth deviation, or capture both.

### Derived Dispersion Metrics

Dispersion values are derived from individual attempt measurements and may feed into:

- ClubPerformanceProfile dispersion fields (DispersionLeft, DispersionRight, DispersionShort, DispersionLong)
- Target box generation for grid-based drills
- Planning and practice insights

### Workflow Behaviour

Dispersion capture is **opt-in**. The Gapping Chart workflow must function fully with distance-only capture. Enabling dispersion capture extends the workflow but does not block or alter the core distance recording flow.

---

## X.15 Calendar Integration

Matrices can be scheduled within the **Plan → Calendar system** using the same Slot model as drills.

Example:

```
CalendarDay
 ├── Slot — Drill
 ├── Slot — Drill
 └── Slot — Wedge Matrix
```

### Execution Paths

The execution paths for drills and matrices are distinct:

```
Drill Slot  → PracticeBlock → Session → Set → Instance
Matrix Slot → MatrixRun    → MatrixCell → MatrixAttempt
```

### Plan Adherence

Matrix Slots follow the same completion matching rules as Drill Slots. A completed MatrixRun on the same CalendarDay as a planned Matrix Slot marks that Slot as complete.

Matrix completions contribute to **Plan Adherence** metrics in the same way as Drill completions. The Calendar measures practice discipline, not scoring output.

---

## X.16 Relationship to the Scoring Engine

Matrices are **fully isolated from the scoring engine**.

They do not generate:

- 0–5 scores
- Transition window entries
- Pressure window entries
- Subskill weighted averages
- Skill Area scores
- Changes to the Overall 1000-point score

Matrix data does not trigger reflow. No scoring recalculation occurs as a result of matrix runs, edits, or deletions.

Matrices exist purely as **reference dataset generators**. Their influence on the rest of the system is limited to the ClubPerformanceProfile, where it is user-controlled and explicit.

---

## X.17 Architectural Guarantees

The Matrix & Gapping system guarantees:

- **Scoring engine isolation** — no matrix event generates scoring data or triggers reflow
- **Full historical preservation** — all completed MatrixRuns are permanently stored
- **Deterministic recalculation** — derived values are always recalculable from stored attempts
- **Editable attempt-level data** — individual shots may be corrected after run completion
- **Minimum measurement integrity** — runs cannot be completed without the required minimum attempts per measurement unit
- **PerformanceSnapshot as single authority** — the drill system reads exclusively from the Primary snapshot; matrix data never feeds the drill system directly
- **No silent data changes** — matrix data pre-populates the snapshot creation form but the user must explicitly save a snapshot for it to take effect
- **User-managed snapshot lifecycle** — the system never automatically retires or replaces snapshots; all lifecycle decisions belong to the user
- **Partial snapshot support** — snapshots may be saved with incomplete data; only the unpopulated fields for a given club are restricted
- **Hard gate on absent Primary** — Club Carry and Percentage of Club Carry target modes are unavailable until a Primary snapshot is set
- **Canonical weighting formula** — Derived pre-population uses a fully specified exponential decay formula; the calculation is deterministic and auditable
- **Resumable incomplete runs** — the system never discards an InProgress MatrixRun without explicit user action
- **Clear conceptual separation** — training (drills), measurement (matrices), and calibration (snapshots) are architecturally and conceptually distinct
- **Clear conceptual separation** — training (drills) and measurement (matrices) are architecturally and conceptually distinct

---

## X.18 Resolved Architectural Decisions

The following decisions were made during the specification review process and have data model implications that must be captured in the data model extensions document.

---

### X.18.1 PerformanceSnapshot Replaces ClubPerformanceProfile

The `ClubPerformanceProfile` entity defined in Section 9 is retired. The `PerformanceSnapshot` becomes the single authoritative store for club performance data across the entire system.

**Sections requiring update:**

- Section 4 (§4.4) — target distance resolution reads from the Primary PerformanceSnapshot instead of ClubPerformanceProfile
- Section 6 — ClubPerformanceProfile entity is removed; PerformanceSnapshot entity is added
- Section 9 — bag setup flow updated to reflect that carry distances are no longer entered into ClubPerformanceProfile directly; they are populated via snapshot creation
- Section 16 — the time-versioned insert-on-update model for ClubPerformanceProfile no longer applies; versioning is handled through the snapshot lifecycle (Active / Retired / Primary designation)

All references to `ClubPerformanceProfile` across the specification set are superseded by `PerformanceSnapshot`.

---

### X.18.2 Calendar Slot Schema Extended with MatrixType

The existing Slot schema stores a `DrillID` to identify planned content. Matrix Slots cannot reference a DrillID. The Slot schema is extended with a `MatrixType` nullable enum field.

**Updated Slot schema:**

```
Slot
 ├── DrillID                  (nullable — populated for Drill Slots)
 ├── MatrixType               (nullable, enum: GappingChart | WedgeMatrix | ChippingMatrix)
 ├── OwnerType
 ├── OwnerID
 ├── CompletionState
 ├── CompletingSessionID      (nullable — for Drill Slots)
 ├── CompletingMatrixRunID    (nullable — for Matrix Slots)
 └── Planned (boolean)
```

**Integrity rule:** exactly one of `DrillID` or `MatrixType` must be populated per Slot. A Slot cannot be both a Drill Slot and a Matrix Slot simultaneously.

**Sections requiring update:**

- Section 6 (§6.2) — CalendarDay Slot schema updated
- Section 8 (§8.1.1) — Slot model description updated
- Section 16 — Slot JSON column schema updated

---

### X.18.3 Matrix Completion Matching on MatrixRun Completion

The existing completion matching mechanism monitors closed Sessions and matches their `DrillID` against CalendarDay Slot `DrillID` values. Matrix Slots require an equivalent mechanism.

When a MatrixRun is completed, the system checks the CalendarDay (based on the MatrixRun's CompletionTimestamp in the user's home timezone) for an incomplete Slot with a matching `MatrixType`. The first matching incomplete Slot is marked complete and the `CompletingMatrixRunID` is stored on that Slot.

Matching behaviour mirrors the existing Session-based model exactly:

```
MatrixRun completed
      ↓
Resolve CalendarDay from CompletionTimestamp (user's home timezone)
      ↓
Find first incomplete Slot on that day with matching MatrixType
      ↓
Slot CompletionState → CompletedLinked
      ↓
CompletingMatrixRunID stored on Slot
```

If no matching incomplete Slot exists and no empty Slot exists, completion overflow applies in the same way as for Drill completions (Section 8, §8.3.3). The overflow Slot stores the `MatrixType` and is flagged as `Planned = false`.

**Sections requiring update:**

- Section 8 (§8.3.2) — completion matching rules extended to cover MatrixRun completion
- Section 8 (§8.3.3) — completion overflow rules extended to cover Matrix Slots
- Section 6 (§6.2) — CalendarDay Slot schema updated with CompletingMatrixRunID field

---

End of Section 1 — Matrix & Gapping System Architecture (1v.a6 Draft)

---

# ZX Golf App — Matrix & Gapping System
# Section 2 — Matrix & Gapping Homepage

**Version:** 2v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview

---

## 2.1 Overview

The Matrix & Gapping Homepage is the primary entry surface for all matrix-related workflows within the Track area of the ZX Golf App.

This section defines:

- The surface location within Track
- Homepage structure and primary sections
- Start Matrix UI and behaviour
- Active execution conflict rules
- Matrix History structure and behaviour
- Matrix Run Review page actions
- Run deletion rules

This section does not define the matrix execution workflow. Execution behaviour is defined in later sections.

---

## 2.2 Surface Location

Matrices are accessed from a dedicated top-level entry point within the Track tab.

```
Track
 ├── Drills
 └── Matrices & Gapping
```

This structure preserves the conceptual separation established in Section 1:

| Section | Purpose |
|---|---|
| Drills | Training |
| Matrices & Gapping | Measurement / Calibration |

---

## 2.3 Homepage Structure

The Matrices & Gapping homepage contains two primary sections.

```
Matrices & Gapping

1. Start Matrix
2. Matrix History
```

There is no "In Progress" section on the homepage. Incomplete matrix runs are surfaced via the global floating resume control. See Section 2.5.

---

## 2.4 Start Matrix

### 2.4.1 Layout

The Start Matrix section uses a card-based layout.

Each matrix type is presented as a distinct card with:

- Matrix type name
- Short description of the workflow's purpose

**Example:**

```
Start Matrix

┌─────────────────────────────────────┐
│ Gapping Chart                       │
│ Measure full carry distances for    │
│ clubs in your bag.                  │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Wedge Matrix                        │
│ Measure partial wedge distances by  │
│ swing length.                       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Chipping Matrix                     │
│ Measure short-game distance control │
│ by club and target distance.        │
└─────────────────────────────────────┘
```

### 2.4.2 Disabled State

If an active execution object exists (either a `PracticeBlock` or a `MatrixRun`), the Start Matrix cards are rendered in a visually disabled state.

Explanatory text is displayed beneath the section header.

**Example — Active MatrixRun:**

```
Start Matrix
A matrix run is currently active.

[Gapping Chart — disabled]
[Wedge Matrix — disabled]
[Chipping Matrix — disabled]
```

**Example — Active PracticeBlock:**

```
Start Matrix
A practice session is currently active.

[Gapping Chart — disabled]
[Wedge Matrix — disabled]
[Chipping Matrix — disabled]
```

The floating resume control remains visible at the bottom of the screen in both cases. See Section 2.5.

---

## 2.5 Active Execution Model

### 2.5.1 Mutual Exclusivity

The system enforces strict mutual exclusivity between practice sessions and matrix runs.

Only one active execution object may exist at any time.

```
ActiveExecution
 ├── PracticeBlock
 └── MatrixRun

Constraint: ActiveExecutionCount ≤ 1
```

| Active Execution | Effect on Matrices | Effect on Drills |
|---|---|---|
| `MatrixRun` | Start Matrix cards disabled | Start Practice controls disabled |
| `PracticeBlock` | Start Matrix cards disabled | — |

### 2.5.2 Floating Resume Control

When a `MatrixRun` is active, a persistent floating resume control is displayed across the application.

**Example:**

```
┌──────────────────────────────────────┐
│ Active Matrix                        │
│ Wedge Matrix — In Progress   Resume  │
└──────────────────────────────────────┘
```

This control:

- Appears on all pages while a `MatrixRun` is active
- Behaves identically to the existing active `PracticeBlock` resume control
- Is the primary mechanism for communicating an active run to the user
- Navigates the user directly into the active matrix run on tap

### 2.5.3 Starting a MatrixRun

When the user taps a Start Matrix card and no active execution exists:

```
User taps matrix card
       ↓
User completes setup screen
       ↓
MatrixRun created (Status: InProgress)
       ↓
ActiveExecution = MatrixRun (new)
       ↓
Floating resume control appears
       ↓
User enters matrix execution workflow
```

> **Note:** The `MatrixRun` is not created on card tap. A user who taps a card and then abandons the setup screen without confirming does not produce an `InProgress` run. Run creation occurs only on confirmed setup completion.

---

## 2.6 Matrix History

### 2.6.1 Organisation

The Matrix History section displays all completed `MatrixRun` records.

Runs are grouped by matrix type. Within each group, runs are ordered most recent first.

**Example:**

```
Matrix History

Gapping Chart
 ├── Run #14 — 2026-09-10
 ├── Run #9  — 2026-06-15
 └── Run #3  — 2026-03-01

Wedge Matrix
 ├── Run #13 — 2026-05-01
 └── Run #6  — 2026-02-10

Chipping Matrix
 └── Run #2  — 2026-01-20
```

### 2.6.2 Run Identifier

Each `MatrixRun` is identified by a sequential run number and the run date.

**Format:**

```
Run #[N] — YYYY-MM-DD
```

The run number (`#N`) is a globally sequential integer assigned at run creation. It is unique across all matrix types and does not reset per matrix type.

This format unambiguously identifies runs regardless of whether multiple runs of the same matrix type occur on the same day.

### 2.6.3 History Row Content

History rows display the run identifier only.

```
Run #14 — 2026-09-10
```

No additional metadata (attempts, duration, clubs) is shown in the history list.

All detailed information is available on the Matrix Run Review page, accessed by tapping a row.

### 2.6.4 History Depth

All completed runs are displayed. No pruning, archiving, or visibility limit is applied.

```
History Depth: Unlimited
```

Rationale: Matrices represent calibration datasets. Preserving the full historical sequence supports seasonal recalibration analysis, equipment change tracking, and longitudinal performance review.

Pagination or lazy loading may be applied at the implementation level if required. No logical limit exists in the specification.

---

## 2.7 Matrix Run Review Page

### 2.7.1 Navigation

Tapping a run row in Matrix History navigates to the Matrix Run Review page for that run.

```
Matrix History row tapped
       ↓
Matrix Run Review page
```

### 2.7.2 Page Content

The Matrix Run Review page displays the complete record of the selected `MatrixRun`, including:

- Run identifier (`Run #N — YYYY-MM-DD`)
- Matrix type
- Full measurement grid
- Calculated averages per cell
- Dispersion metrics (if captured during the run)
- Run duration
- Timestamp

### 2.7.3 Available Actions

The following actions are available on the Matrix Run Review page.

| Action | Description |
|---|---|
| View Results | Default state of the page. Displays the full matrix dataset. |
| Edit Attempts | Opens attempt-level editing for the run. See Section 2.7.4. |
| Create Performance Snapshot | Navigation link to the Snapshot creation flow. See Section 2.7.5. |
| Discard Run | Permanently deletes the run. See Section 2.7.6. |

### 2.7.4 Edit Attempts

Users may edit any recorded attempt within the run.

Editable fields per attempt:

- Measured distance
- Dispersion values (if captured)
- Club selection (if mislogged)

Editing triggers the recalculation cascade:

```
MatrixAttempt edited
       ↓
MatrixCell recalculated
       ↓
MatrixRun aggregates updated
       ↓
Derived snapshot values updated
```

### 2.7.5 Create Performance Snapshot

The Matrix Run Review page contains a navigation link to the Snapshot creation flow.

**Example:**

```
Create Performance Snapshot →
```

This navigates to the Snapshot creation page defined in Section 1.13.

On the Snapshot creation page, the user selects a pre-population source:

```
Pre-populate from:
○ Derived
○ Last Session
```

If the user selects **Last Session**, the currently viewed `MatrixRun` becomes the source dataset.

The Matrix Run Review page does not contain an inline "Create Snapshot" action. Snapshot creation is handled entirely within the Snapshot creation flow.

### 2.7.6 Discard Run

A `MatrixRun` may be permanently deleted via the Discard Run action.

**Confirmation:**

A confirmation dialog is presented before deletion proceeds.

```
Discard this run?
This cannot be undone.

[Cancel]   [Discard]
```

**On confirmation, the following records are permanently deleted:**

- `MatrixRun`
- All associated `MatrixCell` records
- All associated `MatrixAttempt` records

**Integrity Constraint:**

If the run has previously contributed to a `PerformanceSnapshot`, deleting the run does not modify or invalidate the snapshot.

```
Discard MatrixRun
       ↓
MatrixRun deleted
MatrixCells deleted
MatrixAttempts deleted
       ↓
PerformanceSnapshot: unchanged
```

Snapshots are treated as authoritative historical records once saved and are not dependent on the continued existence of their source run.

---

## 2.8 Decision Log

| # | Decision |
|---|---|
| 2.1 | Track tab contains `Drills` and `Matrices & Gapping` as top-level entries |
| 2.2 | Matrix homepage contains two sections: Start Matrix and Matrix History |
| 2.3 | Incomplete runs are surfaced via the global floating resume control only |
| 2.4 | Only one active execution (`PracticeBlock` or `MatrixRun`) may exist at any time |
| 2.5 | Start Matrix uses a card-based layout with description text per matrix type |
| 2.6 | Start Matrix cards are shown in a disabled state with explanatory text when an active execution exists |
| 2.7 | Matrix History is grouped by matrix type, ordered most recent first |
| 2.8 | History rows display run identifier only (`Run #N — YYYY-MM-DD`) |
| 2.9 | All completed runs are displayed; no history depth limit |
| 2.10 | Matrix Run Review page supports: View Results, Edit Attempts, Snapshot link, Discard Run |
| 2.11 | Discard Run requires a simple confirmation dialog before proceeding |
| 2.12 | Discarding a run does not modify or invalidate associated PerformanceSnapshots |

---

*End of Section 2 — Matrix & Gapping Homepage*

---

# ZX Golf App — Matrix & Gapping System
# Section 3 — Gapping Chart Workflow

**Version:** 3v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage

---

## 3.1 Overview

This section defines the full workflow for the Gapping Chart matrix type, from session setup through to completion.

The Gapping Chart is a single-axis matrix structured by club. Each selected club produces a `MatrixCell` containing one or more `MatrixAttempt` records capturing distance and optional dispersion data.

This section defines:

- Session setup screen
- Club selection model
- Session configuration options
- Environment metadata
- Attempt entry model
- Shot order behaviour
- Progress indicators
- Session completion rules
- Mid-session editing and club removal

---

## 3.2 Session Setup Screen

Before a Gapping Chart run begins, the user configures the session on a dedicated setup screen.

The setup screen is divided into four sections.

```
Gapping Chart Setup

1. Select Clubs
2. Session Shot Target
3. Session Options
4. Environment & Measurement

[ Start Gapping Session ]
```

---

## 3.3 Club Selection

### 3.3.1 Selection Model

The user manually selects which clubs from their current bag will participate in the session.

**Example:**

```
Select Clubs

☑ LW
☑ SW
☑ PW
☑ 9i
☑ 8i
☑ 7i
☐ 6i
☐ 5i
☐ 4i
☐ 3W
☐ Driver
```

The user may select any subset of their current bag. There is no requirement to include all clubs.

### 3.3.2 Resulting Matrix Structure

The system creates one `MatrixCell` per selected club at run creation.

**Example (selected clubs: 7i, 8i, 9i, PW):**

```
MatrixCells created:
 ├── 7i
 ├── 8i
 ├── 9i
 └── PW
```

Each cell records `MatrixAttempt` records during the session.

### 3.3.3 Mid-Session Club Removal

The user may remove a club from the session at any time during an active run.

A removal control is accessible directly from the active club selector.

**Example:**

```
Current Club
[ 7i  ✕ ]
```

Tapping the ✕ removes the club from the session.

**Behaviour on removal:**

- The `MatrixCell` for that club is soft-excluded (`ExcludedFromRun = true`); no data is deleted
- All associated `MatrixAttempt` records are retained in the database
- The cell and its attempts are hidden from the session UI and excluded from completion validation, progress tracking, and analytics
- The session advances to the next club in the current order

Club removal is also available as part of the completion flow if an under-minimum club is detected. See Section 3.8.

---

## 3.4 Session Shot Target

### 3.4.1 Definition

Each Gapping Chart run includes a Session Shot Target defining the intended number of attempts per club for the session.

**Example:**

```
Session Shot Target
Shots per club: [ 5 ]
```

This target applies uniformly to all selected clubs.

### 3.4.2 Default Value

The Session Shot Target defaults to **5** shots per club.

### 3.4.3 Validation Rule

The session target must satisfy the hard minimum attempt rule.

```
SessionShotTarget ≥ 3
```

Values below 3 are rejected.

| Input | Result |
|---|---|
| 2 | Invalid — blocked |
| 3 | Valid |
| 5 | Valid (default) |

### 3.4.4 Role of the Target

The Session Shot Target serves two purposes:

- **Progress tracking** — The progress indicator for each club is measured against the session target
- **Practice guidance** — The target provides a suggested number of shots for a reliable dataset

The target does not affect session completion eligibility. Completion is governed by the hard minimum rule. See Section 3.8.

---

## 3.5 Session Options

### 3.5.1 Dispersion Capture

Users choose whether the session captures lateral dispersion data.

**Example:**

```
Capture Dispersion
○ Enabled
○ Disabled
```

**If enabled**, the attempt entry screen displays four measurement fields:

```
Carry Distance
Total Distance
Left Deviation
Right Deviation
```

**If disabled**, the attempt entry screen displays distance fields only:

```
Carry Distance
Total Distance
```

### 3.5.2 Club Order

Defines the default club progression sequence during the session.

**Example:**

```
Club Order
○ Low → High
○ High → Low
○ Random
```

| Option | Description | Example sequence |
|---|---|---|
| Low → High | Shortest to longest club | LW, SW, PW, 9i, 8i, 7i, ... |
| High → Low | Longest to shortest club | Driver, 3W, 5i, 6i, 7i, ... |
| Random | System randomises at run start | 8i, Driver, PW, 7i, 3W, 9i |

**Random order behaviour:**

The randomised sequence is generated once when the run begins and remains fixed for the session duration.

If the user manually overrides the current club mid-session, the remaining randomised sequence is preserved. On completing the overridden club, the system returns to the next club in the original randomised sequence.

```
Random sequence: [8i, PW, 7i, 9i]
User on 8i → manually switches to 7i
7i complete → system returns to PW (next in sequence)
```

---

## 3.6 Environment & Measurement

The setup screen includes an optional environment metadata section. All fields in this section are optional and may be left blank.

**Example:**

```
Environment & Measurement

Measurement Device
○ Launch Monitor
○ Range Estimation
○ GPS
○ Simulator
○ Other

Environment
○ Indoor
○ Outdoor

Surface
○ Grass
○ Mat
```

### 3.6.1 Storage

These values are stored as metadata on the `MatrixRun` record.

```
MatrixRun
 ├── MatrixType
 ├── StartTimestamp
 ├── EndTimestamp
 ├── SessionShotTarget
 ├── MeasurementDevice       (nullable)
 ├── EnvironmentType         (nullable)
 ├── SurfaceType             (nullable)
 └── MatrixCells
```

### 3.6.2 Purpose

Session environment metadata supports:

- Filtering of historical runs
- Identification of measurement reliability differences
- Grass vs mat carry distance analysis
- Indoor vs outdoor dataset segmentation

---

## 3.7 Attempt Entry

### 3.7.1 Distance Units

All distance and deviation fields use the user's global distance unit setting (Yards or Meters).

Units are not configurable per run.

All values are stored internally in the canonical unit (meters), with UI conversion applied at the display layer.

```
MatrixAttempt
 ├── CarryDistanceMeters      (nullable)
 ├── TotalDistanceMeters      (nullable)
 ├── LeftDeviationMeters      (nullable)
 ├── RightDeviationMeters     (nullable)
 └── AttemptTimestamp
```

### 3.7.2 Measurement Fields

Each attempt may record up to four measurement values depending on the session's dispersion capture setting.

| Field | Dispersion On | Dispersion Off |
|---|---|---|
| Carry Distance | Available | Available |
| Total Distance | Available | Available |
| Left Deviation | Available | Hidden |
| Right Deviation | Available | Hidden |

### 3.7.3 Attempt Validity Rule

To record a shot attempt, at least one measurement field must be populated.

```
AttemptValid =
  CarryDistance IS NOT NULL
  OR TotalDistance IS NOT NULL
  OR LeftDeviation IS NOT NULL
  OR RightDeviation IS NOT NULL
```

If all fields are empty, the Add Shot action is disabled.

### 3.7.4 Deviation Model

Lateral dispersion is captured using directional deviation values. Only one deviation field should normally be populated for a given attempt.

**Example:**

```
Shot landed 5y left of target
LeftDeviation = 5
RightDeviation = null
```

### 3.7.5 Add Shot Action

Each shot is recorded using an explicit **Add Shot** action.

**Example interface:**

```
Carry Distance:   [ 164 ]
Total Distance:   [ 171 ]
Left Deviation:   [     ]
Right Deviation:  [     ]

[ Add Shot ]
```

**Behaviour on Add Shot:**

```
User enters values
       ↓
Tap Add Shot
       ↓
MatrixAttempt created
       ↓
Attempt list updates
       ↓
Entry fields clear for next shot
```

### 3.7.6 Dual Submission Buttons

Before the minimum attempt count is reached, a single **Add Shot** button is displayed.

Once the user is entering the third attempt for a club (i.e. `AttemptCount = 2` when beginning the entry), the submission controls change to two options.

**Example:**

```
Carry Distance:   [ 166 ]
Total Distance:   [ 173 ]
Left Deviation:   [     ]
Right Deviation:  [     ]

[ Add Shot – Same Club ]   [ Add Shot – Next Club ]
```

| Action | Behaviour |
|---|---|
| Add Shot – Same Club | Records the attempt and keeps the user on the current club |
| Add Shot – Next Club | Records the attempt and advances to the next club in the session sequence |

**Add Shot – Next Club sequence:**

```
8i Attempt 3 entered
       ↓
Add Shot – Next Club
       ↓
Attempt recorded
       ↓
System advances to next club (e.g. 7i)
```

---

## 3.8 Shot Order and Club Navigation

### 3.8.1 Default Progression

The session progresses through clubs in the order defined by the Club Order setting on the setup screen (Low → High, High → Low, or Random). See Section 3.5.2.

### 3.8.2 Manual Override

At any point during the session, the user may switch to a different club manually using the club selector.

**Example:**

```
Current Club
[ 7i  ✕ ▼ ]
```

Selecting a different club from the dropdown immediately navigates to that club's `MatrixCell`.

After completing the overridden club, the system returns to the next club in the original session sequence (including for Random order).

---

## 3.9 Progress Indicators

### 3.9.1 Per-Club Progress Bar

Each club displays a progress bar showing attempts recorded against the Session Shot Target.

**Example (target = 5):**

```
7i
[■■■□□]
3 / 5 shots
```

**At target:**

```
7i
[■■■■■]
5 / 5 shots
```

**Beyond target:**

```
7i
[■■■■■■]
6 / 5 shots
```

The bar extends visually beyond the target to indicate additional attempts.

### 3.9.2 Club List Completion Indicator

The club list overview shows a checkmark next to any club that has reached the hard minimum (3 attempts), regardless of whether the session target has been met.

**Example:**

```
Club List

LW  ✓
SW  ✓
PW  ✓
9i
8i
7i
```

A checkmark indicates:

```
AttemptCount ≥ 3
```

---

## 3.10 Attempt Editing During a Run

While a Gapping Chart run is active, the user may edit or delete any previously recorded attempt.

**Editable fields:**

- Carry Distance
- Total Distance
- Left Deviation
- Right Deviation

**Editing behaviour:**

```
MatrixAttempt edited
       ↓
MatrixCell aggregates recalculated
```

Attempt timestamps are not modified on edit. Attempts remain ordered chronologically by their original `AttemptTimestamp`.

**Deletion during run:**

An attempt may be deleted while the run is active. If deletion reduces the attempt count below the hard minimum, the club becomes ineligible for session completion until a further attempt is recorded.

```
AttemptCount < 3
→ Club ineligible for completion
```

---

## 3.11 Session Completion

### 3.11.1 Completion Rule

A Gapping Chart run may only be completed when all selected clubs satisfy the hard minimum attempt rule.

```
∀ Club ∈ SelectedClubs
AttemptCount ≥ 3
```

The **Finish Session** action is disabled until this condition is met for all clubs.

### 3.11.2 Handling Under-Minimum Clubs

If the user attempts to finish the session and one or more clubs have fewer than 3 attempts, the system surfaces the issue and presents two options per affected club:

- **Record additional attempts** — Keep the club in the session and continue logging
- **Remove club from session** — Exclude the club from the final dataset

**Example:**

```
Session cannot be completed

9i — 2 shots
  [ Continue recording ]   [ Remove club ]
```

Removing the club soft-excludes its `MatrixCell` (`ExcludedFromRun = true`). All associated `MatrixAttempt` records are retained in the database but the cell is removed from completion validation and hidden from the session UI.

### 3.11.3 On Completion

When the session is completed:

```
Finish Session confirmed
       ↓
MatrixRun.Status = Completed
MatrixRun.EndTimestamp = now
       ↓
Final aggregates calculated per MatrixCell
       ↓
MatrixRun available in Matrix History
       ↓
ActiveExecution cleared
       ↓
Floating resume control dismissed
```

---

## 3.12 Data Model Summary

```
MatrixRun (Gapping Chart)
 ├── RunNumber               (sequential, globally unique)
 ├── MatrixType              = GappingChart
 ├── Status                  (InProgress | Completed)
 ├── StartTimestamp
 ├── EndTimestamp            (nullable)
 ├── SessionShotTarget
 ├── DisperionCaptureEnabled (boolean)
 ├── ClubOrder               (LowToHigh | HighToLow | Random)
 ├── MeasurementDevice       (nullable)
 ├── EnvironmentType         (nullable)
 ├── SurfaceType             (nullable)
 └── MatrixCells[]
        └── MatrixCell
             ├── ClubID
             └── MatrixAttempts[]
                    └── MatrixAttempt
                         ├── CarryDistanceMeters      (nullable)
                         ├── TotalDistanceMeters      (nullable)
                         ├── LeftDeviationMeters      (nullable)
                         ├── RightDeviationMeters     (nullable)
                         └── AttemptTimestamp
```

---

## 3.13 Decision Log

| # | Decision |
|---|---|
| 3.1 | Club selection is manual per session; any subset of the current bag may be selected |
| 3.2 | Minimum attempts per club = 3 (hard minimum, system enforced) |
| 3.3 | Session Shot Target defaults to 5; must be ≥ 3 |
| 3.4 | Progress indicators track against Session Shot Target, not the hard minimum |
| 3.5 | Club completion checkmark triggers at AttemptCount ≥ 3 |
| 3.6 | Attempt entry uses Add Shot explicit action model |
| 3.7 | After minimum is reached, dual submission buttons appear: Add Shot – Same Club / Add Shot – Next Club |
| 3.8 | Distance entry is manual only (V1); no launch monitor integration |
| 3.9 | Each attempt records up to four fields: Carry, Total, Left Deviation, Right Deviation |
| 3.10 | At least one field must be populated for an attempt to be valid |
| 3.11 | Dispersion fields are shown/hidden via a setup screen toggle |
| 3.12 | Club order options: Low → High, High → Low, Random |
| 3.13 | Random order is fixed at run start; manual overrides temporarily diverge then return to the randomised sequence |
| 3.14 | Clubs may be removed at any time via the ✕ control on the club selector |
| 3.15 | Environment & Measurement fields (Device, Indoor/Outdoor, Surface) are optional session metadata |
| 3.16 | All distance values stored in meters internally; UI applies unit conversion |
| 3.17 | Attempts are editable and deletable during an active run |
| 3.18 | Under-minimum clubs must be completed or removed before the session can be finished |

---

*End of Section 3 — Gapping Chart Workflow*

---

# ZX Golf App — Matrix & Gapping System
# Section 4 — Wedge Matrix Workflow

**Version:** 4v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow

---

## 4.1 Overview

This section defines the full workflow for the Wedge Matrix matrix type, from session setup through to completion.

The Wedge Matrix is a multi-axis matrix structured by user-defined checkpoints across up to three axes: Club, Axis A (e.g. Effort), and Axis B (e.g. Flight). Each unique combination of axis values produces a `MatrixCell` containing one or more `MatrixAttempt` records.

This section defines:

- Axis model and optional axis behaviour
- Session setup screen
- Club selection
- Checkpoint definition and templates
- Axis naming
- Session shot estimation
- Picklist navigation and ordering
- Attempt entry model
- Progress indicators
- Session completion rules
- Mid-session editing and cell removal

---

## 4.2 Matrix Axis Model

### 4.2.1 Axis Structure

The Wedge Matrix supports up to three axes.

```
Club × Axis A × Axis B
```

Each axis is user-defined. The labels "Axis A" and "Axis B" are placeholders — the user assigns custom names to each axis. See Section 4.4.

### 4.2.2 Axis Requirements

Only the Club axis is required. Axis A and Axis B are both optional.

| Configuration | Matrix Structure | Example |
|---|---|---|
| Club only | Club × (100% effort assumed) | 56° — Full effort |
| Club + Axis A | Club × Axis A | 56° × 70% |
| Club + Axis B only | Club × Axis B | 56° × Low |
| Club + Axis A + Axis B | Club × Axis A × Axis B | 56° × 70% × Low |

**Fallback rule:**

If neither Axis A nor Axis B is defined, the session is treated as a full-effort capture equivalent to a single-checkpoint gapping session.

```
No axes defined
       ↓
Matrix = Club only
       ↓
Each club = one MatrixCell at implied full effort
```

### 4.2.3 Measurement Unit

Each unique combination of axis values constitutes one measurement unit and maps to one `MatrixCell`.

```
MeasurementUnit = Club [× Axis A value] [× Axis B value]
```

**Example (Club + Axis A + Axis B):**

```
Clubs:  52°, 56°, 60°
Axis A: 50%, 70%, 90%
Axis B: Low, Standard, High

Total cells: 3 × 3 × 3 = 27
```

**Example (Club + Axis A only):**

```
Clubs:  52°, 56°, 60°
Axis A: 50%, 70%, 90%

Total cells: 3 × 3 = 9
```

---

## 4.3 Session Setup Screen

Before a Wedge Matrix run begins, the user configures the session on a dedicated setup screen.

```
Wedge Matrix Setup

1. Select Clubs
2. Axis A  (optional)
   └── Axis Name
   └── Checkpoints
3. Axis B  (optional)
   └── Axis Name
   └── Checkpoints
4. Session Shot Target
5. Session Options
6. Environment & Measurement
7. Session Summary

[ Start Wedge Matrix ]
```

---

## 4.4 Axis Naming

Each axis has a user-editable name displayed throughout the session UI.

**Example:**

```
Axis A Name: [ Effort      ]
Axis B Name: [ Flight      ]
```

Users may rename axes to match their preferred system.

**Examples of valid naming:**

| Axis A | Axis B |
|---|---|
| Effort | Flight |
| Swing Length | Trajectory |
| Clock | Shape |
| Power | Height |

Axis names are stored on the `MatrixRun` and used as column/row labels throughout the session and review screens.

If an axis is left empty (no checkpoints defined), it is excluded from the session and its name field is hidden.

---

## 4.5 Club Selection

### 4.5.1 Selection Model

The user manually selects which clubs from their current bag will participate in the session.

**Example:**

```
Select Clubs

☑ 52°
☑ 56°
☑ 60°
☐ PW
☐ 9i
☐ 8i
```

Any subset of the current bag may be selected.

### 4.5.2 Mid-Session Club Removal

Clubs may be removed from the session at any time via the ✕ control on the club selector, consistent with the Gapping workflow.

```
Current Club
[ 56°  ✕ ▼ ]
```

Removing a club soft-excludes all `MatrixCell` records for that club across all axis combinations (`ExcludedFromRun = true`). All associated `MatrixAttempt` records are retained in the database but are hidden from the session UI and excluded from completion validation, progress tracking, and analytics.

---

## 4.6 Checkpoint Definition

### 4.6.1 User-Defined Checkpoints

Checkpoints are user-defined labels applied to each optional axis. They carry no intrinsic numeric meaning — the system treats them as identifiers only.

Users may define checkpoints by:

- Selecting a system template (see Section 4.6.2)
- Editing a template after selection
- Defining checkpoints fully from scratch

**Example (Effort axis):**

```
Effort Checkpoints

50%
70%
90%
[ + Add Checkpoint ]
```

**Example (Flight axis):**

```
Flight Checkpoints

Low
Standard
High
[ + Add Checkpoint ]
```

### 4.6.2 System Templates

The setup screen provides system-provided checkpoint templates to reduce setup friction.

**Axis A (Effort) Templates:**

| Template | Checkpoints |
|---|---|
| Clock | 7:30 / 9:00 / 10:30 |
| Effort % | 50% / 70% / 90% / 100% |
| Custom | User defined |

**Axis B (Flight) Templates:**

| Template | Checkpoints |
|---|---|
| Trajectory | Low / Standard / High |
| Expanded Trajectory | Low / Mid / High |
| Custom | User defined |

When a template is selected, its checkpoints are inserted into editable fields. The user may then rename, delete, or add checkpoints before starting the session.

### 4.6.3 Axis Limits

The following limits apply per axis.

```
Max Axis A Checkpoints = 10
Max Axis B Checkpoints = 10
```

### 4.6.4 Checkpoint Editing

Within the editable checkpoint list, users may:

- Rename any checkpoint
- Delete any checkpoint
- Add new checkpoints (up to the axis maximum)
- Reorder checkpoints

---

## 4.7 Session Shot Target

### 4.7.1 Definition

Each Wedge Matrix run includes a Session Shot Target defining the intended number of attempts per cell.

**Example:**

```
Session Shot Target
Shots per cell: [ 5 ]
```

### 4.7.2 Default and Validation

| Property | Value |
|---|---|
| Default | 5 |
| Minimum | 3 |

Values below 3 are rejected.

### 4.7.3 Role of the Target

The Session Shot Target governs progress indicators only. It does not affect session completion eligibility. Completion is governed by the hard minimum rule. See Section 4.10.

---

## 4.8 Session Summary

The setup screen displays a live Session Summary that updates dynamically as the user configures axes, clubs, and the shot target.

**Example:**

```
Session Summary

Clubs:               3
Axis A checkpoints:  3
Axis B checkpoints:  2
Target shots / cell: 5

Estimated shots:  90
Minimum shots:    54
```

**Formulae:**

```
EstimatedShots = Clubs × AxisACount × AxisBCount × SessionShotTarget
MinimumShots   = Clubs × AxisACount × AxisBCount × 3
```

Where axes not defined contribute a factor of 1.

**Example (Club + Axis A only):**

```
EstimatedShots = 3 × 3 × 1 × 5 = 45
MinimumShots   = 3 × 3 × 1 × 3 = 27
```

---

## 4.9 Session Options and Environment Metadata

The Wedge Matrix setup screen includes the same Session Options and Environment & Measurement sections as the Gapping workflow.

### 4.9.1 Session Options

**Dispersion Capture:**

```
Capture Dispersion
○ Enabled
○ Disabled
```

Controls whether Left Deviation and Right Deviation fields appear during attempt entry.

**Shot Order:**

```
Shot Order
○ Top → Bottom
○ Bottom → Top
○ Random
```

Applies to the ordering of measurement units in the picklist. See Section 4.9.2.

### 4.9.2 Shot Order Behaviour

| Mode | Behaviour |
|---|---|
| Top → Bottom | Picklist entries ordered by generated matrix sequence |
| Bottom → Top | Reverse of the generated matrix sequence |
| Random | Entries randomised once at session start; order fixed for run duration |

**Random order override:**

If the user manually selects a different measurement unit mid-session, the remaining randomised sequence is preserved. On completing the manually selected cell, the system returns to the next entry in the original randomised sequence.

### 4.9.3 Environment & Measurement

All fields are optional.

```
Environment & Measurement

Measurement Device
○ Launch Monitor
○ Range Estimation
○ GPS
○ Simulator
○ Other

Environment
○ Indoor
○ Outdoor

Surface
○ Grass
○ Mat
```

---

## 4.10 Picklist Navigation

### 4.10.1 Structure

During the session, measurement units are presented in a grouped picklist selector.

Entries are grouped by club. Within each club group, entries are ordered according to the Shot Order setting.

**Example (3 clubs, Effort + Flight axes):**

```
Select Shot

52°
 ├── 52° — 50% — Low
 ├── 52° — 50% — Standard
 ├── 52° — 70% — Low
 └── 52° — 70% — Standard

56°
 ├── 56° — 50% — Low
 ├── 56° — 50% — Standard
 ├── 56° — 70% — Low
 └── 56° — 70% — Standard

60°
 ├── 60° — 50% — Low
 └── ...
```

### 4.10.2 Cell Status in Picklist

Cells that have reached the hard minimum (3 attempts) display a completion checkmark.

**Example:**

```
52°
 ├── 52° — 50% — Low       ✓
 ├── 52° — 50% — Standard  ✓
 ├── 52° — 70% — Low
 └── 52° — 70% — Standard
```

### 4.10.3 Manual Override

The user may select any measurement unit from the picklist at any time, overriding the automatic session order.

---

## 4.11 Attempt Entry

### 4.11.1 Distance Units

All distance and deviation fields use the user's global distance unit setting. Units are not configurable per run.

All values are stored internally in the canonical unit (meters), with UI conversion at the display layer.

### 4.11.2 Measurement Fields

| Field | Dispersion On | Dispersion Off |
|---|---|---|
| Carry Distance | Available | Available |
| Total Distance | Available | Available |
| Left Deviation | Available | Hidden |
| Right Deviation | Available | Hidden |

### 4.11.3 Attempt Validity Rule

At least one measurement field must be populated to record an attempt.

```
AttemptValid =
  CarryDistance IS NOT NULL
  OR TotalDistance IS NOT NULL
  OR LeftDeviation IS NOT NULL
  OR RightDeviation IS NOT NULL
```

### 4.11.4 Add Shot Action

Each shot is recorded using an explicit **Add Shot** action, consistent with the Gapping workflow.

**Before minimum attempts reached:**

```
Carry Distance:   [ 98  ]
Total Distance:   [     ]
Left Deviation:   [     ]
Right Deviation:  [     ]

[ Add Shot ]
```

**Once minimum is reached (AttemptCount = 2 when beginning entry):**

```
Carry Distance:   [ 101 ]
Total Distance:   [     ]
Left Deviation:   [     ]
Right Deviation:  [     ]

[ Add Shot – Same Cell ]   [ Add Shot – Next Cell ]
```

| Action | Behaviour |
|---|---|
| Add Shot – Same Cell | Records the attempt and keeps the user on the current cell |
| Add Shot – Next Cell | Records the attempt and advances to the next entry in the picklist |

---

## 4.12 Progress Indicators

### 4.12.1 Per-Cell Progress Bar

Each cell displays a progress bar against the session shot target.

**Example (target = 5):**

```
56° — 70% — Low
[■■■□□]
3 / 5 shots
```

**At target:**

```
[■■■■■] ✓
5 / 5 shots
```

**Beyond target:**

```
[■■■■■■]
6 / 5 shots
```

### 4.12.2 Picklist Completion Checkmark

A checkmark appears next to any cell where `AttemptCount ≥ 3`, regardless of whether the session target has been met.

---

## 4.13 Attempt Editing During a Run

While a Wedge Matrix run is active, the user may edit or delete any previously recorded attempt on any cell.

**Editable fields:**

- Carry Distance
- Total Distance
- Left Deviation
- Right Deviation

Attempt timestamps are not modified on edit.

Deletion during a run is permitted. If deletion reduces a cell's attempt count below 3, that cell becomes ineligible for session completion until a further attempt is recorded.

---

## 4.14 Session Completion

### 4.14.1 Completion Rule

A Wedge Matrix run may only be completed when all measurement units satisfy the hard minimum.

```
∀ MeasurementUnit ∈ Session
AttemptCount ≥ 3
```

### 4.14.2 Handling Under-Minimum Cells

If the user attempts to finish the session and one or more cells have fewer than 3 attempts, the system surfaces the issue per affected cell.

**Example:**

```
Session cannot be completed

52° — 70% — High — 2 shots
  [ Continue recording ]   [ Remove cell ]
```

Removing a cell soft-excludes it (`ExcludedFromRun = true`). All associated `MatrixAttempt` records are retained in the database but the cell is removed from completion validation and hidden from the session UI.

```
Finish Session confirmed
       ↓
MatrixRun.Status = Completed
MatrixRun.EndTimestamp = now
       ↓
Final aggregates calculated per MatrixCell
       ↓
MatrixRun available in Matrix History
       ↓
ActiveExecution cleared
       ↓
Floating resume control dismissed
```

---

## 4.15 Data Model

The Wedge Matrix does not use a flat, type-specific data model. It is implemented using the generic runtime model defined in Section 6 and the canonical entity schema defined in Section 8.

The Wedge Matrix is configured as follows within that model:

- **MatrixType** = `WEDGE_MATRIX`
- **Axes:** Club (required), plus up to two optional user-named axes (e.g. Effort, Flight), each with user-defined `MatrixAxisValue` records
- **Dispersion fields:** `LeftDeviationMeters` and `RightDeviationMeters` are available on `MatrixAttempt` when dispersion capture is enabled
- **Fields not used:** `RolloutDistanceMeters`, `GreenSpeed`, `GreenFirmness`

Refer to Section 6.11 (Full Data Model) and Section 8.9 (Full Schema Reference) for the authoritative entity definitions.

---

## 4.16 Decision Log

| # | Decision |
|---|---|
| 4.1 | Wedge Matrix supports up to three axes: Club, Axis A, Axis B |
| 4.2 | Only Club is required; Axis A and Axis B are both optional |
| 4.3 | If no axes are defined, the session defaults to Club only at implied full effort |
| 4.4 | Axis A and Axis B names are user-editable |
| 4.5 | Each unique axis combination constitutes one MatrixCell (measurement unit) |
| 4.6 | Club selection is manual; any subset of the current bag may be selected |
| 4.7 | Clubs may be removed mid-session via the ✕ control on the club selector |
| 4.8 | Checkpoints are user-defined labels; templates provided for Effort and Flight axes |
| 4.9 | Max checkpoints per axis = 10 |
| 4.10 | Session Shot Target defaults to 5; must be ≥ 3 |
| 4.11 | Setup screen displays live Estimated Shots and Minimum Shots summary |
| 4.12 | Picklist navigation used; entries grouped by club |
| 4.13 | Shot order options: Top → Bottom, Bottom → Top, Random |
| 4.14 | Random order fixed at session start; manual overrides return to the randomised sequence |
| 4.15 | Dual submission buttons (Same Cell / Next Cell) appear once minimum is reached |
| 4.16 | Progress bars track against session target; checkmarks appear at AttemptCount ≥ 3 |
| 4.17 | Attempts are editable and deletable during an active run |
| 4.18 | Under-minimum cells must be completed or removed before the session can be finished |
| 4.19 | Environment & Measurement fields are optional session metadata |
| 4.20 | All distance values stored in meters internally; UI applies unit conversion |
| 4.21 | Wedge Matrix data model defers to the canonical runtime model in Sections 6 and 8; Section 4.15 contains a configuration summary only |

---

*End of Section 4 — Wedge Matrix Workflow*

---

# ZX Golf App — Matrix & Gapping System
# Section 5 — Chipping Matrix Workflow

**Version:** 5v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow, Section 4 — Wedge Matrix Workflow

---

## 5.1 Overview

This section defines the full workflow for the Chipping Matrix matrix type, from session setup through to completion.

The Chipping Matrix reuses the Wedge Matrix multi-axis engine, substituting a Carry Distance axis for the Effort axis. The resulting matrix structure is:

```
Club × Carry Distance × Flight
```

Key differences from the Wedge Matrix:

- Carry Distance axis replaces Effort axis
- No lateral dispersion capture (Left/Right Deviation fields are absent)
- Green condition metadata replaces dispersion session options
- Carry distance checkpoints are unlimited in number

This section defines:

- Axis model and optional axis behaviour
- Session setup screen
- Club selection
- Carry distance and flight checkpoint definition
- Axis naming
- Green condition metadata
- Session shot estimation
- Picklist navigation and ordering
- Attempt entry model
- Progress indicators
- Session completion rules

---

## 5.2 Matrix Axis Model

### 5.2.1 Axis Structure

The Chipping Matrix supports up to three axes.

```
Club × Axis A (Carry Distance) × Axis B (Flight)
```

Both Axis A and Axis B are optional, consistent with the Wedge Matrix engine.

| Configuration | Matrix Structure | Example |
|---|---|---|
| Club only | Club × (implied full effort) | SW — full effort |
| Club + Axis A | Club × Carry Distance | SW × 10y |
| Club + Axis B only | Club × Flight | SW × Standard |
| Club + Axis A + Axis B | Club × Carry Distance × Flight | SW × 10y × Standard |

**Fallback rule:**

If neither axis is defined, the session is treated as a club-only capture at implied full effort.

### 5.2.2 Axis Naming

Both axis labels are user-editable, consistent with the Wedge Matrix.

**Example:**

```
Axis A Name: [ Carry Distance ]
Axis B Name: [ Flight         ]
```

Users may rename axes to match their preferred terminology.

**Examples of valid naming:**

| Axis A | Axis B |
|---|---|
| Carry Distance | Flight |
| Landing Zone | Trajectory |
| Target | Height |

Axis names are stored on the `MatrixRun` and used as labels throughout the session and review screens.

### 5.2.3 Measurement Unit

Each unique combination of axis values constitutes one measurement unit and maps to one `MatrixCell`.

```
MeasurementUnit = Club [× Axis A value] [× Axis B value]
```

**Example (Club + Carry Distance + Flight):**

```
Clubs:           PW, SW, LW
Carry Distances: 5y, 10y, 15y, 20y
Flight:          Low, Standard, High

Total cells: 3 × 4 × 3 = 36
```

---

## 5.3 Session Setup Screen

Before a Chipping Matrix run begins, the user configures the session on a dedicated setup screen.

```
Chipping Matrix Setup

1. Select Clubs
2. Axis A — Carry Distance  (optional)
   └── Axis Name
   └── Checkpoints
3. Axis B — Flight  (optional)
   └── Axis Name
   └── Checkpoints
4. Session Shot Target
5. Shot Order
6. Environment & Measurement
7. Green Conditions
8. Session Summary

[ Start Chipping Matrix ]
```

---

## 5.4 Club Selection

### 5.4.1 Selection Model

The user manually selects which clubs from their current bag will participate in the session.

**Example:**

```
Select Clubs

☑ PW
☑ SW
☑ LW
☐ 9i
☐ 8i
```

Any subset of the current bag may be selected.

### 5.4.2 Mid-Session Club Removal

Clubs may be removed at any time via the ✕ control on the club selector.

```
Current Club
[ SW  ✕ ▼ ]
```

Removing a club soft-excludes all `MatrixCell` records for that club across all axis combinations (`ExcludedFromRun = true`). All associated `MatrixAttempt` records are retained in the database but are hidden from the session UI and excluded from completion validation, progress tracking, and analytics.

---

## 5.5 Carry Distance Checkpoints

### 5.5.1 User-Defined Distances

Carry distance checkpoints are fully user-defined. They represent the intended carry landing distance of each chip.

**Example:**

```
Carry Distance Checkpoints

5y
10y
15y
20y
[ + Add Distance ]
```

### 5.5.2 Default Template

The setup screen provides a default carry distance template to reduce setup friction.

**Default template:**

```
5y
10y
15y
20y
```

When the carry distance axis is activated, this template is pre-populated into editable fields. The user may rename, delete, reorder, or add distances freely.

### 5.5.3 Axis Limit

There is no maximum limit on the number of carry distance checkpoints. The Session Summary provides a live shot estimate to help the user gauge session size. See Section 5.8.

### 5.5.4 Distance Units

Carry distance checkpoint values follow the user's global distance unit setting (Yards or Meters). Units are not configurable per session.

---

## 5.6 Flight Checkpoints

The Flight axis behaves identically to the Wedge Matrix Flight axis.

### 5.6.1 User-Defined Checkpoints

Flight checkpoints are user-defined labels.

**Example:**

```
Flight Checkpoints

Low
Standard
High
[ + Add Checkpoint ]
```

### 5.6.2 System Templates

| Template | Checkpoints |
|---|---|
| Trajectory | Low / Standard / High |
| Expanded Trajectory | Low / Mid / High |
| Custom | User defined |

When a template is selected, checkpoints are inserted into editable fields for modification.

### 5.6.3 Axis Limit

```
Max Flight Checkpoints = 10
```

---

## 5.7 Session Shot Target

### 5.7.1 Definition

Each Chipping Matrix run includes a Session Shot Target defining the intended number of attempts per cell.

```
Session Shot Target
Shots per cell: [ 5 ]
```

### 5.7.2 Default and Validation

| Property | Value |
|---|---|
| Default | 5 |
| Minimum | 3 |

Values below 3 are rejected.

### 5.7.3 Shot Order

```
Shot Order
○ Top → Bottom
○ Bottom → Top
○ Random
```

Ordering applies to the picklist sequence. Random order is fixed at session start. Manual overrides temporarily diverge then return to the original sequence, consistent with the Wedge Matrix behaviour.

---

## 5.8 Session Summary

The setup screen displays a live Session Summary updating dynamically as configuration changes.

**Example:**

```
Session Summary

Clubs:                    3
Carry distance checkpoints: 4
Flight checkpoints:       3
Target shots / cell:      5

Estimated shots:  180
Minimum shots:    108
```

**Formulae:**

```
EstimatedShots = Clubs × CarryDistanceCount × FlightCount × SessionShotTarget
MinimumShots   = Clubs × CarryDistanceCount × FlightCount × 3
```

Where axes not defined contribute a factor of 1.

---

## 5.9 Environment & Measurement

All fields are optional.

```
Environment & Measurement

Measurement Device
○ Launch Monitor
○ Range Estimation
○ GPS
○ Simulator
○ Other

Environment
○ Indoor
○ Outdoor

Surface
○ Grass
○ Mat
```

---

## 5.10 Green Conditions

The Chipping Matrix setup screen includes a Green Conditions section for recording the practice surface characteristics.

All fields are optional.

```
Green Conditions

Green Speed (Stimpmeter)
[ ◀  9.0  ▶ ]
Range: 6.0 – 15.0, steps of 0.5

Green Firmness
○ Soft
○ Medium
○ Firm
```

### 5.10.1 Green Speed

Green speed is captured using a stepped selector.

| Property | Value |
|---|---|
| Range | 6.0 – 15.0 |
| Step | 0.5 |
| Default | None (optional field) |

**Example values:** 6.0, 6.5, 7.0, ... 14.5, 15.0

### 5.10.2 Green Firmness

Green firmness is captured using a three-option selector.

| Option | Description |
|---|---|
| Soft | Ball pitches and stops quickly |
| Medium | Typical conditions |
| Firm | Ball releases after landing |

### 5.10.3 Storage

Green condition values are stored as metadata on the `MatrixRun` and apply to all attempts within the session.

```
MatrixRun
 ├── GreenSpeed      (nullable, 6.0–15.0 in 0.5 steps)
 └── GreenFirmness   (nullable: Soft | Medium | Firm)
```

### 5.10.4 Purpose

Capturing green conditions enables future analysis such as:

- Carry vs rollout comparison across different green speeds
- Distance control variance between soft and firm conditions
- Indoor vs outdoor chipping dataset segmentation

---

## 5.11 Picklist Navigation

### 5.11.1 Structure

During the session, measurement units are presented in a grouped picklist selector.

Entries are grouped by club. Within each club group, entries are ordered according to the Shot Order setting.

**Example (3 clubs, Carry Distance + Flight axes):**

```
Select Shot

PW
 ├── PW — 5y  — Low
 ├── PW — 5y  — Standard
 ├── PW — 10y — Low
 └── PW — 10y — Standard

SW
 ├── SW — 5y  — Low
 ├── SW — 5y  — Standard
 ├── SW — 10y — Low
 └── SW — 10y — Standard

LW
 ├── LW — 5y  — Low
 └── ...
```

### 5.11.2 Cell Status in Picklist

Cells that have reached the hard minimum (3 attempts) display a completion checkmark.

**Example:**

```
SW
 ├── SW — 5y  — Low       ✓
 ├── SW — 5y  — Standard  ✓
 ├── SW — 10y — Low
 └── SW — 10y — Standard
```

### 5.11.3 Manual Override

The user may select any measurement unit from the picklist at any time, overriding the automatic session order.

---

## 5.12 Attempt Entry

### 5.12.1 Measurement Fields

Chipping attempts do not include lateral dispersion fields. Left Deviation and Right Deviation are not captured in the Chipping Matrix.

| Field | Available |
|---|---|
| Carry Distance | Yes |
| Rollout Distance | Yes |
| Total Distance | Yes |
| Left Deviation | No |
| Right Deviation | No |

Rationale: directional dispersion is minimal for chips; the primary calibration variables are distance control and rollout.

> **Note:** Section 7.8.2 introduces `RolloutDistanceMeters` as a first-class attempt field. The data model defined in Section 7.9 supersedes Section 5.16 for the Chipping `MatrixAttempt` structure.

### 5.12.2 Attempt Validity Rule

At least one measurement field must be populated to record an attempt.

```
AttemptValid =
  CarryDistance IS NOT NULL
  OR RolloutDistance IS NOT NULL
  OR TotalDistance IS NOT NULL
```

### 5.12.3 Distance Units

All distance values use the user's global distance unit setting. Values are stored internally in meters with UI conversion at the display layer.

### 5.12.4 Add Shot Action

Each shot is recorded using an explicit **Add Shot** action.

**Before minimum attempts reached:**

```
Carry Distance:   [ 9.6  ]
Rollout Distance: [      ]
Total Distance:   [ 12.4 ]

[ Add Shot ]
```

**Once minimum is reached (AttemptCount = 2 when beginning entry):**

```
Carry Distance:   [ 10.1 ]
Rollout Distance: [      ]
Total Distance:   [ 13.0 ]

[ Add Shot – Same Cell ]   [ Add Shot – Next Cell ]
```

| Action | Behaviour |
|---|---|
| Add Shot – Same Cell | Records the attempt and keeps the user on the current cell |
| Add Shot – Next Cell | Records the attempt and advances to the next entry in the picklist |

---

## 5.13 Progress Indicators

### 5.13.1 Per-Cell Progress Bar

Each cell displays a progress bar tracking attempts against the session shot target.

**Example (target = 5):**

```
SW — 10y — Standard
[■■■□□]
3 / 5 shots
```

**At target:**

```
[■■■■■] ✓
5 / 5 shots
```

**Beyond target:**

```
[■■■■■■]
6 / 5 shots
```

### 5.13.2 Picklist Completion Checkmark

A checkmark appears next to any cell where `AttemptCount ≥ 3`, regardless of whether the session target has been met.

---

## 5.14 Attempt Editing During a Run

While a Chipping Matrix run is active, the user may edit or delete any previously recorded attempt on any cell.

**Editable fields:**

- Carry Distance
- Total Distance

Attempt timestamps are not modified on edit.

Deletion during a run is permitted. If deletion reduces a cell's attempt count below 3, that cell becomes ineligible for session completion until a further attempt is recorded.

---

## 5.15 Session Completion

### 5.15.1 Completion Rule

A Chipping Matrix run may only be completed when all measurement units satisfy the hard minimum.

```
∀ MeasurementUnit ∈ Session
AttemptCount ≥ 3
```

### 5.15.2 Handling Under-Minimum Cells

If the user attempts to finish the session and one or more cells have fewer than 3 attempts, the system surfaces the issue per affected cell.

**Example:**

```
Session cannot be completed

SW — 15y — High — 2 shots
  [ Continue recording ]   [ Remove cell ]
```

Removing a cell soft-excludes it (`ExcludedFromRun = true`). All associated `MatrixAttempt` records are retained in the database but the cell is removed from completion validation and hidden from the session UI.

### 5.15.3 On Completion

```
Finish Session confirmed
       ↓
MatrixRun.Status = Completed
MatrixRun.EndTimestamp = now
       ↓
Final aggregates calculated per MatrixCell
       ↓
MatrixRun available in Matrix History
       ↓
ActiveExecution cleared
       ↓
Floating resume control dismissed
```

---

## 5.16 Data Model

The Chipping Matrix does not use a flat, type-specific data model. It is implemented using the generic runtime model defined in Section 6 and the canonical entity schema defined in Section 8.

The Chipping Matrix is configured as follows within that model:

- **MatrixType** = `CHIPPING_MATRIX`
- **Axes:** Club (required), plus up to two optional user-named axes (e.g. Carry Distance, Flight), each with user-defined `MatrixAxisValue` records
- **Attempt fields:** `CarryDistanceMeters`, `RolloutDistanceMeters`, `TotalDistanceMeters` (see Section 7.9 for the authoritative Chipping `MatrixAttempt` structure)
- **Fields not used:** `LeftDeviationMeters`, `RightDeviationMeters`
- **Green condition metadata:** `GreenSpeed` and `GreenFirmness` are stored on `MatrixRun`

Refer to Section 6.11 (Full Data Model) and Section 8.9 (Full Schema Reference) for the authoritative entity definitions.

---

## 5.17 Decision Log

| # | Decision |
|---|---|
| 5.1 | Chipping Matrix reuses the Wedge Matrix engine with Carry Distance substituted for Effort |
| 5.2 | Only Club is required; Carry Distance and Flight axes are both optional |
| 5.3 | If no axes are defined, the session defaults to Club only at implied full effort |
| 5.4 | Both axis labels are user-editable |
| 5.5 | Carry distance checkpoints are fully user-defined with no maximum limit |
| 5.6 | Default carry distance template: 5y, 10y, 15y, 20y |
| 5.7 | Max Flight checkpoints = 10 |
| 5.8 | Session Shot Target defaults to 5; must be ≥ 3 |
| 5.9 | Setup screen displays live Estimated Shots and Minimum Shots summary |
| 5.10 | Picklist navigation used; entries grouped by club |
| 5.11 | Shot order options: Top → Bottom, Bottom → Top, Random |
| 5.12 | Random order fixed at session start; manual overrides return to the randomised sequence |
| 5.13 | Chipping attempts record Carry Distance, Rollout Distance, and Total Distance — no lateral dispersion |
| 5.14 | Dual submission buttons (Same Cell / Next Cell) appear once minimum is reached |
| 5.15 | Progress bars track against session target; checkmarks appear at AttemptCount ≥ 3 |
| 5.16 | Attempts are editable and deletable during an active run |
| 5.17 | Under-minimum cells must be completed or removed before the session can be finished |
| 5.18 | Green Speed captured via stepped selector: range 6.0–15.0 in steps of 0.5 |
| 5.19 | Green Firmness captured as Soft / Medium / Firm |
| 5.20 | All environment and green condition fields are optional session metadata |
| 5.21 | All distance values stored in meters internally; UI applies unit conversion |
| 5.22 | Chipping Matrix data model defers to the canonical runtime model in Sections 6 and 8; Section 5.16 contains a configuration summary only |

---

*End of Section 5 — Chipping Matrix Workflow*

---

# ZX Golf App — Matrix & Gapping System
# Section 6 — Matrix Runtime Model

**Version:** 6v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow, Section 4 — Wedge Matrix Workflow, Section 5 — Chipping Matrix Workflow

---

## 6.1 Overview

This section defines the core runtime engine that underpins all matrix workflows.

The Matrix Runtime Model is intentionally workflow-agnostic. Rather than defining separate data models for Gapping, Wedge, and Chipping matrices, the engine uses a set of generic entities that support any combination of axes. Workflow-specific behaviour is expressed through configuration, not separate models.

This section defines:

- Core runtime entities and their roles
- Entity relationships and data model
- Cell generation rules
- MatrixRun lifecycle
- Axis immutability rules
- Cell exclusion model
- Completion validation rules
- Post-completion editing and recalculation cascade

---

## 6.2 Core Runtime Entities

The Matrix Runtime Model consists of five first-class entities.

```
MatrixRun
MatrixAxis
MatrixAxisValue
MatrixCell
MatrixAttempt
```

### 6.2.1 Entity Roles

| Entity | Role |
|---|---|
| `MatrixRun` | Represents one complete or in-progress matrix session |
| `MatrixAxis` | Defines one dimension of the matrix |
| `MatrixAxisValue` | Represents one value within an axis |
| `MatrixCell` | Represents one unique combination of axis values |
| `MatrixAttempt` | Represents a single recorded shot within a cell |

---

## 6.3 Entity Definitions

### 6.3.1 MatrixRun

A `MatrixRun` represents one matrix session from setup through to completion.

```
MatrixRun
 ├── RunNumber               (sequential, globally unique)
 ├── MatrixType              (GappingChart | WedgeMatrix | ChippingMatrix)
 ├── Status                  (InProgress | Completed)
 ├── StartTimestamp
 ├── EndTimestamp            (nullable)
 ├── SessionShotTarget
 ├── ShotOrder               (TopToBottom | BottomToTop | Random)
 ├── Metadata                (see Section 6.3.6)
 ├── Axes[]
 └── Cells[]
```

### 6.3.2 MatrixAxis

A `MatrixAxis` defines one dimension of the matrix. Each run may have one or more axes.

```
MatrixAxis
 ├── MatrixRunID
 ├── AxisType                (Club | CarryDistance | Effort | Flight | Custom)
 ├── AxisName                (user-defined label)
 ├── AxisOrder               (integer — determines axis role in cell generation)
 └── AxisValues[]
```

**AxisOrder** determines the position of the axis in the cell identity. For example:

```
AxisOrder 1 = Club
AxisOrder 2 = Effort
AxisOrder 3 = Flight
```

### 6.3.3 MatrixAxisValue

A `MatrixAxisValue` represents one value within an axis.

```
MatrixAxisValue
 ├── AxisID
 ├── Label                   (user-defined string, e.g. "56°", "70%", "Low")
 └── SortOrder               (integer — determines display order within axis)
```

### 6.3.4 MatrixCell

A `MatrixCell` represents one unique combination of axis values and acts as the container for attempts.

```
MatrixCell
 ├── MatrixRunID
 ├── AxisValueIDs[]          (one value ID per axis — defines cell identity)
 ├── ExcludedFromRun         (boolean, default: false)
 └── Attempts[]
```

Cell identity is defined by the combination of `AxisValueIDs`. No two cells in a run share the same combination.

### 6.3.5 MatrixAttempt

A `MatrixAttempt` represents a single recorded shot within a cell.

```
MatrixAttempt
 ├── MatrixCellID
 ├── CarryDistanceMeters     (nullable)
 ├── TotalDistanceMeters     (nullable)
 ├── LeftDeviationMeters     (nullable)
 ├── RightDeviationMeters    (nullable)
 └── AttemptTimestamp
```

Field availability varies by matrix type.

| Field | Gapping | Wedge | Chipping |
|---|---|---|---|
| CarryDistance | ✓ | ✓ | ✓ |
| TotalDistance | ✓ | ✓ | ✓ |
| LeftDeviation | ✓ | ✓ | — |
| RightDeviation | ✓ | ✓ | — |

Nullable fields for inapplicable matrix types are always stored as `null`.

### 6.3.6 MatrixRun Metadata

Session-level contextual values are stored as metadata on the `MatrixRun`. All metadata fields are optional.

```
MatrixRun Metadata
 ├── DispersionCaptureEnabled  (boolean — Gapping, Wedge only)
 ├── MeasurementDevice         (nullable)
 ├── EnvironmentType           (nullable: Indoor | Outdoor)
 ├── SurfaceType               (nullable: Grass | Mat)
 ├── GreenSpeed                (nullable, 6.0–15.0 in 0.5 steps — Chipping only)
 └── GreenFirmness             (nullable: Soft | Medium | Firm — Chipping only)
```

---

## 6.4 Entity Relationship

```
MatrixRun
 ├── MatrixAxis (1 or more)
 │    └── MatrixAxisValue (1 or more)
 │
 └── MatrixCell (generated at run start)
      └── MatrixAttempt (0 or more)
```

Cells are linked to axis values by reference. A cell's identity is defined by its set of `AxisValueIDs`, one per axis.

---

## 6.5 Cell Generation

### 6.5.1 Generation Timing

All `MatrixCell` records are generated when the `MatrixRun` begins. No cells are created lazily during the session.

```
MatrixRun created
       ↓
Axes and AxisValues defined
       ↓
MatrixCells generated (CartesianProduct)
       ↓
MatrixRun.Status = InProgress
```

### 6.5.2 Generation Formula

Cells are generated as the cartesian product of all axis values.

```
MatrixCells = CartesianProduct(AxisValues per Axis)
```

**Example:**

```
Clubs:  52°, 56°, 60°     (3 values)
Effort: 50%, 70%, 90%     (3 values)
Flight: Low, Standard     (2 values)

Total cells: 3 × 3 × 2 = 18
```

**Single-axis example (Gapping):**

```
Clubs: 7i, 8i, 9i, PW    (4 values)

Total cells: 4
```

### 6.5.3 Initial Cell State

All generated cells begin with:

```
ExcludedFromRun = false
AttemptCount    = 0
```

### 6.5.4 Why Upfront Generation Is Required

Generating cells at run start enables:

- Deterministic session structure throughout the run
- Accurate session shot estimation on the setup screen
- Correct progress tracking from the first attempt
- Reliable completion validation

---

## 6.6 MatrixRun Lifecycle

```
Setup screen completed
       ↓
MatrixRun created (Status: InProgress)
Axes created
AxisValues created
MatrixCells generated
       ↓
ActiveExecution = MatrixRun
Floating resume control appears
       ↓
User records MatrixAttempts
       ↓
Completion rule satisfied
       ↓
User confirms Finish Session
       ↓
MatrixRun.Status = Completed
MatrixRun.EndTimestamp = now
Final aggregates calculated
       ↓
ActiveExecution cleared
Floating resume control dismissed
MatrixRun appears in Matrix History
```

---

## 6.7 Axis Immutability

### 6.7.1 Rule

Once a `MatrixRun` has started (Status = InProgress), its axes and axis values are locked and cannot be modified.

**Immutable elements after run start:**

- `MatrixAxis` records
- `MatrixAxisValue` records
- Axis order
- Axis count
- Checkpoint labels

**Examples of prohibited changes during a run:**

```
Adding a checkpoint
Removing a checkpoint
Renaming a checkpoint
Adding a club
Removing a club
Changing carry distances
```

### 6.7.2 Rationale

Because `MatrixCells` are generated as the cartesian product of axis values at run start, any structural change to the axes would invalidate or orphan existing cells and their associated attempt data.

Locking axes guarantees:

```
Cell identity is stable throughout the session
Attempt data remains correctly associated
Matrix structure is deterministic and auditable
```

### 6.7.3 Permitted Operations During a Run

Despite axis immutability, the following operations remain available:

| Operation | Permitted |
|---|---|
| Record new attempts | Yes |
| Edit existing attempts | Yes |
| Delete attempts | Yes |
| Soft-exclude a cell | Yes |
| Discard the entire run | Yes |
| Modify axes or axis values | No |

---

## 6.8 Cell Exclusion

### 6.8.1 Exclusion Model

When a measurement unit is removed from a session, its corresponding `MatrixCell` is not deleted. Instead it is soft-excluded.

```
MatrixCell.ExcludedFromRun = true
```

### 6.8.2 Rationale

Because cells are generated deterministically from the cartesian product of axis values, deleting them would break the structural integrity of the matrix. Soft exclusion preserves:

- Original matrix structure
- Attempt auditability
- Deterministic analytics

### 6.8.3 Behaviour of Excluded Cells

| Context | Behaviour |
|---|---|
| Active session picklist | Hidden |
| Progress tracking | Ignored |
| Shot estimates | Ignored |
| Completion validation | Ignored |
| Matrix Run Review page | Hidden |
| Database | Retained |

Excluded cells are not visible to the user in any UI context. Their records are retained in the database for auditability.

### 6.8.4 Example

**Before exclusion:**

```
52° — 50% — Low
52° — 50% — Standard
52° — 50% — High
```

**User removes `52° — 50% — High`:**

```
MatrixCell (52° × 50% × High)
ExcludedFromRun = true
```

**After exclusion (UI):**

```
52° — 50% — Low
52° — 50% — Standard
```

---

## 6.9 Completion Validation

### 6.9.1 Completion Rule

A `MatrixRun` may be completed when all active (non-excluded) cells satisfy the hard minimum attempt rule.

```
∀ MatrixCell where ExcludedFromRun = false
AttemptCount ≥ 3
```

The **Finish Session** action is disabled until this condition is satisfied for all active cells.

### 6.9.2 Under-Minimum Cells

If the user attempts to finish the session while one or more active cells have fewer than 3 attempts, the system surfaces each affected cell and presents two options:

```
Session cannot be completed

52° — 70% — High — 2 shots
  [ Continue recording ]   [ Remove cell ]
```

| Action | Behaviour |
|---|---|
| Continue recording | Keeps the cell active; user records additional attempts |
| Remove cell | Soft-excludes the cell; it is removed from completion validation |

---

## 6.10 Post-Completion Editing and Recalculation

### 6.10.1 Editing Rule

`MatrixAttempt` records remain editable after a `MatrixRun` is completed.

Editing any attempt triggers an immediate deterministic recalculation of all derived values.

### 6.10.2 Recalculation Cascade

```
MatrixAttempt edited
       ↓
MatrixCell aggregates recalculated
       ↓
MatrixRun aggregates recalculated
       ↓
Derived dataset values updated
```

### 6.10.3 Derived Values Affected

Depending on the matrix type, recalculation propagates through:

**Cell-level:**
- Average Carry Distance
- Average Total Distance
- Dispersion metrics (where applicable)

**Run-level:**
- Per-club averages
- Per-checkpoint averages
- Distance consistency metrics

**Snapshot-derived values:**
- If the run contributes to a `PerformanceSnapshot`, derived model values are recalculated

### 6.10.4 Snapshot Integrity

Editing a `MatrixAttempt` does not modify previously saved `PerformanceSnapshot` records.

Snapshots are treated as immutable historical records once saved.

```
PerformanceSnapshot saved
       ↓
MatrixAttempt edited later
       ↓
PerformanceSnapshot: unchanged
Derived model: recalculated
```

---

## 6.11 Full Data Model

```
MatrixRun
 ├── RunNumber
 ├── MatrixType
 ├── Status
 ├── StartTimestamp
 ├── EndTimestamp
 ├── SessionShotTarget
 ├── ShotOrder
 ├── DispersionCaptureEnabled
 ├── MeasurementDevice
 ├── EnvironmentType
 ├── SurfaceType
 ├── GreenSpeed
 ├── GreenFirmness
 │
 ├── MatrixAxis[]
 │    ├── AxisType
 │    ├── AxisName
 │    ├── AxisOrder
 │    └── MatrixAxisValue[]
 │         ├── Label
 │         └── SortOrder
 │
 └── MatrixCell[]
      ├── AxisValueIDs[]
      ├── ExcludedFromRun
      └── MatrixAttempt[]
           ├── CarryDistanceMeters
           ├── TotalDistanceMeters
           ├── LeftDeviationMeters
           ├── RightDeviationMeters
           └── AttemptTimestamp
```

---

## 6.12 Decision Log

| # | Decision |
|---|---|
| 6.1 | `MatrixAxis` exists as a first-class entity alongside `MatrixRun`, `MatrixAxisValue`, `MatrixCell`, and `MatrixAttempt` |
| 6.2 | The engine is workflow-agnostic; workflow behaviour is expressed through axis configuration |
| 6.3 | All `MatrixCell` records are generated at run start using the cartesian product of axis values |
| 6.4 | Axes and axis values are immutable once a `MatrixRun` has started |
| 6.5 | Removed cells are soft-excluded (`ExcludedFromRun = true`) rather than deleted |
| 6.6 | Excluded cells are hidden in all UI contexts but retained in the database |
| 6.7 | Completion rule applies only to active (non-excluded) cells |
| 6.8 | Attempts remain editable after run completion |
| 6.9 | Attempt edits trigger immediate recalculation of all derived values |
| 6.10 | Previously saved `PerformanceSnapshot` records are not modified by post-completion edits |

---

*End of Section 6 — Matrix Runtime Model*

---

# ZX Golf App — Matrix & Gapping System
# Section 7 — Matrix Review Pages

**Version:** 7v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow, Section 4 — Wedge Matrix Workflow, Section 5 — Chipping Matrix Workflow, Section 6 — Matrix Runtime Model

---

## 7.1 Overview

This section defines how completed matrix runs are presented within the Review area of the ZX Golf App.

Matrix results are surfaced using a hybrid model: a dedicated Matrices section within Review provides full browsing and analysis of all matrix runs, while other Review areas (such as Club pages) reference matrix-derived data where relevant.

This section defines:

- Review navigation structure
- Matrix entry pages and run history
- Gapping Chart review visualisation
- Gap highlighting and configuration
- Multi-run comparison
- Wedge Matrix review visualisation
- Wedge chart filtering
- Chipping Matrix review visualisation
- Chipping accuracy metrics and rollout capture
- Cell detail views and attempt editing

---

## 7.2 Review Navigation Structure

### 7.2.1 Top-Level Structure

Matrix results are accessible from a dedicated section within the Review tab.

```
Review
 ├── Practice
 ├── Clubs
 └── Matrices
      ├── Gapping Charts
      ├── Wedge Matrices
      └── Chipping Matrices
```

Note: Round analysis is not present in the current version of the app and is not referenced in this section.

### 7.2.2 Hybrid Integration

In addition to the dedicated Matrices section, Club pages within Review reference matrix-derived data where available.

**Example Club page:**

```
7i

Carry Distance
165y

Source
Latest Gapping Snapshot
```

This keeps calibration data transparent and traceable without requiring the user to navigate to the Matrices section to understand where club statistics originate.

---

## 7.3 Matrix Entry Pages

Each matrix type has a dedicated entry page within Review → Matrices. These pages display the full history of completed runs for that type.

**Example (Gapping Charts):**

```
Gapping Charts

Run #14 — 2026-06-15
Run #9  — 2026-03-12
Run #3  — 2026-01-05
```

Runs are ordered most recent first.

Selecting a run navigates to the Matrix Run Review page for that run.

---

## 7.4 Gapping Chart Review Page

### 7.4.1 Page Layout

The Gapping Chart Review page contains two primary sections displayed together:

1. Distance Ladder Chart
2. Numerical Table

This dual display allows players to quickly interpret distance gaps visually while retaining access to exact figures.

### 7.4.2 Distance Ladder Chart

The primary visualisation is a distance ladder chart ordered by average carry distance.

**Example:**

```
PW   ───────────── 135y
9i   ──────────────── 148y
8i   ────────────────── 160y
7i   ─────────────────── 167y ⚠
6i   ───────────────────────── 184y
```

Clubs are ordered by carry distance, not by bag order. This ensures the visual spacing between clubs directly represents distance gaps.

Gap warnings are overlaid on the chart. See Section 7.5.

### 7.4.3 Numerical Table

Below the ladder chart, the same data is presented in a table.

**Example:**

```
Club   Avg Carry   Avg Total   Shots
PW        135         142        5
9i        148         156        5
8i        160         168        6
7i        167         176        5  ⚠
6i        184         193        5
```

Columns:

| Column | Description |
|---|---|
| Club | Club identifier |
| Avg Carry | Average carry distance across all attempts |
| Avg Total | Average total distance across all attempts |
| Shots | Number of attempts recorded |

Gap warnings are also reflected in the table. See Section 7.5.

### 7.4.4 Club Attempt Detail View

Selecting a club row in the table opens a Club Attempt Detail view for that club within the run.

**Example:**

```
7i — Run #9 — 2026-03-12

Attempt 1   Carry 166   Total 175
Attempt 2   Carry 168   Total 177
Attempt 3   Carry 167   Total 176
Attempt 4   Carry 168   Total 177
Attempt 5   Carry 166   Total 175
```

From this view users may:

- Edit any attempt
- Delete any attempt

Edits trigger the recalculation cascade defined in Section 6.10.

---

## 7.5 Gap Highlighting

### 7.5.1 Default Thresholds

The Gapping Chart Review page analyses the distance gap between each adjacent pair of clubs and highlights gaps that fall outside acceptable bounds.

**System default thresholds:**

```
Minimum acceptable gap: 6 units
Maximum acceptable gap: 20 units
```

Gap thresholds are displayed and stored in the user's configured distance unit (Yards or Meters).

### 7.5.2 Gap Calculation

Gaps are calculated using average carry distance, with clubs ordered by carry distance.

```
Gap(n) = AvgCarry(n+1) − AvgCarry(n)
```

### 7.5.3 Warning Conditions

| Condition | Warning |
|---|---|
| Gap < minimum threshold | Small gap warning |
| Gap > maximum threshold | Large gap warning |

### 7.5.4 Visual Indicators

Problematic gaps are marked on both the ladder chart and the numerical table.

**Example:**

```
7i   ─────────────────── 167y ⚠ Small gap (7y — min: 10y)
```

Indicators include:

- Visual marker on the chart
- Warning icon in the table row
- Tooltip showing: gap value, configured threshold, and warning type

### 7.5.5 User Configuration

Users may adjust gap thresholds from within the Review settings.

**Example:**

```
Gap Analysis

Minimum gap  [ 8 ]  yd
Maximum gap  [ 18 ] yd
```

Values are entered and displayed in the user's configured distance unit.

Changes update the highlighting immediately across all Gapping Chart review pages.

---

## 7.6 Multi-Run Comparison

### 7.6.1 Initiating a Comparison

From the Gapping Charts history page, users may select multiple runs to compare.

**Example:**

```
Gapping Charts

☑ Run #14 — 2026-06-15
☑ Run #9  — 2026-03-12
☐ Run #3  — 2026-01-05

[ Compare ]
```

Maximum runs compared simultaneously: **3**

### 7.6.2 Comparison Ladder Chart

The comparison page overlays carry distance data from the selected runs on a shared ladder.

**Example:**

```
7i Carry Distance

Run Jan   ─────────────── 168y
Run Mar   ──────────────── 170y
Run Jun   ────────────────── 172y
```

This makes distance changes across time immediately visible.

### 7.6.3 Comparison Table

Below the chart, a comparison table displays exact values per run.

**Example:**

```
Club   Jun Carry   Mar Carry   Jan Carry
PW        138         137         135
9i        151         149         148
8i        163         162         160
7i        172         170         168
```

Runs are displayed with most recent first.

---

## 7.7 Wedge Matrix Review Page

### 7.7.1 Visualisation Approach

Wedge Matrix results are displayed as a distance ladder chart that plots every recorded measurement unit (Club × Effort × Flight combination) according to its average carry distance.

This transforms the matrix into a distance map showing all available shot types along a continuous distance scale — matching how players conceptualise their wedge system in practice.

### 7.7.2 Distance Ladder Chart

The ladder spans from the minimum to maximum carry distance in the dataset, with padding added for readability.

**Example:**

```
35y ─────────────────────────────────────────── 115y

52° — 50% — Low        ●  38y
52° — 50% — Standard      ●  42y
52° — 50% — High             ●  46y

56° — 70% — Low                  ●  58y
56° — 70% — Standard                 ●  62y
56° — 70% — High                        ●  67y

60° — 90% — Low                           ●  74y
60° — 90% — Standard                          ●  79y
60° — 90% — High                                  ●  84y
```

Each plotted point represents one `MatrixCell` (one Club × Effort × Flight combination).

**Ladder bounds formula:**

```
Min display = min(AvgCarry) − padding
Max display = max(AvgCarry) + padding
```

### 7.7.3 Flight Colour Differentiation

Plotted points are coloured by Flight checkpoint to allow quick trajectory comparison.

**Example legend:**

```
Low        ● Blue
Standard   ● Green
High       ● Orange
```

Colours are applied consistently across the chart. If the user has defined custom Flight checkpoint names, the same colour assignment applies in order of checkpoint sequence.

### 7.7.4 Chart Filtering

Users may filter the displayed points by any axis. Filter controls are available for all three axes.

**Example:**

```
Filter

Clubs
☑ 52°   ☑ 56°   ☑ 60°

Effort
☑ 50%   ☑ 70%   ☑ 90%

Flight
☑ Low   ☑ Standard   ☑ High
```

Deselecting a value hides all points associated with that value from the ladder. The chart updates immediately.

### 7.7.5 Interactive Point Selection

Tapping a plotted point opens the Cell Detail view for that measurement unit.

**Example:**

```
56° — 70% — Standard

Average Carry    62y
Average Total    70y
Attempts         5

Attempt 1   Carry 61   Total 69
Attempt 2   Carry 63   Total 71
Attempt 3   Carry 62   Total 70
Attempt 4   Carry 61   Total 69
Attempt 5   Carry 63   Total 71
```

From this view users may:

- Edit any attempt
- Delete any attempt

Edits trigger the recalculation cascade defined in Section 6.10.

---

## 7.8 Chipping Matrix Review Page

### 7.8.1 Visualisation Approach

The Chipping Matrix review focuses on **landing accuracy and rollout**, reflecting the primary skill being measured: distance control around the green.

Rather than a distance ladder, the visualisation shows how closely each shot lands relative to its intended target, and how far the ball rolls out after landing.

### 7.8.2 Rollout Capture

Each chipping attempt records three distance values.

| Field | Description |
|---|---|
| Carry Distance | Where the ball landed |
| Rollout Distance | How far the ball rolled after landing |
| Total Distance | Carry + Rollout (carry distance to final resting position) |

**Example attempt:**

```
Carry:   10y
Rollout:  4y
Total:   14y
```

Rollout is the difference between where the ball lands and where it comes to rest. It is captured as a separate field rather than derived from Carry and Total, as the user may not always record both.

**Updated attempt validity rule:**

At least one of Carry Distance, Rollout Distance, or Total Distance must be populated.

```
AttemptValid =
  CarryDistance IS NOT NULL
  OR RolloutDistance IS NOT NULL
  OR TotalDistance IS NOT NULL
```

**Updated `MatrixAttempt` structure for Chipping Matrix:**

```
MatrixAttempt (Chipping)
 ├── MatrixCellID
 ├── CarryDistanceMeters     (nullable)
 ├── RolloutDistanceMeters   (nullable)
 ├── TotalDistanceMeters     (nullable)
 └── AttemptTimestamp
```

### 7.8.3 Page Structure

The Chipping Matrix Review page is structured as follows:

```
Chipping Matrix Review
Run #N — YYYY-MM-DD

Distance Accuracy Overview
[Summary table — all targets]

Club Sections
 ├── PW
 │    └── [Charts for each target × flight combo]
 ├── SW
 │    └── [Charts for each target × flight combo]
 └── LW
      └── [Charts for each target × flight combo]
```

Each club section is expandable and collapsed by default. All flight types for a given club are shown within the same section.

### 7.8.4 Distance Accuracy Overview

At the top of the review page, a summary table shows average landing error per target distance, aggregated across all clubs and flights.

**Example:**

```
Distance Accuracy Overview

Target   Avg Carry Error   Avg Total Error
5y            0.22y             0.31y
10y           0.28y             0.38y
15y           0.36y             0.47y
20y           0.44y             0.56y
```

This helps players identify which distances require the most practice.

### 7.8.5 Club Section Layout

Within each club section, measurement units are grouped showing all flight types for each target distance together.

**Example (SW — 10y target, all flights):**

```
SW

10y Target

  Standard                Low                   High
  Target  10y |────|      Target  10y |────|     Target  10y |────|
  Shots   ● 9.6           Shots   ● 9.4          Shots   ● 9.9
          ● 9.8                   ● 9.6                   ● 10.2
          ● 10.1                  ● 9.8                   ● 10.4
  Avg Carry  9.83y        Avg Carry  9.60y        Avg Carry  10.17y
  Avg Roll   3.8y         Avg Roll   2.1y         Avg Roll   5.2y
```

Each mini-chart shows:

- A horizontal line representing the target carry distance
- Plotted points showing actual carry distances per attempt
- Average carry and average rollout below the chart

### 7.8.6 Accuracy Metrics

Each measurement unit displays the following summary statistics:

| Metric | Definition |
|---|---|
| Average Carry | Mean carry distance across all attempts |
| Average Error | Mean of `|carry − target|` across all attempts |
| Average Rollout | Mean rollout distance across all attempts |
| Short Bias | Percentage of attempts finishing short of target |
| Attempts | Total number of recorded attempts |

**Example:**

```
SW — 10y — Standard

Average Carry    9.83y
Average Error    0.28y
Average Rollout  3.80y
Short Bias       60%
Attempts         5
```

### 7.8.7 Cell Detail View

Tapping a measurement unit opens the full Cell Detail view.

**Example:**

```
SW — 10y — Standard

Average Carry    9.83y
Average Rollout  3.80y
Average Total    13.63y

Attempt 1   Carry 9.6   Rollout 3.6   Total 13.2
Attempt 2   Carry 9.8   Rollout 3.9   Total 13.7
Attempt 3   Carry 10.1  Rollout 3.8   Total 13.9
Attempt 4   Carry 10.2  Rollout 4.0   Total 14.2
Attempt 5   Carry 9.9   Rollout 3.7   Total 13.6
```

From this view users may:

- Edit any attempt
- Delete any attempt

Edits trigger the recalculation cascade defined in Section 6.10.

---

## 7.9 Updated Chipping Matrix Data Model

The addition of Rollout Distance updates the `MatrixAttempt` structure and the `MatrixRun` data model for the Chipping Matrix.

```
MatrixRun (Chipping Matrix)
 ├── RunNumber
 ├── MatrixType                 = ChippingMatrix
 ├── Status
 ├── StartTimestamp
 ├── EndTimestamp
 ├── SessionShotTarget
 ├── ShotOrder
 ├── AxisAName
 ├── AxisBName
 ├── AxisACheckpoints[]
 ├── AxisBCheckpoints[]
 ├── MeasurementDevice
 ├── EnvironmentType
 ├── SurfaceType
 ├── GreenSpeed
 ├── GreenFirmness
 └── MatrixCells[]
        └── MatrixCell
             ├── ClubID
             ├── AxisAValue
             ├── AxisBValue
             └── MatrixAttempts[]
                    └── MatrixAttempt
                         ├── CarryDistanceMeters      (nullable)
                         ├── RolloutDistanceMeters    (nullable)
                         ├── TotalDistanceMeters      (nullable)
                         └── AttemptTimestamp
```

This supersedes the Chipping `MatrixAttempt` structure defined in Section 5.16.

---

## 7.10 Decision Log

| # | Decision |
|---|---|
| 7.1 | Hybrid Review structure: dedicated Matrices section + Club page references |
| 7.2 | Review tab contains Practice, Clubs, and Matrices; no round analysis |
| 7.3 | Gapping Chart review displays distance ladder chart and numerical table |
| 7.4 | Gap highlighting is configurable; system defaults are 6 (min) and 20 (max) in user's distance unit |
| 7.5 | Gap thresholds are displayed and stored in the user's configured distance unit |
| 7.6 | Up to 3 Gapping Chart runs may be compared simultaneously |
| 7.7 | Wedge Matrix review uses a distance ladder plotting all Club × Effort × Flight combinations by carry |
| 7.8 | Flight checkpoints are differentiated by colour on the Wedge ladder chart |
| 7.9 | Wedge chart supports filtering by all axes: Club, Effort, and Flight |
| 7.10 | Chipping Matrix review groups measurement units by club, showing all flights per target distance |
| 7.11 | Chipping accuracy visualisation focuses on target vs actual carry with rollout metrics |
| 7.12 | Chipping attempts record Carry Distance, Rollout Distance, and Total Distance |
| 7.13 | Rollout Distance is a dedicated field, not derived from Carry and Total |
| 7.14 | Chipping attempt validity rule: at least one of Carry, Rollout, or Total must be populated |
| 7.15 | Cell Detail views are accessible from all matrix review pages |
| 7.16 | Attempts are editable from the Cell Detail view; edits trigger the Section 6 recalculation cascade |

---

*End of Section 7 — Matrix Review Pages*

---

# ZX Golf App — Matrix & Gapping System
# Section 8 — Data Model Extensions

**Version:** 8v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow, Section 4 — Wedge Matrix Workflow, Section 5 — Chipping Matrix Workflow, Section 6 — Matrix Runtime Model, Section 7 — Matrix Review Pages

---

## 8.1 Overview

This section formally defines all database entities introduced by the Matrix & Gapping system, and documents extensions to existing entities required to support matrix workflows.

This section defines:

- MatrixType enumeration
- Core matrix entity schemas
- Entity relationships
- Extensions to existing entities
- MatrixCell axis membership model
- Persistence guarantees

---

## 8.2 MatrixType Enumeration

Each `MatrixRun` identifies its workflow using a fixed `MatrixType` value.

### 8.2.1 Allowed Values

```
GAPPING_CHART
WEDGE_MATRIX
CHIPPING_MATRIX
```

### 8.2.2 Role of MatrixType

`MatrixType` is stored on `MatrixRun` and determines:

| Concern | Governed by MatrixType |
|---|---|
| Workflow behaviour | Yes |
| Attempt field schema | Yes |
| Review visualisation | Yes |
| Analytics rules | Yes |

**Example:**

```
MatrixRun
 ├── MatrixType = WEDGE_MATRIX
```

### 8.2.3 Type-Specific Field Rules

| Field | GAPPING_CHART | WEDGE_MATRIX | CHIPPING_MATRIX |
|---|---|---|---|
| LeftDeviation | Optional | Optional | Not used |
| RightDeviation | Optional | Optional | Not used |
| RolloutDistance | Not used | Not used | Optional |
| GreenSpeed | Not used | Not used | Optional |
| GreenFirmness | Not used | Not used | Optional |

### 8.2.4 Extensibility

The `MatrixType` enumeration is fixed at three values for the current version.

Future matrix types (e.g. `PUTTING_MATRIX`, `SHOT_SHAPE_MATRIX`) may be added in later versions. No extensibility mechanism is required at this stage.

---

## 8.3 New Entity Schemas

The Matrix system introduces five new entities.

```
MatrixRun
MatrixAxis
MatrixAxisValue
MatrixCell
MatrixAttempt
```

### 8.3.1 MatrixRun

Represents one complete or in-progress matrix session.

```
MatrixRun

MatrixRunID             PK
MatrixType              GAPPING_CHART | WEDGE_MATRIX | CHIPPING_MATRIX
RunNumber               Integer, sequential, globally unique
RunState                InProgress | Completed
StartTimestamp
EndTimestamp            Nullable

SessionShotTarget       Integer ≥ 3
ShotOrderMode           TopToBottom | BottomToTop | Random
DispersionCaptureEnabled  Boolean (GAPPING_CHART, WEDGE_MATRIX only)

MeasurementDevice       Nullable
EnvironmentType         Nullable — Indoor | Outdoor
SurfaceType             Nullable — Grass | Mat

GreenSpeed              Nullable — 6.0 to 15.0 in 0.5 steps (CHIPPING_MATRIX only)
GreenFirmness           Nullable — Soft | Medium | Firm (CHIPPING_MATRIX only)
```

### 8.3.2 MatrixAxis

Defines one dimension of the matrix. Each `MatrixRun` has one or more axes.

```
MatrixAxis

MatrixAxisID            PK
MatrixRunID             FK → MatrixRun
AxisType                Club | Effort | Flight | CarryDistance | Custom
AxisName                String — user-defined label
AxisOrder               Integer — position in cell identity
```

`AxisOrder` determines the role of the axis in cell generation and display.

**Example:**

```
AxisOrder 1 = Club
AxisOrder 2 = Effort
AxisOrder 3 = Flight
```

### 8.3.3 MatrixAxisValue

Represents one value within an axis.

```
MatrixAxisValue

AxisValueID             PK
MatrixAxisID            FK → MatrixAxis
Label                   String — user-defined (e.g. "56°", "70%", "Low", "10y")
SortOrder               Integer — display order within the axis
```

### 8.3.4 MatrixCell

Represents one unique combination of axis values and acts as the container for attempts.

```
MatrixCell

MatrixCellID            PK
MatrixRunID             FK → MatrixRun
AxisValueIDs            Array of AxisValueID — defines cell identity (see Section 8.4)
ExcludedFromRun         Boolean, default: false
```

No two cells within the same `MatrixRun` share the same `AxisValueIDs` combination.

### 8.3.5 MatrixAttempt

Represents a single recorded shot within a cell.

```
MatrixAttempt

MatrixAttemptID         PK
MatrixCellID            FK → MatrixCell
AttemptTimestamp

CarryDistanceMeters     Nullable
TotalDistanceMeters     Nullable
LeftDeviationMeters     Nullable — GAPPING_CHART and WEDGE_MATRIX only
RightDeviationMeters    Nullable — GAPPING_CHART and WEDGE_MATRIX only
RolloutDistanceMeters   Nullable — CHIPPING_MATRIX only
```

Fields not applicable to a given `MatrixType` are always stored as `null`.

---

## 8.4 MatrixCell Axis Membership

### 8.4.1 Storage Model

Each `MatrixCell` stores its axis membership using a single array field containing `AxisValueID` references.

```
MatrixCell
 ├── MatrixCellID
 ├── MatrixRunID
 ├── AxisValueIDs    [12, 34, 56]
 └── ExcludedFromRun
```

**Example:**

```
Cell identity: 56° × 70% × Low

AxisValueIDs = [12, 34, 56]

Where:
  12 → "56°"  (Club axis)
  34 → "70%"  (Effort axis)
  56 → "Low"  (Flight axis)
```

### 8.4.2 Rationale

An array field avoids the need for a separate join table (`MatrixCellAxisValue`) while still supporting arbitrary matrix dimensions.

| Property | Benefit |
|---|---|
| Simpler schema | Fewer tables, fewer joins |
| Faster reads | Cell identity resolved in a single field |
| Flexible axis count | Supports 1, 2, or 3 axes without schema changes |

Because axes are immutable after run start (Section 6.7), the array remains stable and deterministic for the lifetime of the run.

---

## 8.5 Entity Relationships

```
MatrixRun
 ├── MatrixAxis (one or more)
 │    └── MatrixAxisValue (one or more)
 │
 └── MatrixCell (generated at run start)
      └── MatrixAttempt (zero or more)
```

`MatrixCell` references `MatrixAxisValue` records via the `AxisValueIDs` array. No direct foreign key exists between `MatrixCell` and `MatrixAxis` — the relationship is resolved through `MatrixAxisValue`.

---

## 8.6 Extensions to Existing Entities

### 8.6.1 CalendarSlot

The `CalendarSlot` entity used by the Plan system requires two new fields to support matrix session scheduling.

**New fields:**

```
CalendarSlot

CompletingMatrixRunID   Nullable FK → MatrixRun
MatrixType              Nullable — GAPPING_CHART | WEDGE_MATRIX | CHIPPING_MATRIX
```

**Usage:**

When a `CalendarSlot` is of type `MATRIX`, these fields record:

- Which `MatrixRun` completed the slot (once fulfilled)
- Which matrix type was scheduled

**Example:**

```
CalendarSlot
 ├── SlotType                = MATRIX
 ├── MatrixType              = WEDGE_MATRIX
 └── CompletingMatrixRunID   = null (unfulfilled) | MatrixRunID (fulfilled)
```

### 8.6.2 Review Note — Existing Entity Audit

> **Implementation Note for Claude Code**
>
> `CalendarSlot` has been identified as the only existing entity requiring extension for the Matrix system. However, a full audit of all existing ZX Golf entities should be performed during build planning to confirm no other entities require modification.
>
> Areas to review in particular:
> - Any entity that references `PracticeBlock` by analogy (the matrix system mirrors practice session patterns)
> - Any entity involved in performance tracking or club statistics that may benefit from a matrix data reference
> - The `ActiveExecution` model, which now governs both `PracticeBlock` and `MatrixRun`
>
> This note should be resolved before implementation begins.

---

## 8.7 Persistence Guarantees

The following persistence rules apply to all matrix entities.

| Entity | Guarantee |
|---|---|
| `MatrixRun` | Permanent unless explicitly discarded by the user |
| `MatrixAxis` | Immutable after run start |
| `MatrixAxisValue` | Immutable after run start |
| `MatrixCell` | Generated at run start; soft-excludable; never hard-deleted |
| `MatrixAttempt` | Editable and deletable at any time |
| Derived values | Recalculated deterministically on any attempt edit |
| `PerformanceSnapshot` | Not modified by post-completion attempt edits |

---

## 8.8 Analytics Scope

Matrix analytics operate across all `MatrixRun` records, not only those linked to `PerformanceSnapshot` records.

```
Analytics source = All MatrixRuns (Completed)
```

This ensures analytics reflect the full measurement history of the player rather than only formally snapshotted calibration states.

`PerformanceSnapshot` records remain authoritative for:

- Practice targeting
- Club baseline distances
- System calibration

But they do not constrain the analytics dataset.

---

## 8.9 Full Schema Reference

```
MatrixRun
 ├── MatrixRunID             PK
 ├── MatrixType
 ├── RunNumber
 ├── RunState
 ├── StartTimestamp
 ├── EndTimestamp
 ├── SessionShotTarget
 ├── ShotOrderMode
 ├── DispersionCaptureEnabled
 ├── MeasurementDevice
 ├── EnvironmentType
 ├── SurfaceType
 ├── GreenSpeed
 ├── GreenFirmness
 │
 ├── MatrixAxis[]
 │    ├── MatrixAxisID       PK
 │    ├── MatrixRunID        FK
 │    ├── AxisType
 │    ├── AxisName
 │    ├── AxisOrder
 │    └── MatrixAxisValue[]
 │         ├── AxisValueID   PK
 │         ├── MatrixAxisID  FK
 │         ├── Label
 │         └── SortOrder
 │
 └── MatrixCell[]
      ├── MatrixCellID       PK
      ├── MatrixRunID        FK
      ├── AxisValueIDs[]
      ├── ExcludedFromRun
      └── MatrixAttempt[]
           ├── MatrixAttemptID     PK
           ├── MatrixCellID        FK
           ├── AttemptTimestamp
           ├── CarryDistanceMeters
           ├── TotalDistanceMeters
           ├── LeftDeviationMeters
           ├── RightDeviationMeters
           └── RolloutDistanceMeters
```

---

## 8.10 Decision Log

| # | Decision |
|---|---|
| 8.1 | MatrixType is a fixed enumeration: GAPPING_CHART, WEDGE_MATRIX, CHIPPING_MATRIX |
| 8.2 | MatrixType determines workflow behaviour, attempt schema, review visualisation, and analytics rules |
| 8.3 | Five new entities introduced: MatrixRun, MatrixAxis, MatrixAxisValue, MatrixCell, MatrixAttempt |
| 8.4 | MatrixCell stores axis membership as an AxisValueIDs array rather than a join table |
| 8.5 | CalendarSlot is extended with CompletingMatrixRunID and MatrixType fields |
| 8.6 | A full existing entity audit is required during build planning to confirm no other entities need extension |
| 8.7 | MatrixRun records are permanent unless explicitly discarded |
| 8.8 | Axes and axis values are immutable after run start |
| 8.9 | MatrixCells are soft-excluded rather than deleted |
| 8.10 | Analytics operate across all completed MatrixRuns, not only snapshot-linked runs |

---

*End of Section 8 — Data Model Extensions*

---

# ZX Golf App — Matrix & Gapping System
# Section 9 — Matrix Analytics Integration

**Version:** 9v.a1
**Status:** Canonical
**Depends on:** Section 1 — Matrix & Gapping System Overview, Section 2 — Matrix & Gapping Homepage, Section 3 — Gapping Chart Workflow, Section 4 — Wedge Matrix Workflow, Section 5 — Chipping Matrix Workflow, Section 6 — Matrix Runtime Model, Section 7 — Matrix Review Pages, Section 8 — Data Model Extensions

---

## 9.1 Overview

This section defines how matrix datasets generate insights and analytics for the player within the Review system.

Analytics transform raw `MatrixAttempt` records into meaningful measures of distance calibration, coverage, accuracy, and trend — turning the matrix data into actionable player value.

This section defines:

- Analytics data source and scope
- Aggregation eligibility rules
- Outlier trimming
- Weighted vs raw aggregation model
- The four analytics categories
- Automated insights layer
- Insight surfacing rules

---

## 9.2 Analytics Data Source

Matrix analytics operate across all completed `MatrixRun` records, not only those linked to `PerformanceSnapshot` records.

```
Analytics source = All MatrixRuns where RunState = Completed
```

All calculations are derived views computed at query time. No analytics values are stored as permanent fields.

---

## 9.3 Aggregation Eligibility Rules

### 9.3.1 Minimum Attempt Threshold

Analytics are only computed for `MatrixCell` records that meet the minimum attempt threshold.

```
AttemptCount ≥ 3
```

Cells with fewer than 3 attempts are excluded from all analytics calculations.

### 9.3.2 Excluded Cells

Cells marked as soft-excluded are ignored across all analytics.

```
ExcludedFromRun = true → excluded from analytics
```

### 9.3.3 Outlier Trimming

Before analytics values are calculated, outlier attempts are removed using a symmetric trim applied to the attempt dataset per cell.

**Trim rule:**

```
Remove the top 10% and bottom 10% of attempts by carry distance
```

For small datasets, trimming is applied proportionally.

**Example (5 attempts):**

```
Attempts (sorted): 58, 61, 62, 63, 68

10% trim = 0.5 attempts each end → round to nearest whole attempt
→ Remove 1 attempt from each end

Trimmed dataset: 61, 62, 63
```

**Example (10 attempts):**

```
10% trim = 1 attempt each end
→ Remove lowest and highest attempt
```

Trimmed datasets are used as the basis for all derived metrics. Raw attempt records are never modified.

---

## 9.4 Weighted Aggregation Model

### 9.4.1 Weighting Principle

All analytics default to a time-weighted aggregation model where more recent runs contribute more to derived values than older runs. This prevents outdated calibration data from dominating analytics.

### 9.4.2 Weight Formula

Each `MatrixRun` is assigned a weight based on its age in days relative to today.

```
weight = exp(−2.25 × √(age_days / 365))
```

**Example weights:**

| Run Age | Weight |
|---|---|
| 10 days | ≈ 0.90 |
| 30 days | ≈ 0.78 |
| 90 days | ≈ 0.63 |
| 180 days | ≈ 0.50 |
| 365 days | ≈ 0.32 |

### 9.4.3 Weighted Average Formula

For any derived metric (e.g. average carry distance), the weighted average is calculated as:

```
WeightedAverage =
  Σ(value × weight) / Σ(weight)
```

Applied across all eligible attempts from all eligible runs, where each attempt inherits the weight of its parent `MatrixRun`.

### 9.4.4 Raw vs Weighted Toggle

Users may toggle between weighted and raw aggregation on all analytics views.

**Example control:**

```
Aggregation
○ Weighted  ● Raw
```

**Raw mode** treats all eligible attempts equally regardless of run age.

**Weighted mode** (default) applies the decay formula above.

The toggle is available on each analytics view. The selected mode persists within the session but does not need to persist across sessions.

---

## 9.5 Analytics Categories

The Matrix system produces four analytics categories.

```
1. Club Distance Analytics      (Gapping Chart)
2. Wedge Coverage Analytics     (Wedge Matrix)
3. Chipping Accuracy Analytics  (Chipping Matrix)
4. Distance Trend Analytics     (all matrix types)
```

---

## 9.6 Club Distance Analytics

**Source:** Gapping Chart runs

**Location:** Review → Matrices → Gapping Charts (and referenced on Review → Clubs)

### 9.6.1 Metrics

For each club with sufficient data, the following metrics are calculated.

| Metric | Definition |
|---|---|
| Average Carry | Weighted mean carry distance (trimmed dataset) |
| Average Total | Weighted mean total distance (trimmed dataset) |
| Carry Consistency | Standard deviation of carry distances (trimmed dataset) |
| Distance Gap | Gap to next club by carry distance |
| Data Sources | Number of contributing runs |

### 9.6.2 Consistency Formula

```
CarryConsistency = StdDev(trimmed carry distances)
```

Lower values indicate more reliable distance control.

### 9.6.3 Example Display

```
7i

Average Carry       170y
Average Total       181y
Carry Consistency   ±2.4y
Distance Gap        +12y to 6i

Derived from 3 gapping sessions
```

### 9.6.4 Gap Analysis

Gap analytics are calculated between every adjacent club pair ordered by average carry distance.

```
Gap(n) = AvgCarry(n+1) − AvgCarry(n)
```

Gaps outside the user-configured thresholds (defined in Section 7.5) trigger visual warnings consistent with the per-run gap highlighting behaviour.

---

## 9.7 Wedge Coverage Analytics

**Source:** Wedge Matrix runs

**Location:** Review → Matrices → Wedge Matrices

### 9.7.1 Coverage Model

Wedge coverage analytics determine which distances the player can reliably produce, and whether any gaps or overlaps exist in their wedge system.

Each `MatrixCell` with sufficient data contributes one coverage point, plotted at its average carry distance.

### 9.7.2 Coverage Chart

The coverage chart plots all eligible shot types (Club × Effort × Flight combinations) along a continuous distance scale.

**Example:**

```
Distance Coverage

30y ─────────────────────────────────────── 110y

  52° 50% Low      ● 38y
  52° 50% Std      ● 42y
  52° 50% High     ● 46y
  56° 70% Low      ● 58y
  56° 70% Std      ● 62y
  56° 70% High     ● 67y
  60° 90% Low      ● 74y
  60° 90% Std      ● 79y
  60° 90% High     ● 84y
```

Flight types are colour-differentiated consistent with Section 7.7.3.

### 9.7.3 Coverage Metrics per Cell

For each plotted shot type:

| Metric | Definition |
|---|---|
| Average Carry | Weighted mean carry (trimmed) |
| Carry Consistency | StdDev of carry (trimmed) |
| Data Sources | Number of contributing runs |

### 9.7.4 Coverage Gap Detection

The system identifies distances within the player's overall wedge range that are not reliably covered by any shot type.

**Gap definition:**

A coverage gap exists where no eligible shot type produces an average carry within a threshold distance of a given yard marker.

This insight is surfaced as an automated observation. See Section 9.9.

### 9.7.5 Chart Filtering

The coverage chart supports filtering by all axes (Club, Effort, Flight), consistent with Section 7.7.4.

---

## 9.8 Chipping Accuracy Analytics

**Source:** Chipping Matrix runs

**Location:** Review → Matrices → Chipping Matrices

### 9.8.1 Metrics

For each `MatrixCell` with sufficient data, the following accuracy metrics are calculated.

| Metric | Definition |
|---|---|
| Average Carry | Weighted mean carry distance (trimmed) |
| Average Error | Mean of `|carry − target|` (trimmed) |
| Average Rollout | Weighted mean rollout distance (trimmed) |
| Average Total | Weighted mean total distance (trimmed) |
| Short Bias | Percentage of trimmed attempts finishing short of target |
| Carry Consistency | StdDev of carry distances (trimmed) |
| Data Sources | Number of contributing runs |

### 9.8.2 Aggregated Accuracy Overview

Accuracy is summarised across all clubs per target distance.

**Example:**

```
Distance Accuracy Overview

Target   Avg Error   Short Bias
5y        0.22y        55%
10y       0.28y        60%
15y       0.36y        58%
20y       0.44y        62%
```

This overview helps players identify which target distances show the weakest control.

### 9.8.3 Rollout Analytics

Average rollout is displayed per measurement unit and aggregated by green condition where sufficient data exists.

**Example:**

```
SW — 10y — Standard

Average Rollout    3.8y
On Firm greens     5.1y  (2 sessions)
On Medium greens   3.6y  (1 session)
```

Green condition metadata from `MatrixRun` (Section 8.3.1) is used to segment rollout analytics where multiple sessions with differing conditions exist.

---

## 9.9 Distance Trend Analytics

**Source:** All matrix types

**Location:** Surfaced within each matrix type's review page

### 9.9.1 Eligibility

Distance trend analytics are displayed for any club or cell where the combined attempt dataset (across all contributing runs) meets the minimum threshold.

```
Total eligible attempts ≥ 3
```

Trend data is shown as soon as this threshold is met, even if only one run contributes.

### 9.9.2 Trend Data

Trend analytics plot average carry distance over time, one point per completed `MatrixRun`.

**Example:**

```
7i Carry Distance Trend

Run Jan   168y
Run Mar   170y
Run Jun   172y
```

Each point represents the per-run average carry for that cell, calculated from the trimmed attempt dataset for that run only (not the cross-run weighted average).

### 9.9.3 Trend Sources by Matrix Type

| Matrix Type | Trend dimension |
|---|---|
| Gapping Chart | Per-club carry trend |
| Wedge Matrix | Per-cell carry trend (Club × Effort × Flight) |
| Chipping Matrix | Per-cell carry and rollout trend |

### 9.9.4 Weighted vs Raw in Trend View

The weighted/raw toggle (Section 9.4.4) applies to trend views. In weighted mode, the plotted trend points are weighted averages; in raw mode they are unweighted per-run averages.

---

## 9.10 Automated Insights

### 9.10.1 Insight Model

The analytics system generates short automated observations based on the computed analytics data. These observations are displayed contextually within matrix review pages — they do not appear in a separate dedicated section.

Insights are lightweight observations, not coaching recommendations.

### 9.10.2 Surfacing Rule

Insights appear inline on the relevant matrix review page, in close proximity to the data that triggered them.

**Example placement:**

```
[Distance Ladder Chart]

⚑ Your 8i and 9i carry only 7y apart. Consider recalibrating one club.

[Numerical Table]
```

### 9.10.3 Insight Types by Category

**Gapping Chart Insights:**

| Trigger | Example Insight |
|---|---|
| Gap below minimum threshold | *"Your 8i–9i gap is 7y — below your minimum of 10y."* |
| Gap above maximum threshold | *"Your 5i–6i gap is 24y — above your maximum of 20y."* |
| High carry inconsistency | *"Your 7i carry varies by ±5y. More data may improve reliability."* |

**Wedge Matrix Insights:**

| Trigger | Example Insight |
|---|---|
| Coverage gap detected | *"No shot type reliably covers 55–65y in your current wedge system."* |
| Distance overlap detected | *"Your 56° 70% High and 60° 90% Low produce similar distances (67y / 66y)."* |

**Chipping Matrix Insights:**

| Trigger | Example Insight |
|---|---|
| Consistent short bias | *"Your 10y chips land short on average. Check carry target alignment."* |
| High average error at a distance | *"Your 20y chip accuracy (avg error 0.8y) is significantly lower than shorter distances."* |
| Rollout variance by condition | *"Your rollout on firm greens averages 5.1y vs 3.6y on medium greens."* |

### 9.10.4 Insight Display Rules

- Insights are generated only when sufficient data exists (minimum 3 eligible attempts)
- A maximum of **3 insights** are displayed per review page to avoid noise
- Insights are ranked by relevance (magnitude of the detected issue)
- Insights do not replace or duplicate the gap warning indicators already defined in Section 7.5

---

## 9.11 Decision Log

| # | Decision |
|---|---|
| 9.1 | Analytics operate across all completed MatrixRuns, not only snapshot-linked runs |
| 9.2 | All analytics values are derived at query time; none are stored permanently |
| 9.3 | Analytics require a minimum of 3 eligible attempts per cell |
| 9.4 | Excluded cells (ExcludedFromRun = true) are ignored in all analytics |
| 9.5 | Outlier trimming removes the top and bottom 10% of attempts per cell before calculation |
| 9.6 | All analytics default to time-weighted aggregation using the defined decay formula |
| 9.7 | Users may toggle between weighted and raw aggregation on all analytics views |
| 9.8 | Automated insights are displayed contextually within matrix review pages only |
| 9.9 | A maximum of 3 insights are shown per review page, ranked by relevance |
| 9.10 | Trend analytics are eligible as soon as 3 total attempts exist across all runs |
| 9.11 | Trend points represent per-run averages from trimmed data, not cross-run weighted averages |
| 9.12 | Rollout analytics are segmented by green condition where sufficient data exists |

---

*End of Section 9 — Matrix Analytics Integration*