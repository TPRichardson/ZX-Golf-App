Section 13 — Live Practice Workflow

Version 13v.a7 — Expanded & Consolidated

This document defines the canonical Live Practice Workflow for ZX Golf App. It is fully harmonised with Section 0 (0v.f1), Section 3 (3v.g8), Section 4 (4v.g9), Section 6 (6v.b7), Section 7 (7v.b9), Section 8 (8v.a8), Section 11 (11v.a5), Section 12 (12v.a5), and Section 14 (14v.a4). Live Practice governs execution only. It does not alter scoring architecture, structural parameters, window mechanics, allocation models, or planning data.

13.1 Architectural Positioning

Live Practice is an immersive execution state. It is not a tab and not a persistent navigation surface. When active, it temporarily suspends all cross-domain navigation. It operates strictly within the runtime hierarchy defined in Section 3.

When Live Practice is active:

- Bottom navigation is hidden.

- Cross-tab navigation is disabled.

- Only one PracticeBlock may exist per user.

- Only one authoritative active Session may exist at any time (Section 3, §3.1.4).

- All scoring operations execute deterministically under Section 1–7 rules.

- Every Session must be created through a PracticeEntry. No standalone Session creation is permitted within Live Practice.

Hierarchy during execution: App → PracticeBlock → PracticeEntry → Session → Set → Instance.

13.2 PracticeBlock Model

A PracticeBlock represents a single execution event. It persists only if at least one Session exists at closure. The PracticeBlock entity is defined in Section 6 (§6.2). Within Live Practice, the PracticeBlock’s internal queue is represented by an ordered list of PracticeEntry objects, replacing the static DrillOrder snapshot used at creation time.

13.2.1 Entry Point Queue Population

Live Practice may be launched from four entry points (Section 12, §12.2.2). Each entry point creates a new PracticeBlock and populates the initial PracticeEntry queue as follows:

Start Today’s Practice (Home)

Visible only when today’s CalendarDay has at least one filled Slot. The PracticeBlock is created with PracticeEntries pre-loaded from the CalendarDay’s filled Slots, in Slot order. Each filled Slot’s DrillID becomes a PendingDrill PracticeEntry. Empty Slots (no DrillID assigned) are excluded. The queue is fully editable after creation.

Start Clean Practice (Home)

Always visible. Creates a PracticeBlock with an empty PracticeEntry queue. The user adds drills within the Live Practice workflow.

Start from Track

When a user starts a Drill or Routine from Track, a PracticeBlock is created. If a single Drill is selected, one PendingDrill PracticeEntry is created. If a Routine is selected, PracticeEntries are created for each entry in the Routine’s ordered list. Generation Criteria within Routines are resolved at launch time per Section 8 (§8.1.2). The queue is fully editable after creation.

Save & Practice (Plan → Create)

After creating a new Drill via Plan, Save & Practice creates a PracticeBlock with a single PendingDrill PracticeEntry referencing the newly created DrillID. The queue is fully editable after creation.

All entry points produce the same immersive Live Practice state. The origin surface is not stored on the PracticeBlock and does not affect behaviour. Exit always routes to Home regardless of launch origin (Section 3, §3.6).

13.3 PracticeEntry Structure

Each PracticeBlock contains an ordered list of PracticeEntries. PracticeEntry is a Live Practice execution-layer construct. It does not participate in scoring calculations, window storage, or derived state materialisation. PracticeEntries are deleted when the PracticeBlock is deleted.

13.3.1 PracticeEntry Schema

  ---------------------------------------------------------------------------------------------------------------------------
  Field                   Type                    Notes
  ----------------------- ----------------------- ---------------------------------------------------------------------------
  PracticeEntryID         UUID (PK)               

  PracticeBlockID         UUID (FK)               Parent PracticeBlock

  PositionIndex           Integer                 Deterministic order within queue. Updated on reorder

  EntryType               Enum                    PendingDrill | ActiveSession | CompletedSession

  DrillID                 UUID (FK)               Immutable. Set at creation. References Drill entity

  SessionID               UUID (FK) nullable      Null for PendingDrill. Set on Session creation. References Session entity

  CreatedAt               Timestamp (UTC)         

  UpdatedAt               Timestamp (UTC)         
  ---------------------------------------------------------------------------------------------------------------------------

