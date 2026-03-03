# TD-03 API Contract Layer — Phase 4 Extract (TD-03v.a5)
Sections: §3.3.3 PracticeRepository, §4.4 Session Close Scoring Pipeline
============================================================

## §3.3.3 PracticeRepository

3.3.3 PracticeRepository

PracticeRepository orchestrates the full Live Practice lifecycle defined in Section 13. All composite operations execute within Drift transactions. State transition guards are defined in TD-04.

  ------------------------ ----------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Method                   Signature                                                                                             Description

  createPracticeBlock      Future<PracticeBlock> createPracticeBlock({String? sourceRoutineId, List<String>? initialDrillIds})   Creates a PracticeBlock and initial PracticeEntries. If initialDrillIds provided, creates PendingDrill entries with sequential PositionIndex. If sourceRoutineId provided, resolves Routine entries (including Generation Criteria) and creates PracticeEntries.

  watchPracticeBlock       Stream<PracticeBlockWithEntries> watchPracticeBlock(String pbId)                                      Watches PracticeBlock with all PracticeEntries, joined to Drill names and Session scores. Primary data source for the queue view.

  getActivePracticeBlock   Stream<PracticeBlock?> getActivePracticeBlock()                                                       Watches for an existing open PracticeBlock (no EndTimestamp, IsDeleted = false). Used on app launch to detect crash recovery scenario (Section 13, §13.14).

  addDrillToQueue          Future<PracticeEntry> addDrillToQueue(String pbId, String drillId, {int? position})                   Creates a PendingDrill PracticeEntry. If position specified, inserts at that index and shifts subsequent entries. Otherwise appends.

  removePendingEntry       Future<void> removePendingEntry(String entryId)                                                       Hard deletes a PendingDrill PracticeEntry. Reindexes remaining entries. No scoring impact.

  removeCompletedEntry     Future<void> removeCompletedEntry(String entryId)                                                     Composite: soft-deletes the Session (cascade to Sets/Instances), triggers reflow, writes EventLog (SessionDeletion), then hard-deletes the PracticeEntry. Blocked while another Session is Active (§13.4.2).

  reorderQueue             Future<void> reorderQueue(String pbId, List<String> orderedEntryIds)                                  Reindexes PositionIndex for all entries in the specified order. ActiveSession entry position is locked.

  duplicateEntry           Future<PracticeEntry> duplicateEntry(String entryId)                                                  Creates a new PendingDrill PracticeEntry with the same DrillID, inserted immediately after the source entry.

  startSession             Future<Session> startSession(String entryId)                                                          Composite: (1) Verify no ActiveSession exists. (2) Create Session entity inheriting Drill properties. (3) Create first Set (SetIndex = 1). (4) Attach SessionID to PracticeEntry. (5) Transition EntryType to ActiveSession. Returns the new Session.

  discardSession           Future<void> discardSession(String entryId)                                                           Composite: (1) Hard-delete all Instances in Session. (2) Hard-delete all Sets. (3) Hard-delete Session. (4) Clear SessionID on PracticeEntry. (5) Reset EntryType to PendingDrill. No scoring. No EventLog.

  restartSession           Future<void> restartSession(String entryId)                                                           Alias for discardSession. The PracticeEntry remains in queue at its current position, ready for startSession again.

  logInstance              Future<Instance> logInstance(String setId, InstanceCompanion data)                                    Creates an Instance in the specified Set. Validates RawMetrics against the Drill’s MetricSchema (see §9.3.1 for parse failure handling). Evaluates integrity bounds (Section 11). For structured drills: if Instance count reaches RequiredAttemptsPerSet, signals Set complete.

  advanceSet               Future<Set> advanceSet(String sessionId)                                                              Creates the next Set (SetIndex = previous + 1). Only valid for structured drills when current Set is complete and more Sets remain.

  endSession               Future<Session> endSession(String sessionId)                                                          Manual end for unstructured drills. Sets CompletionTimestamp = now, Status = Closed. Triggers scoring pipeline and completion matching.

  endPracticeBlock         Future<PracticeBlockSummary> endPracticeBlock(String pbId)                                            Composite: (1) Verify no ActiveSession. (2) Hard-delete all PendingDrill entries. (3) If zero Sessions exist, hard-delete PracticeBlock and return empty summary. (4) Set EndTimestamp and ClosureType = Manual. (5) Return summary data for Post-Session Summary screen.

  saveQueueAsRoutine       Future<Routine> saveQueueAsRoutine(String pbId, String routineName)                                   Creates a Routine from current PracticeEntry queue. Each entry’s DrillID becomes a fixed Routine entry. Preserves queue order.

  updateInstance           Future<Instance> updateInstance(String instanceId, InstanceCompanion data)                            Edits an existing Instance’s RawMetrics or SelectedClub. Re-evaluates integrity bounds. If Instance belongs to a Closed Session, triggers reflow for affected subskills.

  deleteInstance           Future<void> deleteInstance(String instanceId)                                                        Soft-deletes an Instance. If Instance belongs to a Closed Session, triggers reflow. Writes EventLog.
  ------------------------ ----------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


## §4.4 Session Close Scoring Pipeline

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

