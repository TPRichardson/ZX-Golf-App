TD-02 — Database DDL Schema

Version TD-02v.a6 — Canonical

Harmonised with: Section 6 (6v.b7), Section 16 (16v.a5), TD-01 (TD-01v.a4), Section 2 (2v.f1), Section 4 (4v.g9), Section 7 (7v.b9), Section 9 (9v.a2), Section 14 (14v.a4).

1. Purpose

This document translates the logical data model (Section 6) and database architecture (Section 16) into executable Postgres DDL for Supabase, plus a matching Drift (SQLite) schema for the Flutter client. It also seeds all reference data and the V1 System Drill Library.

Deliverables: 001_create_schema.sql (Postgres DDL), 002_seed_reference_data.sql (reference + system drill seed), and this specification document.

2. Schema Overview

The schema is organised into five table groups per Section 16 (§16.1):

  --------------------- -------------------------------------------------------------------------------------------------------------------------------------------------- ----------
  Group                 Tables                                                                                                                                             Count

  Source Tables         User, Drill, PracticeBlock, Session, Set, Instance, PracticeEntry, UserDrillAdoption, UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping   11

  Reference Tables      EventTypeRef, MetricSchema, SubskillRef                                                                                                            3

  Planning Tables       CalendarDay, Routine, Schedule, RoutineInstance, ScheduleInstance                                                                                  5

  Materialised Tables   MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore                                           4

  System Tables         EventLog, UserDevice, UserScoringLock, SystemMaintenanceLock, MigrationLog                                                                         5
  --------------------- -------------------------------------------------------------------------------------------------------------------------------------------------- ----------

Total: 28 tables.

3. Design Decisions

3.1 SubskillRef Reference Table

Section 2 defines 19 subskills across 7 Skill Areas with fixed allocations summing to 1000. The spec treats these as system-defined constants. The DDL introduces a SubskillRef reference table (not present in Section 6 or 16) to centralise subskill identity and allocation in the database rather than scattering these values across application code.

Rationale: Subskill IDs appear in Drill.SubskillMapping (JSON array), MaterialisedWindowState.Subskill, MaterialisedSubskillScore.Subskill, and EventLog.AffectedSubskills. A reference table provides a single source of truth for subskill names and allocations, simplifies validation, and makes the allocation table queryable without hardcoding. The table is read-only for application code and seeded at deployment time.

SubskillID convention: snake_case compound key: {skill_area}_{subskill_name}. Examples: irons_distance_control, driving_shape_control. These IDs are used in Drill.SubskillMapping JSON arrays and materialised table Subskill columns.

3.2 Server-Assigned UpdatedAt

Per TD-01 (§2.1), UpdatedAt is always server-assigned via a Postgres BEFORE UPDATE trigger (set_updated_at function). The client never writes UpdatedAt. This establishes a single authoritative timestamp source for sync conflict detection. Every table with an UpdatedAt column has a corresponding trigger.

3.3 Deterministic System Drill UUIDs

System Drills use deterministic UUID v4 values (patterned: a0000001-0000-4000-8000-00000000000N) to ensure seed idempotency. Re-running the seed migration is safe. This pattern is strictly confined to system-seeded rows (28 System Drills in V1) and must not be extended to user-generated entities, which use gen_random_uuid() for conflict-free generation across devices per TD-01 (§2.1). Future System Drill additions must follow the same deterministic pattern with the next available prefix block.

3.4 Sync Uniformity: UpdatedAt on All Synced Tables

All synced tables carry UpdatedAt (server-assigned via trigger) to give the sync engine a single uniform pull path. This includes insert-only tables (ClubPerformanceProfile, UserSkillAreaClubMapping) and insert/delete-only tables (RoutineInstance, ScheduleInstance) where UpdatedAt is technically redundant but eliminates the need for a dual sync path (UpdatedAt-based vs CreatedAt-based). The only exception is EventLog, which is append-only with no updates or deletes and syncs via CreatedAt. Child tables without a UserID column (Session, Set, Instance, ClubPerformanceProfile) require a different download query strategy: the sync download RPC joins the child table to its parent (e.g. Session JOIN PracticeBlock ON PracticeBlockID) to scope by UserID via RLS, then filters by the child’s UpdatedAt. The DDL includes UpdatedAt-only indexes on these child tables (ix_sync_session, ix_sync_set, ix_sync_instance, ix_sync_clubprofile) to support the timestamp range scan in this JOIN-based query pattern.