13.3.2 PracticeEntry State Transitions

PracticeEntry has a three-state lifecycle with defined transitions. No transition may be skipped. No reverse transitions are permitted except via Restart (see §13.5.4).

  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  From State         To State           Trigger                                                         Side Effects
  ------------------ ------------------ --------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------
  PendingDrill       ActiveSession      User starts drill                                               Session entity created (Section 3, §3.1.4). SessionID attached to PracticeEntry. Only one ActiveSession permitted.

  ActiveSession      CompletedSession   Session closes (manual, structured completion, or auto-close)   Session enters scoring pipeline. Window insertion. Completion matching (Section 8, §8.3.2).

  ActiveSession      PendingDrill       Restart (discard + reset)                                       Session discarded. SessionID cleared. EntryType reset. No scoring impact.

  ActiveSession      (removed)          Discard + remove                                                Session discarded. PracticeEntry deleted. No scoring impact.

  CompletedSession   (removed)          User removes entry                                              Session deleted. Cascade to Sets and Instances. Full reflow (Section 7, §7.2). EventLog: SessionDeletion.

  PendingDrill       (removed)          User removes entry                                              PracticeEntry deleted. No scoring impact. No reflow.
  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

13.3.3 Prohibited States

The following states are structurally prohibited:

- PracticeEntry without a DrillID.

- PracticeEntry with EntryType = CompletedSession and SessionID = null.

- Two or more PracticeEntries with EntryType = ActiveSession in the same PracticeBlock.

- Session entity without a corresponding PracticeEntry within Live Practice scope.

13.4 Queue Governance

The PracticeEntry queue is fully flexible. Queue edits never mutate Calendar state and never trigger scoring recalculation.

13.4.1 Permitted Queue Operations

The user may perform the following operations on the queue at any time, subject to the active Session constraint (§13.5.2):

  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Operation                   Target                                         Behaviour
  --------------------------- ---------------------------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------
  Add drill                   Any position                                   Creates new PendingDrill PracticeEntry. Drill selected from user’s Practice Pool via Track picker within Live Practice.

  Reorder                     Any PendingDrill entry                         Updates PositionIndex values. CompletedSession entries may also be reordered for display purposes.

  Remove                      PendingDrill                                   Deletes PracticeEntry. No scoring impact.

  Remove                      CompletedSession                               Deletes Session (cascade). Triggers reflow. EventLog written.

  Duplicate                   Any entry (PendingDrill or CompletedSession)   Creates new PendingDrill PracticeEntry referencing the same DrillID. No Session data copied. Inserted after the source entry.

  Create Drill from Session   CompletedSession                               Invokes Drill Duplication (Section 4, §4.7). Creates a new User Custom Drill and a new PendingDrill PracticeEntry referencing the new DrillID.
  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

13.4.2 Queue Editing During Active Session

While a Session is Active, the user’s primary interface is the focused execution screen (§13.8). Queue editing operations (add, reorder, remove PendingDrill entries, duplicate) remain available via the secondary queue drawer. However, the following restrictions apply:

- The ActiveSession entry cannot be removed or reordered.

- No other drill may be started.

- CompletedSession removal (which triggers reflow) is blocked while a Session is Active, because reflow lock would interrupt Instance logging.

13.5 Session Lifecycle Within Live Practice

13.5.1 Starting a Drill

When the user starts a PendingDrill entry, the following atomic sequence executes:

1. Verify no other ActiveSession exists. If one does, block the action.

2. Create a new Session entity (Section 3, §3.1.4; Section 6, §6.2).

3. Attach SessionID to the PracticeEntry.

4. Transition EntryType from PendingDrill to ActiveSession.

5. Transition UI to focused execution screen (§13.8).

The Session inherits all structural properties from the referenced Drill: Skill Area, Subskill mapping, Scoring Mode, Drill Type, Metric Schema, anchors, RequiredSetCount, RequiredAttemptsPerSet, Target Definition, and Club Selection Mode.

