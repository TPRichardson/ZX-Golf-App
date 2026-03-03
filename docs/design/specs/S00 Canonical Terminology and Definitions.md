ZX Golf App — Canonical Terminology & Definitions

Version 0v.f1 — Consolidated

This document is the single source of truth for all terminology used across the ZX Golf App specification. Every other document in the set must use these terms exactly as defined here. If a conflict is found between this document and another, this document governs.

1. Scoring Hierarchy

Overall Score (1000)

The single composite number representing total practice performance. Maximum 1000. Sum of all Skill Area scores. Always displayed against the full 1000-point scale. The system never displays a reduced attainable total based on which subskills have data.

Skill Area

One of seven top-level golf disciplines: Irons (280), Driving (240), Putting (200), Pitching (100), Chipping (100), Woods (50), Bunkers (30). Sum of its Subskill scores.

Skill Area is the sole term used for these seven disciplines. When creating a drill, the user selects a Skill Area, which determines eligible clubs and eligible subskills. There is no separate “Category” concept.

Subskill

A measurable component within a Skill Area. Each has a fixed point allocation. The lowest level at which scoring windows operate.

Subskill Points

Allocation × (Weighted Average / 5).

2. Windows & Occupancy

Window

A rolling container of scored entries at the Subskill level. Each Subskill maintains two windows:

• Transition (25 occupancy units)

• Pressure (25 occupancy units)

Window size is fixed at 25 occupancy units. It is a system-level constant and is not user-configurable.

Occupancy Unit

Measurement of how much space an Entry consumes.

• 1.0 if Session maps to one Subskill

• 0.5 per Subskill if dual-mapped

• Minimum = 0.5

• No subdivision below 0.5

Entry

A scored Session inserted into a Subskill window. Ordered strictly by Completion Timestamp.

Window Average

Sum(score × occupancy) / total occupancy.

Weighted Average

(Transition Average × 0.35) + (Pressure Average × 0.65). The 65/35 split is a system-level constant and is not user-configurable.

Roll-Off

Removal of oldest occupancy units when window is full. Occurs in 0.5 increments. FIFO based solely on Completion Timestamp. When a 1.0 entry is partially rolled off to 0.5, the original 0–5 score is preserved unchanged; only the occupancy weight is reduced.

3. Scoring Anchors

Minimum (Min)

Maps to 0 on 0–5 scale.

Scratch

Maps to 3.5 on 0–5 scale.

Pro

Maps to 5 on 0–5 scale. Hard-capped at 5.

Linear Interpolation

Two segments: Min–Scratch (0–3.5) and Scratch–Pro (3.5–5). No nonlinear curves, no sigmoid scaling, no asymptotic ceilings.

4. Runtime Hierarchy

Drill → Routine → PracticeBlock → Session → Set → Instance

Definition Objects

Drill

Permanent definition object specifying:

• Skill Area

• Subskill mapping

• Anchors (one set per mapped subskill)

• Scoring Mode

• Drill Type

• Input Mode

• Metric Schema

• Target Definition (grid-based drills only)

• Club Selection Mode (multi-club Skill Areas only)

• RequiredSetCount (integer ≥1)

• RequiredAttemptsPerSet (integer ≥1, or null for open-ended)

Routine

Blueprint of ordered entries. Each entry is either a fixed Drill reference or a Generation Criterion (see Section 8, Planning Layer Terms). Instantiation creates a PracticeBlock snapshot. Template linkage severed after creation. If a referenced Drill is deleted or retired, it is automatically removed. Empty Routines are auto-deleted.

Execution Objects

PracticeBlock

Execution container for a real-world practice occurrence. Auto-ends after 4 hours without new Session. Persisted only if ≥1 Session exists.

Session

Runtime execution of one Drill. Atomic unit that enters Subskill windows. Score = simple average of all Instance 0–5 scores across all Sets.

Set

Sequential attempt container within a Session. Sets are strictly sequential: Set N+1 cannot begin until Set N is complete. No interleaving. No parallel Sets. Not an independent scoring unit.

Instance

Atomic logged attempt within an active Set. Stores raw metric(s), selected club, timestamp, and derived 0–5 score. Editable without affecting chronological ordering.

