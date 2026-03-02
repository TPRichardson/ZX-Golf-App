TD-04 — Entity State Machines & Reflow Process

Version TD-04v.a4 — Canonical

Harmonised with: Section 0 (0v.f1), Section 1 (1v.g2), Section 3 (3v.g8), Section 4 (4v.g9), Section 6 (6v.b7), Section 7 (7v.b9), Section 8 (8v.a8), Section 11 (11v.a5), Section 13 (13v.a7), Section 17 (17v.a4), TD-01 (TD-01v.a4), TD-02 (TD-02v.a6), TD-03 (TD-03v.a5).

1. Purpose

This document consolidates all entity state transitions and the reflow process into formal, implementable definitions. The product specification describes state transitions narratively across multiple sections. TD-04 extracts them into explicit state machine tables that Claude Code implements as guards, and consolidates the reflow process into a single sequential algorithm.

State machine tables define: FromState → ToState → Guard Condition → Side Effects → Spec Reference. The reflow process is defined as a numbered step-by-step algorithm.

TD-03 defines the Repository method signatures that invoke state transitions. TD-04 defines the legal transitions those methods enforce. The two documents are co-dependent: TD-03 says what operations exist; TD-04 says which state changes each operation is permitted to make.

Deliverable: This specification document. Claude Code consumes it to implement state transition guards in Repository methods and the reflow orchestration in ScoringRepository.

2. Entity State Machines

Each entity with a meaningful lifecycle is defined below. Entities with no state transitions (e.g. Instance, Set, SubskillRef) are excluded — they are created, optionally edited, and deleted but have no formal state machine.

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

2.4 Drill

Drill state is tracked via the Status enum column (Active, Retired, Deleted). System Drills and User Custom Drills share the same state machine but differ in permitted operations.

2.4.1 State Transitions

  --------- ---------------- ----------------------------------- --------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------
  From      To               Trigger                             Guard Conditions                                                                                                Side Effects                                                                                                                                                                                        Spec Reference

  (None)    Active           Drill creation (User Custom only)   Valid SubskillMapping, MetricSchemaID, Anchors (if scored). System Drills are seeded, not created at runtime.   Drill row created. UserDrillAdoption auto-created if adopted.                                                                                                                                       Section 3 §3.1.1; TD-03 §3.3.2 createCustomDrill

  Active    Retired          User retires drill                  User Custom: user-owned. System: via UserDrillAdoption retirement.                                              Status = Retired. Hidden from Practice Pool. Historical Sessions retained in windows. Roll-off continues naturally. Reflow triggered if sessions exist in windows. EventLog entry.                  Section 1 §1.17; TD-03 §3.3.2 retireDrill

  Retired   Active           Reactivation                        User Custom: user-owned. System: UserDrillAdoption re-adopted.                                                  Status = Active. Drill returns to Practice Pool. No reflow (windows unchanged).                                                                                                                     Section 1 §1.17

  Active    Deleted (soft)   User deletes drill                  User Custom only. System Drills cannot be deleted by users.                                                     IsDeleted=true. UserDrillAdoption soft-deleted. Active PracticeEntry references removed (PendingDrill entries). Completed Sessions remain until rolled off. Full reflow. EventLog: DrillDeletion.   Section 1 §1.17; Section 7 §7.2; TD-03 §3.3.2 deleteDrill

  Retired   Deleted (soft)   User deletes retired drill          User Custom only.                                                                                               Same as Active → Deleted.                                                                                                                                                                           Section 1 §1.17
  --------- ---------------- ----------------------------------- --------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- -----------------------------------------------------------

2.4.2 Drill Immutability Rules

The following fields are immutable post-creation for all drills (System and User Custom): Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, RequiredAttemptsPerSet, Club Selection Mode, Target Definition. Changing any of these requires creation of a new Drill. Anchor edits are permitted for User Custom Drills and trigger reflow. System Drill anchors are changed centrally only.

2.5 UserDrillAdoption

UserDrillAdoption links a user to a System Drill. It governs whether the System Drill appears in the user's Practice Pool. Status is an enum: Active or Retired.

2.5.1 State Transitions

  --------- ----------- ------------------------------- ----------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------
  From      To          Trigger                         Guard Conditions                                                  Side Effects                                                                                                                Spec Reference

  (None)    Active      User adopts System Drill        Drill exists. No existing adoption (or re-adoption of Retired).   UserDrillAdoption created with Status=Active. Drill appears in Practice Pool.                                               TD-03 §3.3.2 adoptDrill

  Active    Retired     User unadopts (Keep)            None.                                                             Status = Retired. Drill hidden from Practice Pool. Historical Sessions retained. No reflow.                                 Section 6 §6.2; TD-03 §3.3.2 retireAdoption

  Active    (Deleted)   User unadopts (Remove/Delete)   None.                                                             UserDrillAdoption soft-deleted. Child Sessions of the Drill soft-deleted. Full reflow triggered. EventLog: DrillDeletion.   Section 6 §6.2

  Retired   Active      User re-adopts                  None.                                                             Status = Active. Drill returns to Practice Pool. Historical Sessions reconnected. No reflow.                                Section 6 §6.2; TD-03 §3.3.2 adoptDrill
  --------- ----------- ------------------------------- ----------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------

