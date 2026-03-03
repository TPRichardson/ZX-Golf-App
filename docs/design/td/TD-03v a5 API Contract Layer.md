TD-03 — API Contract Layer

Version TD-03v.a5 — Canonical

Harmonised with: Section 0 (0v.f1), Section 3 (3v.g8), Section 4 (4v.g9), Section 6 (6v.b7), Section 7 (7v.b9), Section 8 (8v.a8), Section 9 (9v.a2), Section 13 (13v.a7), Section 14 (14v.a4), Section 16 (16v.a5), Section 17 (17v.a4), TD-01 (TD-01v.a4), TD-02 (TD-02v.a6).

1. Purpose

This document defines the interface contract between ZX Golf App’s client application and its data layer. It specifies how Flutter code reads, writes, and synchronises data, what operations are available, what their inputs and outputs are, and where each category of business rule is enforced.

ZX Golf App is an offline-first application. The client never communicates directly with Supabase for routine data operations. All reads and writes flow through a local Drift (SQLite) database via a Repository Layer. A separate Sync Transport Layer handles bidirectional synchronisation with the Supabase server when connectivity is available. This two-layer architecture is a direct consequence of the offline-first constraint established in TD-01 (§2).

Deliverable: This specification document. Claude Code consumes it to implement the Dart repository interfaces, Riverpod providers, Supabase RPC functions, and sync engine.

2. Architecture Overview

2.1 Two-Layer Interface Model

The API contract is split into two distinct layers, each with a single responsibility:

  ------------------------ ------------------------------------------------------------------------------------------------------------------------------------ --------------------------------------------------------- ----------------------------------------
  Layer                    Responsibility                                                                                                                       Technology                                                Connectivity

  Local Repository Layer   All data reads and writes. Business logic orchestration. Reflow execution. The sole data access path for UI and business logic.      Drift (SQLite) + Dart abstract interfaces                 None required. Operates fully offline.

  Sync Transport Layer     Bidirectional synchronisation between the local Drift database and the remote Supabase database. Upload, download, merge, rebuild.   Supabase Client SDK + Supabase RPC functions (Postgres)   Required. Executes only when online.
  ------------------------ ------------------------------------------------------------------------------------------------------------------------------------ --------------------------------------------------------- ----------------------------------------

Data flow: UI → Riverpod Provider → Repository (Drift) → Local SQLite. Sync Engine → Supabase RPC → Postgres. The Repository Layer and Sync Transport Layer share the same local Drift database but never run concurrently on the same table. Sync acquires a local transaction lock during merge (TD-01 §2.6).

2.1.1 SyncWriteGate Service

To enforce the invariant that Repository and Sync never write concurrently to the same table, the application implements a SyncWriteGate service. This service coordinates access between the two layers:

Acquisition: Before the sync merge phase begins, the sync engine calls SyncWriteGate.acquireExclusive(). This sets a gate flag and waits for any in-flight Repository write transactions to complete (drain period, max 2 seconds). If the drain period expires with an active write, sync defers to the next trigger.

Hold: While the gate is held, Repository write methods check the gate before opening a Drift transaction. If the gate is held, the Repository method suspends (via a Dart Completer) until the gate is released. Read operations (streams, watches) are never blocked.

Release: After merge, completion matching, and full rebuild complete, the sync engine calls SyncWriteGate.release(). Suspended Repository writes resume.

Timeout: The gate carries a 60-second hard timeout. If sync does not release within this period, the gate auto-releases and sync is marked as failed. This prevents deadlock in crash scenarios.

Scope: The SyncWriteGate is a singleton service injected via Riverpod. It is not persisted; gate state resets on app restart.

2.2 Repository Layer Principles

-   Single source of truth: The local Drift database is the only data source the application reads from. Materialised scoring tables are populated by local reflow, never by network calls.

-   Reactive streams: All read operations return Drift reactive streams (Stream<T>) that automatically emit when underlying data changes. Riverpod providers wrap these streams. UI rebuilds are automatic.

-   Transaction boundaries: All composite operations (e.g. start Session, close PracticeBlock) execute within a single Drift transaction. Either the full operation succeeds or nothing changes.

-   No network awareness: Repository methods never check connectivity, never call Supabase, and never block on network state. The sync engine is an independent subsystem.

-   Type safety: Drift code generation produces strongly typed Dart classes from the schema. Repository methods accept and return these typed entities, not raw maps or JSON.

2.3 Sync Transport Principles

-   Pipeline execution: Sync follows the six-step pipeline defined in TD-01 §2.5: Upload → Download → Merge → Completion Matching → Deterministic Rebuild → Confirm.

-   Atomic stages: Upload is wrapped in a single Supabase RPC transaction. Merge is wrapped in a single Drift transaction. No partial state is committed at any stage (TD-01 §2.6).

-   Trigger model: Sync triggers on: connectivity restored, periodic interval (configurable, default 5 minutes while online), manual user pull-to-refresh, and after significant local mutations (Session close, reflow complete).

-   Non-blocking: Sync never blocks UI read operations. Write operations are gated during the merge phase via SyncWriteGate (§2.1.1). If a conflict arises post-merge, sync retries on next trigger.

3. Local Repository Layer

The Repository Layer is organised into domain-scoped repository classes. Each repository encapsulates all Drift queries for its domain. Riverpod providers expose repository methods to the UI layer. The UI never accesses Drift tables directly.

State machine note: Repository methods that enforce state transitions (e.g. PendingDrill → ActiveSession, Session lifecycle) implement guards defined in TD-04 (Entity State Machines). TD-03 defines the method signatures and data contracts; TD-04 defines the legal state transition rules those methods enforce.

PracticeEntry query safety rule: All scoring queries, window composition queries, and historical Session lookups must reference the Session table directly. They must never join through or filter via PracticeEntry. PracticeEntry is a runtime queue entity that is hard-deleted when a PracticeBlock closes (TD-04 §2.1.4). After cross-device sync, valid Closed Sessions may exist without a corresponding PracticeEntry row. Any query that assumes PracticeEntry existence will silently omit valid scoring data.

3.1 Repository Organisation

  --------------------- ----------------------------------- ---------------------------------------------------------------------------------------------------------------------------
  Repository            Domain                              Entities Managed

  UserRepository        User identity & settings            User

  DrillRepository       Drill definitions & adoption        Drill, UserDrillAdoption, MetricSchema (read-only)

  PracticeRepository    Live Practice execution             PracticeBlock, PracticeEntry, Session, Set, Instance

  ScoringRepository     Scoring engine & reflow             MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore, UserScoringLock

  ClubRepository        Golf bag & club configuration       UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping

  PlanningRepository    Routines, Schedules, Calendar       Routine, RoutineInstance, Schedule, ScheduleInstance, CalendarDay

  EventLogRepository    Audit trail                         EventLog

  ReferenceRepository   System reference data (read-only)   EventTypeRef, MetricSchema, SubskillRef

  SyncRepository        Sync metadata & transport           SyncMetadata (local-only), all entities (for sync read/write)
  --------------------- ----------------------------------- ---------------------------------------------------------------------------------------------------------------------------

Each repository receives the Drift database instance via constructor injection. Riverpod providers are scoped to the authenticated user session. On logout, all providers are disposed and the local database is cleared.

3.2 Entity CRUD Operations

Every entity supports a standard CRUD interface. The table below defines the standard pattern. Entity-specific variations and restrictions are documented in subsequent sections.

