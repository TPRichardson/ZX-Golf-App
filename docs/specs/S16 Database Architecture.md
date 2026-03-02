Section 16 — Database Architecture

Version 16v.a5 — Canonical

This document defines the canonical Database Architecture for ZX Golf App. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 3 (User Journey Architecture 3v.g7), Section 4 (Drill Entry System 4v.g8), Section 5 (Review 5v.d6), Section 6 (Data Model & Persistence Layer 6v.b7), Section 7 (Reflow Governance System 7v.b9), Section 8 (Practice Planning Layer 8v.a8), Section 9 (Golf Bag & Club Configuration 9v.a2), Section 10 (Settings & Configuration 10v.a5), Section 11 (Metrics Integrity & Safeguards 11v.a5), Section 13 (Live Practice Workflow 13v.a6), Section 14 (Drill Entry Screens & System Drill Library 14v.a4), and the Canonical Definitions (0v.f1). This specification is technology-agnostic but assumes a relational database engine with support for JSON columns, row-level security policies, and standard ACID transactions.

16.1 Relational Schema Design

Section 6 defines the logical data model. Section 16 translates that model into a physical relational schema. The schema is organised into five table groups: Source Tables (authoritative user data), Reference Tables (system-defined configuration), Planning Tables (calendar and scheduling), Materialised Tables (derived scoring cache), and System Tables (locks, audit, maintenance).

16.1.1 Design Principles

-   All tables use UUID primary keys for portability and conflict-free generation across devices.

-   All tables carry CreatedAt (UTC) and UpdatedAt (UTC) timestamps, auto-populated by the database.

-   Soft-deleted entities use an IsDeleted boolean flag. Database-layer filtering (row-level policies or filtered views) ensures soft-deleted rows are invisible to standard queries. Explicit unfiltered access is available for audit, recovery, and reflow operations.

-   JSON columns are used for structured-but-bounded fields that are always read and written atomically: Anchors, RawMetrics, Routine entries, Schedule entries, CalendarDay Slots, and PracticeBlock DrillOrder.

-   All foreign keys use UUID references with named constraints.

-   Nullable fields are explicitly marked. All other fields are NOT NULL by default.

16.1.2 Enumeration Strategy

Enumerations are enforced at the database level using a hybrid strategy:

Stable Enumerations (Native Enum Types or Check Constraints)

The following enumerations are architecturally fixed and enforced via native database enum types or CHECK constraints. Adding a value requires a schema migration.

  ------------------------------------------------------------------------------------------------------------------------------------------
  Enumeration          Values                                                                            Rationale
  -------------------- --------------------------------------------------------------------------------- -----------------------------------
  SkillArea            Driving, Irons, Putting, Pitching, Chipping, Woods, Bunkers                       Fixed to canonical 7 (Section 2)

  DrillType            TechniqueBlock, Transition, Pressure                                              Fixed to canonical 3 (Section 4)

  ScoringMode          Shared, MultiOutput                                                               Fixed to canonical 2 (Section 4)

  InputMode            GridCell, ContinuousMeasurement, RawDataEntry, BinaryHitMiss                      Fixed to canonical 4 (Section 4)

  GridType             ThreeByThree, OneByThree, ThreeByOne                                              Fixed to canonical 3 (Section 4)

  ClubType             36 types (Driver, W1–W9, H1–H9, i1–i9, PW, AW, GW, SW, UW, LW, Chipper, Putter)   Fixed to canonical 36 (Section 9)

  DrillOrigin          System, UserCustom                                                                Fixed to canonical 2 (Section 4)

  DrillStatus          Active, Retired, Deleted                                                          Fixed to canonical 3 (Section 4)

  SessionStatus        Active, Closed, Discarded                                                         Fixed to canonical 3 (Section 3)

  ClubSelectionMode    Random, Guided, UserLed                                                           Fixed to canonical 3 (Section 9)

  TargetDistanceMode   Fixed, ClubCarry, PercentageOfClubCarry                                           Fixed to canonical 3 (Section 4)

  TargetSizeMode       Fixed, PercentageOfTargetDistance                                                 Fixed to canonical 2 (Section 4)

  CompletionState      Incomplete, CompletedLinked, CompletedManual                                      Fixed to canonical 3 (Section 8)

  SlotOwnerType        Manual, RoutineInstance, ScheduleInstance                                         Fixed to canonical 3 (Section 8)

  ClosureType          Manual, AutoClosed                                                                Fixed to canonical 2 (Section 3)

  AdoptionStatus       Active, Retired                                                                   Fixed to canonical 2 (Section 4)

  ScheduleAppMode      List, DayPlanning                                                                 Fixed to canonical 2 (Section 8)

  PracticeEntryType    PendingDrill, ActiveSession, CompletedSession                                     Fixed to canonical 3 (Section 13)

  UserClubStatus       Active, Retired                                                                   Fixed to canonical 2 (Section 9)

  RoutineStatus        Active, Retired, Deleted                                                          Fixed to canonical 3 (Section 8)

  ScheduleStatus       Active, Retired, Deleted                                                          Fixed to canonical 3 (Section 8)
  ------------------------------------------------------------------------------------------------------------------------------------------

Extensible Enumerations (Reference Tables)

The following enumerations may grow as the system evolves and are enforced via reference lookup tables with foreign key relationships. EventType uses a reference table for deployment flexibility (adding a new type requires an INSERT, not a schema migration), but this does not grant unconstrained extensibility. All EventType values must trace back to the canonical enumeration defined in Section 7 (§7.9). No EventType may be added to the reference table without first being specified in Section 7.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Reference Table   Current Values                                                                                                                                                                                                                                       Rationale
  ----------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------
  EventType         AnchorEdit, InstanceEdit, InstanceDeletion, SessionDeletion, SessionAutoDiscarded, PracticeBlockDeletion, DrillDeletion, SystemParameterChange, ReflowFailed, ReflowReverted, IntegrityFlagRaised, IntegrityFlagCleared, IntegrityFlagAutoResolved   Section 7 (§7.9) defines the canonical enumeration but explicitly states that other sections extend it

  MetricSchema      System-defined schemas with InputMode, HardMinInput, HardMaxInput, validation rules, scoring adapter binding                                                                                                                                         New schemas may be introduced in future versions (e.g. new drill types)
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.1.3 Source Tables

