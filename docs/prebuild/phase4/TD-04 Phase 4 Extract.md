# TD-04 Entity State Machines — Phase 4 Extract (TD-04v.a4)
Sections: §2.1 PracticeEntry, §2.2 Session, §2.3 PracticeBlock
============================================================

2.1 PracticeEntry

PracticeEntry is the queue management entity within Live Practice (Section 13). It has a three-state lifecycle with no skip transitions. The ActiveSession state is exclusive: only one PracticeEntry per PracticeBlock may be in ActiveSession at any time.

2.1.1 State Definitions

  ------------------ ----------------------------------------------------- -----------------------------------------------------------------------
  State              Description                                           Invariants

  PendingDrill       Queued for execution. No Session exists.              SessionID = NULL. DrillID NOT NULL.

  ActiveSession      Session in progress. Exactly one per PracticeBlock.   SessionID NOT NULL. Session.Status = Active. Max 1 per PracticeBlock.

  CompletedSession   Session closed and scored. Window entry complete.     SessionID NOT NULL. Session.Status = Closed.
  ------------------ ----------------------------------------------------- -----------------------------------------------------------------------

2.1.2 State Transitions

  ------------------ ------------------ ------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------------
  From State         To State           Trigger                                                             Guard Conditions                                                                                                                                        Side Effects                                                                                                                              Spec Reference

  PendingDrill       ActiveSession      User starts drill                                                   No other ActiveSession exists in PracticeBlock. Scoring lock not held. Drill is not deleted.                                                            Session entity created. First Set created (SetIndex=1). SessionID attached to PracticeEntry.                                              Section 3 §3.1.4; Section 13 §13.5.1; TD-03 §3.3.3 startSession

  ActiveSession      CompletedSession   Session closes (structured completion, manual end, or auto-close)   Structured: all Sets and Instances complete. Unstructured: ≥1 Instance exists (else discard). Auto-close: 2hr inactivity with valid completion state.   Session.Status = Closed. CompletionTimestamp set per authority rules. Scoring pipeline executes. Window insertion. Completion matching.   Section 3 §3.4; Section 13 §13.5.3; TD-03 §3.3.3 endSession

  ActiveSession      PendingDrill       Restart (discard + reset)                                           None beyond ActiveSession ownership.                                                                                                                    Session hard-deleted (all Sets, Instances). SessionID cleared on PracticeEntry. No scoring. No EventLog.                                  Section 13 §13.5.4; TD-03 §3.3.3 restartSession

  ActiveSession      (Removed)          Discard + remove entry                                              None beyond ActiveSession ownership.                                                                                                                    Session hard-deleted. PracticeEntry hard-deleted. No scoring. No EventLog.                                                                Section 13 §13.5.5

  CompletedSession   (Removed)          User removes entry                                                  No other ActiveSession in PracticeBlock (reflow lock would interrupt execution).                                                                        Session soft-deleted. Cascade to Sets/Instances. Reflow triggered. EventLog: SessionDeletion. PracticeEntry hard-deleted.                 Section 13 §13.6.2; TD-03 §3.3.3 removeCompletedEntry

  PendingDrill       (Removed)          User removes entry                                                  None.                                                                                                                                                   PracticeEntry hard-deleted. No scoring. No reflow. No EventLog.                                                                           Section 13 §13.6.1; TD-03 §3.3.3 removePendingEntry
  ------------------ ------------------ ------------------------------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------------

2.1.3 Prohibited States (Runtime)

The following states are prohibited during an active Live Practice session (runtime invariant, enforced at the Repository layer): PracticeEntry without DrillID. CompletedSession with SessionID = NULL. Two or more ActiveSession entries in same PracticeBlock. Session entity without corresponding PracticeEntry within Live Practice scope.

2.1.4 Session Without PracticeEntry (Persistent State)

The PracticeEntry ↔ Session invariant is a runtime constraint, not a persistent data integrity rule. After a PracticeBlock closes, PracticeEntry rows for completed Sessions are retained but the relationship is informational — the Session's validity for window composition does not depend on a PracticeEntry existing. Closed Sessions are independently valid scoring entities.

Cross-device sync edge case: if Device A hard-deletes a PracticeEntry while the associated Closed Session persists, the merge may produce a Session row with no corresponding PracticeEntry. This is not an error state. The rule is: a Closed Session that exists without a corresponding PracticeEntry is treated as historical-only. It remains valid for window composition and scoring. No PracticeEntry reconstruction is required. No recovery action is triggered. The Repository layer must not assume PracticeEntry existence when processing historical Sessions for reflow or window queries. This invariant is enforced at the Repository layer; no database-level FK enforcement exists between PracticeEntry and Session (PracticeEntry.SessionID is a nullable FK, not a mandatory bidirectional link).

2.2 Session

Session represents the runtime execution of a single Drill. Session state is tracked via the Status enum column and CompletionTimestamp presence. The single-active-Session rule is enforced globally per user.

