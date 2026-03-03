# TD Reference Catalogue

> Exhaustive catalogue of every topic, entity, API, rule, decision, and dependency
> referenced across all 8 Technical Design documents (TD-01 through TD-08).
> Built for gap analysis against Product Specification sections S00--S17.

---

## TD-01 Technology Stack Decisions (TD-01v.a4)

### Topics & System Areas Covered
- Platform selection (Flutter, cross-platform, Android-first for V1, iOS deferred)
- Backend selection (Supabase hosted cloud with Postgres)
- Local database selection (Drift / SQLite for on-device persistence)
- State management selection (Riverpod)
- Authentication method (Google Sign-In via Supabase Auth; Apple Sign-In mandatory when iOS added)
- Distribution channel (Google Play Store, internal/closed testing tracks)
- Push notifications (Firebase Cloud Messaging triggered by Supabase Edge Functions)
- Synchronisation strategy (Deterministic Merge-and-Rebuild model)
- Sync transport (timestamp-based upload/download, bidirectional)
- Conflict detection (timestamp-based, UpdatedAt comparison)
- Conflict resolution (Last-Write-Wins by UpdatedAt for structural edits)
- Soft-delete propagation (forward-only, delete always wins regardless of timestamp)
- ID generation (client-generated UUID v4, accepted natively by Postgres)
- Tombstone strategy (existing IsDeleted soft-delete flags; no separate tombstone table)
- Sync granularity (row-level; CalendarDay Slot-level exception)
- Reflow on sync (automatic, non-blocking full deterministic rebuild)
- Materialised state (never synced; local-only replaceable cache)
- Authority model: structural definitions (server-authoritative)
- Authority model: execution data (additive merge)
- Authority model: scoring (deterministic local projection, no device holds authoritative scoring state)
- Merge precedence table (Updated/Updated = LWW, Updated/Deleted = Deleted, Deleted/Updated = Deleted, Deleted/Deleted = Deleted)
- CalendarDay Slot-level merge (per-position independent LWW using SlotUpdatedAt)
- Sync pipeline 6-step sequence (Upload, Download, Merge, Completion Matching, Deterministic Rebuild, Confirm)
- Sync atomicity per stage (Upload = single Supabase RPC transaction, Download = consistent snapshot, Merge = single Drift transaction)
- Cross-device Session concurrency (same device: enforced at runtime; online: server-mediated; offline: both Sessions merge additively)
- System Drill update delivery (via standard sync pipeline download)
- Schema version gating (sync blocked if local schema older than server; "App update required to sync")
- Schema migration backward compatibility requirement for raw execution entities
- Security: local DB encryption not required for V1 (Android FBE sufficient)
- Security: Supabase RLS enabled on all user-scoped tables from day one
- Security: RLS policy pattern (SELECT/INSERT/UPDATE/DELETE scoped to auth.uid())
- Security: RLS child table join-through policies (deepest chain = 4 joins: Instance -> Set -> Session -> PracticeBlock -> UserID)
- Security: JWT access token and refresh token management by Supabase Auth
- Security: token lifecycle during offline periods (auto-refresh, re-auth prompt if refresh token expired)
- Security: HTTPS enforced on all Supabase connections
- Security: server-side AES-256 encryption at rest by Supabase default
- Rooted-device threat model exclusion (local SQLite extractable on rooted device; accepted for V1)
- Scale: max 20,000 Sessions per user over product lifetime
- Scale: max 100 Instances per Session
- Scale: max 2,000,000 total Instances (theoretical ceiling)
- Scale: window size fixed at 25 occupancy units
- Scale: max active drills practical ceiling 200-300
- Performance: target device baseline = 2020 mid-range Android (Samsung Galaxy A51 equivalent)
- Performance: single-drill reflow < 200ms (later refined to < 150ms in TD-06)
- Performance: full reflow < 500ms (later refined to < 1s in TD-06)
- Performance: cold-start to SkillScore < 1 second
- Performance: Instance logging latency < 50ms per write
- Cold-start edge cases (crash mid-reflow, schema migration, first launch)
- Local storage envelope estimates (light user 15-40MB, heavy user 80-200MB, realistic ceiling 150-400MB, theoretical max ~600MB+)
- Scoring engine as pure rebuild (recalculates all derived state from raw Instance data every time)
- Materialised tables as output destination of pure rebuild engine (replaceable cache)
- Reflow atomic swap within Serializable transaction
- Future sync evolution levers (real-time subscriptions, field-level merge, operation-level sync)

### Entities & Data Structures Referenced
- User
- Drill (System Drill, User Custom Drill)
- PracticeBlock
- Session
- Set
- Instance
- PracticeEntry
- UserDrillAdoption
- UserClub
- ClubPerformanceProfile
- UserSkillAreaClubMapping
- Routine, RoutineInstance
- Schedule, ScheduleInstance
- CalendarDay (with Slots JSON array)
- EventLog
- UserDevice
- SyncMetadata (local-only)
- MaterialisedWindowState
- MaterialisedSubskillScore
- MaterialisedSkillAreaScore
- MaterialisedOverallScore
- SubskillRef (reference table)
- MetricSchema (reference table)
- EventTypeRef (reference table)

### Rules, Constraints & Business Logic
- Every synced table must have UpdatedAt (timestamp, UTC, NOT NULL) with automatic update trigger; EventLog exception (CreatedAt only)
- IsDeleted soft-delete flag required on tables supporting user-initiated deletion; exempt categories listed (account-lifecycle, ephemeral, status-managed, insert-only, insert/hard-delete, permanent-once-created)
- Tables with IsDeleted: Drill, PracticeBlock, Session, Set, Instance, UserDrillAdoption, Routine, Schedule, UserDevice
- UUID v4 primary keys generated client-side for all entities
- Local-only tables excluded from sync (SyncMetadata, materialised tables)
- Sync queries must include soft-deleted records
- Window composition: ORDER BY CompletionTimestamp DESC, SessionID DESC for deterministic membership
- Bounded window size (25 occupancy units) ensures constant window composition cost
- Single active Session per user rule
- Offline: no operations blocked by lack of connectivity
- All schema migrations must preserve backward compatibility of raw execution entities

### Decisions & Rationale
- Flutter over native Android (cross-platform, iOS reuse, owner familiarity)
- React Native rejected (weaker typing than Dart)
- Supabase over Firebase Firestore (relational model fits better than NoSQL)
- Drift over Isar/Hive (relational local DB mirrors Postgres schema)
- Riverpod over BLoC (less boilerplate), over Provider (known limitations), over GetX (loosely structured)
- SQLCipher not added (proportionate to data sensitivity)
- Timestamp-based sync over CRDT/operation-log (deliberately simple for V1)
- LWW over field-level merge (simpler; CalendarDay is sole exception)
- Row-level sync granularity with CalendarDay Slot-level exception acknowledged as deviation