Source tables contain authoritative user data. These are the single source of truth for all scoring calculations and system behaviour.

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table                      Section Reference   Key Fields                                                                                                                                                                                                                                                                            Notes
  -------------------------- ------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -------------------------------
  User                       §6.2                UserID (PK), Timezone, WeekStartDay, UnitPreferences (JSON)                                                                                                                                                                                                                           Top-level scoping entity

  Drill                      §6.2                DrillID (PK), UserID (FK nullable), Name, SkillArea, DrillType, ScoringMode, InputMode, MetricSchemaID (FK), GridType, SubskillMapping (JSON), ClubSelectionMode, TargetDistance*, TargetSize*, RequiredSetCount, RequiredAttemptsPerSet, Anchors (JSON), Origin, Status, IsDeleted   Covers System and User Custom

  PracticeBlock              §6.2                PracticeBlockID (PK), UserID (FK), SourceRoutineID (FK nullable), DrillOrder (JSON), StartTimestamp, EndTimestamp, ClosureType, IsDeleted                                                                                                                                             Persisted only if ≥1 Session

  PracticeEntry              §13.3.1             PracticeEntryID (PK), PracticeBlockID (FK), PositionIndex, EntryType, DrillID (FK), SessionID (FK nullable)                                                                                                                                                                           Live Practice queue

  Session                    §6.2                SessionID (PK), DrillID (FK), PracticeBlockID (FK), CompletionTimestamp, Status, IntegrityFlag, IntegritySuppressed, UserDeclaration, SessionDuration, IsDeleted                                                                                                                      Atomic scoring unit

  Set                        §6.2                SetID (PK), SessionID (FK), SetIndex, IsDeleted                                                                                                                                                                                                                                       Sequential container

  Instance                   §6.2                InstanceID (PK), SetID (FK), SelectedClub (FK), RawMetrics (JSON), Timestamp, ResolvedTargetDistance, ResolvedTargetWidth, ResolvedTargetDepth, IsDeleted                                                                                                                             Atomic attempt

  UserDrillAdoption          §6.2                UserDrillAdoptionID (PK), UserID (FK), DrillID (FK), Status                                                                                                                                                                                                                           System Drill adoption

  UserClub                   §9.11.1             ClubID (PK), UserID (FK), ClubType, Make, Model, Loft, Status                                                                                                                                                                                                                         Bag configuration

  ClubPerformanceProfile     §9.11.1             ProfileID (PK), ClubID (FK), EffectiveFromDate, CarryDistance, DispersionLeft/Right/Short/Long                                                                                                                                                                                        Time-versioned

  UserSkillAreaClubMapping   §9.11.1             MappingID (PK), UserID (FK), SkillArea, ClubType, IsMandatory                                                                                                                                                                                                                         Club eligibility
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.1.4 Reference Tables

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table           Purpose                             Key Fields                                                                                                        Mutability
  --------------- ----------------------------------- ----------------------------------------------------------------------------------------------------------------- ---------------------------------------
  MetricSchema    System-defined metric schemas       MetricSchemaID (PK), Name, InputMode, HardMinInput, HardMaxInput, ValidationRules (JSON), ScoringAdapterBinding   System-only. Immutable to users

  EventTypeRef    Extensible event type enumeration   EventTypeID (PK), Name, Description                                                                               System-only. Extended by new sections
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.1.5 Planning Tables

Planning tables use JSON array columns for Slots, Routine entries, and Schedule entries. This is a deliberate architectural tradeoff:

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Advantage                                                                                                Tradeoff
  -------------------------------------------------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Atomic read/write: Slots are always accessed as a complete day, never queried individually across days   Referential integrity for Drill references within JSON is enforced at the application layer, not by database-level foreign keys

  Schema simplicity: no join-heavy Slot table with millions of rows                                        Cross-Slot aggregate queries (e.g. 'all Slots referencing DrillID X across all days') require JSON operators rather than simple WHERE clauses

  Matches the logical model defined in Section 6 directly                                                  Future normalisation path: if Slot-level queries become a dominant pattern, a dedicated Slot table can be introduced alongside the JSON column (dual-write migration)

  Bounded array sizes: SlotCapacity per day is small (default 5, rarely exceeds 10–15)                     Application layer must handle cascade cleanup when a Drill is deleted or retired (clearing Slots that reference it)
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

This tradeoff is appropriate for V1. The normalisation path (dedicated Slot table) is available as a future scaling lever if cross-day Slot queries become a performance requirement.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table              Section Reference   Key Fields                                                                                              Notes
  ------------------ ------------------- ------------------------------------------------------------------------------------------------------- --------------------------------------
  CalendarDay        §8.13.1             UserID (FK), Date, SlotCapacity, Slots (JSON array)                                                     Sparse storage with default fallback

  Routine            §6.2, §8.1.2        RoutineID (PK), UserID (FK), Name, Entries (JSON array), Status, IsDeleted                              Mixed fixed + criteria entries

  Schedule           §6.2, §8.1.3        ScheduleID (PK), UserID (FK), Name, ApplicationMode, Entries/TemplateDays (JSON), Status, IsDeleted     List or DayPlanning mode

  RoutineInstance    §8.2.4              RoutineInstanceID (PK), RoutineID (FK nullable), UserID (FK), CalendarDayDate, OwnedSlots (JSON)        Application tracking

  ScheduleInstance   §8.2.5              ScheduleInstanceID (PK), ScheduleID (FK nullable), UserID (FK), StartDate, EndDate, OwnedSlots (JSON)   Application tracking
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.1.6 Materialised Tables

Materialised tables store derived scoring state computed during reflow. They are a replaceable cache, not a source of truth (Section 7, §7.11.1). They may be truncated and fully rebuilt from raw Instance data and the canonical scoring model at any time.

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table                        Purpose                                                  Key Fields                                                                                                                                                                 Rebuild Source
  ---------------------------- -------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------
  MaterialisedWindowState      Current window contents per subskill per practice type   UserID, SkillArea, Subskill, PracticeType (Transition/Pressure), Entries (JSON: ordered list of SessionID, score, occupancy), TotalOccupancy, WeightedSum, WindowAverage   Instance data + Drill anchors + occupancy rules

  MaterialisedSubskillScore    Current subskill weighted averages and point values      UserID, SkillArea, Subskill, TransitionAverage, PressureAverage, WeightedAverage, SubskillPoints, Allocation                                                               MaterialisedWindowState + 65/35 weighting + allocation

  MaterialisedSkillAreaScore   Current skill area scores                                UserID, SkillArea, SkillAreaScore, Allocation                                                                                                                              Sum of child MaterialisedSubskillScore.SubskillPoints

  MaterialisedOverallScore     Current overall score                                    UserID, OverallScore                                                                                                                                                       Sum of all MaterialisedSkillAreaScore.SkillAreaScore
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

All materialised tables are keyed by UserID. During reflow, the affected rows are recomputed in isolation and swapped atomically (Section 7, §7.7). No partial materialised state is ever visible to the user.

