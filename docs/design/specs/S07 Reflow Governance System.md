Section 7 — Reflow Governance System

Version 7v.b9 — Consolidated

This document defines the governance, execution, locking, and failure model for scoring recalculation (“Reflow”). It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 4 (Drill Entry System 4v.g8), Section 6 (Data Model & Persistence Layer 6v.b7), Section 8 (Practice Planning Layer 8v.a8), Section 10 (Settings & Configuration 10v.a5), Section 11 (Metrics Integrity & Safeguards 11v.a5), and the Canonical Definitions (0v.f1). Reflow preserves deterministic scoring, atomic integrity, and full recalculability.

7.1 Structural Parameter Definition

A Structural Parameter is any editable parameter whose change alters:

-   Numeric scoring output

-   Window composition

-   Aggregation results (Subskill → Skill Area → Overall)

Immutable structural identity fields (Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, RequiredAttemptsPerSet) are excluded because they cannot change and therefore cannot trigger reflow.

7.2 Reflow Trigger Catalogue

The following events trigger a reflow:

User-Initiated Triggers

-   User Custom Drill anchor edits

-   Instance edit (post-close) — value or grid cell change on a closed Session’s Instance

-   Instance deletion (post-close) — removal of an Instance from an unstructured drill’s closed Session

-   Session deletion

-   PracticeBlock deletion

-   Drill deletion (with scored data)

-   Session auto-discard — triggered when the last Instance in an unstructured drill’s closed Session is deleted, converting the Session to a discard

System-Initiated Triggers

-   System Drill anchor edits (central only)

-   Skill Area allocation edits (central only)

-   Subskill allocation edits (central only)

-   65/35 weighting edits (central only)

-   Scoring formula edits (central only)

Not Reflow Triggers

-   Window size (fixed system constant, not editable)

-   IntegrityFlag and IntegritySuppressed changes (observational integrity state with no scoring impact; see Section 11)

-   Instance edits or deletions during an active (open) Session — these are pre-scoring and do not affect window state

7.3 Post-Close Editing Rules

Editing constraints after Session close depend on whether the drill is structured or unstructured.

Structured Drills (RequiredSetCount ≥1 and RequiredAttemptsPerSet ≥1)

-   Instance value may be edited (grid cell selection or metric value). Triggers reflow.

-   Individual Instance deletion is prohibited. Removing an Instance would leave a Set with fewer than RequiredAttemptsPerSet, violating structural integrity.

-   Individual Set deletion is prohibited. Removing a Set would leave a Session with fewer than RequiredSetCount, violating structural integrity.

-   The entire Session may be deleted. Triggers reflow.

Unstructured Drills (RequiredSetCount=1 and RequiredAttemptsPerSet=null)

-   Instance value may be edited. Triggers reflow.

-   Individual Instances may be deleted. Triggers reflow.

-   If the last remaining Instance is deleted, the Session is automatically discarded (scored Session converted to discard). Triggers reflow.

-   The entire Session may be deleted. Triggers reflow.

All post-close edits and deletions follow the same reflow pipeline: recalculate Session score → rebuild affected window(s) → propagate upward to Subskill → Skill Area → Overall.

7.4 Reflow Scope Model

Reflow is scoped laterally and propagates upward only.

-   A change affects only the impacted Subskill(s).

For Multi-Output drills mapped to two Subskills, anchor edits scope reflow to only the Subskill(s) whose anchor was modified. If only one Subskill’s anchor is edited, the other Subskill’s window is not rebuilt.

-   Impacted Subskill windows are fully rebuilt chronologically.

-   Propagation continues upward to Skill Area and Overall.

-   No lateral recalculation occurs.

When multiple Subskills are affected, the system executes a single combined scoped reflow transaction. There is one atomic swap and one EventLog entry.

7.5 Lock Conditions

During reflow, the system enters a full scoring lock. All reflow types use the same lock model regardless of scope.

-   No Sessions may start.

-   No Instances may be logged.

-   No Instance edits or deletions.

-   No Session or PracticeBlock deletions.

-   No anchor edits.

-   No structural edits.

-   Scoring views unavailable.

-   UI displays loading state.

-   Lifecycle timers suspended (e.g., PracticeBlock 4-hour auto-end). Timers resume when the lock is released.

The full lock is justified by the sub-1-second expected duration for user-initiated reflows. The window cap of 25 occupancy units per subskill puts a hard ceiling on data volume, making scoped locks unnecessary.

The scoring lock is user-scoped and applies across all devices. If a reflow is triggered on one device while a Session is active on another, the active Session may continue executing but cannot log Instances until the lock releases. The Session’s 2-hour inactivity timer runs independently of the lock.

The full scoring lock model does not apply to sync-triggered deterministic rebuilds (Section 17, §17.4.5). Sync rebuilds are background reconciliation processes and use a non-blocking model. The user continues to interact with the application normally during sync. User-initiated reflows retain priority; if a user-initiated structural edit coincides with a sync-triggered rebuild, the sync rebuild is deferred until the user-initiated reflow completes.

7.5.1 Client-Side Behaviour During Lock

When a scoring lock is active, the following client-side rules apply to any device attempting to log Instances or perform blocked operations:

-   Instance logging attempts are rejected immediately with a UI notice (“Scoring update in progress. Please wait.”).

-   No client-side buffering of rejected Instance data. The user must re-enter after the lock releases.

-   No partial save of in-progress data during lock.

-   No retry queue for blocked operations.

-   Input fields remain visible but submission is disabled until the lock releases.

