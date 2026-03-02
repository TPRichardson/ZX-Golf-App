TD-07 — Error Handling Patterns

Version TD-07v.a4 — Canonical

Harmonised with: Section 0 (0v.f1), Section 1 (1v.g2), Section 3 (3v.g8), Section 7 (7v.b9), Section 11 (11v.a5), Section 15 (15v.a3), Section 16 (16v.a5), Section 17 (17v.a4), TD-01 (TD-01v.a4), TD-02 (TD-02v.a6), TD-03 (TD-03v.a5), TD-04 (TD-04v.a4), TD-05 (TD-05v.a3), TD-06 (TD-06v.a6).

1. Purpose

This document defines the error handling patterns for ZX Golf App. It specifies how every category of failure is detected, categorised, communicated to the user, recovered from, and logged. The product specification and preceding technical design documents define what happens when things go right. TD-07 defines what happens when they go wrong.

The offline-first architecture (TD-01 §2) means the app must function without network connectivity. Errors therefore fall into two fundamentally different classes: local errors (scoring, database, state machine violations) that are unrelated to connectivity, and remote errors (sync transport, merge, authentication) that depend on it. TD-07 treats these separately because their recovery strategies differ.

TD-03 §7 established the error type hierarchy (ZxGolfAppException and its subclasses) and the error response contract for Repository methods. TD-07 expands this into concrete patterns: which exception is thrown in each failure scenario, what the user sees, what is logged, and what recovery path is available.

Deliverable: This specification document. Claude Code consumes it to implement error handling, user-facing messaging, retry logic, and diagnostic logging across all phases.

2. Error Type Hierarchy

TD-03 §7.2 defines the base exception class and categories. This section consolidates the complete hierarchy with the specific exception types used throughout this document.

2.1 Base Class

All application errors extend ZxGolfAppException, which carries a machine-readable code (String), a human-readable message (String), and an optional context map (Map<String, dynamic>) for diagnostic metadata. The code field uses the CATEGORY_SPECIFIC_ERROR naming convention (e.g. SYNC_UPLOAD_FAILED, VALIDATION_INVALID_ANCHORS).

2.2 Exception Categories

  ------------ -------------- ---------------------------------------------- -------------------------------------------
  Category     Prefix         Scope                                          User Impact

  Validation   VALIDATION_*   Input rejected before persistence              Inline field error; operation blocked

  Reflow       REFLOW_*       Scoring pipeline failure                       Temporary scoring freeze; auto-recovery

  Sync         SYNC_*         Transport or merge failure                     Sync deferred; local operation unaffected

  System       SYSTEM_*       Infrastructure failure (DB, storage, memory)   Feature degradation; may require restart

  Conflict     CONFLICT_*     Cross-device state divergence                  Informational; auto-resolved or surfaced

  Auth         AUTH_*         Authentication or authorisation failure        Re-authentication prompt; local data safe
  ------------ -------------- ---------------------------------------------- -------------------------------------------

2.3 Complete Exception Catalogue

The following table enumerates every exception code used in the application. Each code maps to exactly one recovery pattern defined in subsequent sections.

  ---------------------------------- ------------------------------------------ --------------------------------
  Code                               Thrown By                                  Recovery Pattern

  VALIDATION_INVALID_ANCHORS         DrillRepository.createDrill, editAnchors   §4.1 — Inline validation

  VALIDATION_INVALID_STRUCTURE       DrillRepository.createDrill                §4.1 — Inline validation

  VALIDATION_REQUIRED_FIELD          Any Repository create/update               §4.1 — Inline validation

  VALIDATION_STATE_TRANSITION        Any Repository state change                §4.2 — Guard rejection

  VALIDATION_DUPLICATE_ENTRY         Repository insert operations               §4.1 — Inline validation

  VALIDATION_SINGLE_ACTIVE_SESSION   PracticeRepository.startSession            §4.3 — Active Session conflict

  REFLOW_LOCK_TIMEOUT                ScoringRepository.executeReflow            §5.1 — Lock retry exhaustion

  REFLOW_TRANSACTION_FAILED          ScoringRepository.executeReflow            §5.2 — Transaction rollback

  REFLOW_REBUILD_TIMEOUT             ScoringRepository.executeFullRebuild       §5.3 — Rebuild timeout

  SYNC_UPLOAD_FAILED                 SyncEngine.upload                          §6.1 — Transport retry

  SYNC_DOWNLOAD_FAILED               SyncEngine.download                        §6.1 — Transport retry

  SYNC_MERGE_FAILED                  SyncEngine.merge                           §6.2 — Merge rollback

  SYNC_MERGE_TIMEOUT                 SyncWriteGate (60s hard timeout)           §6.3 — Gate timeout

  SYNC_SCHEMA_MISMATCH               SyncEngine.validateSchema                  §6.4 — Schema version block

  SYNC_PAYLOAD_TOO_LARGE             SyncEngine.upload                          §6.5 — Payload splitting

  SYNC_NETWORK_UNAVAILABLE           ConnectivityMonitor                        §6.6 — Offline deferral

  SYSTEM_DATABASE_CORRUPT            Drift startup or query                     §7.1 — Database recovery

  SYSTEM_STORAGE_FULL                Drift write operation                      §7.2 — Storage pressure

  SYSTEM_OUT_OF_MEMORY               Reflow or rebuild at scale                 §7.3 — Memory pressure

  SYSTEM_MIGRATION_FAILED            Drift schema migration                     §7.4 — Migration failure

  SYSTEM_REFERENTIAL_INTEGRITY       Drift FK constraint violation              §14.1 — Referential integrity

  CONFLICT_DUAL_ACTIVE_SESSION       SyncEngine.merge (Session)                 §8.1 — LWW resolution

  CONFLICT_STRUCTURAL_DIVERGENCE     SyncEngine.merge (Drill, etc.)             §8.2 — Silent LWW merge

  CONFLICT_SLOT_COLLISION            SyncEngine.merge (CalendarDay)             §8.3 — Slot-level merge

  AUTH_TOKEN_EXPIRED                 Supabase client                            §9.1 — Token refresh

  AUTH_REFRESH_FAILED                Supabase client                            §9.2 — Re-authentication

  AUTH_SESSION_REVOKED               Supabase client                            §9.3 — Forced re-auth
  ---------------------------------- ------------------------------------------ --------------------------------

3. Error Propagation Model

Errors propagate through three layers: Repository, Provider, and UI. Each layer has a distinct responsibility.

3.1 Repository Layer

Repository methods throw typed ZxGolfAppException subclasses. They never catch and swallow exceptions silently. Every thrown exception carries a diagnostic context map with at minimum: the operation name, the entity type, and the entity ID (where applicable). Repository methods wrap Drift transactions in try-catch blocks. If a Drift transaction fails, the Repository wraps the underlying DatabaseException in the appropriate ZxGolfAppException subclass before re-throwing.

3.2 Riverpod Provider Layer

Providers expose errors as AsyncError states on AsyncValue. When a Repository method throws, the provider transitions to AsyncError with the ZxGolfAppException as the error object. Providers never catch exceptions for the purpose of suppressing them. Providers may catch exceptions for the purpose of mapping them to a more specific AsyncError state (e.g. adding retry metadata).

Reactive streams (Drift watch queries) emit errors through the stream error channel. The provider surfaces these as AsyncError. Stream errors do not terminate the stream; the provider remains subscribed and will emit the next successful value when the underlying query succeeds.

3.3 UI Layer

The UI layer consumes AsyncValue and renders error states using a consistent ErrorDisplay widget. The widget pattern is defined in §10. The UI never catches exceptions directly from Repository calls; all error handling flows through Riverpod’s AsyncValue.when() pattern.

Unhandled exceptions that escape the Riverpod error boundary are caught by a top-level FlutterError.onError handler and the Dart Zone error handler. These log the error (domain: system, level: error) and display a generic fallback error message. The app does not crash on unhandled exceptions; it degrades gracefully.

4. Validation Errors

Validation errors are the most common error category. They are caused by user input that violates domain rules. They are always preventable by the UI layer (i.e. the UI should make it difficult or impossible to submit invalid input), but the Repository layer enforces validation as a safety net.

4.1 Inline Field Validation