16.1.7 System Tables

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table                   Purpose          Key Fields                                                                                                                                                                   Notes
  ----------------------- ---------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------
  EventLog                §6.2, §7.9       EventLogID (PK), UserID (FK), DeviceID (UUID, nullable, FK → UserDevice), EventTypeID (FK), Timestamp, AffectedEntityIDs (JSON), AffectedSubskills (JSON), Metadata (JSON)   Append-only. No updates or deletions. Cold storage archival policy applies (§16.7.4)

  UserDevice              §17.4.1, §17.9   DeviceID (PK, UUID), UserID (FK), DeviceLabel (string, nullable), RegisteredAt (UTC), LastSyncAt (UTC, nullable)                                                             Sync infrastructure. No scoring impact. Deregistration removes from sync roster only.

  UserScoringLock         §16.4.3          UserID (PK), IsLocked, LockedAt, LockExpiresAt                                                                                                                               Application-level scoring lock per user

  SystemMaintenanceLock   §16.4.4          LockID (PK), IsActive, ActivatedAt, Reason                                                                                                                                   System-wide maintenance flag. Single-row table
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.2 Entity Relationships

All foreign key relationships are documented below with their cascade and referential integrity behaviour. Relationships are grouped by domain.

16.2.1 Core Execution Chain

The core execution chain follows the runtime hierarchy: User → PracticeBlock → Session → Set → Instance.

  ---------------------------------------------------------------------------------------------------------------------------------------------------
  Parent          Child           FK on Child                     On Parent Soft-Delete                On Parent Hard-Delete
  --------------- --------------- ------------------------------- ------------------------------------ ----------------------------------------------
  User            PracticeBlock   PracticeBlock.UserID            N/A (User deletion is hard delete)   Cascade hard-delete all child PracticeBlocks

  PracticeBlock   PracticeEntry   PracticeEntry.PracticeBlockID   Cascade soft-delete                  Cascade hard-delete

  PracticeBlock   Session         Session.PracticeBlockID         Cascade soft-delete                  Cascade hard-delete

  Session         Set             Set.SessionID                   Cascade soft-delete                  Cascade hard-delete

  Set             Instance        Instance.SetID                  Cascade soft-delete                  Cascade hard-delete
  ---------------------------------------------------------------------------------------------------------------------------------------------------

16.2.2 Drill Relationships

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parent         Child               FK on Child                 On Parent Delete/Retire                            Notes
  -------------- ------------------- --------------------------- -------------------------------------------------- -------------------------------------------------
  Drill          Session             Session.DrillID             Session retains reference (historical integrity)   Sessions reference the Drill active at creation

  Drill          PracticeEntry       PracticeEntry.DrillID       PracticeEntry retains reference                    DrillID is immutable on PracticeEntry

  Drill          UserDrillAdoption   UserDrillAdoption.DrillID   Adoption record governs lifecycle                  System Drills only

  MetricSchema   Drill               Drill.MetricSchemaID        N/A (schemas are system-immutable)                 Reference table FK
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.2.3 Club Relationships

  --------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parent      Child                    FK on Child             On Parent Retire/Delete                           Notes
  ----------- ------------------------ ----------------------- ------------------------------------------------- -----------------------------------------------
  UserClub    Instance                 Instance.SelectedClub   Reference preserved (soft reference if deleted)   Deletion blocked if Instance references exist

  UserClub    ClubPerformanceProfile   Profile.ClubID          Profiles deleted on hard-delete                   Time-versioned data
  --------------------------------------------------------------------------------------------------------------------------------------------------------------

16.2.4 Planning Relationships

  --------------------------------------------------------------------------------------------------------------------------------------------------
  Parent     Child                 FK on Child                   On Parent Delete/Retire              Notes
  ---------- --------------------- ----------------------------- ------------------------------------ ----------------------------------------------
  Routine    RoutineInstance       RoutineInstance.RoutineID     FK set to null. Instance persists.   Instance is self-sufficient

  Schedule   ScheduleInstance      ScheduleInstance.ScheduleID   FK set to null. Instance persists.   Instance is self-sufficient

  Drill      Routine (entries)     Routine.Entries JSON          Entry auto-removed from JSON array   Routine auto-deleted if entries empty

  Drill      Schedule (entries)    Schedule.Entries JSON         Entry auto-removed from JSON array   Schedule auto-deleted if all entries removed

  Drill      CalendarDay (slots)   CalendarDay.Slots JSON        Slot cleared immediately             Owning instance loses that slot position
  --------------------------------------------------------------------------------------------------------------------------------------------------

16.2.5 Referential Integrity Rules

-   No orphaned Sessions: every Session must reference a valid PracticeBlock.

-   No orphaned Sets: every Set must reference a valid Session.

-   No orphaned Instances: every Instance must reference a valid Set.

-   No orphaned PracticeEntries: every PracticeEntry must reference a valid PracticeBlock.

-   UserClub deletion is blocked (not cascaded) when Instance references exist, enforcing the Section 9 (§9.7.2) rule that clubs with historical data may only be retired.

-   Routine and Schedule source references on RoutineInstance/ScheduleInstance are nullable, allowing the instance to survive source deletion.

-   JSON-embedded references (Routine entries, Schedule entries, CalendarDay Slots) are maintained by application-layer cascade logic, not database-level foreign keys. The application is responsible for cleaning these references on Drill deletion or retirement.

16.3 Indexing Strategy

Indexes are designed to support the dominant query patterns identified across the specification. Every query is user-scoped (Section 6, §6.4), so UserID is a leading key in most composite indexes.

16.3.1 Primary Key Indexes

All tables have a UUID primary key index. These are created automatically by the database engine.

16.3.2 Core Query Indexes

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Table           Index                         Columns                                                               Purpose
  --------------- ----------------------------- --------------------------------------------------------------------- --------------------------------------------------------------------------------
  Session         ix_session_drill_completion   DrillID, CompletionTimestamp DESC                                     Window construction: fetch all Sessions for a Drill ordered by completion time

  Session         ix_session_practiceblock      PracticeBlockID                                                       PracticeBlock child lookup

  Session         ix_session_user_completion    PracticeBlock.UserID (via join or denorm), CompletionTimestamp DESC   Completion matching and chronological session history

  Session         ix_session_status             Status (partial: Active only)                                         Active Session enforcement (single active Session per user)

  Instance        ix_instance_set               SetID                                                                 Set child lookup

  Instance        ix_instance_timestamp         SetID, Timestamp ASC                                                  Chronological instance ordering within a Set

  Set             ix_set_session                SessionID, SetIndex ASC                                               Session child lookup in order

  PracticeBlock   ix_pb_user_start              UserID, StartTimestamp DESC                                           Recent practice history

  PracticeEntry   ix_pe_practiceblock_pos       PracticeBlockID, PositionIndex ASC                                    Queue ordering

  PracticeEntry   ix_pe_session                 SessionID (partial: non-null only)                                    Session lookup (sparse)
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.3.3 Equipment & Mapping Indexes

  -----------------------------------------------------------------------------------------------------------------------------------
  Table                      Index                       Columns                          Purpose
  -------------------------- --------------------------- -------------------------------- -------------------------------------------
  UserClub                   ix_userclub_user            UserID                           Bag queries

  ClubPerformanceProfile     ix_clubprofile_club_date    ClubID, EffectiveFromDate DESC   Active profile resolution

  UserSkillAreaClubMapping   ix_mapping_user_skillarea   UserID, SkillArea                Eligible club lookups

  Instance                   ix_instance_selectedclub    SelectedClub                     Club usage tracking and deletion blocking
  -----------------------------------------------------------------------------------------------------------------------------------

