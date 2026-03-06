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

Removing a club discards all `MatrixCell` records and associated `MatrixAttempt` records for that club across all axis combinations.

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

Removing a cell discards its `MatrixCell` and all associated `MatrixAttempt` records.

### 4.14.3 On Completion

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

## 4.15 Data Model Summary

```
MatrixRun (Wedge Matrix)
 ├── RunNumber                 (sequential, globally unique)
 ├── MatrixType                = WedgeMatrix
 ├── Status                    (InProgress | Completed)
 ├── StartTimestamp
 ├── EndTimestamp              (nullable)
 ├── SessionShotTarget
 ├── DispersionCaptureEnabled  (boolean)
 ├── ShotOrder                 (TopToBottom | BottomToTop | Random)
 ├── AxisAName                 (nullable)
 ├── AxisBName                 (nullable)
 ├── AxisACheckpoints[]        (nullable)
 ├── AxisBCheckpoints[]        (nullable)
 ├── MeasurementDevice         (nullable)
 ├── EnvironmentType           (nullable)
 ├── SurfaceType               (nullable)
 └── MatrixCells[]
        └── MatrixCell
             ├── ClubID
             ├── AxisAValue               (nullable)
             ├── AxisBValue               (nullable)
             └── MatrixAttempts[]
                    └── MatrixAttempt
                         ├── CarryDistanceMeters      (nullable)
                         ├── TotalDistanceMeters      (nullable)
                         ├── LeftDeviationMeters      (nullable)
                         ├── RightDeviationMeters     (nullable)
                         └── AttemptTimestamp
```

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

---

*End of Section 4 — Wedge Matrix Workflow*