2.2.1 State Definitions

  ---------------- ---------------- ---------------------------------------------- -----------------------------------------------------------------------------------
  State            Status Value     Description                                    Invariants

  Created/Active   Active           Session in progress. Instances being logged.   CompletionTimestamp = NULL. Exactly one Active Session per user.

  Closed           Closed           Session completed. Scored and in window(s).    CompletionTimestamp NOT NULL. Materialised in windows (Transition/Pressure only).

  Discarded        (Hard-deleted)   Session abandoned. No trace remains.           Row physically removed from database. No sync propagation.
  ---------------- ---------------- ---------------------------------------------- -----------------------------------------------------------------------------------

2.2.2 State Transitions

  -------- ---------------- -------------------------------------- -------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------
  From     To               Trigger                                Guard Conditions                                                                                   Side Effects                                                                                                                                          Spec Reference

  (None)   Active           startSession                           No Active Session exists for user. Scoring lock not held. Drill not deleted.                       Session row created with Status=Active. First Set created. PracticeEntry updated.                                                                     Section 3 §3.1.4; Section 13 §13.5.1

  Active   Closed           Structured completion                  All Sets complete (SetIndex = RequiredSetCount). Final Set has RequiredAttemptsPerSet Instances.   CompletionTimestamp = timestamp of final Instance. Scoring pipeline. Window insertion. Completion matching. EventLog: SessionCompletion (implicit).   Section 3 §3.4; Section 10

  Active   Closed           Manual end (unstructured)              ≥1 Instance in Session. RequiredAttemptsPerSet = NULL.                                             CompletionTimestamp = moment End Drill pressed. Scoring pipeline. Window insertion. Completion matching.                                              Section 3 §3.4; Section 13 §13.5.3

  Active   Closed           Auto-close (inactivity)                2 hours no new Instance. Unstructured with ≥1 Instance, OR structured with all Sets complete.      CompletionTimestamp = timestamp of last Instance. Scoring pipeline. Passive notification.                                                             Section 3 §3.4

  Active   Discarded        Auto-close (invalid state)             2 hours no new Instance. Zero Instances, OR structured with incomplete Sets.                       Session hard-deleted with all Sets/Instances. PracticeEntry reverts to PendingDrill. Passive notification.                                            Section 3 §3.4

  Active   Discarded        User discard/restart                   None.                                                                                              Session hard-deleted with all Sets/Instances. No scoring. No EventLog.                                                                                Section 13 §13.5.4–5

  Active   Discarded        Cross-device conflict                  Another device starts Session while online. User confirms on new device.                           Previous Session hard-deleted on all devices. New Session becomes authoritative.                                                                      Section 3 §3.5; Section 17 §17.4.7

  Closed   (Soft-deleted)   User deletes Session                   Scoring lock not held. No Active Session blocking reflow.                                          IsDeleted=true. Reflow triggered. Calendar Slot reverts to Incomplete. EventLog: SessionDeletion.                                                     Section 7 §7.2; Section 8 §8.3.4

  Closed   Discarded        Last Instance deleted (unstructured)   Unstructured drill. Instance count reaches zero after deletion.                                    Session auto-discarded (hard-deleted). Reflow triggered. EventLog: SessionAutoDiscarded.                                                              Section 7 §7.2; Section 7 §7.3
  -------- ---------------- -------------------------------------- -------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------------------------- --------------------------------------

2.2.3 Cross-Device Session Concurrency

The single-active-Session rule is enforced differently depending on connectivity context per TD-01 §2.7 and Section 17 §17.4.7:

Same device: single Active Session enforced at runtime. No ambiguity.

Cross-device while online: server-mediated conflict detection. If a second device attempts to start a Session while another device has an Active Session, a warning is displayed. On confirmation, the previous Session is hard-discarded and the new Session becomes authoritative.

Cross-device while offline: no runtime enforcement is possible. Both devices may independently start and complete Sessions. This is accepted by design. On sync, both Closed Sessions merge additively and enter Subskill windows chronologically by CompletionTimestamp. No data is discarded. This is not a conflict — it is a permitted edge case.

Cross-device dual-Active-Session at sync time: if both devices arrive at sync with a still-Active Session for the same user (extremely rare — requires both devices to have open, un-closed Sessions simultaneously), the Session with the later UpdatedAt wins via standard LWW. The losing Session is hard-deleted during merge reconciliation. If the losing Session had logged Instances, those Instances are lost (the Session was never Closed, so no scoring data entered windows). This is consistent with the existing discard semantics: an Active Session that is superseded leaves no scoring trace.

This data loss is intentional. Only Closed Sessions are considered durable scoring artifacts. Active Sessions are ephemeral execution state until Closed. Instance data logged within an Active Session has no scoring permanence until the Session closes and enters a window. Code must never attempt to merge Instances between two conflicting Active Sessions — this would break scoring determinism by creating a synthetic Session that neither device produced.

2.2.4 Completion Timestamp Authority

