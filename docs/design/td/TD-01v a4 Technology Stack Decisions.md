ZX Golf App — TD-01 Technology Stack Decisions

Version TD-01v.a4

Harmonised with: Product Specification Sections 0–17, Technical Design To-Do (TD-v.a5).

This document records all technology stack, synchronisation, security, and scale decisions for the ZX Golf App application. Every decision is final for V1 implementation. Claude Code must treat this document as authoritative for all platform and infrastructure choices.

1. Core Technology Stack

The following decisions define the application platform, backend, local persistence, state management, authentication, distribution, and notification infrastructure.

1.1 Decision Summary

  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Decision                            Resolution
  ----------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Platform                            Cross-platform via Flutter. Android-first for V1 launch. iOS achievable from the same codebase when required.

  Backend                             Supabase (hosted cloud). Postgres database with built-in authentication, real-time subscriptions, row-level security, and Edge Functions.

  Local Database                      Drift (SQLite) for on-device persistence. Provides full offline capability, strongly typed queries, migration support, and reactive streams.

  State Management                    Riverpod. Provides dependency injection, reactive state, and clean separation between UI and business logic. Pairs with Drift’s reactive database streams.

  Authentication                      Google Sign-In via Supabase Auth. Sole authentication method for V1 (Android). Apple Sign-In is mandatory when iOS is introduced (Apple App Store requirement when third-party sign-in is offered).

  Distribution                        Google Play Store. Internal/closed testing tracks for beta. Manual builds for V1; CI/CD deferred.

  Push Notifications                  Firebase Cloud Messaging (FCM). Supabase Edge Functions trigger FCM for delivery. Used for daily practice reminders (Section 8).
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

1.2 Platform Rationale

Flutter was selected over native Android (Kotlin) for three reasons. First, the ZX Golf App specification contains no platform-specific hardware requirements (no camera, Bluetooth, AR, or NFC), making cross-platform viable without compromise. Second, Flutter enables iOS deployment from the same codebase with minimal platform-specific code, avoiding a full rebuild when iOS is added. Third, the product owner has existing Flutter familiarity, which supports code review and maintenance.

Native Android was rejected because it would require discarding the entire codebase to add iOS later. React Native was considered but Flutter’s Dart language provides stronger typing and better alignment with Drift’s code generation approach.

1.3 Backend Rationale

Supabase was selected because the ZX Golf App data model is heavily relational. Section 6 defines strict foreign key relationships, cascade delete rules, and enumeration table constraints that map directly to Postgres. Firebase Firestore was rejected because its document-oriented NoSQL model would require flattening the relational schema, creating friction at every layer of the build.

Supabase’s built-in features reduce custom backend work: Supabase Auth handles Google Sign-In and JWT token management; Row-Level Security enforces per-user data isolation at the database level; Edge Functions support server-side logic (push notification triggers, System Drill update distribution); real-time subscriptions provide a path to enhanced multi-device sync beyond V1.

1.4 Local Database Rationale

Drift (SQLite) was selected because it provides a relational local database that mirrors the Supabase Postgres schema. Both sides speak SQL with compatible types, which simplifies sync logic. Drift’s code generation produces strongly typed Dart classes from table definitions, eliminating a class of runtime type errors. Its migration system supports schema evolution across app versions.

Drift’s reactive query streams integrate directly with Riverpod, enabling the UI to automatically update when underlying data changes — critical for real-time scoring feedback during Live Practice (Section 13).

Isar and Hive were rejected as NoSQL solutions that would introduce impedance mismatch with the relational server schema.

1.5 State Management Rationale

Riverpod was selected for its strong typing, testability, and natural pairing with Drift’s reactive streams. It provides clear dependency injection patterns, which is important when Claude Code builds modules independently across build phases — each module can declare its dependencies explicitly rather than relying on implicit global state.

BLoC was considered but adds boilerplate that increases Claude Code’s output volume without proportional benefit. Provider was rejected as Riverpod’s predecessor with known limitations. GetX was rejected for producing loosely structured codebases.