2.6 CalendarDay Slot

CalendarDay Slots are stored as a JSON array on the CalendarDay entity. Each Slot position has an independent lifecycle. Slot state is derived from the CompletionState enum field and the presence/absence of DrillID and SessionID.

2.6.1 State Definitions

  --------------------- ----------------- ---------- ----------- ----------------------------------------------------------------------
  State                 CompletionState   DrillID    SessionID   Description

  Empty                 N/A               NULL       NULL        Slot exists (capacity allocated) but no drill assigned.

  Filled (Incomplete)   Incomplete        NOT NULL   NULL        Drill assigned. Awaiting completion.

  Completed (Linked)    CompletedLinked   NOT NULL   NOT NULL    Matched to a Closed Session via completion matching.

  Completed (Manual)    CompletedManual   NOT NULL   NULL        User manually marked complete. No linked Session. No scoring impact.
  --------------------- ----------------- ---------- ----------- ----------------------------------------------------------------------

2.6.2 State Transitions

  --------------------- --------------------- ----------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------- --------------------------------
  From                  To                    Trigger                                                           Guard Conditions                                                                                                                                                     Side Effects                                                                                                                  Spec Reference

  Empty                 Filled (Incomplete)   Manual assignment, Routine application, or Schedule application   Slot position ≤ SlotCapacity.                                                                                                                                        DrillID set. OwnerType set (Manual, RoutineInstance, or ScheduleInstance). OwnerID set.                                       Section 8 §8.1; Section 8 §8.2

  Filled (Incomplete)   Completed (Linked)    Completion matching finds matching Closed Session                 Session.DrillID matches Slot.DrillID. Session CompletionTimestamp date (user timezone) matches CalendarDay date. This is earliest unmatched Slot for this DrillID.   CompletingSessionID = matched Session's ID. CompletionState = CompletedLinked.                                                Section 8 §8.3.2

  Filled (Incomplete)   Completed (Manual)    User manually marks complete                                      None.                                                                                                                                                                CompletionState = CompletedManual. No SessionID. No scoring impact.                                                           Section 8 §8.3.4

  Filled (Incomplete)   Empty                 User clears Slot assignment                                       None.                                                                                                                                                                DrillID cleared. OwnerType/OwnerID cleared.                                                                                   Section 8

  Completed (Linked)    Filled (Incomplete)   Linked Session deleted                                            None.                                                                                                                                                                CompletingSessionID cleared. CompletionState reverts to Incomplete. DrillID and ownership preserved.                          Section 8 §8.3.4

  Completed (Manual)    Filled (Incomplete)   User reverses manual completion                                   None.                                                                                                                                                                CompletionState = Incomplete.                                                                                                 Section 8 §8.3.4

  (Overflow creation)   Completed (Linked)    Completion overflow                                               No matching Slot exists and no empty Slots remain on CalendarDay.                                                                                                    New Slot created. SlotCapacity incremented by 1. DrillID set. CompletingSessionID set. Planned = false. OwnerType = Manual.   Section 8 §8.3.3
  --------------------- --------------------- ----------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------- --------------------------------

2.6.3 Slot-Level Sync Merge

CalendarDay is the sole exception to row-level LWW sync (TD-01 §2.4). Each Slot position is merged independently using SlotUpdatedAt. SlotCapacity uses standard row-level LWW. TD-03 §5.4.3 defines the merge algorithm. The server validates that no SlotUpdatedAt exceeds server time + 60 seconds (TD-03 §5.4.4).

2.7 IntegrityFlag Lifecycle

IntegrityFlag and IntegritySuppressed are boolean fields on the Session entity. They form a composite observational state that has no scoring impact. The integrity system is strictly passive — it detects and surfaces, but never alters scoring behaviour (Section 11 §11.1).

2.7.1 State Definitions

  ------------------ --------------- --------------------- ---------------------- -------------------------------------------------------------------------------------------------------------
  Composite State    IntegrityFlag   IntegritySuppressed   UI Indicator           Description

  Clean              false           false                 None                   All Instances within plausibility bounds.

  Flagged            true            false                 Warning icon visible   ≥1 Instance outside HardMinInput/HardMaxInput bounds.

  Suppressed         true            true                  None (hidden)          User acknowledged flag. UI indicator hidden.

  Suppressed-Clean   false           true                  None                   Transient: breach resolved but suppression not yet cleared. On next evaluation, IntegritySuppressed resets.
  ------------------ --------------- --------------------- ---------------------- -------------------------------------------------------------------------------------------------------------