16.3.4 Planning Indexes

  ------------------------------------------------------------------------------------------------------------------------------------
  Table               Index                     Columns                                 Purpose
  ------------------- ------------------------- --------------------------------------- ----------------------------------------------
  CalendarDay         ix_calday_user_date       UserID, Date (unique composite)         Day lookup and sparse storage

  RoutineInstance     ix_ri_user_date           UserID, CalendarDayDate                 Day-level routine instance lookup

  ScheduleInstance    ix_si_user_daterange      UserID, StartDate, EndDate              Date range overlap queries

  Routine             ix_routine_user           UserID                                  User routine library

  Schedule            ix_schedule_user          UserID                                  User schedule library

  Drill               ix_drill_user_skillarea   UserID, SkillArea, Status               Practice Pool queries filtered by Skill Area

  Drill               ix_drill_system           Origin (partial: System only), Status   System Drill library queries

  UserDrillAdoption   ix_adoption_user          UserID, Status                          Adopted drill queries
  ------------------------------------------------------------------------------------------------------------------------------------

16.3.5 System Indexes

  ---------------------------------------------------------------------------------------------------------------
  Table        Index                        Columns                       Purpose
  ------------ ---------------------------- ----------------------------- ---------------------------------------
  EventLog     ix_eventlog_user_timestamp   UserID, Timestamp DESC        Audit trail queries

  EventLog     ix_eventlog_type_timestamp   EventTypeID, Timestamp DESC   Event type filtering

  EventLog     ix_eventlog_archival         Timestamp ASC                 Cold storage archival batch selection

  UserDevice   ix_userdevice_userid         UserID                        Device list per user

  EventLog     ix_eventlog_deviceid         DeviceID                      Device-origin audit queries
  ---------------------------------------------------------------------------------------------------------------

16.3.6 Foreign Key Index Governance

Most relational databases (including PostgreSQL) do not automatically create indexes on foreign key columns. Unindexed foreign keys cause full table scans on JOIN, CASCADE, and referential integrity checks. The following governance rule applies:

-   Every foreign key column must have a corresponding index. This includes: Instance.SetID, Instance.SelectedClub, Set.SessionID, Session.DrillID, Session.PracticeBlockID, PracticeBlock.UserID, PracticeEntry.PracticeBlockID, PracticeEntry.DrillID, PracticeEntry.SessionID, UserDrillAdoption.UserID, UserDrillAdoption.DrillID, UserClub.UserID, ClubPerformanceProfile.ClubID, UserSkillAreaClubMapping.UserID, Drill.MetricSchemaID, EventLog.EventTypeID, RoutineInstance.RoutineID, ScheduleInstance.ScheduleID, and UserScoringLock.UserID.

-   Where a FK column is the leading column of a composite index already defined in §16.3.2–16.3.5, no additional single-column index is required.

-   Where a FK column is not covered by an existing composite index, a dedicated single-column index must be created.

-   Migration governance (§16.5.3) must verify FK index coverage for every migration that introduces a new foreign key.

16.3.7 Soft-Delete Index Strategy

Row-level policies enforce soft-delete filtering at the database layer, eliminating the need for explicit IsDeleted conditions in application queries. For administrative and reflow operations that require access to soft-deleted rows, unfiltered queries bypass the row-level policy. Partial indexes on IsDeleted = false are recommended for tables with high soft-delete volume (Session, Instance) to keep index sizes efficient.

16.3.8 Materialised Table Indexes

  ----------------------------------------------------------------------------------------------------------------------------------------------
  Table                        Index                    Columns                                                        Purpose
  ---------------------------- ------------------------ -------------------------------------------------------------- -------------------------
  MaterialisedWindowState      ix_mws_user_subskill     UserID, SkillArea, Subskill, PracticeType (unique composite)   Window lookup

  MaterialisedSubskillScore    ix_mss_user_subskill     UserID, SkillArea, Subskill (unique composite)                 Subskill score lookup

  MaterialisedSkillAreaScore   ix_msas_user_skillarea   UserID, SkillArea (unique composite)                           Skill area score lookup

  MaterialisedOverallScore     ix_mos_user              UserID (unique, PK)                                            Overall score lookup
  ----------------------------------------------------------------------------------------------------------------------------------------------

16.4 Transaction Model

All database operations execute within explicit transactions with defined isolation levels. The transaction model ensures atomicity, consistency, and determinism as required by the scoring engine guarantees (Section 1, §1.18) and reflow governance (Section 7, §7.7).

16.4.1 Transaction Boundaries

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Operation                               Transaction Scope                                                           Isolation Level                                                  Notes
  --------------------------------------- --------------------------------------------------------------------------- ---------------------------------------------------------------- ----------------------------------------------------------------------------------------------
  Instance creation (active Session)      Single Instance insert                                                      Read Committed                                                   High-frequency, low-latency. No scoring side-effects during active Session

  Session close (structured completion)   Session status update + materialised state rebuild for affected subskills   Repeatable Read                                                  Lock table prevents concurrent reflows. Materialised swap is the only Serializable operation

  Session close (manual end)              Session status update + materialised state rebuild                          Repeatable Read                                                  Same model as structured completion

  Reflow (user-initiated)                 Lock acquisition + affected materialised table rebuild + lock release       Repeatable Read (Serializable for materialised swap step only)   Lock table serialises access. Atomic swap step uses Serializable

  Reflow (system-initiated)               Per-user: same as user-initiated. Global lock managed separately            Repeatable Read (Serializable for swap)                          Parallel execution with concurrency cap

  Instance edit (post-close)              Instance update + full reflow                                               Repeatable Read (Serializable for swap)                          Lock table prevents concurrent modification

  Session deletion                        Cascade soft-delete + full reflow                                           Repeatable Read (Serializable for swap)                          Lock table prevents concurrent modification

  Drill deletion                          Cascade soft-delete + full reflow + EventLog write                          Repeatable Read (Serializable for swap)                          Widest transaction scope

  PracticeBlock creation                  PracticeBlock insert + PracticeEntry inserts                                Read Committed                                                   No scoring impact

  Calendar Slot fill                      CalendarDay upsert with Slot JSON update                                    Read Committed                                                   No scoring impact

  Routine/Schedule application            CalendarDay upserts + Instance record creation                              Read Committed                                                   No scoring impact

  Completion matching                     CalendarDay Slot update (CompletionState + SessionID)                       Read Committed                                                   Triggered post-Session-close, separate transaction

  EventLog write                          Single append                                                               Read Committed                                                   Append-only, no contention
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16.4.2 Isolation Level Rationale

