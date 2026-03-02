Section 6 — Data Model & Persistence Layer

Version 6v.b7 — Canonical

This document defines the canonical Data Model and Persistence Layer. It is fully harmonised with Sections 1–5, Section 7 (7v.b9), Section 8 (Practice Planning Layer 8v.a8), Section 9 (9v.a2), Section 10 (10v.a5), Section 13 (Live Practice Workflow 13v.a6), and the Canonical Definitions (0v.f1), and Section 11 (11v.a5).

6.1 Core Domain Objects

The persistence layer stores the following entities. All entities carry CreatedAt (UTC) and UpdatedAt (UTC) timestamps.

Definition Objects

• Drill — Permanent drill definition

• Routine — Blueprint of ordered drill references

Execution Objects

• PracticeBlock — Real-world practice container

• Session — Runtime execution of one drill

• Set — Sequential attempt container within a Session

• Instance — Atomic logged attempt (stores SelectedClub per shot)
• PracticeEntry — Execution-layer queue position within a PracticeBlock (Section 13)

Relationship Objects

• UserDrillAdoption — Links a user to an adopted System Drill

• UserClub — Club in a user’s configured bag (36-type enumeration with optional Make, Model, Loft)

• ClubPerformanceProfile — Time-versioned carry distance and dispersion data per club

• UserSkillAreaClubMapping — Per-user ClubType → Skill Area eligibility assignments

System Objects

• EventLog — Audit trail for reflow and deletion events

• UserDevice — Registered device for synchronisation (Section 17)

Planning Objects

• CalendarDay — A single date on the user’s Calendar with SlotCapacity and ordered Slots

• Routine — Reusable ordered list of entries (fixed DrillIDs and/or Generation Criteria)

• Schedule — Reusable multi-day blueprint (fixed DrillIDs, Generation Criteria, and/or Routine references)

• RoutineInstance — Application record linking a Routine to a CalendarDay with owned Slot tracking

• ScheduleInstance — Application record linking a Schedule to a CalendarDay range with owned Slot tracking

6.2 Entity Schemas

User

Referenced by all user-scoped entities. Detailed specification deferred to Settings & Configuration (Section 10). Included here to establish the foreign key relationship.

  -------------------------------------------------------------------------
  Field                 Type              Notes
  --------------------- ----------------- ---------------------------------
  UserID                UUID (PK)         

  CreatedAt             Timestamp (UTC)   

  UpdatedAt             Timestamp (UTC)   
  -------------------------------------------------------------------------

Drill

Covers both System Drills and User Custom Drills. The Drill no longer stores a fixed SelectedClub — club selection occurs at Instance level.

Drill.SkillArea is an enum with seven values: Driving, Irons, Putting, Pitching, Chipping, Woods, Bunkers. This enum is the canonical persistence-layer representation of the Skill Areas defined in Section 2 (2v.f1).

  ---------------------------------------------------------------------------------------------------------------------------------------------------
  Field                    Type                 Notes
  ------------------------ -------------------- -----------------------------------------------------------------------------------------------------
  DrillID                  UUID (PK)            

  UserID                   UUID (FK) nullable   Null for System Drills; set for User Custom Drills

  Name                     String               

  SkillArea                Enum                 Driving, Irons, Putting, Pitching, Chipping, Woods, Bunkers

  DrillType                Enum                 TechniqueBlock, Transition, Pressure. Immutable post-creation

  ScoringMode              Enum nullable        Shared, MultiOutput. Scored drills only

  InputMode                Enum                 GridCell, ContinuousMeasurement, RawDataEntry, BinaryHitMiss

  MetricSchemaID           String               System-defined. Immutable post-creation

  GridType                 Enum nullable        ThreeByThree, OneByThree, ThreeByOne. Grid drills only

  SubskillMapping          Array (1–2)          Immutable post-creation

  ClubSelectionMode        Enum nullable        Random, Guided, UserLed. Multi-club Skill Areas only

  TargetDistanceMode       Enum nullable        Fixed, ClubCarry, PercentageOfClubCarry. Grid drills only

  TargetDistanceValue      Decimal nullable     Fixed distance or percentage value depending on mode

  TargetSizeMode           Enum nullable        Fixed, PercentageOfTargetDistance. Grid drills only

  TargetSizeWidth          Decimal nullable     Fixed width or percentage. Required for 3×3 and 1×3 grids

  TargetSizeDepth          Decimal nullable     Fixed depth or percentage. Required for 3×3 and 3×1 grids

  RequiredSetCount         Integer ≥1           Immutable post-creation

  RequiredAttemptsPerSet   Integer ≥1 or null   Null = open-ended. Immutable post-creation

  Anchors                  JSON                 Per mapped subskill: {Min, Scratch, Pro}. Hit-rate % for grid drills. Editable for User Custom only

  Origin                   Enum                 System, UserCustom

  Status                   Enum                 Active, Retired, Deleted

  IsDeleted                Boolean              Soft delete flag

  CreatedAt                Timestamp (UTC)      

  UpdatedAt                Timestamp (UTC)      
  ---------------------------------------------------------------------------------------------------------------------------------------------------