### External Integrations & Dependencies
- Flutter SDK
- Supabase (hosted cloud Postgres, Auth, Edge Functions, RLS, real-time subscriptions)
- Drift (SQLite code generation for Flutter)
- Riverpod (state management)
- Google Sign-In (via Supabase Auth)
- Google Play Store (distribution)
- Firebase Cloud Messaging (push notifications)
- Apple Sign-In (mandatory when iOS introduced)

---

## TD-02 Database DDL Schema (TD-02v.a6)

### Topics & System Areas Covered
- Schema overview: 5 table groups (Source, Reference, Planning, Materialised, System) = 28 tables
- Postgres DDL for Supabase (001_create_schema.sql)
- Seed data (002_seed_reference_data.sql)
- Drift (SQLite) local schema mirroring Postgres 1:1 with SQLite-specific adaptations
- SubskillRef reference table introduction (not in S06/S16; centralises subskill identity and allocation)
- SubskillID naming convention (snake_case compound key: {skill_area}_{subskill_name})
- Server-assigned UpdatedAt via Postgres BEFORE UPDATE trigger (set_updated_at function)
- Deterministic System Drill UUIDs (patterned: a0000001-0000-4000-8000-00000000000N)
- Sync uniformity: UpdatedAt on all synced tables for uniform pull path; EventLog exception (CreatedAt only)
- Materialised tables as output layer of pure rebuild engine
- Putting Direction: ClubSelectionMode = NULL (Putter auto-selected)
- MaterialisedWindowState.PracticeType constrained to Transition or Pressure (TechniqueBlock excluded)
- Target size columns: TargetSizeWidth for direction (1x3), TargetSizeDepth for distance (3x1), both for 3x3
- PercentageOfTargetDistance value semantics (e.g. 7 means 7%)
- Sync infrastructure requirements (UpdatedAt trigger, IsDeleted flags, UUID PKs, SyncMetadata)
- RLS model: three tiers (direct UserID, Drill hybrid, child table join-through)
- Enumeration strategy: 21 stable Postgres ENUM types + extensible reference tables (EventTypeRef, MetricSchema)
- Index coverage (all S16 indexes plus FK column indexes; governance rule for no duplicate single-column indexes)
- Critical window construction index: ix_session_drill_completion (DrillID, CompletionTimestamp DESC)
- Partial index: ix_session_status (Active only) for single-active-Session enforcement
- Download sync indexes: composite (UserID, UpdatedAt) on synced tables; (UserID, CreatedAt) on EventLog
- UpdatedAt-only indexes on child tables without UserID (ix_sync_session, ix_sync_set, ix_sync_instance, ix_sync_clubprofile)

### Entities & Tables Defined
- Source Tables (11): User, Drill, PracticeBlock, Session, Set, Instance, PracticeEntry, UserDrillAdoption, UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping
- Reference Tables (3): EventTypeRef, MetricSchema, SubskillRef
- Planning Tables (5): CalendarDay, Routine, Schedule, RoutineInstance, ScheduleInstance
- Materialised Tables (4): MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore
- System Tables (5): EventLog, UserDevice, UserScoringLock, SystemMaintenanceLock, MigrationLog

### Seed Data Manifest
- EventTypeRef: 16 rows (all canonical event types from S07 + IntegrityFlag events from S11 + ReflowComplete, SessionCompletion, RebuildStorageFailure)
- SubskillRef: 19 rows with allocations summing to 1000 (Irons 280, Driving 240, Putting 200, Pitching 100, Chipping 100, Woods 50, Bunkers 30)
- MetricSchema: 8 rows (grid_1x3_direction, grid_3x1_distance, grid_3x3_multioutput, binary_hit_miss, raw_carry_distance, raw_ball_speed, raw_club_head_speed, technique_duration)
- System Drills: 28 rows (7 Technique Blocks, 7 Direction Control, 6 Distance Control, 3 Distance Maximum, 3 Shape Control, 2 Flight Control)
- SystemMaintenanceLock: 1 row (IsActive = FALSE)

### Rules & Constraints
- 21 enum types (stable, schema migration required to add values)
- 28 tables, 17 triggers, 49 indexes (including 16 sync download indexes), 30 RLS policies
- 22 CHECK constraints (value range, JSONB type guards, ScoringMode conditional nullability, status/delete consistency, date range)
- 5 UNIQUE constraints
- Drift local schema: no ENUM types (TEXT with app-layer validation), no JSONB (TEXT parsed at read), no RLS, client-assigned UpdatedAt locally, TIMESTAMPTZ -> INTEGER (epoch ms), DECIMAL -> REAL
- SystemMaintenanceLock and MigrationLog are server-only (not in local Drift schema)

### Deferred Items
- Soft-delete partial indexes
- GIN indexes on JSON columns
- Snapshot immutability triggers on Instance and PracticeBlock
- EventLog archival job
- Advisory locks (pg_advisory_xact_lock)

---

## TD-03 API Contract Layer (TD-03v.a5)

### Topics & System Areas Covered
- Two-layer interface model (Local Repository Layer + Sync Transport Layer)
- Offline-first architecture: client never communicates directly with Supabase for routine operations
- SyncWriteGate service (coordinates Repository and Sync write exclusivity)
- SyncWriteGate mechanics: acquireExclusive(), 2-second drain period, 60-second hard timeout, Dart Completer suspension, singleton via Riverpod
- Repository layer principles (single source of truth, reactive streams, transaction boundaries, no network awareness, type safety)
- Sync transport principles (6-step pipeline, atomic stages, trigger model, non-blocking)
- Domain-scoped repository classes (8 repositories + SyncRepository)
- Standard CRUD pattern (Create, Read single, Read stream, Update, Soft Delete, Hard Delete)
- Soft delete vs hard delete semantics and use cases
- PracticeEntry query safety rule (scoring queries must never join through PracticeEntry)
- Reflow process contract (10-step algorithm)
- Reflow trigger catalogue (9 trigger types with affected scopes)
- Session close scoring pipeline (runs outside UserScoringLock)
- RebuildGuard for full rebuild coordination (in-memory, 30-second timeout, deferred reflow coalescing)
- Sync engine interface (triggerSync, getSyncStatus, getLastSyncTimestamp, forceFullSync)
- Upload RPC function (sync_upload): request payload structure, UPSERT logic, server-side processing
- Upload payload batching (2MB per request, parent-before-child ordering, partial upload state tracking)
- Upload idempotency (UPSERT inherently idempotent)
- Structural immutability guard on Drill UPSERT (SubskillMapping, MetricSchemaID, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ScoringMode, InputMode)
- Download RPC function (sync_download): request payload, server-side processing, REPEATABLE READ isolation
- Download query performance (composite indexes required)
- Client-side merge algorithm (general LWW, delete-always-wins, additive merge for execution data)
- Tie-break rationale (local-wins-tie when UpdatedAt equal; microsecond precision)
- CalendarDay Slot-level merge (per-position independent merge using SlotUpdatedAt)
- SlotUpdatedAt trust model and server-side future-timestamp validation (NOW() + 60 seconds tolerance)
- Post-merge pipeline (completion matching, deterministic rebuild, confirm)
- SyncWriteGate timeout validation during post-merge pipeline
- Domain boundary enforcement (Database, Repository, Sync Transport, UI layers)
- Error response contract (5 categories: VALIDATION, STATE, CONSTRAINT, SYNC, SYSTEM)
- ZxGolfAppException base class and subclasses
- Authentication flow (Google Sign-In via Supabase Auth, JWT management, offline behaviour)
- Authorisation model (local: single-user; remote: RLS)
- Key payload shapes (Anchors, SubskillMapping, RawMetrics, CalendarDay Slots, MaterialisedWindowState Entries, Routine Entries, ReflowTrigger, PracticeBlockSummary)
- RawMetrics parse failure handling (creation: throw; sync merge: insert with 0.0 score; reflow: 0.0 fallback)