2.7.2 State Transitions

  ----------------------------- -------------- --------------------------------------------------------------- ---------------------------------------------------------------------- --------------------------------------------------------------------------------------------------- ---------------------------------------
  From                          To             Trigger                                                         Guard Conditions                                                       Side Effects                                                                                        Spec Reference

  Clean                         Flagged        Instance saved or edited with RawMetric outside bounds          RawMetric < HardMinInput OR RawMetric > HardMaxInput for the schema.   IntegrityFlag = true. EventLog: IntegrityFlagRaised.                                                Section 11 §11.4.3

  Flagged                       Clean          All breaching Instances edited to valid values (auto-resolve)   No remaining Instances with RawMetric outside bounds.                  IntegrityFlag = false. EventLog: IntegrityFlagAutoResolved.                                         Section 11 §11.5.2

  Flagged                       Suppressed     User manually clears flag                                       IntegrityFlag = true.                                                  IntegritySuppressed = true. UI indicator hidden. EventLog: IntegrityFlagCleared.                    Section 11 §11.6.1–2

  Suppressed                    Flagged        Any Instance in Session edited                                  Edit occurs on any Instance (regardless of breach status).             IntegritySuppressed = false. Full plausibility re-check runs. If breach exists, flag reappears.     Section 11 §11.6.2

  Suppressed                    Clean          Instance edit resolves all breaches                             No remaining breaches after re-check.                                  IntegritySuppressed = false. IntegrityFlag = false.                                                 Section 11 §11.6.2

  Any (Flagged or Suppressed)   Re-evaluated   Reflow executes touching this Session's subskill window         Reflow triggered by any structural change.                             IntegritySuppressed = false. Plausibility re-checked against current data. Flag state re-derived.   Section 11 §11.6.3; TD-03 §4.2 Step 9
  ----------------------------- -------------- --------------------------------------------------------------- ---------------------------------------------------------------------- --------------------------------------------------------------------------------------------------- ---------------------------------------

2.7.3 Key Constraints

IntegrityFlag and IntegritySuppressed changes are not reflow triggers (Section 7 §7.2). Detection applies only to Continuous Measurement and Raw Data Entry schemas. Grid Cell Selection and Binary Hit/Miss are excluded. Values exactly equal to HardMinInput or HardMaxInput are not in breach. Suppression does not survive reflow. Suppression is per-Session, not global.

2.8 Routine

Routine is a reusable blueprint with a simple Active/Retired/Deleted lifecycle. Routine state changes have no scoring impact.

2.8.1 State Transitions

  ---------------- ---------------- --------------------------------- ---------------------------------------------------------------------------- -------------------------------------------------------------------------------------------- ----------------------------------------------
  From             To               Trigger                           Guard Conditions                                                             Side Effects                                                                                 Spec Reference

  (None)           Active           User creates Routine              At least one entry (fixed DrillID or Generation Criterion).                  Routine row created. Status = Active.                                                        Section 8 §8.1.2; TD-03 §3.3.6 createRoutine

  Active           Retired          User retires Routine              None.                                                                        Status = Retired. Hidden from selection. Existing RoutineInstances unaffected.               Section 3 §3.1.2

  Retired          Active           User reactivates                  None.                                                                        Status = Active. Returns to selection.                                                       Section 3 §3.1.2

  Active/Retired   Deleted (soft)   User deletes Routine              None.                                                                        IsDeleted=true. RoutineInstance references preserved (self-sufficient). No scoring impact.   Section 3 §3.1.2; TD-03 §3.3.6 deleteRoutine

  Active           Deleted (auto)   All Drills removed from Routine   Drill deletion/retirement removes all fixed entries leaving Routine empty.   Routine auto-deleted. No scoring impact.                                                     Section 3 §3.1.2
  ---------------- ---------------- --------------------------------- ---------------------------------------------------------------------------- -------------------------------------------------------------------------------------------- ----------------------------------------------

2.9 Schedule

Schedule follows the same lifecycle pattern as Routine. Application Mode (List or DayPlanning) is set at creation and is effectively immutable for the Schedule's lifetime.