Routine

  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Field                 Type                            Notes
  --------------------- ------------------------------- ------------------------------------------------------------------------------------------------------------------------------------
  RoutineID             UUID (PK)                       

  UserID                UUID (FK)                       Owner

  Name                  String                          

  Entries               Ordered Array of EntryObjects   Each entry: {Type: Fixed, DrillID} or {Type: Criterion, SkillArea?, DrillTypes[], Subskill?, Mode}. References only; not ownership

  Status                Enum                            Active, Retired, Deleted

  IsDeleted             Boolean                         Soft delete flag

  CreatedAt             Timestamp (UTC)                 

  UpdatedAt             Timestamp (UTC)                 
  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Entries are an ordered list; each entry is either {Type: Fixed, DrillID} or {Type: Criterion, SkillArea, DrillTypes[], Subskill?, Mode}. If a referenced Drill is deleted or retired, the corresponding fixed entry is automatically removed. If the entry list becomes empty, the Routine is auto-deleted. Generation Criterion entries reference Skill Areas and Drill Types, not specific Drills, and are unaffected by drill lifecycle changes.

PracticeBlock

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Field                 Type                        Notes
  --------------------- --------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  PracticeBlockID       UUID (PK)                   

  UserID                UUID (FK)                   Owner

  SourceRoutineID       UUID (FK) nullable          Null if created via manual or system build

  DrillOrder            Ordered Array of DrillIDs   Creation-time audit snapshot of initial drill queue. Severed from template. Superseded by PracticeEntry for live queue representation during execution (Section 13, §13.15).

  StartTimestamp        Timestamp (UTC)             

  EndTimestamp          Timestamp (UTC) nullable    Set on close

  ClosureType           Enum nullable               Manual, AutoClosed

  IsDeleted             Boolean                     Soft delete flag

  CreatedAt             Timestamp (UTC)             

  UpdatedAt             Timestamp (UTC)             
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Persisted only if ≥1 Session exists. Auto-deleted if no Session started.
PracticeEntry
Execution-layer queue object within a PracticeBlock. Each PracticeEntry represents a single position in the Live Practice queue. Schema: PracticeEntryID (UUID, PK), PracticeBlockID (UUID FK), DrillID (UUID FK), SessionID (UUID FK, nullable — null for PendingDrill entries), EntryType (Enum: PendingDrill, ActiveSession, CompletedSession), PositionIndex (Integer ≥ 0 — queue ordering key), CreatedAt (UTC), UpdatedAt (UTC). PracticeEntry does not participate in scoring calculations, window storage, or derived state materialisation. PracticeEntries are deleted when the parent PracticeBlock is deleted. See Section 13 (§13.3) for full behavioural specification.

Session

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Field                 Type                       Notes
  --------------------- -------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  SessionID             UUID (PK)                  

  DrillID               UUID (FK)                  Drill executed

  PracticeBlockID       UUID (FK)                  Parent PracticeBlock

  CompletionTimestamp   Timestamp (UTC) nullable   Authoritative window ordering key. Set on close

  Status                Enum                       Active, Closed, Discarded

  IntegrityFlag         Boolean                    Default false. True when ≥1 Instance breaches plausibility bounds. No scoring impact.

  IntegritySuppressed   Boolean                    Default false. True when user clears flag. Resets on Instance edit or reflow. No scoring impact.

  UserDeclaration       String (nullable)          User-declared intention for Binary Hit/Miss drills (e.g. draw, fade, high, low). Nullable. Only populated for Sessions using Binary Hit/Miss input mode. Informational only; no scoring impact.

  SessionDuration       Integer (nullable)         Elapsed time in seconds. Derived for scored drills (first Instance timestamp to last Instance timestamp). Primary data for Technique Block Sessions. Nullable. No scoring impact. Not a reflow trigger. Available for time-based analytics in Review (Section 5).

  IsDeleted             Boolean                    Soft delete flag

  CreatedAt             Timestamp (UTC)            

  UpdatedAt             Timestamp (UTC)            
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Session score is derived (simple average of all Instance 0–5 scores across all Sets) and is not stored. Session no longer stores SelectedClub — this is recorded per Instance.