### API Endpoints & Contracts
- sync_upload RPC function (Supabase Edge Function or Postgres RPC, single Postgres transaction)
- sync_download RPC function (REPEATABLE READ isolation, includes soft-deleted rows)
- DTO serialisation layer (sync_dto.dart): toSyncDto() extension methods, fromSyncDto() factory methods

### Repository Methods Defined
- **UserRepository**: getCurrentUser(), updateSettings(), updateProfile()
- **DrillRepository**: watchUserDrills(), watchAdoptedDrills(), createCustomDrill(), updateDrill(), retireDrill(), deleteDrill(), adoptDrill(), retireAdoption(), getMetricSchema()
- **PracticeRepository**: createPracticeBlock(), watchPracticeBlock(), getActivePracticeBlock(), addDrillToQueue(), removePendingEntry(), removeCompletedEntry(), reorderQueue(), duplicateEntry(), startSession(), discardSession(), restartSession(), logInstance(), advanceSet(), endSession(), endPracticeBlock(), saveQueueAsRoutine(), updateInstance(), deleteInstance()
- **ScoringRepository**: watchOverallScore(), watchSkillAreaScores(), watchSubskillScores(), watchWindowState(), executeReflow(), executeFullRebuild(), acquireScoringLock(), releaseScoringLock(), isScoringLocked(), scoreInstance(), scoreSession()
- **ClubRepository**: watchUserBag(), addClub(), updateClub(), retireClub(), addPerformanceProfile(), getActiveProfile(), watchClubsForSkillArea(), updateSkillAreaMapping()
- **PlanningRepository**: watchRoutines(), createRoutine(), updateRoutine(), deleteRoutine(), watchSchedules(), createSchedule(), applySchedule(), watchCalendarDays(), updateCalendarDay(), executeCompletionMatching()
- **EventLogRepository**: writeEvent(), watchRecentEvents(), getEventsForEntity()
- **SyncEngine**: triggerSync(), getSyncStatus(), getLastSyncTimestamp(), forceFullSync()

### Rules & Business Logic
- Reflow algorithm 10 steps: Acquire Lock -> Determine Affected Subskills -> Rebuild Instance Scores -> Rebuild Session Scores -> Rebuild Window Composition -> Rebuild Subskill Scores -> Rebuild Skill Area Scores -> Rebuild Overall Score -> Side Effects -> Release Lock
- Window composition: occupancy 1.0 single-mapped, 0.5 dual-mapped; partial roll-off (1.0 -> 0.5 with score preserved); cumulative <= 25.0
- Subskill scoring: WeightedAverage = (TransitionAvg x 0.35) + (PressureAvg x 0.65); SubskillPoints = Allocation x (WeightedAverage / 5)
- Session close pipeline does NOT acquire UserScoringLock (appends incrementally, does not rebuild historical state)
- RebuildGuard prevents concurrent full rebuild and scoped reflow; deferred reflows coalesced by subskill scope union
- Rebuild storage pressure: truncate-and-repopulate temporarily doubles storage (~50KB worst case); SYSTEM_STORAGE_FULL on exhaustion
- Upload rejected_rows mechanism for structural field changes on Drill
- Domain boundary rules: scoring never in UI, state machine guards never at DB layer, UI never writes to Drift directly, sync engine never triggers business logic, RLS is last line of defence

### Payload Shapes
- Drill.Anchors: Shared mode ({"default": {min, scratch, pro}}), Multi-Output mode (per-subskill anchor sets)
- Drill.SubskillMapping: JSON array of subskill IDs (1 or 2)
- Instance.RawMetrics: varies by InputMode (GridCell: {row, col}; ContinuousMeasurement: {value, unit}; RawDataEntry: {value, unit}; BinaryHitMiss: {hit}; technique variant: {duration_seconds})
- CalendarDay.Slots: JSON array of {position, drillId, sessionId, completionState, ownerType, ownerInstanceId, slotUpdatedAt}
- MaterialisedWindowState.Entries: JSON array of {sessionId, drillId, score, occupancy, completionTimestamp}; max ~50 entries, ~9KB worst case
- Routine.Entries: JSON array of {type: "fixed", drillId} or {type: "generated", criteria: {skillArea, drillType, subskill}}
- ReflowTrigger: {type, drillId?, sessionId?, affectedSubskills}
- ReflowTriggerType enum: anchorEdit, sessionDeletion, instanceEdit, instanceDeletion, drillDeletion, drillRetirement, allocationChange, syncRebuild
- PracticeBlockSummary: {practiceBlockId, startTimestamp, endTimestamp, sessions: [SessionSummary]}
- SessionSummary: {sessionId, drillName, skillArea, drillType, sessionScore?, scoreDelta?, skillAreaImpact?, integrityFlagged}

### Deferred Items
- Batch Instance logging (V2)
- Real-time Supabase subscriptions (V2)
- Field-level merge beyond CalendarDay (V2)
- EventLog archival API
- Push notification triggers
- Server-side SlotUpdatedAt normalisation (V2)

---

## TD-04 Entity State Machines & Reflow Process (TD-04v.a4)