3.5 EventLog: No UpdatedAt

EventLog is append-only (Section 6 §6.2). Entries are never updated or deleted from the primary database. Only CreatedAt is recorded. No UpdatedAt trigger. The sync engine pulls EventLog rows via CreatedAt > lastSyncCheckpoint.

3.6 Materialised Tables: Output Layer of the Pure Rebuild Engine

TD-01 (§4.3) specifies a pure rebuild scoring engine: when reflow fires, it recalculates all derived state from raw Instance data every time. It never patches or incrementally updates a previous result. The four materialised tables (MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore) are the output destination of this pure rebuild, not an alternative calculation path or competing source of truth.

Section 16 (§16.1.6) explicitly defines materialised tables as a replaceable cache. They can be truncated and fully rebuilt from raw Instance data at any time (Section 16 §16.7.3, Scenario 4). The reflow atomic swap (Section 16 §16.4.5) writes the rebuild results to these tables within a Serializable transaction. Between reflows, reads are served from this cache to avoid per-read recalculation.

This is not a dual source of truth. Raw Instance data is the single source of truth. Materialised tables are a deterministic projection of that data. The architecture is: raw data → pure rebuild calculation → atomic write to materialised cache.

3.7 Putting Direction: No ClubSelectionMode

Putting Direction and Putting Distance drills have ClubSelectionMode set to NULL because Putting has exactly one eligible club (Putter), which is auto-selected. The application layer handles this per Section 9 (§9.4). No selector is displayed.

3.8 Materialised Table PracticeType Column

MaterialisedWindowState.PracticeType uses the drill_type enum but is constrained to Transition or Pressure values only. TechniqueBlock sessions do not enter windows (Section 3). This constraint is enforced at the application layer rather than via a separate enum, to avoid type proliferation. The composite primary key (UserID, SkillArea, Subskill, PracticeType) ensures one window row per subskill per practice type per user.

3.9 Target Size Columns: Width vs Depth

Direction drills (1×3): TargetSizeWidth is populated (lateral dimension). TargetSizeDepth is NULL.

Distance drills (3×1): TargetSizeDepth is populated (depth dimension). TargetSizeWidth is NULL.

This matches the grid orientation: 1×3 measures direction (width matters), 3×1 measures distance (depth matters). Multi-Output 3×3 grids populate both. The PercentageOfTargetDistance value in TargetSizeWidth or TargetSizeDepth is the percentage figure itself (e.g. 7 means 7%).

4. Sync Infrastructure

Per TD-01 (§2), the sync model requires:

-   UpdatedAt trigger on all synced tables (server-assigned, never client-written).

-   IsDeleted soft-delete flag on all entities that support deletion. See TD-01 §2.10 for the exception categories (account-lifecycle, ephemeral, status-managed, insert-only, insert/hard-delete, and permanent-once-created tables).

-   UUID primary keys generated client-side (gen_random_uuid default for server-created rows).

-   SyncMetadata (lastSyncCheckpoint per table) managed by Drift on the client. Not a Postgres table.

Tables without UpdatedAt (EventLog only) sync via CreatedAt. EventLog is append-only; the sync engine pulls rows with CreatedAt > lastSyncCheckpoint. All other synced tables use the uniform UpdatedAt-based pull path.

5. Row-Level Security Model

RLS is enabled on all tables from day one per TD-01 (§3.2). The policy model has three tiers:

5.1 Direct UserID Tables

Standard policy: WHERE UserID = auth.uid(). Applies to: User, PracticeBlock, UserDrillAdoption, UserClub, UserSkillAreaClubMapping, Routine, Schedule, CalendarDay, RoutineInstance, ScheduleInstance, EventLog, UserDevice, UserScoringLock, and all materialised tables.

