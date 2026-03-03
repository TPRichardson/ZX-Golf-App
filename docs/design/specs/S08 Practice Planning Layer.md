Section 8 — Practice Planning Layer

Version 8v.a8 — Consolidated

This document defines the canonical Practice Planning Layer. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 3 (User Journey Architecture 3v.g7), Section 4 (Drill Entry System 4v.g8), Section 5 (Review 5v.d6), Section 6 (Data Model & Persistence Layer 6v.b7), Section 7 (Reflow Governance System 7v.b9), Section 11 (Metrics Integrity & Safeguards 11v.a5), Section 12 (UI/UX Structural Architecture 12v.a5), and the Canonical Definitions (0v.f1).

8.1 Core Planning Objects

The Planning layer introduces four new structural objects: Calendar, Routine, Schedule, and their application instances. These objects are strictly separated from the scoring engine — they do not modify window state, scoring parameters, or derived scores. The Planning layer is read-only with respect to all scoring engine state.

8.1.1 Calendar

The Calendar is a single persistent object per user. It represents all days past and future and serves as both the execution planning surface and a living record of actual practice.

Structure

-   One Calendar per user

-   Perpetual — every day implicitly exists

-   Each day exposes a SlotCapacity: the number of planned Sessions for that day

-   Default SlotCapacity follows a day-of-week pattern (7 values, one per day of the week), configured in Settings. System default: 5 for all days.

-   Users reduce or zero out days they do not wish to practise on

-   SlotCapacity = 0 represents a rest day

CalendarDay Persistence

A CalendarDay entity is only created in the persistence layer when the day deviates from the user’s default SlotCapacity pattern — either the user modifies SlotCapacity, or a Slot is filled with a DrillID. Days with no entity are rendered using the default pattern. This is a sparse storage model with default fallback.

Slot Model

Each Slot represents one planned Session executing one Drill. The relationship is strictly 1:1 — a Slot cannot contain multiple Drills. Slots are ordered within a CalendarDay. Existing Slot assignments are never overwritten by system actions — Schedules and Routines fill remaining capacity only.

Slot Filling

Slots may be filled by:

-   Manual assignment — user directly places a DrillID into a Slot

-   Routine application — a Routine’s entries populate available Slots on a single CalendarDay

-   Schedule application — a Schedule’s entries populate available Slots across a range of CalendarDays

-   Completion overflow — when a completed Session matches no existing Slot and no empty Slot exists, the system creates an additional Slot and fills it (see §8.3.3)

Manual assignment, Routine application, and Schedule application fill only empty Slots. If a CalendarDay has 5 Slots with 2 already filled, any application may fill up to 3 additional Slots.

SlotCapacity Editing

The user may increase or decrease a CalendarDay’s SlotCapacity at any time. However, SlotCapacity cannot be reduced below the number of currently filled Slots — the system enforces a hard block. The user must clear Slots before reducing capacity.

8.1.2 Routine

A Routine is a reusable ordered list of entries. It serves as an atomic building block for practice planning. A Routine is the object referenced in Section 3 (§3.1.2) and Section 6 (§6.2), extended with mixed entry support.

Entry Types

Each entry in a Routine is independently one of two types:

-   Fixed DrillID — a specific drill from the user’s Practice Pool

-   Generation Criterion — a parameterised instruction for the system to select a drill at application time

Routines may not reference other Routines. Schedules are the only object that can reference Routines.

Generation Criterion Schema

Each generation criterion entry specifies:

-   Skill Area (optional — if omitted, the Weakness Detection Engine selects the Skill Area based on the active mode)

-   Drill Type (required) — multi-select from Technique, Transition, Pressure. At least one must be selected.

-   Subskill (optional) — narrows selection within the Skill Area

-   Generation Mode (required) — Weakest, Strength, Novelty, or Random

The generation mode is set per entry, not per Routine. A single Routine may mix modes across its entries.

Criteria Resolution

Generation criteria are resolved to specific DrillIDs at application time — each time the Routine is used, criteria are resolved fresh against the current scoring engine state and Practice Pool. The Routine stores criteria permanently, never resolved DrillIDs. This ensures recommendations remain current.

No Draft Stage

Routine creation has no draft stage. The user builds the Routine directly by adding fixed DrillIDs and/or criteria entries, then saves. Resolution occurs only at application time.

Referential Integrity

A Routine references Drills (for fixed entries) but does not own them. If a referenced Drill is deleted or retired, it is automatically removed from the Routine. If the entry list becomes empty, the Routine is auto-deleted. See Section 6 (§6.2) for cascade rules. Generation criteria entries are unaffected by individual drill lifecycle changes — they reference Skill Areas and Drill Types, not specific drills.

