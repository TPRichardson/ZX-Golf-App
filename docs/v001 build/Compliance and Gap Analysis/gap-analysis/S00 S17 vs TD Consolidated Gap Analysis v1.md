# Consolidated Gap Analysis: S00–S17 vs TD Reference Catalogue

> Full specification suite (S00 through S17) compared against all 8 Technical Design documents (TD-01 through TD-08).
> Consolidated from Batches 2A–2F.

---

## Methodology

For each specification section, every distinct rule, entity, constraint, and definition is checked against the TD Reference Catalogue. Items are classified as:

- **Covered** — TD documents explicitly address or implement the spec item.
- **Gap** — Spec defines something with no corresponding TD coverage.
- **Conflict** — Spec and TD define the same item differently.
- **TD-Only** — TD introduces something not present in the spec documents under review.

---

## S00 — Canonical Terminology & Definitions (0v.f1)

### S00 Section 1: Scoring Hierarchy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Overall Score = 1000 max, sum of all Skill Area scores | TD-05 TC-9.1.3 (perfect 1000), TD-03 scoring chain | Covered | |
| Overall Score always displayed against full 1000-point scale | TD-06 Phase 6 acceptance (zero state), TD-07 §12 graceful degradation | Covered | |
| 7 Skill Areas with fixed allocations (280/240/200/100/100/50/30) | TD-02 SubskillRef seed data (19 rows summing to 1000), TD-05 reference data | Covered | |
| Skill Area is the sole term for the seven disciplines | No TD reference to alternative terminology | Covered | Implicit — no TD introduces a conflicting term |
| Subskill: measurable component with fixed allocation | TD-02 SubskillRef table, TD-05 allocation values | Covered | |
| Subskill Points = Allocation x (WeightedAverage / 5) | TD-03 §4 reflow algorithm, TD-05 TC-7.x series | Covered | |

### S00 Section 2: Windows & Occupancy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Window: rolling container at Subskill level, two per subskill (Transition 25, Pressure 25) | TD-01 window size constant, TD-02 MaterialisedWindowState, TD-05 TC-6.x | Covered | |
| Window size fixed at 25 occupancy units, not user-configurable | TD-01 scale assumptions, TD-02 constraints | Covered | |
| Occupancy: 1.0 single-mapped, 0.5 dual-mapped, minimum 0.5 | TD-03 §4, TD-05 TC-6.4/6.5/6.6 | Covered | |
| Entry: scored Session inserted into window, ordered by Completion Timestamp | TD-01 window composition ORDER BY, TD-05 TC-6.8.1 tiebreaker | Covered | |
| Window Average = Sum(score x occupancy) / total occupancy | TD-05 TC-6.x, TD-03 §4 | Covered | |
| Weighted Average = (Transition x 0.35) + (Pressure x 0.65) | TD-03 §4, TD-05 TC-7.x | Covered | |
| Roll-Off: FIFO by Completion Timestamp, 0.5 increments, 1.0->0.5 preserves score | TD-05 TC-6.7.1/6.7.2/6.7.3, TD-03 §4 | Covered | |

### S00 Section 3: Scoring Anchors

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Min maps to 0, Scratch maps to 3.5, Pro maps to 5 (capped) | TD-05 TC-4.x, scoring formula reference data | Covered | |
| Two-segment linear interpolation: Min-Scratch (0-3.5), Scratch-Pro (3.5-5) | TD-05 formula definition, TD-03 §4 | Covered | |
| No nonlinear curves, sigmoid, asymptotic ceilings | Implicit in TD-05 test case structure | Covered | |

### S00 Section 4: Runtime Hierarchy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Hierarchy: Drill -> Routine -> PracticeBlock -> Session -> Set -> Instance | TD-02 table hierarchy, TD-04 state machines | Covered | |
| Drill: permanent definition object with listed fields | TD-02 Drills table DDL, TD-04 Drill state machine | Covered | |
| Drill fields: Skill Area, Subskill mapping, Anchors, Scoring Mode, Drill Type, Input Mode, Metric Schema, Target Definition, Club Selection Mode, RequiredSetCount, RequiredAttemptsPerSet | TD-02 Drills table columns | Covered | |
| Routine: blueprint of ordered entries (fixed or generated), template linkage severed after creation | TD-02 Routine table, TD-04 Routine state machine | Covered | |
| Empty Routines auto-deleted when referenced Drill deleted/retired | TD-04 Routine state machine | Covered | |
| PracticeBlock: execution container, auto-ends after 4h | TD-04 PracticeBlock state machine, TD-06 Phase 4 | Covered | |
| PracticeBlock persisted only if >= 1 Session exists | TD-04 PracticeBlock state machine | Covered | |
| Session: runtime execution of one Drill, score = simple average of all Instance 0-5 scores | TD-05 TC-5.x, TD-04 Session state machine | Covered | |
| Set: sequential attempt container, strictly sequential, not independent scoring unit | TD-02 Sets table, TD-05 TC-5.3.1 multi-set averaging | Covered | |
| Instance: atomic attempt with raw metrics, selected club, timestamp, derived score | TD-02 Instance table, TD-05 TC-4.x | Covered | |
| SelectedClub stored on every Instance | TD-02 Instance.ClubID, S00 explicit statement | Covered | |
| Instance editable without affecting chronological ordering | TD-05 TC-11.1.7 | Covered | |

### S00 Section 5: Drill Classification

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Technique Block: non-scored, no subskill mapping, no window entry, no anchors, open-ended only | TD-02 MaterialisedWindowState.PracticeType constraint, TD-05 TC-11.1.1 | Covered | |
| Transition: enters Transition window (35%) | TD-05 test cases, TD-03 §4 | Covered | |
| Pressure: enters Pressure window (65%) | TD-05 test cases, TD-03 §4 | Covered | |
| Shared Mode: one score, one anchor set, 0.5 occupancy if dual-mapped | TD-05 TC-6.4/6.5, TD-03 payload shapes | Covered | |
| Multi-Output Mode: two subskills, two independent scores, two anchor sets, 0.5 each | TD-05 TC-12.x, TD-03 payload shapes | Covered | |
| Grid Cell Selection input mode | TD-02 MetricSchema seed (grid_1x3, grid_3x1, grid_3x3), TD-05 TC-4.1.x | Covered | |
| Continuous Measurement input mode | TD-02 MetricSchema seed (raw_carry_distance), TD-05 deferred test note | Covered | |
| Raw Data Entry input mode | TD-02 MetricSchema seed (raw_ball_speed, raw_club_head_speed), TD-05 TC-4.3/4.4 | Covered | |
| Binary Hit/Miss input mode | TD-02 MetricSchema seed (binary_hit_miss), TD-05 TC-4.5.x | Covered | |
| Binary Hit/Miss excluded from integrity detection | TD-07 Phase 4 error handling, S11 reference | Covered | |
| System Drill: centrally governed, anchors immutable to users | TD-02 seed data (28 drills), TD-04 Drill state machine | Covered | |
| User Custom Drill: user-created, anchors editable (triggers reflow) | TD-04 Drill state machine, TD-03 DrillRepository | Covered | |
| Immutable post-creation fields listed | TD-03 structural immutability guard, TD-04 Drill state machine | Covered | |
| Drill Duplication: new DrillID, Origin=UserCustom, all structural fields copied | TD-03 DrillRepository.createCustomDrill() | Covered | |

### S00 Section 6: Grid Scoring Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 3x3 Grid (Multi-Output): direction hit = center column, distance hit = middle row | TD-05 TC-4.1.x, TD-02 MetricSchema grid_3x3_multioutput | Covered | |
| 1x3 Grid (Direction Only, Shared Mode) | TD-02 MetricSchema grid_1x3_direction | Covered | |
| 3x1 Grid (Distance Only, Shared Mode) | TD-02 MetricSchema grid_3x1_distance | Covered | |
| Grid scoring metric = hit-rate percentage through anchors | TD-05 TC-4.1.x | Covered | |
| 3x3 Multi-Output: each subskill hit-rate independent, scored against own anchors | TD-05 TC-12.x | Covered | |

### S00 Section 7: Target Definition

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Target Distance: Fixed, Club Carry, Percentage of Club Carry | TD-02 Drills table columns (TargetDistanceMode, etc.) | Covered | |
| Club Carry/Percentage modes greyed out until carry distances entered | TD-06 Phase 4 (UI behaviour) | Covered | Implicit in UI implementation |
| Target Size: Fixed or Percentage of Target Distance | TD-02 Drills table columns (TargetSizeWidth, TargetSizeDepth) | Covered | |
| Grid type determines required dimensions (3x3: both, 1x3: width, 3x1: depth) | TD-02 §3.5 target size columns | Covered | |

### S00 Section 8: Club Selection

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| SelectedClub stored on every Instance, per shot | TD-02 Instance.ClubID | Covered | |
| Club Selection Mode: Random, Guided, User Led (default) | TD-02 Drills.ClubSelectionMode column | Covered | |
| Random: system selects, user cannot override | TD-06 Phase 4 | Covered | |
| Guided: system suggests, user may override | TD-06 Phase 4 | Covered | |
| User Led: user selects (default) | TD-06 Phase 4 | Covered | |
| Auto-select if Skill Area has only one eligible club | TD-06 Phase 4 (implicit in UI) | Covered | |

### S00 Section 9: Drill Lifecycle States

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Active: available for new Sessions | TD-04 Drill state machine | Covered | |
| Retired: hidden, historical retained, roll off naturally | TD-04 Drill state machine, TD-05 reflow tests | Covered | |
| Deleted: permanently removed, all Sessions/Sets/Instances removed, reflow triggered | TD-04 Drill state machine, TD-03 DrillRepository | Covered | |

### S00 Section 10: Session Lifecycle States

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Active: in progress | TD-04 Session state machine | Covered | |
| Closed: ended (manual, structured, auto-close), window entry inserted | TD-04 Session state machine | Covered | |
| Discarded: hard-deleted, no scoring impact | TD-04 Session state machine | Covered | |
| Incomplete: structured drill, not all Sets complete, must complete or discard | TD-04 Session state machine | Covered | S00 defines "Incomplete" as a conceptual state |
| Completion Timestamp semantics (structured/manual/auto-close) | TD-04 Session state machine, TD-01 | Covered | |

### S00 Section 11: Set Structure

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| RequiredSetCount >= 1 | TD-02 Drills table CHECK constraint | Covered | |
| RequiredAttemptsPerSet >= 1 or null | TD-02 Drills table | Covered | |
| Structured Drill: auto-closes on final Instance of final Set | TD-04 Session structured completion | Covered | |
| Unstructured Drill: RequiredSetCount=1, RequiredAttemptsPerSet=null, manual End | TD-04 Session unstructured completion | Covered | |
| Set structure does not affect scoring calculation | TD-05 TC-5.x (flat average across Sets) | Covered | |
| Single Instance valid for scoring in unstructured drills | TD-05 TC-5.4.1 | Covered | |
| Technique Block drills always unstructured | TD-02 Drill constraints, S00 §5 | Covered | |
| Post-Close Editing: structured Instance value editable, Instance/Set deletion prohibited | TD-04 Session state machine guards | Covered | |
| Post-Close Editing: unstructured Instance editable/deletable, last Instance deletion auto-discards | TD-04 Session state machine, TD-05 TC-11.1.6 | Covered | |
| All post-close edits trigger reflow | TD-04 reflow trigger catalogue | Covered | |
| Immutable post-creation fields: SubskillMapping, MetricSchema, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ClubSelectionMode, TargetDefinition | TD-03 structural immutability guard, TD-04 Drill state machine | Covered | |
| ClubSelectionMode listed as immutable post-creation | TD-03 structural immutability guard | **Conflict** | S00 §11 lists ClubSelectionMode as immutable; TD-03 §5.3 immutability guard lists: SubskillMapping, MetricSchemaID, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ScoringMode, InputMode. ClubSelectionMode is absent from TD-03's guard list. TD-04 similarly omits it. ScoringMode and InputMode appear in TD lists but not in S00 §11. |
| ScoringMode not listed as immutable in S00 §11 | TD-03 includes ScoringMode in immutability guard | **Conflict** | S00 §11 omits ScoringMode from its immutable list. TD-03 and TD-04 include it. |
| InputMode not listed as immutable in S00 §11 | TD-03 includes InputMode in immutability guard | **Conflict** | S00 §11 omits InputMode from its immutable list. TD-03 and TD-04 include it. |

### S00 Section 12: Data Integrity & Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Reflow: full historical recalculation triggered by structural parameter changes | TD-04 reflow algorithm, TD-03 §4 | Covered | |
| Reflow executes as background process, UI shows loading state | TD-06 Phase 2B, TD-04 | Covered | |
| User-initiated triggers: Drill anchor edits (User Custom only) | TD-04 reflow trigger catalogue | Covered | |
| System-initiated triggers: allocation edits, weighting edits, formula edits, System Drill anchor edits | TD-04 reflow trigger catalogue | Covered | |
| Window size is not a reflow trigger | TD-04 non-reflow triggers list | Covered | |
| Deterministic, Recalculable, Canonical, Harmonised definitions | Implicit in TD-05 convergence tests | Covered | |

### S00 Section 13: Planning Layer Terms

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Calendar: single persistent object per user | TD-02 CalendarDay table (per-day entities) | Covered | S00 defines Calendar as concept; TD-02 implements via CalendarDay rows |
| CalendarDay: date with SlotCapacity and ordered Slots list | TD-02 CalendarDay table, TD-03 CalendarDay Slots payload shape | Covered | |
| CalendarDay sparse storage with default fallback | TD-06 Phase 5 | Covered | |
| Slot: position within CalendarDay, 1:1 with Drills | TD-03 Slot payload shape, TD-04 CalendarDay Slot state machine | Covered | |
| Slot fields: DrillID, OwnerType, OwnerID, CompletionState, CompletingSessionID, Planned flag | TD-03 CalendarDay Slots payload shape | Covered | |
| SlotCapacity: user-configurable day-of-week pattern, default 5 | TD-06 Phase 5, Phase 8 (calendar defaults screen) | Covered | |
| Routine: reusable ordered list of entries (fixed or generation criteria) | TD-02 Routine table, TD-03 Routine entries payload shape | Covered | |
| Schedule: multi-day blueprint, List or Day Planning modes | TD-02 Schedule table, TD-06 Phase 5 | Covered | |
| Generation Criterion: Skill Area (optional), Drill Type (required, multi-select), Subskill (optional), Generation Mode (Weakest/Strength/Novelty/Random) | TD-03 Routine entries payload shape (criterion object) | Covered | |
| RoutineInstance and ScheduleInstance: created on apply, support unapply | TD-02 tables, TD-04 state machines | Covered | |
| Slot Ownership: OwnerType (Manual/RoutineInstance/ScheduleInstance) | TD-03 Slot payload shape | Covered | |
| Completion Matching: source-agnostic, date-strict, first-match ordering | TD-06 Phase 5, TD-03 post-merge pipeline | Covered | |
| Completion Overflow: auto-create Slot, increase SlotCapacity, Planned=false | TD-06 Phase 5 | Covered | |
| Plan Adherence: (Completed planned / Total planned) x 100, overflow excluded | TD-06 Phase 6 (plan adherence screen) | Covered | |
| WeaknessIndex: (5 - WeightedAverage) x (SubskillAllocation / 1000) | TD-06 Phase 5 (weakness detection) | Covered | |

### S00 Section 14: Metrics Integrity Terms

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| IntegrityFlag: boolean on Session, true if Instance outside HardMin/HardMax | TD-02 Session.IntegrityFlag, TD-07 Phase 4 | Covered | |
| IntegrityFlag state-derived, auto-resolves, no scoring impact | TD-05 TC-11.1.5, TD-07 | Covered | |
| IntegritySuppressed: boolean on Session, manual clear, resets on Instance edit | TD-02 Session.IntegritySuppressed, TD-06 Phase 8 | Covered | |
| HardMinInput / HardMaxInput: system-defined on MetricSchema, immutable | TD-02 MetricSchema table | Covered | |
| IntegrityFlagRaised / Cleared / AutoResolved EventLog event types | TD-02 EventTypeRef seed data | Covered | |

### S00 Section 15: Real-World Application Layer Terms

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| DeviceID: UUID per device, registered on first server connection | TD-02 UserDevice table, TD-01 sync transport | Covered | |
| UserDevice entity: DeviceID, UserID, device label, timestamps | TD-02 UserDevice table | Covered | |
| Last-Write-Wins (LWW) definition and scope | TD-01 conflict resolution, TD-03 merge algorithm | Covered | |
| LWW applies to: User Custom Drills, clubs, Routines, Schedules, CalendarDay Slots, Settings | TD-01 merge precedence table, TD-03 merge rules | Covered | |
| LWW does not apply to: execution data (additive merge), soft-delete flags (always propagate) | TD-01, TD-03 merge rules | Covered | |
| Deterministic Merge-and-Rebuild definition | TD-01 sync strategy, TD-03 pipeline | Covered | |
| Sync Pipeline 6 steps: Upload, Download, Merge, Completion Matching, Rebuild, Confirm | TD-01 pipeline, TD-03 §5 | Covered | |

---

---

## S01 — Scoring Engine (1v.g2)

### S01 Section 1.1: Core Principles

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Scoring engine is: Linear, Deterministic, Fully recalculable, Occupancy-weighted, Subskill-granular, Globally weighted (65/35) | TD-05 precision policy, TD-03 §4 reflow contract | Covered | |
| No time decay, smoothing, volatility dampening, outlier filtering, diversity enforcement, difficulty multipliers | Implicit in TD-05 test structure (no such adjustments tested) | Covered | |
| Scores change only when: new drills logged, old drills roll off, structural parameters edited | TD-04 reflow trigger catalogue, TD-04 non-reflow triggers | Covered | |
| One canonical scoring model at any time | TD-04 §3 reflow idempotency | Covered | |

### S01 Section 1.2: Overall Score Structure

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Total Score = 1000 | TD-05 TC-9.1.3, TD-02 SubskillRef seed | Covered | |
| Skill Area allocations (280/240/200/100/100/50/30) | TD-02 SubskillRef seed data, TD-05 reference data | Covered | |
| Allocations system-controlled, not user-editable | TD-04 non-reflow triggers note, TD-02 reference table design | Covered | |

### S01 Section 1.3: Subskill Allocations

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All 19 subskill allocations individually specified | TD-02 SubskillRef seed data (19 rows), TD-05 reference data | Covered | |
| Each Skill Area sum matches its allocation | TD-07 allocation invariant check (startup integrity) | Covered | |
| System-controlled, not user-editable | TD-02 reference table design | Covered | |

### S01 Section 1.4: Drill Scoring Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Every scored drill defines Min/Scratch/Pro per mapped subskill | TD-02 Drills.Anchors column, TD-03 Anchors payload | Covered | |
| Case 1: Below Min = 0 | TD-05 TC-4.1.1, TC-4.3.1 | Covered | |
| Case 2: Min to Scratch = 3.5 x (p-min)/(scratch-min) | TD-05 TC-4.x series | Covered | |
| Case 3: Scratch to Pro = 3.5 + 1.5 x (p-scratch)/(pro-scratch) | TD-05 TC-4.x series | Covered | |
| Case 4: Above Pro = 5 (capped) | TD-05 TC-4.1.7, TC-4.3.7 | Covered | |
| Score strictly capped at 5 | TD-05 TC-4.1.7 | Covered | |

### S01 Section 1.5: Drill Type Weighting

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Pressure 65%, Transition 35% | TD-03 §4, TD-05 TC-7.x | Covered | |
| Applied identically to every subskill | TD-05 TC-7.x across multiple subskills | Covered | |
| System-level constant, not configurable per skill/subskill/user | TD-04 scope determination (65/35 edit = all 19 subskills) | Covered | |

### S01 Sections 1.6-1.10: Windows, Occupancy, Roll-Off

All items in these sections duplicate S00 definitions and are fully covered by the same TD references noted in the S00 analysis above.

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All S01 §1.6-1.10 items | See S00 §2 analysis | Covered | No additional rules beyond S00 |

### S01 Section 1.11: Subskill Score Conversion

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| SubskillPoints = Allocation x (WeightedAverage / 5) | TD-05 TC-7.x, TD-03 §4 | Covered | |
| Unfilled occupancy contributes 0 | TD-05 TC-7.1.4 (both empty) | Covered | |
| Subskills contribute from first qualifying drill | TD-05 TC-9.1.2 (single subskill only) | Covered | |

### S01 Section 1.12-1.13: Skill Area Score, Overall Score

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Skill Area Score = sum of Subskill Points | TD-05 TC-8.x | Covered | |
| Overall Score = sum of all Skill Area Scores | TD-05 TC-9.x | Covered | |
| Always displayed against full 1000-point scale | TD-06 Phase 6 zero state | Covered | |
| No emotional framing of drops | TD-07 user-facing messaging (factual + actionable) | Covered | |

### S01 Section 1.14: Zero Baseline

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All subskills start at 0, all windows start empty | TD-05 TC-9.1.4 (zero no data) | Covered | |
| Empty capacity contributes 0, score builds upward | TD-05 TC-7.1.4 | Covered | |

### S01 Section 1.15: Reflow Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Structural parameter change triggers: full recalculation, window reprocessing, skill recomputation, overall recomputation, logged event, timeline annotation | TD-04 reflow algorithm (10 steps), TD-03 EventLog emission | Covered | |
| Reflow executes as background process, triggered immediately after edit | TD-04 §3, TD-06 Phase 2B | Covered | |
| UI displays loading state until complete | TD-06 Phase 2B acceptance | Covered | |
| Scores not available for display during reflow | TD-07 graceful degradation (scoring lock held) | Covered | |
| No on-read recalculation | Implicit in TD-04 reflow design (write-triggered only) | Covered | |
| User-initiated triggers: Drill anchor edits (User Custom only) | TD-04 reflow trigger catalogue | Covered | |
| System-initiated triggers: allocations, weighting, formula, System Drill anchors | TD-04 reflow trigger catalogue | Covered | |
| Window size not a reflow trigger | TD-04 non-reflow triggers list | Covered | |
| One canonical scoring model, no legacy branches | TD-04 reflow idempotency | Covered | |

### S01 Section 1.16: Ceiling Behaviour

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Score capped strictly at 5 per drill | TD-05 TC-4.1.7 | Covered | |
| No overperformance tracking | No TD reference | **Gap** | S01 explicitly states no overperformance tracking. No TD document addresses this as a constraint. Low risk — the cap at 5 inherently prevents it, but the explicit prohibition is uncodified in TD. |
| No automatic anchor adjustment | No TD reference | **Gap** | S01 explicitly states no automatic anchor adjustment. No TD document addresses this constraint. Low risk — no TD introduces auto-adjustment, but the prohibition is not explicitly stated. |
| Calibration edits are manual | Implicit in TD-04 (user-initiated anchor edits) | Covered | |

### S01 Section 1.17: Drill Retirement and Deletion

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Retirement vs Deletion are distinct with different scoring consequences | TD-04 Drill state machine | Covered | |
| Retired: hidden, historical retained, remain in windows, roll off naturally | TD-04 Drill state machine | Covered | |
| Retired: cannot be manually purged from scoring | No explicit TD reference | **Gap** | S01 states retired drills "cannot be manually purged from scoring." No TD document addresses a purge prohibition for retired drills. The TD-04 state machine transitions do not include a purge action, so this is implicitly enforced. |
| Deleted: permanently removed with all Sessions/Instances, full recalculation, irreversible | TD-04 Drill state machine, TD-04 reflow trigger | Covered | |

### S01 Section 1.18: System Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Deterministic outputs | TD-05 TC-10.5.1, TC-10.7.1 convergence | Covered | |
| Linear performance mapping | TD-05 formula definition | Covered | |
| Occupancy-weighted fairness | TD-05 TC-6.x | Covered | |
| No inflation from split drills | TD-05 TC-12.x (Multi-Output occupancy) | Covered | |
| No hidden smoothing | Implicit (no smoothing in any TD) | Covered | |
| Structural integrity across edits | TD-04 reflow algorithm | Covered | |
| Full recalculability | TD-04 full rebuild algorithm | Covered | |

---

---

## S02 — Skill Architecture & Weighting Framework (2v.f1)

### S02 Section 2.1: Canonical Skill Tree

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Full tree with all 19 subskills and their allocations | TD-02 SubskillRef seed data, TD-05 reference data | Covered | |
| Structural Guarantee 1: All Skill Areas sum to 1000 | TD-07 allocation invariant startup check | Covered | |
| Structural Guarantee 2: All Subskills sum to their Skill Area allocation | TD-07 allocation invariant startup check | Covered | |
| Structural Guarantee 3: Impossible to max Skill Area while ignoring Subskill | Inherent in formula (SubskillPoints proportional to WeightedAverage) | Covered | |
| Structural Guarantee 4: No redistribution for unused Subskills | TD-05 TC-8.1.2 (one empty subskill) | Covered | |
| Structural Guarantee 5: Skill Area selection determines mapping, clubs filtered from bag | TD-06 Phase 3 (bag configuration) | Covered | |

### S02 Section 2.2: Skill Area Definitions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| User selects Skill Area first, then club | TD-06 Phase 3 (drill creation flow) | Covered | |
| Eligible club types per Skill Area are user-configurable with mandatory minimums | TD-03 ClubRepository.updateSkillAreaMapping() | Covered | |
| Mandatory mappings: Driving->Driver, Irons->i1-i9, Putting->Putter | TD-02 seed data implied, TD-06 Phase 3 | Covered | |
| All other Skill Area mappings user-configurable | TD-03 ClubRepository | Covered | |
| Cross-Skill-Area mapping prohibited | TD-02 constraints, TD-03 validation | Covered | |

### S02 Section 2.3: Subskill Definitions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All 19 subskill descriptions (purpose/meaning of each) | No explicit TD reference | **Gap** | S02 provides descriptive definitions for each subskill (e.g., "Carry proximity and depth dispersion control" for Irons Distance Control). No TD document captures these semantic definitions. TD-02 seeds SubskillRef with IDs and allocations but not descriptions. This is a display/documentation concern, not a functional gap. |