2.9.1 State Transitions

  ---------------- ---------------- ----------------------- ------------------------------------------- --------------------------------------------------------------------------------- ---------------------------------------------
  From             To               Trigger                 Guard Conditions                            Side Effects                                                                      Spec Reference

  (None)           Active           User creates Schedule   At least one entry. Application Mode set.   Schedule row created. Status = Active.                                            Section 8 §8.2; TD-03 §3.3.6 createSchedule

  Active           Retired          User retires            None.                                       Status = Retired. Hidden from selection. Existing ScheduleInstances unaffected.   Section 8

  Retired          Active           User reactivates        None.                                       Status = Active.                                                                  Section 8

  Active/Retired   Deleted (soft)   User deletes            None.                                       IsDeleted=true. ScheduleInstance references preserved. No scoring impact.         TD-03 §3.3.6
  ---------------- ---------------- ----------------------- ------------------------------------------- --------------------------------------------------------------------------------- ---------------------------------------------

2.10 UserClub

UserClub represents a club in the user's bag. Status governs Active/Retired lifecycle. Club changes have no direct scoring impact.

2.10.1 State Transitions

  --------- --------- ------------------- ------------------ --------------------------------------------------------------------------------------------------- ---------------------------------
  From      To        Trigger             Guard Conditions   Side Effects                                                                                        Spec Reference

  (None)    Active    User adds club      Valid ClubType.    UserClub created. Default UserSkillAreaClubMapping entries created per Section 9 mandatory rules.   Section 9; TD-03 §3.3.5 addClub

  Active    Retired   User retires club   None.              Status = Retired. Club remains on historical Instances. Excluded from future selection.             TD-03 §3.3.5 retireClub

  Retired   Active    User reactivates    None.              Status = Active. Returns to selection.                                                              Section 9
  --------- --------- ------------------- ------------------ --------------------------------------------------------------------------------------------------- ---------------------------------

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

5. Deferred Items

CRDT or event-sourced state machines: V1 uses simple state enums with LWW conflict resolution. Event-sourced state transitions deferred per TD-01 §2.11.

Drill version history: V1 treats Drill edits as in-place mutations with reflow. No version chain or edit history is maintained on the Drill entity beyond EventLog audit entries.

Undo support for state transitions: V1 has no undo capability for state transitions. Discards, deletions, and closes are final (soft-delete is recoverable only via database-level intervention, not user-facing undo).

Multi-user state machines: V1 is single-user. Coach/Admin access (Section 17 §17.6) is deferred. State machine guards do not consider multi-role access.

6. Dependency Map

TD-04 is consumed by:

TD-05 (Scoring Engine Test Cases): Reflow algorithm steps define the computation sequence that test cases verify. Scope determination rules define which windows are included in each test scenario.

TD-06 (Phased Build Plan): State machine tables define acceptance criteria per phase. Each phase must demonstrate that all state transitions for in-scope entities are correctly guarded.

TD-07 (Error Handling): Failure model (§3.4) defines the error scenarios that TD-07 expands into user-facing error patterns and recovery flows.

TD-08 (Claude Code Prompt Architecture): State machine tables and reflow algorithm are always-loaded context for build phases involving Repository implementation.

7. Version History

  ----------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Version     Description

  TD-04v.a1   Initial version. All entity state machines formalised. Reflow process consolidated as 10-step algorithm with full trigger catalogue, scope rules, full rebuild algorithm, idempotency guarantees, and failure model. Cross-cutting concerns: sync conflict handling, offline state transitions, coordination mechanism comparison.

  TD-04v.a2   Addressed first critique. Added: PracticeEntry ↔ Session persistent state rule (§2.1.4). Cross-device dual-Active-Session offline resolution (§2.2.3). Timer pause semantics during scoring lock (§2.3.4). Window composition boundary condition corrected (Step 5). Reflow lock blocking scope narrowed with explicit not-blocked list (Step 1). Confirmed IntegritySuppressed global reset and Routine auto-delete cascade as intentional.

  TD-04v.a3   Addressed second critique. Added: Active Session ephemeral data-loss rule — explicit statement that only Closed Sessions are durable scoring artifacts, code must never merge Instances between conflicting Active Sessions (§2.2.3). Deferred reflow coalescing — pending triggers merged by subskill scope union before execution, eliminating redundant rebuilds (§3.3.3). Session close scoring lock model — explicit statement that Session close pipeline runs outside ScoringLock because it appends incrementally, code must not add lock acquisition (§3.1.4). Window composition deterministic secondary sort — ORDER BY CompletionTimestamp DESC, SessionID DESC guarantees cross-device convergence at boundary (Step 5). Integrity re-evaluation vs anchor edit clarification — anchors affect 0–5 scoring, HardMinInput/HardMaxInput are immutable schema properties unrelated to anchors (Step 9). Terminology: removed ‘atomic swap’ from Step 2 in favour of ‘atomic transaction’. Confirmed: empty PracticeBlock hard-delete-only is intentional.
  ----------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End of TD-04 — Entity State Machines & Reflow Process (TD-04v.a4 Canonical)
