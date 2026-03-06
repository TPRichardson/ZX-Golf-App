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