Session carries two integrity fields: IntegrityFlag (boolean, default false) and IntegritySuppressed (boolean, default false, persisted). IntegrityFlag is true when one or more Instances breach schema plausibility bounds. IntegritySuppressed is true when the user has manually cleared an active flag; it resets to false on any Instance edit. Both fields are non-scoring and do not trigger reflow. See Section 11.

Set

  ----------------------------------------------------------------------------
  Field                 Type              Notes
  --------------------- ----------------- ------------------------------------
  SetID                 UUID (PK)         

  SessionID             UUID (FK)         Parent Session

  SetIndex              Integer ≥1        Sequential position within Session

  IsDeleted             Boolean           Soft delete flag

  CreatedAt             Timestamp (UTC)   

  UpdatedAt             Timestamp (UTC)   
  ----------------------------------------------------------------------------

Instance

Every Instance records the SelectedClub used for that shot. This enables per-Instance target resolution for grid-based drills and provides a full audit trail of club usage.

  --------------------------------------------------------------------------------------------------------------------
  Field                    Type               Notes
  ------------------------ ------------------ ------------------------------------------------------------------------
  InstanceID               UUID (PK)          

  SetID                    UUID (FK)          Parent Set

  SelectedClub             UUID (FK)          References UserClub.ClubID. Required for all scored drills

  RawMetrics               JSON               Schema-defined performance data (grid cell, measurement, or raw value)

  Timestamp                Timestamp (UTC)    Device-recorded

  ResolvedTargetDistance   Decimal nullable   Snapshot at Instance creation for grid drills

  ResolvedTargetWidth      Decimal nullable   Snapshot at Instance creation for grid drills

  ResolvedTargetDepth      Decimal nullable   Snapshot at Instance creation for grid drills

  IsDeleted                Boolean            Soft delete flag

  CreatedAt                Timestamp (UTC)    

  UpdatedAt                Timestamp (UTC)    
  --------------------------------------------------------------------------------------------------------------------

Derived 0–5 score is calculated from RawMetrics and Drill anchors at read time. Not stored. For grid-based drills, the hit/miss determination is stored in RawMetrics (which cell was tapped); the target box dimensions are resolved at display time from the Drill’s Target Definition and the Instance’s SelectedClub.

UserDrillAdoption

  -------------------------------------------------------------------------
  Field                 Type              Notes
  --------------------- ----------------- ---------------------------------
  UserDrillAdoptionID   UUID (PK)         

  UserID                UUID (FK)         

  DrillID               UUID (FK)         Must reference a System Drill

  Status                Enum              Active, Retired

  CreatedAt             Timestamp (UTC)   

  UpdatedAt             Timestamp (UTC)   
  -------------------------------------------------------------------------

On unadopt with KEEP: Status set to Retired. On unadopt with DELETE: record removed; Drill’s child Sessions soft-deleted; full recalculation triggered. Re-adoption sets Status back to Active and reconnects historical Sessions.

UserClub

Defines the user’s configured bag. Each club is a distinct entity with ClubType from the canonical 36-type enumeration (Section 9, §9.1.1). Includes optional Make, Model, and Loft fields (descriptive only, no scoring impact). Status governs Active/Retired lifecycle. Eligible clubs per Skill Area are filtered from this set via UserSkillAreaClubMapping. Full bag configuration specified in Section 9.

  -------------------------------------------------------------------------------------------------
  Field                 Type               Notes
  --------------------- ------------------ --------------------------------------------------------
  ClubID                UUID (PK)          

  UserID                UUID (FK)          

  ClubType              Enum               From canonical 36-type enumeration (Section 9, §9.1.1)

  Make                  String nullable    Descriptive only. No scoring impact

  Model                 String nullable    Descriptive only. No scoring impact

  Loft                  Decimal nullable   Analytics only. No scoring impact

  Status                Enum               Active, Retired

  CreatedAt             Timestamp (UTC)    

  UpdatedAt             Timestamp (UTC)    
  -------------------------------------------------------------------------------------------------