3.2.1 Standard CRUD Pattern

  --------------- -------------------------------------------------------- ------------------------------------------------------ ----------------------------------------------------------------------------------------------
  Operation       Signature Pattern                                        Returns                                                Notes

  Create          Future<Entity> create(EntityCompanion data)              Inserted entity with server-default fields populated   Drift companion objects enforce NOT NULL and type constraints at compile time.

  Read (single)   Future<Entity?> getById(String id)                       Entity or null                                         All reads filter IsDeleted = false unless explicitly requested.

  Read (stream)   Stream<List<Entity>> watchAll({filters})                 Reactive stream of matching entities                   Primary read path for UI. Emits on any table change.

  Update          Future<Entity> update(String id, EntityCompanion data)   Updated entity                                         UpdatedAt is never set by client. Server trigger assigns it on sync.

  Soft Delete     Future<void> softDelete(String id)                       void                                                   Sets IsDeleted = true. Row remains for sync propagation.

  Hard Delete     Future<void> hardDelete(String id)                       void                                                   Physical row removal. Used only for discard operations (e.g. Session discard). Never synced.
  --------------- -------------------------------------------------------- ------------------------------------------------------ ----------------------------------------------------------------------------------------------

3.2.2 Soft Delete vs Hard Delete

Two deletion mechanisms exist, serving different purposes:

-   Soft delete (IsDeleted = true): The standard deletion path. The row remains in the local database with IsDeleted = true. On sync upload, the server receives the soft-deleted row. Other devices pull the deletion flag and apply it locally. Soft deletes are permanent and forward-propagating per TD-01 §2.3 merge precedence. Used for: Drill deletion, Session deletion (post-scoring), Routine deletion, Schedule deletion, PracticeBlock deletion.

-   Hard delete (physical row removal): Used exclusively for discard operations where the entity never entered the scoring pipeline and should leave no trace. Hard-deleted rows are not synced. Used for: Session discard (active Session with no scoring), PracticeEntry removal, empty PracticeBlock cleanup.

3.3 Entity-Specific Operations

3.3.1 UserRepository

  ---------------- ------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------
  Method           Signature                                                                                  Description

  getCurrentUser   Stream<User> getCurrentUser()                                                              Watches the authenticated user’s row. Single emission source for all user-dependent providers.

  updateSettings   Future<User> updateSettings({String? timezone, int? weekStartDay, Map? unitPreferences})   Partial update of user-configurable settings. Triggers Calendar view refresh if timezone or weekStartDay changes.

  updateProfile    Future<User> updateProfile({String? displayName})                                          Update display name.
  ---------------- ------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------

3.3.2 DrillRepository

  -------------------- ------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method               Signature                                                                       Description

  watchUserDrills      Stream<List<Drill>> watchUserDrills({SkillArea? filter, DrillStatus? status})   Watches all drills accessible to the user: System Drills (UserID = null) + user’s own custom drills. Excludes IsDeleted = true.

  watchAdoptedDrills   Stream<List<DrillWithAdoption>> watchAdoptedDrills({SkillArea? filter})         Watches drills the user has adopted (Practice Pool). Joins Drill with UserDrillAdoption.

  createCustomDrill    Future<Drill> createCustomDrill(DrillCompanion data)                            Creates a User Custom Drill. Validates: SubskillMapping references valid SubskillRef IDs for the selected SkillArea; MetricSchemaID references a valid schema; if Scored, ScoringMode is set; Anchors structure matches ScoringMode.

  updateDrill          Future<Drill> updateDrill(String drillId, DrillCompanion data)                  Updates a User Custom Drill. System Drills cannot be updated by user. Anchor edits on scored drills trigger reflow (delegated to ScoringRepository).

  retireDrill          Future<void> retireDrill(String drillId)                                        Sets Status = Retired. Drill remains in windows but is excluded from Practice Pool selection. Triggers reflow if sessions exist in windows. Writes EventLog entry.

  deleteDrill          Future<void> deleteDrill(String drillId)                                        Soft deletes drill. Cascades: UserDrillAdoption soft-deleted. Active PracticeEntry references removed. Completed Sessions in windows remain until rolled off. Triggers reflow. Writes EventLog entry.

  adoptDrill           Future<UserDrillAdoption> adoptDrill(String drillId)                            Creates UserDrillAdoption with Status = Active. Idempotent: re-adopting a Retired adoption reactivates it.

  retireAdoption       Future<void> retireAdoption(String drillId)                                     Sets UserDrillAdoption.Status = Retired. Drill removed from Practice Pool but remains in windows.

  getMetricSchema      Future<MetricSchema> getMetricSchema(String schemaId)                           Reads a MetricSchema definition. Used during Session execution to determine input mode and validation bounds.
  -------------------- ------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.3.3 PracticeRepository

PracticeRepository orchestrates the full Live Practice lifecycle defined in Section 13. All composite operations execute within Drift transactions. State transition guards are defined in TD-04.

  ------------------------ ----------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                   Signature                                                                                             Description

  createPracticeBlock      Future<PracticeBlock> createPracticeBlock({String? sourceRoutineId, List<String>? initialDrillIds})   Creates a PracticeBlock and initial PracticeEntries. If initialDrillIds provided, creates PendingDrill entries with sequential PositionIndex. If sourceRoutineId provided, resolves Routine entries (including Generation Criteria) and creates PracticeEntries.

  watchPracticeBlock       Stream<PracticeBlockWithEntries> watchPracticeBlock(String pbId)                                      Watches PracticeBlock with all PracticeEntries, joined to Drill names and Session scores. Primary data source for the queue view.

  getActivePracticeBlock   Stream<PracticeBlock?> getActivePracticeBlock()                                                       Watches for an existing open PracticeBlock (no EndTimestamp, IsDeleted = false). Used on app launch to detect crash recovery scenario (Section 13, §13.14).

  addDrillToQueue          Future<PracticeEntry> addDrillToQueue(String pbId, String drillId, {int? position})                   Creates a PendingDrill PracticeEntry. If position specified, inserts at that index and shifts subsequent entries. Otherwise appends.

  removePendingEntry       Future<void> removePendingEntry(String entryId)                                                       Hard deletes a PendingDrill PracticeEntry. Reindexes remaining entries. No scoring impact.

  removeCompletedEntry     Future<void> removeCompletedEntry(String entryId)                                                     Composite: soft-deletes the Session (cascade to Sets/Instances), triggers reflow, writes EventLog (SessionDeletion), then hard-deletes the PracticeEntry. Blocked while another Session is Active (§13.4.2).

  reorderQueue             Future<void> reorderQueue(String pbId, List<String> orderedEntryIds)                                  Reindexes PositionIndex for all entries in the specified order. ActiveSession entry position is locked.

  duplicateEntry           Future<PracticeEntry> duplicateEntry(String entryId)                                                  Creates a new PendingDrill PracticeEntry with the same DrillID, inserted immediately after the source entry.

  startSession             Future<Session> startSession(String entryId)                                                          Composite: (1) Verify no ActiveSession exists. (2) Create Session entity inheriting Drill properties. (3) Create first Set (SetIndex = 1). (4) Attach SessionID to PracticeEntry. (5) Transition EntryType to ActiveSession. Returns the new Session.

  discardSession           Future<void> discardSession(String entryId)                                                           Composite: (1) Hard-delete all Instances in Session. (2) Hard-delete all Sets. (3) Hard-delete Session. (4) Clear SessionID on PracticeEntry. (5) Reset EntryType to PendingDrill. No scoring. No EventLog.

  restartSession           Future<void> restartSession(String entryId)                                                           Alias for discardSession. The PracticeEntry remains in queue at its current position, ready for startSession again.

  logInstance              Future<Instance> logInstance(String setId, InstanceCompanion data)                                    Creates an Instance in the specified Set. Validates RawMetrics against the Drill’s MetricSchema (see §9.3.1 for parse failure handling). Evaluates integrity bounds (Section 11). For structured drills: if Instance count reaches RequiredAttemptsPerSet, signals Set complete.

  advanceSet               Future<Set> advanceSet(String sessionId)                                                              Creates the next Set (SetIndex = previous + 1). Only valid for structured drills when current Set is complete and more Sets remain.

  endSession               Future<Session> endSession(String sessionId)                                                          Manual end for unstructured drills. Sets CompletionTimestamp = now, Status = Closed. Triggers scoring pipeline and completion matching.

  endPracticeBlock         Future<PracticeBlockSummary> endPracticeBlock(String pbId)                                            Composite: (1) Verify no ActiveSession. (2) Hard-delete all PendingDrill entries. (3) If zero Sessions exist, hard-delete PracticeBlock and return empty summary. (4) Set EndTimestamp and ClosureType = Manual. (5) Return summary data for Post-Session Summary screen.

  saveQueueAsRoutine       Future<Routine> saveQueueAsRoutine(String pbId, String routineName)                                   Creates a Routine from current PracticeEntry queue. Each entry’s DrillID becomes a fixed Routine entry. Preserves queue order.

  updateInstance           Future<Instance> updateInstance(String instanceId, InstanceCompanion data)                            Edits an existing Instance’s RawMetrics or SelectedClub. Re-evaluates integrity bounds. If Instance belongs to a Closed Session, triggers reflow for affected subskills.

  deleteInstance           Future<void> deleteInstance(String instanceId)                                                        Soft-deletes an Instance. If Instance belongs to a Closed Session, triggers reflow. Writes EventLog.
  ------------------------ ----------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.3.4 ScoringRepository

