# ZX Golf App — Matrix & Gapping System
# Combined Spec Review — Issues and Questions

**Version:** 1v.a1
**Status:** Draft — Pre-Engineering Review
**Scope:** Sections 1–9 of the Matrix & Gapping System specification set

---

## Overview

This document consolidates all identified weaknesses, contradictions, gaps, and open questions across the Matrix & Gapping System specification set. Issues are grouped by category and ordered by severity within each group.

These issues should be resolved before engineering begins.

---

## 1. Critical — Direct Contradictions

These are places where two or more sections of the spec directly conflict. They represent the highest risk of incorrect implementation.

---

### 1.1 Cell and Club Removal: Hard Delete vs Soft Exclusion

**Sections:** 3.3.3, 3.11.2, 4.5.2, 4.14.2, 5.4.2 vs 6.8

Sections 3, 4, and 5 consistently describe removing a club or cell mid-session as discarding the `MatrixCell` and all associated `MatrixAttempt` records. Section 6.8 explicitly defines the cell exclusion model as soft exclusion only (`ExcludedFromRun = true`) and states cells are "never hard-deleted."

These are a direct contradiction. The runtime model must govern, which means the workflow sections are wrong as written.

Beyond the contradiction, the hard-delete behaviour described in the workflow sections is also poor UX. A user who records four attempts on a club and then removes it should not lose that data. The `ExcludedFromRun` field already exists precisely to handle this case. Hard deletion is unnecessary.

**Resolution required:** All workflow sections should be updated to use soft exclusion. The data is retained; the cell is hidden from the session UI and excluded from completion validation and analytics.

---

### 1.2 Dispersion Fields: Four Axes in Section 1, Two in Implementation

**Sections:** X.14 vs 3, 6, 8

Section X.14 defines four dispersion axes: Left deviation, Right deviation, Long deviation, Short deviation. The Gapping Chart workflow (Section 3), the runtime model (Section 6), and the data model (Section 8) implement only Left and Right deviation. Long and Short deviation fields do not appear in the `MatrixAttempt` schema.

Either Section X.14 is aspirational and the two-axis model is the intended V1 scope, or Section 8 is missing two fields. As written, the overview contradicts the data model.

**Resolution required:** Confirm whether Long/Short deviation is in scope for V1. If not, Section X.14 must be updated. If yes, the data model and workflow sections must be extended.

---

### 1.3 Rollout Field: Section 7 Adds It but Section 5 Entry UI Never Captures It

**Sections:** 5.12 vs 7.8.2, 7.9

Section 7.8.2 introduces `RolloutDistanceMeters` as a dedicated attempt field for the Chipping Matrix, adds a three-field validity rule, and includes a note in Section 7.9 that it supersedes the Section 5.16 data model. However, Section 5.12 (the attempt entry UI) is never updated — it still shows only Carry Distance and Total Distance with no rollout input field.

As written, the player has no mechanism to enter rollout data during a session, despite it being present in the data model.

**Resolution required:** Section 5.12 must be updated to include a Rollout Distance field and reflect the updated validity rule.

---

### 1.4 Workflow-Level Data Models Conflict with the Generic Runtime Model

**Sections:** 4.15, 5.16 vs 6, 8

The Wedge Matrix (Section 4.15) and Chipping Matrix (Section 5.16) data model summaries define flat, type-specific `MatrixRun` structures with direct fields such as `AxisAName`, `AxisBName`, `AxisACheckpoints[]`. Sections 6 and 8 define a fully normalised, workflow-agnostic model using separate `MatrixAxis` and `MatrixAxisValue` entities.

These cannot both be correct. The Sections 4 and 5 summaries appear to be earlier drafts that were not reconciled with the generic runtime model.

**Resolution required:** The Section 4.15 and 5.16 data model summaries should be replaced with references to the canonical model defined in Sections 6 and 8.

---

### 1.5 MatrixRun Created on Card Tap vs on Setup Completion

**Sections:** 2.5.3 vs 6.6

The flow diagram in Section 2.5.3 shows `ActiveExecution = MatrixRun (new)` as an immediate result of tapping a Start Matrix card. Section 6.6 correctly shows the run is not created until after the setup screen is completed.

A user who taps a card and then abandons the setup screen should not have an `InProgress` MatrixRun created. The Section 2.5.3 diagram misrepresents the lifecycle.

**Resolution required:** The Section 2.5.3 diagram should be corrected to show run creation occurring after setup completion, not on card tap.

---

### 1.6 Gap Threshold Defaults Are Internally Inconsistent

**Sections:** 7.5.1, 7.4 decision log vs 7.5.4, 9.10.3