### S02 Section 2.4: Subskill Allocation Mathematics

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| SubskillPoints = Allocation x (WeightedAverage / 5) | TD-05 TC-7.x, TD-03 §4 | Covered | |
| WeightedAverage = (TransitionAvg x 0.35) + (PressureAvg x 0.65) | TD-05 TC-7.x, TD-03 §4 | Covered | |
| No redistribution between subskills | TD-05 TC-8.1.2 | Covered | |

### S02 Section 2.5: Drill-to-Subskill Mapping Matrix

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Must map to 1-2 subskills, mapping immutable | TD-02 Drills.SubskillMapping, TD-03 immutability guard | Covered | |
| Shared Mode: one score, one anchor set | TD-05, TD-03 payload | Covered | |
| Multi-Output Mode: independent scores, independent anchors | TD-05 TC-12.x, TD-03 payload | Covered | |
| Cross-Skill-Area mapping prohibited | TD-02, TD-03 validation | Covered | |

### S02 Section 2.6: Window Definitions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Each subskill: Transition (25) + Pressure (25) windows | TD-02 MaterialisedWindowState, TD-05 | Covered | |
| Window size fixed at 25, system constant, not user-configurable | TD-01, TD-02 | Covered | |
| Technique Block drills do not enter windows — detailed description | TD-02 MaterialisedWindowState.PracticeType constraint, TD-05 TC-11.1.1 | Covered | |

### S02 Section 2.7: Weight & Window Versioning

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| System-controlled parameters: allocations, weighting, window size | TD-04 scope determination | Covered | |
| User-editable: drill scoring anchors (User Custom only) | TD-04 reflow trigger catalogue | Covered | |
| Any structural parameter change triggers full recalculation and timeline annotation | TD-04 reflow algorithm | Covered | |
| One canonical scoring model | TD-04 reflow idempotency | Covered | |

### S02 Section 2.8: Structural Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Deterministic additive structure | TD-05 convergence tests | Covered | |
| No cross-area inflation | TD-05 TC-12.x occupancy rules | Covered | |
| No hidden smoothing | Implicit (no smoothing in any TD) | Covered | |
| No redistribution | TD-05 TC-8.1.2 | Covered | |
| No time decay | Implicit (no decay in any TD) | Covered | |
| Full recalculability | TD-04 full rebuild algorithm | Covered | |

---

---

## S03 — User Journey Architecture (3v.g8)

### S03 Section 3.1: Core Object Hierarchy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Six structural layers: Drill -> Routine -> PracticeBlock -> Session -> Set -> Instance | TD-02 table hierarchy, TD-04 state machines | Covered | |
| Drill definition fields (Name, Skill Area, Subskill mapping, Anchors, Scoring mode, Metric Schema, Available clubs, RequiredSetCount, RequiredAttemptsPerSet, Drill Type) | TD-02 Drills table DDL | Covered | |
| Drill Type governs scoring: Technique Block (no scoring), Transition (Transition window), Pressure (Pressure window) | TD-02 MaterialisedWindowState constraint, TD-05 TC-11.1.1 | Covered | |
| Drill Definition Immutability: RequiredSetCount/RequiredAttemptsPerSet immutable post-creation | TD-03 structural immutability guard, TD-04 Drill state machine | Covered | |
| Routine: blueprint with fixed entries and Generation Criteria | TD-02 Routine table, TD-03 Routine.Entries payload | Covered | |
| Routine instantiation creates PracticeBlock, template linkage severed | TD-04 Routine state machine | Covered | |
| Routine referential integrity: Drill deleted/retired -> auto-removed from template | TD-04 Routine state machine | Covered | |
| Empty Routines auto-deleted | TD-04 Routine state machine | Covered | |
| Routine retirement and deletion: no effect on Drills/Sessions/scoring | TD-04 Routine state machine | Covered | |
| PracticeBlock creation via: Routine, Manual, System-generated, Calendar-initiated | TD-06 Phase 4, Phase 5 | Covered | |
| PracticeBlock persisted only if >= 1 Session | TD-04 PracticeBlock state machine | Covered | |
| PracticeBlock closure: Manual (End Practice) or Auto-end (4h) | TD-04 PracticeBlock state machine (Manual/ScheduledAutoEnd/SessionTimeout) | Covered | |
| PracticeBlock cannot close while Session Active | TD-04 PracticeBlock state machine guards | Covered | |
| Auto-end generates passive notification only | TD-07 user-facing messaging | Covered | |
| Session: runtime execution of single Drill, created on Start Drill | TD-04 Session state machine | Covered | |
| Only one authoritative active Session per user | TD-04 Session state machine, TD-01 single active Session rule | Covered | |
| Structured drills: auto-close on final Instance of final Set | TD-04 Session structured completion | Covered | |
| Unstructured drills: manual or inactivity-based termination | TD-04 Session unstructured completion | Covered | |
| Completion Timestamp Authority (4 rules) | TD-04 Session state machine, TD-01 sync transport | Covered | |
| Server does not alter device-recorded completion timestamp | TD-01 authority model, TD-03 upload RPC | Covered | |
| Session Stores: completion timestamp, Sets, derived drill score (not persisted) | TD-02 Session table columns | Covered | S03 says "derived drill score not persisted" — TD-02 Session table has SessionScore column, but this aligns with materialised state pattern |
| Session is atomic scored unit entering subskill windows | TD-04 Session state machine, TD-05 | Covered | |
| Technique Block Sessions do not enter windows | TD-02 MaterialisedWindowState.PracticeType constraint, TD-05 TC-11.1.1 | Covered | |
| Editing Instances does not alter timestamp or window position | TD-05 TC-11.1.7 | Covered | |
| Sessions reference Drill definition active at creation time | TD-04 structural immutability | Covered | |
| Set: strictly sequential, no interleaving or parallel Sets | TD-04, TD-06 Phase 4 | Covered | |
| Set is not independent scoring unit, Session score = mean of all Instance scores | TD-05 TC-5.x | Covered | |
| Incomplete structured Sessions discarded entirely, no partial saves | TD-04 Session state machine | Covered | |
| Instance: atomic attempt with metrics, timestamp, derived score | TD-02 Instance table, TD-05 | Covered | |
| Instance edits allowed during active Session and after close, trigger recalculation | TD-04 reflow trigger catalogue | Covered | |

### S03 Section 3.2: First-Time User Flow

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| User lands on empty Dashboard | TD-06 Phase 6 (zero state) | Covered | |
| No forced onboarding | TD-06 Phase 6 | Covered | |
| Context-aware prompts displayed | TD-06 Phase 6 | Covered | |
| Bag rule: if bag not configured, Technique Block only | No explicit TD reference | **Gap** | S03 specifies that if the bag is not configured, only Technique Block drills are allowed. No TD document codifies this as a validation rule or UI constraint. TD-07 does not list a specific error for this scenario. |
| Drill Library: canonical drills preloaded | TD-02 seed data (28 System Drills) | Covered | |
| Start Practice CTA visible immediately | TD-06 Phase 6 | Covered | |

### S03 Section 3.3: Returning User Flow

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Home Dashboard is root state | TD-06 Phase 6 | Covered | |
| Dashboard Top Section: Overall Score (0-1000) | TD-06 Phase 6 | Covered | |
| Dashboard Top Section: Today's Slot Summary (filled/total with visual progress) | TD-06 Phase 6 | Covered | |
| Start Today's Practice: visible only when CalendarDay has >= 1 filled Slot | No explicit TD reference | **Gap** | S03 specifies conditional visibility of "Start Today's Practice" based on filled Slots. No TD document addresses this specific UI rule. Implementation likely exists in shell/dashboard code but is not codified in a TD. |
| Start Clean Practice: always visible | No explicit TD reference | **Gap** | Same as above — S03 specifies this always-visible CTA. Not codified in a TD. |
| If Session Active -> auto-resume | TD-04 Session state machine, TD-06 Phase 4 | Covered | |
| If PracticeBlock auto-ended -> passive banner | TD-07 user-facing messaging | Covered | |
| Settings accessible via gear icon in top-right | TD-06 Phase 8 (AppBar gear icon) | Covered | |

### S03 Section 3.4: Session Lifecycle

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Start Drill only, duplicate taps ignored | TD-04 Session state machine guards | Covered | |
| Structured: auto-closes on final Instance of final Set | TD-04 Session structured completion | Covered | |
| If user attempts early end of structured drill: prompted to complete or discard | TD-04 Session state machine | Covered | |
| Unstructured: End Drill to close manually | TD-04 Session unstructured completion | Covered | |
| Inactivity safeguard: 2h no Instance -> auto-close | TD-04 Session auto-close (2h timer) | Covered | |
| Auto-close with zero Instances -> discarded | TD-04 Session state machine | Covered | |
| Auto-close structured incomplete -> discarded, popup banner on next open | TD-04 Session state machine, TD-07 | Covered | |
| Auto-close all Sets complete or unstructured with >= 1 Instance -> saved and scored | TD-04 Session state machine | Covered | |
| Passive notification for all auto-close events | TD-07 user-facing messaging | Covered | |
| Manual End Practice while Session Active: prompt, confirm -> End Session then close PracticeBlock | TD-04 PracticeBlock state machine | Covered | |
| Discard: hard delete, all Sets/Instances removed, no scoring impact | TD-04 Session state machine (Active -> Discarded) | Covered | |
| Closed Sessions may be hard deleted, triggers full recalculation | TD-04 Session state machine, reflow trigger catalogue | Covered | |
| Post-Session Summary: distinct application state after PracticeBlock close | TD-06 Phase 4 (post_session_summary_screen) | Covered | |
| Post-Session Summary displays: final 0-5 scores, Overall Score delta, key statistics | TD-06 Phase 4, TD-03 PracticeBlockSummary/SessionSummary payload | Covered | |
| User must tap Done to proceed, no auto-dismiss | TD-06 Phase 4 | Covered | |
| Scores reflect updated engine state (post-reflow) | TD-04 Session close pipeline | Covered | |
| Exit routes to Home Dashboard regardless of launch surface | TD-06 Phase 4 acceptance | Covered | |

### S03 Section 3.5: Concurrency Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Single authoritative active Session | TD-04 Session state machine, TD-01 | Covered | |
| Second device: warning, on confirm previous Session hard-discarded | TD-04 cross-device dual-Active-Session, TD-07 CONFLICT_DUAL_ACTIVE_SESSION | Covered | |
| Server enforces LWW, displaced device returns to dashboard on sync | TD-07 dual active Session resolution | Covered | |
| Offline: cross-device overlap permitted, resolved chronologically on sync | TD-04 offline state transitions, TD-01 cross-device Session concurrency | Covered | |

### S03 Section 3.6: Offline Behaviour

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Offline supports: Start PracticeBlock/Session, Log Instances, End Session, local scoring | TD-01 offline behaviour, TD-07 graceful degradation | Covered | |
| Device completion timestamp authoritative, stored in UTC | TD-01, TD-03 | Covered | |
| Server does not mutate completion time | TD-01, TD-03 | Covered | |
| Scoring does not require server connectivity | TD-01 offline-first architecture | Covered | |

### S03 Sections 3.7-3.9: State Model, Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 8 valid states listed | TD-04 entity state machines | Covered | |
| 4 invalid states listed | TD-04 state machine guards | Covered | |
| Post-Session Summary as valid state | TD-06 Phase 4 | Covered | |
| Deterministic lifecycle guarantee | TD-04, TD-05 | Covered | |
| 7 structural guarantees listed | TD-04, TD-05 convergence tests | Covered | |

---

---

## S04 — Drill Entry System (4v.g9)

### S04 Section 4.1: Drill Definition Schema

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Two layers: System Master Library (immutable) and User Practice Pool | TD-02 Drills table (Origin column), TD-06 Phase 3 | Covered | |
| Immutable post-creation fields: Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, RequiredAttemptsPerSet, Club Selection Mode, Target Definition | TD-03 structural immutability guard | **Conflict** | Same conflict as S00. S04 includes ClubSelectionMode and TargetDefinition; TD-03 includes ScoringMode and InputMode instead. See S00-S02 gap analysis Conflict 1. |
| System Drills: immutable fields listed (including Anchors, ClubSelectionMode, TargetDefinition) | TD-03, TD-04 | Covered | System Drills have all fields immutable to users |
| Central edits trigger full reflow | TD-04 reflow trigger catalogue (System Drill anchor edits) | Covered | |
| Adopt/Unadopt model for System Drills | TD-03 DrillRepository.adoptDrill()/retireAdoption(), TD-04 UserDrillAdoption state machine | Covered | |
| Unadopt prompt: keep or delete historical data | TD-04 UserDrillAdoption state machine (Retire vs Delete) | Covered | |
| Keep -> Retired state, identity preserved, re-adoption reconnects | TD-04 UserDrillAdoption state machine | Covered | |
| Delete -> permanent removal, all Sessions/Instances deleted, full recalculation | TD-04 Drill state machine | Covered | |
| User Custom Drill creation rules (Skill Area, Metric Schema, Anchors, Drill Type, Subskill mapping, Set structure) | TD-03 DrillRepository.createCustomDrill(), TD-06 Phase 3 | Covered | |
| Dual-mapped drills within same Skill Area only | TD-02 constraints, TD-03 validation | Covered | |
| Technique Block: RequiredSetCount=1, RequiredAttemptsPerSet=null | TD-02 Drill constraints | Covered | |
| Drill Duplication: new DrillID, Origin=UserCustom, structural fields copied, anchors editable | TD-03 DrillRepository (implicit in createCustomDrill) | Covered | |
| Anchor Governance: System immutable, User Custom editable with reflow | TD-04 reflow trigger catalogue | Covered | |
| Anchor edits blocked while Drill in Retired state | No explicit TD reference | **Gap** | S04 states anchor edits are blocked during Retired state. TD-04 Drill state machine shows Active->Retired transition but does not explicitly address anchor edit guard during Retired state. The guard may be implicitly enforced by the state machine (anchor edit only available on Active drills), but no TD codifies this constraint. |
| User must reactivate before editing anchors | No explicit TD reference | **Gap** | Same as above — the reactivation requirement before anchor editing is not explicitly stated in any TD. |
| User Custom Drill Retirement/Deletion prompt and behaviour | TD-04 Drill state machine (Active->Retired, Active->Deleted) | Covered | |
| Retired: cannot be manually purged from scoring | No explicit TD reference | **Gap** | Same gap identified in S01 analysis. |
| Deletion is irreversible at application layer, soft delete at persistence layer | TD-01 soft-delete strategy, TD-02 IsDeleted flag | Covered | |

### S04 Section 4.2: Drill Skill Areas

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Skill Areas fixed to canonical set | TD-02 SubskillRef seed data | Covered | |
| Skill Area determines eligible clubs and subskills | TD-03 ClubRepository.watchClubsForSkillArea() | Covered | |
| Eligible clubs filtered from user's configured bag at Session start | TD-06 Phase 4 | Covered | |

### S04 Section 4.3: Input Modes & Metric Schema

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Metric schemas system-defined only, users cannot create custom | TD-02 MetricSchema reference table | Covered | |
| Each schema defines: input mode, required fields, valid ranges, validation, scoring adapter | TD-02 MetricSchema table, TD-05 test cases | Covered | |
| Schema immutable once drill created | TD-03 structural immutability guard | Covered | |
| Grid Cell Selection: user taps cell, resolved target displayed | TD-06 Phase 4 (grid_cell_screen) | Covered | |
| Grid types: 3x3 (Multi-Output), 1x3 (direction, Shared), 3x1 (distance, Shared) | TD-02 MetricSchema seed data | Covered | |
| Continuous Measurement: numeric value, scored via anchor interpolation | TD-02 MetricSchema seed, TD-06 Phase 4 (continuous_measurement_screen) | Covered | |
| Raw Data Entry: numeric value no target, scored via anchor interpolation | TD-02 MetricSchema seed, TD-06 Phase 4 (raw_data_entry_screen) | Covered | |
| Binary Hit/Miss: Hit or Miss tap, scored metric = hit-rate percentage | TD-02 MetricSchema seed, TD-06 Phase 4 (binary_hit_miss_screen) | Covered | |
| Binary Hit/Miss: user declares intention at Session start, stored on Session, no scoring impact | No explicit TD reference | **Gap** | S04 specifies that at Session start for Binary Hit/Miss drills, "the user declares their intention (e.g. 'draw' or 'fade'); the declaration is stored on the Session for reference but has no scoring impact." No TD document addresses this declaration field. TD-02 Session table DDL does not include an intention/declaration column. |
| Binary Hit/Miss: no HardMinInput/HardMaxInput, excluded from integrity detection | TD-07 Phase 4 error handling, TD-02 MetricSchema | Covered | |
| Multi-Output Model (Non-Grid): two independent metrics, separate anchor sets | TD-05 TC-12.x, TD-03 payload shapes | Covered | |

### S04 Section 4.4: Target Definition

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Required for all grid-based drills | TD-02 Drills table | Covered | |
| Target Distance: Fixed, Club Carry, Percentage of Club Carry | TD-02 Drills columns | Covered | |
| Club Carry/Percentage modes greyed out until carry distances entered | TD-06 Phase 4 UI | Covered | |
| Target Size: Fixed or Percentage of Target Distance | TD-02 Drills columns | Covered | |
| Dimension requirements by grid type (3x3: both, 1x3: width, 3x1: depth) | TD-02 §3.5 | Covered | |
| Target box scales by club, not by anchor level | No explicit TD reference | **Gap** | S04 states "The target box size scales by club (via the resolved target distance) but does not scale by anchor level." No TD explicitly confirms that anchor level does not affect target box size. This is implicit in the design but not codified. |
| Target Definition fields immutable post-creation | TD-03 structural immutability guard | **Conflict** | Same conflict as Conflict 1 — TD-03 does not list TargetDefinition fields in its immutability guard. |
| Historical Instances retain snapshot target values | No explicit TD reference | **Gap** | S04 states "Historical Instances retain their snapshot target values regardless of any drill-level changes." Since target definition is immutable, this is moot in practice. No TD addresses snapshot semantics. |

### S04 Section 4.5: Club Selection

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| SelectedClub stored on every Instance | TD-02 Instance.ClubID | Covered | |
| Drill definition no longer stores fixed SelectedClub | TD-02 Drills table (no fixed club column) | Covered | |
| Eligible clubs derived from Skill Area filtered against user's bag | TD-03 ClubRepository | Covered | |
| Club Selection Mode: Random, Guided, User Led (default) | TD-02 Drills.ClubSelectionMode | Covered | |
| Auto-select if only one eligible club | TD-06 Phase 4 | Covered | |

### S04 Section 4.6: Instance Entry Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| One-shot entry default | TD-06 Phase 4 | Covered | |
| Bulk Entry: active Set only, cannot exceed remaining capacity | No explicit TD reference | **Gap** | S04 specifies a Bulk Entry mechanism with detailed rules (no overflow, hard validation, sequential timestamps). No TD document addresses bulk entry. TD-03 PracticeRepository.logInstance() is singular. TD-06 Phase 4 does not mention bulk entry. TD-05 defers batch Instance logging to V2. |
| Bulk Entry: generates individual Instance records with micro-offset timestamps | No explicit TD reference | **Gap** | Same as above. |
| Bulk Entry: same SelectedClub for batch | No explicit TD reference | **Gap** | Same as above. |
| Hard blocking of invalid values, all required fields mandatory, no partial saves, no silent correction | TD-07 inline field validation, TD-03 validation | Covered | |
| Instance edits during active Session: pre-scoring, no reflow, no ordering change | TD-04 non-reflow triggers (Instance edits during active Session) | Covered | |
| SelectedClub may be edited on Instance | TD-06 Phase 4 | Covered | |
| Post-Close Editing (Structured): value editable, Instance/Set deletion prohibited, Session deletable | TD-04 Session state machine guards | Covered | |
| Post-Close Editing (Unstructured): value editable, Instance deletable, last deletion -> auto-discard, Session deletable | TD-04 Session state machine, TD-05 TC-11.1.6 | Covered | |
| All post-close edits follow reflow pipeline (S07) | TD-04 reflow trigger catalogue | Covered | |
| Schema Plausibility Bounds: HardMinInput/HardMaxInput on Continuous Measurement and Raw Data Entry | TD-02 MetricSchema table | Covered | |
| Values outside range saved normally but trigger IntegrityFlag | TD-07 Phase 4 error handling | Covered | |
| Grid Cell Selection and Binary Hit/Miss: no plausibility bounds | TD-02 MetricSchema seed data | Covered | |
| Numeric input field default: blank (dash), not zero | No explicit TD reference | **Gap** | S04 specifies the UI default for numeric input fields is blank/dash, not zero. No TD codifies this UI convention. Implementation concern only. |

### S04 Section 4.7: Scoring Adapters

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All adapters use strict linear 0-5 interpolation | TD-05 scoring formula, TD-03 §4 | Covered | |
| Grid Cell Selection: hit-rate percentage through anchors | TD-05 TC-4.1.x | Covered | |
| Continuous Measurement: entered value through anchors | TD-05 (deferred test note: identical adapter) | Covered | |
| Raw Data Entry: entered value through anchors | TD-05 TC-4.3.x, TC-4.4.x | Covered | |
| Binary Hit/Miss: hit-rate percentage, identical to Grid Cell Selection | TD-05 TC-4.5.x | Covered | |
| Session Score: simple average, no minimum threshold, single Instance valid | TD-05 TC-5.4.1 | Covered | |
| Sets strictly sequential, no interleaving | TD-04 | Covered | |
| Structured: auto-close on final Instance of final Set | TD-04 | Covered | |
| Incomplete structured cannot be saved | TD-04 | Covered | |

### S04 Section 4.8: Live Feedback & Preview Logic

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| During active Session: show shot confirmation | TD-06 Phase 4 (score flash widget) | Covered | |
| Show hit/miss vs target (grid: highlight tapped cell) | TD-06 Phase 4 (grid_cell_screen) | Covered | |
| Show Set and attempt progress for structured drills | TD-06 Phase 4 (execution_header) | Covered | |
| Show resolved target for next Instance | TD-06 Phase 4 | Covered | |
| Do not display per-shot 0-5 | No explicit TD reference | **Gap** | S04 explicitly prohibits displaying the per-shot 0-5 score during active Session. No TD codifies this prohibition. The implementation may comply but the rule is not in a TD. |
| Do not display running average | No explicit TD reference | **Gap** | Same as above — S04 explicitly prohibits displaying running average during active Session. |
| At Session End: display final 0-5 score, impact on 1000-point overall, do not expose window mechanics | TD-06 Phase 4 (post-session summary) | Covered | |

### S04 Section 4.9: Structural Guarantees

All 8 guarantees are covered by the combination of TD-03 (API contracts), TD-04 (state machines), TD-05 (test cases), and TD-06 (build plan).

---

---

## S05 — Review: SkillScore & Analysis (5v.d6)

### S05 Section 5.1: SkillScore (Engine State View)

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| SkillScore displays current scoring engine state | TD-06 Phase 6 (review_dashboard_screen) | Covered | |
| SkillScore reflects: 65/35 weighting, windows, occupancy, allocations, deterministic logic | TD-06 Phase 6, TD-03 ScoringRepository.watch*() | Covered | |
| SkillScore is not bucket-based, does not use session grouping | No explicit TD reference | **Gap** | S05 explicitly states SkillScore "is not bucket-based and does not use session grouping." No TD codifies this prohibition. Implicit in the engine design but not explicitly stated. |
| Overall Score (0-1000), always against full scale | TD-06 Phase 6 (overall_score_display) | Covered | |
| Skill Area Scores | TD-06 Phase 6 (skill_area_heatmap) | Covered | |
| Subskill Scores (0-5 effective weighted average) | TD-06 Phase 6 (subskill_breakdown) | Covered | |
| Transition & Pressure window saturation (e.g. 18/25) | TD-06 Phase 6 | Covered | |
| Current weighted averages per subskill | TD-06 Phase 6 | Covered | |
| All values represent current engine state only | Implicit in materialised table design | Covered | |
| No smoothing, no time decay, no bucket aggregation | Implicit | Covered | |
| Window Detail View: tap into any window | TD-06 Phase 6 (window_detail_screen) | Covered | |
| Chronological list, newest at top | TD-06 Phase 6 | Covered | |
| Roll-off from bottom (oldest first) | TD-06 Phase 6 | Covered | |
| Each Entry shows: Drill name, Date, 0-5 score, Occupancy (1.0 or 0.5) | TD-06 Phase 6 (window detail parsed entries) | Covered | |
| Visual divider marks roll-off boundary | TD-06 Phase 6 (roll-off boundary) | Covered | |
| Read-only inspection, no editing/deletion from this view | TD-06 Phase 6 | Covered | |
| Weakness Ranking View: all Subskills in priority order by WeaknessIndex | TD-06 Phase 6 (weakness_ranking_screen) | Covered | |
| Weakness Ranking displays: rank, name, Skill Area, weighted average, saturation, WeaknessIndex, allocation | TD-06 Phase 6 | Covered | |
| Weakness Ranking informational only from Review (no planning/generation action) | TD-06 Phase 6 | Covered | |
| Same ranking accessible from Planning tab | TD-06 Phase 5 | Covered | |