ScoringRepository implements the pure rebuild scoring engine defined in Section 1 and Section 7. It reads raw Instance data and writes to materialised tables. It is the sole writer to materialised tables.

  ---------------------- ------------------------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                 Signature                                                                                                    Description

  watchOverallScore      Stream<MaterialisedOverallScore?> watchOverallScore()                                                        Watches the user’s overall SkillScore. Primary data source for Dashboard.

  watchSkillAreaScores   Stream<List<MaterialisedSkillAreaScore>> watchSkillAreaScores()                                              Watches all 7 Skill Area scores.

  watchSubskillScores    Stream<List<MaterialisedSubskillScore>> watchSubskillScores({SkillArea? filter})                             Watches subskill scores, optionally filtered by Skill Area.

  watchWindowState       Stream<MaterialisedWindowState?> watchWindowState(String subskillId, DrillType practiceType)                 Watches a single window’s state (entries, occupancy, average).

  executeReflow          Future<void> executeReflow(ReflowTrigger trigger)                                                            Core reflow operation. Acquires UserScoringLock. Determines affected subskills from trigger. Rebuilds: Instance scores → Session scores → Window composition → Subskill scores → Skill Area scores → Overall score. Atomic write to materialised tables. Releases lock. Writes EventLog (ReflowComplete). See §4 for full reflow specification.

  executeFullRebuild     Future<void> executeFullRebuild()                                                                            Rebuilds all materialised state from scratch. Used after sync merge (TD-01 §2.5 Step 5) and on data recovery. Acquires RebuildGuard (§4.5) to prevent overlap with concurrent reflow. Truncates and repopulates all materialised tables atomically.

  acquireScoringLock     Future<bool> acquireScoringLock()                                                                            Sets UserScoringLock.IsLocked = true with expiry. Returns false if already locked. Used by reflow and by UI to block Instance logging during reflow.

  releaseScoringLock     Future<void> releaseScoringLock()                                                                            Clears the lock. Called after reflow completes or on timeout.

  isScoringLocked        Stream<bool> isScoringLocked()                                                                               Watches lock state. UI observes this to show blocking indicator during reflow.

  scoreInstance          double scoreInstance(Map<String, dynamic> rawMetrics, Map<String, dynamic> anchors, String metricSchemaId)   Pure function. Given raw metrics and anchors, returns 0–5 score using the scoring adapter bound to the MetricSchema. Two-segment linear interpolation: Min→Scratch (0–3.5), Scratch→Pro (3.5–5). Capped at 5. This is not a repository method but a pure scoring utility exposed alongside the repository.

  scoreSession           double scoreSession(List<double> instanceScores)                                                             Pure function. Simple average of all Instance 0–5 scores across all Sets.
  ---------------------- ------------------------------------------------------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.3.5 ClubRepository

  ------------------------ -------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------
  Method                   Signature                                                                                    Description

  watchUserBag             Stream<List<UserClub>> watchUserBag({UserClubStatus? status})                                Watches all clubs in the user’s bag. Default: Active clubs only.

  addClub                  Future<UserClub> addClub(UserClubCompanion data)                                             Adds a club to the bag. Validates ClubType is valid. Creates default UserSkillAreaClubMapping entries per Section 9 mandatory mapping rules.

  updateClub               Future<UserClub> updateClub(String clubId, UserClubCompanion data)                           Updates club details (Make, Model, Loft). Does not affect scoring.

  retireClub               Future<void> retireClub(String clubId)                                                       Sets Status = Retired. Club remains on historical Instances but excluded from future selection.

  addPerformanceProfile    Future<ClubPerformanceProfile> addPerformanceProfile(String clubId, ProfileCompanion data)   Insert-only. Creates a new time-versioned performance profile. The most recent profile (by EffectiveFromDate) is the active profile.

  getActiveProfile         Future<ClubPerformanceProfile?> getActiveProfile(String clubId)                              Returns the most recent profile for a club (highest EffectiveFromDate ≤ today).

  watchClubsForSkillArea   Stream<List<UserClub>> watchClubsForSkillArea(SkillArea skillArea)                           Watches clubs mapped to a Skill Area via UserSkillAreaClubMapping. Used by club selector during Session execution.

  updateSkillAreaMapping   Future<void> updateSkillAreaMapping(String clubType, SkillArea skillArea, bool mapped)       Creates or deletes a UserSkillAreaClubMapping entry. Mandatory mappings (Section 9) cannot be removed.
  ------------------------ -------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------

3.3.6 PlanningRepository

  --------------------------- ---------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                      Signature                                                                                      Description

  watchRoutines               Stream<List<Routine>> watchRoutines({RoutineStatus? status})                                   Watches user’s Routines. Default: Active.

  createRoutine               Future<Routine> createRoutine(String name, List<RoutineEntry> entries)                         Creates a Routine with ordered entries. Each entry is either a fixed DrillID or a Generation Criterion.

  updateRoutine               Future<Routine> updateRoutine(String routineId, {String? name, List<RoutineEntry>? entries})   Updates Routine name or entry list. No scoring impact.

  deleteRoutine               Future<void> deleteRoutine(String routineId)                                                   Soft deletes. Cascading: RoutineInstance references set to null. Empty Routines auto-deleted (Section 3, §3.1.2).

  watchSchedules              Stream<List<Schedule>> watchSchedules({ScheduleStatus? status})                                Watches user’s Schedules.

  createSchedule              Future<Schedule> createSchedule(ScheduleCompanion data)                                        Creates a Schedule (List or DayPlanning mode).

  applySchedule               Future<List<CalendarDay>> applySchedule(String scheduleId, Date startDate, Date endDate)       Instantiates a Schedule across a date range. Creates/updates CalendarDay rows with Slot assignments. Creates ScheduleInstance tracking record.

  watchCalendarDays           Stream<List<CalendarDay>> watchCalendarDays(Date start, Date end)                              Watches CalendarDay rows in a date range. Primary source for Calendar view.

  updateCalendarDay           Future<CalendarDay> updateCalendarDay(String dayId, {int? slotCapacity, List<Slot>? slots})    Updates SlotCapacity or individual Slot assignments on a CalendarDay.

  executeCompletionMatching   Future<void> executeCompletionMatching(String sessionId)                                       Runs completion matching for a closed Session against today’s CalendarDay. Date-strict in user timezone. DrillID matching. First-match ordering. Overflow handling per Section 8 §8.3.3.
  --------------------------- ---------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.3.7 EventLogRepository

  -------------------- ---------------------------------------------------------------------------- ------------------------------------------------------------------------
  Method               Signature                                                                    Description

  writeEvent           Future<EventLog> writeEvent(EventLogCompanion data)                          Appends an EventLog entry. Insert-only. No update or delete.

  watchRecentEvents    Stream<List<EventLog>> watchRecentEvents({int limit, String? eventTypeId})   Watches recent events, optionally filtered by type.

  getEventsForEntity   Future<List<EventLog>> getEventsForEntity(String entityId)                   Returns all events referencing a specific entity in AffectedEntityIDs.
  -------------------- ---------------------------------------------------------------------------- ------------------------------------------------------------------------

