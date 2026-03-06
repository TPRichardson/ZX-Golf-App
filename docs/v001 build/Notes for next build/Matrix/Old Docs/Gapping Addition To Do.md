# ZX Golf App — Matrix & Gapping System Specification To-Do

## Purpose

This document defines the **work plan for producing the Matrix & Gapping system specification** within the ZX Golf App.

The Matrix & Gapping system introduces structured workflows for capturing **distance calibration datasets** such as:

* Gapping charts
* Wedge matrices
* Chipping matrices

Each workflow will support:

* **Track entry workflows**
* **Review pages**
* Integration with **PerformanceSnapshots**

The final deliverables are **canonical markdown spec documents** suitable for implementation.

---

# Spec Authoring Process

Each section is produced using the following workflow:

1. The assistant generates a **list of key design questions** required to define the section.
2. The user answers the questions.
3. The assistant produces a **final canonical markdown specification document** for that section.

All specification documents must:

* Follow the **tone and structure of the canonical ZX spec**
* Use **canonical terminology**
* Define **runtime behaviour, lifecycle rules, and UI behaviour**
* Be suitable for **direct technical implementation**

---

# Document Build List

## Section 1 — Matrix System Overview ✅ COMPLETE

File

```
matrix-system-overview.md
```

Defines:

* System purpose
* Architectural separation from drills
* Matrix runtime model
* MatrixRun / MatrixCell / MatrixAttempt
* PerformanceSnapshot integration
* Recency-weighted derived calculations
* Snapshot creation workflow
* Calendar integration
* Scoring engine isolation
* Data model changes

---

## Section 2 — Matrix & Gapping Homepage ✅ COMPLETE

File

```
matrix-homepage.md
```

Defines:

* Track navigation

```
Track
 ├ Drills
 └ Matrices & Gapping
```

* Start Matrix entry cards
* Active execution behaviour (floating resume control)
* Mutual exclusivity of PracticeBlock and MatrixRun
* Matrix history grouped by type
* Unlimited history
* Run review page
* Run discard behaviour
* Snapshot creation link

---

## Section 3 — Gapping Chart Workflow ✅ COMPLETE

File

```
gapping-chart-workflow.md
```

Defines:

* Setup screen
* Club selection
* Session shot target (default 5)
* Hard minimum attempts (3)
* Club ordering options
* Dispersion toggle
* Attempt capture fields

```
CarryDistance
TotalDistance
LeftDeviation
RightDeviation
```

* Add Shot workflow
* Dual submit buttons after attempt 3
* Progress tracking
* Club removal rules
* Session completion rules
* Environment metadata

```
MeasurementDevice
IndoorOutdoor
SurfaceType
```

---

# Remaining Sections

---

# Section 4 — Wedge Matrix Workflow

File

```
wedge-matrix-workflow.md
```

Purpose:

Defines the workflow for capturing **partial wedge distance matrices**.

Typical matrix structure:

```
Club × Swing Length
```

Example:

```
        7:30   9:00   10:30   Full
52°
56°
60°
```

Topics to define:

* Swing length model
* Matrix grid structure
* Attempt capture
* Shot ordering
* Progress tracking
* Completion rules
* Environment metadata

---

# Section 5 — Chipping Matrix Workflow

File

```
chipping-matrix-workflow.md
```

Purpose:

Defines matrix workflows for **short-game distance control**.

Example structure:

```
Club × Target Distance
```

Example:

```
        5y   10y   15y   20y
PW
SW
LW
```

Topics to define:

* Target distance model
* Club selection
* Measurement model
* Attempt capture
* Completion rules

---

# Section 6 — Matrix Runtime Model

File

```
matrix-runtime-model.md
```

Purpose:

Defines the **runtime lifecycle objects** introduced by matrices.

Entities:

```
MatrixRun
MatrixCell
MatrixAttempt
```

Topics to define:

* entity structure
* lifecycle rules
* editing behaviour
* deletion behaviour
* deterministic recalculation rules
* run states

```
InProgress
Completed
```

---

# Section 7 — Matrix Review Pages

File

```
matrix-review-pages.md
```

Purpose:

Defines how matrices appear in **Review**.

Includes:

* Gapping chart visualisation
* Wedge matrix grid
* Chipping matrix results
* historical comparisons
* dispersion analysis

---

# Section 8 — Data Model Extensions

File

```
matrix-data-model.md
```

Purpose:

Defines changes to the canonical **Section 6 Data Model**.

Includes:

* MatrixRun schema
* MatrixCell schema
* MatrixAttempt schema
* PerformanceSnapshot integration
* Calendar Slot extension

```
MatrixType
CompletingMatrixRunID
```

---

# Section 9 — Analytics Integration

File

```
matrix-analytics.md
```

Purpose:

Defines how matrix datasets interact with **Review analytics**.

Includes:

* club carry trends
* wedge distance consistency
* dispersion modelling
* practice planning insights
* snapshot lineage

---

# Final Deliverables

When complete the Matrix system will produce the following specification set:

```
matrix-system-overview.md
matrix-homepage.md
gapping-chart-workflow.md
wedge-matrix-workflow.md
chipping-matrix-workflow.md
matrix-runtime-model.md
matrix-review-pages.md
matrix-data-model.md
matrix-analytics.md
```

---

# Remaining Build Order

Recommended completion order:

1. Wedge Matrix Workflow
2. Chipping Matrix Workflow
3. Matrix Runtime Model
4. Matrix Review Pages
5. Data Model Extensions
6. Analytics Integration