Save as Manual (Clone)

At any point after application (when criteria have been resolved to a preview), the user may clone the resolved result into a new Routine containing only fixed DrillIDs. The original Routine remains intact with its criteria. The cloned Routine is a standard fixed-entry Routine with no generation capability.

Retirement and Deletion

Routines may be retired (hidden from active use, preserved) or deleted. Neither action affects any Drill, Session, or scoring data.

8.1.3 Schedule

A Schedule is a reusable multi-day blueprint for populating CalendarDay Slots. It defines a pattern of entries across days. A Schedule is not calendar-bound — it contains no specific dates until applied.

Entry Types

Each entry in a Schedule is independently one of three types:

-   Fixed DrillID — a specific drill from the user’s Practice Pool

-   Generation Criterion — same schema as Routine criteria (Skill Area + Drill Type multi-select + optional Subskill + Mode per entry)

-   Routine Reference — a reference to a saved Routine, which expands inline at application time

When a Routine reference is expanded, its entries (both fixed DrillIDs and resolved criteria) are inserted sequentially into the Slot stream. Routine expansion is inline — the Routine’s entries compete for Slots like any other Schedule entry.

Application Modes

A Schedule operates in one of two application modes, selected at creation:

List Mode: The Schedule defines a single flat ordered list of entries. When applied to a CalendarDay range, entries fill available Slots sequentially across days. When the list is exhausted, it wraps back to the first entry and repeats. The list does not carry unfilled entries across day boundaries; each day starts from where the list left off.

Day Planning Mode: The Schedule defines N template days, each containing an ordered list of entries. When applied to a CalendarDay range: Template Day 1’s entries fill available Slots on CalendarDay 1 in order. If a CalendarDay has fewer available Slots than the template day’s entry count, excess entries for that template day are discarded. The system advances to the next template day for the next CalendarDay, regardless of remaining entries. Template days with zero entries are treated as rest-day templates — the corresponding CalendarDay is skipped. After the final template day, the cycle wraps back to Template Day 1. CalendarDays with SlotCapacity = 0 still consume a template day position (they advance the cycle). The template day’s entries are discarded for that day.

Criteria Resolution

As with Routines, generation criteria within a Schedule are resolved at application time, fresh against the current engine state. The Schedule stores criteria permanently, never resolved DrillIDs.

Save as Manual (Clone)

After application (when all criteria have been resolved to a preview), the user may clone the resolved Schedule state into a new Schedule containing only fixed DrillIDs and Routine references. The original Schedule remains intact.

Referential Integrity

A Schedule references Drills (for fixed entries) and Routines (for Routine reference entries) but does not own them.

-   If a referenced Drill is deleted or retired, it is removed from the Schedule’s entry list

-   If a referenced Routine is deleted or retired, its entry is removed from the Schedule

-   If all entries are removed from a List Mode Schedule, the Schedule is auto-deleted

-   If all entries are removed from a template day in Day Planning Mode, that template day becomes an empty rest-day template. The Schedule persists unless all template days are empty, in which case it is auto-deleted

Retirement and Deletion

Schedules may be retired (hidden from active use, preserved) or deleted. Neither action affects any Drill, Routine, Session, or scoring data.

8.2 Application Model

When a Routine or Schedule is applied to the Calendar, the system resolves all entries, presents a preview, and creates an application instance to track which Slots were filled.

8.2.1 Application Preview

Before committing to the Calendar, the system presents a preview showing all resolved DrillIDs mapped to CalendarDay Slots. The user may:

-   Confirm — commit all Slot assignments to the Calendar

-   Discard — cancel the application entirely

-   Reroll all — re-resolve all generation criteria entries (fixed DrillIDs and Routine references are unaffected)

-   Reroll individual Slot — re-resolve a single generation criterion entry for that Slot

Reroll Behaviour

When rerolling an individual Slot, the system selects a different drill from the eligible pool. The last 2 drills shown for that Slot are excluded from the reroll. A drill shown 3 or more rerolls ago may appear again.

If the eligible pool for a criterion contains fewer than 3 drills, the exclusion window is reduced to fit: 2 eligible drills = exclude 1; 1 eligible drill = no exclusion (reroll effectively disabled for that Slot).

Fixed DrillID entries and Routine reference entries are not rerollable.

8.2.2 Routine Application

A Routine is applied to a single CalendarDay. The Routine’s entries populate available Slots in order. If the CalendarDay has fewer available Slots than the Routine has entries, excess entries are discarded.