13.5.2 Active Session Constraint

While a Session is Active, no other drill may be started. The user must either complete or discard the active Session before switching. No pause state exists. No concurrent execution is permitted. This preserves the single authoritative active Session rule defined in Section 3 (§3.1.4).

13.5.3 Session Completion

A Session may close via three paths, as defined in Section 3 (§3.4):

Structured Completion — Session auto-closes when the final Instance of the final Set is logged. CompletionTimestamp = timestamp of that final Instance.

Manual End — For unstructured drills, the user presses End Drill. CompletionTimestamp = moment End Drill is pressed.

Auto-Close (inactivity) — 2 hours with no new Instance. CompletionTimestamp = timestamp of last logged Instance. If zero Instances exist, the Session is discarded. If a structured drill has incomplete Sets, the Session is discarded. Passive notification displayed on next app open (Section 3, §3.4.3).

On completion, EntryType transitions to CompletedSession. The Session enters the scoring pipeline: 0–5 scores are calculated per Instance, the Session score is derived (simple average), and the Session is inserted into the appropriate Subskill window(s). Completion matching with the Calendar executes per Section 8 (§8.3.2). The UI returns to the queue view.

13.5.4 Restart

A user may restart an ActiveSession. Restart executes the following atomic sequence:

1. Discard the current Session (hard delete; no scoring impact).

2. Clear SessionID on the PracticeEntry.

3. Reset EntryType to PendingDrill.

4. Return to queue view.

The user may then start the same PracticeEntry again, which creates a fresh Session. Restart is functionally equivalent to discard followed by immediate re-availability, but preserves the PracticeEntry’s position and DrillID in the queue.

13.5.5 Discarding a Session

Discarding an ActiveSession hard-deletes the Session, all its Sets, and all its Instances. No scoring occurs. No window entry occurs. No reflow is triggered. No EventLog entry is written. The PracticeEntry may then be removed from the queue or restarted.

13.6 Deletion & Reflow Behaviour

13.6.1 Removing PendingDrill

May be removed freely. No Session exists. No scoring impact. No reflow. No EventLog entry.

13.6.2 Removing CompletedSession

Removing a CompletedSession entry executes the following:

1. Delete the Session entity.

2. Cascade delete to all child Sets and Instances (Section 6, §6.6).

3. Trigger full reflow (Section 7, §7.2).

4. Write EventLog entry: EventType = SessionDeletion.

5. Delete the PracticeEntry.

The Drill definition is unaffected. The Drill remains in the user’s Practice Pool unless separately deleted or retired.

13.6.3 Removing ActiveSession

An ActiveSession cannot be removed directly. The user must first discard the Session (§13.5.5), which resets the PracticeEntry to PendingDrill. The PendingDrill entry may then be removed under §13.6.1 rules.

13.6.4 Reflow Lock Interaction

If a reflow is in progress (Section 7, §7.5), Instance logging is temporarily blocked. No client-side buffering of Instances occurs during reflow lock. The user is shown a brief blocking indicator until reflow completes. CompletedSession removal is blocked while a Session is Active to prevent reflow lock from interrupting execution.
13.6.5 Source Drill Deletion During Active PracticeBlock
If a Drill referenced by a PendingDrill PracticeEntry is deleted or retired while the PracticeBlock is active, the PendingDrill entry is removed from the queue immediately. No Session exists for a PendingDrill, so no scoring or reflow consequence applies. If the Drill is referenced by a CompletedSession PracticeEntry, the PracticeEntry is unaffected — the Session has already been scored and entered its window. The Drill deletion triggers reflow through the standard pipeline (Section 7, §7.2). If removal of PendingDrill entries leaves the queue empty and no CompletedSession entries exist, the PracticeBlock is auto-deleted (standard empty PracticeBlock rule).

13.7 Multiple Executions of Same Drill

The same DrillID may appear multiple times within a single PracticeBlock, either through explicit duplication or through the restart flow. Each execution:

- Produces an independent Session with a unique SessionID.