5.2 Drill (Hybrid)

Drills use a dual condition: UserID = auth.uid() OR UserID IS NULL. This allows users to read System Drills (UserID = NULL) while restricting User Custom Drills to their owner. System Drills are writable only by service-role operations.

5.3 Child Tables (Join-Through)

Session, Set, Instance, PracticeEntry, and ClubPerformanceProfile do not carry a direct UserID. Their RLS policies join through the parent chain to reach UserID. The deepest chain is Instance → Set → Session → PracticeBlock → UserID (4 joins). The FK indexes defined in Section 16 (§16.3.6) ensure these joins are index-backed. TD-06 (Phased Build Plan) must include an RLS join performance validation step in Phase 1 to confirm query planner behaviour at representative data volumes.

5.4 Reference Tables

EventTypeRef, MetricSchema, and SubskillRef are read-only for all authenticated users. SystemMaintenanceLock is similarly read-only. Write operations on these tables are restricted to service-role.

6. Enumeration Strategy

Following Section 16 (§16.1.2):

6.1 Stable Enumerations (Postgres ENUM Types)

21 enum types created. These are architecturally fixed. Adding a value requires a schema migration. Full list: skill_area, drill_type, scoring_mode, input_mode, grid_type, club_type (36 values), drill_origin, drill_status, session_status, club_selection_mode, target_distance_mode, target_size_mode, completion_state, slot_owner_type, closure_type, adoption_status, schedule_app_mode, practice_entry_type, user_club_status, routine_status, schedule_status.

6.2 Extensible Enumerations (Reference Tables)

EventTypeRef and MetricSchema are reference tables with FK enforcement. New values require an INSERT, not a schema migration. However, all EventType values must trace to the canonical enumeration in Section 7 (§7.9) and all MetricSchema definitions must be specified before insertion.

7. Index Coverage

The DDL implements all indexes specified in Section 16 (§16.3.2–§16.3.8) plus all FK column indexes per the governance rule in §16.3.6. Where a FK column is the leading column of an existing composite index, no duplicate single-column index is created.

Notable: ix_session_drill_completion (DrillID, CompletionTimestamp DESC) is the critical window construction index. Window composition queries must use ORDER BY CompletionTimestamp DESC, SessionID DESC to guarantee deterministic window membership when two Sessions share an identical CompletionTimestamp (possible during offline multi-device use). SessionID is the primary key and serves as the tiebreaker; the existing index supports this ordering without modification because the PK is implicitly appended by both Postgres and SQLite query planners. ix_instance_set and ix_set_session support the Instance → Set → Session aggregation chain. ix_session_status uses a partial index (Active only) for the single-active-Session enforcement query.

8. Drift (Local SQLite) Schema Notes

Per TD-01 (§1.3), the Drift local schema mirrors the Postgres schema 1:1 in table names, column names, and column types with the following SQLite-specific adaptations:

-   No ENUM types: Enums stored as TEXT with application-layer validation.

-   No JSONB: JSON columns stored as TEXT. Parsed at read time.

-   No RLS: Single-user local database. All data belongs to the authenticated user.

-   No server-assigned UpdatedAt: Local UpdatedAt is client-assigned. On push, the server reassigns UpdatedAt via trigger. On pull, the server-assigned value overwrites local. All synced tables use UpdatedAt for uniform sync (except EventLog, which uses CreatedAt).

-   TIMESTAMPTZ → INTEGER: Stored as Unix epoch milliseconds.

-   DECIMAL → REAL: SQLite does not have a native DECIMAL type.

-   SyncMetadata table: Local-only table tracking lastSyncCheckpoint per table. Not mirrored to Postgres.

-   Materialised tables: Included locally. Reflow runs client-side (TD-01 §1.2). Same structure, same rebuild-from-raw guarantee.

-   SystemMaintenanceLock and MigrationLog: Server-only. Not present in local schema.