4. Reflow Process Contract

This section consolidates the reflow process into a precise algorithmic contract that ScoringRepository.executeReflow implements. The reflow process is defined across Sections 1 and 7 of the product specification. This section does not add new rules; it consolidates them into an implementable sequence.

4.1 Reflow Trigger Catalogue

The following operations trigger reflow. Each trigger specifies the affected scope:

  ---------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------
  Trigger Operation                        Affected Scope                                                                                                                                        Spec Reference

  Anchor edit (Drill)                      All subskills mapped by the edited Drill                                                                                                              Section 7, §7.2

  Session deletion                         All subskills mapped by the Session’s Drill                                                                                                           Section 7, §7.2

  Instance edit (on Closed Session)        All subskills mapped by the Session’s Drill                                                                                                           Section 7, §7.2

  Instance deletion (on Closed Session)    All subskills mapped by the Session’s Drill                                                                                                           Section 7, §7.2

  Drill deletion (with window entries)     All subskills mapped by the deleted Drill                                                                                                             Section 7, §7.2

  Drill retirement (with window entries)   All subskills mapped by the retired Drill                                                                                                             Section 7, §7.2

  Subskill allocation change               All subskills in the affected Skill Area                                                                                                              Section 7, §7.2

  Sync merge completion                    All subskills (full rebuild)                                                                                                                          TD-01, §2.5 Step 5

  Session close (normal)                   Subskills mapped by the closed Session’s Drill. This is technically a window insertion, not a reflow trigger, but it follows the same rebuild path.   Section 1, Section 3 §3.4
  ---------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------

4.2 Reflow Algorithm

The following numbered steps execute in order within a single Drift transaction:

Step 1 — Acquire Lock. Set UserScoringLock.IsLocked = true, LockedAt = now, LockExpiresAt = now + 30 seconds. If already locked and not expired, wait and retry (max 3 attempts, 500ms interval). If locked and expired, force-acquire (previous reflow assumed failed). Instance logging is blocked while the lock is held (Section 7, §7.5).

Step 2 — Determine Affected Subskills. From the trigger, identify which SubskillIDs are affected. For a single-mapped Drill edit: 1 subskill. For a dual-mapped Drill edit: 2 subskills. For an allocation change: all subskills in the Skill Area. For sync full rebuild: all 19 subskills.

Step 3 — Rebuild Instance Scores. For each affected subskill, query all Closed Sessions (Status = ‘Closed’, IsDeleted = false) whose Drill maps to that subskill. For each Session, re-score all Instances from raw metrics using current anchors. This step is necessary because anchor edits change the 0–5 mapping. Instance scores are not persisted; they are computed in-memory during reflow.

Step 4 — Rebuild Session Scores. For each Session identified in Step 3, compute the Session score as the simple average of all Instance 0–5 scores across all Sets.

Step 5 — Rebuild Window Composition. For each affected subskill and each DrillType (Transition, Pressure): query Sessions ordered by CompletionTimestamp DESC, SessionID DESC. The secondary sort on SessionID guarantees deterministic window membership when two Sessions share an identical CompletionTimestamp (possible during offline multi-device use). Walk forward, summing occupancy units (1.0 for single-mapped, 0.5 for dual-mapped). Inclusion rules: (a) If adding the entry’s full occupancy keeps cumulative occupancy ≤ 25.0, include it at full occupancy. (b) If the entry’s full occupancy would cause cumulative occupancy to exceed 25.0 but a partial reduction (0.5 decrement) would fit, include the entry at reduced occupancy (e.g. a 1.0-occupancy entry is reduced to 0.5; its score is preserved at the original value). (c) If even the reduced occupancy would exceed 25.0, exclude the entry. This partial roll-off mechanism ensures the window fills to its maximum capacity without discarding entries prematurely. A single-mapped entry occupying 1.0 may be reduced to 0.5, not removed entirely, if only 0.5 capacity remains. Score is never adjusted — only occupancy is reduced. The partial entry’s score continues to contribute to WeightedSum at its reduced occupancy weight. Write to MaterialisedWindowState: Entries (JSON array of {SessionID, Score, Occupancy, CompletionTimestamp}), TotalOccupancy, WeightedSum (sum of score × occupancy), WindowAverage (WeightedSum / TotalOccupancy).

Step 6 — Rebuild Subskill Scores. For each affected subskill: read TransitionAverage and PressureAverage from the two window rows. Compute WeightedAverage = (TransitionAverage × 0.35) + (PressureAverage × 0.65). Look up Allocation from SubskillRef. Compute SubskillPoints = Allocation × (WeightedAverage / 5). Write to MaterialisedSubskillScore.

Step 7 — Rebuild Skill Area Scores. For each Skill Area containing an affected subskill: sum SubskillPoints across all subskills in that Skill Area. Write SkillAreaScore to MaterialisedSkillAreaScore.

Step 8 — Rebuild Overall Score. Sum all 7 SkillAreaScores. Write OverallScore to MaterialisedOverallScore.

Step 9 — Side Effects. Reset IntegritySuppressed = false on any Sessions whose scores were recalculated (Section 11). Write EventLog entry: EventType = ReflowComplete, AffectedSubskills = list of SubskillIDs processed, Metadata = {trigger type, duration_ms}.

Step 10 — Release Lock. Set UserScoringLock.IsLocked = false. Clear LockedAt and LockExpiresAt.

4.3 Reflow Idempotency

Reflow must be safely re-runnable. If the app crashes mid-reflow (between Steps 1 and 10), the lock expires after 30 seconds. On next app launch, the system detects an expired lock and initiates a full rebuild. Because reflow is a pure function of raw data, re-running it produces identical results. No manual intervention is required.

4.4 Scoring Pipeline (Session Close)

When a Session closes (structured completion, manual end, or auto-close), the following pipeline executes. This is the non-reflow scoring path, triggered once per Session close:

-   Score all Instances: raw metrics → 0–5 score via scoring adapter.

-   Evaluate integrity bounds (Section 11): flag Session if any Instance breaches HardMinInput/HardMaxInput.

-   Compute Session score: simple average of all Instance scores.

-   Insert Session into window(s): compose window per Step 5 of reflow, writing new entry.

-   Recompute subskill, Skill Area, and Overall scores per Steps 6–8.

-   Execute completion matching (Section 8 §8.3.2).

-   Write EventLog: SessionCompletion.

The Session close scoring pipeline does not acquire the UserScoringLock. It runs outside the lock because it does not mutate historical window state — it appends a new entry to the window and recomputes the affected subskill chain incrementally. No existing Session scores are recalculated. This distinction is architecturally important: wrapping Session close scoring inside the ScoringLock would unnecessarily block Instance logging on the next drill while the current Session’s scores are computed. Code must not add ScoringLock acquisition to the Session close path.