### S05 Section 5.2: Analysis (Trend & Diagnostic View)

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Analysis displays performance trends over time, session-native | TD-06 Phase 6 (analysis_screen) | Covered | |
| Score-Level Trends at Overall, Skill Area, Subskill levels | TD-06 Phase 6 (performance_chart) | Covered | |
| Vertical axis: 0-5 scale only | TD-06 Phase 6 | Covered | |
| Resolution Toggle: Daily, Weekly (default), Monthly | TD-06 Phase 6 (analysis_filters with Resolution) | Covered | |
| Bucket Value: mean of Session 0-5 scores within bucket, bucket displays Session count | TD-06 Phase 6 | Covered | |
| No reconstruction of allocation or 1000-point scale in Analysis | No explicit TD reference | **Gap** | S05 explicitly states "No reconstruction of allocation or 1000-point scale occurs" in Analysis. No TD codifies this constraint. |
| Subskill trend: each subskill's own independent 0-5 score | TD-06 Phase 6 | Covered | |
| Multi-Output: drill-level averaged score does not feed into subskill trends | No explicit TD reference | **Gap** | S05 specifies that the drill-level averaged score "does not feed into subskill trends" for Multi-Output drills. No TD explicitly states this separation. |
| Rolling Overlay: Daily=7-bucket, Weekly=4-bucket, Monthly=none | TD-06 Phase 6 (rolling overlay via fl_chart) | Covered | |
| Rolling overlay operates across buckets only | No explicit TD reference | **Gap** | S05 specifies rolling overlay "operates across buckets only." Not codified in a TD. |
| Drill-Level Analysis: Session score trend + Raw metric diagnostics | TD-06 Phase 6 (session_history_screen, session_detail_screen) | Covered | |
| Multi-Output drill-level Session score = mean of two subskill outputs (display only) | No explicit TD reference | **Gap** | S05 specifies this display convention. Not explicitly codified in a TD. |
| Grid Cell Selection diagnostics: grid with hit/miss distribution, cell counts/percentages | No explicit TD reference | **Gap** | S05 specifies detailed grid diagnostic visualisation (cell-level counts, percentages, center box hit-rate highlighted). No TD document describes this specific visualisation. TD-06 Phase 6 mentions raw diagnostics generally. |
| 3x3 grid: additional 1x3 direction summary and 3x1 distance summary views | No explicit TD reference | **Gap** | S05 specifies derived 1x3 and 3x1 summary views from 3x3 data. No TD addresses this. |
| Continuous Measurement diagnostics: average value, distribution histogram | No explicit TD reference | **Gap** | S05 specifies histogram visualisation. Not codified in a TD. |
| Raw Data Entry diagnostics: average value, distribution histogram | No explicit TD reference | **Gap** | Same as above. |
| Binary Hit/Miss diagnostics: hit count, miss count, hit-rate, ratio visualisation | No explicit TD reference | **Gap** | S05 specifies ratio visualisation for Binary Hit/Miss. Not codified in a TD. |
| All grid diagnostics aggregate regardless of club | No explicit TD reference | **Gap** | S05 specifies cross-club aggregation for grid diagnostics. Not codified in a TD. |
| Set Aggregation: all Instances across all Sets, no per-Set breakdown | No explicit TD reference | **Gap** | S05 specifies aggregate-only, no per-Set breakdown. Not codified in a TD. |
| Raw analytics default to last 3 months, user may adjust | No explicit TD reference | **Gap** | S05 specifies default date range for raw analytics. Not codified in a TD. |
| Variance Tracking: single SD value from all Session 0-5 scores in date range | TD-06 Phase 6 (session_history_screen variance tracking with SD RAG thresholds) | Covered | |
| Multi-Output: SD calculated separately per subskill, two RAG indicators | TD-06 Phase 6 | Covered | |
| Confidence Tiers: <10 Sessions = not displayed, 10-19 = low confidence, 20+ = full confidence | TD-06 Phase 6 (confidence levels) | Covered | |
| RAG Thresholds: Green SD<0.40, Amber 0.40<=SD<0.80, Red SD>=0.80 | TD-06 Phase 6 (SD RAG thresholds) | Covered | |
| Date Range Persistence: 1 hour, timer resets on Analysis visit, default reset to 3 months/Weekly | No explicit TD reference | **Gap** | S05 specifies a 1-hour persistence timer for date range and resolution across Analysis views. No TD codifies this behaviour. |

### S05 Section 5.3: Plan Adherence

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Adherence = (Completed planned / Total planned) x 100 | TD-06 Phase 6 (plan_adherence_screen) | Covered | |
| Only Slots with DrillID count as planned | TD-06 Phase 6 | Covered | |
| Overflow Slots (Planned=false) excluded from both numerator and denominator | TD-06 Phase 6 | Covered | |
| Weekly and monthly rollups | TD-06 Phase 6 (weekly/monthly rollups) | Covered | |
| Skill Area breakdown | TD-06 Phase 6 (SkillArea breakdown) | Covered | |
| Time Period Options: custom, last 12/6/3 months, last 4 weeks | No explicit TD reference | **Gap** | S05 specifies 5 time period options for Plan Adherence. TD-06 Phase 6 mentions "weekly/monthly adherence rollups" but does not detail the specific time period options. |
| Date Range Persistence: 1 hour, default reset to last 4 weeks | No explicit TD reference | **Gap** | S05 specifies 1-hour persistence with different default (4 weeks vs 3 months for Analysis). Not codified in a TD. |
| Rollup boundaries use user's home timezone and configured week start day (Monday or Sunday) | No explicit TD reference | **Gap** | S05 specifies timezone and week start day for rollup boundaries. No TD addresses week start day configuration. |
| Week start day: Monday or Sunday | No explicit TD reference | **Gap** | S05 defines this setting. No TD or S10 cross-reference confirms this setting exists in TD implementation. |

### S05 Section 5.4: Structural Separation

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| SkillScore, Analysis, Plan Adherence architecturally distinct | TD-06 Phase 6 (Review tab dual-tab: Dashboard | Analysis) | Covered | |
| No window mechanics exposed in Analysis | No explicit TD reference | **Gap** | S05 explicitly prohibits window mechanics in Analysis. Not codified in a TD. |
| Plan Adherence: no interaction with scoring engine/windows/derived scores | TD-06 Phase 6 (architectural separation) | Covered | |
| Session duration available in Analysis for time-based analytics | No explicit TD reference | **Gap** | S05 mentions session duration data from S14 §14.10.8 available in Analysis. No TD addresses session duration in analysis context. |
| Duration tracked passively on scored Sessions (first Instance to last Instance) | No explicit TD reference | **Gap** | S05 specifies duration tracking semantics. Not codified in a TD. |
| Duration is primary data field for Technique Block Sessions | No explicit TD reference | **Gap** | S05 specifies duration as primary field for Technique Block. Not codified in a TD. |
| Duration has no scoring impact, no window interaction | Implicit in design | Covered | |

---

---

## S06 — Data Model & Persistence Layer (6v.b7)

### S06 Section 6.1-6.2: Core Domain Objects & Entity Schemas

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Entity list: Drill, Routine, PracticeBlock, Session, Set, Instance, PracticeEntry, UserDrillAdoption, UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping, EventLog, UserDevice, CalendarDay, Schedule, RoutineInstance, ScheduleInstance | TD-02 §3 (28 tables), TD-03 repositories | Covered | |
| All entities carry CreatedAt (UTC) and UpdatedAt (UTC) | TD-02 UpdatedAt trigger requirement, TD-01 sync uniformity | Covered | |
| User entity: UserID (UUID PK), CreatedAt, UpdatedAt | TD-02 User table | Covered | |
| Drill schema: 22 fields including DrillID, UserID nullable, Name, SkillArea (enum), DrillType (enum), ScoringMode (enum nullable), InputMode (enum), MetricSchemaID, GridType (enum nullable), SubskillMapping (array 1-2), ClubSelectionMode (enum nullable), TargetDistance fields, TargetSize fields, RequiredSetCount, RequiredAttemptsPerSet, Anchors (JSON), Origin (enum), Status (enum), IsDeleted, timestamps | TD-02 Drills table DDL | Covered | Per source-of-truth hierarchy, TD-02 governs when S06 and TD-02 diverge on column details |
| Drill.SkillArea enum: 7 values | TD-02 SkillArea enum | Covered | |
| Routine schema: RoutineID, UserID, Name, Entries (ordered array), Status, IsDeleted, timestamps | TD-02 Routine table | Covered | |
| Routine entry types: Fixed DrillID or Criterion | TD-03 Routine.Entries payload shape | Covered | |
| Routine auto-delete when empty | TD-04 Routine state machine | Covered | |
| PracticeBlock schema: PracticeBlockID, UserID, SourceRoutineID nullable, DrillOrder, Start/EndTimestamp, ClosureType, IsDeleted, timestamps | TD-02 PracticeBlock table | Covered | |
| PracticeBlock.ClosureType: Manual, AutoClosed | TD-04 PracticeBlock state machine (Manual/ScheduledAutoEnd/SessionTimeout) | **Conflict** | S06 defines ClosureType as {Manual, AutoClosed}. TD-04 defines three types: Manual, ScheduledAutoEnd, SessionTimeout. TD-02 governs per source-of-truth hierarchy. |
| PracticeEntry schema: PracticeEntryID, PracticeBlockID, DrillID, SessionID nullable, EntryType (enum), PositionIndex, timestamps | TD-02 PracticeEntry table | Covered | |
| PracticeEntry does not participate in scoring | TD-04 PracticeEntry state machine | Covered | |
| Session schema: SessionID, DrillID, PracticeBlockID, CompletionTimestamp nullable, Status (enum), IntegrityFlag, IntegritySuppressed, UserDeclaration (string nullable), SessionDuration (integer nullable), IsDeleted, timestamps | TD-02 Session table DDL | **Conflict** | S06 includes UserDeclaration and SessionDuration columns. TD-02 Session DDL may not include these columns. This requires verification against the actual TD-02 DDL. Per source-of-truth hierarchy, TD-02 governs. |
| Session.UserDeclaration: intention for Binary Hit/Miss, nullable, no scoring impact | No explicit TD-02 reference | **Gap** | Same gap identified in S04 analysis. S06 defines this column; if TD-02 omits it, the column is missing from the DDL. |
| Session.SessionDuration: elapsed time in seconds, nullable, no scoring impact | No explicit TD-02 reference | **Gap** | S06 defines this column. If TD-02 omits it, the column is missing from the DDL. Related to the S05 gap about session duration in Analysis. |
| Session score is derived (not stored) | TD-02, TD-04 materialised state design | Covered | |
| Set schema: SetID, SessionID, SetIndex (integer >= 1), IsDeleted, timestamps | TD-02 Sets table | Covered | |
| Instance schema: InstanceID, SetID, SelectedClub (UUID FK), RawMetrics (JSON), Timestamp, ResolvedTargetDistance/Width/Depth (nullable), IsDeleted, timestamps | TD-02 Instance table | Covered | |
| Instance derived 0-5 score not stored | TD-02 materialised state design | Covered | |
| Instance.ResolvedTargetDistance/Width/Depth: snapshots at creation for grid drills | TD-02 Instance table columns | Covered | |
| UserDrillAdoption schema | TD-02 UserDrillAdoption table | Covered | |
| UserClub schema: ClubID, UserID, ClubType (enum from 36-type), Make/Model/Loft (nullable), Status | TD-02 UserClub table | Covered | |
| ClubPerformanceProfile schema: ProfileID, ClubID, EffectiveFromDate, CarryDistance, 4 dispersion fields, timestamps | TD-02 ClubPerformanceProfile table | Covered | |
| UserSkillAreaClubMapping schema: MappingID, UserID, ClubType, SkillArea, IsMandatory, timestamps | TD-02 UserSkillAreaClubMapping table | Covered | |
| EventLog schema: EventLogID, UserID, EventType, Timestamp, AffectedEntityIDs (JSON), AffectedSubskills (JSON nullable), Metadata (JSON nullable), CreatedAt | TD-02 EventLog table | Covered | |
| EventLog: DeviceID column (UUID nullable, originating device) | TD-02 EventLog table | Covered | TD-02 likely includes DeviceID |
| EventLog append-only (no updates, no deletions) | TD-02, TD-01 EventLog exception (CreatedAt only) | Covered | |
| Schedule schema: ScheduleID, UserID, Name, ApplicationMode (enum), entries/TemplateDays, Status, IsDeleted, timestamps | TD-02 Schedule table | Covered | |
| ScheduleInstance schema: ScheduleInstanceID, ScheduleID (nullable), UserID, StartDate, EndDate, OwnedSlots, CreatedAt | TD-02 ScheduleInstance table | Covered | |
| RoutineInstance schema: RoutineInstanceID, RoutineID (nullable), UserID, CalendarDayDate, OwnedSlots, CreatedAt | TD-02 RoutineInstance table | Covered | |
| CalendarDay / Slot schema | TD-02 CalendarDay table, TD-03 Slots payload | Covered | |
| Metric Schema plausibility bounds (HardMinInput, HardMaxInput) on MetricSchema, not on Instance/Session | TD-02 MetricSchema table | Covered | |

### S06 Section 6.3: Derived Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All scoring values derived, not stored as persisted fields | TD-02 materialised tables design, TD-04 reflow | Covered | |
| Derived state materialised post-reflow, served authoritatively | TD-01, TD-03, TD-04 | Covered | |
| No per-read derivation from raw data | TD-04 reflow design | Covered | |
| List of 10 derived values (Instance score, Session score, hit-rate, target dimensions, window state, averages, subskill/skill area/overall points, analytics) | TD-02 materialised tables (4 tables), TD-04 | Covered | |

### S06 Section 6.4: Ownership & User Scoping

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| UserID top-level scoping key, every query scoped to authenticated user | TD-02 RLS model (3 tiers), TD-01 security | Covered | |
| Drill.UserID null for System Drills | TD-02 Drills table, TD-02 RLS hybrid tier for Drill | Covered | |
| All entity ownership rules listed | TD-02 RLS policies (30 policies) | Covered | |

### S06 Section 6.5: Transaction Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Session closure: Session + Sets + Instances atomically | TD-04 Session state machine, TD-03 PracticeRepository | Covered | |
| Incomplete structured Sessions never persisted | TD-04 Session state machine | Covered | |
| Anchor edits: commit + trigger background recalculation atomically | TD-04 reflow algorithm | Covered | |
| Deletion: soft-delete + cascade + trigger recalculation atomically | TD-04 reflow trigger catalogue | Covered | |

### S06 Section 6.6: Deletion Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Soft Delete: IsDeleted = true, excluded from all queries, irreversible at UX | TD-01 soft-delete strategy, TD-02 IsDeleted flag | Covered | |
| Cascade rules: Drill -> Sessions -> Sets -> Instances | TD-04 state machines, TD-03 repository methods | Covered | |
| PracticeBlock -> Sessions -> Sets -> Instances | TD-04 | Covered | |
| PracticeBlock -> PracticeEntries (cascade, no cascade to Session) | TD-04 PracticeEntry state machine | Covered | |
| Retirement: only Drills, Routines, Schedules | TD-04 state machines | Covered | |
| Drill deleted/retired -> CalendarDay Slots cleared immediately | TD-04, TD-06 Phase 5 | Covered | |
| Schedule/Routine deleted -> Instance source reference set to null | TD-04, TD-06 Phase 5 | Covered | |
| Planning objects: no scoring impact, no recalculation | TD-04 non-reflow triggers | Covered | |
| Active Session Deletion Block: Drill deletion blocked while Session Active | TD-04 Drill state machine guard | Covered | |
| Session Auto-Discard: last Instance deletion -> auto-discard -> recalculation + EventLog | TD-04 Session state machine, TD-05 TC-11.1.6 | Covered | |

### S06 Section 6.7: Recalculation Behaviour

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Trigger catalogue reference to S07 | TD-04 reflow trigger catalogue | Covered | |
| Background process, loading state, materialised post-reflow state | TD-04, TD-06 Phase 2B | Covered | |
| EventLog entry for every recalculation, S07 §7.9 canonical enumeration | TD-02 EventTypeRef seed, TD-07 | Covered | |

### S06 Section 6.8: Indexing Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Session(CompletionTimestamp) | TD-02 ix_session_drill_completion | Covered | |
| Session(DrillID) | TD-02 ix_session_drill_completion (composite) | Covered | |
| Session(PracticeBlockID) | TD-02 indexes | Covered | |
| PracticeEntry(PracticeBlockID, PositionIndex) | TD-02 indexes | Covered | |
| PracticeEntry(SessionID) | TD-02 indexes | Covered | |
| Instance(SetID) | TD-02 indexes | Covered | |
| Instance(SelectedClub) | TD-02 indexes | Covered | S06 specifies this index; TD-02 may or may not include it explicitly |
| Set(SessionID) | TD-02 indexes | Covered | |
| UserDrillAdoption(UserID, DrillID) unique | TD-02 UNIQUE constraints | Covered | |
| All remaining indexes (UserClub, EventLog, CalendarDay, Routine, Schedule, etc.) | TD-02 §7 index coverage (49 indexes) | Covered | |
| All queries filter on IsDeleted = false | TD-01, TD-02 | Covered | |

### S06 Section 6.9: Structural Guarantees

All 11 guarantees are covered by TD-01, TD-02, TD-03, TD-04, and TD-07.

---

---

## S07 — Reflow Governance System (7v.b9)

### S07 Section 7.1: Structural Parameter Definition

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Structural Parameter: any editable parameter whose change alters numeric scoring, window composition, or aggregation | TD-04 §3 reflow trigger catalogue | Covered | |
| Immutable identity fields excluded (cannot change, cannot trigger reflow) | TD-04 §3 non-reflow triggers | Covered | |

### S07 Section 7.2: Reflow Trigger Catalogue

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| User-initiated: Custom Drill anchor edits | TD-04 reflow trigger catalogue | Covered | |
| User-initiated: Instance edit (post-close) | TD-04 reflow trigger catalogue | Covered | |
| User-initiated: Instance deletion (post-close, unstructured) | TD-04 reflow trigger catalogue | Covered | |
| User-initiated: Session deletion | TD-04 reflow trigger catalogue | Covered | |
| User-initiated: PracticeBlock deletion | TD-04 reflow trigger catalogue | Covered | |
| User-initiated: Drill deletion (with scored data) | TD-04 reflow trigger catalogue | Covered | |
| User-initiated: Session auto-discard | TD-04 reflow trigger catalogue | Covered | |
| System-initiated: System Drill anchor edits | TD-04 reflow trigger catalogue | Covered | |
| System-initiated: Skill Area/Subskill allocation edits | TD-04 reflow trigger catalogue | Covered | |
| System-initiated: 65/35 weighting edits | TD-04 reflow trigger catalogue | Covered | |
| System-initiated: Scoring formula edits | TD-04 reflow trigger catalogue | Covered | |
| Not trigger: Window size (fixed) | TD-04 non-reflow triggers | Covered | |
| Not trigger: IntegrityFlag/IntegritySuppressed changes | TD-04 non-reflow triggers | Covered | |
| Not trigger: Instance edits during active Session | TD-04 non-reflow triggers | Covered | |

### S07 Section 7.3: Post-Close Editing Rules

All items covered by TD-04 Session state machine and reflow trigger catalogue. Identical to S04 §4.6 analysis.

### S07 Section 7.4: Reflow Scope Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Scoped laterally, propagates upward only | TD-04 §3 scope determination | Covered | |
| Multi-Output: anchor edit scopes to only affected subskill(s) | TD-04 scope determination rules (Multi-Output single anchor) | Covered | |
| Multiple subskills: single combined scoped reflow transaction | TD-04 §3 | Covered | |
| One atomic swap, one EventLog entry | TD-04 §3 reflow algorithm | Covered | |

### S07 Section 7.5: Lock Conditions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Full scoring lock during reflow | TD-04 §5 coordination mechanisms, TD-07 scoring lock | Covered | |
| Blocked: Session start, Instance logging, edits/deletions, anchor edits, structural edits | TD-04 §5 blocked operations during scoring lock | Covered | |
| Scoring views unavailable, UI loading state | TD-07 graceful degradation | Covered | |
| Lifecycle timers suspended during lock, resume when released | TD-04 timer pause semantics | Covered | |
| Lock is user-scoped, applies across devices | TD-04 §5 UserScoringLock | Covered | |
| Active Session on other device: can continue but cannot log Instances until lock releases | TD-04 §5 | Covered | |
| 2-hour inactivity timer runs independently of lock | TD-04 | Covered | |
| Sync-triggered rebuilds: non-blocking model, user continues normally | TD-04 full rebuild (RebuildGuard not UserScoringLock) | Covered | |
| User-initiated reflow has priority over sync rebuild | TD-04 §5 coordination mechanisms | Covered | |

### S07 Section 7.5.1: Client-Side Behaviour During Lock

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Instance logging rejected immediately with UI notice | TD-07 user-facing messaging | Covered | |
| No client-side buffering of rejected data | No explicit TD reference | **Gap** | S07 explicitly prohibits buffering of rejected Instance data. Not codified in a TD. |
| No partial save during lock | No explicit TD reference | **Gap** | S07 explicitly prohibits partial saves. Implicit in TD-04 lock design but not stated. |
| No retry queue for blocked operations | No explicit TD reference | **Gap** | S07 explicitly prohibits retry queues. Not codified in a TD. |
| Input fields visible but submission disabled | No explicit TD reference | **Gap** | S07 specifies UI behaviour during lock. Not codified in a TD. |
| Global scoring lock for centrally-triggered changes with maintenance banner | No explicit TD reference | **Gap** | S07 describes a global lock and maintenance banner for server-initiated changes. No TD addresses this scenario. Central/system-initiated reflows are not addressed in the TD sync or reflow architecture. |

### S07 Section 7.6: Conflict Resolution Rules

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| One reflow at a time per user | TD-04 RebuildGuard/UserScoringLock | Covered | |
| Structural edits hard-blocked during reflow | TD-04 blocked operations | Covered | |
| No queuing of structural edits | TD-04 deferred reflow coalescing | **Conflict** | S07 says "No queuing of structural edits." TD-04 describes deferred reflow coalescing where pending triggers are merged by subskill scope union. These may not conflict if "structural edits" means the user action (blocked) while "deferred reflow" means internal trigger coalescing. However, the language creates ambiguity. |
| No cancel-and-restart chaining | TD-04 | Covered | |
| Single logical transaction | TD-04 | Covered | |
| User must wait for current reflow before next structural edit | TD-04 blocked operations during lock | Covered | |

### S07 Section 7.7: Failure & Atomicity Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Atomic swap model: derived state computed in isolation, new state on success only | TD-04 reflow algorithm (atomic swap within Serializable transaction) | Covered | |
| User never sees partial state | TD-04 | Covered | |
| Hard timeout: 60 seconds per user reflow | TD-07 scoring lock timeout, TD-04 | **Conflict** | S07 specifies 60-second timeout. TD-03 SyncWriteGate specifies 60-second hard timeout. TD-04 RebuildGuard specifies 30-second timeout. The timeout values may apply to different mechanisms (UserScoringLock vs RebuildGuard), but S07's 60s for "individual user reflow" and TD-04's 30s for RebuildGuard could conflict for full rebuild scenarios. |
| Automatic retry: up to 3 attempts with short delay | TD-07 reflow transaction rollback (retry once, then 2-second delay) | **Conflict** | S07 says "up to 3 attempts." TD-07 describes "retry once" then fall back to full rebuild on next launch. The retry counts differ. |
| User remains in loading state during retries | TD-07 | Covered | |
| Complete failure: reflow marked failed in EventLog, revert to previous state, lock released | TD-07 reflow failure handling | Covered | |
| User notification on failure | TD-07 user-facing messaging (REFLOW_TRANSACTION_FAILED) | Covered | |
| Failed reflow logged for investigation | TD-07 EventLog entries (ReflowFailed) | Covered | |

### S07 Section 7.8: Performance Constraints

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| User-initiated: target sub-1-second | TD-06 Phase 2B (<150ms p95 scoped, <1s p95 full) | Covered | |
| Hard timeout: 60 seconds | TD-07, TD-04 | Covered | See timeout conflict above |
| Full scoring lock for duration, no partial reads | TD-04 | Covered | |
| System-initiated: parallel execution with concurrency cap | No explicit TD reference | **Gap** | S07 specifies parallel execution of system-initiated reflows with a concurrency cap. No TD addresses server-side parallel reflow orchestration. |
| System-initiated: 60-second timeout per user | TD-07 | Covered | |
| Global scoring lock + maintenance banner until all complete | No explicit TD reference | **Gap** | Same gap as §7.5.1 — global lock for system-initiated changes. |

### S07 Section 7.9: EventLog Integration

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| EventType canonical enumeration (S07 as single source of truth) | TD-02 EventTypeRef seed data | Covered | |
| 12 event types listed (AnchorEdit through IntegrityFlagAutoResolved) | TD-02 EventTypeRef seed data (16 rows) | Covered | TD-02 has additional types (ReflowComplete, SessionCompletion, RebuildStorageFailure) beyond S07's list |
| AnchorEdit | TD-02 EventTypeRef | Covered | |
| InstanceEdit | TD-02 EventTypeRef | Covered | |
| InstanceDeletion | TD-02 EventTypeRef | Covered | |
| SessionDeletion | TD-02 EventTypeRef | Covered | |
| SessionAutoDiscarded | TD-02 EventTypeRef | Covered | |
| PracticeBlockDeletion | TD-02 EventTypeRef | Covered | |
| DrillDeletion | TD-02 EventTypeRef | Covered | |
| SystemParameterChange | TD-02 EventTypeRef | Covered | |
| ReflowFailed | TD-02 EventTypeRef | Covered | |
| ReflowReverted | TD-02 EventTypeRef | Covered | |
| IntegrityFlagRaised | TD-02 EventTypeRef | Covered | |
| IntegrityFlagCleared | TD-02 EventTypeRef | Covered | |
| IntegrityFlagAutoResolved | TD-02 EventTypeRef | Covered | |

### S07 Section 7.10-7.11: Structural Guarantees & Derived State Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 6 structural guarantees | TD-04, TD-05, TD-07 | Covered | |
| Derived state materialised post-reflow, served authoritatively | TD-01, TD-03, TD-04 materialised tables | Covered | |
| No per-read derivation | TD-04 reflow design | Covered | |
| Materialised state = replaceable cache, not source of truth | TD-01 materialised state rule, TD-04 full rebuild | Covered | |
| If lost/corrupted, full reflow from raw data restores identically | TD-07 database corruption recovery, TD-04 full rebuild | Covered | |

---

---

## S08 — Practice Planning Layer (8v.a8)