On confirmation, a RoutineInstance is created (see §8.2.4).

8.2.3 Schedule Application

A Schedule is applied to a range of CalendarDays. The user specifies the start date and end date. Entry-to-Slot mapping follows the Schedule’s application mode (List Mode or Day Planning Mode). CalendarDays with SlotCapacity = 0 are skipped (in List Mode) or consume a template day position (in Day Planning Mode). Only empty Slots are filled.

On confirmation, a ScheduleInstance is created (see §8.2.5).

8.2.4 RoutineInstance

Canonical schema defined in Section 6 (§6.2). Behavioural specification follows.

Created when a Routine is applied to a CalendarDay and confirmed.

Schema

-   RoutineID (source Routine)

-   CalendarDay date

-   List of owned Slot positions (the specific Slots this application filled)

-   CreatedAt (UTC)

Slot Ownership

Each Slot filled during the application is owned by the RoutineInstance. If the user subsequently manually edits a Slot’s DrillID, that Slot’s ownership is broken — it becomes a manual assignment and is no longer tracked by the RoutineInstance.

Unapply

The user may unapply a RoutineInstance at any time. This clears all Slots still owned by the instance and deletes the RoutineInstance record. Slots whose ownership was broken by manual editing are left untouched. Unapply works regardless of whether the source Routine still exists — the instance is self-sufficient.

Visual Distinction

The UI visually distinguishes Slots owned by a RoutineInstance from manually assigned Slots and Slots owned by a ScheduleInstance.

8.2.5 ScheduleInstance

Canonical schema defined in Section 6 (§6.2). Behavioural specification follows.

Created when a Schedule is applied to a CalendarDay range and confirmed.

Schema

-   ScheduleID (source Schedule)

-   Start date

-   End date

-   List of owned Slot positions (CalendarDay date + Slot index pairs)

-   CreatedAt (UTC)

Slot Ownership

Same ownership model as RoutineInstance. Manual edits to a Slot break the ScheduleInstance’s ownership of that Slot.

Unapply

Same behaviour as RoutineInstance — clears owned Slots, deletes the ScheduleInstance record. Manually edited Slots are preserved. Unapply works regardless of whether the source Schedule still exists.

Coexistence

Multiple ScheduleInstances may coexist on the same CalendarDays. Each owns only the Slots it filled. A RoutineInstance and a ScheduleInstance may also coexist on the same CalendarDay.

8.2.6 Instance Snapshot Behaviour

Instances are snapshots created at application time. If the user subsequently edits the source Routine or Schedule, existing Instances are unaffected. Edits to blueprints only affect future applications. This is consistent with the PracticeBlock instantiation model in Section 3 (§3.1.2).

8.2.7 Slot Integrity on Drill Deletion

If a Drill referenced in a CalendarDay Slot is deleted or retired, the Slot is cleared immediately. If the Slot was owned by a RoutineInstance or ScheduleInstance, the instance loses ownership of that Slot position.

8.3 Execution & Completion

8.3.1 Calendar-Initiated Practice

The user may start practice directly from a CalendarDay. This creates a PracticeBlock from the day’s filled Slots in Slot order. Any generation criteria that have not been pre-resolved (e.g. the user did not go through an application preview for manually added criteria) are resolved at this point. Standard PracticeBlock rules apply (Section 3, §3.1.3).

The user is not required to execute drills in the Slot order — the order is a recommendation, not a constraint.

8.3.2 Universal Completion Matching

The system monitors all Closed Sessions and matches them to CalendarDay Slots using the following rules:

-   A Closed Session’s CompletionTimestamp date (in the user’s home timezone) is matched to the CalendarDay of the same date

-   If the CalendarDay contains a Slot with the same DrillID as the completed Session, that Slot is marked complete

-   Matching is source-agnostic — it does not matter whether the Session was started from the Calendar, a Routine, a manual PracticeBlock, or any other source

-   Only Closed Sessions trigger completion matching. Starting a Session does not mark completion.

-   Matching is always active across all PracticeBlocks — if a user completes multiple PracticeBlocks in a day, all completions are matched

Duplicate Drill Handling

If a CalendarDay has the same DrillID in multiple Slots, one completed Session marks only the first (earliest ordered) matching incomplete Slot. A second Session of the same Drill is required to mark the second Slot.

Technique Block Completions

Technique Block Sessions are Closed Sessions and participate in completion matching like any scored drill. The Calendar measures practice discipline, not scoring output.

8.3.3 Completion Overflow

If a user completes a Session for a Drill that does not appear in any Slot on the CalendarDay, or all matching Slots are already complete and no empty Slots exist:

