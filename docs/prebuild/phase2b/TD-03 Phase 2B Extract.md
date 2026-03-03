# TD-03 API Contract Layer — Phase 2B Extract (TD-03v.a5)
Sections: §4 Reflow Process Contract
============================================================

4. Reflow Process Contract

This section consolidates the reflow process into a precise algorithmic contract that ScoringRepository.executeReflow implements. The reflow process is defined across Sections 1 and 7 of the product specification. This section does not add new rules; it consolidates them into an implementable sequence.

4.1 Reflow Trigger Catalogue

The following operations trigger reflow. Each trigger specifies the affected scope:

  ---------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------
  Trigger Operation                        Affected Scope                                                                                                                                        Spec Reference

  Anchor edit (Drill)                      All subskills mapped by the edited Drill                                                                                                              Section 7, §7.2

  Session deletion                         All subskills mapped by the Session’s Drill                                                                                                           Section 7, §7.2

  Instance edit (on Closed Session)        All subskills mapped by the Session’s Drill                                                                                                           Section 7, §7.2

  Instance deletion (on Closed Session)    All subskills mapped by the Session’s Drill                                                                                                           Section 7, §7.2

  Drill deletion (with window entries)     All subskills mapped by the deleted Drill                                                                                                             Section 7, §7.2

  Drill retirement (with window entries)   All subskills mapped by the retired Drill                                                                                                             Section 7, §7.2

  Subskill allocation change               All subskills in the affected Skill Area                                                                                                              Section 7, §7.2

  Sync merge completion                    All subskills (full rebuild)                                                                                                                          TD-01, §2.5 Step 5

  Session close (normal)                   Subskills mapped by the closed Session’s Drill. This is technically a window insertion, not a reflow trigger, but it follows the same rebuild path.   Section 1, Section 3 §3.4
  ---------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------

4.2 Reflow Algorithm

The following numbered steps execute in order within a single Drift transaction:

Step 1 — Acquire Lock. Set UserScoringLock.IsLocked = true, LockedAt = now, LockExpiresAt = now + 30 seconds. If already locked and not expired, wait and retry (max 3 attempts, 500ms interval). If locked and expired, force-acquire (previous reflow assumed failed). Instance logging is blocked while the lock is held (Section 7, §7.5).

Step 2 — Determine Affected Subskills. From the trigger, identify which SubskillIDs are affected. For a single-mapped Drill edit: 1 subskill. For a dual-mapped Drill edit: 2 subskills. For an allocation change: all subskills in the Skill Area. For sync full rebuild: all 19 subskills.

Step 3 — Rebuild Instance Scores. For each affected subskill, query all Closed Sessions (Status = ‘Closed’, IsDeleted = false) whose Drill maps to that subskill. For each Session, re-score all Instances from raw metrics using current anchors. This step is necessary because anchor edits change the 0–5 mapping. Instance scores are not persisted; they are computed in-memory during reflow.

Step 4 — Rebuild Session Scores. For each Session identified in Step 3, compute the Session score as the simple average of all Instance 0–5 scores across all Sets.

Step 5 — Rebuild Window Composition. For each affected subskill and each DrillType (Transition, Pressure): query Sessions ordered by CompletionTimestamp DESC, SessionID DESC. The secondary sort on SessionID guarantees deterministic window membership when two Sessions share an identical CompletionTimestamp (possible during offline multi-device use). Walk forward, summing occupancy units (1.0 for single-mapped, 0.5 for dual-mapped). Inclusion rules: (a) If adding the entry’s full occupancy keeps cumulative occupancy ≤ 25.0, include it at full occupancy. (b) If the entry’s full occupancy would cause cumulative occupancy to exceed 25.0 but a partial reduction (0.5 decrement) would fit, include the entry at reduced occupancy (e.g. a 1.0-occupancy entry is reduced to 0.5; its score is preserved at the original value). (c) If even the reduced occupancy would exceed 25.0, exclude the entry. This partial roll-off mechanism ensures the window fills to its maximum capacity without discarding entries prematurely. A single-mapped entry occupying 1.0 may be reduced to 0.5, not removed entirely, if only 0.5 capacity remains. Score is never adjusted — only occupancy is reduced. The partial entry’s score continues to contribute to WeightedSum at its reduced occupancy weight. Write to MaterialisedWindowState: Entries (JSON array of {SessionID, Score, Occupancy, CompletionTimestamp}), TotalOccupancy, WeightedSum (sum of score × occupancy), WindowAverage (WeightedSum / TotalOccupancy).