### S08 Section 8.1: Core Planning Objects

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Planning layer strictly separated from scoring engine | TD-04 non-reflow triggers, TD-03 domain boundaries | Covered | |
| Calendar: single persistent object per user, perpetual | TD-02 CalendarDay table, TD-06 Phase 5 | Covered | |
| SlotCapacity default day-of-week pattern (7 values), system default 5 | TD-06 Phase 8 (calendar defaults screen) | Covered | |
| SlotCapacity = 0 represents rest day | TD-06 Phase 5 | Covered | |
| CalendarDay sparse persistence with default fallback | TD-02 CalendarDay table, TD-06 Phase 5 | Covered | |
| Slot: 1:1 with Drills, ordered within CalendarDay | TD-03 CalendarDay Slots payload shape | Covered | |
| Existing Slot assignments never overwritten by system actions | TD-06 Phase 5 (routine/schedule fill empty only) | Covered | |
| SlotCapacity cannot be reduced below filled Slots (hard block) | No explicit TD reference | **Gap** | S08 specifies a hard block preventing reduction below filled Slots. Not explicitly codified in a TD. |
| Routine: reusable ordered list, fixed DrillIDs and/or Generation Criteria | TD-02 Routine table, TD-03 payload | Covered | |
| Routines may not reference other Routines | TD-02, TD-03 | Covered | |
| Generation Criterion: Skill Area (optional), Drill Type (required multi-select), Subskill (optional), Mode (Weakest/Strength/Novelty/Random) | TD-03 Routine.Entries payload, TD-06 Phase 5 | Covered | |
| Criteria resolved fresh at application time, never stored as resolved DrillIDs | TD-06 Phase 5 | Covered | |
| No draft stage for Routine creation | No explicit TD reference | **Gap** | S08 explicitly states no draft stage. Not codified in a TD. |
| Routine referential integrity (Drill deleted/retired -> removed, empty -> auto-delete) | TD-04 Routine state machine | Covered | |
| Save as Manual (Clone): resolved result into new fixed-entry Routine | No explicit TD reference | **Gap** | S08 specifies a "Save as Manual" clone feature. Not codified in any TD. May be unimplemented. |
| Schedule: reusable multi-day blueprint, Fixed/Criterion/RoutineRef entries | TD-02 Schedule table, TD-06 Phase 5 | Covered | |
| Application Modes: List and Day Planning | TD-02 Schedule.ApplicationMode, TD-06 Phase 5 | Covered | |
| List Mode: sequential fill, wrap on exhaustion | TD-06 Phase 5 | Covered | |
| Day Planning Mode: N template days cycling, zero-entry = rest-day template | TD-06 Phase 5 | Covered | |
| CalendarDays with SlotCapacity = 0: skipped (List) or consume template position (DayPlanning) | No explicit TD reference | **Gap** | S08 specifies different handling of zero-capacity days between List and DayPlanning modes. The DayPlanning mode rule (zero-capacity days consume template position) may not be explicitly codified in a TD. |
| Schedule referential integrity (Drill/Routine deleted -> removed from entries) | TD-04 Schedule state machine | Covered | |
| Schedule auto-delete: List Mode when all entries removed; DayPlanning when all template days empty | No explicit TD reference | **Gap** | S08 specifies auto-delete conditions. TD-04 may not cover DayPlanning-specific auto-delete rule. |

### S08 Section 8.2: Application Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Application Preview: show resolved DrillIDs mapped to Slots | TD-06 Phase 5 (routine_apply_screen, schedule_apply_screen) | Covered | |
| Preview actions: Confirm, Discard, Reroll all, Reroll individual | TD-06 Phase 5 | Covered | |
| Reroll: exclude last 2 drills, reduced exclusion for small pools | TD-06 Phase 5 | Covered | |
| Fixed DrillID and Routine reference entries not rerollable | No explicit TD reference | **Gap** | S08 specifies these are not rerollable. Likely implemented but not codified in a TD. |
| Routine Application: single CalendarDay, fill available Slots in order, excess discarded | TD-06 Phase 5 (routine_application.dart) | Covered | |
| Schedule Application: date range, mode-specific mapping | TD-06 Phase 5 (schedule_application.dart) | Covered | |
| RoutineInstance: created on confirm, tracks owned Slots | TD-02 RoutineInstance table | Covered | |
| ScheduleInstance: created on confirm, tracks owned Slots across days | TD-02 ScheduleInstance table | Covered | |
| Slot Ownership: manual edits break ownership | TD-06 Phase 5 | Covered | |
| Unapply: clears owned Slots, deletes Instance record | TD-06 Phase 5 | Covered | |
| Multiple Instances coexist on same CalendarDays | TD-06 Phase 5 | Covered | |
| Instance snapshot behaviour: edits to source don't affect existing Instances | TD-06 Phase 5 | Covered | |
| Slot integrity on Drill deletion: Slot cleared, ownership broken | TD-04, TD-06 Phase 5 | Covered | |

### S08 Section 8.3: Execution & Completion

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Calendar-initiated practice: PracticeBlock from filled Slots in order | TD-06 Phase 5, Phase 4 | Covered | |
| Drill order is recommendation, not constraint | No explicit TD reference | **Gap** | S08 explicitly states order is a recommendation. Not codified in a TD. |
| Universal Completion Matching: Closed Sessions matched to CalendarDay Slots | TD-06 Phase 5 (completion_matching.dart) | Covered | |
| Matching rules: CompletionTimestamp date in home timezone, same DrillID | TD-06 Phase 5 | Covered | |
| Source-agnostic matching | TD-06 Phase 5 | Covered | |
| Only Closed Sessions trigger matching | TD-06 Phase 5 | Covered | |
| Matching always active across all PracticeBlocks | TD-06 Phase 5 | Covered | |
| Duplicate Drill: first earliest ordered incomplete Slot | TD-06 Phase 5 (first-match ordering) | Covered | |
| Technique Block Sessions participate in completion matching | No explicit TD reference | **Gap** | S08 explicitly states Technique Block Sessions participate. Likely implemented but not codified in a TD. |
| Completion Overflow: create additional Slot, increase SlotCapacity by 1, Manual ownership, Planned=false | TD-06 Phase 5 (completion overflow) | Covered | |
| Overflow scope: modifies persisted CalendarDay only, not default pattern | TD-06 Phase 5 | Covered | |
| No automatic correction or notification for overflow drift | No explicit TD reference | **Gap** | S08 explicitly prohibits automatic correction of overflow drift. Not codified in a TD. |
| Completion State: Incomplete, CompletedLinked, CompletedManual | TD-04 CalendarDay Slot state machine | Covered | |
| Session deletion reverts Slot to Incomplete, clears CompletingSessionID | No explicit TD reference | **Gap** | S08 specifies revert behaviour on Session deletion. May be implemented but not codified in a TD. |
| Calendar is advisory, not binding: no scoring penalty for deviation | TD-06 Phase 5, S08 §8.15 | Covered | |
| Past CalendarDays preserved as-is, incomplete Slots remain visible | TD-06 Phase 5 | Covered | |

### S08 Section 8.4: Plan Adherence

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Adherence = (Completed planned / Total planned) x 100 | TD-06 Phase 6 (plan_adherence_screen) | Covered | |
| Overflow excluded from numerator and denominator | TD-06 Phase 6 | Covered | |
| Manually completed Slots count as completed | No explicit TD reference | **Gap** | S08 states manually completed Slots count for adherence. Not codified in a TD. |
| Same-day manual additions included | No explicit TD reference | **Gap** | S08 states any deliberately placed Slot counts. Not codified in a TD. |
| Display: Planning Tab headline % (last 4 weeks) | TD-06 Phase 6 (plan_adherence_badge on Dashboard) | Covered | |
| Display: Review section detailed breakdown | TD-06 Phase 6 (plan_adherence_screen) | Covered | |
| Rollup boundaries: home timezone + week start day | No explicit TD reference | **Gap** | Same gap as S05. |
| Date range persistence: 1 hour, reset to 4 weeks | No explicit TD reference | **Gap** | Same gap as S05. |

### S08 Section 8.7: Weakness Detection Engine

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Ranked ordering of Subskills driving drill selection | TD-06 Phase 5 (weakness_detection.dart) | Covered | |
| Two-stage model: Subskill level then Drill level | TD-06 Phase 5 | Covered | |
| Priority 1: Incomplete windows ranked above fully saturated | TD-06 Phase 5 | Covered | |
| Priority 2: WeaknessIndex = (5 - WeightedAverage) x AllocationWeight | TD-06 Phase 5 | Covered | |
| Tiebreaking: lower WeightedAverage > higher AllocationWeight > alphabetical | TD-06 Phase 5 | Covered | |
| No-data subskills: WeaknessIndex = 5 x AllocationWeight | TD-06 Phase 5 | Covered | |
| Mode-specific ordering: Weakest, Strength, Novelty, Random | TD-06 Phase 5 (4 selection modes) | Covered | |
| Weakest: descending WI, then lowest avg score, then least recent, then alphabetical | TD-06 Phase 5 | Covered | |
| Strength: ascending WI, then highest avg, then most recent, then alphabetical | TD-06 Phase 5 | Covered | |
| Novelty: descending WI, then least recent Drill, no-history drills first | TD-06 Phase 5 | Covered | |
| Random: uniform random, no subskill ranking | TD-06 Phase 5 | Covered | |
| Technique Block integration: inherit Skill Area ranking position | TD-06 Phase 5 | Covered | |
| Technique Block granularity asymmetry: Skill Area level vs Subskill level | TD-06 Phase 5 | Covered | |

### S08 Section 8.8-8.9: Drill Type Filtering, Recency & Distribution

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Drill Type filtering strict, no fallback | TD-06 Phase 5 | Covered | |
| Unresolvable criterion: Slot left empty with notification | No explicit TD reference | **Gap** | S08 specifies notification for unresolvable criteria. Not codified in a TD. |
| Intra-application drill repetition block | TD-06 Phase 5 | Covered | |
| Exhausted pool: Slot left empty | TD-06 Phase 5 | Covered | |
| Cross-day independence: no cross-day recency enforcement | TD-06 Phase 5 | Covered | |

### S08 Section 8.10: Deterministic Resolution Algorithm

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 5-step algorithm (expand, truncate, process, handle empty, return preview) | TD-06 Phase 5 (routine_application, schedule_application) | Covered | |
| Inline Routine expansion to flat list | TD-06 Phase 5 | Covered | |
| Drill repetition block across entire flat list | TD-06 Phase 5 | Covered | |
| Schedule-specific: List Mode wrapping, DayPlanning cycling | TD-06 Phase 5 | Covered | |
| Determinism guarantee for Weakest/Strength/Novelty | TD-06 Phase 5 | Covered | |
| Random mode: seeded PRNG from user ID + application timestamp | No explicit TD reference | **Gap** | S08 specifies a seeded PRNG with specific seed derivation (hash of user ID + timestamp). Not codified in a TD. |

### S08 Sections 8.11-8.14: Timezone, UI, Settings

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Timezone model: home timezone for all Calendar operations | TD-06 Phase 5 | Covered | |
| Home timezone auto-detected, manual override in Settings | No explicit TD reference | **Gap** | S08 specifies auto-detect + manual override. Not codified in a TD. |
| Planning Tab: Calendar | Create dual-tab | TD-06 Phase 5 | Covered | |
| Calendar tab: 3-day rolling default, 2-week toggle | TD-06 Phase 5 (calendar_screen) | Covered | |
| Create tab: three tiles (Drill, Routine, Schedule) | TD-06 Phase 5 | Covered | |
| Drill creation: Save & Practice shortcut | No explicit TD reference | **Gap** | S08 specifies "Save & Practice" which launches Live Practice immediately after drill creation. Not codified in a TD. |
| Home Dashboard: Today's Slot Summary + two practice CTAs | TD-06 Phase 6 | Covered | |
| Notifications: daily at configured time, only if filled Slots, toggle on/off | S10 notifications (deferred per Known Deviations) | Covered | Acknowledged as deferred |
| Settings additions: SlotCapacity pattern, home timezone, week start day, notification toggle/time | TD-06 Phase 8 (settings screens) | Covered | Partially — week start day and timezone may not be explicitly codified |

---

---

## S09 — Golf Bag & Club Configuration (9v.a2)

### S09 Sections 9.1-9.2: Club Identity & Skill Area Mappings

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 36-type ClubType enumeration | TD-02 ClubType enum | Covered | |
| Multiple clubs of same ClubType permitted | TD-02 UserClub table (no UNIQUE on ClubType) | Covered | |
| No maximum bag size | No explicit TD reference | **Gap** | S09 states no bag size maximum. TD-02 has no constraint but the absence is implicit, not explicit. Low risk. |
| UserClub entity schema | TD-02 UserClub table | Covered | |
| UserSkillAreaClubMapping: ClubType -> Skill Area per user | TD-02 UserSkillAreaClubMapping table, TD-03 ClubRepository | Covered | |
| Mandatory mappings: Driver->Driving, Putter->Putting, i1-i9->Irons | TD-03 ClubRepository (S09 §9.2.3 default/mandatory mappings) | Covered | |
| Default mappings table (7 Skill Areas with defaults) | TD-03 ClubRepository, TD-06 Phase 3 | Covered | |
| Multi-area assignment: single ClubType to multiple Skill Areas | TD-02, TD-03 | Covered | |

### S09 Section 9.3: Hard Gating Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Scored drill requires >= 1 eligible club for Skill Area | TD-06 Phase 3 | Covered | |
| Gate applies to: creation, adoption, Routine, Schedule, Calendar Slot, Session | No explicit TD reference for all 6 contexts | **Gap** | S09 lists 6 specific contexts where the gate applies. TD-06 Phase 3 covers drill creation and Session start, but may not explicitly gate Routine/Schedule/Calendar Slot addition. |
| Technique Block exception: no club required | TD-02 MaterialisedWindowState constraint, TD-06 Phase 4 | Covered | |
| Gate on club retirement: activates if last eligible club | No explicit TD reference | **Gap** | S09 specifies automatic gate activation when last eligible club is retired. TD-03 ClubRepository may not explicitly handle this cascade. |
| Existing drills/Routines/Schedules not deleted, just cannot execute | No explicit TD reference | **Gap** | S09 specifies preservation but execution block. Not explicitly codified in a TD. |

### S09 Section 9.4: Club Selection Mode

All items covered — identical to S00 §8 and S04 §4.5 analysis. Covered by TD-02 and TD-06 Phase 4.

### S09 Section 9.5: Club Performance Profiles

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| ClubPerformanceProfile: time-versioned, optional | TD-02 ClubPerformanceProfile table, TD-03 ClubRepository | Covered | |
| Active profile: most recent with EffectiveFromDate <= timestamp | TD-02, TD-03 ClubRepository.getActiveProfile() | Covered | |
| 4 asymmetric dispersion values (Left, Right, Short, Long) | TD-02 ClubPerformanceProfile table | Covered | |
| Dispersion analytics-only, no scoring/target impact | TD-02, S09 structural guarantee | Covered | |
| Bulk performance updates: creates new rows, preserves history | TD-03 ClubRepository.addPerformanceProfile() | Covered | |
| No scoring impact, no reflow triggered | TD-04 non-reflow triggers | Covered | |

### S09 Section 9.6: Target Resolution

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Target resolution at Instance creation time | TD-02 Instance table (ResolvedTarget columns) | Covered | |
| Snapshot-stored: ResolvedTargetDistance/Width/Depth | TD-02 Instance columns | Covered | |
| Subsequent carry edits do not alter historical Instances | Implicit in snapshot design | Covered | |

### S09 Section 9.7: Club Lifecycle

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Retirement: hidden, historical preserved, no scoring impact, no reflow | TD-04 UserClub state machine | Covered | |
| Retirement blocked if club has Instance references -> retire only | TD-03 ClubRepository, TD-04 | Covered | |
| Deletion: only if no Instance references and no performance profiles | TD-03 ClubRepository | Covered | |
| No scoring impact from deletion | TD-04 non-reflow triggers | Covered | |

### S09 Section 9.8: Bag Setup & Onboarding

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Bag setup required during onboarding | No explicit TD reference | **Gap** | S09 specifies onboarding requires bag setup. No TD addresses onboarding flow. |
| Standard 14-club preset | No explicit TD reference | **Gap** | S09 defines a specific 14-club preset (Driver, 3W, 5W, 4i-9i, PW, GW, SW, LW, Putter). Not codified in any TD or seed data. |
| Quick-start: accept immediately or customise before confirming | No explicit TD reference | **Gap** | S09 specifies quick-start UX. Not in any TD. |
| Default mappings applied on preset acceptance | TD-03 ClubRepository (default mappings) | Covered | |

### S09 Section 9.9: Measurement Unit System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Distance: Yards or Metres | TD-06 Phase 8 (settings), S10 reference | Covered | |
| Small Length: Inches or Centimetres | TD-06 Phase 8 | Covered | |
| Speed (future): mph or km/h | No explicit TD reference | **Gap** | S09 declares speed units as future-compatible. No TD addresses this. Deferred is expected. |
| Weight (future): grams or ounces | No explicit TD reference | **Gap** | Same — future-compatible, not in TDs. |
| Canonical base units: Metres, Centimetres, m/s, grams | No explicit TD reference | **Gap** | S09 specifies internal canonical storage units. No TD codifies which base units are used for internal storage. |
| Unit changes: display-layer only, no data mutation, no scoring impact | Implicit in design | Covered | |

### S09 Sections 9.10-9.13: Analytics, Data Model, Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Analytics usage (overlays, future target suggestions, gapping) | No explicit TD reference | **Gap** | S09 lists future analytics uses. No TD addresses these. |
| Data model additions: UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping | TD-02 tables | Covered | |
| Instance extension: SelectedClub, ResolvedTarget fields | TD-02 Instance table | Covered | |
| Referential integrity rules (5 rules listed) | TD-02 FK constraints, TD-03 repository guards | Covered | |
| Indexing (3 indexes) | TD-02 §7 index coverage | Covered | |
| 12 structural guarantees | TD-01 through TD-07 combined | Covered | |

---

---

## S10 — Settings & Configuration (10v.a5)

### S10 Section 10.1: Configuration Scope

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All settings per-user, no device-level overrides | TD-01, TD-06 Phase 8 | Covered | |
| No global presets, no onboarding modes | TD-06 Phase 8 | Covered | |
| Home timezone configured per user | TD-06 Phase 8 (calendar defaults) | Covered | |

### S10 Section 10.2: Scoring Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| System-governed parameters listed (allocations, weighting, window size, mechanics, weakness algorithm) | TD-04 scope determination, TD-02 | Covered | |
| Integrity detection system-governed | TD-07 Phase 4 | Covered | |

### S10 Section 10.3: Drill Library Management

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| State model: Active, Retired, Deleted (no Hidden) | TD-04 Drill state machine | Covered | |
| Library is flat, filter-driven (no tagging, no folders) | No explicit TD reference | **Gap** | S10 explicitly prohibits tagging and folder hierarchy. No TD codifies this. Implicit in Phase 3 drill screens. |
| Filters: Skill Area, Drill Type, Subskill, Scoring Mode | TD-06 Phase 3 (skill_area_picker, drill screens) | Covered | |
| Drill duplication rules | TD-03 DrillRepository, TD-06 Phase 3 | Covered | |

### S10 Section 10.4: Anchor Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Min < Scratch < Pro strictly increasing | TD-05 TC-13.x anchor validation | Covered | |
| No additional realism constraints | Implicit (no TD introduces additional constraints) | Covered | |
| Anchors editable one drill at a time | No explicit TD reference | **Gap** | S10 states anchor edits are one-drill-at-a-time. No TD codifies this constraint. Implicit in TD-03 DrillRepository API (per-drill methods). |
| Anchor edits blocked in Retired state, must reactivate | No explicit TD reference | **Gap** | Repeat of S04 gap. |
| All anchor edits trigger reflow | TD-04 reflow trigger catalogue | Covered | |

### S10 Section 10.5: Confirmation Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Soft confirmation (modal: "This action will recalculate your scores") | TD-06 Phase 8 (confirmation_dialog.dart) | Covered | |
| Soft confirmation applies to: anchor edit, post-close Instance edit, Session deletion, Drill deletion, PracticeBlock deletion | TD-06 Phase 8 | Covered | |
| No preview simulation, no impact estimation | No explicit TD reference | **Gap** | S10 explicitly prohibits preview simulation and impact estimation. Not codified. |
| Strong confirmation (type-to-confirm) for account deletion | TD-06 Phase 8 (confirmation_dialog.dart strong variant) | Covered | |

### S10 Section 10.6: Units & Measurement

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Distance: Yards or Metres (global preference) | TD-06 Phase 8 | Covered | |
| Small Length: Inches or Centimetres | TD-06 Phase 8 | Covered | |
| Speed/Raw Metric: global default per metric, per-drill override at creation, unit immutable post-creation | No explicit TD reference | **Gap** | S10 specifies per-drill unit override at creation time with immutability. No TD addresses per-drill unit selection. |
| Canonical internal storage | S09 canonical base units gap applies | **Gap** | Same gap as S09 §9.9. |

### S10 Section 10.7: Execution Defaults

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Default Club Selection Mode configurable per Skill Area | TD-06 Phase 8 (execution_defaults_screen) | Covered | |
| On drill creation, pre-filled from Skill Area default, user may override | TD-06 Phase 8 | Covered | |
| ClubSelectionMode immutable after drill creation | TD-03 structural immutability guard | **Conflict** | Same conflict as S00 — S10 states ClubSelectionMode immutable, TD-03 guard list does not include it. |
| PracticeBlock auto-end: 4 hours (not user-configurable) | TD-04 PracticeBlock state machine | Covered | |
| Session inactivity auto-close: 2 hours (not user-configurable) | TD-04 Session state machine (2h timer) | Covered | |

### S10 Section 10.8: Calendar Defaults

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| System default SlotCapacity: 5 per day | TD-06 Phase 8 (calendar_defaults_screen) | Covered | |
| User modifiable 7-day pattern | TD-06 Phase 8 | Covered | |
| Changes apply only to future non-persisted CalendarDays | TD-06 Phase 5/8 | Covered | |
| No adaptive behaviour | TD-06 Phase 8 | Covered | |

### S10 Section 10.9: Analytics Preferences

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Default Analysis resolution: Daily/Weekly/Monthly | TD-06 Phase 8 | Covered | |
| Week start day: Monday or Sunday | No explicit TD reference | **Gap** | S10 confirms week start day setting. Same gap from S05/S08 — not codified in a TD. |
| Date range persistence: 1 hour from last visit, resets to defaults | No explicit TD reference | **Gap** | Same gap from S05/S08. |

### S10 Section 10.10: Notifications

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Optional daily practice reminder with configurable time | Known Deviation in CLAUDE.md | Covered | Acknowledged as deferred: "flutter_local_notifications deferred to post-V1" |
| No reminder on rest days or all-completed days | Not implemented | Covered | Deferred |
| Per-user toggle on/off | TD-06 Phase 8 (preferences) | Covered | Toggle persisted but not functional |

### S10 Section 10.11: Account Controls

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Data Export: JSON full export | Known Deviation in CLAUDE.md | Covered | Acknowledged: "Data export stubbed — placeholder" |
| Optional CSV session summary | Not implemented | Covered | Deferred |
| No re-import in V1 | Not implemented | Covered | Deferred |
| Full Account Deletion: hard delete + cascade all entities | Known Deviation in CLAUDE.md | Covered | "Local cascade only. Server-side not deleted." |
| Strong confirmation required | TD-06 Phase 8 | Covered | |

---

---

## S11 — Metrics Integrity & Safeguards (11v.a5)

### S11 Section 11.1: Core Philosophy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Strictly observational: detect and surface, never alter scoring | TD-05 TC-11.1.5 (IntegrityFlag no scoring impact), TD-07 | Covered | |
| 6 allowed actions (detect, flag, surface, log) | TD-07, TD-06 Phase 4 | Covered | |
| 7 prohibited actions (suppress, alter, block, trigger reflow, freeze, require confirm, auto-adjust) | TD-04 non-reflow triggers (IntegrityFlag/IntegritySuppressed not triggers) | Covered | |
| No behavioural modelling, statistical detection, anti-gaming | S11 §11.7 intentionally omitted sections | Covered | No TD introduces any of these |

### S11 Section 11.2: Scope & Purpose

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Fat-finger detection on numeric fields only | TD-07 Phase 4 | Covered | |
| Applies to: Continuous Measurement, Raw Data Entry | TD-02 MetricSchema | Covered | |
| Excluded: Grid Cell Selection, Binary Hit/Miss | TD-02 MetricSchema (no bounds on these) | Covered | |
| Technique Block duration included (HardMin=0, HardMax=43200) | No explicit TD reference | **Gap** | S11 specifies Technique Block duration bounds (0-43200 seconds). Not explicitly codified in TD-02 MetricSchema seed data. |
| Excluded: derived percentages, scores, averages, aggregated metrics | TD-04 (only raw metrics checked) | Covered | |

### S11 Section 11.3: Schema Plausibility Bounds

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| HardMinInput and HardMaxInput on MetricSchema | TD-02 MetricSchema table | Covered | |
| System-defined, immutable, not user/drill/per-user editable | TD-02 reference table design | Covered | |
| Not reflow triggers | TD-04 non-reflow triggers | Covered | |
| Negativity governed by HardMinInput (no separate flag) | No explicit TD reference | **Gap** | S11 specifies negativity is governed by HardMinInput (negative HardMinInput allows negative values). Not codified in a TD. Implicit in schema design. |
| Zero treated like any other value | No explicit TD reference | **Gap** | S11 specifies zero has no special treatment. Not codified in a TD. |
| Illustrative bounds table (Carry 0-500m, Lateral -200-200m, etc.) | TD-02 MetricSchema seed data | Covered | Values in seed data should match |

### S11 Section 11.4: Detection Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Evaluation at Instance save and post-close edit (event-driven) | TD-07 Phase 4 | Covered | |
| No deferred batch, no Session-close sweep, no scheduled re-evaluation | No explicit TD reference | **Gap** | S11 explicitly prohibits batch/sweep/scheduled evaluation. Not codified in a TD. |
| Breach: RawMetric < HardMinInput or > HardMaxInput | TD-07 | Covered | |
| Boundary values (exactly equal) not in breach | No explicit TD reference | **Gap** | S11 specifies inclusive boundaries (equal = not breach). Important for test cases but not explicitly stated in any TD. |
| On breach: Instance saved normally, scoring proceeds, window entry proceeds, flag set, EventLog written | TD-05 TC-11.1.5, TD-07 | Covered | |

