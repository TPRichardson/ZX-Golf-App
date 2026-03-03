# TD-04 Entity State Machines & Reflow — Phase 2B Extract (TD-04v.a4)
Sections: §3 Reflow Process Specification, §4 Cross-Cutting Concerns
============================================================

3. Reflow Process Specification

Reflow is not an entity state machine. It is a multi-step process with lock acquisition, ordered rebuild, failure handling, and event emission. Sections 1 and 7 of the product specification define the rules but never consolidate them into a single sequential algorithm. This section provides that consolidation.

TD-03 §4 defines the Repository method contract (executeReflow, executeFullRebuild). TD-04 defines the algorithmic steps those methods implement.

3.1 Reflow Trigger Catalogue

The following is the complete enumeration of operations that initiate reflow. Each trigger specifies its affected scope (which subskills are rebuilt).

3.1.1 User-Initiated Triggers

  ---------------------------------------------- -------------------------------------------------------------------------------------------------------------------- --------------------------------
  Trigger Operation                              Affected Scope                                                                                                       Spec Reference

  User Custom Drill anchor edit                  All subskills mapped by the edited Drill. For Multi-Output drills: only the subskill(s) whose anchor was modified.   Section 7 §7.2; Section 7 §7.4

  Instance edit (post-close)                     All subskills mapped by the Session's Drill.                                                                         Section 7 §7.2

  Instance deletion (post-close, unstructured)   All subskills mapped by the Session's Drill.                                                                         Section 7 §7.2

  Session deletion                               All subskills mapped by the Session's Drill.                                                                         Section 7 §7.2

  Session auto-discard (last Instance deleted)   All subskills mapped by the Session's Drill.                                                                         Section 7 §7.2

  PracticeBlock deletion                         All subskills mapped by all Drills in the PracticeBlock's Sessions.                                                  Section 7 §7.2

  Drill deletion (with scored data in windows)   All subskills mapped by the deleted Drill.                                                                           Section 7 §7.2

  Drill retirement (with sessions in windows)    All subskills mapped by the retired Drill.                                                                           Section 7 §7.2
  ---------------------------------------------- -------------------------------------------------------------------------------------------------------------------- --------------------------------

3.1.2 System-Initiated Triggers

  -------------------------------------- --------------------------------------------------------- -------------------
  Trigger Operation                      Affected Scope                                            Spec Reference

  System Drill anchor edit (central)     All subskills mapped by the edited System Drill.          Section 7 §7.2

  Skill Area allocation edit (central)   All subskills in the affected Skill Area.                 Section 7 §7.2

  Subskill allocation edit (central)     The affected subskill and its parent Skill Area.          Section 7 §7.2

  65/35 weighting edit (central)         All 19 subskills (global).                                Section 7 §7.2

  Scoring formula edit (central)         All 19 subskills (global).                                Section 7 §7.2

  Sync merge completion                  All 19 subskills (full rebuild via executeFullRebuild).   TD-01 §2.5 Step 5
  -------------------------------------- --------------------------------------------------------- -------------------

3.1.3 Not Reflow Triggers

The following explicitly do not trigger reflow: Window size changes (fixed constant, not editable). IntegrityFlag and IntegritySuppressed changes (observational, no scoring impact). Instance edits or deletions during an active (open) Session (pre-scoring, no window state affected). Drill metadata edits (name, description) that do not affect anchors. Club configuration changes. Routine or Schedule changes. CalendarDay Slot changes.

3.1.4 Session Close Scoring Pipeline

Session close is technically a window insertion, not a reflow trigger, but it follows the same rebuild path. When a Session closes (structured completion, manual end, or auto-close with valid state), the scoring pipeline in TD-03 §4.4 executes: score all Instances → evaluate integrity bounds → compute Session score → insert into window(s) → recompute subskill/Skill Area/Overall scores → completion matching → EventLog.

The Session close scoring pipeline does not acquire the UserScoringLock. It runs outside the lock because it does not mutate historical window state — it appends a new entry to the window and recomputes the affected subskill chain incrementally. No existing Session scores are recalculated. This distinction is architecturally important: wrapping Session close scoring inside the ScoringLock would unnecessarily block Instance logging on the next drill while the current Session's scores are computed. Code must not add ScoringLock acquisition to the Session close path.

3.2 Reflow Algorithm (Scoped)

The following numbered steps execute in order within a single Drift transaction. This algorithm implements ScoringRepository.executeReflow(ReflowTrigger trigger) as defined in TD-03 §4.2.

Step 1 — Acquire Scoring Lock

Set UserScoringLock.IsLocked = true, LockedAt = now, LockExpiresAt = now + 30 seconds. If already locked and not expired: wait and retry (max 3 attempts, 500ms interval). If locked and expired: force-acquire (previous reflow assumed failed).