The CompletionTimestamp determines window position and is immutable once set. Rules: Structured Completion = timestamp of final Instance of final Set. Manual End = moment End Drill pressed. Auto-Close = timestamp of last logged Instance. The server never mutates the device-recorded completion timestamp.

2.2.5 Post-Close Edit Rules

  ----------------- ---------------------------------------------------- --------------------------------------------------------------------------- ----------------------------------------- ------------------------------------------
  Drill Structure   Instance Value Edit                                  Instance Deletion                                                           Set Deletion                              Session Deletion

  Structured        Permitted. Triggers reflow.                          Prohibited (violates RequiredAttemptsPerSet).                               Prohibited (violates RequiredSetCount).   Permitted. Triggers reflow.

  Unstructured      Permitted. Triggers reflow.                          Permitted. Triggers reflow. Last Instance deleted = Session auto-discard.   N/A (single Set).                         Permitted. Triggers reflow.

  Technique Block   Permitted (duration edit). No reflow (no scoring).   N/A (single Instance per Session).                                          N/A (single Set).                         Permitted. No reflow (no scoring state).
  ----------------- ---------------------------------------------------- --------------------------------------------------------------------------- ----------------------------------------- ------------------------------------------

2.3 PracticeBlock

PracticeBlock is the execution container for a real-world practice occurrence. It is not tracked by a Status enum; its state is derived from timestamps (StartTimestamp, EndTimestamp) and the presence of child Sessions.

2.3.1 State Definitions

  -------------------- ------------------------------------------------ ------------------------------------------------------------
  State                Derived From                                     Description

  Active               EndTimestamp = NULL, IsDeleted = false           Practice in progress. Sessions may be started.

  Closed (Manual)      EndTimestamp NOT NULL, ClosureType = Manual      User ended practice. At least one Session exists.

  Closed (AutoClose)   EndTimestamp NOT NULL, ClosureType = AutoClose   4-hour safeguard timer fired. At least one Session exists.

  Discarded            (Hard-deleted)                                   No Sessions existed. PracticeBlock removed without trace.
  -------------------- ------------------------------------------------ ------------------------------------------------------------

2.3.2 State Transitions

  -------- -------------------- ----------------------------------------------- ----------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------
  From     To                   Trigger                                         Guard Conditions                                            Side Effects                                                                                                                        Spec Reference

  (None)   Active               User initiates practice                         No existing Active PracticeBlock for user.                  PracticeBlock created. PracticeEntries created from source (Calendar, Routine, manual, or empty).                                   Section 3 §3.1.3; Section 13 §13.2

  Active   Closed (Manual)      User presses End Practice                       No ActiveSession exists. ≥1 Session in PracticeBlock.       All PendingDrill entries hard-deleted. EndTimestamp set. ClosureType = Manual. Post-Session Summary displayed.                      Section 3 §3.1.3; Section 13 §13.10.1; TD-03 §3.3.3 endPracticeBlock

  Active   Closed (AutoClose)   4-hour inactivity safeguard                     No new Session started within 4 hours. ≥1 Session exists.   All PendingDrill entries hard-deleted. EndTimestamp set. ClosureType = AutoClose. Passive notification.                             Section 3 §3.1.3; Section 13 §13.10.2

  Active   Discarded            End Practice or auto-close with zero Sessions   Zero CompletedSession entries.                              PracticeBlock hard-deleted. All PendingDrill entries hard-deleted. No record persisted.                                             Section 3 §3.1.3

  Active   Discarded            All PendingDrill entries removed, no Sessions   Queue empty. Zero Sessions.                                 PracticeBlock hard-deleted.                                                                                                         Section 13 §13.6.5

  Closed   (Soft-deleted)       User deletes PracticeBlock from history         None.                                                       IsDeleted=true. Child Sessions cascade soft-delete. Reflow triggered for all affected subskills. EventLog: PracticeBlockDeletion.   Section 7 §7.2
  -------- -------------------- ----------------------------------------------- ----------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------

2.3.3 Closure Precedence Rules

1. PracticeBlock cannot close while a Session is Active. If Session auto-closes, PracticeBlock timer becomes eligible again. 2. Auto-end generates passive notification only. 3. The 4-hour timer measures from last Session start (not last Instance). 4. Lifecycle timers are paused during scoring lock (Section 7 §7.5) and resume with their remaining duration on lock release.

2.3.4 Timer Suspension Semantics During Scoring Lock

When a scoring lock is acquired (reflow Step 1), the PracticeBlock 4-hour auto-end timer pauses. The remaining duration at the moment of lock acquisition is preserved. When the lock is released (reflow Step 10), the timer resumes with the preserved remaining duration. The timer does not evaluate against wall-clock time during the lock period. This means if 3 hours 59 minutes have elapsed when a reflow starts, and the reflow takes 25 seconds, the timer resumes with 1 minute remaining after lock release — it does not fire immediately on release. This ensures deterministic timer behaviour regardless of reflow duration. The same pause semantics apply to the Session 2-hour inactivity auto-close timer.