### S11 Section 11.5: Session-Level Flag

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| IntegrityFlag: simple boolean on Session | TD-02 Session.IntegrityFlag | Covered | |
| >= 1 Instance in breach -> true; all within bounds -> false | TD-07 Phase 4 | Covered | |
| No severity levels, breach counts, graduated indicators | No explicit TD reference | **Gap** | S11 explicitly prohibits graduated indicators. Not codified. |
| Auto-resolution: state-derived, corrective edit resolves | TD-07 | Covered | |
| IntegrityFlagAutoResolved EventLog entry | TD-02 EventTypeRef | Covered | |
| UI indicator: subtle warning icon at Session level only | TD-06 Phase 6 (session_history_screen) | Covered | |
| Indicator NOT in: SkillScore, Overall/Skill Area displays, Analysis trends, Window Detail | TD-06 Phase 6 | Covered | |

### S11 Section 11.6: Manual Clear & Suppression

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| User may clear IntegrityFlag on any flagged Session | TD-06 Phase 8 (IntegritySuppressed toggle) | Covered | |
| On clear: UI indicator removed, IntegritySuppressed = true, EventLog written | TD-06 Phase 8 | Covered | |
| Suppression resets on any Instance edit | TD-06 Phase 8 | Covered | |
| Suppression does not survive reflow | TD-06 Phase 8 (IntegritySuppressed reset) | Covered | |
| Suppression is per-Session, not global | TD-06 Phase 8 | Covered | |
| Suppression does not block detection for new Instances | No explicit TD reference | **Gap** | S11 specifies suppression does not block future detection. Not codified in a TD. |
| Reflow interaction: IntegritySuppressed cleared as side-effect of reflow | TD-06 Phase 2B (IntegritySuppressed reset) | Covered | |
| 4 constraints on clear action (no alter logic, no remove logs, no modify values, no permanent exemption) | Implicit in design | Covered | |

### S11 Section 11.7: Intentionally Omitted

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Spike Detection not implemented | No TD introduces spike detection | Covered | |
| Minimum Attempt Thresholds not implemented | No TD introduces minimum thresholds | Covered | |
| Anti-Gaming Controls not implemented | No TD introduces anti-gaming | Covered | |
| Manual Override Flags not implemented | No TD introduces manual flagging | Covered | |

### S11 Section 11.8-11.9: EventLog & Data Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 3 event types extending S07 canonical enumeration | TD-02 EventTypeRef seed data | Covered | |
| Session entity extension: IntegrityFlag, IntegritySuppressed | TD-02 Session table | Covered | |
| MetricSchema extension: HardMinInput, HardMaxInput | TD-02 MetricSchema table | Covered | |
| No scoring impact for all additions | TD-04, TD-05 | Covered | |

---

---

## S12 — UI/UX Structural Architecture (12v.a5)

### S12 Section 12.1: Architectural Philosophy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 5 governing principles (practice-first, deterministic, cross-domain consistency, state isolation, progressive density) | No explicit TD reference | **Gap** | S12 defines 5 architectural principles. No TD document codifies these principles explicitly. They are implicitly followed in TD-06 screen designs. |

### S12 Section 12.2: Top-Level Navigation Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Three-domain bottom navigation: Plan, Track, Review | TD-06 Phase 1 (ShellScreen, BottomNavigationBar) | Covered | |
| Home Dashboard as persistent launch layer above tabs | No explicit TD reference | **Gap** | S12 specifies Home Dashboard as a persistent launch layer. TD-06 Phase 1 only specifies ShellScreen with 3 tabs; no Home Dashboard is mentioned in any TD. (Note: now implemented per plan, but not in any TD.) |
| Home accessible via top-left Home control from any tab | No explicit TD reference | **Gap** | S12 specifies a Home icon on all tabs. Not in any TD. |
| Tapping Home does not reset current tab state | No explicit TD reference | **Gap** | S12 specifies tab state preservation on Home navigation. Not codified. |
| Settings via gear icon on Home Dashboard only | TD-06 Phase 8 (AppBar gear icon) | Partial | TD-06 Phase 8 adds gear icon but doesn't specify Home-only restriction. |
| Live Practice as full-screen immersive state | TD-06 Phase 4 (practice screens) | Covered | |
| Bottom nav hidden during Live Practice | TD-06 Phase 4 | Covered | Implicit in practice screen design. |
| Cross-tab navigation disabled during Live Practice | TD-06 Phase 4 | Covered | |

### S12 Section 12.2.2: Live Practice Entry Points

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Home Dashboard: Start Today's Practice | No explicit TD reference | **Gap** | Entry point not in any TD (Home Dashboard gap). |
| Home Dashboard: Start Clean Practice | No explicit TD reference | **Gap** | Same — Home Dashboard gap. |
| Track: Start action on Drill or Routine | TD-06 Phase 4 (practice_queue_screen) | Covered | |
| Plan → Calendar: Start Practice from Slot | TD-06 Phase 5 (calendar_day_detail_screen) | Covered | |
| Plan → Create: Save & Practice | TD-06 Phase 3 (drill_create_screen) | Partial | TD-06 Phase 3 mentions drill creation; Save & Practice action not explicitly specified. |
| Any Drill detail page: Practice This Drill | TD-06 Phase 3 (drill_detail_screen) | Partial | Not explicitly listed as an entry point in TD-06. |

### S12 Section 12.3: Home Dashboard

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Overall Score (0–1000) on Home | No explicit TD reference | **Gap** | Home Dashboard not in any TD. |
| Today's Slot Summary (filled / capacity + progress indicator) | No explicit TD reference | **Gap** | Home Dashboard not in any TD. |
| Start Today's Practice button (conditional on filled Slots) | No explicit TD reference | **Gap** | Home Dashboard not in any TD. |
| Start Clean Practice button (always visible) | No explicit TD reference | **Gap** | Home Dashboard not in any TD. |
| Home exclusions (no weakness highlights, no trend sparklines, no plan adherence, no last session) | No explicit TD reference | **Gap** | Explicit exclusions not codified. |
| No mini-picker or Quick Start selector on Home | No explicit TD reference | **Gap** | Explicit prohibition not codified. |

### S12 Section 12.4: Plan Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Dual-tab: Calendar, Create | TD-06 Phase 5 (PlanTab) | Covered | |
| 3-day rolling view (default) | TD-06 Phase 5 (calendar_screen) | Covered | |
| Horizontally swipeable infinitely in both directions | No explicit TD reference | **Gap** | S12 specifies infinite horizontal swipe. TD-06 Phase 5 specifies "3-day rolling + 2-week toggle" but not swipe behaviour details. |
| Per-slot completion state indicators | TD-06 Phase 5 (slot_tile) | Covered | |
| Per-slot ownership indicators (Manual, RoutineInstance, ScheduleInstance) | TD-06 Phase 5 (slot_tile) | Covered | |
| Tap empty Slot → Calendar Bottom Drawer | TD-06 Phase 5 (calendar_day_detail_screen) | Partial | TD-06 specifies day detail screen; bottom drawer pattern not explicitly described in a TD. |
| Tap filled Slot → Slot Detail (drill info, replace, remove, start practice, ownership) | TD-06 Phase 5 (calendar_day_detail_screen, slot_tile) | Covered | |
| Drag and drop into empty Slots only | No explicit TD reference | **Gap** | S12 specifies drag-and-drop behaviour. No TD addresses drag-and-drop mechanics. |
| Drop onto filled Slot visually blocked | No explicit TD reference | **Gap** | Same drag-and-drop gap. |
| 2-Week View: 14-day grid, compact summary (X/Y) | TD-06 Phase 5 (calendar_screen "2-week toggle") | Covered | |
| 2-Week View: tap day → switch to 3-Day centred on date | No explicit TD reference | **Gap** | S12 specifies tap-to-switch behaviour. Not in any TD. |
| 2-Week View: drag Drill onto day fills first empty Slot | No explicit TD reference | **Gap** | Drag-and-drop in 2-week view not codified. |
| 2-Week View: drag Routine fills remaining Slots | No explicit TD reference | **Gap** | Same drag-and-drop gap. |
| 2-Week View: drag Schedule opens date picker + preview | No explicit TD reference | **Gap** | Same drag-and-drop gap. |
| 2-Week View exclusions (no Slot editing, no tap-to-open, no reorder, no ownership) | No explicit TD reference | **Gap** | Explicit 2-Week View restrictions not codified. |
| Calendar toggle: 3-Day / 2-Week (explicit, always visible, no gesture dependency) | No explicit TD reference | **Gap** | S12 specifies "no pinch-to-zoom, no hidden interactions". Not codified. |
| Calendar Bottom Drawer: segmented (Drills / Routines / Schedules), search, filters, drag handles | No explicit TD reference | **Gap** | S12 defines a specific bottom drawer pattern. TD-06 Phase 5 mentions calendar_day_detail_screen but not a bottom drawer with this structure. |
| Create surface: 3 equal tiles with descriptions | TD-06 Phase 5 (routine_create_screen, schedule_create_screen), Phase 3 (drill_create_screen) | Partial | TD-06 lists create screens but not the tile-based entry surface described in S12. |
| Save & Practice action after drill creation | No explicit TD reference | **Gap** | S12 §12.4.5 specifies this explicitly. Not in any TD. |

### S12 Section 12.5: Track Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Segmented control: Drills / Routines | TD-06 Phase 3 (practice_pool_screen), Phase 5 (routine_list_screen) | Covered | |
| Filters persist independently per segment | No explicit TD reference | **Gap** | S12 specifies independent filter persistence. Not codified. |
| Reset Filters control visible when active | No explicit TD reference | **Gap** | Not codified. |
| Segment switch does not clear other segment's filters | No explicit TD reference | **Gap** | Not codified. |
| Scroll position does not persist across segment switches | No explicit TD reference | **Gap** | Not codified. |
| Drills grouped into 7 Skill Area sections (accordion) | TD-06 Phase 3 (practice_pool_screen, skill_area_picker) | Covered | |
| Filters: Skill Area, Drill Type, Subskill, Scoring Mode | TD-06 Phase 3 (skill_area_picker) | Partial | TD-06 mentions skill_area_picker but may not list all 4 filter dimensions explicitly. |
| No flat global list as default | No explicit TD reference | **Gap** | S12 prohibits flat default. Implicit in accordion design but not codified. |
| Routine list: flat, sorted by most recently used | No explicit TD reference | **Gap** | S12 specifies flat + MRU sort. Not codified. |
| Track is read-only for drill details | TD-06 Phase 3 (drill_detail_screen) | Partial | TD-06 Phase 3 has drill_detail_screen but read-only restriction not explicit. |
| "Edit Drill" button navigates to Plan | No explicit TD reference | **Gap** | S12 specifies cross-navigation to Plan for editing. Not codified. |
| "Edit Drill" hidden for System Drills | No explicit TD reference | **Gap** | Not codified. |

### S12 Section 12.6: Review Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Dual-tab: Dashboard / Analysis | TD-06 Phase 6 (ReviewTab) | Covered | |
| Dashboard: Overall Score, Heatmap, Trend Snapshot, Plan Adherence, CTA | TD-06 Phase 6 (review_dashboard_screen) | Covered | |
| Heatmap: 7 tiles, expandable inline to Subskills (accordion) | TD-06 Phase 6 (skill_area_heatmap) | Covered | |
| Trend Snapshot auto-switches context on Heatmap expansion | TD-06 Phase 6 (trend_snapshot) | Partial | TD-06 mentions trend_snapshot widget but auto-context-switch on heatmap expand may not be explicit. |
| Weakness Ranking accessible from Review Dashboard CTA | TD-06 Phase 6 (weakness_ranking_screen) | Covered | |
| Weakness Ranking accessible from Planning tab | TD-06 Phase 5 | Partial | TD-06 Phase 5 doesn't explicitly list weakness ranking access from Plan. |
| Analysis chart toggle: Performance / Volume / Both | TD-06 Phase 6 (analysis_screen) | Covered | |
| 4 top filters always visible: Scope, Drill Type, Time Resolution, Date Range | TD-06 Phase 6 (analysis_filters) | Covered | |
| Technique Block excluded from Drill Type filter (visible at Drill scope only) | No explicit TD reference | **Gap** | S12 specifies Technique Block filter exclusion rules. Not codified in a TD. |
| Conditional filters based on Scope (Skill Area → subskill selector; Drill → drill selector) | TD-06 Phase 6 (analysis_filters) | Covered | |
| Drill scope: auto-lock Drill Type for Technique Block | No explicit TD reference | **Gap** | Not codified. |
| Session History button at Drill scope | TD-06 Phase 6 (session_history_screen) | Covered | |
| Volume chart stacking: primary by Skill Area, shade by Drill Type | TD-06 Phase 6 (volume_chart) | Partial | TD-06 mentions volume_chart but shade-within-segment detail may not be explicit. |
| Legend: 7 Skill Areas + shade key (not 21 segments) | No explicit TD reference | **Gap** | Specific legend requirement not codified. |
| Comparative Analytics: time range vs time range (V1) | No explicit TD reference | **Gap** | S12 §12.6.3 specifies comparison mode. Not addressed in any TD. |
| Compare toggle/button in Analysis | No explicit TD reference | **Gap** | Not codified. |
| Two date range selectors when comparison active | No explicit TD reference | **Gap** | Not codified. |
| Drill vs Drill, Skill Area vs Skill Area, etc. deferred to V2 | No explicit TD reference | **Gap** | V2 deferrals not codified (informational). |

### S12 Section 12.7-12.8: Live Practice Architecture & Post-Session Summary

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Entry from any §12.2.2 entry point creates PracticeBlock | TD-04 PracticeBlock state machine, TD-06 Phase 4 | Covered | |
| State isolation: bottom nav hidden, no cross-tab | TD-06 Phase 4 | Covered | |
| Lifecycle timers: 4-hour PB auto-end, 2-hour Session inactivity | TD-04 state machines | Covered | |
| Exit always routes to Home Dashboard | No explicit TD reference | **Gap** | S12 specifies "Exit always routes to Home." TD-04 routes to first route. Home Dashboard routing not in any TD. |
| Post-Session Summary: final 0–5 scores, Overall Score delta, key statistics | TD-06 Phase 4 (post_session_summary_screen) | Partial | TD-06 lists the screen but may not specify all content (delta, statistics). |
| Summary is a dedicated state (not modal/toast) | No explicit TD reference | **Gap** | S12 specifies dedicated state. Not codified. |
| Must tap Done to proceed | TD-06 Phase 4 | Covered | |
| No automatic timeout/auto-dismiss | No explicit TD reference | **Gap** | Not codified. |
| Scores reflect post-reflow state | No explicit TD reference | **Gap** | Not codified. |

### S12 Sections 12.9-12.12: Consistency Model, Cross-Shortcuts, Guarantees, Non-Goals

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Consistent two-tab internal pattern across Plan/Track/Review | TD-06 Phases 3-6 | Covered | Implicitly followed. |
| 7 cross-shortcuts defined | No explicit TD reference | **Gap** | S12 §12.10.1 lists 7 specific cross-shortcuts. No TD catalogues cross-domain shortcuts. |
| Shortcut philosophy (asymmetrical, secondary) | No explicit TD reference | **Gap** | Not codified. |
| 10 interaction guarantees | No explicit TD reference | **Gap** | S12 §12.11 lists 10 structural guarantees. Not codified in a TD as a set. Individual guarantees are covered by TD-04 and TD-06 implicitly. |
| 7 explicit non-goals | No explicit TD reference | **Gap** | S12 §12.12 lists explicit exclusions. Not codified. |

---

---

## S13 — Live Practice Workflow (13v.a7)

### S13 Section 13.1: Architectural Positioning

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Immersive execution state (not a tab) | TD-06 Phase 4 | Covered | |
| Bottom nav hidden, cross-tab disabled | TD-06 Phase 4 | Covered | |
| Only one PracticeBlock per user | TD-04 PracticeBlock state machine (single active) | Covered | |
| Only one authoritative active Session at any time | TD-04 Session state machine | Covered | |
| Every Session created through PracticeEntry | TD-02 PracticeEntry table, TD-04 | Covered | |
| Hierarchy: App → PracticeBlock → PracticeEntry → Session → Set → Instance | TD-02 schema hierarchy | Covered | |

### S13 Section 13.2: PracticeBlock Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| PracticeBlock persists only if ≥1 Session at closure | TD-04 PracticeBlock state machine | Covered | |
| DrillOrder superseded by PracticeEntry for Live Practice queue | TD-02 PracticeEntry table | Covered | |
| DrillOrder remains as creation-time snapshot | TD-02 PracticeBlock.DrillOrder | Covered | |

### S13 Section 13.2.1: Entry Point Queue Population

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Start Today's Practice: pre-loaded from CalendarDay filled Slots | No explicit TD reference | **Gap** | Home Dashboard entry point not in any TD. |
| Start Clean Practice: empty queue | No explicit TD reference | **Gap** | Home Dashboard entry point not in any TD. |
| Start from Track: single Drill or Routine creates PracticeEntries | TD-06 Phase 4 (practice_queue_screen) | Covered | |
| Routine entries: Generation Criteria resolved at launch time | TD-06 Phase 5 | Covered | |
| Save & Practice from Plan → Create | No explicit TD reference | **Gap** | Not in any TD. |
| Origin surface not stored on PracticeBlock | TD-02 PracticeBlock table (no origin field) | Covered | Implicit. |
| Exit always routes to Home | No explicit TD reference | **Gap** | Same Home routing gap. |

### S13 Section 13.3: PracticeEntry Structure

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| PracticeEntry schema (7 fields) | TD-02 PracticeEntry table | Covered | |
| 3-state lifecycle: PendingDrill → ActiveSession → CompletedSession | TD-04 PracticeEntry state machine | Covered | |
| No transition skipping | TD-04 | Covered | |
| ActiveSession → PendingDrill (Restart) | TD-04 | Covered | |
| ActiveSession → removed (Discard + remove) | TD-04, TD-03 PracticeRepository | Covered | |
| CompletedSession → removed (Session deletion + reflow) | TD-04, TD-03 PracticeRepository | Covered | |
| 4 prohibited states | TD-04 state machine constraints | Covered | |

### S13 Section 13.4: Queue Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Queue edits never mutate Calendar state | TD-06 Phase 4/5 (calendar independence) | Covered | |
| Add drill from Practice Pool within Live Practice | TD-06 Phase 4 (practice_queue_screen) | Covered | |
| Reorder PendingDrill entries | TD-06 Phase 4 | Covered | |
| Remove PendingDrill (no scoring impact) | TD-04 | Covered | |
| Remove CompletedSession (cascade + reflow) | TD-04 | Covered | |
| Duplicate: creates new PendingDrill with same DrillID, inserted after source | TD-06 Phase 4 | Partial | TD-06 mentions practice_entry_card but explicit duplicate-after-source positioning may not be specified. |
| Create Drill from Session (drill duplication) | No explicit TD reference | **Gap** | S13 specifies creating a new User Custom Drill from a CompletedSession. Not explicitly addressed in any TD. |
| Queue editing during Active Session: restrictions (ActiveSession entry immovable, no other drill startable, CompletedSession removal blocked) | TD-04 state machine constraints | Covered | |

### S13 Section 13.5: Session Lifecycle

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Starting a drill: 5-step atomic sequence | TD-04, TD-03 PracticeRepository | Covered | |
| Session inherits all structural properties from Drill | TD-02 Session table, TD-04 | Covered | |
| Active Session constraint (no concurrent execution) | TD-04 | Covered | |
| Structured Completion: auto-close on final Instance of final Set | TD-04 Session state machine | Covered | |
| Manual End for unstructured drills | TD-04 | Covered | |
| Auto-Close (2h inactivity) | TD-04 Session state machine (2h timer) | Covered | |
| Auto-Close: zero Instances → discard | TD-04 | Covered | |
| Auto-Close: structured drill with incomplete Sets → discard | TD-04 | Covered | |
| Passive notification on next app open | TD-07 | Partial | TD-07 mentions passive notifications but may not specify this exact scenario. |
| Restart: 4-step atomic sequence | TD-04 | Covered | |
| Discard: hard-delete Session, Sets, Instances | TD-04, TD-03 | Covered | |
| Discard: no scoring, no window entry, no reflow, no EventLog | TD-04 non-reflow triggers | Covered | |

### S13 Section 13.6: Deletion & Reflow Behaviour

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Removing PendingDrill: free, no impact | TD-04 | Covered | |
| Removing CompletedSession: 5-step cascade + reflow | TD-04, TD-03 | Covered | |
| Removing ActiveSession: not direct, must discard first | TD-04 state machine | Covered | |
| Reflow lock interaction: Instance logging blocked during reflow | TD-07 (reflow lock) | Covered | |
| No client-side Instance buffering during lock | No explicit TD reference | **Gap** | S13 explicitly prohibits client-side buffering during reflow lock. Not codified. |
| CompletedSession removal blocked during Active Session (to prevent reflow interruption) | TD-04 | Covered | |
| Source Drill deletion during active PracticeBlock: PendingDrill removed, CompletedSession unaffected | No explicit TD reference | **Gap** | S13 §13.6.5 specifies cascade behaviour for drill deletion during active PB. Not explicitly addressed in any TD. |
| Empty PB after PendingDrill removal → auto-delete | TD-04 PracticeBlock (no Sessions → discard) | Covered | |

### S13 Section 13.7: Multiple Executions of Same Drill

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Same DrillID may appear multiple times in PracticeBlock | TD-02 PracticeEntry (no uniqueness on DrillID) | Covered | |
| Each execution produces independent Session, window entry, deletion, completion matching | TD-04, TD-02 | Covered | |
| No limit on executions per PracticeBlock | No explicit TD reference | **Gap** | S13 explicitly states no limit. Not codified (implicit in schema design). |

### S13 Section 13.8: Technique Block Handling

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Same PracticeEntry lifecycle as scored drills | TD-04 | Covered | |
| No scoring anchors, no 0–5 score, no subskill mapping, no window entry | TD-02, TD-04, TD-05 | Covered | |
| Always unstructured (RequiredSetCount=1, RequiredAttemptsPerSet=null) | TD-02 Drill seed data | Covered | |
| Timer interface with Start/Stop + background running | TD-06 Phase 4 (technique_block_screen) | Covered | |
| Manual duration override | TD-06 Phase 4 | Covered | |
| One Instance per Session (duration as raw metric) | TD-02 MetricSchema | Covered | |
| Technique Block Sessions participate in Calendar completion matching | TD-04, TD-06 Phase 5 | Covered | |
| No reflow on Technique Block Session deletion | TD-04 non-reflow triggers | Covered | |
| Post-Session Summary: listed but no score, no delta, no Skill Area impact | TD-06 Phase 4 (post_session_summary_screen) | Partial | May not be explicitly specified in TD-06. |

### S13 Section 13.9: Focus-First UI Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Focus narrows at each layer (App → PB → Session) | No explicit TD reference | **Gap** | S13 defines a focus hierarchy. Not codified in a TD. |
| Queue View: all entries, state differentiation, controls, End Practice, Save as Routine | TD-06 Phase 4 (practice_queue_screen) | Covered | |
| Execution View: screen dominates, queue via secondary drawer | TD-06 Phase 4 (execution screens) | Covered | |
| Execution View: drill name, Skill Area, Set/Instance progress, club selector, target overlay | TD-06 Phase 4 (execution_header, club_selector) | Covered | |
| No per-shot 0–5 scores or running averages during execution | TD-05 scoring test cases | Covered | |

### S13 Section 13.10: Ending Practice

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Manual End: prompt to complete/discard Active Session | TD-04 | Covered | |
| PendingDrill entries discarded | TD-04 | Covered | |
| CompletedSession entries persist | TD-04 | Covered | |
| PB persisted only if ≥1 Session | TD-04 | Covered | |
| Post-Session Summary displayed | TD-06 Phase 4 | Covered | |
| PracticeBlock Auto-End (4 hours) | TD-04 | Covered | |
| Auto-End: PendingDrill discarded, CompletedSessions persist | TD-04 | Covered | |
| On next app open: Post-Session Summary if Sessions exist | No explicit TD reference | **Gap** | S13 specifies deferred summary on next app open after auto-end. Not codified. |
| Passive banner if no Sessions (empty PB discarded) | No explicit TD reference | **Gap** | Not codified. |
| Session Auto-Close during Live Practice: entry type handling | TD-04 Session state machine | Covered | |
| PB 4-hour timer resumes from last Session start | No explicit TD reference | **Gap** | S13 specifies timer measurement base. Not codified. |

### S13 Section 13.11: Calendar Independence

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Queue edits do not modify CalendarDay Slots | TD-06 Phase 4/5 (architectural separation) | Covered | |
| Removing PendingDrill loaded from Calendar does not modify Slot | No explicit TD reference | **Gap** | S13 explicitly specifies this. Not codified. |
| Adding drill not in Calendar does not create Slot | TD-06 Phase 5 (planning separation) | Covered | |
| Calendar updates only via completion matching | TD-06 Phase 5 (completion_matching) | Covered | |
| No real-time Slot modification during Live Practice | No explicit TD reference | **Gap** | Explicit prohibition not codified. |
| No automatic SlotCapacity expansion | TD-06 Phase 5 | Covered | |

### S13 Section 13.12: Save Practice as Routine

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Save current queue as Routine from queue view | No explicit TD reference | **Gap** | S13 §13.12 specifies saving PracticeEntry queue as a Routine. Not addressed in any TD. |
| All entries (PendingDrill + CompletedSession) included in Routine | No explicit TD reference | **Gap** | Same gap. |
| ActiveSession included by DrillID | No explicit TD reference | **Gap** | Same gap. |
| Routine immediately available in Track and Plan | No explicit TD reference | **Gap** | Same gap. |

