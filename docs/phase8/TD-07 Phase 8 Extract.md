# TD-07 Error Handling — Phase 8 Extract (TD-07v.a4)
Sections: §7 System Errors, §13 Partial Save Recovery, §14 Data Integrity Verification
============================================================

## §7 System Errors

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


## §13 Partial Save Recovery

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


## §14 Data Integrity Verification

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
