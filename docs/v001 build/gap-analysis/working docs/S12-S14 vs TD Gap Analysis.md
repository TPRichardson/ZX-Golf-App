# Gap Analysis: S12, S13, S14 vs TD Reference Catalogue

> Batch 2E — UI/UX Structural Architecture (S12), Live Practice Workflow (S13),
> Drill Entry Screens & System Drill Library (S14)
> compared against all 8 Technical Design documents (TD-01 through TD-08).

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

## Conflicts Identified

### Conflict 1 (Carried): ClubSelectionMode Immutability

S12/S14 reference Club Selection Mode per drill. S10 states it is immutable after creation. TD-03 structural immutability guard does not include ClubSelectionMode. Carried from previous batches.

### Conflict 2 (Carried): ClosureType

S06/PracticeBlock.ClosureType values differ between S-docs and TD-04. Carried forward.

---

## Gaps Summary

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S12 | §12.1 | 5 architectural principles not codified | Low | Informational |
| 2 | S12 | §12.2 | Home Dashboard as persistent launch layer | High | Entire Home Dashboard missing from all TDs |
| 3 | S12 | §12.2 | Home icon on all tabs | Medium | Navigation control not codified |
| 4 | S12 | §12.2 | Tab state preservation on Home navigation | Low | Not codified |
| 5 | S12 | §12.2.2 | Home Dashboard entry points (Start Today's / Start Clean) | High | Home gap |
| 6 | S12 | §12.3 | All Home Dashboard content items (score, slots, buttons, exclusions) | High | Home gap |
| 7 | S12 | §12.4 | Infinite horizontal swipe in 3-day view | Low | UX detail |
| 8 | S12 | §12.4 | Drag-and-drop mechanics (3-day and 2-week views) | Medium | Not codified |
| 9 | S12 | §12.4 | 2-Week View interactions (tap-to-switch, drag Drill/Routine/Schedule) | Medium | Not codified |
| 10 | S12 | §12.4 | 2-Week View exclusions (no Slot editing, etc.) | Low | Not codified |
| 11 | S12 | §12.4 | Calendar toggle: no gesture dependency | Low | Not codified |
| 12 | S12 | §12.4 | Calendar Bottom Drawer structure (segmented, search, filters, drag handles) | Medium | Not codified |
| 13 | S12 | §12.4.5 | Create surface: 3 equal tiles | Low | TD has create screens but not tile entry |
| 14 | S12 | §12.4.5 | Save & Practice action | Medium | Not codified |
| 15 | S12 | §12.5 | Filter persistence rules (4 specific behaviours) | Low | Not codified |
| 16 | S12 | §12.5 | Routine list: flat + MRU sort | Low | Not codified |
| 17 | S12 | §12.5 | Track read-only with "Edit Drill" cross-navigation | Medium | Not codified |
| 18 | S12 | §12.5 | "Edit Drill" hidden for System Drills | Low | Not codified |
| 19 | S12 | §12.6 | Technique Block excluded from Drill Type filter | Low | Not codified |
| 20 | S12 | §12.6 | Drill scope auto-lock for Technique Block | Low | Not codified |
| 21 | S12 | §12.6 | Volume chart legend specification | Low | Not codified |
| 22 | S12 | §12.6.3 | Comparative Analytics (time range vs time range) | Medium | Entire feature not in any TD |
| 23 | S12 | §12.7 | Exit always routes to Home Dashboard | Medium | Home routing gap |
| 24 | S12 | §12.8 | Post-Session Summary: score delta, key statistics | Medium | Not fully enumerated in TD |
| 25 | S12 | §12.8 | Summary: dedicated state, no auto-dismiss, post-reflow scores | Low | Not codified |
| 26 | S12 | §12.10 | 7 cross-shortcuts catalogued | Low | Not codified |
| 27 | S12 | §12.11 | 10 interaction guarantees | Low | Not codified as a set |
| 28 | S12 | §12.12 | 7 explicit non-goals | Low | Not codified |
| 29 | S13 | §13.2.1 | Start Today's Practice queue population | High | Home entry point gap |
| 30 | S13 | §13.2.1 | Save & Practice entry point | Medium | Not codified |
| 31 | S13 | §13.4.1 | Create Drill from Session (queue operation) | Medium | Not in any TD |
| 32 | S13 | §13.6 | No client-side Instance buffering during reflow lock | Low | Explicit prohibition |
| 33 | S13 | §13.6.5 | Source Drill deletion during active PB behaviour | Medium | Not codified |
| 34 | S13 | §13.7 | No limit on same-drill executions per PB | Low | Implicit |
| 35 | S13 | §13.9 | Focus hierarchy (App → PB → Session) | Low | Not codified |
| 36 | S13 | §13.10 | Deferred Post-Session Summary on next app open (after auto-end) | Medium | Not codified |
| 37 | S13 | §13.10 | Passive banner for discarded empty PB | Low | Not codified |
| 38 | S13 | §13.10 | PB 4-hour timer measurement base | Low | Not codified |
| 39 | S13 | §13.11 | Calendar independence: PendingDrill removal doesn't modify Slot | Low | Not codified |
| 40 | S13 | §13.11 | No real-time Slot modification during Live Practice | Low | Not codified |
| 41 | S13 | §13.12 | Save Practice as Routine (entire feature) | Medium | Not in any TD |
| 42 | S13 | §13.13 | Post-Summary shown only if ≥1 Session | Low | Not codified |
| 43 | S13 | §13.13 | Summary content: score delta, Skill Area impact direction | Medium | Not fully in TD |
| 44 | S13 | §13.13 | Technique Block in summary: no score/delta/impact | Low | Not codified |
| 45 | S13 | §13.13 | Summary is read-only | Low | Not codified |
| 46 | S13 | §13.14 | Crash recovery UX (restore Live Practice on next open) | Medium | Not codified |
| 47 | S14 | §14.7 | Practice-ground design philosophy | Low | Informational |
| 48 | S14 | §14.8 | 80% screen takeover for club selector | Medium | Core UX pattern not codified |
| 49 | S14 | §14.8 | Single eligible club: auto-select + hide selector | Low | Not codified |
| 50 | S14 | §14.9 | Target dimensions integrated into grid visual | Low | Not codified |
| 51 | S14 | §14.9 | User declaration reminder in title bar | Low | Not codified |
| 52 | S14 | §14.9 | Submit + Save dual-action buttons for Raw Data Entry | Medium | Not codified |
| 53 | S14 | §14.10 | Haptic feedback on Instance save | Low | Not codified |
| 54 | S14 | §14.10 | No sound on standard shots (sound for banners only) | Low | Not codified |
| 55 | S14 | §14.10 | Undo Last Instance mechanism | Medium | Not in any TD |
| 56 | S14 | §14.10 | Set Transition interstitial | Low | Not codified |
| 57 | S14 | §14.10.5 | Bulk Entry mode (entire feature) | High | Not in any TD |
| 58 | S14 | §14.10.6 | End/Discard/Restart in secondary menu | Low | Not codified |
| 59 | S14 | §14.10.6 | Restart/Discard confirmation prompts | Low | Not codified |
| 60 | S14 | §14.10.7 | 80% Screen Takeover (full specification) | Medium | Not codified |
| 61 | S14 | §14.10 | Portrait-only for Drill Entry Screen | Low | Not codified |
| 62 | S14 | §14.10.8 | Session Duration Tracking (passive for scored drills) | Medium | Not codified |
| 63 | S14 | §14.12 | Session.SessionDuration column missing from TD-02 | Medium | Data model addition not in TD-02 |

---

## Summary

| Category | Count |
|----------|-------|
| Spec items checked | ~230 |
| Fully covered by TD | ~137 |
| Gaps (spec without TD) | 63 |
| Conflicts | 2 (both carried from previous batches) |

**Overall Assessment:**

**S12 (UI/UX)** has the most significant gap: the **Home Dashboard** is completely absent from all TDs. This is the most architecturally significant finding — the entire persistent launch layer, its content, its navigation controls, and its entry points to Live Practice are specified in S12 but not designed in any TD. Beyond Home, the major gap areas are Calendar drag-and-drop mechanics, Comparative Analytics in Review, and the detailed Cross-Shortcut catalogue. Many lower-risk gaps are detailed UX behaviours (filter persistence, scroll behaviour, view exclusions) that are implicitly addressed by the implementation but never explicitly designed.

**S13 (Live Practice)** is well-covered by TD-04 (state machines) and TD-06 Phase 4 (screens). The main gaps are: Save Practice as Routine (entire feature), Create Drill from Session (queue operation), crash recovery UX, deferred Post-Session Summary after auto-end, and the Home Dashboard entry points. The core execution lifecycle is thoroughly designed.

**S14 (Drill Entry Screens)** has excellent coverage for the System Drill Library (28 drills fully specified in TD-02 seed data). The gaps are concentrated in **UI interaction patterns**: Bulk Entry mode (entire feature not in any TD), 80% Screen Takeover rule, Undo Last Instance, Session Duration Tracking (passive), and haptic feedback. These are execution UX details that the TDs don't address at the interaction level.

---

*End of S12-S14 vs TD Gap Analysis (Batch 2E)*