4.5 RebuildGuard (Full Rebuild Coordination)

The full rebuild triggered after sync merge (§5.5 Step 5) does not acquire the standard UserScoringLock to avoid blocking user-initiated reflow. However, concurrent execution of a full rebuild and a standard reflow against the same materialised tables creates a race condition. The RebuildGuard prevents this:

Mechanism: executeFullRebuild acquires a RebuildGuard flag (in-memory, not persisted) before truncating materialised tables. While the guard is held, executeReflow checks the guard before acquiring UserScoringLock. If the guard is held, reflow defers and re-queues itself for execution after rebuild completes. Deferred reflows are coalesced by subskill scope before execution: all pending triggers are merged into a single combined scope representing the union of all affected SubskillIDs. This combined scope executes as one scoped reflow (one lock acquisition, one transaction, one EventLog entry) immediately upon guard release. The coalesced EventLog entry records all original trigger types in its Metadata field. Coalescing eliminates redundant computation without altering deterministic behaviour, since reflow is a pure rebuild from raw data.

Atomicity: The full rebuild executes the truncate and repopulate within a single Drift transaction. If the transaction fails, no partial state is committed. The RebuildGuard is released on both success and failure.

Storage pressure: The truncate-and-repopulate approach temporarily doubles materialised table storage during the transaction (old rows marked for deletion, new rows inserted, then old rows vacuumed). For worst-case scenarios (19 subskills × 2 drill types × 25-entry windows), the maximum transient overhead is approximately 50KB. SQLite’s WAL journal handles this within normal operating bounds. If the rebuild transaction fails due to storage exhaustion, the entire transaction rolls back (no partial commit). The system raises SYSTEM_STORAGE_FULL, writes an EventLog entry (EventType = RebuildStorageFailure), and leaves materialised tables in their pre-rebuild state. The RebuildGuard is released on failure. The application’s storage monitoring (Section 16 §16.7) alerts the user independently. A subsequent sync or manual retry will re-attempt the rebuild once storage is available.

Timeout: If the RebuildGuard is held for more than 30 seconds (matching the UserScoringLock expiry), it auto-releases and logs an error. Deferred reflows resume and will operate on whatever state exists.

5. Sync Transport Layer

The Sync Transport Layer implements the six-step sync pipeline defined in TD-01 §2.5. This section defines the Supabase RPC function contracts and the client-side sync engine interface.

5.1 Sync Engine Interface

  ---------------------- ------------------------------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                 Signature                                              Description

  triggerSync            Future<SyncResult> triggerSync({SyncTrigger reason})   Executes the full six-step pipeline. Returns success/failure with diagnostics. Non-blocking: runs in background isolate. Acquires SyncWriteGate (§2.1.1) during merge phase.

  getSyncStatus          Stream<SyncStatus> getSyncStatus()                     Watches sync state: Idle, InProgress, Failed(reason), Offline.

  getLastSyncTimestamp   Future<DateTime?> getLastSyncTimestamp()               Returns the last successful sync timestamp from SyncMetadata.

  forceFullSync          Future<SyncResult> forceFullSync()                     Forces a complete re-download and full rebuild. Used for recovery scenarios.
  ---------------------- ------------------------------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

5.2 Upload RPC Function

Function name: sync_upload

Execution context: Supabase Edge Function or Postgres RPC function, executed within a single Postgres transaction.

5.2.1 Request Payload

The client sends a single JSON payload containing all locally modified entities since the last successful sync. The payload is structured by table name:

{ "schema_version": "1", "device_id": "uuid",

"changes": { "PracticeBlock": [...], "Session": [...],

"Set": [...], "Instance": [...], "Drill": [...],

"UserDrillAdoption": [...], "UserClub": [...],

"ClubPerformanceProfile": [...], "UserSkillAreaClubMapping": [...],

"Routine": [...], "Schedule": [...], "CalendarDay": [...],

"RoutineInstance": [...], "ScheduleInstance": [...],

"EventLog": [...], "UserDevice": [...], "User": [...] } }

Each entity in the changes array is the full row payload (all columns). The server applies UPSERT logic: INSERT ON CONFLICT (PK) DO UPDATE. The server-side UpdatedAt trigger overwrites any client-provided value.

5.2.2 Payload Batching

To avoid exceeding practical payload limits, the client enforces the following thresholds:

Maximum payload size: 2MB per upload request. If the serialised JSON exceeds 2MB, the client partitions changes into multiple sequential upload requests, each within the size limit. Partitioning splits by table (never mid-table) to preserve referential integrity within each batch.

Batch ordering: When multiple batches are required, parent entities are uploaded before children (e.g. PracticeBlock before Session before Set before Instance). Each batch is a separate Postgres transaction. If a later batch fails, earlier batches remain committed; the client records partial upload state in SyncMetadata and retries the remaining batches on next sync. Partial upload state is not persisted to disk beyond SyncMetadata; if the app crashes mid-upload, the entire upload set is re-sent on next sync. This is safe because upload is idempotent (§5.2.3): re-sending already-committed batches produces no side effects beyond a new server-side UpdatedAt timestamp.

Row count advisory: Under normal usage patterns (daily practice, < 50 Sessions between syncs), a single batch is expected. The batching mechanism is a safety net for extended offline periods or bulk data scenarios.

5.2.3 Upload Idempotency

The upload operation is idempotent. Re-sending the same payload (e.g. after a network timeout where the client cannot confirm receipt) produces the same server state:

-   UPSERT (INSERT ON CONFLICT DO UPDATE) is inherently idempotent at the row level.

-   Server-side UpdatedAt triggers assign a new timestamp on each write, but repeated writes with identical data produce functionally equivalent state.

-   The client may safely retry a failed or unconfirmed upload without risk of data corruption or duplication.

-   The client tracks upload confirmation via the server’s success response. If no confirmation is received, the same payload is included in the next sync cycle.

5.2.4 Server-Side Processing

-   Validate schema_version matches current server schema. If mismatch, reject with error code SCHEMA_VERSION_MISMATCH.

-   Authenticate via JWT. Extract auth.uid(). All rows must belong to the authenticated user (enforced by RLS).

-   Within a single transaction: UPSERT each entity. RLS policies validate ownership. UpdatedAt triggers fire on each write. Structural immutability guard: for Drill entities, the UPSERT must verify that the following fields have not changed from the existing row (if one exists): SubskillMapping, MetricSchemaID, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ScoringMode, InputMode. If any structural field differs between the incoming payload and the existing row, the row is rejected (not upserted) and included in rejected_rows. This prevents a corrupted client payload, a bug, or a future code regression from silently overwriting drill structural identity through sync, which would invalidate all historical scoring data.

-   Return: { success: true, server_timestamp: <UTC>, rejected_rows: [] }

-   If any row fails RLS or constraint validation, the entire transaction rolls back. Return: { success: false, error: <detail> }

5.2.5 DTO Serialisation Layer

A dedicated DTO (Data Transfer Object) layer mediates between Drift entity types and Supabase RPC JSON payloads:

Upload: Each Drift entity is converted to a Map<String, dynamic> via a toSyncDto() extension method. This method handles: DateTime → ISO 8601 string conversion, enum → string mapping, JSONB fields (Anchors, SubskillMapping, RawMetrics, Slots, Entries) → pre-serialised JSON strings, and null-safety for optional fields.

Download: Incoming JSON maps are converted to Drift companion objects via fromSyncDto() factory methods. These methods handle: ISO 8601 string → DateTime parsing, string → enum mapping with fallback to unknown/default, JSON string → parsed Map/List for JSONB fields, and type validation (reject rows with missing required fields, log warning, continue).