### S13 Section 13.13: Post-Session Summary

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Displayed after Live Practice ends, before Home | TD-06 Phase 4 (post_session_summary_screen) | Covered | |
| Shown only if ≥1 Session exists | No explicit TD reference | **Gap** | Not codified (implicit). |
| Content: drill name, Skill Area, 0–5 score, score delta, Skill Area impact, IntegrityFlag | TD-06 Phase 4 (post_session_summary_screen) | Partial | TD-06 lists the screen but may not enumerate all 6 content items. Score delta and Skill Area impact direction may not be explicit. |
| Technique Block: listed, no score/delta/impact | No explicit TD reference | **Gap** | Not codified. |
| Summary is read-only (no editing/deletion/management) | No explicit TD reference | **Gap** | Not codified. |

### S13 Section 13.14: Failure & Recovery

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| App crash with Active Session: Session remains, inactivity timers apply | TD-04 Session state machine | Covered | |
| On next open: Live Practice restored, no data loss | No explicit TD reference | **Gap** | S13 specifies explicit crash recovery UX. TD-04 handles server-side state but no TD addresses client-side restoration flow. |
| App crash with no Active Session: PB remains, 4h timer continues | TD-04 PracticeBlock | Covered | |
| PB auto-end while app closed: summary on next open | No explicit TD reference | **Gap** | Same deferred summary gap. |
| Reflow lock: Instance logging blocked, brief indicator | TD-07 (reflow lock), TD-04 RebuildGuard | Covered | |
| No client-side Instance buffering during lock | No explicit TD reference | **Gap** | Repeated from §13.6. |
| Offline: all core operations supported | TD-01 offline-first architecture | Covered | |
| Only initial account creation requires connectivity | TD-01 | Covered | |
| Queue editing available offline | TD-01 offline-first | Covered | |

### S13 Section 13.15: Section 6 Impact (Data Model)

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| PracticeEntry entity added | TD-02 PracticeEntry table | Covered | |
| Required indexes: (PracticeBlockID, PositionIndex) and (SessionID) | TD-02 §7 indexes | Covered | |
| Cascade rules: PB deletion → PracticeEntry deletion | TD-02 FK constraints | Covered | |
| PracticeEntry deletion does NOT cascade to Session | TD-02 (nullable FK) | Covered | |

---

---

## S14 — Drill Entry Screens & System Drill Library (14v.a4)

### S14 Section 14.1: V1 Library Scope

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 28 System Drills total (7 Technique + 21 Transition) | TD-02 seed data, TD-06 Phase 3 | Covered | |
| 0 Pressure Drills (deferred) | TD-06 | Covered | |
| Users may create custom Pressure drills from day one | TD-06 Phase 3 (drill_create_screen) | Covered | |
| 19 subskills covered with at least one Transition drill | TD-02 seed data | Covered | |
| 2 additional Distance Maximum drills (Ball Speed, Club Head Speed) | TD-02 seed data | Covered | |

### S14 Section 14.2: Technique Blocks

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 7 Technique Blocks (one per Skill Area) | TD-02 seed data | Covered | |
| No scoring anchors, no subskill mapping, no window entry | TD-02, TD-04 | Covered | |
| Open-ended: RequiredSetCount=1, RequiredAttemptsPerSet=null | TD-02 seed data | Covered | |
| Single Instance with duration as data field | TD-02 MetricSchema | Covered | |

### S14 Sections 14.3-14.4: Scored Transition Drills & Catalogue

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| All Transition drills: 1×10 structure, Shared scoring, single subskill | TD-02 seed data | Covered | |
| 7 Direction Control drills with specific anchors and targets | TD-02 seed data | Covered | Anchor values should match S14. |
| 6 Distance Control drills with specific anchors and targets | TD-02 seed data | Covered | |
| 3 Distance Maximum drills (Carry, Ball Speed, Club Head Speed) | TD-02 seed data | Covered | |
| 3 Shape Control drills (Binary Hit/Miss) | TD-02 seed data | Covered | |
| 2 Flight Control drills (Binary Hit/Miss) | TD-02 seed data | Covered | |
| Complete 28-drill catalogue | TD-02 seed data, TD-06 Phase 3 | Covered | |

### S14 Section 14.5: Binary Hit/Miss Input Mode

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Fourth input mode in Metric Schema framework | TD-02 InputMode enum | Covered | |
| Two buttons: Hit and Miss | TD-06 Phase 4 (binary_hit_miss_screen) | Covered | |
| Scored metric: hit-rate % through anchors | TD-05 scoring test cases | Covered | |
| User declaration at Session start (draw/fade, high/low) | TD-02 Session.UserDeclaration | Covered | |
| Declaration stored but no scoring impact | TD-02, TD-05 | Covered | |
| No HardMinInput/HardMaxInput for Binary Hit/Miss | TD-02 MetricSchema | Covered | |

### S14 Section 14.6: Anchor Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| System Drill anchors: system-defined, immutable to users | TD-03 DrillRepository immutability guards | Covered | |
| Central anchor edits trigger full reflow | TD-04 reflow triggers | Covered | |
| Users may duplicate to create custom drills with editable anchors | TD-03 DrillRepository.duplicateDrill() | Covered | |

### S14 Section 14.7: Design Philosophy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Practice-ground context (poor lighting, quick interactions, single-handed) | No explicit TD reference | **Gap** | S14 design philosophy not codified in any TD. Informational but guides implementation decisions. |
| Minimum taps to log Instance | TD-06 Phase 4 | Covered | Implicit in screen designs. |

### S14 Section 14.8: Screen Structure

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Title bar: drill name, Skill Area, Set/Instance progress, target, user declaration | TD-06 Phase 4 (execution_header) | Covered | |
| Club selector: collapsed by default, 80% takeover on expand | No explicit TD reference | **Gap** | S14 specifies 80% screen takeover for club selector. Not codified in a TD. |
| User Led: tappable, expands to large buttons | TD-06 Phase 4 (club_selector) | Covered | |
| Guided Mode: system-suggested, tappable to override | TD-06 Phase 4 (club_selector) | Covered | |
| Random Mode: system-selected, not tappable | TD-06 Phase 4 (club_selector) | Covered | |
| Single eligible club: auto-selected, selector hidden | No explicit TD reference | **Gap** | S14 specifies auto-selection when single club eligible. Not codified. |
| Instance list: scrollable, per-Instance result + club, tap to edit inline | TD-06 Phase 4 | Partial | TD-06 lists screens but inline Instance editing may not be explicit. |
| Pre-scoring edits do not trigger reflow | TD-04 (pre-scoring edit rules) | Covered | |

### S14 Section 14.9: Input Mode Layouts

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Grid Cell Selection: large labelled tap targets at bottom | TD-06 Phase 4 (grid_cell_screen) | Covered | |
| 1×3 Grid: Left, Centre, Right (Centre = target) | TD-06 Phase 4 | Covered | |
| 3×1 Grid: Long, Ideal, Short (Ideal = target) | TD-06 Phase 4 | Covered | |
| 3×3 Grid: 9 cells, Centre = target (future) | TD-02 MetricSchema | Covered | Structural stub. |
| Target dimensions integrated into grid (width on horizontal edges, depth on vertical) | No explicit TD reference | **Gap** | S14 specifies target integration into grid as a visual diagram. Not codified. |
| Target distance above grid | No explicit TD reference | **Gap** | Same gap. |
| System hit/miss cell colours | TD-06 Phase 4, S15 design tokens | Covered | |
| Single tap saves Instance + visual flash + vibration | TD-06 Phase 4 (score_flash) | Covered | |
| Binary Hit/Miss: two large buttons, side by side, Hit left / Miss right | TD-06 Phase 4 (binary_hit_miss_screen) | Covered | |
| System hit/miss button colours | TD-06 Phase 4, S15 | Covered | |
| User declaration reminder in title bar | No explicit TD reference | **Gap** | S14 specifies persistent reminder. Not codified. |
| Raw Data Entry: custom large-button numeric keypad | TD-06 Phase 4 (raw_data_entry_screen) | Covered | |
| Submit (primary) + Save (secondary, smaller) action buttons | No explicit TD reference | **Gap** | S14 specifies dual-action button pattern (Submit + Save). Not codified in a TD. |
| Unit label from Metric Schema | TD-02 MetricSchema | Covered | |
| Continuous Measurement: structural stub, identical to Raw Data Entry | TD-06 Phase 4 (continuous_measurement_screen) | Covered | |
| Technique Block timer: Start/Stop, background running, manual override | TD-06 Phase 4 (technique_block_screen) | Covered | |

### S14 Section 14.10: Interaction Behaviours

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Haptic feedback (vibration) on Instance save | No explicit TD reference | **Gap** | S14 specifies haptic feedback. No TD addresses device haptics. |
| Colour flash on grid/button tap | TD-06 Phase 4 (score_flash, 120ms) | Covered | |
| No sound on standard shot confirmation | No explicit TD reference | **Gap** | S14 explicitly excludes sound for standard shots. Not codified. |
| Sound reserved for achievement banners only | No explicit TD reference | **Gap** | Same gap. |
| Undo Last Instance: available immediately after save, until next Instance | No explicit TD reference | **Gap** | S14 defines a specific undo mechanism. Not addressed in any TD. |
| Undo removes most recently saved Instance, decrements count | No explicit TD reference | **Gap** | Same undo gap. |
| Undo is pre-scoring, no reflow | No explicit TD reference | **Gap** | Same undo gap. |
| Achievement banners: top-of-screen, transient, "ping" sound | TD-06 Phase 8 (achievement_banner) | Covered | |
| Banner triggers: best streak, best set score, personal best Session score | TD-06 Phase 8 | Partial | TD-06 mentions achievement_banner but may not enumerate all 3 triggers. |
| Banners auto-dismiss, do not interrupt input flow | TD-06 Phase 8 | Covered | |
| Set Transition interstitial ("Set 1 Complete — Starting Set 2") | No explicit TD reference | **Gap** | S14 specifies a set transition interstitial. Not codified. |
| Auto-advance to next Set, no user action | No explicit TD reference | **Gap** | Not codified. |
| Final Set → Session auto-close | TD-04 Session state machine | Covered | |
| Bulk Entry: tab toggle (Single / Bulk) at top of input area | No explicit TD reference | **Gap** | S14 §14.10.5 specifies a bulk entry mode. Not addressed in any TD. |
| Bulk Grid: counter per cell, submit batch | No explicit TD reference | **Gap** | Same bulk entry gap. |
| Bulk Binary: numeric Hit/Miss counts, submit | No explicit TD reference | **Gap** | Same gap. |
| Bulk Raw Data: multi-row numeric input, submit batch | No explicit TD reference | **Gap** | Same gap. |
| Bulk rules: active Set only, structured Set capacity limit, same SelectedClub | No explicit TD reference | **Gap** | Same gap. |
| Sequential micro-offset timestamps for bulk Instances | No explicit TD reference | **Gap** | Same gap. |
| End/Discard/Restart in secondary menu (overflow/ellipsis) | No explicit TD reference | **Gap** | S14 specifies these controls in a secondary menu. Not codified. |
| End Drill: available for unstructured only | TD-04 Session state machine | Covered | |
| Restart/Discard require confirmation prompt | No explicit TD reference | **Gap** | S14 specifies confirmation for Restart/Discard. Not codified. |
| 80% Screen Takeover: interactive element expands to 80%+ of screen | No explicit TD reference | **Gap** | S14 specifies specific 80% takeover rule. Not codified in any TD. |
| Takeover: title bar compressed, Instance list hidden, other elements hidden | No explicit TD reference | **Gap** | Same gap. |
| Auto-collapse after interaction completes | No explicit TD reference | **Gap** | Same gap. |
| Portrait Only for Drill Entry Screen | No explicit TD reference | **Gap** | S14 specifies portrait-only. Not codified. |

### S14 Section 14.10.8: Session Duration Tracking

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Duration tracked on all Sessions | No explicit TD reference | **Gap** | S14 specifies duration tracking for all Sessions. Not codified as a TD requirement. |
| Technique Block: user-facing timer, stored as Instance raw metric | TD-02 MetricSchema, TD-06 Phase 4 | Covered | |
| Transition/Pressure: passive background duration (first to last Instance timestamps) | No explicit TD reference | **Gap** | S14 specifies passive duration calculation. Not codified. |
| SessionDuration field on Session entity | No explicit TD reference | **Gap** | S14 §14.12 adds SessionDuration (integer, nullable) to Session. Not in TD-02 Session table. |
| Duration available in Review for analytics | No explicit TD reference | **Gap** | Not codified. |

### S14 Section 14.12: Data Model Additions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Session.SessionDuration (integer, nullable) | TD-02 Session table — **not present** | **Gap** | S14 adds SessionDuration to Session entity. TD-02 does not include this column. |
| Technique Block Instance: duration via Metric Schema (HardMinInput=0, HardMaxInput=43200) | TD-02 MetricSchema seed data | Covered | Values should match. |

---

---

## S15 — Branding & Design System (15v.a3)

### S15 Section 15.1: Strategic Positioning

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Audience: serious amateur performance improvers | No explicit TD reference | **Gap** | S15 defines target audience. Not codified in any TD. Informational. |
| Tonal direction: performance-focused, analytical | No explicit TD reference | **Gap** | Not codified. Informational. |
| Design intent: reinforce determinism and structural clarity | No explicit TD reference | **Gap** | Not codified. |
| 5 positioning characteristics | No explicit TD reference | **Gap** | Not codified. |
| Explicit exclusions: gamification, celebratory theatrics, lifestyle branding, etc. | No explicit TD reference | **Gap** | S15 lists explicit prohibitions. Not codified. |

### S15 Section 15.2: Tone & Voice Guidelines

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Copy tone: concise, direct, no exclamation marks in system messages | No explicit TD reference | **Gap** | Not codified. |
| No motivational language in scoring displays | No explicit TD reference | **Gap** | Not codified. |
| Achievement text: factual, not celebratory | TD-06 Phase 8 (achievement_banner) | Partial | TD-06 mentions achievement banner but not tonal guidance. |
| Error messages: factual, actionable, no blame/alarm | TD-07 error handling patterns | Partial | TD-07 defines error handling structure but not tonal guidance. |
| Score communication: neutral, no emotional framing | No explicit TD reference | **Gap** | Not codified. |