Validation rules are evaluated at two points: eagerly in the UI (on field change or form submission) and defensively in the Repository (on write). The UI validation is the primary enforcement mechanism. The Repository validation is the safety net that guarantees invalid data never reaches the database.

Anchor validation (TD-05 §13): Min < Scratch < Pro (strictly increasing). Evaluated on each field change. If violated, the Save button is disabled and an inline message states the constraint (e.g. “Min must be less than Scratch”). The Repository throws VALIDATION_INVALID_ANCHORS if the UI check is bypassed.

Structural identity (TD-04 §2.4.2): Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, RequiredAttemptsPerSet, Club Selection Mode, and Target Definition are immutable post-creation. The UI hides edit affordances for these fields on existing drills. The Repository throws VALIDATION_INVALID_STRUCTURE if an edit attempts to change an immutable field.

Required fields: The Repository validates that all non-nullable columns have values before insert. Missing required fields throw VALIDATION_REQUIRED_FIELD with context identifying the missing field name.

4.2 State Transition Guard Rejection

Every state machine transition defined in TD-04 has a guard condition. If the guard fails, the Repository throws VALIDATION_STATE_TRANSITION with context containing: the entity type, the current state, the attempted target state, and the guard that failed.

The UI layer prevents most invalid transitions by hiding or disabling action affordances that are not available in the current state (e.g. the End Drill button is not shown for a Session that is not Active). The guard rejection at the Repository layer is a safety net for race conditions where the entity state changed between UI render and user tap.

User message: “This action is no longer available. The screen will refresh.” The UI re-reads the entity state and re-renders. No retry is needed; the UI update resolves the stale state.

4.3 Active Session Conflict

The single-active-Session rule (TD-04 §2.2) prohibits starting a new Session while another Session is Active on the same device. If the user attempts to start a Session and an Active Session exists, the Repository throws VALIDATION_SINGLE_ACTIVE_SESSION.

User message: “You have an active session in progress. End or discard it before starting a new one.” The UI navigates to the active Session or offers a discard action.

Cross-device active Session conflict is a sync concern, handled in §8.1.

5. Reflow Errors

The reflow pipeline (TD-04 §3) is the most architecturally critical error domain. Because reflow is a pure deterministic rebuild from raw data, most reflow errors are recoverable by re-running the pipeline. The primary risk is not incorrect results but temporary scoring unavailability.

5.1 Lock Retry Exhaustion

When ScoringRepository.executeReflow attempts to acquire UserScoringLock and the lock is already held by another reflow, it retries up to 3 times at 500ms intervals (TD-04 §3.2, Step 1). If all retries fail:

Exception: REFLOW_LOCK_TIMEOUT.

Diagnostic log: Domain: scoring, Level: warning. Context: trigger type, lock holder timestamp, retry count.

Recovery: The reflow trigger is enqueued for deferred execution (same mechanism as TD-04 §3.3.3 deferred coalescing). When the current lock holder releases, the deferred queue drains. No user intervention is required.

User impact: The UI displays a brief loading indicator on the affected score displays. The indicator dismisses when the deferred reflow completes. If the deferred reflow has not completed within 5 seconds, the indicator text changes to “Scores are updating. This may take a moment.”

Escalation: If the deferred reflow also times out (i.e. the lock is perpetually held), the expired-lock recovery path activates: after 30 seconds the lock expires, the next operation force-acquires, and a full rebuild executes (TD-04 §3.4.1). This is the terminal recovery path for all lock contention scenarios.

5.2 Transaction Rollback

If the Drift transaction wrapping the reflow algorithm (Steps 1–10) fails at any step:

Exception: REFLOW_TRANSACTION_FAILED.

Diagnostic log: Domain: scoring, Level: error. Context: trigger type, step number where failure occurred, underlying Drift exception message.

Recovery: The Drift transaction rolls back completely. No partial materialised state is written. The scoring lock is released in a finally block (Step 10 always executes, even on error). The reflow trigger is re-enqueued for immediate retry (single retry). If the retry also fails, the trigger is enqueued with a 2-second delay. If the delayed retry fails, the system logs at error level and falls back to the expired-lock full-rebuild recovery path on next app launch.

User impact: Materialised scores remain at their pre-reflow values. These values are stale but consistent (they represent the state before the triggering edit). The user sees no corruption — only a delay in score updates.

5.3 Rebuild Timeout

The full rebuild (TD-04 §3.3, post-sync) is bounded by the RebuildGuard 30-second timeout. If the rebuild exceeds this:

Exception: REFLOW_REBUILD_TIMEOUT.

Diagnostic log: Domain: scoring, Level: error. Context: elapsed duration, subskill count processed before timeout, Instance count in database.

Recovery: The Drift transaction rolls back. Materialised tables retain their pre-rebuild state. A retry is scheduled on next app foreground event. The profiling benchmark harness (TD-06 §7.1.2) is designed to catch this scenario in testing; a rebuild timeout in production indicates data volumes exceeding the tested envelope.

User impact: “Scores are temporarily unavailable. They will update shortly.” Scores display the last known values with a subtle staleness indicator (dimmed opacity, not a warning colour).

5.4 Crash Mid-Reflow

If the app is force-killed or crashes between Steps 1 and 10 of the reflow algorithm:

Detection: On next app launch, the startup sequence checks UserScoringLock. If IsLocked = true and LockExpiresAt < now, the lock is expired.

Recovery: The startup sequence force-acquires the lock and initiates a full rebuild (executeFullRebuild). Because reflow is a pure function of raw data plus current structural parameters, re-running produces identical results (TD-04 §3.4.1). No user intervention is required.

Diagnostic log: Domain: scoring, Level: warning. Context: expired lock timestamp, time since expiry.

User impact: The user sees the standard cold-start loading state. The full rebuild adds to the startup time. At typical data volumes (under 5K Sessions / 50K Instances), the rebuild completes within the 1-second cold-start target (TD-01 §4.2). At higher data volumes approaching the 50K Sessions / 500K Instances ceiling, the full rebuild may exceed 1 second. The Phase 2B profiling benchmark harness validates the actual rebuild duration at target volumes; if the 1-second cold-start target cannot be met at high volumes during a crash-recovery rebuild, a progress indicator is shown and the target is treated as a best-effort goal rather than a hard gate for this specific scenario. The 1-second target remains a hard gate for normal cold starts (where no rebuild is needed) and for full rebuilds at the Phase 2B validated volume tier.

6. Sync Errors

Sync errors are the most varied category because they span network transport, server-side processing, and local merge logic. The cardinal rule for all sync errors is: local data is never corrupted by a sync failure. The offline-first architecture guarantees that the app is fully functional without sync. Sync failures degrade the multi-device experience but never the single-device experience.

6.1 Transport Retry Strategy

Upload and download failures (HTTP errors, timeouts, network drops) follow an exponential backoff retry strategy:

  ----------------------- ------------------------------- ---------------------- --------------------------
  Attempt                 Base Delay                      With Jitter (±250ms)   Cumulative Wait (approx)

  1st retry               1 second                        750ms – 1,250ms        ~1 second

  2nd retry               2 seconds                       1,750ms – 2,250ms      ~3 seconds

  3rd retry               4 seconds                       3,750ms – 4,250ms      ~7 seconds

  Max retries exhausted   Sync deferred to next trigger   —                      —
  ----------------------- ------------------------------- ---------------------- --------------------------

Jitter (±250ms uniform random) is applied to each retry delay to prevent synchronised retry storms when multiple devices encounter the same server outage simultaneously. The jitter range is small enough to preserve the exponential backoff characteristic while distributing retries across a 500ms window.

Exception: SYNC_UPLOAD_FAILED or SYNC_DOWNLOAD_FAILED (after all retries exhausted).

Diagnostic log: Domain: sync, Level: warning. Context: HTTP status code (if available), retry count, elapsed time, payload size, error message.

Recovery: Sync defers to the next automatic trigger (connectivity restored, periodic 5-minute interval, or manual pull-to-refresh). No data is lost. Partially uploaded batches are tracked in SyncMetadata and resumed on the next attempt (TD-06 Phase 7A).

User impact: No interruption to local operation. If the user is actively watching for sync (e.g. expecting data on another device), the sync status indicator in Settings shows “Last sync failed — will retry automatically.” No modal error dialog is displayed for transport failures.