The majority of scoring operations use Repeatable Read rather than Serializable. This is sufficient because the UserScoringLock table (§16.4.3) already serialises all reflow operations at the application level. Concurrent reflows are structurally impossible when the lock is held. Serializable isolation is reserved exclusively for the materialised state atomic swap step within reflow, where the old derived state is replaced with the new derived state. This is the only moment where a phantom read could produce inconsistent scoring output.

This approach avoids throughput bottlenecks and phantom retry storms that full Serializable isolation can produce under concurrency, while preserving the atomicity guarantee that users never see partial scoring state.

16.4.3 User Scoring Lock

The UserScoringLock table implements the application-level scoring lock defined in Section 7 (§7.5). One row per user.

  --------------------------------------------------------------------------------------------------------
  Field           Type              Notes
  --------------- ----------------- ----------------------------------------------------------------------
  UserID          UUID (PK, FK)     References User. One row per user, created on first lock acquisition

  IsLocked        Boolean           True during active reflow

  LockedAt        Timestamp (UTC)   When the lock was acquired

  LockExpiresAt   Timestamp (UTC)   Hard timeout: LockedAt + 60 seconds
  --------------------------------------------------------------------------------------------------------

Lock Acquisition

-   Before any reflow, the application attempts to set IsLocked = true with an atomic conditional update (UPDATE ... WHERE IsLocked = false).

-   If the update affects zero rows, the lock is already held. The operation is rejected.

-   LockExpiresAt is set to LockedAt + 60 seconds (hard timeout per Section 7, §7.8).

Race Condition Safety

The atomic conditional UPDATE is safe against concurrent acquisition attempts: the database engine's row-level locking guarantees that only one process can successfully update the row from IsLocked = false to IsLocked = true. The second concurrent process sees the already-updated row and receives zero affected rows. This behaviour is inherent to row-level locking in all major relational databases.

For stale lock expiry races (two processes both detect an expired lock simultaneously), the same atomic UPDATE pattern applies: only one process wins the conditional update. Implementations requiring additional safety may use SELECT ... FOR UPDATE on the lock row before the conditional update, or enforce a partial unique index on (UserID) WHERE IsLocked = true.

Lock Release

-   On successful reflow completion: IsLocked = false, LockedAt and LockExpiresAt cleared.

-   On reflow failure (after retries): IsLocked = false, revert to previous valid state (Section 7, §7.7).

-   Stale lock recovery: a background process checks for locks where LockExpiresAt < NOW(). Any stale lock is force-released and logged as ReflowFailed in EventLog.

Implementation Note

Implementations using PostgreSQL may optionally use advisory locks (pg_advisory_xact_lock) as a performance enhancement. The application-level lock table remains the portable, technology-agnostic mechanism.

16.4.4 System Maintenance Lock

The SystemMaintenanceLock table is a single-row table controlling the global scoring lock for system-initiated reflows (Section 7, §7.5.1).

  ------------------------------------------------------------------------------------------------------
  Field           Type              Notes
  --------------- ----------------- --------------------------------------------------------------------
  LockID          UUID (PK)         Single row; pre-seeded on system initialisation

  IsActive        Boolean           True during system-wide reflow

  ActivatedAt     Timestamp (UTC)   When activated

  Reason          String            Description of the structural change (e.g. '65/35 weighting edit')
  ------------------------------------------------------------------------------------------------------

When IsActive = true, all user-facing scoring operations are blocked and the UI displays a maintenance banner. Per-user reflows execute in parallel with a concurrency cap. The lock is released when all user reflows complete.

16.4.5 Reflow Atomic Swap

Reflow executes under an atomic swap model (Section 7, §7.7). The transaction sequence is:

-   Acquire user scoring lock.

-   Compute new derived state from raw Instance data and canonical scoring model in isolation (temporary rows or in-memory). This step operates under Repeatable Read.

-   Within a single Serializable transaction scoped to the affected UserID: delete affected materialised rows (WHERE UserID = target user AND Subskill IN affected subskills), insert new materialised rows, update IntegritySuppressed flags if applicable, write EventLog entry. This is the only Serializable step. The DELETE and INSERT are always user-scoped to prevent lock escalation to the full materialised table.

-   Release user scoring lock.

If any step fails, the transaction rolls back. The previous materialised state remains authoritative. Retry logic (up to 3 attempts with short delay) executes before marking the reflow as failed (Section 7, §7.7).

16.4.6 Application-Layer Retry Behaviour

Transient database errors (connection drops, lock timeouts, serialisation failures) are handled at the application layer with a consistent retry model across all operations, not only reflow.

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Operation Category           Max Retries   Backoff Strategy                                 On Exhaustion
  ---------------------------- ------------- ------------------------------------------------ --------------------------------------------------------------------------------
  Instance creation            2             Immediate retry (no delay)                       Reject with user-facing error. No data loss risk.

  Session close + scoring      3             100ms, 200ms, 400ms (exponential)                Reject. Session remains Active. User may retry manually.

  Reflow (user-initiated)      3             Short delay between attempts (Section 7, §7.7)   Revert to previous valid state. User notified. EventLog: ReflowFailed.

  Reflow (system-initiated)    3 per user    Short delay between attempts                     Per-user failure logged. System lock released when all users complete or fail.

  Calendar / Planning writes   2             Immediate retry                                  Reject with user-facing error. No scoring impact.

  Read operations              1             Immediate                                        Return cached/stale data or error, depending on criticality
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Retry logic must be idempotent: re-executing the same operation with the same inputs produces the same result. For operations involving the user scoring lock, the lock acquisition step is included in the retry scope (if the lock was acquired and the operation failed, the lock is released before retry).

Row-Level Security and Retry Interaction

Under Repeatable Read isolation with row-level security policies, cross-user contention is structurally impossible because all queries are scoped to a single UserID. The only scenario where RLS-related contention can occur is system-initiated reflows affecting the same user from multiple processes. This is prevented by the per-user scoring lock, which ensures single-threaded reflow execution per user.

16.5 Migration Strategy

16.5.1 Migration Pattern

Schema changes follow a sequential numbered migration pattern. Each migration is a versioned, ordered file applied in strict sequence. Migration files are immutable once applied to any environment. The system is tool-agnostic but the pattern is compatible with standard migration frameworks (Supabase CLI, Flyway, Knex, Prisma Migrate, golang-migrate).

File Naming Convention

NNN_short_description.sql (e.g. 001_create_core_tables.sql, 002_add_planning_tables.sql, 003_add_integrity_fields.sql).

Migration File Structure

-   Each file contains a single logical change.

-   Each file includes both UP (apply) and DOWN (rollback) operations.

-   UP operations are idempotent where possible (IF NOT EXISTS).