### Topics & System Areas Covered
- Formal state machine tables for all entities with meaningful lifecycles
- State machine format: FromState -> ToState -> Guard Condition -> Side Effects -> Spec Reference
- PracticeEntry state machine (PendingDrill, ActiveSession, CompletedSession)
- PracticeEntry persistent state rule (PracticeEntry not synced; cross-device Sessions exist without PracticeEntry)
- Session state machine (Active, Closed, Discarded)
- Session structured completion (auto-close on final Instance of final Set)
- Session unstructured completion (manual End Drill)
- Session auto-close (2-hour inactivity timer via TimerService)
- Session discard (hard-delete, no scoring trace)
- Cross-device dual-Active-Session offline resolution (both merge additively; online: LWW, loser hard-deleted)
- Active Session ephemeral data-loss rule (only Closed Sessions are durable; never merge Instances between conflicting Active Sessions)
- PracticeBlock state machine (Active, Closed)
- PracticeBlock auto-end (4-hour inactivity timer)
- PracticeBlock closure types (Manual, ScheduledAutoEnd, SessionTimeout)
- Timer pause semantics during scoring lock (timers pause, resume with preserved remaining duration)
- Drill state machine (Active, Retired, Deleted)
- Drill structural immutability post-creation (SubskillMapping, MetricSchemaID, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ScoringMode, InputMode)
- UserDrillAdoption state machine (Active, Retired)
- CalendarDay Slot state machine (Empty, Assigned, CompletedLinked, CompletedManual)
- Routine state machine (Active, Deleted; empty Routines auto-deleted when referenced Drill deleted/retired)
- Schedule state machine (Active, Deleted)
- UserClub state machine (Active, Retired)
- Reflow trigger catalogue (10 triggers: anchor edit, Session deletion, Instance edit/deletion on Closed Session, Drill deletion/retirement with window entries, Subskill allocation change, 65/35 weighting edit, scoring formula edit, sync merge completion)
- Non-reflow triggers explicitly listed (window size changes, IntegrityFlag changes, Instance edits during active Session, Drill metadata edits, club/routine/schedule/CalendarDay changes)
- Session close scoring pipeline (not a reflow trigger; runs outside ScoringLock)
- Scoped reflow algorithm (10 steps, single Drift transaction)
- Full rebuild algorithm (post-sync, uses RebuildGuard not UserScoringLock)
- Deferred reflow coalescing (pending triggers merged by subskill union; single execution)
- Reflow idempotency and failure handling (crash recovery, timeout, retry exhaustion, storage exhaustion, guard timeout)
- Scope determination rules (single-mapped: 1 subskill; dual-mapped Shared: 2; dual-mapped Multi-Output single anchor: 1; allocation change: all in Skill Area; 65/35 or formula change: all 19; sync: all 19)
- Sync conflict as implicit state event (post-merge state is authoritative)
- Delete-always-wins in sync merge context
- Offline state transitions (all operate identically offline)
- Three coordination mechanisms compared (UserScoringLock vs SyncWriteGate vs RebuildGuard)
- Blocked operations during scoring lock (Session start, Instance logging, edits, deletions, anchor edits)
- Not-blocked operations during scoring lock (club edits, Routine/Schedule edits, CalendarDay Slot edits, Settings changes, queue reordering)

### Entities with State Machines
- PracticeEntry: PendingDrill -> ActiveSession -> CompletedSession (with hard-delete transitions)
- Session: Active -> Closed (structured/unstructured/auto-close); Active -> Discarded
- PracticeBlock: Active -> Closed (Manual/ScheduledAutoEnd/SessionTimeout)
- Drill: Active -> Retired; Active -> Deleted (soft); Retired -> Active (reactivate); Retired -> Deleted
- UserDrillAdoption: Active -> Retired; Retired -> Active (reactivate)
- CalendarDay Slot: Empty -> Assigned; Assigned -> CompletedLinked; Assigned -> CompletedManual; CompletedLinked -> Assigned (unlinking)
- Routine: Active -> Deleted (soft-delete; auto-delete when empty)
- Schedule: Active -> Deleted (soft-delete)
- UserClub: Active -> Retired

### Deferred Items
- CRDT or event-sourced state machines
- Drill version history
- Undo support for state transitions
- Multi-user state machines (Coach/Admin access)

---

## TD-05 Scoring Engine Test Cases (TD-05v.a3)

### Topics & System Areas Covered
- Precision and rounding policy (IEEE 754 double-precision, no intermediate rounding)
- Assertion tolerance (1e-9 absolute epsilon)
- Display precision (UI-layer concern only; recommended 1 decimal for 0-5 scores, 0 decimal for OverallScore)
- Deterministic equality definition (per-row numeric comparison with tolerance; non-numeric byte-equal)
- Algebraic rearrangement permitted if within tolerance
- Reference data for test cases (19 subskill allocations, V1 System Drill anchor values, scoring formula)
- Two-segment linear interpolation formula (Below Min: 0; Min-Scratch: 0-3.5; Scratch-Pro: 3.5-5; Above Pro: 5 capped)

### Test Case Categories
- Instance scoring: Grid Cell Selection hit-rate (TC-4.1.1 through TC-4.1.7)
- Instance scoring: Bunkers Direction different anchors (TC-4.2.1 through TC-4.2.3)
- Instance scoring: Raw Data Entry - Driving Carry per-Instance (TC-4.3.1 through TC-4.3.7)
- Instance scoring: Raw Data Entry - Ball Speed (TC-4.4.1 through TC-4.4.2)
- Instance scoring: Binary Hit/Miss (TC-4.5.1 through TC-4.5.3)
- Instance scoring: User Custom Drill non-standard anchors (TC-4.6.1 through TC-4.6.2)
- Session scoring: Grid Drill single set (TC-5.1.1)
- Session scoring: Raw Data Entry per-Instance averaging (TC-5.2.1)
- Session scoring: Multi-Set structured drill flat average (TC-5.3.1)
- Session scoring: Single Instance unstructured (TC-5.4.1)
- Window composition: basic fill (TC-6.1.1), full 25-unit (TC-6.2.1), overflow eviction (TC-6.3.1)
- Window composition: dual-mapped 0.5 occupancy (TC-6.4.1), mixed occupancy (TC-6.5.1)
- Window composition: boundary 0.5 fits 1.0 does not (TC-6.6.1)
- Window composition: partial roll-off 1.0->0.5 (TC-6.7.1), full roll-off 0.5 removed (TC-6.7.2), 0.5 swapped for 0.5 (TC-6.7.3)
- Window composition: deterministic ordering identical timestamps tiebreak on SessionID DESC (TC-6.8.1)
- Subskill scoring: both windows populated (TC-7.1.1), Transition only (TC-7.1.2), Pressure only (TC-7.1.3), both empty (TC-7.1.4), perfect score (TC-7.1.5), small allocation (TC-7.1.6)
- Skill Area scoring: all subskills populated (TC-8.1.1), one empty (TC-8.1.2), Bunkers two subskills (TC-8.1.3)
- Overall SkillScore: all areas populated (TC-9.1.1), single subskill only (TC-9.1.2), perfect 1000 (TC-9.1.3), zero no data (TC-9.1.4)
- Reflow: anchor edit recalculates historical scores (TC-10.1.1)
- Reflow: Session deletion recomposes window (TC-10.2.1)
- Reflow: deletion window backfill (TC-10.3.1)
- Reflow: dual-mapped scope (TC-10.4.1)
- Reflow: full rebuild convergence (TC-10.5.1)
- Reflow: interrupted reflow idempotent re-run (TC-10.6.1)
- Reflow: post-sync dual-device convergence (TC-10.7.1)
- Edge cases: Technique Block no window entry (TC-11.1.1), soft-deleted Session excluded (TC-11.1.2), zero hit-rate (TC-11.1.3), post-close edit triggers reflow (TC-11.1.4), integrity flag no scoring impact (TC-11.1.5), last Instance deletion auto-discard (TC-11.1.6), Instance edit does not change window ordering (TC-11.1.7)
- Multi-Output mode: 3x3 grid independent scores through to SubskillPoints (TC-12.1.1), asymmetric performance (TC-12.1.2)
- Anchor validation: valid (TC-13.1.1), Min=Scratch rejected (TC-13.1.2), Scratch=Pro rejected (TC-13.1.3), Min>Scratch rejected (TC-13.1.4), Scratch>Pro rejected (TC-13.1.5), all equal rejected (TC-13.1.6), negative anchors valid if increasing (TC-13.1.7), anchor edit same rules (TC-13.1.8)
- End-to-end scoring scenario: raw data through to OverallScore for Irons only (Section 14)

