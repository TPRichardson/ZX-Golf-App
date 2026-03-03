# Gap Analysis: S00, S01, S02 vs TD Reference Catalogue

> Batch 2A — Canonical Terminology (S00), Scoring Engine (S01), Skill Architecture (S02)
> compared against all 8 Technical Design documents (TD-01 through TD-08).

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

## Conflicts Identified

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
1. **ClubSelectionMode**: Present in S00 but absent from TD-03/TD-04 immutability guards.
2. **TargetDefinition**: Present in S00 but absent from TD-03/TD-04 immutability guards.
3. **ScoringMode**: Absent from S00 but present in TD-03/TD-04 immutability guards.
4. **InputMode**: Absent from S00 but present in TD-03/TD-04 immutability guards.

Per source-of-truth hierarchy, TD-03 governs over S00 for implementation. However, this divergence should be explicitly resolved — either S00 should be updated to match TD-03, or TD-03 should be updated to include ClubSelectionMode and TargetDefinition. ScoringMode and InputMode are arguably subsumed by MetricSchema selection, but the spec should be explicit.

---

## Gaps Identified (Spec items without TD coverage)

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S01 | §1.16 | No overperformance tracking (explicit prohibition) | Low | Implicitly enforced by 5.0 cap, but the prohibition is not stated in any TD. |
| 2 | S01 | §1.16 | No automatic anchor adjustment (explicit prohibition) | Low | No TD introduces auto-adjustment, but the prohibition is uncodified. |
| 3 | S01 | §1.17 | Retired drills cannot be manually purged from scoring | Low | TD-04 state machine has no purge transition, so implicitly enforced. |
| 4 | S02 | §2.3 | Subskill semantic descriptions (purpose of each subskill) | Low | Display/documentation concern. TD-02 SubskillRef seeds ID and allocation but no description column. No functional impact. |

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

## Summary

| Category | Count |
|----------|-------|
| Spec items checked | ~130 |
| Fully covered by TD | ~124 |
| Gaps (spec without TD) | 4 (all low risk) |
| Conflicts | 1 (immutable field list divergence, 4 sub-items) |
| TD-only items (expected in other specs) | ~25 |

**Overall Assessment:** S00, S01, and S02 have excellent TD coverage. The scoring engine, skill architecture, and canonical terminology are thoroughly addressed across TD-01 through TD-08, particularly in TD-02 (schema), TD-03 (API contracts), TD-04 (state machines and reflow), and TD-05 (test cases).

The single conflict regarding immutable post-creation field lists (S00 §11 vs TD-03 §5.3) is the most actionable finding and should be resolved before production. The four gaps are all low-risk items where the spec makes explicit prohibitions that are implicitly enforced by the TD architecture but never explicitly stated.

---

*End of S00-S02 vs TD Gap Analysis (Batch 2A)*
