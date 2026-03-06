# Gap Analysis: S09, S10, S11 vs TD Reference Catalogue

> Batch 2D — Golf Bag & Club Configuration (S09), Settings & Configuration (S10),
> Metrics Integrity & Safeguards (S11)
> compared against all 8 Technical Design documents (TD-01 through TD-08).

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

## Conflicts Identified

### Conflict 1 (Carried): ClubSelectionMode Immutability

S10 §10.7 states ClubSelectionMode is immutable after drill creation. TD-03 structural immutability guard does not include ClubSelectionMode. Same conflict from S00/S04.

### Conflict 2: S06 ClosureType (Carried from S06-S08)

S06/PracticeBlock.ClosureType defines {Manual, AutoClosed}. TD-04 defines {Manual, ScheduledAutoEnd, SessionTimeout}. Carried forward.

---

## Gaps Summary

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S09 | §9.1 | No maximum bag size (explicit statement) | Low | Implicit |
| 2 | S09 | §9.3 | Hard gate applies to all 6 contexts (Routine, Schedule, Calendar Slot may be ungated) | Medium | Gate may not be enforced during Routine/Schedule/Slot addition |
| 3 | S09 | §9.3 | Gate activation on last-club retirement | Medium | Cascade behaviour not codified |
| 4 | S09 | §9.3 | Existing entities preserved but execution-blocked on gate activation | Medium | Preservation + block not codified |
| 5 | S09 | §9.8 | Bag setup required during onboarding | Medium | No TD addresses onboarding |
| 6 | S09 | §9.8 | Standard 14-club preset | Medium | Preset not in TD or seed data |
| 7 | S09 | §9.8 | Quick-start UX | Low | UI detail |
| 8 | S09 | §9.9 | Speed/Weight units (future-compatible) | Low | Expected deferred |
| 9 | S09 | §9.9 | Canonical base units (Metres, Centimetres, etc.) | Low | Not codified |
| 10 | S09 | §9.10 | Analytics usage of carry/dispersion (future features) | Low | Expected deferred |
| 11 | S10 | §10.3 | No tagging or folder hierarchy (prohibition) | Low | Implicit |
| 12 | S10 | §10.4 | Anchors editable one drill at a time | Low | Implicit in API |
| 13 | S10 | §10.4 | Anchor edits blocked in Retired state (repeat) | Medium | Not codified |
| 14 | S10 | §10.5 | No preview simulation, no impact estimation (prohibition) | Low | Not codified |
| 15 | S10 | §10.6 | Per-drill unit override at creation, unit immutable post-creation | Medium | Not codified in TD |
| 16 | S10 | §10.6 | Canonical internal storage units | Low | Not codified |
| 17 | S10 | §10.9 | Week start day setting (repeat) | Low | Not codified |
| 18 | S10 | §10.9 | Date range persistence 1 hour (repeat) | Low | Not codified |
| 19 | S11 | §11.2 | Technique Block duration bounds (0-43200s) | Low | May be in seed data |
| 20 | S11 | §11.3 | Negativity governed by HardMinInput | Low | Implicit |
| 21 | S11 | §11.3 | Zero has no special treatment | Low | Implicit |
| 22 | S11 | §11.4 | No deferred batch/sweep/scheduled evaluation (prohibition) | Low | Implicit |
| 23 | S11 | §11.4 | Boundary values (exactly equal) not in breach | Low | Important for correctness |
| 24 | S11 | §11.5 | No severity levels or graduated indicators (prohibition) | Low | Implicit |
| 25 | S11 | §11.6 | Suppression does not block future detection | Low | Implicit |

---

## Summary

| Category | Count |
|----------|-------|
| Spec items checked | ~140 |
| Fully covered by TD | ~113 |
| Gaps (spec without TD) | 25 |
| Conflicts | 2 (both carried from previous batches) |

**Overall Assessment:** S09 (Golf Bag) is well-covered for core functionality through TD-02 and TD-03. The main gaps are around the onboarding flow (bag setup, 14-club preset) and the hard gate enforcement across all 6 contexts. S10 (Settings) is well-covered by TD-06 Phase 8 implementation. The per-drill unit override and week start day setting are the most notable gaps. S11 (Metrics Integrity) has excellent coverage — the integrity system is thoroughly addressed in TD-02, TD-04, TD-05, TD-06, and TD-07. Gaps are primarily explicit prohibitions (no batch evaluation, no severity levels) that are implicitly enforced by the architecture.

---

*End of S09-S11 vs TD Gap Analysis (Batch 2D)*