2. Synchronisation Strategy

Offline-first is an architectural constraint for ZX Golf App, not an implementation detail. Section 17 requires all core operations to function without network connectivity. The sync strategy defined here affects DDL design, API contract, ID generation, and state machine behaviour. All subsequent TD documents must conform to these decisions.

ZX Golf App uses a Deterministic Merge-and-Rebuild synchronisation model (Section 0, §0v.f1). Raw execution data is merged additively, structural edits are resolved via Last-Write-Wins (LWW), and each device then rebuilds all materialised scoring state locally via deterministic reflow. No device and no server holds authoritative scoring state. All devices converge to identical results from identical raw data.

2.1 Decision Summary

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Decision                            Resolution
  ----------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Sync Transport                      Timestamp-based upload/download. On reconnection, the device uploads all locally modified rows, then downloads all server rows with UpdatedAt greater than the last sync timestamp. Bidirectional.

  Conflict Detection                  Timestamp-based. Conflicts are identified when the same entity has been modified both locally and on the server since the last sync (both have UpdatedAt greater than last sync time).

  Conflict Resolution                 Last-Write-Wins (LWW) by UpdatedAt timestamp for structural edits. Soft-deletes use forward-only propagation (see §2.3 Merge Precedence). The record with the later timestamp survives for non-delete conflicts. The losing edit is silently discarded.

  Soft-Delete Propagation             Forward-only. Soft-delete flags (IsDeleted = true) always propagate forward and are never reversed by sync. This overrides LWW semantics — a delete always wins regardless of timestamp. See §2.3 for the formal merge precedence table.

  ID Generation                       Client-generated UUID v4. Every entity receives its UUID at creation time on-device, before any server contact. Supabase Postgres accepts UUIDs natively as primary keys. No temporary ID swapping required.

  Tombstone Strategy                  Existing IsDeleted soft-delete flags (already specified in Section 6). Sync queries include soft-deleted records so the local database can mark them deleted. No separate tombstone table required for V1.

  Sync Granularity                    Row-level. Each entity row is the unit of sync. One exception: CalendarDay Slot assignments use Slot-level LWW within the Slots JSON array (see §2.4). No operation log.

  Reflow on Sync                      Automatic, non-blocking. After sync merge completes, a full deterministic rebuild executes locally from raw Instance data. This is not a Section 7 scoring lock — it is a background reconciliation process. The user continues to interact with the application normally during rebuild. User-initiated reflows take priority; sync rebuilds defer until any active user-initiated reflow completes.

  Materialised State                  Never synced. MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, and MaterialisedOverallScore are local-only. They are rebuilt locally after each sync via deterministic reflow.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

2.2 Authority Model

The sync model has three distinct authority layers. Making these explicit prevents confusion between the “no authoritative scoring state” principle and the reality that structural definitions do have a central authority.

-   Structural definitions → server-authoritative. System Drill definitions, Skill Area allocations, Subskill allocations, 65/35 weighting, and scoring formula are centrally governed. The server publishes these; devices consume them. The server is authoritative over structural configuration.

-   Execution data → additive merge. PracticeBlocks, Sessions, Sets, Instances, and EventLog entries are append-only and merged additively. No device or server may discard raw execution data during sync. User Custom Drill definitions, club configuration, Routine and Schedule definitions, CalendarDay Slot assignments, and user Settings are resolved via LWW.

-   Scoring → deterministic local projection. All scoring is performed locally on-device via deterministic reflow. The server does not execute reflow, does not maintain materialised scoring state, and does not resolve scoring calculations. Every device converges to identical scoring state from identical raw data.

2.3 Merge Precedence

Soft-delete forward propagation creates an asymmetry with the general LWW model. The following table formalises the merge precedence for all conflict scenarios. This precedence must be enforced in the merge logic defined by TD-03.

  ----------------------------------------------------------------------------------------------
  Local State       Remote State      Result                 Rule
  ----------------- ----------------- ---------------------- -----------------------------------
  Updated           Updated           Later UpdatedAt wins   Standard LWW

  Updated           Deleted           Deleted                Delete always wins (forward-only)

  Deleted           Updated           Deleted                Delete always wins (forward-only)

  Deleted           Deleted           Deleted                Convergent
  ----------------------------------------------------------------------------------------------