6.1.1 Sync Concurrency Control

The sync engine enforces three concurrency invariants to prevent overlapping attempts from competing for resources:

Single active sync invariant: At most one sync cycle may execute at a time. The SyncEngine maintains an in-memory mutex (not persisted). If a sync trigger fires while a cycle is in progress, the trigger is coalesced into a pending flag. When the current cycle completes, if the pending flag is set, a new cycle starts immediately. Multiple coalesced triggers produce a single subsequent cycle.

Retry cancellation on connectivity change: If the ConnectivityMonitor detects a network state change (online → offline or offline → online) during an active backoff delay, the current retry timer is cancelled. On transition to offline, the sync cycle aborts and defers. On transition to online, a new sync cycle starts immediately (skipping remaining backoff delay), because the connectivity change may have resolved the transport failure.

Trigger debouncing: Multiple sync triggers arriving within a 500ms window are coalesced into a single sync cycle. This prevents burst scenarios (e.g. closing a Session triggers both a post-Session-close sync and a post-reflow sync within milliseconds) from spawning redundant cycles. The debounce window starts on the first trigger; when it expires, a single sync cycle executes covering all pending changes.

6.2 Merge Rollback

If the merge algorithm (TD-03 §5.4) fails during execution within the Drift transaction:

Exception: SYNC_MERGE_FAILED.

Diagnostic log: Domain: sync, Level: error. Context: merge step that failed, entity type being merged, entity count processed, underlying exception. This is a high-severity log because merge failures may indicate a logic error in the merge algorithm.

Recovery: The Drift transaction rolls back completely (TD-06 §3.7). No partial merge state is committed. The device continues with its pre-merge local state. Downloaded data remains in the staging area for the next merge attempt. Sync retries on the next trigger.

Merge atomicity contract: The merge algorithm processes all entity types (Drill, Session, Instance, CalendarDay, etc.) within a single Drift transaction. There are no per-entity or per-table commits inside the merge. Either all entity types are merged successfully and the transaction commits, or any failure rolls back all changes across all entity types. This guarantee is critical: a partial merge (e.g. Sessions merged but Instances not) would create referential inconsistencies that are difficult to recover from. The single-transaction guarantee is inherited from TD-06 §17.2 and restated here because the merge rollback recovery path depends on it.

User impact: No visible change to local data. The sync status indicator shows “Sync encountered an issue — will retry.” If merge failures recur across 3 consecutive sync cycles, the indicator escalates to “Sync is experiencing repeated issues. Your data is safe locally. Please check for app updates.”

Banner state management: The escalation banner (“Sync is experiencing repeated issues”) is tied directly to the persisted consecutive failure counter in SyncMetadata. The banner is displayed when the counter ≥ 3 and removed when the counter drops below 3. Because the counter resets to 0 on any successful merge, a single successful merge after 3 or 4 failures clears the banner immediately. The banner does not require separate state tracking — the counter is the single source of truth. If the pattern is 3 failures → 1 success → 3 failures, the banner appears, clears, then reappears. This accurately reflects the system’s sync health to the user.

Escalation: If merge fails on 5 consecutive sync cycles, the sync feature flag (TD-06 §17.1) is automatically set to disabled. The app displays: “Sync has been temporarily disabled due to repeated errors. Your data is safe. Please update the app or contact support.” This prevents an infinite retry loop from consuming resources. The auto-disable behaviour is formally specified below.

Auto-disable state specification:

Counter persistence: The consecutive failure counter is persisted in SyncMetadata (not in-memory). It survives app restarts. This prevents a restart from resetting the counter and re-entering the failure loop.

Counter reset rules: The counter resets to 0 on any successful merge completion. It does not reset on app restart, connectivity change, or manual sync trigger alone — only on a successful merge.

Timeout vs failure distinction: SYNC_MERGE_FAILED (logic errors, unexpected exceptions during merge) increments the consecutive failure counter by 1. SYNC_MERGE_TIMEOUT (60-second hard timeout exceeded) does not increment the counter. A timeout at large data volumes is a performance issue, not a logic error — auto-disabling sync because the user has a large dataset would penalise legitimate use. Merge timeouts are logged at error level and trigger their own diagnostic path (context: elapsed time, entity count, Instance count) but do not contribute to the auto-disable threshold. If merge timeouts recur 3 times consecutively, a separate persistent banner is displayed: “Sync is taking longer than expected. This may resolve as data volumes stabilise.” No auto-disable occurs.

Auto-disable persistence: The disabled state is persisted in SyncMetadata. It survives app restarts. The sync feature flag remains disabled until explicitly re-enabled.

User re-enable: The user can re-enable sync manually in Settings. On re-enable, the consecutive failure counter resets to 0, and a sync cycle triggers immediately. If the underlying issue persists, the counter will climb again and auto-disable will re-engage after 5 more failures.

Pending upload queue: When sync auto-disables, the pending upload queue (tracked in SyncMetadata, including any partial upload state) is preserved, not discarded. On re-enable, the upload resumes from the persisted partial state. No local data is lost or abandoned.

Schema mismatch interaction: SYNC_SCHEMA_MISMATCH (§6.4) bypasses the consecutive failure counter entirely. Schema mismatches are not counted as merge failures because they are not transient errors — they require an app update. Schema mismatch triggers its own dedicated UI (§6.4) independent of the auto-disable mechanism.

6.3 SyncWriteGate Timeout

If the merge Drift transaction exceeds the 60-second hard timeout (TD-06 §3.7):

Exception: SYNC_MERGE_TIMEOUT.

Recovery: The merge transaction is aborted. The Drift transaction rolls back completely. The SyncWriteGate force-releases. Suspended Repository writes resume. Sync retries on the next trigger. The same rollback, deferral, and escalation rules as §6.2 apply.

Diagnostic log: Domain: sync, Level: error. Context: elapsed time, entity count being merged, Instance count in payload. A 60-second merge timeout indicates either extreme data volume or a performance regression in the merge algorithm.

6.4 Schema Version Block

When the client’s schema version does not match the server’s expected version (TD-01 §2.9):

Exception: SYNC_SCHEMA_MISMATCH.

Recovery: Sync is blocked until the app is updated. The app continues in offline-only mode. All local features remain fully functional.

User message: “An app update is required to sync your data across devices. All your data is safe locally. Please update the app.” Displayed as a persistent banner in Settings and as a one-time informational dialog on the first sync attempt after the mismatch is detected.

6.5 Payload Size Management

If a single entity’s serialised DTO exceeds the 2MB per-batch limit (extremely unlikely but theoretically possible with large RawMetrics JSON):

Exception: SYNC_PAYLOAD_TOO_LARGE.

Recovery: The oversized entity is excluded from the current upload batch. All other entities upload normally. The excluded entity is flagged in SyncMetadata for investigation. Sync continues for all other data.

Diagnostic log: Domain: sync, Level: error. Context: entity type, entity ID, serialised size. This should never occur with valid data and may indicate a data integrity issue.

6.6 Offline Deferral

When the ConnectivityMonitor detects no network availability:

Behaviour: All sync triggers are suppressed. No SYNC_NETWORK_UNAVAILABLE exception is thrown to the Repository or Provider layers — sync simply does not execute. The offline indicator (Phase 7C) is displayed.

Recovery: When connectivity is restored, a sync trigger fires automatically (TD-06 Phase 7A). The backlog of local changes uploads in batched order.

User impact: The offline indicator is the only visible change. All local features operate identically. No error dialogs, no degraded functionality, no prompts to reconnect.

7. System Errors

System errors are infrastructure-level failures that are not caused by user actions or sync operations. They are rare but potentially severe.

7.1 Database Corruption

SQLite database corruption is extremely rare but can occur due to device-level storage failures, interrupted writes during power loss, or filesystem errors.

Detection: Drift reports a DatabaseException with an SQLite CORRUPT error code (SQLITE_CORRUPT, SQLITE_NOTADB). Detection occurs either at app startup (when Drift opens the database) or during a query/write operation.

Exception: SYSTEM_DATABASE_CORRUPT.

Recovery strategy — tiered approach:

Tier 1 — Integrity check and repair: On detection, run SQLite PRAGMA integrity_check. If specific pages are corrupt but the database is partially readable, attempt to export readable data to a new database file. This preserves as much raw execution data as possible.