-   DOWN operations reverse the UP operation completely.

-   Data migrations (backfills, transformations) are separate files from structural migrations.

16.5.2 Migration Categories

  ----------------------------------------------------------------------------------------------------------------------------------------------------
  Category               Examples                                        Rollback Risk                                      Requires Data Migration
  ---------------------- ----------------------------------------------- -------------------------------------------------- --------------------------
  Additive structural    New table, new column, new index                Low (DROP reverses)                                No

  Modifying structural   Column type change, constraint change           Medium (data loss possible on rollback)            Possibly

  Data migration         Backfill new column, transform JSON structure   High (data transformation may not be reversible)   Yes (by definition)

  Enum extension         Add value to reference table, add enum value    Low                                                No

  Destructive            Drop table, drop column, remove constraint      High (data loss)                                   Possibly (archive first)
  ----------------------------------------------------------------------------------------------------------------------------------------------------

16.5.3 Migration Governance

-   All migrations are reviewed before application.

-   Destructive migrations require explicit approval and a pre-migration backup.

-   Migrations that alter tables involved in reflow (Drill, Session, Instance, materialised tables) must be tested against the full reflow pipeline.

-   Migrations must not break the deterministic recalculability guarantee: after any migration, all scores must be reproducible from raw Instance data.

-   A migration log table tracks applied migrations with sequence number, filename, applied timestamp, and execution duration.

16.5.4 Zero-Downtime Migration Requirements

Schema changes must support zero-downtime deployment where possible. This is achieved by following an expand-contract pattern:

-   Expand: Add new columns/tables as nullable or with defaults. Deploy application code that writes to both old and new structures.

-   Migrate: Backfill new structures from existing data.

-   Contract: Remove old structures once all application code uses the new structures.

Each phase is a separate migration file. This ensures the application can serve traffic throughout the migration process.

16.6 Versioned Data Handling

The ZX Golf App system uses three distinct versioning patterns, each serving a different architectural purpose.

16.6.1 Time-Versioned Performance Data

ClubPerformanceProfile (Section 9, §9.5) uses insert-on-update time versioning. Each update creates a new row with a new EffectiveFromDate. Historical profiles are never modified or deleted. The active profile at any timestamp is resolved by: most recent EffectiveFromDate ≤ target timestamp.

Database Implementation

-   No UPDATE operations on ClubPerformanceProfile rows. All changes are INSERT.

-   The index on (ClubID, EffectiveFromDate DESC) supports efficient active profile resolution.

-   No cascading impact: carry distance changes do not trigger reflow. Target resolution is snapshot at Instance creation time.

16.6.2 Snapshot Data (Immutable Post-Creation)

Several fields are snapshot at creation time and never modified, ensuring historical integrity:

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Entity          Snapshot Fields                                                    Snapshot Trigger         Rationale
  --------------- ------------------------------------------------------------------ ------------------------ -------------------------------------------------------------------------------------
  Instance        ResolvedTargetDistance, ResolvedTargetWidth, ResolvedTargetDepth   Instance creation        User judged shot against the target displayed at the time (Section 9, §9.6)

  Instance        SelectedClub                                                       Instance creation        Records the actual club used for audit and target resolution

  PracticeBlock   DrillOrder (JSON)                                                  PracticeBlock creation   Creation-time snapshot; Live Practice queue governed by PracticeEntry

  Session         DrillID reference                                                  Session creation         Session references the Drill definition active at creation time (Section 3, §3.1.4)
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Snapshot fields are never modified by subsequent edits to their source entities. This is enforced by application-layer immutability, not database triggers. Engineers must not write UPDATE operations targeting snapshot fields.

Hardening Path

Application-layer governance is the V1 enforcement mechanism for snapshot immutability. For additional safety, implementations may add database-level BEFORE UPDATE triggers on Instance and PracticeBlock that reject any UPDATE operation targeting snapshot fields (ResolvedTargetDistance, ResolvedTargetWidth, ResolvedTargetDepth, SelectedClub on Instance; DrillOrder on PracticeBlock). This is optional and not required for V1, but eliminates reliance on engineering discipline for a critical integrity guarantee.

16.6.3 Structural Versioning via Reflow

The scoring engine uses a single canonical model with no version branching (Section 1, §1.15). When structural parameters change (anchors, allocations, weightings), the system does not store the old model. Instead, it performs a full deterministic recalculation (reflow) that rewrites all derived state from raw Instance data.

Implications for the Database

-   No version column on scoring parameters. There is always exactly one set of current parameters.

-   No historical scoring snapshots are stored. Previous scores exist only in EventLog metadata.

-   Materialised tables are fully replaced on each reflow. No incremental patching.

-   The EventLog provides the audit trail of what changed and when, with old and new values stored in the Metadata JSON field.

16.6.4 Metadata Edits (Unversioned)

UserClub metadata fields (Make, Model, Loft) are treated as if always true (Section 9, §9.7.3). Edits overwrite the existing value with no version history. These fields are descriptive only with no scoring impact.

16.7 Backup & Recovery

16.7.1 Recovery Objectives

  ----------------------------------------------------------------------------------------------
  Objective                        Target          Notes
  -------------------------------- --------------- ---------------------------------------------
  Recovery Point Objective (RPO)   15 minutes      Maximum acceptable data loss window

  Recovery Time Objective (RTO)    1 hour          Maximum acceptable service restoration time
  ----------------------------------------------------------------------------------------------

These targets are achievable at near-zero additional cost on managed database platforms (e.g. Supabase, AWS RDS, Google Cloud SQL) which provide continuous WAL archival and automated point-in-time recovery as built-in features. On self-hosted infrastructure, achieving the 15-minute RPO requires explicit WAL archival configuration and monitoring.

16.7.2 Backup Strategy

Continuous Backup (Primary)

-   Write-Ahead Log (WAL) archival or equivalent continuous replication mechanism.

-   WAL segments archived to durable off-site storage at minimum every 15 minutes.

-   Enables Point-in-Time Recovery (PITR) to any moment within the retention window.

Full Base Backups (Secondary)

-   Full database snapshot taken daily during lowest-traffic window.

-   Base backups retained for 30 days.

-   Base backup + WAL replay provides PITR capability.

Logical Backups (Tertiary)

-   Weekly logical export (pg_dump equivalent) for portability and disaster recovery.

-   Stored in a separate geographic region from primary and WAL storage.

-   Retained for 90 days.

16.7.3 Recovery Procedures

Scenario 1: Instance-Level Recovery (Single Row Corruption)

-   Use PITR to restore a parallel instance to the target timestamp.

-   Extract the affected rows from the parallel instance.

-   Apply corrective inserts/updates to the production database.

-   Trigger reflow if scoring data was affected.

Scenario 2: Table-Level Recovery

-   Restore from most recent base backup + WAL replay to target timestamp.