- Produces an independent window entry.

- Is treated independently for deletion and reflow.

- Is treated independently for completion matching.

There is no limit on the number of times a Drill may be executed within a single PracticeBlock.

13.8 Technique Block Handling

Technique Block drills follow the same PracticeEntry lifecycle as scored drills. They appear in the queue as PendingDrill entries, transition through ActiveSession on start, and transition to CompletedSession on close. The structural difference is in Session behaviour:

- No scoring anchors exist. No 0–5 score is calculated.

- No Subskill mapping exists. No window entry occurs.

- The Session is always unstructured (RequiredSetCount=1, RequiredAttemptsPerSet=null). The user ends the Session via the End Drill action on the drill entry screen.

- The drill entry screen displays a dedicated timer interface with a Start/Stop button. The timer runs in the background when the phone is pocketed. After stopping, the user may manually override the recorded duration.

- One Instance is created per Session. The Instance stores duration (seconds) as its raw metric value via the Metric Schema. No derived 0–5 score is calculated.

- End Drill closes the Session, persists the Instance, and produces no scoring output and no window entry.

- Technique Block Sessions are Closed Sessions and participate in Calendar completion matching (Section 8, §8.3.2). The Calendar measures practice discipline, not scoring output.

- No reflow is triggered on deletion of a Technique Block Session (no scoring state to recalculate).

In the Post-Session Summary (§13.12), Technique Block Sessions are listed for completeness but display no score, no score delta, and no Skill Area impact.

13.9 Focus-First UI Model

13.9.1 Layout Philosophy

Live Practice follows a focus-first execution philosophy aligned with the hierarchical focus model defined in Section 12 (§12.7). Focus narrows at each layer:

- App level → PracticeBlock focus (Live Practice is immersive; shell hidden).

- PracticeBlock level → Queue focus (when no Session is active, queue is the primary surface).

- Session level → Execution focus (when a Session is active, the execution screen dominates).

13.9.2 Queue View (No Active Session)

When no Session is active, the queue is the primary interface. It displays:

- All PracticeEntries in PositionIndex order.

- Visual state differentiation: PendingDrill, CompletedSession (with score if scored drill).

- Controls for queue editing (add, reorder, remove, duplicate).

- End Practice button.

- Save Practice as Routine (secondary action).

13.9.3 Execution View (Active Session)

When a Session is active, the execution screen dominates. The queue is accessible via a secondary drawer but is not the primary surface. The execution view contains:

For Grid Cell Selection drills: the target grid (3×3, 1×3, or 3×1 as defined by the Drill’s Metric Schema). The user taps the cell where the shot landed.

For Continuous Measurement drills: a numeric input field with the Metric Schema’s unit label. HardMinInput and HardMaxInput bounds are evaluated at input time (Section 11, §11.2).

For Raw Data Entry drills: a numeric input field. HardMinInput and HardMaxInput bounds are evaluated at input time (Section 11, §11.2).

The execution view also displays:

- Drill name and Skill Area.

- Current Set number and total Sets (for structured drills).

- Instance count within the current Set.

- Club selector (per Club Selection Mode defined on the Drill; Section 9).

- Target overlay (for grid drills: resolved target distance and target box dimensions).

The execution view does not display per-shot 0–5 scores or running Session averages. This restriction is defined in Section 4 and is absolute within Live Practice. The user sees input confirmations only (e.g., grid cell highlighted, value accepted).

13.10 Ending Practice

13.10.1 Manual End Practice

When the user selects End Practice:

1. If a Session is Active, the user is prompted to complete or discard it. PracticeBlock cannot close while a Session is Active (Section 3, §3.1.3).

2. All PendingDrill PracticeEntries are discarded. No trace is retained.

3. All CompletedSession PracticeEntries persist (their Sessions, Sets, and Instances are already persisted).

4. PracticeBlock is persisted only if ≥1 Session exists (Section 3, §3.1.3).

5. If no Sessions exist, the PracticeBlock is discarded entirely. No record is created.

6. Post-Session Summary screen is displayed (§13.12).

7. User returns to Home.