The Drift schema will be generated as a Dart file during TD-06 (Phased Build Plan). This document establishes the parity contract; the exact Drift code is a build-phase deliverable.

9. Seed Data Manifest

002_seed_reference_data.sql populates:

9.1 EventTypeRef (16 rows)

All canonical event types from Section 7 (§7.9), including the three IntegrityFlag events introduced by Section 11, plus three additional types required by TD-03/TD-04: ReflowComplete, SessionCompletion, and RebuildStorageFailure.

9.2 SubskillRef (19 rows)

All subskills from Section 2 (§2.3) with their canonical allocations. Total allocation: 1000 points (Irons 280, Driving 240, Putting 200, Pitching 100, Chipping 100, Woods 50, Bunkers 30).

9.3 MetricSchema (8 rows)

System-defined schemas: grid_1x3_direction, grid_3x1_distance, grid_3x3_multioutput, binary_hit_miss, raw_carry_distance, raw_ball_speed, raw_club_head_speed, technique_duration. Each schema defines its InputMode, plausibility bounds (where applicable), validation rules, and scoring adapter binding.

9.4 System Drills (28 rows)

The complete V1 System Drill Library from Section 14 (§14.4): 7 Technique Blocks, 7 Direction Control drills (1×3 grid), 6 Distance Control drills (3×1 grid), 3 Distance Maximum drills (Raw Data Entry), 3 Shape Control drills (Binary Hit/Miss), and 2 Flight Control drills (Binary Hit/Miss). All use deterministic UUIDs for seed idempotency.

9.5 SystemMaintenanceLock (1 row)

Pre-seeded single row with IsActive = FALSE per Section 16 (§16.4.4).

10. Deferred Items

-   Soft-delete partial indexes: Recommended by Section 16 (§16.3.7) for high-volume tables. Deferred until data volume warrants. The schema functions correctly without them.

-   GIN indexes on JSON columns: Section 16 (§16.3.2) recommends adding only if JSON query performance degrades.

-   Snapshot immutability triggers: Section 16 (§16.6.2) notes BEFORE UPDATE triggers on Instance and PracticeBlock snapshot fields are optional for V1. Application-layer enforcement is sufficient.

-   EventLog archival job: Section 16 (§16.7.4) defines archival to cold storage. Implementation deferred to operational setup phase.

-   Advisory locks: Section 16 (§16.4.3) notes pg_advisory_xact_lock as optional performance enhancement. V1 uses the application-level UserScoringLock table.

11. File Manifest

  ----------------------------- -------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  File                          Purpose                                                        Tables/Objects

  001_create_schema.sql         Complete DDL: tables, enums, triggers, indexes, RLS policies   28 tables, 21 enum types, 17 triggers, 49 indexes (including 16 sync download indexes per TD-03 §5.3.3), 30 RLS policies, 22 CHECK constraints (value range, JSONB type guards, ScoringMode conditional nullability, status/delete consistency, date range), 5 UNIQUE constraints

  002_seed_reference_data.sql   Reference data + V1 System Drill Library                       16 EventTypes, 19 Subskills, 8 MetricSchemas, 28 System Drills, 1 SystemMaintenanceLock row
  ----------------------------- -------------------------------------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

12. Dependency Map

TD-02 is consumed by:

-   TD-03 (API Contract Layer): Table names, column names, and types define the Supabase SDK query surface. RLS policies determine which queries succeed per auth context.

-   TD-04 (Entity State Machines): Status enum values define valid state transitions. Materialised table structure defines reflow output format.

-   TD-05 (Scoring Engine Test Cases): SubskillRef allocations, MetricSchema definitions, and System Drill anchor values are test inputs.

-   TD-06 (Phased Build Plan): Migration files are deployment artifacts. Drift schema parity contract informs Flutter code generation.

-   TD-08 (Claude Code Prompt Architecture): Table names, enum values, and SubskillRef IDs are codebase constants referenced in CLAUDE.md.

End of TD-02 — Database DDL Schema (TD-02v.a6 Canonical)