### S15 Section 15.3: Colour Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 3-layer colour separation: Interaction, Semantic, Heatmap | TD-06 Phase 1 (tokens.dart) | Covered | tokens.dart implements these layers. |
| Interaction tokens never used for scoring outcomes | No explicit TD reference | **Gap** | S15 specifies colour separation rule. Not codified as a TD rule. |
| color.primary.default #00B3C6 | TD-06 Phase 1 (tokens.dart) | Covered | |
| color.primary.hover #00C8DD | TD-06 Phase 1 | Covered | |
| color.primary.active #007C7F | TD-06 Phase 1 | Covered | |
| color.primary.focus (#00B3C6 @ 60% opacity, 2px outline) | No explicit TD reference | **Gap** | S15 specifies focus ring. May not be in tokens.dart. |
| color.success.default #1FA463 | TD-06 Phase 1 | Covered | |
| color.success.hover #23B26C | TD-06 Phase 1 | Covered | |
| color.success.active #15804A | TD-06 Phase 1 | Covered | |
| color.neutral.miss #3A3F46 | TD-06 Phase 1 | Covered | |
| color.neutral.miss.active #2C3036 | TD-06 Phase 1 | Covered | |
| color.neutral.miss.border #4A5058 | TD-06 Phase 1 | Covered | |
| Miss uses neutral grey, no red | No explicit TD reference | **Gap** | S15 explicitly prohibits red for miss. Not codified as a TD rule. |
| color.warning.integrity #F5A623 | TD-06 Phase 1 | Covered | |
| color.warning.integrity.muted #C88719 | TD-06 Phase 1 | Covered | |
| color.error.destructive #D64545 | TD-06 Phase 1 | Covered | |
| color.error.destructive.hover #E05858 | TD-06 Phase 1 | Covered | |
| color.error.destructive.active #B63737 | TD-06 Phase 1 | Covered | |
| Heatmap: grey→green, continuous opacity, no hard-banded tiers | TD-06 Phase 6 (skill_area_heatmap) | Covered | |
| heatmap.base #2B2F34 | TD-06 Phase 1 | Covered | |
| heatmap.base.border #3A3F46 | TD-06 Phase 1 | Covered | |
| heatmap.base.text #E6E8EB | TD-06 Phase 1 | Covered | |
| heatmap.mid #145A3A | TD-06 Phase 1 | Covered | |
| heatmap.high #1FA463 | TD-06 Phase 1 | Covered | |

### S15 Section 15.4: Surface & Elevation System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Dark-first interface | TD-06 Phase 1 (tokens.dart) | Covered | |
| surface.base #0F1115 | TD-06 Phase 1 | Covered | |
| surface.primary #171A1F | TD-06 Phase 1 | Covered | |
| surface.raised #1E232A | TD-06 Phase 1 | Covered | |
| surface.modal #242A32 | TD-06 Phase 1 | Covered | |
| surface.border #2A2F36 | TD-06 Phase 1 | Covered | |
| surface.scrim Black @ 40% | No explicit TD reference | **Gap** | S15 specifies scrim value. May not be in tokens.dart. |
| No blur effects on scrim | No explicit TD reference | **Gap** | Explicit prohibition not codified. |
| On-press: darken ~4%, no scale, no bounce | No explicit TD reference | **Gap** | S15 specifies press behaviour. Not codified as a TD rule. |
| Elevation exclusion list (5 items: long drop shadows, glow, neumorphism, blur glass, gradients) | No explicit TD reference | **Gap** | Explicit prohibitions not codified. |

### S15 Section 15.5: Typography System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Technical Geometric Sans typeface category | TD-06 Phase 1 (tokens.dart — Manrope) | Covered | |
| Manrope selected | TD-06 Phase 1 | Covered | |
| type.display.xl 32–40px SemiBold | TD-06 Phase 1 (tokens.dart) | Covered | |
| type.display.lg 24–28px SemiBold | TD-06 Phase 1 | Covered | |
| type.header.section 18–22px Medium | TD-06 Phase 1 | Covered | |
| type.body 14–16px Regular | TD-06 Phase 1 | Covered | |
| type.micro 12px Regular @ 70–80% | TD-06 Phase 1 | Covered | |
| Tabular lining numerals on all score displays | TD-06 Phase 1 (tokens.dart — tabular lining) | Covered | |
| No animated counting | No explicit TD reference | **Gap** | Not codified. |
| Typography exclusion list (7 items) | No explicit TD reference | **Gap** | Explicit prohibitions not codified. |

### S15 Section 15.6: Spacing & Layout Grid

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 4px base grid | TD-06 Phase 1 (tokens.dart — xs=4, sm=8, md=16, lg=24, xl=32, xxl=48) | Covered | |
| spacing.8 through spacing.48 | TD-06 Phase 1 | Covered | |
| No arbitrary spacing values (e.g. 13px, 22px) | No explicit TD reference | **Gap** | S15 prohibits arbitrary spacing. Not codified as a TD rule. |

### S15 Section 15.7: Shape Language

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| radius.card 8px | TD-06 Phase 1 (tokens.dart) | Covered | |
| radius.grid 6px | TD-06 Phase 1 | Covered | |
| radius.modal 10px | TD-06 Phase 1 | Covered | |
| Segmented controls: 8px container + 8px highlight | No explicit TD reference | **Gap** | S15 specifies segmented control radius. May not be in tokens.dart. |
| No pill-shaped (999px radius) buttons anywhere | No explicit TD reference | **Gap** | Explicit prohibition not codified. |

### S15 Section 15.8: Component Design System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Primary CTA: filled, color.primary.default, white text | TD-06 Phase 1 (design system) | Covered | |
| Secondary: outline, 1px border, primary text | TD-06 Phase 1 | Covered | |
| Destructive: filled, error.destructive, white text | TD-06 Phase 1 | Covered | |
| Text button: no border, no fill | TD-06 Phase 1 | Covered | |
| Cards: surface.primary, 1px border, 8px radius, 16px padding, press darken | TD-06 Phase 1 | Covered | |
| Grid cells: 6px radius, hit/miss colours, 120ms flash, haptic tick | TD-06 Phase 4 (score_flash) | Covered | |
| Achievement banners: surface.raised, primary accent restrained, factual text, fade in/out, sound ping | TD-06 Phase 8 (achievement_banner) | Covered | |
| Achievement banner prohibitions (no slide, bounce, scale, glow, confetti, streak fire) | No explicit TD reference | **Gap** | S15 lists 6 explicit animation prohibitions for banners. Not codified. |
| Integrity indicators: subtle warning icon, Session level only, not in SkillScore/score displays | TD-06 Phase 6 (session_history_screen) | Covered | |

### S15 Section 15.9: Iconography

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Outlined, geometric, consistent stroke weight | No explicit TD reference | **Gap** | S15 defines icon style. Not codified in a TD. |
| 1.5–2px stroke, no filled icons in navigation | No explicit TD reference | **Gap** | Not codified. |
| Size grid: 16px, 20px, 24px, 32px | No explicit TD reference | **Gap** | Not codified. |
| Colour rules: off-white default, primary active, warning integrity, error destructive | No explicit TD reference | **Gap** | Not codified. |
| No illustrative or golf-themed decorative icons | No explicit TD reference | **Gap** | Not codified. |

### S15 Section 15.10: Motion & Microinteraction System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| motion.fast 120ms | TD-06 Phase 1 (tokens.dart) | Covered | |
| motion.standard 150ms | TD-06 Phase 1 | Covered | |
| motion.slow 200ms | TD-06 Phase 1 | Covered | |
| Easing: ease-in-out cubic only | No explicit TD reference | **Gap** | S15 specifies easing. Not codified. |
| No transitions exceed 200ms anywhere | No explicit TD reference | **Gap** | S15 sets hard 200ms maximum. Not codified as a TD rule. |
| 5 permitted motion patterns (button press, grid tap, achievement banner, heatmap accordion, surface press) | TD-06 Phase 4/8 | Partial | TD-06 covers some patterns but not as a definitive list. |
| Default: silent. Haptic tick on grid tap. Sound ping on achievement only | No explicit TD reference | **Gap** | S15 specifies audio model. Not codified. |
| 12-item motion prohibition list | No explicit TD reference | **Gap** | S15 lists 12 prohibited animation effects. Not codified. |

### S15 Section 15.11: Visual Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Full visual unification across Plan/Track/Review (no domain colour shifts) | No explicit TD reference | **Gap** | S15 specifies no per-domain tints or accent shifts. Not codified. |
| Same tokens everywhere (charcoal, cyan, green, grey, amber, red) | TD-06 Phase 1 (tokens.dart) | Covered | Implicit in token implementation. |
| Differentiation by structure only (information density, interaction patterns, emphasis hierarchy) | No explicit TD reference | **Gap** | Not codified. |

### S15 Section 15.12: Logo & Brand Expression

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Minimal typographic wordmark only (no symbol, emblem, crest, etc.) | No explicit TD reference | **Gap** | Not codified. |
| Product title is working title, not final | No explicit TD reference | **Gap** | Not codified. |
| Title prohibited in: file names, env vars, DB schemas, namespaces, tokens, constants, identifiers | No explicit TD reference | **Gap** | S15 specifies product-name-agnostic governance. Not codified. Note: the Flutter package name is `zx_golf_app` which may conflict. |

### S15 Sections 15.13-15.16: Accessibility, Tokens, Theming, Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| WCAG AA global minimum (4.5:1 normal, 3:1 large text) | No explicit TD reference | **Gap** | S15 specifies accessibility standards. Not codified in any TD. |
| WCAG AAA on 4 cognitively critical surfaces (Overall Score, Session Score, Integrity warning, Destructive dialog) | No explicit TD reference | **Gap** | Not codified. |
| Heatmap: AA sufficient, AAA not required | No explicit TD reference | **Gap** | Not codified. |
| Outdoor usage: large high-contrast numerals for Drill Entry | No explicit TD reference | **Gap** | Not codified. |
| Product-name-agnostic token naming | No explicit TD reference | **Gap** | Not codified. Note: tokens.dart may use neutral names already. |
| Prohibited token name patterns (brand/product name in tokens) | No explicit TD reference | **Gap** | Not codified. |
| Token-first theming (overrides modify tokens only, not component logic) | No explicit TD reference | **Gap** | Not codified. |
| Light mode via token swap (deferred) | No explicit TD reference | **Gap** | Not codified. |
| White-label branding via token override | No explicit TD reference | **Gap** | Not codified. |
| 10 structural guarantees | No explicit TD reference | **Gap** | S15 §15.16 lists 10 guarantees. Not codified as a set. |

---

---

## S16 — Database Architecture (16v.a5)

### S16 Section 16.1: Relational Schema Design

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 5 table groups: Source, Reference, Planning, Materialised, System | TD-02 §1–§8 (schema structure) | Covered | |
| UUID primary keys | TD-02 | Covered | |
| CreatedAt/UpdatedAt UTC timestamps | TD-02 | Covered | |
| IsDeleted soft-delete with RLS filtering | TD-02, TD-01 (soft-delete propagation) | Covered | |
| Foreign key constraints on all relationships | TD-02 §5–§7 | Covered | |
| JSON columns for structured variable-length data | TD-02 (Slots, RawMetrics, Metadata, etc.) | Covered | |
| Source tables list (15 entities) | TD-02 §2–§4 | Covered | |
| Reference tables list (5 entities) | TD-02 §2 (reference data) | Covered | |
| Planning tables list (6 entities) | TD-02 §3 | Covered | |
| Materialised tables list (4 entities) | TD-02 §4 | Covered | |
| System tables list (2 entities: SystemMaintenanceLock, MigrationLog) | TD-02 §8 (server-only, excluded from Drift) | Covered | Known deviation. |

### S16 Section 16.2: Enumeration Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Stable enumerations: native enum types or CHECK constraints | TD-02 enum definitions | Covered | |
| Extensible enumerations: reference table FK | TD-02 (EventTypeRef, MetricSchemaRef, etc.) | Covered | |
| Hybrid approach | TD-02 | Covered | |
| 5 stable enums listed (SkillArea, DrillType, InputMode, ClosureType, DrillOrigin) | TD-02 enums | Covered | |
| 6 extensible enums listed (EventType, MetricSchema, SubskillRef, SkillAreaRef, etc.) | TD-02 reference tables | Covered | |

### S16 Section 16.3: Indexing Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Every FK has an index | TD-02 §7 index list | Covered | |
| 14 composite indexes defined | TD-02 §7 | Covered | Values should match. |
| Partial indexes on IsDeleted=false | No explicit TD reference | **Gap** | S16 specifies partial indexes. TD-02 lists indexes but may not specify partial filtering. |
| JSON column indexes (GIN) deferred to performance need | No explicit TD reference | **Gap** | S16 specifies deferred GIN indexes. Not in any TD. |

### S16 Section 16.4: Transaction & Isolation Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Default isolation: Repeatable Read | No explicit TD reference | **Gap** | S16 specifies default isolation level. TD-02 does not address transaction isolation. |
| Materialised swap: Serializable isolation | No explicit TD reference | **Gap** | S16 specifies Serializable for materialised swap. Not in any TD. |
| User scoring lock (Advisory Lock) | TD-04 RebuildGuard (in-memory mutex) | Partial | S16 specifies database-level advisory lock. TD-04 uses in-memory mutex. Different mechanisms. |
| Lock scope: per-user, prevents concurrent reflow | TD-04 RebuildGuard | Covered | Same concept, different implementation. |
| Lock timeout: 60 seconds | TD-04 RebuildGuard | Covered | |
| 6-step atomic reflow transaction | TD-04 ReflowEngine (10-step orchestrator) | Partial | S16 defines a 6-step DB transaction. TD-04 defines a 10-step application-layer orchestrator. Related but different abstraction levels. |
| Application-layer retry (6 categories with specific values) | TD-07 error handling patterns | Partial | TD-07 defines error handling but may not specify all 6 retry categories with exact values. |
| Instance creation: 2 retries, immediate | No explicit TD reference | **Gap** | S16 specifies exact retry parameters. Not in any TD. |
| Session close + scoring: 3 retries, exponential backoff (100/200/400ms) | No explicit TD reference | **Gap** | Same gap. |
| Calendar/Planning writes: 2 retries, immediate | No explicit TD reference | **Gap** | Same gap. |
| Read operations: 1 retry, immediate | No explicit TD reference | **Gap** | Same gap. |
| Retry idempotency requirement | No explicit TD reference | **Gap** | Not codified. |
| RLS + Repeatable Read: cross-user contention structurally impossible | No explicit TD reference | **Gap** | Not codified as a TD guarantee. |

### S16 Section 16.5: Migration Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Sequential numbered migration pattern | TD-06 Phase 8 (migration infrastructure) | Covered | |
| NNN_short_description.sql naming | TD-02 migration files (001–004) | Covered | |
| UP and DOWN in each file | No explicit TD reference | **Gap** | S16 specifies rollback (DOWN) capability. TD migrations may not include DOWN. |
| Idempotent UP (IF NOT EXISTS) | No explicit TD reference | **Gap** | Not codified. |
| 5 migration categories (additive, modifying, data, enum extension, destructive) | No explicit TD reference | **Gap** | Not codified. |
| Migration governance rules (review, destructive approval, reflow testing, determinism preservation) | No explicit TD reference | **Gap** | S16 specifies 4 governance rules. Not codified in a TD. |
| Migration log table | TD-02 §8 (MigrationLog — server-only) | Covered | |
| Zero-downtime expand-contract pattern | No explicit TD reference | **Gap** | S16 specifies expand-contract for zero-downtime. Not codified. |

### S16 Section 16.6: Versioned Data Handling

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Time-versioned: ClubPerformanceProfile (insert-on-update) | TD-02 ClubPerformanceProfile, TD-03 ClubRepository | Covered | |
| Snapshot fields: Instance (ResolvedTarget*, SelectedClub), PracticeBlock (DrillOrder), Session (DrillID) | TD-02 schema | Covered | |
| Application-layer immutability enforcement | TD-03 structural immutability guards | Covered | |
| Optional DB-level BEFORE UPDATE triggers for snapshot fields | No explicit TD reference | **Gap** | S16 suggests optional triggers. Not in any TD. |
| Structural versioning via reflow (no version column, no historical snapshots) | TD-04 ReflowEngine, TD-01 deterministic rebuild | Covered | |
| Metadata edits: unversioned (UserClub Make, Model, Loft) | TD-02, TD-03 | Covered | |

### S16 Section 16.7: Backup & Recovery

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| RPO: 15 minutes | No explicit TD reference | **Gap** | S16 specifies recovery objectives. Not in any TD. |
| RTO: 1 hour | No explicit TD reference | **Gap** | Same gap. |
| Continuous WAL archival (primary backup) | No explicit TD reference | **Gap** | S16 specifies backup strategy. Not codified. |
| Daily full base backups (retained 30 days) | No explicit TD reference | **Gap** | Same gap. |
| Weekly logical exports (pg_dump, retained 90 days, separate region) | No explicit TD reference | **Gap** | Same gap. |
| 4 recovery scenarios defined | No explicit TD reference | **Gap** | S16 defines 4 specific recovery procedures. Not codified. |
| EventLog tiered storage: 6-month hot, indefinite cold | No explicit TD reference | **Gap** | S16 specifies EventLog archival model. Not codified. |
| Daily archival job, compressed JSON, partitioned by UserID/month | No explicit TD reference | **Gap** | Same gap. |
| Archival and entity purge dependency (dangling references acceptable) | No explicit TD reference | **Gap** | Not codified. |
| Weekly automated backup restore test | No explicit TD reference | **Gap** | S16 specifies backup validation. Not codified. |

### S16 Section 16.8: Performance Scaling

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Multi-tenancy via RLS on UserID | TD-02 RLS policies | Covered | |
| System Drills (UserID IS NULL) readable by all | TD-02 | Covered | |
| 9 query performance targets (Instance <50ms, Session close <200ms, etc.) | No explicit TD reference | **Gap** | S16 specifies exact latency targets. Not codified in any TD. |
| 5-tier scaling levers (index optimisation → connection pooling → read replicas → partitioning → caching) | No explicit TD reference | **Gap** | S16 defines scaling roadmap. Not codified. |
| Volume projections per user | No explicit TD reference | **Gap** | S16 provides annual projections. Not codified. |
| Data retention: indefinite for active users, 90-day soft-delete | No explicit TD reference | **Gap** | S16 specifies retention policy. Not codified. |
| Connection management (6 parameters with baseline values) | No explicit TD reference | **Gap** | S16 specifies pooling configuration. Not codified. |
| Mandatory connection pooling | No explicit TD reference | **Gap** | Not codified. |
| 4 operational monitoring categories (17 specific monitors with thresholds) | No explicit TD reference | **Gap** | S16 specifies extensive monitoring. Not codified in any TD. |

### S16 Section 16.9: Structural Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 18 structural guarantees listed | TD-01 through TD-04 combined | Partial | Individual guarantees are covered across TDs, but S16 consolidates 18 guarantees as a formal set not found in any single TD. |

---

---

## S17 — Real-World Application Layer (17v.a4)

### S17 Section 17.1: Training-Only Positioning

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Strictly structured training system (not competitive round companion) | TD-01 (platform decisions) | Covered | Implicit in TD-01. |
| No on-course mode, holes, rounds, stroke-play | No explicit TD reference | **Gap** | S17 lists 5 explicit exclusions. Not codified in any TD. |
| No GPS, location, geofencing, yardage | No explicit TD reference | **Gap** | Same gap. |
| No competition locking or Rules of Golf compliance | No explicit TD reference | **Gap** | Same gap. |
| User assumed stationary in training context | No explicit TD reference | **Gap** | Not codified. |

### S17 Section 17.2: Range & Practice Ground Usage Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| No environmental mode switching or context detection | No explicit TD reference | **Gap** | S17 explicitly excludes environment-aware features. Not codified. |
| PracticeBlocks behave identically regardless of location | TD-04 | Covered | Implicit. |

### S17 Section 17.3: Offline-First Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Full offline operation | TD-01 offline-first architecture | Covered | |
| Complete local relational mirror of canonical schema | TD-01 (Drift/SQLite local DB) | Covered | |
| Full local scoring engine | TD-01, TD-04 | Covered | |
| Server is not scoring authority | TD-01 (deterministic merge-and-rebuild) | Covered | |
| 17 offline-capable operations listed | TD-01 | Covered | All implicitly covered by offline-first. |
| Only account creation requires connectivity | TD-01 | Covered | |
| System Drill Library bundled with app binary | TD-06 Phase 1 (seed_data.dart) | Covered | |
| System Drill updates via sync pipeline | TD-01 sync, TD-06 Phase 7 | Covered | |
| Server performs 4 functions (sync broker, backup, drill distribution, account management) | TD-01 | Covered | |
| No automatic data pruning in V1 | No explicit TD reference | **Gap** | S17 explicitly states no auto-pruning. Not codified. |
| Window cap (25 occupancy units) provides natural ceiling on materialised state size | TD-02 materialised tables, TD-05 | Covered | |
| Low storage warning notification (no auto-delete) | TD-06 Phase 7C (StorageMonitor stub) | Covered | Known deviation (stub). |
| EventLog archival deferred to V2 | No explicit TD reference | **Gap** | S17 defers local EventLog archival. Not codified as a TD decision. |

### S17 Section 17.4: Multi-Device Synchronisation Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Deterministic merge-and-rebuild sync model | TD-01 sync strategy | Covered | |
| DeviceID: UUID generated on first launch | TD-02 UserDevice table | Covered | |
| No limit on registered devices per user | No explicit TD reference | **Gap** | S17 states no device limit. Not codified. |
| DeviceID: sync bookkeeping only, no scoring impact, no UI exposure beyond Settings device list | No explicit TD reference | **Gap** | S17 specifies DeviceID scope. Not fully codified. |
| Deregistering device: removes from roster, no data deleted | No explicit TD reference | **Gap** | S17 specifies deregistration behaviour. Not codified. |
| Append-only raw execution data (6 entities listed) | TD-01 sync (additive merge) | Covered | |
| LWW structural configuration (5 categories) | TD-01 (LWW by UpdatedAt) | Covered | |
| CalendarDay Slot-level LWW | TD-01 (CalendarDay slot-level exception) | Covered | |
| Soft-delete: forward-only, never reversed by sync | TD-01 (delete always wins) | Covered | |
| Materialised state never synced (4 tables) | TD-01 (materialised never synced) | Covered | |
| 6-step sync pipeline (Upload → Download → Merge → Completion Matching → Rebuild → Confirm) | TD-06 Phase 7B (SyncEngine merge pipeline) | Covered | |
| Sync triggers: connectivity restore, periodic, manual | TD-06 Phase 7A (SyncOrchestrator triggers) | Covered | |
| Periodic: 5-minute interval | TD-06 Phase 7A | Covered | |
| Manual trigger in Settings | No explicit TD reference | **Gap** | S17 specifies manual sync. May not be in TD-06 Phase 8 explicitly. |
| Silent non-blocking sync | TD-06 Phase 7A | Covered | |
| Sync-triggered rebuild: non-blocking (not full scoring lock) | No explicit TD reference | **Gap** | S17 specifies that sync rebuild doesn't use the full scoring lock model. Not codified as a TD rule. |
| User-initiated reflow takes priority over sync rebuild | No explicit TD reference | **Gap** | S17 specifies priority model. Not codified. |
| Sync failure: no partial merge committed, atomic per entity | TD-06 Phase 7B | Covered | |
| No data loss on sync failure, auto-retry on next trigger | TD-06 Phase 7A (consecutive failure counter) | Covered | |
| Cross-device Session concurrency: same-device enforced, online server-mediated, offline both allowed | TD-06 Phase 7C (dual active session detection) | Covered | |
| Offline overlap: both Sessions merge chronologically on sync | TD-01 (additive merge) | Covered | |
| System Drill update delivery via sync | TD-01, TD-06 Phase 7 | Covered | |
| Automatic reflow on System Drill update receipt | TD-01 | Covered | |
| Schema version compatibility: sync blocked on mismatch | TD-06 Phase 7C (schema mismatch persistent flag) | Covered | |
| "App update required to sync" message | TD-06 Phase 7C (SyncStatusBanner) | Covered | |
| Device continues offline during version mismatch | TD-06 Phase 7C | Covered | |
| Schema migrations preserve backward compatibility of raw execution entities | No explicit TD reference | **Gap** | S17 specifies migration compatibility constraint. Not codified as a TD rule. |

### S17 Section 17.5: Data Export & Sharing

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| JSON full export (manual, user-initiated) | Known Deviation (CLAUDE.md) | Covered | Acknowledged as deferred. |
| Optional CSV session summary | Not in any TD | Covered | Deferred. |
| No re-import in V1 | No explicit TD reference | **Gap** | S17 explicitly defers re-import. Not codified. |
| No shareable links, hosted dashboards, external portals | No explicit TD reference | **Gap** | S17 lists 4 explicit exclusions. Not codified. |
| No real-time coach feeds or live shared access | No explicit TD reference | **Gap** | Same gap. |
| Export scope: 9 entity types listed | No explicit TD reference | **Gap** | S17 enumerates export scope. Not codified in a TD. |

### S17 Section 17.6: Coach/Admin Access

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| No coach/admin/secondary user role in V1 | No explicit TD reference | **Gap** | S17 specifies single-user-only. Not codified in a TD. |
| No shared accounts, delegated access, cross-user visibility | No explicit TD reference | **Gap** | S17 lists 5 explicit exclusions. Not codified. |
| Coach interaction via exported files only | No explicit TD reference | **Gap** | Not codified. |
| Future compatibility for coach layer | No explicit TD reference | **Gap** | Not codified. |

### S17 Section 17.7: User Behaviour Constraints

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| No behavioural realism constraints | No explicit TD reference | **Gap** | S17 specifies no enforcement. Not codified. |
| 9 explicitly not-enforced behaviours (max sessions/hour, min time between shots, back-dating, shot-rate throttling, volume caps, anti-gaming, etc.) | No explicit TD reference | **Gap** | S17 lists 9 specific non-enforcements. Not codified. |
| Existing structural constraints (5 items) preserved | TD-04, TD-02 | Covered | |

### S17 Section 17.8: Practical Session Time Limits

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Only existing structural safeguards (2h Session, 4h PB) | TD-04 state machines | Covered | |
| No additional hard maximum PB duration | No explicit TD reference | **Gap** | S17 explicitly states no additional duration limit. Not codified. |
| No per-Session absolute time cap | No explicit TD reference | **Gap** | Same gap. |
| No daily cumulative practice limit | No explicit TD reference | **Gap** | Same gap. |
| Timers are not user-configurable | TD-04 (system constants) | Covered | |

### S17 Section 17.9: Data Model Additions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| UserDevice entity (8 fields) | TD-02 UserDevice table | Covered | |
| EventLog.DeviceID extension | TD-02 EventLog table | Covered | |
| UserDevice(UserID) index | TD-02 §7 | Covered | |
| EventLog(DeviceID) index | TD-02 §7 | Covered | |
| No scoring impact for all additions | TD-04 non-reflow triggers | Covered | |

### S17 Section 17.10: Cross-Section Impact

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Section 3 updates: offline fallback for concurrency | TD-06 Phase 7C | Covered | |
| Section 6 updates: UserDevice entity, EventLog DeviceID | TD-02 | Covered | |
| Section 7 updates: sync rebuild non-blocking clarification | No explicit TD reference | **Gap** | Not codified. |
| Section 13 updates: supersede offline limitation list | No explicit TD reference | **Gap** | S17 supersedes S13 offline limitations. Not codified as a TD update. |
| Section 16 updates: UserDevice table, DeviceID column, indexes | TD-02 | Covered | |
| Section 0 updates: add 5 new terms | No explicit TD reference | **Gap** | S17 requests S00 updates. Not codified. |

### S17 Section 17.11: Structural Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 14 structural guarantees | TD-01 through TD-07 combined | Partial | Individual guarantees covered across TDs but not consolidated in any single TD document. |

---

---

## TD-Only Items (TD introduces beyond S00/S01/S02 scope)

These are items found in the TD Reference Catalogue that are not addressed in S00, S01, or S02 but relate to scoring/architecture topics. They are expected to have coverage in other spec documents (S03-S17).

| TD Source | Item | Expected Spec Coverage |
|-----------|------|----------------------|
| TD-01 | Platform selection (Flutter, Android-first, iOS deferred) | S17 (Real-World Application) |
| TD-01 | Backend selection (Supabase) | S17 |
| TD-01 | Authentication (Google Sign-In) | S17 |
| TD-01 | Sync transport details (upload/download RPCs) | S17 |
| TD-01 | Security model (RLS, encryption, JWT) | S17 |
| TD-01 | Performance targets (reflow <150ms, cold start <1s) | S12 (UI/UX), S17 |
| TD-01 | Local storage envelope estimates | S17 |
| TD-02 | Full DDL schema (28 tables) | S06, S16 |
| TD-02 | Trigger, index, RLS policy counts | S16 |
| TD-02 | SubskillID naming convention (snake_case compound key) | S06, S16 |
| TD-02 | Deterministic System Drill UUIDs | S06, S16 |
| TD-03 | Repository method signatures (8 repositories) | S06 |
| TD-03 | SyncWriteGate mechanics | S17 |
| TD-03 | Error response contract (5 categories) | S07 (Reflow Governance) |
| TD-03 | RawMetrics parse failure handling rules | S04 (Drill Entry) |
| TD-04 | Entity state machine formal tables | S03 (User Journey), S04 |
| TD-04 | Reflow algorithm 10 steps | S07 |
| TD-04 | Three coordination mechanisms compared | S07 |
| TD-05 | 50+ numbered test cases | Testing infrastructure |
| TD-05 | Precision policy (IEEE 754, 1e-9 tolerance) | Testing infrastructure |
| TD-06 | 12-phase build structure | Build management |
| TD-07 | 22 exception codes | S07 |
| TD-07 | Graceful degradation matrix | S07, S17 |
| TD-07 | Startup integrity checks (4 checks) | S07 |
| TD-08 | Context loading strategy, prompt templates | Build management |

---

---

## Consolidated Conflicts

### Conflict 1: Immutable Post-Creation Field Lists Diverge

**S00 §11 lists these immutable post-creation fields:**
- Subskill mapping
- Metric Schema
- Drill Type
- RequiredSetCount
- RequiredAttemptsPerSet
- Club Selection Mode
- Target Definition (grid-based drills only)

**TD-03 §5.3 structural immutability guard lists:**
- SubskillMapping
- MetricSchemaID
- DrillType
- RequiredSetCount
- RequiredAttemptsPerSet
- ScoringMode
- InputMode

**Discrepancies:**
1. **ClubSelectionMode**: Present in S00/S04/S10 but absent from TD-03/TD-04 immutability guards.
2. **TargetDefinition**: Present in S00 but absent from TD-03/TD-04 immutability guards.
3. **ScoringMode**: Absent from S00 but present in TD-03/TD-04 immutability guards.
4. **InputMode**: Absent from S00 but present in TD-03/TD-04 immutability guards.

Per source-of-truth hierarchy, TD-03 governs over S00 for implementation. However, this divergence should be explicitly resolved — either S00 should be updated to match TD-03, or TD-03 should be updated to include ClubSelectionMode and TargetDefinition. ScoringMode and InputMode are arguably subsumed by MetricSchema selection, but the spec should be explicit.

**Referenced in:** S00 §11, S04 §4.1, S10 §10.7, S12/S14

### Conflict 2: PracticeBlock.ClosureType Values

**S06** defines ClosureType as: `Manual, AutoClosed`.
**TD-04** defines three closure types: `Manual, ScheduledAutoEnd, SessionTimeout`.

Per source-of-truth hierarchy, TD-02 governs entity structure. TD-04 has more granular closure types than S06.

**Referenced in:** S06 §6.2

### Conflict 3: Session Columns (UserDeclaration, SessionDuration)

**S06** defines `UserDeclaration` (String nullable) and `SessionDuration` (Integer nullable) on Session.
**TD-02** DDL may not include these columns. This needs verification against the actual TD-02 DDL. Per hierarchy, TD-02 governs.

**Referenced in:** S06 §6.2, S14 §14.12

### Conflict 4: Reflow Timeout (S07 vs TD-04)

**S07 §7.7** specifies 60-second hard timeout for individual user reflow.
**TD-04** RebuildGuard specifies 30-second timeout.
These may apply to different mechanisms (UserScoringLock=60s vs RebuildGuard=30s), but S07 does not distinguish between scoped reflow and full rebuild timeouts.

**Referenced in:** S07 §7.7

### Conflict 5: Reflow Retry Count (S07 vs TD-07)

**S07 §7.7** specifies "automatic retry up to 3 attempts."
**TD-07** describes "retry once, then 2-second delay, then fall back to full rebuild on next launch."
The retry strategy and count differ.

**Referenced in:** S07 §7.7

### Conflict 6: Structural Edit Queuing (S07 vs TD-04)

**S07 §7.6** states "No queuing of structural edits."
**TD-04** describes deferred reflow coalescing (pending triggers merged by subskill scope union).
The deferred coalescing is an internal optimisation, but the language creates potential ambiguity with S07's prohibition.

**Referenced in:** S07 §7.6

### Conflict 7: S16 Advisory Lock vs TD-04 In-Memory Mutex

S16 §16.4.3 specifies a database-level advisory lock for user scoring lock. TD-04 implements RebuildGuard as an in-memory mutex. Different mechanisms for the same purpose. S16 describes the database architecture; TD-04 describes the application implementation. Not a true conflict — different abstraction levels — but worth noting.

**Referenced in:** S16 §16.4

---

## Consolidated Gaps (All Spec Items Without TD Coverage)

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S01 | §1.16 | No overperformance tracking (explicit prohibition) | Low | Implicitly enforced by 5.0 cap, but the prohibition is not stated in any TD. |
| 2 | S01 | §1.16 | No automatic anchor adjustment (explicit prohibition) | Low | No TD introduces auto-adjustment, but the prohibition is uncodified. |
| 3 | S01 | §1.17 | Retired drills cannot be manually purged from scoring | Low | TD-04 state machine has no purge transition, so implicitly enforced. |
| 4 | S02 | §2.3 | Subskill semantic descriptions (purpose of each subskill) | Low | Display/documentation concern. TD-02 SubskillRef seeds ID and allocation but no description column. No functional impact. |
| 5 | S03 | §3.2 | Bag not configured -> Technique Block only rule | Medium | No TD codifies this validation. Could be missed in implementation. |
| 6 | S03 | §3.3 | Start Today's Practice conditional visibility | Low | UI behaviour not in TD. Implementation concern. |
| 7 | S03 | §3.3 | Start Clean Practice always visible | Low | UI behaviour not in TD. Implementation concern. |
| 8 | S04 | §4.1 | Anchor edits blocked while Drill in Retired state | Medium | No TD explicitly codifies this guard. Could allow unintended reflow. |
| 9 | S04 | §4.1 | User must reactivate Drill before editing anchors | Medium | Same as above. |
| 10 | S04 | §4.1 | Retired drills cannot be manually purged (repeat of S01 gap) | Low | Implicitly enforced. |
| 11 | S04 | §4.3 | Binary Hit/Miss intention declaration stored on Session | Medium | No TD-02 column, no TD-03 payload field. Feature may be missing from data model. |
| 12 | S04 | §4.4 | Target box does not scale by anchor level | Low | Implicit in design but not codified. |
| 13 | S04 | §4.4 | Historical Instances retain snapshot target values | Low | Moot since target definition is immutable. |
| 14 | S04 | §4.6 | Bulk Entry mechanism (entire feature) | Medium | Not in any TD. TD-05 defers to V2. S04 describes it as current spec. Potential spec/TD misalignment on scope. |
| 15 | S04 | §4.6 | Numeric input field default: blank (dash), not zero | Low | UI convention not in TD. |
| 16 | S04 | §4.8 | Do not display per-shot 0-5 during active Session | Low | UI prohibition not codified in TD. |
| 17 | S04 | §4.8 | Do not display running average during active Session | Low | UI prohibition not codified in TD. |
| 18 | S05 | §5.1 | SkillScore is not bucket-based | Low | Implicit in design. |
| 19 | S05 | §5.2 | No 1000-point scale reconstruction in Analysis | Low | Design constraint not codified. |
| 20 | S05 | §5.2 | Multi-Output drill-level averaged score not in subskill trends | Low | Separation rule not codified. |
| 21 | S05 | §5.2 | Rolling overlay operates across buckets only | Low | Not codified. |
| 22 | S05 | §5.2 | Multi-Output drill-level Session score = mean (display convention) | Low | Not codified. |
| 23 | S05 | §5.2 | Grid Cell Selection diagnostic visualisations (detailed) | Medium | Detailed grid diagnostics spec not in any TD. May be unimplemented. |
| 24 | S05 | §5.2 | 3x3 derived 1x3/3x1 summary views | Medium | Not in any TD. May be unimplemented. |
| 25 | S05 | §5.2 | Continuous Measurement/Raw Data Entry histograms | Medium | Not in any TD. May be unimplemented. |
| 26 | S05 | §5.2 | Binary Hit/Miss ratio visualisation | Medium | Not in any TD. May be unimplemented. |
| 27 | S05 | §5.2 | Cross-club aggregation for diagnostics | Low | Not codified. |
| 28 | S05 | §5.2 | No per-Set breakdown in diagnostics | Low | Not codified. |
| 29 | S05 | §5.2 | Raw analytics default 3 months | Low | Not codified. |
| 30 | S05 | §5.2 | Date Range Persistence (1 hour timer) | Low | Not codified in TD. |
| 31 | S05 | §5.3 | Plan Adherence time period options (5 options listed) | Low | TD mentions rollups but not specific options. |
| 32 | S05 | §5.3 | Plan Adherence date range persistence (1h, default 4 weeks) | Low | Not codified. |
| 33 | S05 | §5.3 | Rollup boundaries: home timezone + week start day | Low | Week start day not in TD. |
| 34 | S05 | §5.3 | Week start day: Monday or Sunday | Low | Setting not addressed in TD. |
| 35 | S05 | §5.4 | No window mechanics in Analysis (explicit prohibition) | Low | Implicit in design. |
| 36 | S05 | §5.4 | Session duration in Analysis for time-based analytics | Medium | Duration tracking not in any TD. |
| 37 | S05 | §5.4 | Duration as primary field for Technique Block | Medium | Not in any TD. |
| 38 | S06 | §6.2 | Session.UserDeclaration column | Medium | May be missing from TD-02 DDL |
| 39 | S06 | §6.2 | Session.SessionDuration column | Medium | May be missing from TD-02 DDL |
| 40 | S07 | §7.5.1 | No client-side buffering of rejected data (prohibition) | Low | Implicit in design |
| 41 | S07 | §7.5.1 | No partial save during lock (prohibition) | Low | Implicit |
| 42 | S07 | §7.5.1 | No retry queue for blocked operations (prohibition) | Low | Implicit |
| 43 | S07 | §7.5.1 | Input fields visible but submission disabled during lock | Low | UI detail |
| 44 | S07 | §7.5.1 | Global scoring lock + maintenance banner for system-initiated changes | Medium | No TD addresses server-initiated reflow orchestration |
| 45 | S07 | §7.8 | System-initiated parallel reflow with concurrency cap | Medium | Server-side orchestration not in TDs |
| 46 | S08 | §8.1.1 | SlotCapacity hard block below filled count | Low | Likely implemented but not codified |
| 47 | S08 | §8.1.2 | No draft stage for Routine creation | Low | Not codified |
| 48 | S08 | §8.1.2 | Save as Manual (Clone) feature | Medium | Not in any TD. May be unimplemented |
| 49 | S08 | §8.1.3 | Zero-capacity day handling differs between List/DayPlanning | Low | Nuance not codified |
| 50 | S08 | §8.1.3 | Schedule auto-delete for DayPlanning mode | Low | May not cover all cases |
| 51 | S08 | §8.2.1 | Fixed/RoutineRef entries not rerollable | Low | Likely implemented |
| 52 | S08 | §8.3.1 | Drill order is recommendation, not constraint | Low | Not codified |
| 53 | S08 | §8.3.2 | Technique Block Sessions participate in completion matching | Low | Likely implemented |
| 54 | S08 | §8.3.3 | No automatic correction for overflow drift | Low | Not codified |
| 55 | S08 | §8.3.4 | Session deletion reverts Slot to Incomplete | Low | Likely implemented |
| 56 | S08 | §8.4.1 | Manually completed Slots count for adherence | Low | Not codified |
| 57 | S08 | §8.4.1 | Same-day manual additions included in adherence | Low | Not codified |
| 58 | S08 | §8.4.3 | Rollup: home timezone + week start day | Low | Repeat from S05 |
| 59 | S08 | §8.4.4 | Date range persistence 1 hour | Low | Repeat from S05 |
| 60 | S08 | §8.8.1 | Unresolvable criterion notification | Low | Not codified |
| 61 | S08 | §8.10.4 | Random mode seeded PRNG (user ID + timestamp) | Low | Not codified |
| 62 | S08 | §8.11 | Home timezone auto-detect + manual override | Low | Not codified |
| 63 | S08 | §8.12.1 | Drill creation "Save & Practice" shortcut | Medium | Not in any TD. May be unimplemented |
| 64 | S09 | §9.1 | No maximum bag size (explicit statement) | Low | Implicit |
| 65 | S09 | §9.3 | Hard gate applies to all 6 contexts (Routine, Schedule, Calendar Slot may be ungated) | Medium | Gate may not be enforced during Routine/Schedule/Slot addition |
| 66 | S09 | §9.3 | Gate activation on last-club retirement | Medium | Cascade behaviour not codified |
| 67 | S09 | §9.3 | Existing entities preserved but execution-blocked on gate activation | Medium | Preservation + block not codified |
| 68 | S09 | §9.8 | Bag setup required during onboarding | Medium | No TD addresses onboarding |
| 69 | S09 | §9.8 | Standard 14-club preset | Medium | Preset not in TD or seed data |
| 70 | S09 | §9.8 | Quick-start UX | Low | UI detail |
| 71 | S09 | §9.9 | Speed/Weight units (future-compatible) | Low | Expected deferred |
| 72 | S09 | §9.9 | Canonical base units (Metres, Centimetres, etc.) | Low | Not codified |
| 73 | S09 | §9.10 | Analytics usage of carry/dispersion (future features) | Low | Expected deferred |
| 74 | S10 | §10.3 | No tagging or folder hierarchy (prohibition) | Low | Implicit |
| 75 | S10 | §10.4 | Anchors editable one drill at a time | Low | Implicit in API |
| 76 | S10 | §10.4 | Anchor edits blocked in Retired state (repeat) | Medium | Not codified |
| 77 | S10 | §10.5 | No preview simulation, no impact estimation (prohibition) | Low | Not codified |
| 78 | S10 | §10.6 | Per-drill unit override at creation, unit immutable post-creation | Medium | Not codified in TD |
| 79 | S10 | §10.6 | Canonical internal storage units | Low | Not codified |
| 80 | S10 | §10.9 | Week start day setting (repeat) | Low | Not codified |
| 81 | S10 | §10.9 | Date range persistence 1 hour (repeat) | Low | Not codified |
| 82 | S11 | §11.2 | Technique Block duration bounds (0-43200s) | Low | May be in seed data |
| 83 | S11 | §11.3 | Negativity governed by HardMinInput | Low | Implicit |
| 84 | S11 | §11.3 | Zero has no special treatment | Low | Implicit |
| 85 | S11 | §11.4 | No deferred batch/sweep/scheduled evaluation (prohibition) | Low | Implicit |
| 86 | S11 | §11.4 | Boundary values (exactly equal) not in breach | Low | Important for correctness |
| 87 | S11 | §11.5 | No severity levels or graduated indicators (prohibition) | Low | Implicit |
| 88 | S11 | §11.6 | Suppression does not block future detection | Low | Implicit |
| 89 | S12 | §12.1 | 5 architectural principles not codified | Low | Informational |
| 90 | S12 | §12.2 | Home Dashboard as persistent launch layer | High | Entire Home Dashboard missing from all TDs |
| 91 | S12 | §12.2 | Home icon on all tabs | Medium | Navigation control not codified |
| 92 | S12 | §12.2 | Tab state preservation on Home navigation | Low | Not codified |
| 93 | S12 | §12.2.2 | Home Dashboard entry points (Start Today's / Start Clean) | High | Home gap |
| 94 | S12 | §12.3 | All Home Dashboard content items (score, slots, buttons, exclusions) | High | Home gap |
| 95 | S12 | §12.4 | Infinite horizontal swipe in 3-day view | Low | UX detail |
| 96 | S12 | §12.4 | Drag-and-drop mechanics (3-day and 2-week views) | Medium | Not codified |
| 97 | S12 | §12.4 | 2-Week View interactions (tap-to-switch, drag Drill/Routine/Schedule) | Medium | Not codified |
| 98 | S12 | §12.4 | 2-Week View exclusions (no Slot editing, etc.) | Low | Not codified |
| 99 | S12 | §12.4 | Calendar toggle: no gesture dependency | Low | Not codified |
| 100 | S12 | §12.4 | Calendar Bottom Drawer structure (segmented, search, filters, drag handles) | Medium | Not codified |
| 101 | S12 | §12.4.5 | Create surface: 3 equal tiles | Low | TD has create screens but not tile entry |
| 102 | S12 | §12.4.5 | Save & Practice action | Medium | Not codified |
| 103 | S12 | §12.5 | Filter persistence rules (4 specific behaviours) | Low | Not codified |
| 104 | S12 | §12.5 | Routine list: flat + MRU sort | Low | Not codified |
| 105 | S12 | §12.5 | Track read-only with "Edit Drill" cross-navigation | Medium | Not codified |
| 106 | S12 | §12.5 | "Edit Drill" hidden for System Drills | Low | Not codified |
| 107 | S12 | §12.6 | Technique Block excluded from Drill Type filter | Low | Not codified |
| 108 | S12 | §12.6 | Drill scope auto-lock for Technique Block | Low | Not codified |
| 109 | S12 | §12.6 | Volume chart legend specification | Low | Not codified |
| 110 | S12 | §12.6.3 | Comparative Analytics (time range vs time range) | Medium | Entire feature not in any TD |
| 111 | S12 | §12.7 | Exit always routes to Home Dashboard | Medium | Home routing gap |
| 112 | S12 | §12.8 | Post-Session Summary: score delta, key statistics | Medium | Not fully enumerated in TD |
| 113 | S12 | §12.8 | Summary: dedicated state, no auto-dismiss, post-reflow scores | Low | Not codified |
| 114 | S12 | §12.10 | 7 cross-shortcuts catalogued | Low | Not codified |
| 115 | S12 | §12.11 | 10 interaction guarantees | Low | Not codified as a set |
| 116 | S12 | §12.12 | 7 explicit non-goals | Low | Not codified |
| 117 | S13 | §13.2.1 | Start Today's Practice queue population | High | Home entry point gap |
| 118 | S13 | §13.2.1 | Save & Practice entry point | Medium | Not codified |
| 119 | S13 | §13.4.1 | Create Drill from Session (queue operation) | Medium | Not in any TD |
| 120 | S13 | §13.6 | No client-side Instance buffering during reflow lock | Low | Explicit prohibition |
| 121 | S13 | §13.6.5 | Source Drill deletion during active PB behaviour | Medium | Not codified |
| 122 | S13 | §13.7 | No limit on same-drill executions per PB | Low | Implicit |
| 123 | S13 | §13.9 | Focus hierarchy (App → PB → Session) | Low | Not codified |
| 124 | S13 | §13.10 | Deferred Post-Session Summary on next app open (after auto-end) | Medium | Not codified |
| 125 | S13 | §13.10 | Passive banner for discarded empty PB | Low | Not codified |
| 126 | S13 | §13.10 | PB 4-hour timer measurement base | Low | Not codified |
| 127 | S13 | §13.11 | Calendar independence: PendingDrill removal doesn't modify Slot | Low | Not codified |
| 128 | S13 | §13.11 | No real-time Slot modification during Live Practice | Low | Not codified |
| 129 | S13 | §13.12 | Save Practice as Routine (entire feature) | Medium | Not in any TD |
| 130 | S13 | §13.13 | Post-Summary shown only if ≥1 Session | Low | Not codified |
| 131 | S13 | §13.13 | Summary content: score delta, Skill Area impact direction | Medium | Not fully in TD |
| 132 | S13 | §13.13 | Technique Block in summary: no score/delta/impact | Low | Not codified |
| 133 | S13 | §13.13 | Summary is read-only | Low | Not codified |
| 134 | S13 | §13.14 | Crash recovery UX (restore Live Practice on next open) | Medium | Not codified |
| 135 | S14 | §14.7 | Practice-ground design philosophy | Low | Informational |
| 136 | S14 | §14.8 | 80% screen takeover for club selector | Medium | Core UX pattern not codified |
| 137 | S14 | §14.8 | Single eligible club: auto-select + hide selector | Low | Not codified |
| 138 | S14 | §14.9 | Target dimensions integrated into grid visual | Low | Not codified |
| 139 | S14 | §14.9 | User declaration reminder in title bar | Low | Not codified |
| 140 | S14 | §14.9 | Submit + Save dual-action buttons for Raw Data Entry | Medium | Not codified |
| 141 | S14 | §14.10 | Haptic feedback on Instance save | Low | Not codified |
| 142 | S14 | §14.10 | No sound on standard shots (sound for banners only) | Low | Not codified |
| 143 | S14 | §14.10 | Undo Last Instance mechanism | Medium | Not in any TD |
| 144 | S14 | §14.10 | Set Transition interstitial | Low | Not codified |
| 145 | S14 | §14.10.5 | Bulk Entry mode (entire feature) | High | Not in any TD |
| 146 | S14 | §14.10.6 | End/Discard/Restart in secondary menu | Low | Not codified |
| 147 | S14 | §14.10.6 | Restart/Discard confirmation prompts | Low | Not codified |
| 148 | S14 | §14.10.7 | 80% Screen Takeover (full specification) | Medium | Not codified |
| 149 | S14 | §14.10 | Portrait-only for Drill Entry Screen | Low | Not codified |
| 150 | S14 | §14.10.8 | Session Duration Tracking (passive for scored drills) | Medium | Not codified |
| 151 | S14 | §14.12 | Session.SessionDuration column missing from TD-02 | Medium | Data model addition not in TD-02 |
| 152 | S15 | §15.1 | Target audience, tonal direction, design intent, positioning | Low | Informational |
| 153 | S15 | §15.1 | Explicit exclusions (gamification, theatrics, lifestyle) | Low | Not codified |
| 154 | S15 | §15.2 | Tone & voice: no exclamation marks, no motivational language, neutral scores | Low | Not codified |
| 155 | S15 | §15.3 | Interaction/semantic colour separation rule | Low | Structural design rule |
| 156 | S15 | §15.3 | color.primary.focus (60% opacity focus ring) | Low | May be missing from tokens.dart |
| 157 | S15 | §15.3 | No red for miss (explicit prohibition) | Low | Design rule |
| 158 | S15 | §15.4 | surface.scrim (Black @ 40% opacity) | Low | May be missing from tokens.dart |
| 159 | S15 | §15.4 | On-press: darken ~4%, no scale/bounce | Low | Not codified |
| 160 | S15 | §15.4 | Elevation exclusion list (5 prohibitions) | Low | Not codified |
| 161 | S15 | §15.5 | No animated counting (prohibition) | Low | Not codified |
| 162 | S15 | §15.5 | Typography exclusion list (7 prohibitions) | Low | Not codified |
| 163 | S15 | §15.6 | No arbitrary spacing values (prohibition) | Low | Not codified |
| 164 | S15 | §15.7 | Segmented control radius (8px + 8px) | Low | May be missing from tokens |
| 165 | S15 | §15.7 | No pill-shaped buttons (prohibition) | Low | Not codified |
| 166 | S15 | §15.8 | Achievement banner: 6 animation prohibitions | Low | Not codified |
| 167 | S15 | §15.9 | Icon style (outlined, geometric, 1.5-2px stroke, size grid) | Low | Not codified |
| 168 | S15 | §15.9 | No golf-themed decorative icons | Low | Not codified |
| 169 | S15 | §15.10 | Easing: ease-in-out cubic only | Low | Not codified |
| 170 | S15 | §15.10 | No transitions exceed 200ms | Low | Not codified |
| 171 | S15 | §15.10 | Audio model (silent default, haptic tick grid, ping achievement only) | Low | Not codified |
| 172 | S15 | §15.10 | 12-item motion prohibition list | Low | Not codified |
| 173 | S15 | §15.11 | No per-domain visual differentiation (unification rule) | Low | Not codified |
| 174 | S15 | §15.12 | Logo: minimal wordmark only, product-name-agnostic governance | Low | Not codified |
| 175 | S15 | §15.13 | WCAG AA global minimum, selective AAA on 4 surfaces | Medium | Not codified in any TD |
| 176 | S15 | §15.13 | Outdoor usage: high contrast for Drill Entry | Low | Not codified |
| 177 | S15 | §15.14 | Product-name-agnostic token naming + prohibited patterns | Low | Not codified |
| 178 | S15 | §15.15 | Token-first theming, light mode deferred, white-label support | Low | Not codified |
| 179 | S16 | §16.3 | Partial indexes on IsDeleted=false | Low | Not in TD-02 |
| 180 | S16 | §16.3 | Deferred GIN indexes on JSON columns | Low | Not codified |
| 181 | S16 | §16.4 | Default isolation: Repeatable Read | Medium | Not in any TD |
| 182 | S16 | §16.4 | Materialised swap: Serializable isolation | Medium | Not in any TD |
| 183 | S16 | §16.4 | Retry parameters (6 categories with exact values) | Medium | Not codified |
| 184 | S16 | §16.4 | Retry idempotency requirement | Low | Not codified |
| 185 | S16 | §16.4 | Cross-user contention guarantee (RLS + Repeatable Read) | Low | Not codified |
| 186 | S16 | §16.5 | DOWN (rollback) in migration files | Low | Not codified |
| 187 | S16 | §16.5 | Idempotent UP (IF NOT EXISTS) | Low | Not codified |
| 188 | S16 | §16.5 | 5 migration categories | Low | Not codified |
| 189 | S16 | §16.5 | Migration governance rules (4 rules) | Low | Not codified |
| 190 | S16 | §16.5 | Zero-downtime expand-contract pattern | Low | Not codified |
| 191 | S16 | §16.6 | Optional DB-level BEFORE UPDATE triggers for snapshots | Low | Not codified |
| 192 | S16 | §16.7 | RPO 15 min / RTO 1 hour | Medium | Not in any TD |
| 193 | S16 | §16.7 | Backup strategy (WAL + daily + weekly) | Medium | Not codified |
| 194 | S16 | §16.7 | 4 recovery scenarios | Medium | Not codified |
| 195 | S16 | §16.7 | EventLog tiered archival (6-month hot, indefinite cold) | Medium | Not codified |
| 196 | S16 | §16.7 | Daily archival job specification | Low | Not codified |
| 197 | S16 | §16.7 | Weekly automated backup restore test | Low | Not codified |
| 198 | S16 | §16.8 | 9 query performance targets | Medium | Not codified |
| 199 | S16 | §16.8 | 5-tier scaling roadmap | Low | Not codified |
| 200 | S16 | §16.8 | Volume projections per user | Low | Not codified |
| 201 | S16 | §16.8 | Data retention policy (indefinite active, 90-day soft-delete) | Medium | Not codified |
| 202 | S16 | §16.8 | Connection management (6 parameters + mandatory pooling) | Medium | Not codified |
| 203 | S16 | §16.8 | 17 operational monitors with thresholds | Medium | Not codified |
| 204 | S17 | §17.1 | Training-only exclusions (5 items: no on-course, GPS, competition, etc.) | Low | Not codified |
| 205 | S17 | §17.2 | No environmental mode switching or context detection | Low | Not codified |
| 206 | S17 | §17.3 | No automatic data pruning in V1 | Low | Not codified |
| 207 | S17 | §17.3 | Local EventLog archival deferred to V2 | Low | Not codified |
| 208 | S17 | §17.4 | No device limit per user | Low | Not codified |
| 209 | S17 | §17.4 | DeviceID scope restrictions | Low | Not codified |
| 210 | S17 | §17.4 | Device deregistration behaviour | Low | Not codified |
| 211 | S17 | §17.4 | Manual sync trigger in Settings | Low | Not codified |
| 212 | S17 | §17.4 | Sync-triggered rebuild is non-blocking (not full scoring lock) | Medium | Not codified |
| 213 | S17 | §17.4 | User-initiated reflow priority over sync rebuild | Medium | Not codified |
| 214 | S17 | §17.4 | Schema migrations preserve backward compatibility | Medium | Not codified |
| 215 | S17 | §17.5 | No re-import in V1 | Low | Not codified |
| 216 | S17 | §17.5 | 4 sharing exclusions (no shareable links, dashboards, portals, coach feeds) | Low | Not codified |
| 217 | S17 | §17.5 | Export scope (9 entity types) | Low | Not codified |
| 218 | S17 | §17.6 | No coach/admin role in V1 (5 exclusions) | Low | Not codified |
| 219 | S17 | §17.6 | Future compatibility for coach layer | Low | Not codified |
| 220 | S17 | §17.7 | 9 explicitly not-enforced behaviours | Low | Not codified |
| 221 | S17 | §17.8 | No additional PB/Session/daily duration limits | Low | Not codified |
| 222 | S17 | §17.10 | Cross-section impact updates (S07 sync rebuild, S13 offline list, S00 terms) | Low | Not codified |

---

## Consolidated Summary

| Category | S00–S02 | S03–S05 | S06–S08 | S09–S11 | S12–S14 | S15–S17 | **Total** |
|----------|---------|---------|---------|---------|---------|---------|-----------|
| Spec items checked | ~130 | ~160 | ~175 | ~140 | ~230 | ~280 | **~1115** |
| Fully covered by TD | ~124 | ~125 | ~143 | ~113 | ~137 | ~151 | **~793** |
| Gaps (spec without TD) | 4 | 33 | 26 | 25 | 63 | 71 | **222** |
| Conflicts | 1 | 0 (1 carried) | 5 | 0 (2 carried) | 0 (2 carried) | 1 (2 carried) | **7 unique** |
| TD-only items | ~25 | — | — | — | — | — | **~25** |

---

## Per-Batch Assessments

### S00–S02: Canonical Terminology, Scoring Engine, Skill Architecture

S00, S01, and S02 have excellent TD coverage. The scoring engine, skill architecture, and canonical terminology are thoroughly addressed across TD-01 through TD-08, particularly in TD-02 (schema), TD-03 (API contracts), TD-04 (state machines and reflow), and TD-05 (test cases). The single conflict regarding immutable post-creation field lists (S00 §11 vs TD-03 §5.3) is the most actionable finding and should be resolved before production. The four gaps are all low-risk items where the spec makes explicit prohibitions that are implicitly enforced by the TD architecture but never explicitly stated.

### S03–S05: User Journey Architecture, Drill Entry System, Review

S03 (User Journey Architecture) has excellent TD coverage — nearly every lifecycle rule, state machine transition, and concurrency model is addressed in TD-04 and TD-06. S04 (Drill Entry System) is well-covered for core functionality but has notable gaps around Bulk Entry (which TD-05 defers to V2, creating a spec/TD scope conflict), the Binary Hit/Miss intention declaration, and anchor edit guards during Retired state. S05 (Review: SkillScore & Analysis) has the largest gap count due to detailed diagnostic visualisation specifications (grid distribution views, histograms, ratio bars) and Analysis-specific UI conventions (date range persistence, display prohibitions) that are not codified in any TD. Many of these S05 gaps represent fine-grained UI specifications that TDs typically do not address, but the raw metric diagnostic features (gaps 19-22) represent potentially unimplemented functionality.

### S06–S08: Data Model & Persistence, Reflow Governance, Practice Planning

S06 (Data Model) has excellent TD coverage since TD-02 is its direct implementation counterpart. The two Session columns (UserDeclaration, SessionDuration) are the key verification items. S07 (Reflow Governance) is well-covered by TD-04 and TD-07, but has notable conflicts around timeout values and retry counts that suggest the TD implementation made pragmatic adjustments. The system-initiated reflow scenario (global lock, maintenance banner, parallel execution) is entirely absent from TDs — these are server-side orchestration features deferred beyond V1. S08 (Planning Layer) has very good coverage through TD-06 Phase 5, with gaps primarily in fine-grained UI conventions and the "Save as Manual" clone feature.

### S09–S11: Golf Bag & Club Configuration, Settings, Metrics Integrity

S09 (Golf Bag) is well-covered for core functionality through TD-02 and TD-03. The main gaps are around the onboarding flow (bag setup, 14-club preset) and the hard gate enforcement across all 6 contexts. S10 (Settings) is well-covered by TD-06 Phase 8 implementation. The per-drill unit override and week start day setting are the most notable gaps. S11 (Metrics Integrity) has excellent coverage — the integrity system is thoroughly addressed in TD-02, TD-04, TD-05, TD-06, and TD-07. Gaps are primarily explicit prohibitions (no batch evaluation, no severity levels) that are implicitly enforced by the architecture.

### S12–S14: UI/UX Structural Architecture, Live Practice Workflow, Drill Entry Screens

S12 (UI/UX) has the most significant gap: the Home Dashboard is completely absent from all TDs. This is the most architecturally significant finding — the entire persistent launch layer, its content, its navigation controls, and its entry points to Live Practice are specified in S12 but not designed in any TD. Beyond Home, the major gap areas are Calendar drag-and-drop mechanics, Comparative Analytics in Review, and the detailed Cross-Shortcut catalogue. S13 (Live Practice) is well-covered by TD-04 (state machines) and TD-06 Phase 4 (screens). The main gaps are: Save Practice as Routine (entire feature), Create Drill from Session (queue operation), crash recovery UX, and the Home Dashboard entry points. S14 (Drill Entry Screens) has excellent coverage for the System Drill Library (28 drills fully specified in TD-02 seed data). The gaps are concentrated in UI interaction patterns: Bulk Entry mode (entire feature not in any TD), 80% Screen Takeover rule, Undo Last Instance, Session Duration Tracking (passive), and haptic feedback.

### S15–S17: Branding & Design System, Database Architecture, Real-World Application

S15 (Branding & Design System) has good coverage for concrete token values (colours, spacing, typography, motion timing) through TD-06 Phase 1's tokens.dart implementation. The gaps are predominantly design governance rules: prohibition lists, separation principles, accessibility standards, iconography guidelines, and tone/voice rules. Risk is low — these rules constrain how things should look and feel, not what should be built. S16 (Database Architecture) has strong coverage for the schema itself (TD-02) but significant gaps in operational infrastructure: transaction isolation levels, retry parameters, backup/recovery strategy (RPO/RTO), EventLog archival, performance targets, connection management, and operational monitoring. This represents the largest thematic gap area: no TD addresses server-side operational architecture. S17 (Real-World Application Layer) is well-covered for the core technical infrastructure (offline-first, sync model, multi-device, data model) through TD-01 and TD-06 Phase 7. The gaps are primarily explicit exclusions and non-functional constraints. The most notable technical gap is the sync rebuild priority model (S17 specifies user-initiated reflow takes priority over sync rebuild, not codified in any TD).

---

## Gap Risk Distribution

| Risk Level | Count | Percentage |
|------------|-------|------------|
| High | 5 | 2% |
| Medium | 61 | 27% |
| Low | 156 | 70% |
| **Total** | **222** | **100%** |

---

*End of Consolidated S00–S17 vs TD Gap Analysis*