Blocked during lock (operations that could trigger reflow or scoring mutation): no Sessions may start, no Instances may be logged, no Instance edits or deletions, no Session or PracticeBlock deletions, no anchor edits, no structural parameter edits. UI displays loading state. Lifecycle timers paused (see §2.3.4).

Not blocked during lock (operations with no scoring impact): club edits (add, retire, update), Routine edits (create, update, delete), Schedule edits (create, update, delete), CalendarDay Slot edits (assign, clear, manual complete), user Settings changes, Practice Pool browsing, queue reordering of PendingDrill entries. These operations are safe because they do not trigger reflow, do not mutate scoring state, and do not interact with materialised tables.

Step 2 — Determine Affected Subskills

From the ReflowTrigger, identify which SubskillIDs are affected. Single-mapped Drill edit: 1 subskill. Dual-mapped Drill edit: 2 subskills (or 1 if only one anchor was modified on a Multi-Output drill). Allocation change: all subskills in the Skill Area. Sync full rebuild: all 19 subskills. When multiple subskills are affected, a single combined scoped reflow executes. One transaction, one EventLog entry.

Step 3 — Rebuild Instance Scores

For each affected subskill, query all Closed Sessions (Status = Closed, IsDeleted = false) whose Drill maps to that subskill. For each Session, re-score all Instances from raw metrics using current anchors via the scoring adapter bound to the Drill's MetricSchema. Two-segment linear interpolation: Min→Scratch (0–3.5), Scratch→Pro (3.5–5). Capped at 5. Instance scores are computed in-memory during reflow, not persisted to Instance rows.

Step 4 — Rebuild Session Scores

For each Session identified in Step 3, compute the Session score as the simple average of all Instance 0–5 scores across all Sets. This is a flat average — Set boundaries have no weighting effect.

Step 5 — Rebuild Window Composition

For each affected subskill and each DrillType (Transition, Pressure): query Sessions ordered by CompletionTimestamp DESC, SessionID DESC. The secondary sort on SessionID guarantees deterministic window membership when two Sessions share an identical CompletionTimestamp (possible if two devices closed Sessions within the same millisecond offline). Without a secondary sort, SQLite may produce non-deterministic ordering, which would break cross-device convergence at window boundaries.

Walk forward through the ordered results, summing occupancy units (1.0 for single-mapped drills, 0.5 for dual-mapped drills). Inclusion rules: (a) If adding the entry’s full occupancy keeps cumulative occupancy ≤ 25.0, include it at full occupancy. (b) If the entry’s full occupancy would cause cumulative occupancy to exceed 25.0 but a partial reduction (0.5 decrement) would fit, include the entry at reduced occupancy (e.g. a 1.0-occupancy entry is reduced to 0.5; its score is preserved at the original value). (c) If even the reduced occupancy would exceed 25.0, exclude the entry. Example: at 24.5 cumulative occupancy, a 1.0-occupancy entry is reduced to 0.5 (total 25.0) rather than excluded entirely. At 25.0 cumulative occupancy, all subsequent entries are excluded. Score is never adjusted — only occupancy is reduced. The partial entry’s score continues to contribute to WeightedSum at its reduced occupancy weight. Write to MaterialisedWindowState: Entries (JSON array of {SessionID, DrillID, Score, Occupancy, CompletionTimestamp}), TotalOccupancy, WeightedSum (sum of score × occupancy), WindowAverage (WeightedSum / TotalOccupancy).

Step 6 — Rebuild Subskill Scores

For each affected subskill: read TransitionAverage and PressureAverage from the two MaterialisedWindowState rows. Compute WeightedAverage = (TransitionAverage × 0.35) + (PressureAverage × 0.65). Look up Allocation from SubskillRef. Compute SubskillPoints = Allocation × (WeightedAverage / 5). Handle empty windows: if a window has zero entries, its average is 0.0. Write to MaterialisedSubskillScore.

Step 7 — Rebuild Skill Area Scores

For each Skill Area containing an affected subskill: sum SubskillPoints across all subskills in that Skill Area. Write SkillAreaScore to MaterialisedSkillAreaScore.

Step 8 — Rebuild Overall Score

Sum all 7 SkillAreaScores. Write OverallScore to MaterialisedOverallScore. The Overall score maximum is 1000 (sum of all SubskillRef allocations).

Step 9 — Execute Side Effects

