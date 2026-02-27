TD-03 API Contract Layer — Phase 1 Extract (TD-03v.a5)
Sections: §2.1.1 SyncWriteGate, §2.2 Repository Layer Principles, §3.1 Repository Organisation, §3.2 Entity CRUD Operations
============================================================

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