-   The system creates an additional Slot on the CalendarDay

-   The CalendarDay’s SlotCapacity is permanently increased by 1

-   The new Slot is filled with the completed DrillID and marked complete

-   The new Slot is assigned Manual ownership

-   The new Slot is flagged as Planned = false (overflow), distinguishing it from deliberately planned Slots

The overflow increase is permanent but the user retains full control of SlotCapacity. If the user later clears the overflow Slot, they may manually reduce SlotCapacity back down (subject to the hard block: capacity cannot be reduced below the number of currently filled Slots).

8.3.3.1 Overflow Scope

Completion overflow increases SlotCapacity on the persisted CalendarDay entity for that specific date only. It does not modify the user’s underlying default 7-day SlotCapacity pattern (configured in Settings, §10.8). Future non-persisted CalendarDays continue to use the unmodified default pattern.

Over time, heavy Clean Practice usage may accumulate overflow capacity on individual persisted CalendarDays, creating a drift between those days’ persisted SlotCapacity and the user’s default pattern. This is by design — the Calendar is a living record of actual practice, including unplanned work. Users who wish to restore alignment may manually reduce SlotCapacity on individual days after clearing overflow Slots.

The system does not perform any automatic correction, suggestion, or notification regarding accumulated overflow drift. No adaptive adjustment to the default pattern occurs.

8.3.4 Completion State

Each Slot carries a completion state:

-   Incomplete — no matching Closed Session. Default state for all filled Slots.

-   Completed (linked) — a matching Closed Session exists. The Slot stores a reference to the completing SessionID, enabling the user to tap through to the Session’s score and details.

-   Completed (manual) — the user manually marked the Slot as complete without a linked Session (e.g. practice occurred but was not logged in the app). Purely visual — no scoring impact, no window entry, no Session reference.

Session Deletion Revert

If a Session that completed a CalendarDay Slot is subsequently deleted, the Slot’s CompletionState reverts to Incomplete and its CompletingSessionID is cleared. The Slot’s DrillID and ownership are preserved. The Slot returns to its pre-completion planned state.

The UI visually distinguishes completed Slots from incomplete Slots, providing a satisfying progression through the day’s plan.

8.3.5 Deviation

The Calendar is advisory, not binding. The user may deviate from planned Slots at any time:

-   Skip planned drills

-   Execute drills not on the Calendar

-   Execute drills in a different order

-   End the PracticeBlock before all Slots are executed

No scoring penalty or system intervention occurs for deviation.

8.3.6 Past CalendarDays

CalendarDays in the past are preserved as-is. Incomplete Slots remain visible as missed practice. No system action is taken on past incomplete Slots. This enables plan adherence metrics (§8.4).

8.4 Plan Adherence

The system tracks plan adherence to measure practice discipline against the user’s declared plan.

8.4.1 Adherence Metric

Adherence = (Completed planned Slots / Total planned Slots) × 100, expressed as a percentage.

Denominator (Planned Slots): Only Slots with a DrillID assigned count as planned. Empty Slots (unfilled capacity) are excluded.

Exclusions

-   Overflow Slots (Planned = false) are excluded from both the numerator and denominator. Adherence measures discipline against the original plan, not bonus work.

-   Manually completed Slots (no linked Session) count as completed for adherence purposes.

Inclusions

Any deliberately placed Slot counts as planned, regardless of how or when it was added — manual assignment, Routine application, or Schedule application. Same-day manual additions are included.

8.4.2 Display Locations

Planning Tab: A simple headline percentage is displayed: adherence over the last 4 weeks. No breakdown, no drill-level detail. Positioned on the Planning homepage alongside the Calendar.

Review Section: A detailed adherence view is available within Review, positioned as a secondary view accessible from SkillScore. Breakdown options: time period (last 4 weeks, last 3 months, last 6 months, last 12 months, or custom date range), Skill Area segmentation (of all planned Slots containing Drills in a given Skill Area, what percentage were completed), and weekly and monthly rollups.

8.4.3 Rollup Boundaries

Weekly and monthly rollup boundaries use the user’s home timezone and the user’s configured week start day (Monday or Sunday, set in Settings).

8.4.4 Date Range Persistence

User-selected date range and time period persist for 1 hour, consistent with the Analysis date range persistence model defined in Section 5 (§5.2). After 1 hour of no access, the system resets to: last 4 weeks.

8.5 Drill Creation

Drill creation is governed entirely by Section 4 (Drill Entry System). The Planning Layer does not alter drill structure, scoring behaviour, window mechanics, or any immutable field. All drill creation rules, anchor governance, immutability constraints, metric schema selection, target definition, and club selection mode are defined in Section 4 and apply without modification.