ClubPerformanceProfile

Time-versioned performance characteristics for each club. Stores CarryDistance and four optional asymmetric dispersion values (Left, Right, Short, Long). Entry is optional. The active profile at any timestamp is the most recent profile with EffectiveFromDate ≤ timestamp. Dispersion data is analytics-only with no scoring or target resolution impact. Creates new rows on update, preserving full history. No scoring impact. No reflow triggered. See Section 9 (§9.5).

UserSkillAreaClubMapping

Per-user ClubType → Skill Area assignments. Determines which clubs are eligible for drills in each Skill Area. Mandatory minimums enforced (Driver → Driving, i1–i9 → Irons, Putter → Putting). Users may add additional mappings and remove non-mandatory ones. A single ClubType may be assigned to multiple Skill Areas. No scoring impact. No reflow triggered. See Section 9 (§9.2).

  ------------------------------------------------------------------------------------------------------
  Field                 Type               Notes
  --------------------- ------------------ -------------------------------------------------------------
  ProfileID             UUID (PK)          

  ClubID                UUID (FK)          References UserClub.ClubID

  EffectiveFromDate     Date               Profile active from this date. Most recent ≤ timestamp wins

  CarryDistance         Decimal nullable   In user's preferred unit. Used for target resolution

  DispersionLeft        Decimal nullable   Analytics only. No scoring impact

  DispersionRight       Decimal nullable   Analytics only. No scoring impact

  DispersionShort       Decimal nullable   Analytics only. No scoring impact

  DispersionLong        Decimal nullable   Analytics only. No scoring impact

  CreatedAt             Timestamp (UTC)    

  Field                 Type               Notes

  MappingID             UUID (PK)          

  UserID                UUID (FK)          

  ClubType              Enum               From canonical 36-type enumeration

  SkillArea             Enum               Skill Area this ClubType is eligible for

  IsMandatory           Boolean            True for system-enforced defaults (e.g. Driver→Driving)

  CreatedAt             Timestamp (UTC)    
  ------------------------------------------------------------------------------------------------------

EventLog

  ------------------------------------------------------------------------------------------
  Field                 Type              Notes
  --------------------- ----------------- --------------------------------------------------
  EventLogID            UUID (PK)         

  UserID                UUID (FK)         

  EventType             Enum              Canonical enumeration defined in Section 7, §7.9

  Timestamp             Timestamp (UTC)   Event timestamp

  AffectedEntityIDs     JSON              Drill, Session, Instance IDs as applicable

  AffectedSubskills     JSON nullable     Subskills affected by the event

  Metadata              JSON nullable     Change details (e.g. old/new anchor values)

  CreatedAt             Timestamp (UTC)   
  ------------------------------------------------------------------------------------------

Append-only. No updates or deletions. Provides audit trail for reflow and deletion events. Each entry carries a typed event type (enumeration defined canonically in Section 7, §7.9) and a metadata payload. Fields: EventID, UserID, DeviceID (UUID, nullable — originating device; null for server-generated events), EventType, Timestamp (UTC), AffectedEntityIDs, AffectedSubskills, Metadata (JSON), CreatedAt (UTC).

ScheduleInstance

Created on Schedule application to a CalendarDay range and confirmed. Tracks which Slots across which CalendarDays the application filled. Supports unapply. Self-sufficient regardless of source Schedule lifecycle. Same ownership and unapply model as RoutineInstance.

• ScheduleInstanceID (UUID, PK)

• ScheduleID (UUID FK, nullable — null if source deleted)

• UserID (UUID FK)

• StartDate (UTC date)

• EndDate (UTC date)

• OwnedSlots (list of CalendarDay date + Slot position pairs)

• CreatedAt (UTC)

RoutineInstance

Created on Routine application to a CalendarDay and confirmed. Tracks which Slots the application filled. Supports unapply. Manual edits to owned Slots break ownership. Unapply clears owned Slots and deletes the record. Self-sufficient regardless of source Routine lifecycle.

• RoutineInstanceID (UUID, PK)

• RoutineID (UUID FK, nullable — null if source deleted)

• UserID (UUID FK)

• CalendarDayDate (UTC date)

• OwnedSlots (list of Slot positions on the CalendarDay)

• CreatedAt (UTC)

Schedule

Reusable multi-day blueprint for populating CalendarDay Slots. Not calendar-bound until applied.