Section 7.5.1 states the default minimum gap threshold is 6 units. The decision log (7.4) confirms 6 and 20 as defaults. However, the visual example in Section 7.5.4 shows "Small gap (7y — min: 10y)", and the analytics insight example in Section 9.10.3 uses "below your minimum of 10y." The examples contradict the stated defaults.

**Resolution required:** Standardise the default minimum threshold to a single value across all sections. Update examples to match.

---

## 2. Significant — Architectural and Data Model Risks

---

### 2.1 Parallel Runtime: Duplicated Infrastructure

**Section:** X.2

The decision to build a separate matrix runtime (rather than reusing the drill architecture) is correctly flagged in Section X.2 as requiring explicit technical review before implementation. This review is not documented as resolved.

The risk is concrete. By introducing a parallel runtime, the system duplicates:

- Session lifecycle management
- Attempt recording and editing
- Sync logic
- Offline recovery and conflict resolution

This is a long-term maintenance cost. The question is not whether matrices should use the drill scoring engine — they should not — but whether the attempt capture infrastructure (timestamps, edits, sync, offline reconciliation) can be shared.

**Resolution required:** A documented architectural decision must exist before engineering begins. The decision must explain whether a shared capture foundation is used or why a fully separate one is justified.

---

### 2.2 AxisValueIDs Stored as Array — Referential Integrity and Query Risk

**Section:** 8.4

The decision to store cell axis membership as an `AxisValueIDs` array avoids a join table but introduces meaningful risks:

- Querying is harder. Finding all cells where `Effort = 70%` requires an array contains query rather than a simple relational join.
- Referential integrity cannot be enforced by the database. There is no foreign key preventing an `AxisValueID` from referencing a value in a different `MatrixRun`.
- The correctness of the array depends on `AxisOrder` remaining stable, which it does given axis immutability — but this is a fragile implicit assumption.

The alternative join table model is more verbose but safer:

```
MatrixCellAxisValue
─────────────────────
MatrixCellID
AxisValueID
AxisOrder
```

**Resolution required:** Confirm whether the array approach is accepted with documented trade-offs, or whether a join table should be used.

---

### 2.3 Club Identity Stored as String, Not as ClubID Reference

**Sections:** 3, 4, 5, 6, 8

Across the workflow and data model sections, clubs are represented as `AxisType = Club` with labels like `"56°"` or `"7i"`. There is no reference to `ClubID` from the bag configuration system.

If clubs are stored as strings, equipment changes break historical integrity. A player who regrips and relofts a club, or who renames it in their bag, will produce orphaned historical data with no traceability back to the physical club.

**Resolution required:** Confirm whether `MatrixAxisValue` for Club-type axes should reference `ClubID` from the bag system, or whether string storage with a snapshot-style approach is acceptable.

---

### 2.4 No Explicit AttemptCount Field

**Sections:** 6.9, 9.3, throughout

Attempt count is used heavily in completion validation, progress indicators, and analytics eligibility, but it is always derived from `COUNT(MatrixAttempt)`. At scale, this query will be executed frequently — potentially on every shot entry.

**Resolution required:** Confirm whether `AttemptCount` should be a cached/denormalised field on `MatrixCell`, or whether the query cost is considered acceptable.

---

### 2.5 Single ActiveExecution Constraint May Not Reflect Real Behaviour

**Section:** 2.5, 6.6

The system enforces strict mutual exclusivity between `PracticeBlock` and `MatrixRun`. Only one may exist at a time.

This is a UX simplification, but it forces a player who wants to measure a wedge distance during a practice session to end the practice block first. That behaviour may not reflect how players actually work on a range.

A separate-state model may be more appropriate:

```
ActivePracticeBlock  (0–1)
ActiveMatrixRun      (0–1)
```

This is an architectural decision, not just a UX one, and should be confirmed before the floating resume control and homepage disable states are built.

**Resolution required:** Confirm whether mutual exclusivity is a deliberate product constraint or a simplification that should be revisited.

---

### 2.6 Analytics Query Cost Grows Without Bound

**Sections:** 2.6.4, 9.2

History depth is explicitly unlimited. Analytics operate across all completed runs. Combined with the weighted decay formula, this means analytics queries grow in cost forever even as older runs approach zero weight.

The weight formula already handles this conceptually — old data has negligible influence — but the query still processes it.

**Resolution required:** Confirm whether an analytics exclusion window (e.g. runs older than 5 years excluded from analytics calculations, but retained in history) should be introduced.

---

## 3. Workflow Logic Gaps

---

### 3.1 Minimum Attempts vs Session Shot Target: Psychological Mismatch

**Sections:** 3.4.4, 4.7.3, 5.7.3