This table applies to all synced entities with IsDeleted flags. The delete-always-wins rule is a specific exception to LWW that ensures destructive operations are never silently reversed by stale data arriving from another device. TD-03 must implement this precedence in the merge function. TD-04 must reflect it in entity state machine transitions.

2.4 CalendarDay Slot-Level Merge

CalendarDay is the sole exception to the row-level sync granularity rule. Its Slots column is a JSON array where each Slot position may be independently edited on different devices. Pure row-level LWW would discard all Slot edits from the losing device, even if they affected different Slot positions. Section 17 (§17.4.2) specifies Slot-level LWW to prevent this.

The merge rule for CalendarDay is: compare each Slot position independently. For a given Slot position, if Device A wrote it at 10:00 UTC and Device B wrote it at 10:05 UTC, Device B’s assignment wins for that position. Other Slot positions are unaffected. SlotCapacity uses standard row-level LWW (later UpdatedAt wins).

This is field-level merge logic applied to a single entity. It is acknowledged as a deviation from the “no field-level merge” baseline and is intentionally scoped to CalendarDay only. No other entity requires intra-row merge semantics in V1. TD-03 must define the Slot-level merge algorithm. TD-04 must model the CalendarDay Slot state transitions that result from this merge behaviour.

2.5 Sync Pipeline

The Sync Pipeline (Section 17, §17.4.3) executes the following six steps in order. Section 17 is the canonical authority for the full sync pipeline specification. TD-01 records the high-level decisions; Section 17 defines the detailed execution model.

Step 1 — Upload Local Changes

The device transmits all locally created or modified entities since its last successful sync timestamp to the server. This includes new raw execution data, structural edits, soft-delete flags, and EventLog entries. To guarantee atomicity, the upload must be wrapped in a single server-side transaction. TD-03 must define a Supabase RPC function that accepts the full change payload and applies it atomically. If the transaction fails, no partial upload is committed.

Step 2 — Download Remote Changes

The device receives all entities created or modified by other devices (or centrally) since its last successful sync timestamp. This includes raw execution data from other devices, structural edits, soft-delete flags, System Drill updates, and EventLog entries. Soft-deleted rows are included (not filtered by IsDeleted). The download query should use a consistent snapshot (REPEATABLE READ) to ensure internal consistency of the pulled data set.

Step 3 — Merge

Applied locally within a single Drift transaction. Raw execution data is appended additively. Structural configuration is resolved via the merge precedence table (§2.3). Soft-deletes propagate forward (never reversed). CalendarDay Slots are merged per-position (§2.4). System Drill definitions are updated to the latest central version. If the local merge transaction fails, it rolls back completely and sync retries on the next trigger.

Step 4 — Completion Matching

Calendar completion matching (Section 8, §8.3.2) re-runs against all newly merged Closed Sessions. Matching follows standard rules: date-strict in user’s home timezone, DrillID matching, first-match ordering for duplicates. Completion overflow (Section 8, §8.3.3) applies normally if a merged Session has no matching Slot.

Step 5 — Deterministic Rebuild

A full local deterministic reflow executes from raw Instance data and the current structural parameters (post-merge). All materialised scoring tables are rebuilt atomically. This guarantees convergence: every device produces identical scoring state from identical raw data. This rebuild is non-blocking — the Section 7 full scoring lock does not apply (Section 17, §17.4.5).

Step 6 — Confirm

The device’s last successful sync timestamp is updated. The sync cycle is complete.

During offline periods, all operations execute against the local Drift database. No operations are blocked by lack of connectivity. The sync queue accumulates naturally as locally modified rows.

2.6 Sync Atomicity

Each stage of the sync pipeline has explicit transaction boundaries:

-   Upload (Step 1): Wrapped in a single Supabase RPC function executing within a Postgres transaction. Either all changes are applied or none are. TD-03 must define this RPC function.

