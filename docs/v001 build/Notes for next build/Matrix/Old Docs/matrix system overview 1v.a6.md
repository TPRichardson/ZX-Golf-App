# Section X — Matrix & Gapping System Architecture (1v.a6 Draft)

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

The **Finish Matrix** action is only enabled when all required measurement units have met the minimum attempt count. The system must enforce this with a hard block — partial completion is not permitted.

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
"Finish Matrix" action becomes available
      ↓
User presses Finish Matrix
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

If a user exits the matrix workflow before pressing Finish Matrix, the run is saved in an InProgress state and may be resumed at any time.

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
EndTimestamp     (recorded when Finish Matrix is pressed)
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

End of Section X — Matrix & Gapping System Architecture (1v.a6 Draft)