Tier 2 — Server rebuild: If the local database is unrecoverable and the user has synced previously, delete the local database and trigger a full re-download from the server. After download, execute a full rebuild. The user loses only unsynced local changes.

Tier 3 — Clean start: If the user has never synced (no server-side data), delete the local database and re-initialise with seed data. All user data is lost. This is the worst case and should only occur if Tier 1 and Tier 2 are both inapplicable.

User message: Tier 1: “We detected a data issue and repaired it. Your data has been preserved.” Tier 2: “We detected a data issue. Your data has been restored from your synced backup. Any changes since your last sync may not be reflected.” Tier 3: “We detected a data issue that could not be repaired. The app has been reset. We apologise for the inconvenience.”

Diagnostic log: Domain: system, Level: error. Context: SQLite error code, integrity_check output, recovery tier attempted, recovery outcome.

7.2 Storage Pressure

If the device’s storage is critically low (Section 17 §17.3.5):

Detection: Monitored via platform storage APIs. Threshold: warning at 100MB remaining device storage, critical at 50MB.

Warning level (100MB): Non-blocking banner: “Your device storage is running low. This may affect app performance.”

Critical level (50MB): Persistent banner: “Device storage is critically low. Some features may not work correctly. Please free up space.” Sync uploads continue (to preserve data on server). Sync downloads are suspended to avoid consuming remaining space.

Sync cycle behaviour under critical storage: When downloads are suspended, the sync cycle executes only the upload phase. The download phase is skipped entirely, which means the merge phase also does not execute (merge requires downloaded data to merge against). Server-side changes from other devices will not be applied locally until storage is freed and a full sync cycle completes. This is the intended behaviour: preserving local data integrity and uploading local changes to the server takes priority over receiving remote changes. The user is not explicitly told that remote changes are pending — the storage pressure banner is sufficient context.

Download resume trigger: The ConnectivityMonitor (which already monitors network state) is extended to poll available device storage at the same interval as periodic sync triggers (5 minutes). When available storage rises above the 100MB warning threshold after having been below the 50MB critical threshold, a full sync cycle (upload + download + merge) is triggered automatically. This resumes normal sync behaviour without requiring a manual user action. The resume trigger fires once and the system returns to standard periodic sync. If storage fluctuates around the threshold, the critical/warning level transitions gate re-entry: downloads are only suspended when crossing below 50MB and only resumed when crossing above 100MB, preventing oscillation.

Write failure: If a Drift write fails due to SQLITE_FULL, the exception is SYSTEM_STORAGE_FULL. The UI displays: “Could not save. Your device storage is full. Please free up space and try again.” The operation is not retried automatically.

No auto-deletion of user data is performed under any circumstances (Section 17 §17.3.5).

7.3 Memory Pressure

At extreme data volumes (approaching the 50K Sessions / 500K Instances ceiling from TD-01 §4.1), full rebuilds may approach memory limits.

Detection: The profiling benchmark harness (TD-06 Phase 2B) establishes the peak heap allocation at target data volumes. The 256MB peak heap budget is the acceptance threshold. At runtime, if Dart’s ProcessInfo reports heap usage exceeding 200MB during a reflow or rebuild, a warning is logged.

Recovery: If a reflow or rebuild triggers an OutOfMemoryError, the Drift transaction rolls back completely. The system does not attempt a chunked or split-transaction retry. A chunked approach would break the single-transaction atomicity guarantee from TD-04 §3.2 and allow partial materialised state to be visible between subskill batches, violating the invariant that materialised tables are always globally consistent. Instead, the system logs the failure (domain: scoring, level: error, context: heap usage, Instance count, subskill count) and sets a RebuildNeeded flag in SyncMetadata. On next app launch, the full rebuild re-executes within a single transaction. If the OOM recurs on restart, the user is prompted to restart the app, which clears transient memory pressure from other processes.

Design rationale: OOM during rebuild should never occur at validated data volumes (256MB budget tested at 50K Sessions / 500K Instances in Phase 2B). An OOM in production indicates either data volumes exceeding the tested envelope or a memory leak in a concurrent process. In both cases, a restart is the correct recovery — it clears transient memory pressure and the deterministic rebuild produces correct results on re-execution. Sacrificing atomicity for a marginal improvement in availability is not an acceptable trade-off.

User message: “Scores could not be updated. Please restart the app.” Scores display the last known values with a staleness indicator until the next successful rebuild.

OOM escalation path: A consecutive OOM failure counter is persisted in SyncMetadata. It increments on each OOM-triggered rebuild failure and resets to 0 on any successful rebuild. If the counter reaches 2 (two consecutive OOM failures across restarts), the system escalates: score displays are replaced with a static message (“Scores are temporarily unavailable due to device resource limits”), and the Settings screen shows an advisory: “Your practice history exceeds this device’s available memory for score calculation. Scores will resume if memory is freed by closing other apps. If this persists, please contact support.” The app remains fully functional for practice, planning, and data entry — only score display is disabled. All raw execution data is preserved and continues to sync. This escalation is extremely unlikely at validated data volumes (256MB budget tested at 50K/500K) and would only occur on severely memory-constrained devices or with data volumes beyond the tested ceiling.

Automatic rebuild suspension: After OOM escalation engages (counter ≥ 2), all automatic rebuild triggers are suspended. This includes: scoped reflow triggers from anchor edits, Session deletions, or allocation changes; the Session close scoring pipeline’s materialised write step; sync-triggered full rebuilds; and startup integrity rebuilds. Suspension prevents the system from repeatedly attempting a rebuild that will OOM, which would cause memory churn, battery drain, and a restart loop. Rebuild triggers that fire during suspension are logged (domain: scoring, level: info, context: “rebuild suspended due to OOM escalation”) but not executed. The suspension lifts only on the next manual app restart (which clears transient memory pressure from other processes) or when the user taps a “Retry score calculation” action in Settings. On either event, the OOM counter is not reset — it resets only on a successful rebuild. If the retry also OOMs, the counter increments to 3 and suspension re-engages immediately.

7.4 Migration Failure

Drift schema migrations execute on app launch (TD-06 §18.2). If a migration fails:

Exception: SYSTEM_MIGRATION_FAILED.

Recovery: The migration is rolled back to the previous schema version. The app launches on the previous schema. The user can continue using the app at the previous version. The migration is re-attempted on the next app launch.

User message: “The app update could not be fully applied. Some new features may not be available. Please restart the app. If this persists, reinstall the app (your synced data will be restored).”

Diagnostic log: Domain: system, Level: error. Context: migration version, step that failed, underlying exception. This is a critical-severity event that warrants investigation.

8. Conflict Resolution

Conflicts arise from multi-device editing. TD-01 §2.3 defines the merge precedence rules (LWW, delete-always-wins, additive merge for execution data). TD-07 defines how conflicts are surfaced to the user and what recovery is available.

The design principle for conflict resolution UI is: resolve silently when the resolution is deterministic and non-destructive; surface to the user only when data loss has occurred or when user awareness prevents confusion.

8.1 Dual Active Session (Cross-Device)

Per TD-04 §2.2.3, if two devices arrive at sync with Active Sessions for the same user:

Resolution: The Session with the later UpdatedAt wins via standard LWW. The losing Session is hard-deleted during merge. Instance data logged within the losing Session is lost (the Session was never Closed, so no scoring data entered windows).

Explicit data loss acknowledgement: This is a data loss scenario. Although the lost data has no scoring impact (Active Sessions are pre-scoring artifacts), the user may have invested significant time and effort logging Instances. The merge algorithm must count the Instances in the losing Session before deletion and include that count in both the diagnostic log and the user notification. This is an intentional product decision: Active Sessions are ephemeral execution state, and preserving deterministic single-active-Session semantics takes priority over preserving unscored Instance data. TD-04 §2.2.3 defines this explicitly.

Diagnostic log: Domain: sync, Level: warning. Context: discarded Session ID, discarded Instance count, winning Session ID, winning device UpdatedAt, losing device UpdatedAt. This is logged at warning level (not info) because data was destroyed.