8.6 State Awareness

The Planning layer inspects the following scoring engine and analysis data to inform generation criterion resolution and weakness ranking:

-   Current Subskill weighted averages (0–5)

-   Window saturation per Subskill (Transition and Pressure independently)

-   Subskill point allocations

-   Drill recency (CompletionTimestamp of most recent Session per Drill)

-   Drill-level average Session scores (for Weakest/Strength mode drill selection)

The Planning layer is strictly read-only with respect to all inspected data. It does not write to, modify, or trigger recalculation of any scoring state.

8.7 Weakness Detection Engine

The Weakness Detection Engine produces a ranked ordering of Subskills to drive drill selection when resolving generation criteria. The ranking is transparent — the user may view the current Subskill priority ordering from both the Planning tab and the Review section (positioned as a secondary view accessible from SkillScore).

8.7.1 Ranking Granularity

Ranking operates at the Subskill level first, then resolves to Drill level within the selected Subskill. This two-stage model ensures explainability and alignment with the scoring hierarchy defined in Sections 1–2.

8.7.2 Priority Stack

Subskill ranking applies the following priority layers in strict order. Each layer acts as a tiebreaker for the layer above.

Priority 1 — Incomplete Windows: Subskills with incomplete window saturation (total occupancy < 25 in either Transition or Pressure window) are ranked above all fully saturated Subskills. Transition and Pressure windows are treated equally for this purpose. Within the incomplete tier, ordering falls through to Priority 2.

Priority 2 — Allocation-Weighted Subskill Ranking: Subskills are ranked using an allocation-weighted model that prioritises high-impact weaknesses.

For each Subskill:

-   WeightedAverage = (TransitionAvg × 0.35) + (PressureAvg × 0.65)

-   AllocationWeight = SubskillAllocation / 1000

-   WeaknessIndex = (5 − WeightedAverage) × AllocationWeight

Higher WeaknessIndex = higher priority. A Subskill with a low weighted average AND a high allocation (e.g. Irons Distance Control at 110/1000) will outrank a Subskill with the same low average but lower allocation (e.g. Woods Shape Control at 20/1000).

For Subskills with no data (WeightedAverage = 0), the formula yields: WeaknessIndex = 5 × AllocationWeight. These are ranked within the incomplete-window tier per Priority 1.

Tiebreaking

If two Subskills share identical WeaknessIndex values: lower current WeightedAverage wins. If still tied: higher AllocationWeight wins. If still tied: alphabetical by Subskill name (deterministic fallback).

8.7.3 Weakness Ranking Display

The weakness ranking view shows all Subskills in priority order with the following information per Subskill:

-   Rank position

-   Subskill name and Skill Area

-   Current weighted average (0–5)

-   Window saturation (e.g. 12/25 Transition, 25/25 Pressure)

-   WeaknessIndex value

-   Allocation (e.g. 110/1000)

This view is accessible from Planning (informing generation decisions) and from Review (as a diagnostic adjacent to SkillScore). See Section 12 (§12.6.1) for full UI placement.

8.7.4 Mode-Specific Ordering

The generation mode on each criterion entry determines how the Subskill ranking is applied. Four modes are available:

Weakest: Subskills ordered by descending WeaknessIndex (highest priority first). Drills within the selected Subskill are chosen by: lowest average Session score → then least recently executed → then alphabetical by drill name.

Strength: Subskills ordered by ascending WeaknessIndex (lowest priority first — strongest areas). Drills within the selected Subskill are chosen by: highest average Session score → then most recently executed → then alphabetical.

Novelty: Subskills ordered by descending WeaknessIndex (same as Weakest). Drills within the selected Subskill are chosen by: least recently executed Drill (longest time since last Session CompletionTimestamp) → then alphabetical. Drills with no Session history are considered maximally novel and selected first.

Random: Uniform random selection from the eligible drill pool. Subskill ranking is not applied. Every eligible drill has equal probability of selection.

8.7.5 Technique Block Integration

Technique Block drills do not map to Subskills and do not enter windows. When a generation criterion specifies the Technique Drill Type for a given Skill Area, Technique drills inherit the ranking position of their Skill Area.

-   In Weakest mode: if Irons is the weakest Skill Area, Irons Technique drills are eligible and ranked under that area

-   In Strength mode: if Driving is strongest, Driving Technique drills are ranked accordingly

-   The allocation multiplier applies at the Skill Area level (sum of Subskill allocations for that area)

-   Novelty mode operates at drill level within the Technique-filtered pool