Location: DTO conversion methods are defined in a sync_dto.dart file, separate from the Repository and entity definitions. This isolates serialisation concerns from business logic.

5.3 Download RPC Function

Function name: sync_download

5.3.1 Request Payload

{ "schema_version": "1",

"last_sync_timestamp": "2025-01-15T10:30:00Z",

"device_id": "uuid" }

5.3.2 Server-Side Processing

-   Validate schema_version. Reject if mismatch.

-   Query each synced table for rows with UpdatedAt > last_sync_timestamp. RLS automatically scopes to the authenticated user. EventLog exception: EventLog is append-only with no UpdatedAt column (TD-02 §3.5). Query EventLog using CreatedAt > last_sync_timestamp instead. The sync download RPC must implement this as a separate query path for EventLog.

-   Include soft-deleted rows (IsDeleted = true). The client needs these to propagate deletions.

-   Use REPEATABLE READ isolation to ensure a consistent snapshot across all table queries.

-   Return: { success: true, server_timestamp: <UTC>, changes: { <table_name>: [...rows], ... } }

5.3.3 Download Query Performance

Efficient download queries depend on the following index assumptions, which must be present on the Supabase (Postgres) schema:

Required indexes: Each synced table must have a composite index on (UserID, UpdatedAt). This index supports the primary download query pattern: WHERE UserID = auth.uid() AND UpdatedAt > last_sync_timestamp. RLS policies internally filter by UserID, but the composite index ensures the timestamp range scan is efficient. Child tables without a UserID column (Session, Set, Instance, ClubPerformanceProfile) use a different download query strategy: the sync download RPC joins the child to its parent table (e.g. Session JOIN PracticeBlock) to scope by UserID, then filters by the child’s UpdatedAt. The DDL includes UpdatedAt-only indexes on these child tables to support the timestamp range scan in JOIN-based queries.

EventLog: Requires a composite index on (UserID, CreatedAt) since EventLog uses CreatedAt rather than UpdatedAt for sync download queries.

Expected performance: For a typical sync window (5 minutes, < 100 changed rows across all tables), the download query should complete in < 500ms. For a first-sync or force-full-sync scenario (all user data), the query may take 2–5 seconds depending on data volume. The client displays sync progress to the user during extended downloads.

TD-02 alignment: These indexes should be declared in TD-02 (DDL). If not already present, they must be added before Phase 7 implementation.

Mandatory index requirement: The composite (UserID, UpdatedAt) indexes on all synced tables and (UserID, CreatedAt) on EventLog are mandatory, not conditional. These indexes are a prerequisite for sync correctness and performance. TD-02 must declare them explicitly. Phase 7 implementation must not proceed without confirming their presence in the deployed schema.

5.4 Client-Side Merge Algorithm

Merge executes locally within a single Drift transaction after download completes. The merge logic implements TD-01 §2.3 merge precedence:

5.4.1 General Merge Rules

-   New rows (no local match): Insert directly.

-   Existing rows (local match by PK): Compare UpdatedAt. If remote UpdatedAt > local UpdatedAt, overwrite local with remote. If local UpdatedAt ≥ remote UpdatedAt, keep local (local wins tie).

-   Delete precedence: If either local or remote has IsDeleted = true, the merged result is IsDeleted = true, regardless of UpdatedAt comparison. Delete always wins (TD-01 §2.3).

-   Execution data (additive): PracticeBlock, Session, Set, Instance, EventLog: new rows from remote are always inserted. These entities are append-only in practice. Conflicts on these entities resolve via UpdatedAt for metadata fields. EventLog special case: EventLog has no UpdatedAt column (append-only, TD-02 §3.5). Merge for EventLog is insert-if-not-exists by PK only. No LWW comparison is performed because no mutable fields exist.

5.4.2 Tie-Break Rationale and Timestamp Precision

Local-wins-tie rule: When local UpdatedAt = remote UpdatedAt exactly, the local version is retained. This is a deliberate choice: the user’s most recent device interaction is preserved, avoiding a disorienting experience where a sync appears to silently revert local changes. In practice, exact ties are extremely rare because server-side UpdatedAt is assigned by Postgres triggers at microsecond precision (timestamp with time zone, 6 fractional digits). Two independent writes would need to resolve to the same microsecond to produce a tie.

Timestamp precision: Server-side UpdatedAt is Postgres TIMESTAMPTZ with microsecond precision. Client-side DateTime (Dart) also supports microsecond precision. The merge comparator uses the full precision value. No truncation to seconds or milliseconds occurs.

5.4.3 CalendarDay Slot-Level Merge

CalendarDay is the sole exception to row-level merge (TD-01 §2.4). When both local and remote have modifications to the same CalendarDay:

-   SlotCapacity: standard LWW (later UpdatedAt wins).

-   Slots (JSON array): compare each Slot position independently. For each position, the value with the later timestamp wins. Each Slot in the JSON array carries a SlotUpdatedAt field for this purpose.

The merge algorithm iterates Slot positions 0..N (where N = max(local.SlotCapacity, remote.SlotCapacity)). For each position, if only one side has a value, that value is used. If both sides have a value, the one with the later SlotUpdatedAt wins.

5.4.4 SlotUpdatedAt Trust Model

SlotUpdatedAt is a client-written timestamp embedded within the Slots JSON blob. Unlike the row-level UpdatedAt column (which is overwritten by a server-side Postgres trigger), SlotUpdatedAt is not subject to server reassignment because it resides inside a JSONB field.

Risk: A client with a misconfigured clock or a tampered payload could write a future SlotUpdatedAt, causing its slot value to always win in merge conflicts.

V1 mitigation: The server-side sync_upload function validates that no SlotUpdatedAt value within the Slots JSON exceeds the server’s current timestamp (NOW() + 60 seconds tolerance for clock skew). Slots with a SlotUpdatedAt beyond this threshold are rejected, and the upload returns a VALIDATION_SLOT_TIMESTAMP_FUTURE error for the affected CalendarDay row. The client must re-submit with corrected timestamps.

V2 consideration: A future enhancement could have the server normalise SlotUpdatedAt values by replacing them with the server’s transaction timestamp during upload, similar to the row-level UpdatedAt trigger. This is deferred to V2 as it adds complexity to the JSONB processing in the RPC function.

5.5 Post-Merge Pipeline

After merge completes (within the same transaction or immediately after):

-   Step 4 — Completion Matching: Re-run Calendar completion matching against all newly merged Closed Sessions. Date-strict, DrillID matching, first-match ordering. Skip-if-matched guard: Sessions that already have a linked CalendarDay Slot (CompletionState = CompletedLinked) are skipped. This ensures local-close matching is authoritative and sync only matches newly-arrived remote Sessions that have not yet been matched on any device.

-   Step 5 — Deterministic Rebuild: Execute ScoringRepository.executeFullRebuild(). All materialised tables are truncated and rebuilt from raw Instance data. Acquires RebuildGuard (§4.5). Guarantees convergence across devices.

-   Step 6 — Confirm: Update SyncMetadata.lastSyncTimestamp = server_timestamp from the download response.

SyncWriteGate timeout validation: The SyncWriteGate 60-second hard timeout (§2.1.1) must be validated end-to-end in Phase 7B. The post-merge pipeline (Steps 4–6) executes while the gate is held. If any step takes longer than expected (e.g. a large full rebuild after a long offline period), the gate may timeout before Step 6 completes. The implementation must ensure that: (a) the SyncWriteGate timeout triggers a clean abort of the entire post-merge pipeline; (b) the abort rolls back the Drift transaction, preserving pre-merge state; (c) an EventLog entry with EventType = SyncGateTimeout is written; and (d) the next sync attempt re-executes the full pipeline from Step 4. See TD-06 Phase 7B acceptance criteria for the required timeout validation tests.