Reset IntegritySuppressed = false on all Sessions whose scores were recalculated (Section 11 §11.6.3). Re-evaluate IntegrityFlag for those Sessions against current Instance data. Integrity re-evaluation uses the schema-level HardMinInput/HardMaxInput bounds only; anchor edits do not influence integrity bounds. Anchors affect the 0–5 scoring mapping; plausibility bounds are immutable schema properties (Section 11 §11.3.1). A reflow triggered by an anchor edit will reset IntegritySuppressed (transient UI state) but will not change IntegrityFlag unless Instance data has independently changed. Write EventLog entry: EventType = ReflowComplete (if not already defined in the canonical list, this maps to the trigger-specific event type), AffectedSubskills = list of SubskillIDs processed, Metadata = {triggerType, durationMs, affectedSessionCount}.

Step 10 — Release Scoring Lock

Set UserScoringLock.IsLocked = false. Clear LockedAt and LockExpiresAt. UI loading state dismissed. Lifecycle timers resume with preserved remaining duration (§2.3.4). Deferred sync rebuilds may now execute.

3.3 Full Rebuild Algorithm (Post-Sync)

The full rebuild triggered after sync merge (TD-01 §2.5 Step 5) follows the same computation steps as the scoped reflow but with important differences in locking and scope.

3.3.1 Differences from Scoped Reflow

  ----------------------------- ------------------------------------------ ---------------------------------------------------------------------------------------------------------------------
  Aspect                        Scoped Reflow                              Full Rebuild (Post-Sync)

  Lock mechanism                UserScoringLock (blocks user operations)   RebuildGuard (in-memory flag, non-blocking for user reads)

  Scope                         Affected subskills only                    All 19 subskills

  Materialised table handling   Overwrites affected rows                   Truncates and repopulates all materialised tables atomically

  User interaction              Blocked during execution                   User continues normally. Write operations gated via SyncWriteGate.

  Conflict with scoped reflow   N/A                                        If RebuildGuard held, scoped reflow defers to a queue coalesced by subskill scope and executes after guard release.

  Timeout                       30 seconds (lock expiry)                   30 seconds (guard auto-release)

  Method                        executeReflow(trigger)                     executeFullRebuild()
  ----------------------------- ------------------------------------------ ---------------------------------------------------------------------------------------------------------------------

3.3.2 Full Rebuild Steps

1. Acquire RebuildGuard (in-memory singleton, not persisted). If held, wait with timeout. 2. Acquire SyncWriteGate.acquireExclusive() to gate Repository writes (max 2-second drain). 3. Within a single Drift transaction: truncate all four materialised tables, then execute Steps 3–8 of the reflow algorithm for all 19 subskills. 4. Execute Step 9 side effects (IntegritySuppressed reset on all affected Sessions). 5. Release RebuildGuard. Deferred reflows execute per coalescing rules (§3.3.3). 6. Release SyncWriteGate. Repository writes resume.

3.3.3 Deferred Reflow Coalescing

When scoped reflows are deferred during a full rebuild (because the RebuildGuard is held), multiple triggers may accumulate in the deferred queue. Before executing deferred reflows, the queue is coalesced by subskill scope: all pending triggers are merged into a single combined scope representing the union of all affected SubskillIDs. This combined scope executes as one scoped reflow (one lock acquisition, one transaction, one EventLog entry).

Example: during a full rebuild, three triggers arrive: anchor edit on subskill A, Session deletion affecting subskill A, and Skill Area allocation edit affecting subskills A, B, C. Without coalescing, three sequential reflows execute (A, A, A+B+C). With coalescing, one reflow executes with scope {A, B, C}. The result is identical because reflow is a pure rebuild from raw data — running it twice on the same subskill produces the same output. Coalescing eliminates redundant computation without altering deterministic behaviour.

The coalesced EventLog entry records all original trigger types in its Metadata field: {triggers: [{type: anchorEdit, drillId: ...}, {type: sessionDeletion, sessionId: ...}, {type: allocationChange, skillArea: ...}], coalescedFrom: 3, affectedSubskills: [A, B, C]}.

3.4 Reflow Idempotency & Failure Handling

Reflow is a pure function of raw Instance data plus current structural parameters. Re-running it from the same inputs produces identical outputs. This guarantees safe re-runnability.

3.4.1 Crash Recovery

If the app crashes mid-reflow (between Steps 1 and 10), the scoring lock expires after 30 seconds. On next app launch, the system detects an expired lock and initiates a full rebuild. Because reflow is deterministic, re-running produces identical results. No manual intervention required.