The system distinguishes a hard minimum (3 attempts per cell) from a session shot target (default 5). The target controls progress indicators only; completion is governed by the hard minimum.

This creates a UX tension. A player looking at a progress bar showing 3/5 will likely feel the session is incomplete, even though the system will allow them to finish. The spec does not explain this distinction to the user at any point in the UI.

**Resolution required:** Either the completion rule should be tied to the session target, or the UI should explicitly surface both the minimum threshold (for completion eligibility) and the recommended target (for data quality).

---

### 3.2 Unlimited Carry Distance Checkpoints Can Create Impractical Sessions

**Section:** 5.5.3

The Chipping Matrix explicitly allows unlimited carry distance checkpoints. The Session Summary provides a shot estimate, but there is no hard guard against sessions becoming impractical.

Example: 3 clubs × 12 checkpoints × 3 flights × 5 shots = 540 minimum attempts. The spec relies on user judgement, but no guidance or soft warning is provided.

**Resolution required:** Confirm whether a hard upper limit on carry distance checkpoints is required (e.g. ≤ 15), or whether a soft warning at high session shot estimates is sufficient.

---

### 3.3 "Axis B Only" Configuration Is Listed but Underspecified

**Section:** 4.2.2

Section 4.2.2 lists "Club + Axis B only" (Axis A absent) as a valid configuration. It is not explained how the runtime model handles this. If `AxisOrder` is expected to sequence as 1 = Club, 2 = Axis A, 3 = Axis B, what happens when Axis A is absent? Does Axis B become AxisOrder 2? Does a gap at AxisOrder 2 cause issues?

The picklist structure, session summary formulae, and review visualisation behaviour for this configuration are undefined.

**Resolution required:** Clarify whether "Axis B only" is a truly supported configuration or whether it should be removed. If supported, the runtime model must specify how the axis ordering is handled.

---

### 3.4 Rollout / Carry / Total: No Derivation or Consistency Rule Defined

**Section:** 7.8.2

Section 7.8.2 states that `RolloutDistanceMeters` is stored as an independent field because "the user may not always record both." This means three fields exist with the mathematical relationship `Total = Carry + Rollout`, but any two or all three can be populated independently.

The spec does not define whether the system should auto-derive the missing third value when two are present, nor what happens when all three are entered but are internally inconsistent.

**Resolution required:** Define the derivation and consistency rules for the three Chipping attempt distance fields.

---

### 3.5 Multi-Run Comparison Only Defined for Gapping Chart

**Section:** 7.6

Section 7.6 defines a multi-run comparison feature for Gapping Charts (up to 3 runs). No equivalent feature is defined for Wedge Matrix or Chipping Matrix runs.

It is unclear whether this is a deliberate V1 scope decision. If intentional, it should be explicitly noted in Section 7 to prevent it being treated as an omission during development.

**Resolution required:** Confirm whether Wedge and Chipping multi-run comparison is out of scope for V1 and note this explicitly.

---

## 4. Analytics Issues

---

### 4.1 Outlier Trimming Produces Unreliable Results on Small Datasets

**Section:** 9.3.3

The outlier trimming rule removes the top and bottom 10% of attempts per cell. For a cell with only 5 attempts (the minimum at which trimming begins), this removes 1 attempt from each end, leaving 3 data points. Those 3 data points may exaggerate variance rather than reduce it.

A more robust rule would apply trimming only when the dataset is large enough to sustain it:

```
Apply 10% trim only when AttemptCount ≥ 8
Otherwise use raw dataset
```

**Resolution required:** Confirm the trimming policy for small datasets.

---

### 4.2 Weighting Formula Is Difficult to Reason About and Debug

**Section:** 9.4.2

The current decay formula is:

```
weight = exp(−2.25 × √(age_days / 365))
```

This is mathematically unusual. It is hard to explain to stakeholders, hard to tune, and harder to debug. Standard exponential decay is simpler:

```
weight = e^(−age_days / τ)
```

where `τ` is the half-life in days (e.g. `τ = 180` for a six-month half-life). The behaviour is easy to reason about: a run from six months ago contributes half as much as today's run.

**Resolution required:** Confirm whether the existing formula is intentional and if so, document the rationale. Consider replacing with standard exponential decay.

---

### 4.3 Coverage Gap Detection Threshold Is Undefined

**Section:** 9.7.4

Section 9.7.4 defines a coverage gap as a distance within the player's overall wedge range not reliably covered by any shot type within "a threshold distance." The threshold itself is never specified.

Without a concrete value, the algorithm cannot be implemented.

**Resolution required:** Define the coverage radius threshold (e.g. 3 yards). Confirm whether this should be user-configurable or system-defined.

---

### 4.4 Cross-Environment Analytics Mixing

**Sections:** 3.6, 9