User notification: On the device whose Session was discarded, after the merge completes: “A practice session with {N} logged attempts that was in progress on this device was replaced by a more recent session from another device. No scored data was affected.” (where {N} is the Instance count). This is an informational toast with a 6-second display duration (longer than the standard 4 seconds) to ensure the user registers the data loss. If Instance count is 0, the simplified message is: “An empty practice session on this device was replaced by a more recent session from another device.”

Online detection: When online, the server detects concurrent Active Sessions and prompts the user (Phase 7C): “You have an active session on another device. Starting a new session will end the other one. Continue?” On confirmation, the remote Session is hard-discarded.

8.2 Structural Entity LWW

Structural entities (Drill, UserClub, Routine, Schedule, UserDrillAdoption) resolve via standard LWW. The later UpdatedAt wins. These are silent merges with no user notification, because:

The user’s most recent edit is preserved. The losing edit is overwritten but was an older version of the same entity. No data is destroyed — the merged result reflects the latest intention. A post-merge full rebuild ensures materialised scores are consistent with the winning structural state.

Clock skew and timestamp authority: LWW correctness depends on UpdatedAt timestamps being comparable across devices. In ZX Golf App, UpdatedAt is set by the client device clock at write time, not by the server. This means LWW is vulnerable to clock skew: if Device A’s clock is ahead of Device B’s by any amount, Device A’s edits will systematically win regardless of actual edit order. The server-side SlotUpdatedAt validation (TD-03 §5.4.4) rejects timestamps more than 60 seconds in the future relative to server time, which bounds extreme skew. However, within the ±60-second tolerance window, true edit ordering can still be violated. For example: if Device A’s clock is 45 seconds ahead and Device B makes an edit 30 seconds later in real time, Device A’s earlier edit still carries a later UpdatedAt and wins LWW. This is an accepted limitation of the V1 offline-first architecture. Server-assigned timestamps for structural edits would eliminate this risk but require an online edit path, which contradicts the offline-first design. The practical risk is low: modern device clocks synchronise via NTP and rarely diverge by more than a few seconds, but the possibility of incorrect ordering within the tolerance window is a known, documented trade-off.

Delete-always-wins: Per TD-01 §2.3, if either side has IsDeleted = true, the merged result is IsDeleted = true regardless of timestamps. This means a Drill deleted on one device cannot be “un-deleted” by a stale update from another device. This is logged (domain: sync, level: info, context: entity type, entity ID, winning side) but not surfaced to the user.

8.3 CalendarDay Slot-Level Merge

CalendarDay is the sole exception to row-level LWW (TD-01 §2.4). Each Slot position merges independently using its SlotUpdatedAt timestamp.

Conflict scenario: Device A assigns Drill X to Slot 1 while Device B assigns Drill Y to Slot 1. After merge, the Slot with the later SlotUpdatedAt wins.

User impact: Silent. The user sees the winning Slot assignment after sync. No notification is displayed because the Calendar is a planning tool, not a scored artifact — the user can easily reassign the Slot.

Diagnostic log: Domain: sync, Level: info. Context: CalendarDay date, Slot position, winning vs losing DrillIDs, timestamp comparison.

8.4 Execution Data Additive Merge

Execution data (PracticeBlock, Session, Set, Instance) merges additively (TD-01 §2.3). Rows created on different devices are both preserved. This is never a conflict — it is the intended behaviour. No user notification is required. The post-merge full rebuild incorporates all merged execution data into materialised scores.

9. Authentication Errors

Authentication errors affect only sync and server communication. All local functionality is unaffected by authentication state. The user can practice, plan, and review scores indefinitely without authentication — only multi-device sync requires it.

9.1 Token Refresh

Supabase JWTs have a limited lifetime. When the token expires:

Behaviour: The Supabase client automatically attempts a token refresh using the stored refresh token (TD-01 §3.3). This is transparent to the user.

If refresh succeeds: Sync resumes with the new token. No user notification.

If refresh fails: Escalates to §9.2.

9.2 Re-Authentication

If the refresh token itself has expired (extended offline period) or is revoked:

Exception: AUTH_REFRESH_FAILED.

User message: “Please sign in again to sync your data across devices. All your local data is safe.” Displayed as a non-blocking banner with a “Sign In” action button.

Behaviour: Sync is suspended until re-authentication succeeds. All local features continue normally. On successful re-authentication, sync triggers immediately and uploads any pending local changes.

No data loss: The local database is never cleared due to an auth failure. The user’s practice history, scores, and configuration remain intact throughout the re-authentication process.

9.3 Session Revocation

If the server revokes the user’s session (e.g. account security event):

Exception: AUTH_SESSION_REVOKED.

Recovery: Same as §9.2. The user is prompted to sign in again. Local data is preserved.

10. User-Facing Error Messaging

All error messages follow the branding and communication principles from Section 15 §15.2: factual, neutral, actionable. No apologetic language, no exclamation marks, no emoji, no blame attribution.

10.1 Message Structure

Every user-facing error message has exactly two components: a statement of what happened (factual, one sentence) and an action the user can take (specific, one sentence). Messages that cannot offer an action state that the issue will resolve automatically.

Good: “Scores are updating. This may take a moment.”

Bad: “Oops! Something went wrong with your scores. We’re really sorry about that!”

10.2 Display Patterns

Error messages are displayed using one of four patterns, selected based on severity and user-action requirement:

  -------------------- ----------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Pattern              Use Case                                  Behaviour

  Inline field error   Validation failures on specific fields    Red text below the field. Appears on field change or form submission. Dismisses when the field is corrected.

  Toast / snackbar     Transient informational messages          Appears at bottom of screen. Auto-dismisses after 4 seconds. No user action required. Used for: sync status, conflict resolution notifications, auto-recovery confirmations.

  Persistent banner    Ongoing conditions requiring awareness    Appears below the app bar. Does not auto-dismiss. Includes a dismiss action or resolves when the condition clears. Used for: offline indicator, storage warning, schema mismatch, auth expiry.

  Blocking dialog      Rare conditions requiring user decision   Modal dialog. Requires user action to dismiss. Used only for: cross-device active Session conflict (confirm discard), database corruption recovery (Tier 2/3 requiring acknowledgement), sync auto-disable notification.
  -------------------- ----------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

10.3 Complete Message Catalogue

The following table lists every user-facing error message in the application. Messages are referenced by their exception code for traceability.

  ---------------------------------- ------------------- ----------------------------------------------------------------------------------------------------------------
  Code                               Pattern             Message

  VALIDATION_INVALID_ANCHORS         Inline              Min must be less than Scratch, and Scratch must be less than Pro.

  VALIDATION_INVALID_STRUCTURE       Inline              This field cannot be changed after the drill is created.

  VALIDATION_REQUIRED_FIELD          Inline              {field_name} is required.

  VALIDATION_STATE_TRANSITION        Toast               This action is no longer available. The screen will refresh.

  VALIDATION_SINGLE_ACTIVE_SESSION   Toast               You have an active session in progress.

  REFLOW_LOCK_TIMEOUT                None (auto-retry)   (Loading indicator on score displays only)

  REFLOW_TRANSACTION_FAILED          None (auto-retry)   (Scores show pre-edit values until retry succeeds)

  REFLOW_REBUILD_TIMEOUT             Banner              Scores are temporarily unavailable. They will update shortly.

  SYNC_UPLOAD_FAILED                 Toast               Sync could not complete. Will retry automatically.

  SYNC_DOWNLOAD_FAILED               Toast               Sync could not complete. Will retry automatically.

  SYNC_MERGE_FAILED (recurring)      Banner              Sync is experiencing repeated issues. Your data is safe locally.

  SYNC_MERGE_TIMEOUT                 Toast               Sync timed out. Will retry automatically.

  SYNC_SCHEMA_MISMATCH               Banner + Dialog     An app update is required to sync across devices. Your data is safe locally.

  SYSTEM_DATABASE_CORRUPT            Dialog              (Tier-specific message per §7.1)

  SYSTEM_STORAGE_FULL                Banner              Could not save. Your device storage is full. Please free up space.

  SYSTEM_MIGRATION_FAILED            Banner              The app update could not be fully applied. Please restart the app.

  CONFLICT_DUAL_ACTIVE_SESSION       Toast (6s)          A session with {N} logged attempts from this device was replaced by a more recent session from another device.

  AUTH_REFRESH_FAILED                Banner              Please sign in again to sync across devices. Your data is safe.

  AUTH_SESSION_REVOKED               Banner              Please sign in again to sync across devices. Your data is safe.

  SYSTEM_REFERENTIAL_INTEGRITY       Dialog              An unexpected data error occurred. Please restart the app.
  ---------------------------------- ------------------- ----------------------------------------------------------------------------------------------------------------