-   Random mode remains uniform within the eligible pool

Technique drills do not compete with scored drills for Subskill-level ranking — they exist in a parallel filtered pool within the same Skill Area.

Granularity Asymmetry (Intentional): Scored drills (Transition and Pressure) compete at Subskill granularity because they map to specific Subskills. Technique Block drills compete at Skill Area granularity because they have no Subskill mapping (Section 4, §4.1; Section 2, §2.6). This means that in a Skill Area with uneven Subskill weakness distribution, Technique drill selection does not distinguish which Subskill is weakest — it responds only to the aggregate Skill Area ranking position. This asymmetry is a necessary consequence of the scoring model’s Technique Block exclusion from Subskill windows and is accepted by design.

8.8 Drill Type Filtering

Generation criteria specify Drill Type(s) per entry. This acts as a strict filter on the eligible drill pool.

8.8.1 Filter Rules

-   Each generation criterion requires at least one Drill Type: any combination of Technique, Transition, and Pressure (multi-select)

-   The filter is strict — no fallback to unselected Drill Types occurs

-   If no eligible drills exist under the specified Drill Type(s) for the criterion’s Skill Area, the criterion cannot be resolved. The Slot is left empty in the preview with a notification.

-   No soft preference behaviour — the system never substitutes an unselected Drill Type

8.8.2 Interaction with Weakness Detection

Drill Type filtering is applied before weakness ranking. The Weakness Detection Engine operates only on the filtered drill pool. If a criterion’s Skill Area + Drill Type combination yields no eligible drills, the criterion is unresolvable.

8.9 Recency & Distribution Logic

Distribution logic operates at two levels: within individual criteria (drill selection) and across application passes (Skill Area balance).

8.9.1 Intra-Application Drill Repetition Block

When resolving multiple generation criteria within a single application pass (a Routine application or a single ScheduleDay within a Schedule application), drill uniqueness is enforced:

-   The same individual Drill cannot be selected twice within a single application pass

-   The system may select the same Skill Area multiple times if the Weakness Detection Engine determines that area has the greatest need

-   If the eligible pool for a criterion is exhausted (all matching drills already selected in this pass), the Slot is left empty in the preview

When Skill Area is omitted from a criterion, the Weakness Detection Engine selects the Skill Area using the active mode’s ordering (§8.7.4). The system is free to select the same Skill Area for consecutive entries if the ranking supports it.

Random mode respects the drill repetition block but otherwise selects uniformly from the eligible pool.

8.9.2 Cross-Day Independence

Each CalendarDay within a Schedule application is resolved independently. There is no cross-day recency enforcement, no weekly balance target, and no multi-day distribution constraint.

8.10 Deterministic Resolution Algorithm

The following algorithm governs resolution of generation criteria at application time. It applies identically to Routine application and Schedule application (per CalendarDay).

8.10.1 Inputs

-   User’s Practice Pool (all Active adopted System Drills + User Custom Drills)

-   The ordered list of entries to resolve (from the Routine, Schedule entry list, or Schedule template day)

-   Available Slot count for the target CalendarDay

-   Current scoring engine state (Subskill weighted averages, window saturation)

-   Session history (CompletionTimestamps, drill-level averages)

8.10.2 Algorithm Steps

1. Expand all Routine references inline, producing a flat ordered entry list. After inline expansion, the flat entry list contains a mix of Fixed DrillIDs and Generation Criteria regardless of whether they originated from the Routine, the Schedule, or were top-level entries. All entries are processed uniformly in a single pass. The drill repetition block (§8.9.1) operates across the entire flat list.

2. Truncate the entry list to the available Slot count for the CalendarDay. Excess entries are discarded.

3. Process each entry in order: If Fixed DrillID: assign directly to the next available Slot. No resolution required. If Generation Criterion: if Skill Area is specified, filter the Practice Pool to that area. If Skill Area is omitted, the Weakness Detection Engine selects the Skill Area using the criterion’s mode. Apply Drill Type(s) and optional Subskill as strict filters. Remove Retired and Deleted drills. Apply mode-specific drill selection per §8.7.4. Enforce drill repetition block (§8.9.1). Assign the selected DrillID to the next available Slot.

4. If a generation criterion cannot be resolved (empty eligible pool), the Slot is left empty in the preview.

5. Return the ordered list of resolved DrillIDs (with any empty Slots marked) as the preview.

8.10.3 Schedule-Specific Processing

List Mode: Start at the first CalendarDay in the target range with available Slots. Fill available Slots from the entry list in order using the algorithm above. When the CalendarDay’s available Slots are filled, move to the next CalendarDay. CalendarDays with SlotCapacity = 0 are skipped entirely. When the entry list is exhausted, wrap to the first entry and continue. Continue until all CalendarDays in the range have been processed.