This ensures no ambiguity about data state during reflow. The user is never left wondering whether their input was captured. If the lock releases within the expected sub-1-second window, the interruption is negligible. If an extended lock occurs (retry scenario), the UI loading state persists and the rejection notice remains visible until the lock clears.

For centrally-triggered structural changes (e.g., 65/35 weighting edits), a global scoring lock applies to all users. The UI displays a maintenance banner (“Scoring update in progress”) until all user reflows complete.

7.6 Conflict Resolution Rules

-   Only one reflow may execute at a time per user.

-   Structural edits are hard-blocked during reflow.

-   No queuing of structural edits.

-   No cancel-and-restart chaining.

-   Reflow operates as a single logical transaction.

-   The user must wait for the current reflow to complete before initiating another structural edit.

7.7 Failure & Atomicity Model

Reflow executes under an atomic swap model.

-   Derived state is computed in isolation.

-   New state becomes authoritative only upon full success.

-   User never sees partial state.

Timeout

-   Hard timeout: 60 seconds per individual user reflow.

-   If timeout exceeded: abort and revert to previous valid state.

Retry Logic

-   Automatic retry up to 3 attempts.

-   Short delay (hundreds of milliseconds) between retry attempts.

-   User remains in loading state during retries.

Complete Failure

-   If all retries fail: reflow marked as failed in EventLog.

-   System reverts to previous valid scoring state.

-   Scoring lock released. User can continue using the app.

-   User-facing notification displayed: “Your recent edit couldn’t be applied. Your scores have been restored to their previous state. Please try again or contact support.”

-   Failed reflow logged for backend investigation.

7.8 Performance Constraints

User-Initiated Reflows

-   Target completion: sub-1-second.

-   Hard timeout: 60 seconds.

-   Full scoring lock for duration.

-   No partial reads permitted.

System-Initiated Reflows

-   Individual user reflows execute in parallel with a concurrency cap (max N simultaneous reflows, tuned to infrastructure capacity).

-   Hard timeout: 60 seconds per individual user reflow.

-   Overall maintenance window is budgeted operationally per change. No system-enforced limit on total platform reflow duration.

-   Global scoring lock and maintenance banner remain active until all user reflows complete.

7.9 EventLog Integration

All reflow events are recorded in the append-only EventLog (schema defined in Section 6, §6.2). Each event carries a typed event type and a metadata payload containing relevant entity IDs and change details. The following is the canonical EventType enumeration — this is the single source of truth for all event types across the system.

Any section that introduces new event types (including Section 11, Metrics Integrity & Safeguards) extends this enumeration but does not redefine it. Section 7 (§7.9) remains the sole canonical authority for the complete EventType list.

Event Types (Canonical Enumeration)

-   AnchorEdit — User Custom Drill anchor change

-   InstanceEdit — Instance value edited post-close

-   InstanceDeletion — Instance deleted from unstructured drill post-close

-   SessionDeletion — Session deleted

-   SessionAutoDiscarded — Session auto-discarded when last Instance deleted

-   PracticeBlockDeletion — PracticeBlock deleted

-   DrillDeletion — Drill and all child data deleted

-   SystemParameterChange — Central structural parameter updated

-   ReflowFailed — Reflow failed after all retry attempts

-   ReflowReverted — Scoring state reverted to previous valid state after failure

-   IntegrityFlagRaised — Instance saved with raw metric outside schema plausibility bounds; Session IntegrityFlag set to true (introduced by Section 11)

-   IntegrityFlagCleared — User manually cleared an active integrity flag; Session IntegritySuppressed set to true (introduced by Section 11)

-   IntegrityFlagAutoResolved — All Instances in Session returned to valid bounds following edit; IntegrityFlag set to false (introduced by Section 11)

Each EventLog entry includes: event type, timestamp (UTC), affected entity IDs (Drill, Session, Instance as applicable), affected Subskill(s), user ID, and a metadata field with change details (e.g., old and new anchor values).

7.10 Structural Guarantees

The reflow governance model guarantees:

-   Deterministic outputs — same inputs always produce same results

-   Atomic integrity — no partial state visible to users

-   Full recalculability — all scores reproducible from raw Instance data

-   Strict consistency — one canonical scoring model at all times

-   Graceful failure — revert to last valid state on complete failure

-   Full audit trail — every reflow event logged with typed events and metadata

-   Explicit lock behaviour — client-side attempts during lock are rejected with UI notice; no buffering, no partial save

7.11 Derived State Model

Scoring values (Instance 0–5 scores, Session scores, window averages, Subskill points, Skill Area scores, Overall score) are not stored as persisted fields. They are derived from raw Instance data and the canonical scoring model.

However, derived state is materialised post-reflow and served authoritatively until the next reflow event. Reads access the current materialised state — they do not re-derive from raw data on every query. Recalculation occurs only on structural trigger, never on read. This reconciles the “no stored scoring aggregates” principle (Section 6) with the “no on-read recalculation” guarantee: scores are derived, not stored, but the derivation happens once per reflow, not once per read.

7.11.1 Materialised State Classification

To avoid implementation ambiguity: materialised derived state is a replaceable cache, not a source of truth. It is always rebuildable from raw Instance data and the canonical scoring model. If the materialised state is lost or corrupted, a full reflow from raw data restores it identically. Engineers must not treat materialised scoring values as canonical persisted records. The authoritative data is always the raw Instance data plus the current structural parameters.

End of Section 7 — Reflow Governance System (7v.b9 Consolidated)