• ScheduleID (UUID, PK)

• UserID (UUID FK)

• Name (String)

• ApplicationMode (Enum: List or DayPlanning)

• For List Mode: Entries (single ordered list; each entry is Fixed DrillID, Generation Criterion, or RoutineID reference)

• For Day Planning Mode: TemplateDays (ordered list of template days, each containing an ordered entry list)

• Status (Enum: Active, Retired)

• IsDeleted (Boolean)

• CreatedAt (UTC), UpdatedAt (UTC)

Entry types within a Schedule: {Type: Fixed, DrillID}, {Type: Criterion, SkillArea?, DrillTypes[], Subskill?, Mode}, or {Type: RoutineRef, RoutineID}. Routine references expand inline at application time.

Slot Schema

Persisted only when deviating from the user’s default day-of-week SlotCapacity pattern or when a Slot is filled (sparse storage with default fallback). Fields: UserID, Date (UTC), SlotCapacity (integer ≥ 0), Slots (ordered list of Slot objects), CreatedAt (UTC), UpdatedAt (UTC).

CalendarDay

Metric Schema Plausibility Bounds

Each numeric-entry Metric Schema (Continuous Measurement and Raw Data Entry) defines HardMinInput (decimal) and HardMaxInput (decimal). These are system-defined, immutable plausibility bounds. They are not stored on the Instance or Session entity. They have no scoring impact, do not trigger reflow, and are not part of the derived state model. Grid Cell Selection and Binary Hit/Miss schemas do not carry these fields. See Section 11.

6.3 Derived Model

All scoring values are derived from raw Instance data and the canonical scoring model — they are not stored as persisted fields. Derived state is materialised post-reflow and served authoritatively until the next reflow event. Reads access the current materialised state; recalculation occurs only on structural trigger, never on read. The following are never stored as persisted fields:

• Instance 0–5 score (derived from RawMetrics + Drill anchors)

• Session score (derived from Instance scores)

• Session hit-rate percentage for grid drills (derived from Instance grid cell data)

• Resolved target box dimensions (derived from Drill Target Definition + Instance SelectedClub + UserClub CarryDistance)

• Window state (derived from Session entries + occupancy rules)

• Window averages

• Subskill points

• Skill Area scores

• Overall score

• Analytics buckets or trend data

This guarantees full recalculability and eliminates stale-cache risks. See Section 7 (Reflow Governance System, §7.11) for the full derived state materialisation model.

6.4 Ownership & User Scoping

UserID is the top-level scoping key. Every query must be scoped to the authenticated user.

• Drill: UserID set for User Custom Drills. Null for System Drills (shared across all users).

• Routine: Owned by UserID.

• PracticeBlock: Owned by UserID.
• PracticeEntry: Inherits user scope through PracticeBlock.

• Session: Inherits user scope through PracticeBlock.

• Set: Inherits user scope through Session.

• Instance: Inherits user scope through Set.

• UserDrillAdoption: Scoped by UserID.

• UserClub: Scoped by UserID.

• EventLog: Scoped by UserID.

• CalendarDay: Scoped by UserID.

• Routine: Owned by UserID.

• Schedule: Owned by UserID.

• RoutineInstance: Owned by UserID.

• ScheduleInstance: Owned by UserID.

6.5 Transaction Model

Session closure commits Session + Sets + Instances atomically. Incomplete structured Sessions are never persisted.

Drill anchor edits commit the anchor change and trigger background recalculation atomically. The reflow process runs in the background; the UI displays a loading state until complete.

Deletion operations commit the soft-delete flag and cascade to children atomically, then trigger background recalculation.

6.6 Deletion Model

Soft Delete

All deletions set IsDeleted = true at the database layer. Soft-deleted records are excluded from all scoring, analytics, and UI queries. Soft delete is irreversible at the UX layer.

Cascade Rules

Deletion cascades to all children:

• Drill deleted → all Sessions for that Drill → their Sets → their Instances

• PracticeBlock deleted → all Sessions within it → their Sets → their Instances

• Session deleted → its Sets → its Instances

• Set deleted → its Instances

• Routine deleted → no cascade (references Drills, does not own them)
• PracticeBlock deleted → all PracticeEntries within it (cascade). PracticeEntry deletion does not cascade to referenced Session.

Retirement

Only Drills, Routines, and Schedules may be retired. Retirement hides the entity from active use but preserves all historical data. Retired entities are not soft-deleted.