### Rules Verified by Tests
- Two-segment linear interpolation with hard cap at 5.0
- Session score = simple average of all Instance 0-5 scores across all Sets (flat average, no Set weighting)
- Window occupancy: 1.0 single-mapped, 0.5 dual-mapped; cap at 25.0
- Partial roll-off: 1.0 entry reduced to 0.5 with score preserved
- WeightedSum = sum(score x occupancy); WindowAverage = WeightedSum / TotalOccupancy
- SubskillPoints = Allocation x (WeightedAverage / 5)
- WeightedAverage = (TransitionAvg x 0.35) + (PressureAvg x 0.65)
- SkillAreaScore = sum of SubskillPoints for all subskills
- OverallScore = sum of all 7 SkillAreaScores; max 1000
- Empty window average = 0.0
- Anchor validation: Min < Scratch < Pro strictly increasing
- IntegrityFlag has zero scoring effect
- CompletionTimestamp immutable after Session close
- Technique Block Sessions produce no scoring impact (no window entry)
- Reflow is idempotent (re-running produces identical results)
- Full rebuild produces deterministic convergence across devices
- SessionID DESC tiebreaker for identical CompletionTimestamp (lexicographic UUID comparison)

### Deferred Test Categories
- Continuous Measurement System Drills (identical adapter to Raw Data Entry)
- Pressure System Drills (tested via User Custom Drill examples)
- Cross-device sync reflow convergence multi-device harness (Phase 7 deliverable)
- Performance envelope tests (TD-06 scope)
- Lock acquisition/retry/release mechanics (TD-07 scope)
- LWW structural resolution (TD-03/Phase 7 scope)

---

## TD-06 Phased Build Plan (TD-06v.a6)

### Topics & System Areas Covered
- 12-phase build structure (1, 2A, 2.5, 2B, 3, 4, 5, 6, 7A, 7B, 7C, 8)
- Phase sequencing: strictly sequential, hard gate at each boundary
- Design decisions: early server validation (Phase 2.5 before 2B), design-early foundation, automated tests for invisible logic, performance baseline, scoring engine split, optimised validation ordering, sync engine split, instrumentation-first, sync rollback strategy
- Flutter project structure (feature-first directory structure with shared core modules)
- Design system foundation from S15 (colour tokens, typography, spacing, shape, surface, motion, base components)
- Riverpod provider architecture (scoped to authenticated user session)
- Error type hierarchy (established Phase 1)
- Observability and logging framework (established Phase 2B: log levels, domain tagging, reflow/sync diagnostics, dev-mode inspector, profiling harness)
- Sync-awareness guidance for pre-sync phases (no monotonic timestamp assumptions, no fixed window composition assumptions, all reads through reactive streams, no single-device assumptions)
- SyncWriteGate timeout semantics (2-second drain, 60-second hard timeout, crash safety)

### Build Phases Defined
- **Phase 1 - Data Foundation & Design System**: DDL deployment, Drift schema, seed data, design tokens, base components, repository scaffolding, error hierarchy, shell app
- **Phase 2A - Pure Scoring Library**: scoreInstance, scoring adapters per MetricSchema, scoreSession, composeWindow, scoreSubskill, scoreSkillArea, scoreOverall, evaluateIntegrity; all pure functions with TD-05 test suite
- **Phase 2.5 - Server Foundation**: Supabase project, SQL migrations deployed, Google Sign-In, sync_upload/sync_download RPC, DTO layer, basic sync engine, schema version gating
- **Phase 2B - Reflow & Lock Layer**: ScoringRepository full implementation, UserScoringLock, scope determination, materialised table writes, RebuildGuard, deferred reflow coalescing, Session close scoring pipeline, IntegritySuppressed reset, EventLog emission, crash recovery, developer instrumentation, profiling benchmark harness
- **Phase 3 - Drill & Bag Configuration**: DrillRepository full CRUD, Drill creation UI, immutability enforcement, System Drill library browsing, Practice Pool, ClubRepository, Golf Bag UI, UserSkillAreaClubMapping, state machine guards
- **Phase 4 - Live Practice**: TimerService, PracticeRepository with all composite operations, PracticeEntry queue UI, Session execution screens per input mode, target definition, club selection, real-time scoring, structured/unstructured/technique completion, auto-close timers, Session close pipeline, discard, post-close editing, PracticeBlock closure, Post-Session Summary, IntegrityFlag detection
- **Phase 5 - Planning Layer**: PlanningRepository CRUD, Routine/Schedule management UI, Calendar UI, Routine/Schedule instantiation, completion matching, completion overflow, auto-deletion cascades, CalendarDay Slot transitions
- **Phase 6 - Review & Analysis**: SkillScore dashboard, Skill Area detail, subskill detail, window detail, drill history, trend visualisation, heatmap, score display, zero state, IntegrityFlag indicators
- **Phase 7A - Sync Transport & DTO**: automatic sync triggers, payload batching (2MB), sync feature flag, sync diagnostic logging, connectivity monitoring, retry logic, RLS performance validation at 100K Instances
- **Phase 7B - Merge & Rebuild**: full merge algorithm, delete-always-wins, CalendarDay Slot-level merge, SyncWriteGate enforcement, post-merge pipeline, merge transaction atomicity, cross-device Session concurrency, server-side SlotUpdatedAt validation, randomised multi-edit merge harness (100 sequences, 5 cycles)
- **Phase 7C - Conflict UI & Offline Hardening**: offline indicator, sync progress UI, schema version gating UI, token lifecycle management, cross-device active Session warning, storage monitoring, sync status, sync-disabled indicator
- **Phase 8 - Polish & Hardening**: Settings screens, IntegritySuppressed toggle UI, motion refinement, achievement banners, accessibility audit, error messaging review, edge case hardening, font finalisation, product-name agnosticism, data migration playbook