-   Download (Step 2): Uses a consistent snapshot query. Read-only; no atomicity risk.

-   Merge (Step 3): Wrapped in a single Drift (SQLite) transaction. Either the full merge is applied locally or it rolls back completely.

-   Completion matching and rebuild (Steps 4–5): Executes within the same local transaction as merge, or immediately after. Deterministic; no partial state possible.

If sync fails at any stage (network interruption, server unavailability, transaction failure), no partial merge is committed. The device continues operating against its current local state. Sync retries automatically on the next trigger (connectivity restore or periodic interval). No data loss occurs. No user action is required for recovery.

2.7 Cross-Device Session Concurrency

The single active Session per user rule (Section 3, §3.5; Section 13, §13.5.2) is enforced differently depending on connectivity context. Section 17 (§17.4.7) is the canonical authority.

-   Same device: Single active Session enforced at runtime. Unchanged from Section 3 and Section 13.

-   Cross-device while online: Server-mediated conflict detection. If a second device attempts to start a Session while another device has an active Session, a warning is displayed. On confirmation, the previous Session is hard discarded and the new Session becomes authoritative.

-   Cross-device while offline: No runtime enforcement is possible. Both devices may independently start and complete Sessions. This is accepted by design. On sync, both Sessions merge and enter Subskill windows chronologically by CompletionTimestamp. No data is discarded. Offline overlap is considered a valid edge case and not a violation.

2.8 System Drill Update Delivery

The V1 System Drill Library (28 drills, Section 14) is bundled with the application binary at install time. Users have immediate access to all System Drills without requiring network connectivity after initial account creation.

System Drill updates published centrally are delivered to devices via the standard sync pipeline (Step 2: Download Remote Changes). On receipt, the updated definition replaces the local copy and a full local reflow is triggered automatically as part of the sync deterministic rebuild (Step 5). No user action is required.

2.9 Schema Version Gating

Sync requires matching schema versions between the device’s local database and the server’s current canonical schema (Section 17, §17.4.9).

-   If a device’s local schema version is older than the server’s current canonical schema, sync is blocked.

-   A clear message is displayed: “App update required to sync.”

-   The device continues to function fully offline against its current local schema while awaiting the app update. No data loss. No degradation.

-   On app update, the application runs any required local schema migrations, then sync proceeds normally with a full deterministic rebuild.

-   All schema migrations must preserve backward compatibility of raw execution entities. Data logged under an older schema version must remain valid and interpretable after migration.

2.10 DDL Implications

The sync strategy requires the following in TD-02 (Database DDL):

-   Every synced table must have UpdatedAt (timestamp, UTC, NOT NULL) with automatic update on any row modification. Exception: EventLog is append-only with no updates or deletes. It carries CreatedAt only and syncs via CreatedAt > lastSyncCheckpoint. No UpdatedAt column or trigger is required on EventLog.

-   Synced tables that support user-initiated deletion must have IsDeleted (boolean, default false) for soft-delete tombstone support. The following exception categories are exempt from this requirement: (a) Account-lifecycle tables (User) — account deletion is a separate administrative operation outside sync; (b) Ephemeral/UI-layer tables (PracticeEntry) — hard-deleted at PracticeBlock close, not recoverable by design; (c) Status-managed tables (UserClub) — lifecycle governed by status enum, not soft-delete; (d) Insert-only/time-versioned tables (ClubPerformanceProfile) — new entries supersede old ones, never deleted; (e) Insert/hard-delete tables (UserSkillAreaClubMapping, RoutineInstance, ScheduleInstance) — entities are fully replaced on edit, hard-delete is the correct semantic; (f) Permanent-once-created tables (CalendarDay) — created on first use, never deleted, content managed via Slot updates. Tables with IsDeleted: Drill, PracticeBlock, Session, Set, Instance, UserDrillAdoption, Routine, Schedule, UserDevice.

-   A local-only SyncMetadata table storing lastSyncTimestamp per table (or global).

-   Client-generated UUID v4 as primary key type for all entities.