• Drill deleted or retired → any CalendarDay Slot referencing that DrillID is cleared immediately. Owning Instance (if any) loses ownership of that Slot position.

• ScheduleInstance unapplied → owned Slots cleared. ScheduleInstance record deleted. No cascade to Drills or Sessions.

• RoutineInstance unapplied → owned Slots cleared. RoutineInstance record deleted. No cascade to Drills or Sessions.

• Schedule deleted → all ScheduleInstances referencing it have ScheduleID set to null. Instances persist; Slots remain filled.

• Routine deleted → all RoutineInstances referencing it have RoutineID set to null. Instances persist; Slots remain filled.

Planning objects (CalendarDay, Routine, Schedule, RoutineInstance, ScheduleInstance) have no scoring impact. Their deletion does not trigger recalculation.

Planning Object Cascade Rules

Active Session Deletion Block

Deletion of a Drill is blocked while any Session for that Drill is in Active or Paused state. The user must close or discard all active Sessions for the Drill before deletion is permitted. This applies across all devices.

Post-Deletion Recalculation

Any deletion that removes scored data triggers a full background recalculation. A typed EventLog entry is written for every deletion event.

Session Auto-Discard

If the last remaining Instance in a closed unstructured Session is deleted, the Session is automatically discarded. A Session with zero Instances cannot exist in a scored state. The auto-discard triggers recalculation and writes a SessionAutoDiscarded EventLog entry.

6.7 Recalculation Behaviour

Recalculation is triggered by structural changes. The full trigger catalogue is defined in Section 7 (Reflow Governance System). Explicit triggers include: anchor edits (User Custom Drills), Instance edits (post-close), Instance deletions (post-close, unstructured drills only), Session deletions, PracticeBlock deletions, Drill deletions (with scored data), Session auto-discards (last Instance deleted from unstructured drill), and system parameter updates.

Recalculation executes as a background process, triggered immediately after the edit is committed. The UI displays a loading state until recalculation is complete. Reads access materialised post-reflow state — there is no per-read derivation from raw data, and no version registry.

A typed EventLog entry is written for every recalculation event. The canonical EventType enumeration is defined in Section 7 (§7.9 EventLog Integration). Section 6 does not maintain a separate EventType list — Section 7 is the single source of truth for all event types.

6.8 Indexing Strategy

Minimal required indexes:

• Session(CompletionTimestamp) — window ordering

• Session(DrillID) — drill-level queries

• Session(PracticeBlockID) — practice block queries
• PracticeEntry(PracticeBlockID, PositionIndex) — queue ordering
• PracticeEntry(SessionID) — Session lookup (nullable; sparse index recommended)

• Instance(SetID) — set-level aggregation

• Instance(SelectedClub) — club-level analysis

• Set(SessionID) — session-level aggregation

• UserDrillAdoption(UserID, DrillID) — unique constraint

• UserClub(UserID) — bag queries

• EventLog(UserID, CreatedAt) — audit queries

• UserDevice(UserID) — device list per user

• EventLog(DeviceID) — device-origin audit queries

• CalendarDay(UserID, Date) — calendar queries and date uniqueness

• Routine(UserID) — routine library queries

• Schedule(UserID) — schedule library queries

• RoutineInstance(UserID, CalendarDay date) — instance lookup per day

• ScheduleInstance(UserID, StartDate, EndDate) — instance lookup by date range

• ClubPerformanceProfile(ClubID, EffectiveFromDate) — active profile resolution

• UserSkillAreaClubMapping(UserID, SkillArea) — eligible club lookups

All queries filter on IsDeleted = false. Further optimisation deferred until required.

6.9 Structural Guarantees

The persistence layer guarantees:

• No scoring aggregates stored — all derived at read time

• Atomic transaction boundaries for session closure, deletion, and anchor edits

• Soft delete with full cascade integrity

• Background recalculation with loading state — no stale reads

• Append-only audit log for reflow and deletion events

• User-scoped data isolation from the schema level

• Full recalculability from raw Instance data

• CreatedAt and UpdatedAt on all persisted entities

• SelectedClub recorded per Instance for full club audit trail

• Planning objects architecturally isolated from scoring engine — no reflow, no window entry, no derived score impact

• Slot ownership tracking with clean unapply support

• Sparse CalendarDay persistence with day-of-week default fallback

End of Section 6 — Data Model & Persistence Layer (6v.b7 Canonical)

