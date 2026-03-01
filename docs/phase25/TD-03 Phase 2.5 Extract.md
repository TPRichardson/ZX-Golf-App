# TD-03 API Contract Layer — Phase 2.5 Extract (TD-03v.a5)
Sections: §5 Sync Transport Layer, §8 Authentication & Authorisation
============================================================

## §5 Sync Transport Layer

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


## §8 Authentication & Authorisation

8. Authentication & Authorisation

8.1 Authentication Flow

-   Provider: Google Sign-In via Supabase Auth.

-   Token storage: Supabase client SDK manages JWT storage in secure device storage.

-   Offline behaviour: Local operations do not require a valid JWT. Authentication is only required for sync. Token refresh follows TD-01 §3.3.

-   User creation: On first sign-in, the Supabase Auth trigger creates a User row. The client pulls this row on first sync. Initial account creation is the only operation requiring connectivity.

8.2 Authorisation Model

-   Local: Single-user database. All data belongs to the authenticated user. No local authorisation checks needed beyond the Riverpod provider lifecycle (providers are disposed on logout).

-   Remote: RLS policies on all Supabase tables enforce per-user isolation. The client SDK attaches the JWT to all requests. auth.uid() is extracted server-side. No client-side authorisation headers are manually managed.