3.4.2 Failure Model

  -------------------------------------- --------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------- ----------------
  Scenario                               Behaviour                                                       Recovery                                                                                                         Spec Reference

  Reflow timeout (>60 seconds)           Abort. Revert to previous valid materialised state.             User notification. Retry available. EventLog: ReflowFailed.                                                      Section 7 §7.7

  Reflow retry exhaustion (3 attempts)   Reflow marked as failed. Revert to previous state.              Scoring lock released. User can continue. EventLog: ReflowFailed + ReflowReverted.                               Section 7 §7.7

  App crash mid-reflow                   Scoring lock expires (30s). Materialised tables may be stale.   On next launch: detect expired lock, run full rebuild from raw data.                                             TD-03 §4.3

  Full rebuild storage exhaustion        Transaction rolls back. No partial commit.                      SYSTEM_STORAGE_FULL raised. EventLog: RebuildStorageFailure. RebuildGuard released. Retry after storage freed.   TD-03 §4.5

  RebuildGuard timeout (>30 seconds)     Guard auto-releases. Deferred reflows resume.                   Reflows operate on whatever state exists. Eventual consistency via next sync or user-triggered reflow.           TD-03 §4.5
  -------------------------------------- --------------------------------------------------------------- ---------------------------------------------------------------------------------------------------------------- ----------------

3.5 Scope Determination Rules

When a reflow trigger fires, the system must determine which subskill windows require rebuilding. The scope determination follows these rules:

  ----------------------------------------------------------- ---------------------------------------------------------- -------------------------------------------------------------------------------------------------
  Trigger Type                                                Scope Logic                                                Example

  Single-mapped Drill edit                                    1 subskill: the Drill's sole SubskillMapping entry.        Irons Distance Control drill anchor edit → rebuild irons_distance_control windows.

  Dual-mapped Drill (Shared Mode) anchor edit                 2 subskills: both SubskillMapping entries.                 A Shared Mode drill mapped to irons_distance_control and irons_accuracy → rebuild both.

  Dual-mapped Drill (Multi-Output Mode) single anchor edit    1 subskill: only the subskill whose anchor was modified.   Edit only the irons_accuracy anchor on a Multi-Output drill → rebuild irons_accuracy only.

  Dual-mapped Drill (Multi-Output Mode) both anchors edited   2 subskills.                                               Both anchors edited → rebuild both subskill windows.

  Session deletion                                            All subskills mapped by the Session's Drill (1 or 2).      Delete a Session for a dual-mapped drill → rebuild both subskill windows.

  Skill Area allocation change                                All subskills in the affected Skill Area.                  Irons allocation change → rebuild all Irons subskills (distance_control, accuracy, trajectory).

  65/35 weighting change                                      All 19 subskills (global).                                 Every window in the system is rebuilt.

  Sync merge (full rebuild)                                   All 19 subskills.                                          Complete truncate-and-rebuild of all materialised tables.
  ----------------------------------------------------------- ---------------------------------------------------------- -------------------------------------------------------------------------------------------------

4. Cross-Cutting Concerns

4.1 Sync Conflict as Implicit State Event

Per TD-01 §2.3, sync merge applies LWW resolution to structural entities and additive merge to execution data. From the perspective of entity state machines, a sync merge may silently transition an entity to a different state (e.g. a Drill retired on another device arrives as Retired after merge). TD-04 state machines do not model sync as an explicit trigger — instead, the post-merge state is treated as authoritative, and the full rebuild (Step 5 of the sync pipeline) ensures all materialised state is consistent with the merged raw data.

Delete-always-wins: per TD-01 §2.3 merge precedence, if either local or remote has IsDeleted = true, the merged result is IsDeleted = true regardless of timestamps. This means a Drill deleted on one device cannot be "un-deleted" by a stale update from another device.

4.2 Offline State Transitions

All state transitions defined in this document operate identically offline. The local Drift database is the single source of truth during offline operation (TD-01 §2, TD-03 §2.2). Scoring, reflow, completion matching, and all state machine guards execute locally without network dependency. The only state transition that requires connectivity is initial account creation.

4.3 Scoring Lock vs SyncWriteGate vs RebuildGuard

Three coordination mechanisms exist. They serve different purposes and must not be confused:

  ----------------- ---------------------------------------- --------------------------------------------------------------------------------- --------------------------- --------------------------------------------------------
  Mechanism         Scope                                    Blocks                                                                            Duration                    Persistence

  UserScoringLock   User-scoped. Applies to scoped reflow.   Session start, Instance logging, edits, deletions, anchor edits, scoring views.   30 seconds (auto-expiry)    Persisted in UserScoringLock table.

  SyncWriteGate     Global. Sync merge phase.                Repository write transactions (not reads/streams).                                60 seconds (hard timeout)   In-memory singleton (Riverpod). Resets on app restart.

  RebuildGuard      Global. Full rebuild phase.              Scoped reflow (deferred to queue coalesced by subskill scope).                    30 seconds (auto-release)   In-memory flag. Resets on app restart.
  ----------------- ---------------------------------------- --------------------------------------------------------------------------------- --------------------------- --------------------------------------------------------

