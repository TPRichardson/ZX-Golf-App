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
