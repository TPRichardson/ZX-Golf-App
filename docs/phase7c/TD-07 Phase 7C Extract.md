# TD-07 Error Handling — Phase 7C Extract (TD-07v.a4)
Sections: §6 Sync Errors, §9 Authentication Errors, §12 Graceful Degradation
============================================================

## §6 Sync Errors

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


## §9 Authentication Errors

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


## §12 Graceful Degradation

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