10.4 Messages That Are Never Shown

The following events are handled silently with no user-facing message. They are logged for diagnostic purposes only: SYNC_NETWORK_UNAVAILABLE (the offline indicator is shown instead, which is a status indicator, not an error message), CONFLICT_STRUCTURAL_DIVERGENCE (silent LWW resolution), CONFLICT_SLOT_COLLISION (silent per-Slot LWW), AUTH_TOKEN_EXPIRED with successful refresh, REFLOW_LOCK_TIMEOUT with successful deferred retry, individual sync transport retries (only the final failure is potentially surfaced), execution data additive merge (this is normal operation, not a conflict).

11. Logging & Diagnostics

The logging framework is established in Phase 2B (TD-06 §3.5). TD-07 defines the error-specific logging contracts that complement the operational logging defined in TD-06.

11.1 Log Levels for Error Events

  --------- -------------------------------------------------------------------------------------------------------------------- -------------------
  Level     Used For                                                                                                             Release Build

  debug     Verbose diagnostic detail (full exception stack traces, entity state dumps)                                          Suppressed

  info      Routine conflict resolution, silent merges, successful recovery                                                      Suppressed

  warning   Recoverable errors: lock timeouts, transport retries, expired locks on startup                                       Emitted

  error     Unrecoverable or escalated errors: merge failures, database corruption, migration failures, repeated sync failures   Emitted
  --------- -------------------------------------------------------------------------------------------------------------------- -------------------

11.2 Error Log Entry Structure

Every error-level log entry contains: timestamp (ISO 8601), domain tag (scoring, sync, system, auth, practice, planning, repository), log level, exception code (the ZxGolfAppException code string), human-readable message, and a context map with scenario-specific diagnostic data. The context map keys are defined per-exception in the exception catalogue (§2.3) and the individual recovery pattern sections.

11.3 EventLog (Persistent Audit Trail)

The structured logging framework (§11.1–11.2) writes to the platform console and is ephemeral. The EventLog database entity (TD-02) is the persistent audit trail. Because info-level logs are suppressed in release builds (§11.1), events that are diagnostically important for post-mortem analysis must be persisted to EventLog even when their console log would be suppressed. This ensures forensic traceability without requiring remote log aggregation (which is deferred).

The following events are recorded in EventLog:

ReflowComplete (with error context if the reflow was a crash recovery), SyncComplete (with conflict counts and resolution outcomes, including silent LWW merges and their winning/losing sides), SyncFailed (after retry exhaustion, with failure reason), DatabaseRecovery (with tier and outcome), SessionAutoDiscarded, MigrationAttempt (success or failure), DualActiveSessionResolved (with discarded Instance count), MergeAutoDisabled (with consecutive failure count), MergeReEnabled (manual re-enable by user).

EventLog entries are never deleted by the application (archival is deferred per TD-06 §19). The SyncComplete entry is particularly important: it captures silent LWW merge outcomes (structural entity overwrites, Slot-level merge resolutions) that are invisible in release console logs. Without this persistent record, diagnosing user-reported data discrepancies after multi-device sync would require reproduction rather than log analysis.

EventLog growth: At the 50K Sessions ceiling with regular sync cycles, EventLog may accumulate tens of thousands of entries (SyncComplete per cycle, ReflowComplete per reflow, plus conflict resolution entries). Each entry is a single row with a JSON Metadata column; total storage is modest relative to Instance data. However, unbounded growth is a known concern. The post-V1 archival strategy (TD-06 §19, referencing Section 16 §16.7.4) should define a retention window (e.g. 90 days) after which entries are archived to cold storage or pruned. For V1, growth is accepted as a non-critical trade-off in favour of forensic completeness.

EventLog indexing: EventLog is indexed on Timestamp (for chronological queries) and EventType (for filtered lookups). No additional indexes are added. The Metadata JSON column is not indexed; queries that need to filter by metadata content must scan. This keeps write overhead minimal during high-frequency event logging (e.g. SyncComplete on every sync cycle). If post-V1 analysis features require metadata-level queries at scale, GIN indexing on the Metadata column is listed as a deferred item (TD-02 §10).

11.4 Developer Instrumentation for Error Scenarios

The dev-mode tools from Phase 2B (TD-06 §7.1.2) include error-specific capabilities: the materialised table inspector shows the last-known state when scores are stale due to a reflow error, the reflow trigger console can simulate lock contention and transaction failures, and the sync diagnostic log viewer shows the full retry history for the most recent sync cycle. These tools are available in debug builds only and are not user-facing.

12. Graceful Degradation

ZX Golf App is designed as an offline-first application. The degradation model defines what functionality is available under each failure condition.

12.1 Degradation Matrix

  --------------------------------------------- ------------------------------------------------------------------------------ ----------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Condition                                     Available                                                                      Degraded                                                                                  Unavailable

  No network                                    All practice, planning, review, scoring, reflow                                Sync progress indicator not shown                                                         Multi-device sync, cross-device Session conflict detection

  Expired auth token (refresh failed)           All local features                                                             Sync status shows re-auth required                                                        Sync upload/download

  Scoring lock held (reflow in progress)        Practice (queue, browse), planning, review (stale scores), club/drill config   Score displays show loading indicator                                                     Start new Session, log Instances, Instance edits, Session/PB deletions, anchor edits (blocked during both scoped reflow and full rebuild; UserScoringLock is held in both cases per TD-04 §3.2 Step 1 and §3.3.2 Step 1)

  Database corruption (Tier 1 repaired)         All features                                                                   Brief startup delay for repair                                                            None

  Database corruption (Tier 2 server rebuild)   All features after rebuild                                                     Unsynced changes may be lost                                                              None

  Storage full                                  Read operations (review, browse), sync upload                                  Write operations fail individually                                                        New Sessions, Instance logging, drill creation

  Memory pressure (OOM during rebuild)          All features except score display                                              Scores show last known values (1st failure) or static unavailable message (2+ failures)   Score updates until app restart and successful rebuild; score display after 2 consecutive OOM failures

  Schema mismatch                               All local features at current schema                                           Sync blocked                                                                              New features requiring updated schema

  Sync feature flag disabled                    All local features                                                             "Sync disabled" indicator shown                                                           Multi-device sync
  --------------------------------------------- ------------------------------------------------------------------------------ ----------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

12.2 Priority of Recovery

When multiple error conditions coexist, recovery actions are prioritised: database integrity first (a corrupt database blocks everything), then scoring pipeline (stale scores are tolerable briefly but must resolve), then sync (multi-device consistency is important but not time-critical), then auth (auth can wait indefinitely without affecting local operation).

13. Partial Save Recovery

Partial save scenarios occur when the app is interrupted (crash, force-close, power loss) mid-operation. The recovery strategy depends on where in the operation the interruption occurred.

13.1 Crash During Instance Logging

Each Instance is written to Drift as an individual insert within the Session’s ongoing transaction context. Drift uses SQLite’s WAL journaling mode, which guarantees that individual writes are atomic.

Recovery: On restart, the Session is still Active (it was never Closed). All committed Instances are present. The last Instance being written at the moment of the crash may or may not be present depending on whether the SQLite write completed. The user resumes the Session with all committed Instances intact. No duplicate Instances are possible because each Instance has a unique ID generated before the write.

User experience: The user opens the app and finds their Session in progress with all (or all but the last) Instances logged. They continue from where they left off.

13.2 Crash During Session Close

Session close triggers the scoring pipeline (TD-03 §4.4): score Instances, evaluate integrity, compute Session score, insert into window, recompute subskill chain, completion matching, EventLog. This pipeline executes as a sequence of operations, not a single atomic transaction (deliberately, to avoid holding the scoring lock).

