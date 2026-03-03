# Gap Analysis: S03, S04, S05 vs TD Reference Catalogue

> Batch 2B — User Journey Architecture (S03), Drill Entry System (S04),
> Review: SkillScore & Analysis (S05)
> compared against all 8 Technical Design documents (TD-01 through TD-08).

---

## Methodology

Same as Batch 2A. Each spec item is classified as Covered, Gap, Conflict, or TD-Only.

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

## Conflicts Identified

### Conflict 1 (Carried from S00-S02): Immutable Post-Creation Field Lists Diverge

S04 §4.1 replicates the same immutable field list as S00 §11, including ClubSelectionMode and TargetDefinition but omitting ScoringMode and InputMode. TD-03 §5.3 includes ScoringMode and InputMode but omits ClubSelectionMode and TargetDefinition. This conflict is identical to the one identified in the S00-S02 analysis.

---

## Gaps Summary

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S03 | §3.2 | Bag not configured -> Technique Block only rule | Medium | No TD codifies this validation. Could be missed in implementation. |
| 2 | S03 | §3.3 | Start Today's Practice conditional visibility | Low | UI behaviour not in TD. Implementation concern. |
| 3 | S03 | §3.3 | Start Clean Practice always visible | Low | UI behaviour not in TD. Implementation concern. |
| 4 | S04 | §4.1 | Anchor edits blocked while Drill in Retired state | Medium | No TD explicitly codifies this guard. Could allow unintended reflow. |
| 5 | S04 | §4.1 | User must reactivate Drill before editing anchors | Medium | Same as above. |
| 6 | S04 | §4.1 | Retired drills cannot be manually purged (repeat of S01 gap) | Low | Implicitly enforced. |
| 7 | S04 | §4.3 | Binary Hit/Miss intention declaration stored on Session | Medium | No TD-02 column, no TD-03 payload field. Feature may be missing from data model. |
| 8 | S04 | §4.4 | Target box does not scale by anchor level | Low | Implicit in design but not codified. |
| 9 | S04 | §4.4 | Historical Instances retain snapshot target values | Low | Moot since target definition is immutable. |
| 10 | S04 | §4.6 | Bulk Entry mechanism (entire feature) | Medium | Not in any TD. TD-05 defers to V2. S04 describes it as current spec. Potential spec/TD misalignment on scope. |
| 11 | S04 | §4.6 | Numeric input field default: blank (dash), not zero | Low | UI convention not in TD. |
| 12 | S04 | §4.8 | Do not display per-shot 0-5 during active Session | Low | UI prohibition not codified in TD. |
| 13 | S04 | §4.8 | Do not display running average during active Session | Low | UI prohibition not codified in TD. |
| 14 | S05 | §5.1 | SkillScore is not bucket-based | Low | Implicit in design. |
| 15 | S05 | §5.2 | No 1000-point scale reconstruction in Analysis | Low | Design constraint not codified. |
| 16 | S05 | §5.2 | Multi-Output drill-level averaged score not in subskill trends | Low | Separation rule not codified. |
| 17 | S05 | §5.2 | Rolling overlay operates across buckets only | Low | Not codified. |
| 18 | S05 | §5.2 | Multi-Output drill-level Session score = mean (display convention) | Low | Not codified. |
| 19 | S05 | §5.2 | Grid Cell Selection diagnostic visualisations (detailed) | Medium | Detailed grid diagnostics spec not in any TD. May be unimplemented. |
| 20 | S05 | §5.2 | 3x3 derived 1x3/3x1 summary views | Medium | Not in any TD. May be unimplemented. |
| 21 | S05 | §5.2 | Continuous Measurement/Raw Data Entry histograms | Medium | Not in any TD. May be unimplemented. |
| 22 | S05 | §5.2 | Binary Hit/Miss ratio visualisation | Medium | Not in any TD. May be unimplemented. |
| 23 | S05 | §5.2 | Cross-club aggregation for diagnostics | Low | Not codified. |
| 24 | S05 | §5.2 | No per-Set breakdown in diagnostics | Low | Not codified. |
| 25 | S05 | §5.2 | Raw analytics default 3 months | Low | Not codified. |
| 26 | S05 | §5.2 | Date Range Persistence (1 hour timer) | Low | Not codified in TD. |
| 27 | S05 | §5.3 | Plan Adherence time period options (5 options listed) | Low | TD mentions rollups but not specific options. |
| 28 | S05 | §5.3 | Plan Adherence date range persistence (1h, default 4 weeks) | Low | Not codified. |
| 29 | S05 | §5.3 | Rollup boundaries: home timezone + week start day | Low | Week start day not in TD. |
| 30 | S05 | §5.3 | Week start day: Monday or Sunday | Low | Setting not addressed in TD. |
| 31 | S05 | §5.4 | No window mechanics in Analysis (explicit prohibition) | Low | Implicit in design. |
| 32 | S05 | §5.4 | Session duration in Analysis for time-based analytics | Medium | Duration tracking not in any TD. |
| 33 | S05 | §5.4 | Duration as primary field for Technique Block | Medium | Not in any TD. |

---

## Summary

| Category | Count |
|----------|-------|
| Spec items checked | ~160 |
| Fully covered by TD | ~125 |
| Gaps (spec without TD) | 33 |
| Conflicts | 1 (carried from Batch 2A) |

**Overall Assessment:** S03 (User Journey Architecture) has excellent TD coverage — nearly every lifecycle rule, state machine transition, and concurrency model is addressed in TD-04 and TD-06. S04 (Drill Entry System) is well-covered for core functionality but has notable gaps around Bulk Entry (which TD-05 defers to V2, creating a spec/TD scope conflict), the Binary Hit/Miss intention declaration, and anchor edit guards during Retired state. S05 (Review: SkillScore & Analysis) has the largest gap count due to detailed diagnostic visualisation specifications (grid distribution views, histograms, ratio bars) and Analysis-specific UI conventions (date range persistence, display prohibitions) that are not codified in any TD. Many of these S05 gaps represent fine-grained UI specifications that TDs typically do not address, but the raw metric diagnostic features (gaps 19-22) represent potentially unimplemented functionality.

---

*End of S03-S05 vs TD Gap Analysis (Batch 2B)*
