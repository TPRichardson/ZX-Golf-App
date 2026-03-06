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

- The `MatrixCell` and all associated `MatrixAttempt` records for that club are discarded
- The session advances to the next club in the current order
- The club is excluded from the final dataset

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

Removing the club discards its `MatrixCell` and all associated `MatrixAttempt` records.

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