SelectedClub is stored on every Instance. Even when the club does not change between shots, it is recorded per Instance.

5. Drill Classification

Drill Types (immutable post-creation)

Technique Block

Non-scored drill. No Subskill mapping. No window entry. No anchors. Open-ended only (RequiredSetCount=1, RequiredAttemptsPerSet=null).

Transition

Scored drill entering Transition window (35%).

Pressure

Scored drill entering Pressure window (65%).

Scored Drill

Collective term for Transition and Pressure drills.

Scoring Mode

Shared Mode

Drill maps to one or two subskills. One 0–5 score produced and shared across all mapped subskills. One anchor set (Min / Scratch / Pro) defines the scoring scale.

Multi-Output Mode

Drill maps to exactly two subskills. One drill execution captures data that produces two independent performance metrics. Each subskill has its own independent anchor set (Min / Scratch / Pro). Each subskill receives its own independently calculated 0–5 score. Occupancy = 0.5 per subskill. Total system influence equals one drill.

Input Modes

Each Metric Schema uses one of four input modes:

Grid Cell Selection

User taps which cell the shot landed in. Used for accuracy and direction drills. The grid represents a spatial target area with a defined center box. Cells outside the center box represent misses in a specific direction.

Continuous Measurement

User enters a numeric value (e.g. distance in yards). Used for distance-based drills where a precise measurement is available.

Raw Data Entry

User enters a numeric value with no spatial target reference (e.g. swing speed in mph). Used for drills measuring output rather than accuracy.

Binary Hit/Miss

User taps Hit or Miss. Used for drills where the performance measure is whether the user achieved their declared intention (e.g. intended shot shape or trajectory). The scored metric is hit-rate percentage, identical to Grid Cell Selection. No spatial target, no grid, and no numeric value is involved. Binary Hit/Miss schemas do not carry HardMinInput or HardMaxInput and are excluded from integrity detection (Section 11), identical to Grid Cell Selection.

Drill Origin

System Drill

Centrally governed. Anchors, Drill Type, Subskill mapping, Metric Schema, RequiredSetCount, and RequiredAttemptsPerSet are immutable to users. Central edits trigger full reflow.

User Custom Drill

User-created. Anchors editable (triggers reflow).

The following fields are immutable post-creation: Subskill mapping, Metric Schema, Drill Type, RequiredSetCount, and RequiredAttemptsPerSet. Changing any of these requires creation of a new Drill.

Drill Duplication

Creation of a new User Custom Drill by copying an existing drill (System or User Custom). The duplicate receives a new DrillID with Origin = UserCustom. All structural fields are copied. Anchors are copied and editable. Structural identity fields remain immutable post-creation.

6. Grid Scoring Model

Grid Types

3×3 Grid (Multi-Output)

Nine cells arranged in a 3×3 matrix. The center box represents the target. Used with Multi-Output Mode to produce two independent scores:

• Direction subskill: Any shot in the center column (top-center, center, bottom-center) is a hit. Left column and right column are misses.

• Distance subskill: Any shot in the middle row (left-ideal, center, right-ideal) is a hit. Top row (long) and bottom row (short) are misses.

The center cell is a hit for both subskills. Edge-center cells are a hit for one subskill and a miss for the other. Corner cells are misses for both.

1×3 Grid (Direction Only — Shared Mode)

Three cells: Left, Center, Right. Center is a hit. Left and right are misses. Produces one score for a direction subskill.

3×1 Grid (Distance Only — Shared Mode)

Three cells: Long, Ideal, Short. Ideal is a hit. Long and short are misses. Produces one score for a distance subskill.

Grid Scoring Metric

For all grid types, the scored metric is the hit-rate percentage: (number of hits / total Instances) × 100. This percentage is run through the drill’s Min / Scratch / Pro anchors using standard linear interpolation to produce a 0–5 score.

For a 3×3 Multi-Output drill, each subskill’s hit-rate is calculated independently and scored against its own anchor set.

7. Target Definition

Grid-based drills require a Target Definition that specifies the physical meaning of the center box. The target is shown to the user on the Instance entry screen so they can accurately judge which cell their shot landed in.