13.10.2 PracticeBlock Auto-End

Section 3 (§3.1.3) defines that a PracticeBlock auto-ends after 4 hours without a new Session being started. When auto-end triggers within Live Practice:

- All PendingDrill entries are discarded (same behaviour as manual End Practice).

- CompletedSessions persist.

- PracticeBlock is persisted if ≥1 Session exists.

- On next app open, the Post-Session Summary is displayed if Sessions exist. If no Sessions exist, a passive banner notifies the user that the PracticeBlock was auto-ended and discarded.

13.10.3 Session Auto-Close During Live Practice

If a Session auto-closes due to inactivity (2 hours, no new Instance), the standard Section 3 (§3.4.3) rules apply:

- If zero Instances: Session discarded. PracticeEntry reverts to PendingDrill (SessionID cleared).

- If structured drill with incomplete Sets: Session discarded. PracticeEntry reverts to PendingDrill.

- If unstructured drill with ≥1 Instance, or structured drill with all Sets complete: Session saved and scored. PracticeEntry transitions to CompletedSession.

- Passive notification displayed.

The PracticeBlock’s own 4-hour auto-end timer then resumes, measuring from the last Session start.

13.11 Calendar Independence

Once Live Practice begins, the PracticeEntry queue is independent from the Calendar. This rule applies regardless of the entry point (including Start Today’s Practice).

Specifically:

- Queue edits (add, remove, reorder) do not modify CalendarDay Slots.

- Removing a PendingDrill that was loaded from a Calendar Slot does not delete or modify that Slot.

- Adding a drill not in the Calendar does not create a new Slot.

- Calendar updates occur only via universal completion matching when Sessions close (Section 8, §8.3.2).

- No real-time Slot modification occurs during Live Practice.

- No automatic SlotCapacity expansion occurs.

This preserves the architectural separation defined in Section 8: Planning is advisory, Execution is sovereign, Completion is reactive.

13.12 Save Practice as Routine

While viewing the queue, the user may save the current queue as a Routine. This is a secondary UI action and does not affect execution or persistence.

Behaviour:

- Creates a new Routine entity (Section 6, §6.2; Section 8, §8.1.2).

- Includes all PracticeEntries (PendingDrill and CompletedSession). Each entry’s DrillID becomes a fixed entry in the Routine’s ordered list, preserving queue order.

- ActiveSession entries are included using their DrillID (the Session itself is not referenced).

- Does not persist the PracticeBlock.

- Does not affect scoring.

- The Routine is immediately available in Track and Plan for future use.

This action is available regardless of whether any Sessions have been completed. It captures the full practice structure as a reusable blueprint.

13.13 Post-Session Summary

13.13.1 Display Trigger

The Post-Session Summary screen is displayed after Live Practice ends (manual or auto-end) and before the user returns to Home. It is shown only if ≥1 Session exists in the PracticeBlock. If no Sessions exist, no summary is shown.

13.13.2 Scope

The Post-Session Summary displays only Sessions that still exist at the moment the PracticeBlock closes. Sessions deleted during practice (via CompletedSession removal) are excluded. Sessions discarded during practice are excluded. Score deltas reflect the current derived state after any reflow triggered by mid-practice deletions.

13.13.3 Content

The Post-Session Summary includes, per completed Session (Section 3, §3.5; Section 12, §12.8):

- Drill name and Skill Area.

- Final 0–5 Session score (for scored drills).

- Score delta: change to the relevant Subskill Weighted Average caused by this Session’s window entry.

- Skill Area impact: directional indicator (improved, declined, unchanged).

- IntegrityFlag status: if any Instance in the Session breached plausibility bounds (Section 11).

For Technique Block Sessions: drill name is listed, but no score, no score delta, and no Skill Area impact are displayed.

The summary is read-only. No editing, deletion, or drill management is permitted from this screen. The only action is to dismiss and return to Home.

13.14 Failure & Recovery

13.14.1 App Crash / Force Close During Active Session

If the app closes unexpectedly while a Session is Active:

- The Session remains Active on the server.