6. Domain Boundaries

To prevent business logic leaking across layers, each category of validation and business rule is enforced at exactly one layer. Claude Code must place logic at the designated layer and nowhere else.

  --------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Layer                             Enforces                                                                                                                                                                                                    Examples

  Database (Drift + Postgres)       Referential integrity. NOT NULL constraints. CHECK constraints. UNIQUE constraints. CASCADE deletes. ENUM type validation.                                                                                  FK from Session.DrillID to Drill.DrillID. CHECK(SetIndex >= 1). UNIQUE(UserID, Date) on CalendarDay. CASCADE from PracticeBlock to Session.

  Repository (Business Logic)       Scoring calculations. Window composition. Reflow orchestration. State machine guards (defined in TD-04). Integrity flag evaluation. Merge precedence. Completion matching. Composite operation atomicity.   Single active Session guard. Reflow lock acquisition. 0–5 scoring from anchors. Window 25-unit occupancy limit. Delete-always-wins merge rule. CalendarDay Slot-level merge.

  Sync Transport                    Authentication (JWT validation). Authorisation (RLS enforcement). Schema version gating. Upload atomicity. Download consistency (REPEATABLE READ). Rate limiting. SlotUpdatedAt validation (§5.4.4).        auth.uid() extraction. schema_version comparison. Single-transaction UPSERT. SlotUpdatedAt future-timestamp rejection.

  UI (Flutter Widgets + Riverpod)   Input formatting and display. Field-level validation feedback. Optimistic UI updates. Loading/error states. Navigation guards (e.g. block nav during Active Session).                                       Numeric input formatting for Continuous Measurement. Showing integrity warning icon. Blocking End Practice when Session is Active. Displaying reflow lock indicator.
  --------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

6.1 Critical Boundary Rules

-   Scoring logic never runs in UI code. The UI reads materialised scores from ScoringRepository streams. It never computes scores inline.

-   State machine guards never run at the database layer. CHECK constraints enforce value ranges (e.g. SetIndex >= 1) but do not enforce state transitions (e.g. PendingDrill → ActiveSession). State machines are Repository-layer logic, defined in TD-04.

-   The UI never writes to Drift directly. All mutations flow through Repository methods, which enforce business rules before writing.

-   The sync engine never triggers business logic. After merge, it calls executeFullRebuild() and executeCompletionMatching() as discrete steps. It does not re-run state machine guards or re-validate business rules on merged data.

-   RLS is the last line of defence, not the first. The application layer scopes all queries by UserID. RLS catches bugs where the application layer fails to scope correctly. It is not a substitute for correct query construction.

7. Error Response Contract

All Repository methods and Sync Transport functions use a consistent error model. Errors are categorised by origin and severity.

7.1 Error Categories

  ------------------ -------------- ----------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------
  Category           Code Range     Examples                                                                                                                Client Behaviour

  Validation Error   VALIDATION_*   VALIDATION_MISSING_FIELD, VALIDATION_INVALID_ANCHOR, VALIDATION_DRILL_TYPE_MISMATCH, VALIDATION_SLOT_TIMESTAMP_FUTURE   Display field-level feedback. Do not retry.

  State Error        STATE_*        STATE_SESSION_ALREADY_ACTIVE, STATE_PRACTICE_BLOCK_CLOSED, STATE_REFLOW_LOCKED                                          Display contextual message. Retry may succeed after state change.

  Constraint Error   CONSTRAINT_*   CONSTRAINT_FK_VIOLATION, CONSTRAINT_UNIQUE_VIOLATION                                                                    Log error. Display generic message. Indicates a bug.

  Sync Error         SYNC_*         SYNC_SCHEMA_MISMATCH, SYNC_UPLOAD_FAILED, SYNC_NETWORK_ERROR, SYNC_TRANSACTION_FAILED, SYNC_PAYLOAD_TOO_LARGE           Display sync-specific messaging. Auto-retry for transient errors. Prompt app update for schema mismatch.

  System Error       SYSTEM_*       SYSTEM_DATABASE_CORRUPTION, SYSTEM_LOCK_TIMEOUT, SYSTEM_STORAGE_FULL, SYSTEM_REBUILD_TIMEOUT                            Display system-level alert. May require manual intervention.
  ------------------ -------------- ----------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------

7.2 Error Shape

All errors are represented as Dart exceptions extending a common base class:

class ZxGolfAppException {

final String code;

final String message;

final Map<String, dynamic>? context;

}

Repository methods throw ZxGolfAppException subclasses. Riverpod providers catch these and expose them as AsyncError states. The UI layer reads error codes to display appropriate messaging without parsing error message strings.

8. Authentication & Authorisation

8.1 Authentication Flow

-   Provider: Google Sign-In via Supabase Auth.

-   Token storage: Supabase client SDK manages JWT storage in secure device storage.

-   Offline behaviour: Local operations do not require a valid JWT. Authentication is only required for sync. Token refresh follows TD-01 §3.3.

-   User creation: On first sign-in, the Supabase Auth trigger creates a User row. The client pulls this row on first sync. Initial account creation is the only operation requiring connectivity.

8.2 Authorisation Model

-   Local: Single-user database. All data belongs to the authenticated user. No local authorisation checks needed beyond the Riverpod provider lifecycle (providers are disposed on logout).

-   Remote: RLS policies on all Supabase tables enforce per-user isolation. The client SDK attaches the JWT to all requests. auth.uid() is extracted server-side. No client-side authorisation headers are manually managed.

9. Key Payload Shapes

The following payload shapes define the structure of complex JSON fields and composite return types. Simple entity fields are fully defined by the TD-02 DDL schema.

9.1 Drill.Anchors (JSONB)

Anchor structure depends on ScoringMode:

Shared Mode (single anchor set):

{ "default": { "min": <number>, "scratch": <number>, "pro": <number> } }

Multi-Output Mode (per-subskill anchor sets):

{ "<subskill_id_1>": { "min": <number>, "scratch": <number>, "pro": <number> },

"<subskill_id_2>": { "min": <number>, "scratch": <number>, "pro": <number> } }

9.2 Drill.SubskillMapping (JSONB)

["<subskill_id>"] // Single-mapped

["<subskill_id_1>", "<subskill_id_2>"] // Dual-mapped

9.3 Instance.RawMetrics (JSONB)

Structure varies by MetricSchema InputMode:

  ---------------------------------- ------------------------------------------- -------------------------------------
  InputMode                          RawMetrics Shape                            Example

  GridCell                           { "row": <int>, "col": <int> }              { "row": 1, "col": 2 }

  ContinuousMeasurement              { "value": <number>, "unit": "<string>" }   { "value": 152.5, "unit": "yards" }

  RawDataEntry                       { "value": <number>, "unit": "<string>" }   { "value": 108.3, "unit": "mph" }

  BinaryHitMiss                      { "hit": <boolean> }                        { "hit": true }

  RawDataEntry (technique variant)   { "duration_seconds": <int> }               { "duration_seconds": 1800 }
  ---------------------------------- ------------------------------------------- -------------------------------------

Note: The DDL input_mode enum contains four values: GridCell, ContinuousMeasurement, RawDataEntry, BinaryHitMiss. Technique-duration drills use InputMode = RawDataEntry with a distinct JSON shape ({ "duration_seconds": <int> }) rather than the standard RawDataEntry shape. The MetricSchema seed data (002_seed_reference_data) maps technique_duration to InputMode = 'RawDataEntry'. There is no separate TechniqueDuration enum value. The scoring adapter must inspect the MetricSchemaID to determine which JSON shape to expect within RawDataEntry.

9.3.1 RawMetrics Parse Failure Handling