Step 6 — Rebuild Subskill Scores. For each affected subskill: read TransitionAverage and PressureAverage from the two window rows. Compute WeightedAverage = (TransitionAverage × 0.35) + (PressureAverage × 0.65). Look up Allocation from SubskillRef. Compute SubskillPoints = Allocation × (WeightedAverage / 5). Write to MaterialisedSubskillScore.

Step 7 — Rebuild Skill Area Scores. For each Skill Area containing an affected subskill: sum SubskillPoints across all subskills in that Skill Area. Write SkillAreaScore to MaterialisedSkillAreaScore.

Step 8 — Rebuild Overall Score. Sum all 7 SkillAreaScores. Write OverallScore to MaterialisedOverallScore.

Step 9 — Side Effects. Reset IntegritySuppressed = false on any Sessions whose scores were recalculated (Section 11). Write EventLog entry: EventType = ReflowComplete, AffectedSubskills = list of SubskillIDs processed, Metadata = {trigger type, duration_ms}.

Step 10 — Release Lock. Set UserScoringLock.IsLocked = false. Clear LockedAt and LockExpiresAt.

4.3 Reflow Idempotency

Reflow must be safely re-runnable. If the app crashes mid-reflow (between Steps 1 and 10), the lock expires after 30 seconds. On next app launch, the system detects an expired lock and initiates a full rebuild. Because reflow is a pure function of raw data, re-running it produces identical results. No manual intervention is required.

4.4 Scoring Pipeline (Session Close)

When a Session closes (structured completion, manual end, or auto-close), the following pipeline executes. This is the non-reflow scoring path, triggered once per Session close:

-   Score all Instances: raw metrics → 0–5 score via scoring adapter.

-   Evaluate integrity bounds (Section 11): flag Session if any Instance breaches HardMinInput/HardMaxInput.

-   Compute Session score: simple average of all Instance scores.

-   Insert Session into window(s): compose window per Step 5 of reflow, writing new entry.

-   Recompute subskill, Skill Area, and Overall scores per Steps 6–8.

-   Execute completion matching (Section 8 §8.3.2).

-   Write EventLog: SessionCompletion.

The Session close scoring pipeline does not acquire the UserScoringLock. It runs outside the lock because it does not mutate historical window state — it appends a new entry to the window and recomputes the affected subskill chain incrementally. No existing Session scores are recalculated. This distinction is architecturally important: wrapping Session close scoring inside the ScoringLock would unnecessarily block Instance logging on the next drill while the current Session’s scores are computed. Code must not add ScoringLock acquisition to the Session close path.

4.5 RebuildGuard (Full Rebuild Coordination)

The full rebuild triggered after sync merge (§5.5 Step 5) does not acquire the standard UserScoringLock to avoid blocking user-initiated reflow. However, concurrent execution of a full rebuild and a standard reflow against the same materialised tables creates a race condition. The RebuildGuard prevents this:

Mechanism: executeFullRebuild acquires a RebuildGuard flag (in-memory, not persisted) before truncating materialised tables. While the guard is held, executeReflow checks the guard before acquiring UserScoringLock. If the guard is held, reflow defers and re-queues itself for execution after rebuild completes. Deferred reflows are coalesced by subskill scope before execution: all pending triggers are merged into a single combined scope representing the union of all affected SubskillIDs. This combined scope executes as one scoped reflow (one lock acquisition, one transaction, one EventLog entry) immediately upon guard release. The coalesced EventLog entry records all original trigger types in its Metadata field. Coalescing eliminates redundant computation without altering deterministic behaviour, since reflow is a pure rebuild from raw data.

Atomicity: The full rebuild executes the truncate and repopulate within a single Drift transaction. If the transaction fails, no partial state is committed. The RebuildGuard is released on both success and failure.

Storage pressure: The truncate-and-repopulate approach temporarily doubles materialised table storage during the transaction (old rows marked for deletion, new rows inserted, then old rows vacuumed). For worst-case scenarios (19 subskills × 2 drill types × 25-entry windows), the maximum transient overhead is approximately 50KB. SQLite’s WAL journal handles this within normal operating bounds. If the rebuild transaction fails due to storage exhaustion, the entire transaction rolls back (no partial commit). The system raises SYSTEM_STORAGE_FULL, writes an EventLog entry (EventType = RebuildStorageFailure), and leaves materialised tables in their pre-rebuild state. The RebuildGuard is released on failure. The application’s storage monitoring (Section 16 §16.7) alerts the user independently. A subsequent sync or manual retry will re-attempt the rebuild once storage is available.

Timeout: If the RebuildGuard is held for more than 30 seconds (matching the UserScoringLock expiry), it auto-releases and logs an error. Deferred reflows resume and will operate on whatever state exists.