Session metadata captures environment type (Indoor/Outdoor) and surface (Grass/Mat). However, analytics aggregate across all runs regardless of environment. Indoor launch monitor data and outdoor range estimation data will be mixed into the same derived averages.

This can produce meaningless or misleading analytics for players who use both environments.

At minimum, the analytics views should support filtering by environment.

**Resolution required:** Confirm whether environment-based analytics segmentation or filtering is required, and if so, in which sections it should be specified.

---

### 4.5 Gap Ordering by Carry Distance vs Bag Order

**Section:** 7.4.2

The Gapping Chart review page orders clubs by average carry distance. If a player hits their 7i shorter than their 8i in a given session, the ordering becomes:

```
7i — 158y
8i — 160y
```

This inversion will look incorrect to a player who expects clubs to appear in bag order.

A more useful model would sort clubs by bag order but calculate gap warnings using carry distance — making the gap warnings the signal for inversions rather than hiding them in the ordering.

**Resolution required:** Confirm whether ordering by carry or bag order is the correct approach, and document the rationale.

---

## 5. UX and Behavioural Ambiguities

---

### 5.1 Global Run Number May Not Match Player Mental Model

**Section:** 2.6.2

Run numbers are globally sequential across all matrix types. A player who has run 40 sessions will see references like "Run #38 — Wedge Matrix." Their mental model is more likely "my third Wedge Matrix run."

Consider whether a per-type display number is more useful:

```
Run #38 (internal)
Wedge Matrix — Run 3 (display)
```

**Resolution required:** Confirm whether global or per-type run numbering should be used for display purposes.

---

### 5.2 Floating Resume Control Scope Is Undefined

**Section:** 2.5.2

The spec states the floating resume control "appears across the application" while a `MatrixRun` is active. It does not specify whether this includes the Review tab, Settings, Club editing screens, or other contexts.

If it truly appears everywhere, it risks cluttering unrelated surfaces. If scoped to Track only, the spec should say so.

**Resolution required:** Define the exact surfaces on which the floating resume control appears.

---

### 5.3 Attempt Validity Rule Allows Analytics-Incompatible Attempts

**Sections:** 3.7.3, 4.11.3

The attempt validity rule accepts an attempt if any single field is populated. This permits:

```
LeftDeviation = 5
CarryDistance = null
```

An attempt with no carry distance contributes nothing to the core analytics and may produce misleading derived values.

Carry distance should arguably be mandatory, with all other fields optional. This is the primary measurement the entire system is built around.

**Resolution required:** Confirm whether carry distance should be a required field, with all other measurements optional.

---

## 6. Documentation Consistency

---

### 6.1 Section Numbering: "Section X" vs "Section 1"

The System Overview document is titled Section X throughout, but all downstream sections declare `Depends on: Section 1 — Matrix & Gapping System Overview.` This is inconsistent and will cause confusion when the spec is handed to engineers.

---

### 6.2 "Finish Matrix" vs "Finish Session" Terminology

Section X.6 uses "Finish Matrix." Sections 3, 4, 5, and 6 consistently use "Finish Session." This should be standardised to one term.

---

### 6.3 Cross-Run Analytics with Mismatched Axis Names

**Sections:** 9.7, 9.8

Wedge Matrix axis labels are user-defined per run. If a player completes three Wedge Matrix runs using different axis names (e.g. "Effort" in one run, "Clock" in another), the analytics system aggregates across them with no resolution for the naming mismatch. The spec does not address this.

---

## 7. Summary of Key Questions

The following questions represent the most important unresolved decisions.

**Architecture**

- Are `MatrixAttempt` records stored through the same capture pipeline as `DrillAttempt` records (excluding the scoring engine)?
- Is the mutual exclusivity between `PracticeBlock` and `MatrixRun` a firm product decision, or should they be permitted to coexist?
- Should analytics exclude runs older than a defined threshold (e.g. 5 years)?

**Data Model**

- Should `MatrixAxisValue` for Club-type axes reference `ClubID` rather than a string label?
- Should axis membership use a join table (`MatrixCellAxisValue`) rather than an `AxisValueIDs` array?
- Should `AttemptCount` be cached on `MatrixCell`?

**Workflow**

- Should club/cell removal use soft exclusion (consistent with Section 6.8) rather than hard deletion?
- Should session completion require `SessionShotTarget` to be met, or only the hard minimum of 3?
- Should carry distance be a mandatory field for attempt validity?

**Analytics**

- What is the coverage gap threshold used in wedge coverage analytics?
- Should the weighting formula be replaced with standard exponential decay?
- Should analytics be segmentable by environment (Indoor vs Outdoor)?

---

*End of Combined Spec Review*