-   Tables classified as local-only (e.g. SyncMetadata, local UI state, materialised scoring tables) are excluded from sync.

-   Four materialised scoring tables (MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore) are included in the local schema as the output destination of the pure rebuild engine (see §4.3). These are never synced.

2.11 Future Sync Evolution

The V1 sync strategy is deliberately simple. The following enhancements are available as future levers without architectural rework:

-   Real-time subscriptions: Supabase supports Postgres LISTEN/NOTIFY for real-time change streams. Can be layered on top of the upload/download mechanism for instant multi-device sync when online.

-   Field-level merge: If LWW proves too coarse for entities beyond CalendarDay, per-field conflict resolution can be added by comparing individual column timestamps. Requires adding per-field UpdatedAt or a change log.

-   Operation-level sync: If event sourcing becomes necessary, the existing EventLog table provides a foundation for operation replay.

3. Security Requirements

ZX Golf App stores golf practice data with low inherent sensitivity (no financial, health, or identity data). Security measures are proportionate to this risk level while following platform best practices.

3.1 Decision Summary

  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Decision                            Resolution
  ----------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Local DB Encryption                 Not required for V1. Android’s file-based encryption (FBE), enabled by default on all devices running Android 10+, protects app data at rest when the device is locked. SQLCipher is not added. Threat model explicitly excludes rooted-device attackers for V1 — the local SQLite database could be extracted from a rooted device, exposing practice data and the user’s email/UID linkage. This is accepted as proportionate to the data sensitivity. Revisit if sensitive data features are introduced.

  Server-Side RLS                     Supabase Row-Level Security enabled from day one. Every table with user data carries a policy: UserID = auth.uid(). Enforced at the Postgres level — application bugs cannot bypass it.

  Authentication Tokens               Supabase Auth manages JWT access tokens and refresh tokens. Access tokens are short-lived. Refresh tokens handle re-authentication. During offline periods, the app operates against the local database; re-authentication occurs on next connectivity. No offline work is lost.

  Data in Transit                     HTTPS enforced by default on all Supabase connections. No additional transport security required.

  Data at Rest (Server)               Supabase cloud encrypts Postgres data at rest by default (AES-256). No additional configuration required.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

3.2 RLS Policy Pattern

The standard RLS policy for all user-scoped tables follows this pattern:

-   SELECT: WHERE UserID = auth.uid() — users can only read their own data.

-   INSERT: WITH CHECK (UserID = auth.uid()) — users can only create records owned by themselves.

-   UPDATE: WHERE UserID = auth.uid() — users can only modify their own data.

-   DELETE: WHERE UserID = auth.uid() — users can only delete their own data.

Tables without a direct UserID (e.g. Set, Instance) inherit access control through their parent foreign key chain: Instance → Set → Session → PracticeBlock → UserID. RLS policies on child tables join to parent tables to verify ownership. The deepest chain is four joins. TD-06 (Build Plan) must include a performance validation step in Phase 1 to confirm RLS join query planner behaviour at representative data volumes.

Reference tables (ClubType, SkillArea, Subskill, EventType) are read-only for all authenticated users. No user-specific data exists in these tables.

3.3 Token Lifecycle During Offline Periods

When the app is offline, the JWT access token will eventually expire. On reconnection:

-   The Supabase client SDK automatically attempts to refresh the token using the stored refresh token.

-   If the refresh token is still valid, a new access token is issued silently. Sync proceeds normally.

-   If the refresh token has also expired (extended offline period), the user is prompted to re-authenticate via Google Sign-In. No local data is lost — the app continues to function offline until authentication is restored, at which point queued sync operations execute.

4. Scale Assumptions

The following estimates define the performance envelope for V1. They inform database indexing strategy (TD-02), scoring engine design (TD-05), and build phase acceptance criteria (TD-06). These are design ceilings, not expected averages.