Session close idempotency: The Repository method that executes Session close must guard on Session.Status = Active before proceeding. If Session.Status is already Closed, the method throws VALIDATION_STATE_TRANSITION and does not re-execute the scoring pipeline. This guard prevents re-entrancy from rapid double-taps (user taps End Drill twice before the UI refreshes), from crash recovery (Session was closed before crash; on restart the user or system attempts to close it again), and from any other path that could invoke Session close on an already-Closed Session. Without this guard, a second execution could double-write EventLog entries, re-trigger the scoring pipeline redundantly, and cause a duplicate window insertion before the next rebuild corrects it. The UI should disable the close affordance immediately on first tap (optimistic UI), but the Repository guard is the authoritative enforcement.

If crash before Session.Status = Closed is written: On restart, the Session is still Active. The user can close it again. The scoring pipeline re-runs from the beginning. Because scoring is deterministic, re-running produces identical results.

If crash after Session.Status = Closed but before materialised tables updated: On restart, the expired scoring lock is detected (if the pipeline held the lock). A full rebuild executes, which incorporates the Closed Session into materialised scores. If the pipeline had not yet acquired the lock (Session close runs outside UserScoringLock per TD-04 §3.1.4), the RebuildNeeded flag (§13.5, check 2) detects the incomplete materialised write: the flag was set at the start of the scoring pipeline and was not cleared because the materialised write never committed. The startup check triggers a full rebuild.

13.3 Crash During PracticeBlock Operations

PracticeBlock state is derived from timestamps and child Sessions (TD-04 §2.3). If the app crashes while a PracticeBlock is Active:

Recovery: On restart, the PracticeBlock is still Active (EndTimestamp is null). The 4-hour auto-end timer restarts from the current time. The user can continue adding Sessions to the PracticeBlock or end it manually.

If the PracticeBlock has no Sessions (user crashed before starting any drill), no special recovery is needed. The empty PracticeBlock is cleaned up by the standard empty-block cleanup logic (Section 13) on the next PracticeBlock creation.

13.4 Crash During Sync Merge

The merge algorithm executes within a single Drift transaction (TD-06 §17.2). If the app crashes mid-merge:

Recovery: SQLite’s WAL journal recovery rolls back the incomplete transaction on next database open. The local database returns to its pre-merge state. The SyncWriteGate (in-memory singleton) resets on restart. Downloaded data remains available on the server for re-download on the next sync cycle.

User impact: The user sees their pre-merge local data. Sync triggers automatically after restart and the merge re-executes from scratch.

13.5 RebuildNeeded Flag UI Contract

Invariant: No UI surface that displays materialised scoring data (SkillScore dashboard, Skill Area detail, subskill detail, window detail, Post-Session Summary scores) may render without first checking SyncMetadata.RebuildNeeded. If RebuildNeeded = true, the score display must show a staleness indicator (dimmed opacity on score values, not a warning colour) and may optionally show a brief loading state.

This invariant closes the transient inconsistency window that exists between Session.Status = Closed being written and the materialised tables being updated. During normal operation this window is sub-second and invisible to the user. However, if the app is used during that window (e.g. the user navigates to the Review tab immediately after closing a Session), without this invariant the user would briefly see a Closed Session with scores that do not yet reflect it and no indication of staleness.

The RebuildNeeded flag is checked via a lightweight SyncMetadata read (single-row table, indexed). This adds negligible latency to score display rendering. Riverpod providers that serve materialised data must include the RebuildNeeded state in their AsyncValue, so that the UI receives both the score data and the staleness flag in a single emission.

Scope: RebuildNeeded is stored in SyncMetadata, which is a per-UserID table (TD-02). The flag is therefore inherently scoped to the authenticated user. This is noted explicitly to prevent ambiguity if multi-account support is introduced in a future version. Each user’s RebuildNeeded state is independent.

13.6 Startup Integrity Checks

On every app launch, the following integrity checks execute before the UI is populated:

1. Scoring lock check: If UserScoringLock.IsLocked = true and LockExpiresAt < now, force-acquire and trigger full rebuild.

2. RebuildNeeded flag check: SyncMetadata carries a boolean RebuildNeeded flag. This flag is set to true at the start of any operation that modifies materialised state (Session close scoring pipeline, scoped reflow, full rebuild) and cleared to false only after the materialised write transaction commits successfully. If the app crashes between flag-set and flag-clear, the flag remains true on restart. When detected, a full rebuild is triggered. This replaces a count-based comparison of Closed Sessions against window entries, which is unreliable because window occupancy is not 1:1 with Session count (dual-mapped Sessions contribute 0.5 occupancy per subskill, roll-off modifies occupancy, and the occupancy cap means not all Closed Sessions appear in windows).

3. SyncMetadata check: If SyncMetadata indicates a partial upload was in progress (PartialUploadState is non-null), flag the next sync cycle to resume from the partial state.

4. Referential integrity check: If SYSTEM_REFERENTIAL_INTEGRITY was the last recorded error in EventLog (indicating the previous session ended with an FK violation), execute SQLite PRAGMA foreign_key_check on startup. This lightweight query identifies any rows that violate FK constraints across all tables. If violations are found, the system logs each violation (domain: system, level: error, context: table, row ID, parent table) and attempts Tier 1 repair (§7.1): export valid data to a new database file, excluding orphaned rows. This prevents a restart loop where persistent FK corruption triggers the blocking dialog on every launch without resolution.

These checks are lightweight (flag reads and metadata queries) and add negligible time to the startup sequence. The full rebuild is triggered only when an inconsistency is detected, which occurs only after a crash or force-kill.

14. Data Integrity Verification

Beyond crash recovery, the application performs ongoing integrity verification to detect data corruption, logical inconsistencies, and constraint violations.

14.1 Referential Integrity

Drift enforces foreign key constraints at the database level. If a write violates a FK constraint (e.g. creating a Session with a non-existent DrillID), Drift throws a DatabaseException. The Repository wraps this as SYSTEM_REFERENTIAL_INTEGRITY (not VALIDATION_REQUIRED_FIELD, which is semantically reserved for user-input validation). A FK violation in production is either corrupt state or a programming error, not a missing user input — it requires a distinct error code for accurate diagnostic classification.

Exception: SYSTEM_REFERENTIAL_INTEGRITY. Context: entity type, entity ID, violated FK column, referenced table.

Diagnostic log: Domain: system, Level: error. This should never occur in normal operation because the UI only presents valid references. A FK violation in production indicates either a code defect in the Repository layer or data corruption from an external source (e.g. a malformed sync payload that bypassed DTO validation).

User message: Generic blocking dialog: “An unexpected data error occurred. Please restart the app.” The operation is visibly failed — the user’s action is not silently dropped. No technical details are exposed to the user. The dialog is blocking because the FK violation may indicate broader data integrity issues, and a restart triggers the startup integrity checks (§13.6) which can detect and repair related problems.

14.2 Scoring Determinism Verification

The deterministic rebuild architecture (TD-04 §3.4) inherently provides integrity verification: any reflow or rebuild produces the same output from the same input. The profiling benchmark harness (TD-06 Phase 2B) runs paired rebuilds and asserts bitwise equality. In production, the startup integrity check (§13.6) detects scoring inconsistencies and triggers a rebuild to correct them.

14.3 Allocation Invariant

The sum of all SubskillRef allocations must equal exactly 1000 (Section 2 §2.3). This is enforced by seed data and is immutable in V1 (no user-facing allocation editing). On app startup, the system verifies: SUM(Allocation) from SubskillRef = 1000. If this check fails, it indicates corrupt seed data. The recovery is to re-load seed data from the bundled SQL (002_seed_reference_data.sql). This check is a compile-time-equivalent safety net and should never fail in production.

14.4 Sync Payload Validation

Downloaded payloads are validated before merge (TD-03 §5.3). Validation includes: DTO schema conformance (all required fields present, correct types), entity reference integrity (child entities reference existing parents within the payload or in the local database), timestamp plausibility (no entity has an UpdatedAt more than 60 seconds in the future relative to the server clock, per TD-03 §5.4.4). Payloads that fail validation are rejected entirely. The sync cycle logs the rejection and retries on the next trigger. No partial payload is merged.

15. Error Handling by Build Phase