- Inactivity timers apply per Section 3 (§3.4.3): 2 hours with no new Instance triggers auto-close.

- All Instances logged before the crash are persisted (server-acknowledged writes).

On next app open, the system detects the existing PracticeBlock with an ActiveSession. Live Practice is restored: the user is returned to the execution screen for the active drill with the PracticeEntry queue intact. No data is lost. No summary is displayed prematurely.

13.14.2 App Crash / Force Close With No Active Session

If the app closes while no Session is Active (user was viewing the queue):

- The PracticeBlock remains open on the server.

- The 4-hour auto-end timer continues.

On next app open, the system detects the existing PracticeBlock. Live Practice is restored to the queue view. PendingDrill entries are preserved. CompletedSession entries are preserved.

13.14.3 PracticeBlock Auto-End While App Is Closed

If the 4-hour auto-end timer fires while the app is closed:

- PendingDrill entries are discarded.

- CompletedSessions persist.

- PracticeBlock is persisted if ≥1 Session exists; discarded otherwise.

- On next app open, the user is routed to Home. If Sessions existed, the Post-Session Summary is displayed. If not, a passive banner notifies the user that an empty practice was discarded.

13.14.4 Reflow Lock

If a reflow is in progress (Section 7, §7.5), Instance logging is temporarily blocked. No client-side buffering of Instances occurs during reflow lock. The user is shown a brief blocking indicator. Live Practice never overrides structural backend rules. Reflow lock duration is typically sub-second for single-parameter changes.

13.14.5 Offline Behaviour

Offline support follows Section 17 (Real-World Application Layer, §17.3.1), which is the canonical authority for offline capability. All core operations are fully supported offline, including: Start PracticeBlock, Start Session, Log Instances, End Session, local scoring, reflow (full deterministic recalculation), Calendar completion matching, and Drill creation/editing. The only operation requiring connectivity is initial account creation. Queue editing operations that reference the Practice Pool (Add drill, Create Drill from Session) are available offline. Reorder, Remove, and Duplicate are local operations and are available offline.

13.15 Section 6 Impact

The introduction of PracticeEntry as an execution-layer entity requires the following changes to the Data Model (Section 6):

PracticeBlock Entity

The DrillOrder field (Ordered Array of DrillIDs) on PracticeBlock is superseded by the PracticeEntry entity for Live Practice queue representation. DrillOrder remains as a creation-time snapshot for persistence and audit purposes. The authoritative queue order during Live Practice is determined by PracticeEntry.PositionIndex.

PracticeEntry Entity (New)

PracticeEntry is a new entity in the Section 6 data model. Its schema is defined in §13.3.1. It is a child of PracticeBlock. It has a nullable foreign key to Session. It is deleted when the parent PracticeBlock is deleted (cascade). It does not participate in scoring or derived state materialisation.

Indexing

Required indexes:

- PracticeEntry(PracticeBlockID, PositionIndex) — queue ordering.

- PracticeEntry(SessionID) — Session lookup (nullable; sparse index recommended).

Cascade Rules

PracticeBlock deletion cascades to all child PracticeEntries. PracticeEntry deletion does not cascade to the referenced Session (Session deletion is an explicit user action governed by §13.6.2, not an automatic cascade from PracticeEntry removal). Removing a CompletedSession entry requires explicit Session deletion as a separate operation before the PracticeEntry is removed.

13.16 Structural Guarantees

Live Practice guarantees:

- Single authoritative active Session per user.

- Every Session created through a PracticeEntry (no standalone Sessions within Live Practice).

- Deterministic deletion and reflow behaviour.

- Strict separation from planning data (Calendar Independence).

- No hidden scoring mutation.

- No automatic SlotCapacity expansion.

- No persistence without execution (≥1 Session required).

- No per-shot 0–5 scores or running averages displayed during execution.

- Focus-first hierarchical UX.

- Queue flexibility without scoring compromise.

- Full compatibility with Sections 0–12.

- Technique Block drills supported with no scoring output.

- Crash recovery without data loss.

End of Section 13 — Live Practice Workflow (13v.a7 Consolidated)