4.1 Data Volume Ceilings

  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Decision                            Resolution
  ----------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Max Sessions per User               20,000 over product lifetime. Equivalent to approximately 10 years of heavy daily practice (5–6 drills per day).

  Max Instances per Session           100. Bounded by drill structure: a structured drill with 5 Sets of 20 attempts produces 100 Instances. Unstructured drills are open-ended but 100 is a practical ceiling.

  Max Total Instances                 2,000,000 (20,000 Sessions × 100 Instances). This is the theoretical maximum; realistic lifetime total is likely 200,000–500,000. Performance targets (§4.2) are validated against the realistic range, not the theoretical maximum. The 2M figure is a stress-test ceiling, not a target-tested volume.

  Window Size                         25 occupancy units (fixed, per Section 0). Window rebuild scans at most 25 Sessions per subskill.

  Max Active Drills                   No hard limit specified. Practical ceiling of 200–300 drills per user based on 7 Skill Areas with subskills.
  ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

4.2 Performance Targets

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Decision                            Resolution
  ----------------------------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Target Device Baseline              2020 mid-range Android (e.g. Samsung Galaxy A51: Exynos 9611, 4GB RAM). All performance targets must be met on this hardware class.

  Single-Drill Reflow                 < 200ms. An anchor edit on one drill triggers window recomposition and score recalculation for affected subskills. Must feel instantaneous — no spinner required.

  Full Reflow                         < 500ms. Triggered by allocation weight changes affecting all subskill windows. Brief loading indicator acceptable.

  Cold-Start to SkillScore            < 1 second from app launch to SkillScore visible on dashboard. Local Drift database serves dashboard data; network sync occurs in background after UI is populated.

  Instance Logging Latency            < 50ms per Instance write to local DB during Live Practice. Must not create perceptible lag during rapid data entry.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

These performance targets depend on proper composite indexing. TD-02 defines the index strategy; TD-06 must include index-backed performance validation for each target. The bounded window size (25 occupancy units) ensures window composition cost is constant, but Session aggregation (Instance → Set → Session) traverses the full Instance set for a Session. At the realistic volume ceiling (200,000–500,000 Instances), this is manageable with FK indexes. At the 2M theoretical maximum, query planner behaviour on the target device must be verified. If performance degrades at high volumes, bounded timestamp scans and partial indexes are available as optimisation levers.

4.3 Cold-Start Edge Cases

The < 1 second cold-start target assumes materialised tables are already populated. The following edge cases may exceed this target:

-   App crash mid-reflow (empty materialised tables): Materialised tables must be rebuilt from raw data. The app should display the SkillScore shell immediately and populate scores asynchronously, showing a brief loading indicator.

-   Schema migration on first launch after update: Drift runs schema migration before UI population. Migrations must be designed to complete within the 1-second budget or the UI must display a one-time migration progress indicator.

-   First launch (no data): No scoring data exists. Dashboard displays zero state immediately with no computation required.

4.4 Local Storage Envelope

Estimated local SQLite database size at various volume levels:

  -------------------------------------------------------------------------------------------
  Volume                         Estimated Instance Rows   Estimated DB Size (with indexes)
  ------------------------------ ------------------------- ----------------------------------
  Light user (2 years)           20,000–50,000             15–40 MB

  Heavy user (5 years)           100,000–250,000           80–200 MB

  Realistic ceiling (10 years)   200,000–500,000           150–400 MB

  Theoretical maximum            2,000,000                 ~600 MB+
  -------------------------------------------------------------------------------------------

At the realistic ceiling, the local database is well within the storage capacity of the target device class. At the theoretical maximum (600 MB+), storage could become a concern on devices with limited free space. Section 17 (§17.3.5) specifies that the application displays a warning if device storage is critically low but does not auto-delete any user data. Optional local archival of synced EventLog entries is deferred to V2.

4.5 Scoring Engine & Materialised State

Given the window size of 25 occupancy units and the performance targets above, the scoring engine operates as a pure rebuild. When reflow fires, it recalculates all derived state from raw Instance data every time. It never patches or incrementally updates a previous result.