Target Distance

How far away the target is. Three modes:

• Fixed: A set value (e.g. 150 yards) regardless of club.

• Club Carry: Uses the selected club’s carry distance from the user’s bag configuration.

• Percentage of Club Carry: A defined percentage of the selected club’s carry distance (e.g. 80%).

Club Carry and Percentage of Club Carry modes are only available if the user has entered carry distances for their clubs. These modes are greyed out until the required data is complete.

Target Size

The dimensions of the center box. Two modes:

• Fixed: Set dimensions (e.g. 10m wide, 15m deep).

• Percentage of Target Distance: Dimensions scale as a percentage of the resolved target distance (e.g. width = 7% of target distance).

The target box size scales by club (via the resolved target distance) but does not scale by anchor level. One box is shown to the user per Instance.

Anchors for grid-based drills are always hit-rate percentages against whatever box is defined.

Target Size Dimensions

Grid type determines which dimensions are required:

• 3×3 Grid: Width and depth required.

• 1×3 Grid (direction only): Width only.

• 3×1 Grid (distance only): Depth only.

8. Club Selection

SelectedClub

Stored on every Instance. Recorded per shot even when the club does not change. Determines the resolved target distance and target box size for that Instance.

Club Selection Mode

A drill-level setting, applicable to drills in Skill Areas where the user has configured two or more eligible clubs. Three modes: Random (system selects, user cannot override), Guided (system suggests, user may override), User Led (user selects, default). If a Skill Area has only one eligible club, the system auto-selects and this setting is not displayed. Eligible clubs are determined dynamically by the user’s Skill Area Club Mappings (see Section 9).

• Random: System selects from eligible clubs. User cannot override.

• Guided: System suggests a club. User may override.

• User Led: User selects the club for each Instance (default).

9. Drill Lifecycle States

Active

Available for new Sessions.

Retired

Hidden from new use. Historical Sessions retained. Drill identity preserved.

Deleted

Drill permanently removed. All Sessions, Sets, and Instances removed. Drill identity destroyed. Historical reconnection impossible.

10. Session Lifecycle States

Active

Session in progress.

Closed

Session ended (manual, structured completion, or auto-close). Entry inserted into window(s).

Discarded

Session hard-deleted. No scoring impact. A Session may be discarded manually by the user, or auto-discarded when the last remaining Instance in a closed unstructured Session is deleted.

Incomplete

Structured drill with not all Sets complete. Session cannot be saved. User must complete or discard. No partial saves permitted.

Completion Timestamp

Authoritative timestamp determining window position.

• Structured Completion → timestamp of final Instance of final Set

• Manual End (unstructured) → moment End Drill pressed

• Auto-Close (inactivity) → timestamp of last Instance

11. Set Structure

Two drill fields govern Set structure:

RequiredSetCount

Integer ≥1. How many Sets constitute a complete Session.

RequiredAttemptsPerSet

Integer ≥1, or null. How many Instances complete each Set. If null, the Set (and therefore Session) is open-ended and requires manual End Drill.

Structured Drill

RequiredSetCount ≥1 and RequiredAttemptsPerSet ≥1. Session auto-closes when final Instance of final Set is logged.

Unstructured Drill

RequiredSetCount=1 and RequiredAttemptsPerSet=null. Manual End required. Unlimited Instances allowed.

Rules

• Set structure does not affect scoring calculation.

• Governs Session closure eligibility only.

• Single Instance valid for scoring in unstructured drills.

• Technique Block drills are always unstructured.

Post-Close Editing Rules

Editing constraints after Session close depend on drill structure. All post-close edits trigger reflow.

Structured Drills

• Instance value may be edited (grid cell or metric value).

• Individual Instance deletion prohibited (would violate RequiredAttemptsPerSet).

• Individual Set deletion prohibited (would violate RequiredSetCount).

• Entire Session may be deleted.

Unstructured Drills

• Instance value may be edited.

• Individual Instances may be deleted.

• Deleting the last remaining Instance auto-discards the Session.

• Entire Session may be deleted.

Immutable (Post-Creation) Fields