### Acceptance Criteria (selected key items per phase)
- Phase 1: 28 Drift tables, seed data correct, CRUD on 3+ entities, design tokens render, reactive streams emit
- Phase 2A: all TD-05 §4-9 tests pass, boundary cases correct, IEEE 754 precision, 1e-9 tolerance
- Phase 2.5: schema deployed, seed data on server, Google Sign-In, sync round-trip, RLS validated, DTO round-trip, 100-Session/1000-Instance bulk test
- Phase 2B: TD-05 §10-12 pass, scoped reflow <150ms p95, full rebuild <1s p95, peak heap <=256MB, idempotent, lock blocks concurrent, RebuildGuard defers/coalesces, crash recovery works
- Phase 3: browse 28 System Drills, adopt/retire, create User Custom, anchor edit triggers reflow, immutability enforced, Golf Bag config
- Phase 4: all 6 input mode screens, auto-complete structured, real-time scoring, Session close <200ms, discard clean, single-active-Session enforced, auto-close timers, IntegrityFlag
- Phase 5: Routine create/instantiate, Schedule List/DayPlanning, Calendar Slots, completion matching, overflow, auto-deletion cascade
- Phase 6: dashboard with SkillScore, heatmap continuous opacity, zero state, cold-start <1s, WCAG AA/AAA
- Phase 7A: auto sync triggers, 2MB batching, feature flag, diagnostic logs, RLS at 100K <200ms
- Phase 7B: LWW correct, delete-always-wins all 4 scenarios, Slot merge, convergence (deterministic + 100 random), SyncWriteGate timeout, atomicity
- Phase 7C: offline indicator, schema mismatch message, token refresh/re-auth, cross-device Session warning, low-storage warning, sync-disabled indicator
- Phase 8: all Settings, IntegritySuppressed toggle, transitions <=200ms, WCAG AA/AAA, crash recovery, migration playbook

### Performance Targets
- Phase 1: app launch <3s on Pixel 5a
- Phase 2.5: RLS 4-join query at 1K rows/table <50ms
- Phase 2B: scoped reflow <150ms p95 (500 Sessions / 5K Instances), full rebuild <1s p95 (5K Sessions / 50K Instances), peak heap <=256MB
- Phase 6: dashboard cold-start <1s
- Phase 7A: RLS query at 100K Instances cold cache <200ms

### Testing Strategy
- Automated unit tests for scoring (Phase 2A), reflow (Phase 2B), DTO (Phase 2.5), state machines (Phases 3-4), completion matching (Phase 5), merge (Phase 7B), batching (Phase 7A)
- Automated benchmark for performance (Phase 2B)
- Randomised merge harness (Phase 7B): 100 random sequences, 5 cycles, zero convergence failures
- Manual verification for UI, accessibility, performance timing, multi-device

### Rollback Strategy
- Sync feature flag (boolean, persisted, default enabled) for zero-code rollback
- Merge isolation: single Drift transaction, SyncWriteGate timeout = full abort and rollback
- Phase 7 sub-phase independence: 7A = transport only, 7B = merge, 7C = UI (cannot destabilise merge)

### Data Migration Strategy
- Raw execution data is sacred (never delete/truncate/reinterpret)
- Materialised tables are disposable (truncate and rebuild)
- Seed data is additive (new rows; no modification without migration)
- Migration timing budget: <=1s or show progress indicator
- Test matrix: 1K, 10K, 100K Instances

### Deferred Items (V2 Backlog)
- Real-time Supabase subscriptions
- Field-level merge beyond CalendarDay
- EventLog archival
- Batch Instance logging / launch monitor paste
- Push notification triggers via Edge Functions
- Server-side SlotUpdatedAt normalisation
- Soft-delete partial indexes, GIN indexes, snapshot immutability triggers, advisory locks
- Multi-user / Coach access
- Undo support for state transitions
- Drill version history
- iOS deployment
- Remote log aggregation

---

## TD-07 Error Handling Patterns (TD-07v.a4)

### Topics & System Areas Covered
- Error classification: local errors vs remote errors (different recovery strategies)
- Error type hierarchy: ZxGolfAppException base class with 6 categories
- Complete exception catalogue (22 exception codes mapped to recovery patterns)
- Error propagation model: Repository -> Provider (AsyncError) -> UI (ErrorDisplay widget)
- Repository layer: throws typed exceptions, wraps Drift DatabaseException, includes diagnostic context map
- Provider layer: AsyncError states, stream errors do not terminate stream
- UI layer: AsyncValue.when() pattern, ErrorDisplay widget, top-level FlutterError.onError handler, Dart Zone error handler

### Exception Categories & Codes
- **Validation** (VALIDATION_*): INVALID_ANCHORS, INVALID_STRUCTURE, REQUIRED_FIELD, STATE_TRANSITION, DUPLICATE_ENTRY, SINGLE_ACTIVE_SESSION
- **Reflow** (REFLOW_*): LOCK_TIMEOUT, TRANSACTION_FAILED, REBUILD_TIMEOUT
- **Sync** (SYNC_*): UPLOAD_FAILED, DOWNLOAD_FAILED, MERGE_FAILED, MERGE_TIMEOUT, SCHEMA_MISMATCH, PAYLOAD_TOO_LARGE, NETWORK_UNAVAILABLE
- **System** (SYSTEM_*): DATABASE_CORRUPT, STORAGE_FULL, OUT_OF_MEMORY, MIGRATION_FAILED, REFERENTIAL_INTEGRITY
- **Conflict** (CONFLICT_*): DUAL_ACTIVE_SESSION, STRUCTURAL_DIVERGENCE, SLOT_COLLISION
- **Auth** (AUTH_*): TOKEN_EXPIRED, REFRESH_FAILED, SESSION_REVOKED