The engine writes its output to four materialised tables (MaterialisedWindowState, MaterialisedSubskillScore, MaterialisedSkillAreaScore, MaterialisedOverallScore), which are defined in Section 16 (§16.1.6) and implemented in TD-02. These materialised tables are a replaceable cache, not a source of truth (Section 7, §7.11.1; Section 16, §16.7.3). They can be truncated and fully rebuilt from raw Instance data at any time. The reflow atomic swap (Section 16, §16.4.5) writes the rebuild results to these tables within a Serializable transaction. Between reflows, reads are served from this cache to avoid per-read recalculation.

The architecture is: raw data → pure rebuild calculation → atomic write to materialised cache. Raw Instance data is the single source of truth. Materialised tables are a deterministic projection of that data.

Key design steps:

-   Window composition: Query the most recent Sessions for a subskill, sum occupancy until 25 units reached. With proper indexing (Session timestamp + DrillID + SubskillID), this is a bounded scan.

-   Score derivation: Instance 0–5 scores, Session scores, Subskill scores, Skill Area scores, and Overall SkillScore are computed from current raw data and written to materialised tables.

-   Reflow: Re-run the derivation pipeline for affected subskills. The bounded window size (25 units) ensures the input set is small regardless of total Session count.

5. Dependency Map

The following documents directly depend on decisions made in this document:

-   TD-02 (Database DDL): SQL dialect (Postgres for Supabase, SQLite for Drift), sync columns (UpdatedAt, IsDeleted), EventLog CreatedAt-only exception, UUID primary keys, RLS policies, materialised table inclusion.

-   TD-03 (API Contract): Supabase client SDK patterns, sync upload RPC function (atomic transaction wrapper), Supabase RPC functions vs direct table access, CalendarDay Slot-level merge algorithm, merge precedence implementation, offline queue structure, authentication headers.

-   TD-04 (State Machines): Non-blocking reflow-on-sync trigger, offline state transitions, sync conflict as implicit state event, cross-device session concurrency handling, merge precedence table as state transition input, CalendarDay Slot merge state transitions.

-   TD-05 (Scoring Test Cases): Pure rebuild assumption, materialised table output format, performance targets as acceptance criteria.

-   TD-06 (Build Plan): Flutter project structure, Drift code generation pipeline, Supabase project setup as Phase 1 prerequisites, schema version migration path, RLS join performance validation step in Phase 1, index-backed performance validation for all targets in §4.2.

-   TD-07 (Error Handling): Supabase error codes, Drift transaction failure modes, FCM delivery failure handling, sync failure/recovery model, sync atomicity guarantees per stage.

-   TD-08 (Prompt Architecture): Flutter/Dart conventions, Drift table definition patterns, Riverpod provider patterns for CLAUDE.md.

6. Version History

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Version                             Changes
  ----------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  TD-01v.a1                           Initial version. All decisions locked for V1 implementation.

  TD-01v.a2                           Sync pipeline corrected to upload-then-download order per Section 17 (§17.4.3). Full 6-step pipeline adopted. Post-sync reflow changed from standard scoring lock to non-blocking background rebuild per Section 17 (§17.4.5). Added: formal merge precedence table (§2.3), CalendarDay Slot-level merge exception with explicit acknowledgement of field-level deviation (§2.4), authority model clarifying structural vs execution vs scoring authority (§2.2), cross-device session concurrency rules (§2.7), System Drill update delivery model (§2.8), sync atomicity with per-stage transaction boundaries and TD-03 RPC function requirement (§2.6), schema version gating (§2.9), EventLog CreatedAt-only sync exception in DDL implications (§2.10). Materialised tables confirmed for V1 as replaceable cache (§4.5). Added local storage envelope estimates (§4.4), cold-start edge cases (§4.3), performance target dependency on indexing. Security: explicit rooted-device threat model exclusion, RLS performance validation requirement for TD-06. Adopted canonical terminology (Deterministic Merge-and-Rebuild, LWW, Sync Pipeline). Apple Sign-In noted as mandatory iOS requirement. TD-00 reference updated to v.a5.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End of TD-01 Technology Stack Decisions — Version TD-01v.a4
