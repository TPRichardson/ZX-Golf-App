
# Section X — Matrix & Gapping System Architecture
Version 1v.a1 — Draft

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

# X.1 System Purpose

The Matrix & Gapping system exists to build and maintain a **reference dataset describing the player's real-world shot distances**.

Matrices are not training drills. They are **measurement workflows** designed to capture reliable calibration data.

The primary purposes are:

1. Build a **reference dataset of club distances**
2. Help players understand **distance control patterns**
3. Provide a **decision-support reference during play**

Matrices therefore answer a different question from drills.

Drills → “How well did I execute?”  
Matrices → “What does my shot actually do?”

Matrices provide the empirical data that defines the player's **personal yardage model**.

---

# X.2 System Position Within ZX

Matrices operate as a **separate tracking subsystem** parallel to the Drill system.

They share the **Track surface** but do not reuse the Drill runtime architecture.

Track
 ├ Drills
 └ Matrices & Gapping

### Key Architectural Separation

Matrices are **not implemented as drills**.

They do not generate:

- Drill Sessions
- Sets
- Instances
- Subskill window entries
- 0–5 scoring events

This separation protects the integrity of the **scoring engine**, which is designed exclusively for performance evaluation.

---

# X.3 Matrix Types

The system launches with **three fixed matrix workflows**.

These workflows are system-defined and **not user-configurable templates**.

### Supported Matrix Types

1. **Gapping Chart**
   Measures carry distance for clubs in the user's bag.
   Optionally captures dispersion data during the same workflow.

2. **Wedge Matrix**
   Measures distance produced by partial wedge swings.
   Typical structure: Club × Swing Length

3. **Chipping Matrix**
   Measures distance behaviour around the green.
   Typical structure: Club × Target Distance

The architecture allows future matrix types to be added, but users cannot create custom matrix structures.

---

# X.4 Matrix Runtime Model

Matrices introduce a runtime hierarchy separate from drills.

MatrixRun
 └ MatrixCell
      └ MatrixAttempt

### MatrixRun

Represents one execution of a matrix workflow.

Examples:
- Wedge Matrix — 2026-03-01
- Wedge Matrix — 2026-06-15

A MatrixRun contains multiple MatrixCells.

### MatrixCell

Represents a **measurement unit** within the matrix.

Examples:
- Wedge Matrix: 56° × 50% Swing
- Chipping Matrix: PW × 10 yards

Each cell contains multiple attempts.

### MatrixAttempt

Represents a single recorded shot.

Attempts store the **raw measurement data** used to derive averages and dispersion metrics.

---

# X.5 Attempt Capture Model

Matrix workflows record **every individual shot attempt**.

Attempts are not aggregated at entry time.

Example:

MatrixCell
 └ MatrixAttempts
      • Distance = 84y
      • Distance = 82y
      • Distance = 86y

Aggregated values such as:

- average distance
- variance
- dispersion

are **derived values** calculated from stored attempts.

This design allows recalculation if attempts are edited later.

---

# X.6 Minimum Attempt Requirement

All matrix measurements require a **minimum of three attempts**.

| Matrix Type | Measurement Unit |
|-------------|------------------|
| Gapping Chart | Club |
| Wedge Matrix | Club × Swing Length |
| Chipping Matrix | Club × Target Distance |

Users may record **additional attempts beyond the minimum**.

---

# X.7 Matrix Run Lifecycle

Matrix runs follow a simple manual lifecycle.

States:

- InProgress
- Completed

Execution Flow:

Start Matrix → MatrixAttempts logged → Minimum attempts satisfied → User presses Finish Matrix → Run completed

---

# X.8 Incomplete Run Behaviour

Matrix runs are **never discarded automatically by the system**.

If a user exits early the run remains **InProgress** and can be resumed later.

Users may:

- Resume the run
- Discard the run manually

Only **Completed MatrixRuns** contribute to analytical calculations.

---

# X.9 Editing Behaviour

Users may edit MatrixAttempts **after completion**.

When an attempt is edited:

MatrixAttempt edited → MatrixCell recalculated → MatrixRun aggregates updated → Reference dataset recalculated

Structural elements of the run cannot be edited.

---

# X.10 Session Duration Tracking

Each MatrixRun records:

- StartTimestamp
- EndTimestamp
- Duration

Duration = EndTimestamp − StartTimestamp

Duration has **no scoring impact** but may appear in analytics.

---

# X.11 Versioning & Historical Runs

Matrices are **versioned through repeated runs**.

Example:

Wedge Matrix
 ├ Run — 2026-03-01
 ├ Run — 2026-06-15
 └ Run — 2026-09-10

Historical runs are permanently preserved.

---

# X.12 Reference Dataset Model

The system maintains a **current reference dataset** derived from historical MatrixRuns.

Reference Value = WeightedAverage(MatrixRuns)

More recent runs receive greater weight.

---

# X.13 Integration with Club Performance Profiles

Matrix datasets may update the **ClubPerformanceProfile**.

Possible sources:

ClubPerformanceProfile
 ├ System estimated values
 ├ Matrix-derived values
 └ User overrides

User overrides always take precedence.

---

# X.14 Optional Dispersion Capture

The **Gapping Chart workflow optionally captures dispersion**.

Possible measurements:

- Left / Right deviation
- Long / Short deviation

Dispersion capture is optional.

---

# X.15 Calendar Integration

Matrices can be scheduled within the **Plan → Calendar system**.

CalendarDay
 ├ Slot — Drill
 └ Slot — Wedge Matrix

Execution paths:

Drill Slot → PracticeBlock → Session → Set → Instance  
Matrix Slot → MatrixRun → MatrixCell → MatrixAttempt

---

# X.16 Relationship to the Scoring Engine

Matrices are **fully isolated from the scoring engine**.

They do not generate:

- 0–5 scores
- window entries
- Skill Area scores
- Overall Score changes

Matrices exist purely as **reference dataset generators**.

---

# X.17 Architectural Guarantees

The Matrix system guarantees:

- Isolation from the scoring engine
- Preservation of historical runs
- Deterministic recalculation of derived values
- Editable attempt-level data
- Measurement integrity via minimum attempts
- User control over reference datasets
- Separation between **training (drills)** and **measurement (matrices)**