When a Repository method receives or processes RawMetrics JSON that does not conform to the expected schema for the associated MetricSchema:

-   On Instance creation (logInstance): If RawMetrics fails schema validation (missing required keys, wrong types, unexpected structure), the operation throws VALIDATION_INVALID_RAW_METRICS. The Instance is not created. The UI displays field-level feedback.

-   On sync merge (incoming remote data): If a downloaded Instance contains RawMetrics that cannot be parsed against its Drill’s MetricSchema, the Instance is still inserted (data preservation). However, scoreInstance returns 0.0 for the Instance and logs an EventLog entry (EventType = RawMetricsParseFailed, Metadata = {instanceId, parseError}). The Instance is included in windows but contributes a 0.0 score until corrected.

-   On reflow (existing data): If an existing Instance’s RawMetrics cannot be parsed during reflow (possible after a MetricSchema change), the same 0.0-score fallback applies. The EventLog entry is written once per affected Instance per reflow cycle.

9.4 CalendarDay.Slots (JSONB)

[{ "position": 0, "drillId": "<uuid>"|null,

"sessionId": "<uuid>"|null,

"completionState": "Incomplete"|"CompletedLinked"|"CompletedManual",

"ownerType": "Manual"|"RoutineInstance"|"ScheduleInstance",

"ownerInstanceId": "<uuid>"|null,

"slotUpdatedAt": "<ISO8601>" }, ... ]

9.5 MaterialisedWindowState.Entries (JSONB)

[{ "sessionId": "<uuid>", "drillId": "<uuid>",

"score": <0-5>, "occupancy": <0.5|1.0>,

"completionTimestamp": "<ISO8601>" }, ... ]

Ordered by CompletionTimestamp DESC. Most recent first. Total occupancy across all entries ≤ 25.0.

9.5.1 Window JSON Size Constraint

The Entries JSON array has a bounded maximum size. A window contains at most 50 entries (25.0 occupancy units at 0.5 minimum occupancy per entry). Each entry is approximately 180 bytes of JSON. The worst-case Entries blob is therefore approximately 9KB. This is well within SQLite’s default page size (4KB pages, with overflow pages for larger blobs) and Postgres JSONB limits. No explicit size cap is enforced; the 25-unit occupancy ceiling provides an implicit bound.

9.6 Routine.Entries (JSONB)

[{ "type": "fixed", "drillId": "<uuid>" },

{ "type": "generated", "criteria": {

"skillArea": "<SkillArea>", "drillType": "<DrillType>",

"subskill": "<subskill_id>"|null } }, ... ]

9.7 ReflowTrigger (Dart enum/class)

class ReflowTrigger {

final ReflowTriggerType type;

final String? drillId;

final String? sessionId;

final List<String> affectedSubskills;

}

enum ReflowTriggerType {

anchorEdit, sessionDeletion, instanceEdit,

instanceDeletion, drillDeletion, drillRetirement,

allocationChange, syncRebuild

}

9.8 PracticeBlockSummary (Dart class)

Return type for endPracticeBlock. Contains data for the Post-Session Summary screen (Section 13, §13.13):

class PracticeBlockSummary {

final String practiceBlockId;

final DateTime startTimestamp;

final DateTime endTimestamp;

final List<SessionSummary> sessions;

}

class SessionSummary {

final String sessionId;

final String drillName;

final SkillArea skillArea;

final DrillType drillType;

final double? sessionScore;

final double? scoreDelta;

final String? skillAreaImpact;

final bool integrityFlagged;

}

10. Deferred Items

-   Batch Instance logging: V1 logs Instances one at a time. Batch submission (e.g. paste from launch monitor) deferred to V2.

-   Real-time Supabase subscriptions: V1 sync is pull-based. Real-time subscriptions (TD-01 §2.11) deferred to V2.

-   Field-level merge: Only CalendarDay uses sub-row merge in V1. Other entities use row-level LWW. Field-level merge for additional entities deferred per TD-01 §2.11.

-   EventLog archival API: EventLog grows indefinitely in V1. Server-side archival endpoint deferred per Section 16 §16.7.4.

-   Push notification triggers: Supabase Edge Functions for push notifications (e.g. practice reminders) deferred to V2.

-   Server-side SlotUpdatedAt normalisation: Server reassignment of SlotUpdatedAt values during upload deferred to V2. V1 uses client-side timestamps with server-side future-timestamp validation (§5.4.4).

11. Dependency Map

TD-03 is consumed by:

-   TD-04 (Entity State Machines): Repository method signatures define the operations that trigger state transitions. Reflow trigger catalogue (§4.1) defines when scoring state changes. TD-03 references TD-04 for state transition guard definitions; TD-04 references TD-03 for the method contracts those guards protect.

-   TD-05 (Scoring Engine Test Cases): Reflow algorithm (§4.2) and scoring pipeline (§4.4) define the computation steps that test cases verify. Payload shapes (§9) define test data structures.

-   TD-06 (Phased Build Plan): Repository organisation (§3.1) determines which interfaces are built in which phase. Sync engine (§5) is Phase 7 scope. Composite operations define acceptance criteria.

-   TD-07 (Error Handling): Error categories (§7.1) and error shape (§7.2) define the patterns TD-07 expands into full failure mode analysis.

-   TD-08 (Claude Code Prompt Architecture): Repository organisation (§3.1) determines module boundaries in the codebase. Domain boundaries (§6) define where code lives in the directory structure.

12. Version History

  ------------ --------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Version      Date            Description

  TD-03v.a1    February 2026   Initial draft. Two-layer architecture (Local Repository + Sync Transport). Full CRUD and composite operation contracts. Reflow process consolidation. Domain boundary definitions. Sync pipeline implementation detail.

  TD-03v.a2    February 2026   Addressed critique findings. Added: SyncWriteGate service for concurrency coordination (§2.1.1). RebuildGuard for full rebuild vs reflow overlap (§4.5). Upload payload batching thresholds (§5.2.2). Explicit upload idempotency contract (§5.2.3). DTO serialisation layer (§5.2.5). Download query performance clause (§5.3.3). Tie-break rationale and timestamp precision (§5.4.2). SlotUpdatedAt trust model and server-side validation (§5.4.4). RawMetrics parse failure handling (§9.3.1). Window JSON size constraint (§9.5.1). Explicit TD-04 forward references throughout §3. Storage pressure handling in rebuild (§4.5). New error codes: VALIDATION_SLOT_TIMESTAMP_FUTURE, SYNC_PAYLOAD_TOO_LARGE, SYSTEM_REBUILD_TIMEOUT.

  TD-03v.a3    February 2026   Addressed final critique refinements. Added: FIFO execution ordering guarantee for deferred reflows after RebuildGuard release (§4.5). Explicit storage exhaustion failure semantics with SYSTEM_STORAGE_FULL, transaction rollback, and no partial commit (§4.5). Partial upload crash handling clarification: crash mid-upload re-sends full payload idempotently on next sync (§5.2.2). Download index requirement elevated to mandatory with explicit Phase 7 gate (§5.3.3).

  TD-03v.a4    February 2026   TD-04 harmonisation. Window composition deterministic secondary sort: ORDER BY CompletionTimestamp DESC, SessionID DESC added to §4.2 Step 5 for cross-device convergence guarantee at boundary conditions. Session close scoring lock model: explicit statement added to §4.4 that the Session close pipeline runs outside UserScoringLock because it appends incrementally rather than rebuilding historical state. Deferred reflow coalescing: §4.5 RebuildGuard mechanism updated from FIFO queue to subskill-scope coalescing — pending triggers merged into a single combined scope before execution, eliminating redundant rebuilds.
  ------------ --------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End of TD-03 — API Contract Layer (TD-03v.a5 Canonical)