Day Planning Mode: Template Day 1 maps to the first CalendarDay in the range, Template Day 2 to the second, and so on. For each CalendarDay, fill available Slots from the corresponding template day’s entries using the algorithm above. If a CalendarDay has fewer available Slots than the template day’s entry count, excess entries are discarded for that day. After the final template day, the cycle wraps back to Template Day 1. CalendarDays with SlotCapacity = 0 still consume a template day position. The template day’s entries are discarded for that day.

8.10.4 Determinism Guarantee

Given identical inputs (same Practice Pool, same engine state, same entry list, same available Slots), the algorithm produces identical output for Weakest, Strength, and Novelty modes. Random mode uses a seeded pseudo-random generator with a seed derived from a hash of the user’s ID combined with the application timestamp, ensuring both reproducibility for audit purposes and per-user uniqueness.

8.11 Timezone Model

All Calendar operations use the user’s home timezone:

-   CalendarDay date boundaries are determined by the user’s home timezone

-   Completion matching uses CompletionTimestamp converted to the user’s home timezone

-   Adherence rollup boundaries (weekly, monthly) use the user’s home timezone

-   The home timezone is auto-detected from the user’s device with manual override available in Settings

-   The Calendar uses the home timezone consistently, regardless of the user’s physical location at the time of practice

8.12 UI Integration

8.12.1 Planning Tab Structure

The Planning tab uses a dual-tab internal structure, consistent with the two-tab pattern used across all primary domains (see Section 12, §12.9):

Calendar | Create

Calendar tab: Calendar view with today’s CalendarDay prominent. Default mode is a 3-day rolling view (Today + 2 days), toggleable to a 2-week strategic view. Shows Slot fill state, completion progress, and the 4-week adherence headline percentage. Full calendar interaction model (Slot editing, drag-and-drop, bottom drawer) is defined in Section 12 (§12.4).

Create tab: Three equal tiles for object creation: Create Drill (“Design a new practice test”), Create Routine (“Build a repeatable session”), and Create Schedule (“Plan multiple days at once”). After creating a Drill, the user is offered Save and Save & Practice (which launches Live Practice immediately). See Section 12 (§12.4.5).

8.12.2 Home Dashboard Integration

Today’s Slot Summary appears on the Home Dashboard (Section 3, §3.3; Section 12, §12.3). The summary shows filled Slot count and total SlotCapacity with a visual progress indicator.

The Home action zone provides two practice entry points:

-   Start Today’s Practice — visible only when today’s CalendarDay has at least one filled Slot. Launches Live Practice pre-loaded with today’s planned Slots in Slot order.

-   Start Clean Practice — always visible. Launches Live Practice with an empty PracticeBlock. The user adds drills within the Live Practice workflow.

This is positioned within the existing Home Dashboard layout defined in Section 12 (§12.3).

8.12.3 Notifications

Optional push notifications for upcoming planned practice:

-   Single daily notification at a user-configured time

-   Notification sent only if the CalendarDay has filled (planned) Slots

-   Toggle on/off in Settings

-   Notification content: count of planned Slots for the day

8.12.4 Visual Slot States

The Calendar UI distinguishes the following Slot states:

-   Empty — no DrillID assigned

-   Planned (incomplete) — DrillID assigned, not yet completed

-   Completed (linked) — matched to a Closed SessionID

-   Completed (manual) — user-marked complete without a Session

-   Overflow — auto-created for unplanned completions (Planned = false)

Slot ownership is also visually indicated:

-   Manual — user-placed or overflow

-   RoutineInstance-owned — placed by a Routine application

-   ScheduleInstance-owned — placed by a Schedule application

8.13 Data Model Additions

Section 8 introduces the following additions to the persistence layer defined in Section 6.

8.13.1 New Entities

CalendarDay: UserID (owner), Date (UTC), SlotCapacity (integer ≥ 0), Slots (ordered list; each Slot stores: DrillID or null, OwnerType + OwnerID or null, CompletionState, CompletingSessionID or null, Planned flag), CreatedAt (UTC), UpdatedAt (UTC). Only created when deviating from user’s default day-of-week SlotCapacity pattern or when a Slot is filled.

Routine: UserID (owner), Name, Entries (ordered list; each entry is: {Type: Fixed, DrillID} or {Type: Criterion, SkillArea, DrillTypes[], Subskill?, Mode}), Status: Active or Retired, CreatedAt (UTC), UpdatedAt (UTC).

