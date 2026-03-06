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
ActiveExecution = MatrixRun (new)
       ↓
Floating resume control appears
       ↓
User enters matrix execution workflow
```

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

This navigates to the Snapshot creation page defined in Section X.13.

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