### Recovery Patterns
- Inline field validation (anchor validation, structural identity, required fields)
- State transition guard rejection (Repository guard, UI hides invalid affordances)
- Active Session conflict (VALIDATION_SINGLE_ACTIVE_SESSION: navigate to active Session or discard)
- Reflow lock retry exhaustion (deferred to queue, auto-recovery via lock expiry)
- Reflow transaction rollback (rollback, retry once, then 2-second delay, then fall back to full rebuild on next launch)
- Rebuild timeout (RebuildGuard 30-second timeout, retry on next foreground)
- Crash mid-reflow (expired lock detection on startup, full rebuild)
- Transport retry strategy (exponential backoff: 1s, 2s, 4s with +/-250ms jitter; max 3 retries per cycle)
- Sync concurrency control (single active sync invariant, retry cancellation on connectivity change, trigger debouncing 500ms)
- Merge rollback (single Drift transaction rollback, no partial merge)
- Merge failure escalation (3 consecutive: escalated banner; 5 consecutive: auto-disable sync)
- Merge auto-disable state machine (counter persisted in SyncMetadata, survives restarts, resets only on successful merge, schema mismatch bypasses counter)
- Merge timeout vs failure distinction (timeouts do NOT increment auto-disable counter)
- SyncWriteGate timeout (60-second abort, rollback, gate release)
- Schema version block (sync blocked, offline-only mode, "App update required" message)
- Payload size management (oversized entity excluded, flagged in SyncMetadata)
- Offline deferral (sync suppressed, offline indicator shown, auto-trigger on reconnect)
- Database corruption tiered recovery (Tier 1: integrity check + repair; Tier 2: server rebuild; Tier 3: clean start)
- Storage pressure (100MB warning, 50MB critical; sync downloads suspended at critical; resume trigger at 100MB with hysteresis)
- Memory pressure (OOM during rebuild: fail hard, restart; 2 consecutive OOM: score display disabled, all automatic rebuild triggers suspended)
- OOM consecutive failure counter persisted in SyncMetadata
- Migration failure (rollback to previous schema, re-attempt on next launch)
- Dual Active Session (LWW resolution, losing Session hard-deleted, Instance count logged, 6-second toast)
- Structural entity LWW (silent merge, no notification)
- Clock skew acknowledged (client-written UpdatedAt, +-60s tolerance, practical risk low)
- CalendarDay Slot-level merge (silent per-position LWW)
- Execution data additive merge (never a conflict)
- Token refresh (transparent), re-authentication (banner with Sign In action), session revocation

### User-Facing Error Messaging
- Message structure: factual statement + actionable instruction; no apologetic language, exclamation marks, emoji, or blame
- Four display patterns: inline field error, toast/snackbar (4-second auto-dismiss), persistent banner, blocking dialog
- Complete message catalogue for all 22 exception codes
- Silently handled events (offline deferral, structural LWW, Slot LWW, successful token refresh, lock retry success, individual transport retries, additive merge)

### Logging & Diagnostics
- Log levels: debug, info, warning, error (debug/info suppressed in release builds)
- Error log entry structure: timestamp, domain tag, level, exception code, message, context map
- EventLog persistent audit trail (events that must survive release build log suppression)
- EventLog entries: ReflowComplete, SyncComplete, SyncFailed, DatabaseRecovery, SessionAutoDiscarded, MigrationAttempt, DualActiveSessionResolved, MergeAutoDisabled, MergeReEnabled
- EventLog growth acknowledged (unbounded in V1; 90-day retention window deferred)
- EventLog indexing: Timestamp and EventType only; no Metadata JSON indexing in V1
- Developer instrumentation for error scenarios (materialised table inspector, reflow trigger console, sync diagnostic log viewer)

### Graceful Degradation Matrix
- No network: all local features available; sync unavailable
- Expired auth token: all local features; sync upload/download unavailable
- Scoring lock held: practice/planning/review (stale) available; Session start/Instance logging/edits blocked
- Database corruption: Tier 1 = all features; Tier 2 = all features after rebuild; Tier 3 = reset
- Storage full: read operations and sync upload; write operations fail individually
- Memory pressure (OOM): all features except score display (1st failure: stale values; 2+ failures: unavailable)
- Schema mismatch: all local features at current schema; sync blocked
- Sync feature flag disabled: all local features; sync unavailable

### Partial Save Recovery
- Crash during Instance logging (WAL journaling, Session stays Active, resume from committed Instances)
- Crash during Session close (scoring pipeline re-runs; RebuildNeeded flag detects incomplete materialised write)
- Session close idempotency guard (Status = Active check before pipeline execution)
- Crash during PracticeBlock operations (PracticeBlock stays Active, 4-hour timer restarts)
- Crash during sync merge (WAL journal recovery, rollback to pre-merge state)
- RebuildNeeded flag UI contract (score displays must show staleness indicator when true; dimmed opacity, not warning colour)

### Startup Integrity Checks (4 checks)
- Scoring lock check (expired lock -> full rebuild)
- RebuildNeeded flag check (true -> full rebuild)
- SyncMetadata partial upload state check (resume on next sync)
- Referential integrity check (PRAGMA foreign_key_check after previous FK violation; Tier 1 repair if violations found)
- Allocation invariant check (SUM(Allocation) from SubskillRef = 1000; re-load seed data if fails)

### Data Integrity Verification
- Referential integrity (FK violations -> SYSTEM_REFERENTIAL_INTEGRITY -> blocking dialog)
- Scoring determinism verification (paired rebuilds assert bitwise equality; startup check triggers rebuild)
- Allocation invariant (SubskillRef allocations sum to 1000)
- Sync payload validation (DTO schema conformance, entity reference integrity, timestamp plausibility)

### Error Handling by Build Phase
- Phase 1: exception hierarchy, top-level handlers, ErrorDisplay widget, allocation invariant
- Phase 2A: anchor validation, division-by-zero prevention, score cap
- Phase 2.5: schema mismatch, auth errors, transport errors, DTO validation
- Phase 2B: reflow lock timeout, transaction rollback, crash recovery, RebuildNeeded, OOM counter, instrumentation
- Phase 3: structural immutability, state transitions for Drill/Adoption/Club
- Phase 4: single active Session, Session close idempotency, timer errors, Instance crash recovery
- Phase 5: completion matching (no match is not error), cascade deletion, Slot validation
- Phase 6: graceful rendering with empty/stale data, zero state, cold-start
- Phase 7A: transport retry, payload size, network deferral, partial upload, concurrency control, diagnostics
- Phase 7B: merge rollback, merge timeout, dual active Session, atomicity, post-merge rebuild, consecutive failure counter, auto-disable
- Phase 7C: all user-facing sync messages, offline indicator, schema mismatch, auth banners, cross-device conflict, storage monitoring, sync-disabled indicator
- Phase 8: message audit, database corruption recovery, migration failure, storage handling, OOM escalation, referential integrity, RebuildNeeded verification, end-to-end testing