-   Validate materialised state against raw Instance data.

-   Trigger full reflow for affected users if materialised state is inconsistent.

Scenario 3: Full Database Recovery

-   Restore from most recent base backup + WAL replay.

-   Verify referential integrity across all tables.

-   Trigger system-wide reflow to rebuild all materialised state.

-   Target: service restored within 1 hour (RTO).

Scenario 4: Materialised State Corruption Only

-   No backup restore required.

-   Truncate all materialised tables.

-   Execute full reflow from raw Instance data for all affected users.

-   This scenario validates the “replaceable cache” architecture (Section 7, §7.11.1).

16.7.4 EventLog Archival

The EventLog uses a tiered storage model:

  -------------------------------------------------------------------------------------------------------------------
  Tier      Retention     Storage Type                          Access Pattern
  --------- ------------- ------------------------------------- -----------------------------------------------------
  Hot       6 months      Primary database                      Full query capability. Standard indexes apply

  Cold      Indefinite    Object storage (e.g. S3-compatible)   Batch retrieval only. Compressed JSON export format
  -------------------------------------------------------------------------------------------------------------------

Archival Process

-   A scheduled job runs daily and moves EventLog rows older than 6 months to cold storage.

-   Rows are exported in compressed JSON format, partitioned by UserID and month.

-   After successful export verification, archived rows are hard-deleted from the primary database.

-   The archival process is idempotent: re-running it does not duplicate cold storage entries.

-   Cold storage data is available for compliance, audit, and support investigations. It is not required for any runtime operation.

Archival and Entity Purge Dependency

EventLog entries in cold storage reference entity IDs (DrillID, SessionID, InstanceID) in their AffectedEntityIDs and Metadata fields. If soft-deleted source entities are permanently purged after the 90-day retention period (§16.8.5), these references become dangling: the EventLog records the historical event, but the referenced entity no longer exists in the primary database. This is acceptable by design: the EventLog is a historical audit record, not a live lookup mechanism. The Metadata JSON field contains sufficient detail (old and new values, entity context) for the event to be interpretable without resolving the referenced entity. Cold storage retention must be treated as the authoritative long-term audit trail once source entities are purged.

16.7.5 Backup Validation

-   Automated weekly backup restore test to a staging environment.

-   Validation includes: referential integrity check, row count comparison against production, sample reflow execution to verify scoring determinism, materialised state consistency check.

-   Backup validation failures generate operational alerts.

16.8 Performance Scaling

16.8.1 Multi-Tenancy Model

All users share the same database tables. Multi-tenancy isolation is enforced via row-level security policies (or equivalent database-layer filtering) keyed on UserID. Every query is user-scoped (Section 6, §6.4). No cross-user data access is permitted through standard application queries.

Row-Level Policy Enforcement

-   Every user-scoped table has a row-level policy: SELECT, INSERT, UPDATE, DELETE restricted to rows WHERE UserID = authenticated_user_id.

-   System Drills (Drill.UserID IS NULL) are readable by all users but not writable.

-   Materialised tables are user-scoped and follow the same policy.

-   EventLog is user-scoped for standard queries. Administrative queries bypass policies for support operations.

16.8.2 Query Performance Targets

  ----------------------------------------------------------------------------------------------------
  Operation                    Target Latency   Notes
  ---------------------------- ---------------- ------------------------------------------------------
  Instance creation (single)   < 50ms           High-frequency during active practice

  Session close + scoring      < 200ms          Includes materialised state update

  Window state read            < 50ms           Materialised table lookup

  Overall score read           < 20ms           Single-row materialised lookup

  User-initiated reflow        < 1 second       Target per Section 7 (§7.8). Hard timeout 60s

  Calendar day read            < 50ms           Single-row lookup with JSON Slot array

  Drill library query          < 100ms          Filtered by SkillArea, DrillType, Status

  Analysis trend query         < 500ms          Aggregate query over Session history with date range

  Completion matching          < 100ms          Post-Session-close CalendarDay Slot update
  ----------------------------------------------------------------------------------------------------

16.8.3 Scaling Levers

The following scaling mechanisms are available as user and data volumes grow. They are listed in order of implementation priority.

Tier 1: Index Optimisation (Immediate)

-   All indexes defined in §16.3 are deployed from launch.

-   Partial indexes on soft-deleted tables (IsDeleted = false) reduce index scan volume.

-   JSON column indexes (GIN indexes on Slots, RawMetrics) are added only if JSON query performance degrades.

Tier 2: Connection Pooling

-   Connection pooler (e.g. PgBouncer, Supabase built-in pooler) for efficient connection management.

-   Transaction-mode pooling for short-lived queries. Session-mode pooling for operations requiring prepared statements.

Tier 3: Read Replicas

-   Read-heavy operations (Analysis trend queries, SkillScore display, Drill library browsing, Calendar reads) routed to read replicas.

-   Write operations (Instance logging, Session management, reflow) remain on primary.

-   Materialised table reads can tolerate slight replication lag (sub-second) since they represent a point-in-time snapshot.

Tier 4: Table Partitioning

-   Instance table partitioned by UserID if row counts exceed performance thresholds. Instance is the highest-volume table (10 Instances per Session minimum for structured drills).

-   EventLog partitioned by Timestamp for efficient archival queries.

-   Session table partitioned by UserID if warranted by growth.

Tier 5: Materialised State Caching

-   Application-level cache (e.g. Redis) for frequently accessed materialised scores (Overall Score, Skill Area Scores).

-   Cache invalidated on reflow completion.

-   Cache miss falls through to materialised table read (still fast).

16.8.4 Volume Projections

The following estimates inform scaling decisions. Projections assume a moderately active user base.

  ---------------------------------------------------------------------------------------------------------------
  Metric                     Per User (Annual)   Notes
  -------------------------- ------------------- ----------------------------------------------------------------
  Sessions                   500–1,500           3–5 drills per practice, 2–4 practices per week

  Instances                  5,000–15,000        10 Instances per structured Session

  CalendarDays (persisted)   200–365             Depends on planning engagement

  EventLog entries           50–200              Anchored to edit and deletion frequency

  Materialised rows          ~40                 Fixed: 1 overall + 7 skill areas + ~19 subskills + ~38 windows
  ---------------------------------------------------------------------------------------------------------------

The fixed window cap of 25 occupancy units per subskill per practice type (Section 1, §1.6) places a hard ceiling on reflow computation volume regardless of user history length. This is the primary architectural guarantee enabling sub-1-second reflow targets.

16.8.5 Data Retention

Active user data is retained indefinitely. The system does not purge historical Sessions, Instances, or CalendarDays for active users. Users may export their data (Section 10, §10.11) or request full account deletion.

Soft-deleted data is retained in the primary database for a configurable period (default: 90 days) to support recovery and audit. After the retention period, soft-deleted rows may be permanently purged by a background cleanup process. Purging soft-deleted rows does not trigger reflow (the scoring engine already treats them as non-existent).

