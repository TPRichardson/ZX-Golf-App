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

Removing a club discards all `MatrixCell` records and associated `MatrixAttempt` records for that club across all axis combinations.

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
| Total Distance | Yes |
| Left Deviation | No |
| Right Deviation | No |

Rationale: directional dispersion is minimal for chips; the primary calibration variable is distance control.

### 5.12.2 Attempt Validity Rule

At least one measurement field must be populated to record an attempt.

```
AttemptValid =
  CarryDistance IS NOT NULL
  OR TotalDistance IS NOT NULL
```

### 5.12.3 Distance Units

All distance values use the user's global distance unit setting. Values are stored internally in meters with UI conversion at the display layer.

### 5.12.4 Add Shot Action

Each shot is recorded using an explicit **Add Shot** action.

**Before minimum attempts reached:**

```
Carry Distance:  [ 9.6  ]
Total Distance:  [ 12.4 ]

[ Add Shot ]
```

**Once minimum is reached (AttemptCount = 2 when beginning entry):**

```
Carry Distance:  [ 10.1 ]
Total Distance:  [ 13.0 ]

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

Removing a cell discards its `MatrixCell` and all associated `MatrixAttempt` records.

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

## 5.16 Data Model Summary

```
MatrixRun (Chipping Matrix)
 ├── RunNumber                  (sequential, globally unique)
 ├── MatrixType                 = ChippingMatrix
 ├── Status                     (InProgress | Completed)
 ├── StartTimestamp
 ├── EndTimestamp               (nullable)
 ├── SessionShotTarget
 ├── ShotOrder                  (TopToBottom | BottomToTop | Random)
 ├── AxisAName                  (nullable)
 ├── AxisBName                  (nullable)
 ├── AxisACheckpoints[]         (nullable — carry distance values)
 ├── AxisBCheckpoints[]         (nullable — flight labels)
 ├── MeasurementDevice          (nullable)
 ├── EnvironmentType            (nullable)
 ├── SurfaceType                (nullable)
 ├── GreenSpeed                 (nullable, 6.0–15.0 in 0.5 steps)
 ├── GreenFirmness              (nullable: Soft | Medium | Firm)
 └── MatrixCells[]
        └── MatrixCell
             ├── ClubID
             ├── AxisAValue               (nullable — carry distance)
             ├── AxisBValue               (nullable — flight label)
             └── MatrixAttempts[]
                    └── MatrixAttempt
                         ├── CarryDistanceMeters      (nullable)
                         ├── TotalDistanceMeters      (nullable)
                         └── AttemptTimestamp
```

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
| 5.13 | Chipping attempts record Carry Distance and Total Distance only — no lateral dispersion |
| 5.14 | Dual submission buttons (Same Cell / Next Cell) appear once minimum is reached |
| 5.15 | Progress bars track against session target; checkmarks appear at AttemptCount ≥ 3 |
| 5.16 | Attempts are editable and deletable during an active run |
| 5.17 | Under-minimum cells must be completed or removed before the session can be finished |
| 5.18 | Green Speed captured via stepped selector: range 6.0–15.0 in steps of 0.5 |
| 5.19 | Green Firmness captured as Soft / Medium / Firm |
| 5.20 | All environment and green condition fields are optional session metadata |
| 5.21 | All distance values stored in meters internally; UI applies unit conversion |

---

*End of Section 5 — Chipping Matrix Workflow*