### Deferred Items
- Remote error reporting (Sentry/Crashlytics)
- User-initiated error reporting
- Automatic retry with user-configurable limits
- Conflict resolution UI beyond notifications
- Multi-user error scenarios

---

## TD-08 Claude Code Prompt Architecture (TD-08v.a3)

### Topics & System Areas Covered
- Context loading strategy for Claude Code sessions
- Complete artifact inventory (18 product specs S00-S17 + 8 TDs TD-01 to TD-08)
- Always-loaded context (CLAUDE.md, S00, S06 summary, TD-01, TD-02 snapshot, TD-06 current phase, TD-07 extracts, TD-03 SyncWriteGate summary)
- Phase-specific context loading table (12 phases x required documents)
- Context loading rules (phase boundary enforcement, additive loading, extract discipline, CLAUDE.md always wins, no document omission)
- CLAUDE.md governance (structure, sections, owners, update triggers)
- CLAUDE.md update rules (version gating, phase lock, deviation recording before implementation, no arbitrary additions, no invented architecture, no behavioural rules)
- Codebase conventions (directory architecture, naming, comments, source-of-truth hierarchy, spec version tracking)
- Prompt templates (new module, test writing, bug fix, refactoring)
- Verification checkpoints (structural, behavioural, data integrity, performance)
- Session workflow (7-step sequence: operator setup, Claude Code execution, verification)
- Session summary format (phase, task, files, tests, deviations, stubs, issues)

### Entity Structure Conflict Rule
- When S06 and TD-02 diverge on entity definitions (nullability, defaults, column types, constraints), TD-02 governs

### Source-of-Truth Hierarchy
- 1 (lowest): Product Specification (S00-S17)
- 2: Technical Design documents (TD-01-TD-08)
- 3: CLAUDE.md Known Deviations
- 4 (highest): Operator instruction in current session
- S00 (Canonical Definitions) governs terminology at all levels

### CLAUDE.md Sections Defined
- Project Identity
- Spec Version Registry
- Source-of-Truth Hierarchy
- Current Build Phase
- Directory Architecture
- Naming Conventions
- Code Comment Conventions
- Design Token Reference
- Error Handling Quick Reference
- Phase Completion Log
- Known Deviations

### Naming Conventions
- Dart files: snake_case.dart, one public class per file
- Dart classes: UpperCamelCase with purpose suffix (Repository, Provider, Service, Widget, State, Exception)
- Dart functions: lowerCamelCase, verb-first for actions, noun-first for getters
- Dart variables: lowerCamelCase, no abbreviations except id/url/dto
- Dart constants: lowerCamelCase with k prefix (kMaxWindowOccupancy)
- Riverpod providers: lowerCamelCase + Provider suffix
- Drift tables: UpperCamelCase plural for table class
- Database columns: UpperCamelCase (UserID, CompletionTimestamp)
- Supabase RPCs: snake_case verb_noun (sync_upload, sync_download)
- Test files: snake_case_test.dart
- JSON keys: camelCase per TD-03 section 9
- Feature branches: phase/N-short-description

### Code Comment Conventions
- Spec reference: // Spec: S07 section 7.2 -- Reflow trigger: anchor edit
- TD reference: // TD-04 section 3.2 Step 4 -- Scope determination
- Deviation note: // DEVIATION: [description]. See CLAUDE.md Known Deviations.
- Phase stub: // Phase 3 stub -- replaced in Phase 5 (completion matching)
- Non-obvious logic: explanatory comment for complex business logic
- No comment required for standard CRUD, obvious idioms, self-descriptive methods

### Verification Checkpoints
- **Structural**: files in correct directories, naming conventions, no future-phase code, stubs present, no orphan files, no invented architecture
- **Behavioural**: acceptance criteria met, required tests pass 100%, spec rule compliance, state machine guard enforcement, error handling present
- **Data Integrity**: DDL alignment, seed data completeness, sync column presence, materialised table isolation, JSON payload shape compliance, DTO-to-DDL consistency
- **Performance**: hard phase gates (Phase 1: launch <3s; Phase 2.5: RLS <50ms; Phase 2B: reflow <150ms p95, rebuild <1s p95, heap <=256MB; Phase 6: cold-start <1s; Phase 7A: RLS at 100K <200ms)

### Prompt Templates
- New Module Prompt (phase context, task, spec references, conventions, stubs, acceptance criteria, output format)
- Test Writing Prompt (phase context, test source, test framework, precision, fixtures, coverage)
- Bug Fix Prompt (symptom, expected behaviour, reproduction, scope constraint, verification)
- Refactoring Prompt (motivation, scope, invariant, conventions, output)

### Context Loading Table (Phase -> Documents)
- Phase 1: S15, S16, TD-02 full; S06 full, TD-03 extracts, TD-07 Phase 1 extract
- Phase 2A: S01, S02, TD-05 section 4-9; S14 anchor table extract
- Phase 2.5: S16, TD-02 full; S17 sync extracts, TD-03 section 5, TD-03 section 8, TD-07 section 6/9
- Phase 2B: S07, TD-04 section 3-4, TD-05 section 10-12; TD-03 section 4, TD-07 section 5, S16 section 16.1.6
- Phase 3: S04, S09, S14; TD-03 section 3.3.2/3.3.5, TD-04 section 2.4-2.5/2.10, TD-07 section 4
- Phase 4: S03, S13, S14; S04, S11 section 11.1-11.6, TD-03 section 3.3.3/4.4, TD-04 section 2.1-2.3, TD-07 section 4/13
- Phase 5: S08; TD-03 section 3.3.6, TD-04 section 2.6/2.8-2.9, TD-07 section 4
- Phase 6: S05, S12, S15; TD-03 section 3.3.4, S16 section 16.1.6
- Phase 7A: S17; TD-03 section 5, TD-07 section 6, TD-01 section 2
- Phase 7B: S17, TD-04 full; TD-01 section 2.3-2.6, TD-03 section 5.4-5.5, TD-07 section 6/8
- Phase 7C: S17, S15; TD-01 section 2.9/3.3, TD-07 section 6/9/12
- Phase 8: S10, S11, S15; S12, S17 section 17.3.5, TD-07 section 7/13/14, TD-06 section 18-19

### External Dependencies Referenced
- Flutter SDK (test package, code generation)
- Dart language (ProcessInfo for heap monitoring)
- Supabase client SDK
- Google Fonts (Manrope)
- Android TalkBack (accessibility)
- Pixel 5a emulator (performance baseline)

---

*End of TD Reference Catalogue*