16.8.6 Connection Management

The database must be accessed through a connection pooler in all environments. Direct connections are prohibited for application traffic.

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Parameter                                      Baseline Value               Notes
  ---------------------------------------------- ---------------------------- -----------------------------------------------------------------------------------------
  Maximum pool size (per application instance)   20 connections               Sufficient for V1 single-instance deployment. Scale with application instances.

  Minimum idle connections                       5                            Avoids cold-start latency on first requests after idle periods

  Connection timeout                             5 seconds                    Maximum wait time to acquire a connection from the pool. Reject with error if exceeded.

  Idle timeout                                   10 minutes                   Return idle connections to the database after 10 minutes of inactivity

  Maximum connection lifetime                    30 minutes                   Recycle connections to prevent stale state accumulation

  Pooling mode                                   Transaction mode (default)   Session mode for operations requiring prepared statements or advisory locks
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

These are baseline values for a V1 deployment. Connection pool sizing should be tuned based on observed query latency percentiles and pool wait times. The total connection count across all application instances must not exceed the database server's maximum connection limit minus a reserved buffer for administrative access (minimum 5 reserved connections).

Managed Platform Note

Supabase provides a built-in PgBouncer connection pooler. The baseline values above are compatible with Supabase's default configuration. Transaction mode is recommended for standard application traffic. Session mode is required only for reflow operations that use advisory locks (optional enhancement per §16.4.3).

16.8.7 Operational Monitoring

The following operational monitors are required from launch. Each monitor defines a metric, threshold, and alerting behaviour.

Query Performance

  -----------------------------------------------------------------------------------------------------------------------------
  Monitor             Threshold                            Action
  ------------------- ------------------------------------ --------------------------------------------------------------------
  Slow query log      Queries exceeding 500ms              Log with full query plan. Alert if frequency exceeds 10 per hour.

  P95 query latency   > 200ms sustained for 5 minutes      Alert. Investigate index coverage and query plans.

  P99 query latency   > 1 second sustained for 5 minutes   Alert (high priority). Potential missing index or lock contention.
  -----------------------------------------------------------------------------------------------------------------------------

Lock & Reflow Health

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Monitor               Threshold                                                                             Action
  --------------------- ------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------
  Reflow duration       > 5 seconds (user-initiated)                                                          Alert. Investigate data volume or index degradation.

  Reflow failure rate   Any single failure (reflows should never fail after retries under normal operation)   Alert on every occurrence. Check EventLog for ReflowFailed entries. Investigate root cause.

  Stale scoring lock    Lock held > 60 seconds (hard timeout)                                                 Auto-release + alert. Log as ReflowFailed.

  Lock contention       > 5 lock acquisition rejections per hour                                              Alert. Investigate concurrent edit patterns.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Database Health

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Monitor                                       Threshold                                                         Action
  --------------------------------------------- ----------------------------------------------------------------- ------------------------------------------------------------
  Connection pool utilisation                   > 80% sustained for 10 minutes                                    Alert. Consider scaling pool size or adding read replicas.

  Connection pool wait time                     P95 > 1 second                                                    Alert. Pool exhaustion risk.

  Index bloat                                   > 40% bloat ratio on any index                                    Alert. Schedule REINDEX or VACUUM.

  Table bloat                                   > 30% dead tuple ratio on high-write tables (Instance, Session)   Alert. Schedule VACUUM.

  Disk usage                                    > 80% of allocated storage                                        Alert. Review archival schedule and data retention.

  Replication lag (if read replicas deployed)   > 5 seconds sustained                                             Alert. Read replica may serve stale materialised state.
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Backup & Archival

  ----------------------------------------------------------------------------------------------------------------------------
  Monitor                    Threshold                                  Action
  -------------------------- ------------------------------------------ ------------------------------------------------------
  WAL archival gap           > 15 minutes since last archived segment   Alert (high priority). RPO at risk.

  Daily base backup          Missed or failed                           Alert (high priority). Recovery capability degraded.

  Weekly backup validation   Validation failure                         Alert. Investigate backup integrity.

  EventLog archival          Hot storage rows older than 6 months       Alert. Archival job may have failed.
  ----------------------------------------------------------------------------------------------------------------------------

All alerts route to the operations team. Critical alerts (RPO risk, reflow failure, backup failure) additionally trigger on-call escalation. Alert thresholds are operational parameters and may be tuned without requiring a specification update.

16.9 Structural Guarantees

The Database Architecture guarantees:

-   Deterministic recalculability: all scores reproducible from raw Instance data and canonical scoring parameters at any time.

-   Atomic reflow integrity: no partial materialised state visible to users. The materialised swap step uses Serializable isolation; all other operations use Repeatable Read with application-level lock enforcement.

-   Physical separation of source and derived data: materialised tables are a replaceable cache. Truncation and rebuild produces identical results.

-   Database-layer soft-delete enforcement: row-level policies ensure soft-deleted rows are invisible to standard queries without application-layer filtering.

-   Referential integrity: foreign key constraints on all cross-table relationships. JSON-embedded references maintained by application-layer cascade logic with explicit tradeoff documentation.

-   Foreign key index coverage: every FK column is indexed, either by a dedicated index or as the leading column of a composite index.

-   User data isolation: row-level security policies enforce strict UserID scoping on all queries. Cross-user contention is structurally impossible.

-   Enumeration integrity: stable enumerations enforced by native enum types or check constraints. Extensible enumerations enforced by reference table foreign keys.

-   Sequential migration governance: all schema changes tracked, ordered, and reversible. No destructive migration without backup. Zero-downtime capability via expand-contract pattern.

-   Point-in-time recovery within 15 minutes (RPO) via continuous WAL archival. Achievable at near-zero cost on managed platforms.

-   Service restoration within 1 hour (RTO) from any failure scenario.

-   EventLog archival to cold storage: 6-month hot retention, indefinite cold retention.

-   Connection management: mandatory connection pooling with defined baseline sizing and tuning guidance.

-   Operational monitoring: query performance, lock health, database health, and backup integrity monitors defined with thresholds and alerting.

-   Application-layer retry model: consistent retry behaviour defined for all operation categories, not only reflow.

-   Technology-agnostic specification: all patterns are implementable on any relational database with JSON, row-level policy, and ACID transaction support.

-   Bounded reflow cost: the 25-occupancy-unit window cap guarantees reflow computation volume is constant regardless of user history length.

-   No scoring impact from planning, equipment, or metadata operations: CalendarDay, Routine, Schedule, UserClub metadata, and ClubPerformanceProfile changes never trigger reflow.

-   Explicit JSON tradeoff documentation: planning table JSON modelling is a deliberate V1 decision with a defined normalisation path for future scale.

End of Section 16 — Database Architecture (16v.a5 Canonical)