The following fields define drill structural identity and are immutable post-creation for all drills (System and User Custom):

• Subskill mapping

• Metric Schema

• Drill Type

• RequiredSetCount

• RequiredAttemptsPerSet

• Club Selection Mode

• Target Definition (grid-based drills only)

Editing any of the above requires creation of a new Drill.

Set Structure Governance

RequiredSetCount and RequiredAttemptsPerSet are immutable for both System Drills and User Custom Drills. Any change requires creation of a new Drill. Historical Sessions remain bound to the original drill definition.

12. Data Integrity & Governance

Reflow

Full historical recalculation triggered by changes to Structural Parameters. Executes as a background process immediately after edit. UI displays loading state until complete. Anchor edits rewrite history via deterministic recalculation. Set structure edits do not rewrite history; they require new Drill creation.

Reflow Triggers

User-initiated: Drill anchor edits (User Custom Drills only).

System-initiated: Skill Area allocation edits, Subskill allocation edits, 65/35 weighting edits, scoring formula edits, System Drill anchor edits.

Window size is a fixed system constant and is not a reflow trigger.

Structural Parameter

Any value whose change alters historical scoring (anchors, weights, formula).

Immutable (post-creation)

Field structurally prohibited from editing. Changing it requires creation of a new Drill. Not a reflow parameter.

Deterministic

Same inputs always produce same outputs.

Recalculable

All scores verifiable by replaying historical data.

Canonical

Single authoritative version. No legacy branches.

Harmonised

Confirmed consistent across specification set.

13. Planning Layer Terms

Calendar

A single persistent object per user representing all days past and future. Serves as both the execution planning surface and a living record of actual practice. The Calendar contains CalendarDays.

CalendarDay

A single date within the Calendar. Stores SlotCapacity and an ordered list of Slots. CalendarDay entities are only persisted when deviating from the user’s default day-of-week SlotCapacity pattern or when a Slot is filled (sparse storage with default fallback).

Slot

A single position within a CalendarDay representing one planned Session executing one Drill. Strictly 1:1 with Drills. Each Slot stores: DrillID, OwnerType, OwnerID, CompletionState, CompletingSessionID, and a Planned flag.

SlotCapacity

The number of Slots available on a CalendarDay. Defaults to a user-configurable day-of-week pattern (system default: 5). May be increased automatically by completion overflow.

Routine

A reusable ordered list of entries (fixed DrillIDs and/or Generation Criteria). Serves as an atomic building block for practice planning. Routines may not reference other Routines. Formerly referred to as Routine in earlier sections.

Schedule

A reusable multi-day blueprint for populating CalendarDay Slots. Contains entries (fixed DrillIDs, Generation Criteria, or Routine references). Operates in one of two Application Modes: List or Day Planning. Not calendar-bound until applied.

Generation Criterion

A parameterised instruction within a Routine or Schedule for the system to select a drill at application time. Specifies: Skill Area (optional — if omitted, the Weakness Detection Engine selects), Drill Type (required, multi-select), Subskill (optional), Generation Mode (required: Weakest, Strength, Novelty, or Random). Resolved fresh against current engine state each time the parent Routine or Schedule is applied.

Application Mode

A Schedule-level setting governing how entries map to CalendarDays. Two modes: List Mode (flat ordered list, sequential fill across days, wraps on exhaustion) and Day Planning Mode (N template days, each with an entry list, cycling across CalendarDays).

RoutineInstance

Created when a Routine is applied to a CalendarDay and confirmed. Tracks which Slots the application filled. Supports unapply (clears owned Slots and deletes the record). Self-sufficient — works regardless of source Routine lifecycle.

ScheduleInstance

Created when a Schedule is applied to a CalendarDay range and confirmed. Tracks which Slots across which CalendarDays the application filled. Supports unapply. Self-sufficient — works regardless of source Schedule lifecycle.

Slot Ownership

Each filled Slot records an OwnerType (Manual, RoutineInstance, or ScheduleInstance) and an OwnerID. Manual edits to a Slot break the previous owner’s ownership.

Completion Matching