Schedule: UserID (owner), Name, ApplicationMode: List or DayPlanning. For List Mode: Entries (single ordered list; each entry is Fixed DrillID, Generation Criterion, or RoutineID reference). For Day Planning Mode: TemplateDays (ordered list of template days, each containing an ordered entry list). Status: Active or Retired, CreatedAt (UTC), UpdatedAt (UTC).

RoutineInstance: RoutineID (source Routine, nullable — null if source deleted), UserID (owner), CalendarDay date, OwnedSlots (list of Slot positions on the CalendarDay), CreatedAt (UTC).

ScheduleInstance: ScheduleID (source Schedule, nullable — null if source deleted), UserID (owner), StartDate, EndDate, OwnedSlots (list of CalendarDay date + Slot position pairs), CreatedAt (UTC).

8.13.2 Slot Schema

Each Slot within a CalendarDay contains:

-   DrillID (nullable — null if empty)

-   OwnerType: Manual, RoutineInstance, or ScheduleInstance

-   OwnerID (nullable — reference to the owning Instance, null for Manual)

-   CompletionState: Incomplete, CompletedLinked, or CompletedManual

-   CompletingSessionID (nullable — set only for CompletedLinked state)

-   Planned: boolean (true for deliberately placed Slots, false for overflow Slots)

8.13.3 Referential Integrity

-   CalendarDay references Drills in Slots but does not own them

-   RoutineInstance references a Routine and CalendarDay Slots — unapply clears owned Slots and deletes the record

-   ScheduleInstance references a Schedule and CalendarDay Slots — unapply clears owned Slots and deletes the record

-   If a source Routine or Schedule is deleted, the Instance’s source reference is set to null. The Instance persists, Slots remain filled, and unapply remains available.

-   If a Drill referenced in a Slot is deleted or retired, the Slot is cleared immediately. The owning Instance (if any) loses ownership of that Slot position.

8.13.4 No Scoring Impact

Calendar, CalendarDay, Routine, Schedule, RoutineInstance, and ScheduleInstance entities have no relationship to the scoring engine. They do not trigger reflow, do not enter windows, and do not affect any derived scoring state. They are pure planning objects. Plan adherence metrics are computed from planning data only and do not interact with the scoring engine.

8.14 Settings Additions

Section 8 introduces the following user-configurable settings:

-   Default SlotCapacity pattern — 7 values, one per day of the week (system default: 5 for all days)

-   Home timezone — auto-detected from device, manually overridable

-   Week start day — Monday or Sunday

-   Practice notification toggle — on/off

-   Practice notification time — time of day for the daily notification

8.15 Structural Guarantees

The Practice Planning Layer guarantees:

-   No modification of scoring engine state — Planning is strictly read-only with respect to windows, scores, and structural parameters

-   No hidden redistribution of skill weights — allocation-weighted ranking uses published allocations transparently

-   No creation of new Drills by generation criteria — drill pool is always user-authored or system-provided

-   Strict Slot filling rules — existing assignments are never overwritten by system actions

-   Deterministic resolution under identical conditions for Weakest, Strength, and Novelty modes

-   No structural overrides — Routines and Schedules cannot modify drill definitions, Set counts, or scoring anchors

-   Transparent weakness ranking — user may inspect the current Subskill priority ordering from Planning and Review

-   Preview with confirm/discard — all Calendar applications require explicit user confirmation before committing

-   Reroll capability — individual or bulk re-resolution of generation criteria during preview with rolling 2-drill exclusion window

-   Full compatibility with Sections 1–7 — no architectural deviation from the canonical scoring model, data model, or reflow governance

-   Clean separation of blueprint and calendar — Routines and Schedules are reusable templates; the Calendar is the execution surface

-   Application traceability — RoutineInstance and ScheduleInstance records track provenance of Slot assignments with full unapply support

-   Universal completion matching — source-agnostic, timezone-consistent, always active

-   Plan adherence measurement — excludes overflow, includes all deliberately planned Slots

-   Instance self-sufficiency — unapply works regardless of source blueprint lifecycle

-   UI structure aligned with Section 12 — Planning tab uses Calendar | Create dual-tab pattern

-   Overflow scope isolation — completion overflow modifies only the persisted CalendarDay, never the default 7-day SlotCapacity pattern

-   Intentional Technique Block granularity asymmetry — Technique drills rank at Skill Area level, scored drills at Subskill level, by design

-   Per-user random seed — Random mode seed is user-salted to ensure per-user uniqueness while preserving audit reproducibility

End of Section 8 — Practice Planning Layer (8v.a8 Consolidated)