This section maps error handling deliverables to the TD-06 build phases. Each phase introduces specific error patterns that must be implemented and tested.

  ------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Phase                     Error Handling Deliverables

  1 — Data Foundation       ZxGolfAppException base class and all subclasses. Top-level FlutterError.onError and Zone error handlers. ErrorDisplay widget (all four display patterns). Startup allocation invariant check.

  2A — Pure Scoring         Anchor validation (VALIDATION_INVALID_ANCHORS). Division-by-zero prevention in interpolation. Score cap enforcement (never > 5.0). No error handling for orchestration (pure functions).

  2.5 — Server Foundation   SYNC_SCHEMA_MISMATCH detection and UI. AUTH_TOKEN_EXPIRED and AUTH_REFRESH_FAILED handling. Basic transport error detection (HTTP status codes). DTO validation on download.

  2B — Reflow & Lock        REFLOW_LOCK_TIMEOUT with deferred retry. REFLOW_TRANSACTION_FAILED with rollback and retry. Crash mid-reflow detection and full rebuild. Startup scoring lock check. RebuildNeeded flag mechanism with UI staleness contract. OOM consecutive failure counter. Error-specific developer instrumentation.

  3 — Drill & Bag           VALIDATION_INVALID_STRUCTURE for immutability enforcement. VALIDATION_STATE_TRANSITION for Drill/UserDrillAdoption/UserClub state machines. Anchor edit reflow error propagation.

  4 — Live Practice         VALIDATION_SINGLE_ACTIVE_SESSION. Session close pipeline error handling with explicit idempotency guard (Status = Active check). Timer error handling (TimerService failures). Instance logging crash recovery. PracticeBlock crash recovery.

  5 — Planning              Completion matching error handling (no match found is not an error). Cascade deletion error propagation. CalendarDay Slot validation.

  6 — Review                Graceful rendering with empty/stale materialised data. Zero-state handling. Cold-start performance validation.

  7A — Sync Transport       SYNC_UPLOAD_FAILED / SYNC_DOWNLOAD_FAILED with retry strategy. SYNC_PAYLOAD_TOO_LARGE handling. SYNC_NETWORK_UNAVAILABLE deferral. Partial upload state tracking and resumption. Sync concurrency control (single active sync invariant, retry cancellation on connectivity change, trigger debouncing). Sync diagnostic logging.

  7B — Merge & Rebuild      SYNC_MERGE_FAILED with rollback. SYNC_MERGE_TIMEOUT with gate release. CONFLICT_DUAL_ACTIVE_SESSION resolution with Instance count logging. Merge transaction atomicity enforcement. Post-merge rebuild error propagation. Consecutive failure counter persistence. Auto-disable state machine (5-failure threshold, persisted state, re-enable rules, schema mismatch bypass).

  7C — Conflict UI          All user-facing sync error messages. Offline indicator. Schema mismatch banner. Auth re-authentication banner. Cross-device Session conflict dialog. Storage monitoring with download resume trigger (100MB threshold hysteresis). Sync-disabled indicator. Merge failure banner tied to consecutive failure counter.

  8 — Polish                Error message audit (all messages factual and actionable). SYSTEM_DATABASE_CORRUPT tiered recovery. SYSTEM_MIGRATION_FAILED rollback. SYSTEM_STORAGE_FULL handling with sync asymmetry. SYSTEM_OUT_OF_MEMORY fail-hard with restart recovery and 2-failure escalation. SYSTEM_REFERENTIAL_INTEGRITY generic dialog. RebuildNeeded UI staleness verification. Full end-to-end error scenario testing.
  ------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

16. Deferred Items

The following error handling capabilities are explicitly deferred from V1:

Remote error reporting: V1 logs errors to the platform console only. Remote error aggregation (Sentry, Crashlytics, or equivalent) is deferred. The structured logging framework is designed to be extensible: adding a remote transport requires implementing a single LogSink interface.

User-initiated error reporting: “Report a problem” functionality that allows users to submit diagnostic data is deferred. The EventLog provides the persistent audit trail that would feed such a feature.

Automatic retry with user-configurable limits: V1 uses fixed retry counts (3 for transport, 3 for lock acquisition). User-configurable retry limits or backoff parameters are deferred.

Conflict resolution UI beyond notifications: V1 resolves all conflicts algorithmically (LWW, delete-always-wins). A UI for manual conflict resolution (e.g. “Choose which version to keep”) is deferred. The deterministic merge rules make manual resolution unnecessary for V1 data complexity.

Multi-user error scenarios: Coach/Admin access (Section 17 §17.6) is deferred. Error handling for multi-role access, shared-entity editing conflicts, and permission-based errors is out of scope.

17. Dependency Map

TD-07 is consumed by:

TD-08 (Claude Code Prompt Architecture): Error handling patterns are always-loaded context for all build phases. The exception catalogue, recovery patterns, and user-facing message catalogue are referenced in Claude Code prompts to ensure consistent error handling across the codebase.

18. Version History

  ------------ ------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Version      Date         Changes

  TD-07v.a1    2026-02-27   Initial draft. Complete error handling patterns for all exception categories, recovery strategies, user-facing messaging, logging contracts, graceful degradation matrix, and phase-mapped deliverables.

  TD-07v.a2    2026-02-27   Review fixes: (1) Removed chunked OOM rebuild — fail hard and restart to preserve atomic determinism guarantee from TD-04. (2) Dual Active Session explicitly acknowledged as data loss; Instance count logged and included in user notification. (3) Merge auto-disable formally specified: counter persistence, reset rules, re-enable behaviour, schema mismatch bypass, pending queue preservation. (4) Startup integrity check replaced fragile count-based comparison with RebuildNeeded flag mechanism. (5) FK violation remapped from VALIDATION_REQUIRED_FIELD to new SYSTEM_REFERENTIAL_INTEGRITY code. (6) Sync concurrency control added: single active sync invariant, retry cancellation on connectivity change, trigger debouncing. (7) Clock skew acknowledged in structural LWW section. (8) Cold-start performance target honestly qualified for crash-recovery rebuild at extreme volumes. (9) EventLog persistence expanded to cover info-level events suppressed in release builds.

  TD-07v.a3    2026-02-27   Second review fixes: (1) Added §13.5 RebuildNeeded Flag UI Contract — explicit invariant that score displays must show staleness indicator when RebuildNeeded = true, closing transient inconsistency window between Session close and materialised write. (2) SYSTEM_REFERENTIAL_INTEGRITY changed from silent failure to generic blocking dialog — user action is visibly failed, not silently dropped. (3) Storage pressure sync asymmetry clarified — download suspended means merge skipped, server-side changes do not apply until storage freed. (4) Clock skew wording sharpened with concrete example showing incorrect ordering within ±60s tolerance window. (5) Merge timeout separated from merge failure for auto-disable counter — timeouts do not increment counter to avoid penalising large datasets. (6) Transport retry jitter added (±250ms uniform random) to prevent synchronised retry storms. (7) EventLog growth explicitly acknowledged with cross-reference to deferred archival strategy. (8) OOM escalation path added — after 2 consecutive failures, score display disabled with advisory message. (9) Section numbering adjusted: §13.5 is now RebuildNeeded UI Contract, §13.6 is Startup Integrity Checks.

  TD-07v.a4    2026-02-27   Third review fixes: (1) Session close idempotency explicitly stated — Repository guards on Session.Status = Active before executing scoring pipeline, preventing double-write from rapid taps or crash recovery. (2) OOM escalation now suspends all automatic rebuild triggers to prevent memory thrashing and restart loops; resumes only on manual restart or explicit user retry. (3) Storage pressure download resume trigger defined — automatic full sync when available storage rises above 100MB after having been below 50MB critical threshold; hysteresis prevents oscillation. (4) Merge failure banner state explicitly tied to consecutive failure counter; banner clears automatically on successful merge. (5) RebuildNeeded flag scoped explicitly to UserID via SyncMetadata per-user table. (6) PRAGMA foreign_key_check added to startup integrity checks after FK violation to prevent restart loops from persistent corruption. (7) EventLog indexing strategy specified — Timestamp and EventType only; no Metadata JSON indexing in V1. (8) Graceful degradation matrix clarified — Session start blocked during both scoped reflow and full rebuild. (9) Merge atomicity contract restated — no per-entity commits inside merge transaction.
  ------------ ------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End of TD-07 — Error Handling Patterns (TD-07v.a4 Canonical)