The system’s process of monitoring all Closed Sessions and matching them to CalendarDay Slots. Source-agnostic (any Closed Session counts), date-strict (user’s home timezone), first-match ordering for duplicate DrillIDs. Only Closed Sessions trigger matching.

Completion Overflow

When a completed Session matches no existing Slot and no empty Slot exists on the CalendarDay, the system auto-creates an additional Slot, increases SlotCapacity by 1, fills the Slot, and flags it as Planned = false.

Plan Adherence

Metric measuring practice discipline: (Completed planned Slots / Total planned Slots) × 100. Overflow Slots (Planned = false) excluded from calculation. Displayed as a 4-week headline in Planning and with detailed breakdowns in Review.

WeaknessIndex

Allocation-weighted ranking metric for Subskills: (5 − WeightedAverage) × (SubskillAllocation / 1000). Higher value = higher priority for practice. Used by the Weakness Detection Engine to drive drill selection in generation criteria resolution.

14. Metrics Integrity Terms

IntegrityFlag

Boolean field on the Session entity. True if one or more Instances in the Session have a raw metric value outside the schema’s HardMinInput/HardMaxInput range. State-derived: reflects current Instance data, not historical events. Auto-resolves when all Instances return to valid range. No scoring impact.

IntegritySuppressed

Boolean field on the Session entity. True when the user has manually cleared an active IntegrityFlag. Persisted and survives app restarts. Resets to false on any Instance edit within the Session. Suppresses the UI indicator while active. No scoring impact.

HardMinInput

System-defined decimal field on each numeric-entry Metric Schema (Continuous Measurement and Raw Data Entry). Defines the minimum plausible value for the schema. Immutable. Not user-editable. Not per-drill. Not per-user. Governs negativity (schemas allowing negative values define a negative HardMinInput). Not a reflow trigger.

HardMaxInput

System-defined decimal field on each numeric-entry Metric Schema (Continuous Measurement and Raw Data Entry). Defines the maximum plausible value for the schema. Immutable. Not user-editable. Not per-drill. Not per-user. Not a reflow trigger.

IntegrityFlagRaised

EventLog event type. Written when an Instance is saved with a raw metric outside the schema’s plausibility bounds and the Session’s IntegrityFlag is set to true.

IntegrityFlagCleared

EventLog event type. Written when a user manually clears an active IntegrityFlag. Session IntegritySuppressed is set to true.

IntegrityFlagAutoResolved

EventLog event type. Written when all Instances in a Session return to valid plausibility bounds following an edit, and the Session’s IntegrityFlag is automatically set to false.

15. Real-World Application Layer Terms

DeviceID

UUID generated on first application launch per device. Registered against the user’s account on first server connection. Used for sync bookkeeping only: tracking last sync timestamp per device, identifying data origin for audit purposes, and annotating EventLog entries. No scoring impact. Not exposed in UI beyond a device list in Settings.

UserDevice

Entity representing a registered device for a user. Stores DeviceID, UserID, device label, registration timestamp, and last sync timestamp. Pure synchronisation infrastructure with no scoring impact.

Last-Write-Wins (LWW)

Conflict resolution strategy for mutable structural configuration during multi-device synchronisation. When two devices edit the same entity, the edit with the later UTC timestamp (UpdatedAt field) wins. Applies to User Custom Drill definitions, club configuration, Routine and Schedule definitions, CalendarDay Slot assignments, and user Settings. Does not apply to append-only execution data (which merges additively) or soft-delete flags (which always propagate forward).

Deterministic Merge-and-Rebuild

The synchronisation model used by ZX Golf App. Raw execution data is merged additively, structural edits are resolved via LWW, and each device then rebuilds all materialised scoring state locally via deterministic reflow. No device and no server holds authoritative scoring state. All devices converge to identical results from identical raw data.

Sync Pipeline

The ordered sequence of steps executed during device synchronisation: (1) Upload local changes, (2) Download remote changes, (3) Merge (append-only data plus LWW for structural edits), (4) Completion matching re-run, (5) Deterministic rebuild (full local reflow), (6) Confirm (update last sync timestamp). Defined in Section 17 (§17.4.3).

End of 0v.f1 Consolidated Definitions

