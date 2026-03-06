# Gap Analysis: S06, S07, S08 vs TD Reference Catalogue

> Batch 2C — Data Model & Persistence (S06), Reflow Governance (S07),
> Practice Planning Layer (S08)
> compared against all 8 Technical Design documents (TD-01 through TD-08).

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

## Conflicts Identified

### Conflict 1: PracticeBlock.ClosureType Values

**S06** defines ClosureType as: `Manual, AutoClosed`.
**TD-04** defines three closure types: `Manual, ScheduledAutoEnd, SessionTimeout`.

Per source-of-truth hierarchy, TD-02 governs entity structure. TD-04 has more granular closure types than S06.

### Conflict 2: Session Columns (UserDeclaration, SessionDuration)

**S06** defines `UserDeclaration` (String nullable) and `SessionDuration` (Integer nullable) on Session.
**TD-02** DDL may not include these columns. This needs verification against the actual TD-02 DDL. Per hierarchy, TD-02 governs.

### Conflict 3: Reflow Timeout (S07 vs TD-04)

**S07 §7.7** specifies 60-second hard timeout for individual user reflow.
**TD-04** RebuildGuard specifies 30-second timeout.
These may apply to different mechanisms (UserScoringLock=60s vs RebuildGuard=30s), but S07 does not distinguish between scoped reflow and full rebuild timeouts.

### Conflict 4: Reflow Retry Count (S07 vs TD-07)

**S07 §7.7** specifies "automatic retry up to 3 attempts."
**TD-07** describes "retry once, then 2-second delay, then fall back to full rebuild on next launch."
The retry strategy and count differ.

### Conflict 5: Structural Edit Queuing (S07 vs TD-04)

**S07 §7.6** states "No queuing of structural edits."
**TD-04** describes deferred reflow coalescing (pending triggers merged by subskill scope union).
The deferred coalescing is an internal optimisation, but the language creates potential ambiguity with S07's prohibition.

---

## Gaps Summary

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S06 | §6.2 | Session.UserDeclaration column | Medium | May be missing from TD-02 DDL |
| 2 | S06 | §6.2 | Session.SessionDuration column | Medium | May be missing from TD-02 DDL |
| 3 | S07 | §7.5.1 | No client-side buffering of rejected data (prohibition) | Low | Implicit in design |
| 4 | S07 | §7.5.1 | No partial save during lock (prohibition) | Low | Implicit |
| 5 | S07 | §7.5.1 | No retry queue for blocked operations (prohibition) | Low | Implicit |
| 6 | S07 | §7.5.1 | Input fields visible but submission disabled during lock | Low | UI detail |
| 7 | S07 | §7.5.1 | Global scoring lock + maintenance banner for system-initiated changes | Medium | No TD addresses server-initiated reflow orchestration |
| 8 | S07 | §7.8 | System-initiated parallel reflow with concurrency cap | Medium | Server-side orchestration not in TDs |
| 9 | S08 | §8.1.1 | SlotCapacity hard block below filled count | Low | Likely implemented but not codified |
| 10 | S08 | §8.1.2 | No draft stage for Routine creation | Low | Not codified |
| 11 | S08 | §8.1.2 | Save as Manual (Clone) feature | Medium | Not in any TD. May be unimplemented |
| 12 | S08 | §8.1.3 | Zero-capacity day handling differs between List/DayPlanning | Low | Nuance not codified |
| 13 | S08 | §8.1.3 | Schedule auto-delete for DayPlanning mode | Low | May not cover all cases |
| 14 | S08 | §8.2.1 | Fixed/RoutineRef entries not rerollable | Low | Likely implemented |
| 15 | S08 | §8.3.1 | Drill order is recommendation, not constraint | Low | Not codified |
| 16 | S08 | §8.3.2 | Technique Block Sessions participate in completion matching | Low | Likely implemented |
| 17 | S08 | §8.3.3 | No automatic correction for overflow drift | Low | Not codified |
| 18 | S08 | §8.3.4 | Session deletion reverts Slot to Incomplete | Low | Likely implemented |
| 19 | S08 | §8.4.1 | Manually completed Slots count for adherence | Low | Not codified |
| 20 | S08 | §8.4.1 | Same-day manual additions included in adherence | Low | Not codified |
| 21 | S08 | §8.4.3 | Rollup: home timezone + week start day | Low | Repeat from S05 |
| 22 | S08 | §8.4.4 | Date range persistence 1 hour | Low | Repeat from S05 |
| 23 | S08 | §8.8.1 | Unresolvable criterion notification | Low | Not codified |
| 24 | S08 | §8.10.4 | Random mode seeded PRNG (user ID + timestamp) | Low | Not codified |
| 25 | S08 | §8.11 | Home timezone auto-detect + manual override | Low | Not codified |
| 26 | S08 | §8.12.1 | Drill creation "Save & Practice" shortcut | Medium | Not in any TD. May be unimplemented |

---

## Summary

| Category | Count |
|----------|-------|
| Spec items checked | ~175 |
| Fully covered by TD | ~143 |
| Gaps (spec without TD) | 26 |
| Conflicts | 5 |

**Overall Assessment:** S06 (Data Model) has excellent TD coverage since TD-02 is its direct implementation counterpart. The two Session columns (UserDeclaration, SessionDuration) are the key verification items. S07 (Reflow Governance) is well-covered by TD-04 and TD-07, but has notable conflicts around timeout values and retry counts that suggest the TD implementation made pragmatic adjustments. The system-initiated reflow scenario (global lock, maintenance banner, parallel execution) is entirely absent from TDs — these are server-side orchestration features deferred beyond V1. S08 (Planning Layer) has very good coverage through TD-06 Phase 5, with gaps primarily in fine-grained UI conventions and the "Save as Manual" clone feature.

---

*End of S06-S08 vs TD Gap Analysis (Batch 2C)*
