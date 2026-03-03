# TD-07 Error Handling — Phase 4 Extract (TD-07v.a4)
Sections: §4 Validation Errors, §13 Partial Save Recovery
============================================================

## §4 Validation Errors

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

