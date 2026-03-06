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
