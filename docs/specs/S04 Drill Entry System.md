Section 4 — Drill Entry System

Version 4v.g9 — Consolidated

This document defines the canonical Drill Entry System. It is fully harmonised with Section 1 (1v.g2), Section 2 (2v.f1), Section 3 (3v.g8), Section 6 (6v.b7), Section 7 (7v.b9), Section 10 (10v.a5), the Canonical Definitions (0v.f1), Section 11 (11v.a5), and Section 14 (14v.a4).

4.1 Drill Definition Schema

Drills exist in two layers: 1) System Master Library (immutable, centrally governed), and 2) User Practice Pool.

Drill Mutability Rules

The following fields are immutable post-creation for all drills (System and User Custom):

• Subskill mapping

• Metric Schema

• Drill Type

• RequiredSetCount

• RequiredAttemptsPerSet

• Club Selection Mode

• Target Definition (grid-based drills only)

Changing any of the above requires creation of a new Drill.

System Drills

Live reference to central definition. The following are immutable to users:

• Anchors

• Drill Type

• Subskill mapping

• Metric Schema

• RequiredSetCount

• RequiredAttemptsPerSet

• Club Selection Mode

• Target Definition (grid-based drills only)

Central edits trigger full reflow.

Adopt/Unadopt Model

Users adopt System drills into their Practice Pool to make them available for Sessions and Routines. Users may unadopt a System drill at any time. On unadopt, the user is prompted: keep or delete historical Session data.

If KEEP:

• Drill hidden from active library (Retired state)

• Historical Sessions and scoring data retained

• Drill identity preserved

• Re-adoption reconnects historical Sessions automatically

If DELETE:

• Drill removed permanently

• All Sessions deleted

• All Instances deleted

• Full recalculation triggered

• Irreversible action

User Custom Drills

User-created drills with the following rules:

• Must select Skill Area (fixed to canonical Skill Areas)

• Must select Metric Schema (system-defined only)

• Must define anchors (Min / Scratch / Pro) — scored drills only; one set per mapped subskill

• Must define Drill Type (Technique Block, Transition, Pressure)

• Subskill mapping (1 or 2 subskills) limited to the chosen Skill Area. Dual-mapped drills must map to two subskills within the same Skill Area. Cross-Skill-Area subskill mapping is prohibited.

• May define RequiredSetCount (integer ≥1, default 1) and RequiredAttemptsPerSet (integer ≥1 or null)

• Technique Block drills are open-ended only (RequiredSetCount=1, RequiredAttemptsPerSet=null)

• Must define Target Definition for grid-based drills (see Section 4.4)

• Must set Club Selection Mode for multi-club Skill Areas (see Section 4.5)

Drill Duplication

Users may duplicate any existing drill (System or User Custom) to create a new User Custom Drill. The duplicate receives a new DrillID with Origin = UserCustom. All structural fields are copied: Skill Area, Subskill mapping, Metric Schema, Drill Type, Scoring Mode, Set structure, Target Definition, and Club Selection Mode. Anchors are copied and editable. Structural identity fields remain immutable post-creation as per standard User Custom Drill rules.

Anchor Governance

System Drill anchors are immutable to users. User Custom Drill anchors are editable and trigger full historical recalculation.

Anchor edits are blocked while a Drill is in Retired state. The user must reactivate the Drill (return to Active state) before editing anchors. This prevents reflow on historical data for drills the user has stepped away from.

User Custom Drill Retirement and Deletion

If a user removes a custom drill from their Practice Pool, the system prompts: “Delete all session data?”

If YES (Delete):

• Drill removed permanently

• All Sessions deleted

• All Instances deleted

• Full recalculation triggered

• Irreversible action

If NO (Retire):

• Drill marked Retired

• Hidden from library

• No new Sessions allowed

• Historical Sessions and scoring data fully retained

• Remains in historical windows, rolls off naturally

• Cannot be manually purged from scoring

Deletion Model

Drill deletion is irreversible at application layer. Soft delete at persistence layer ensures audit safety.

4.2 Drill Skill Areas

Skill Areas are fixed to the canonical set: Driving, Irons, Putting, Pitching, Chipping, Woods, Bunkers.

Skill Area determines eligible clubs and eligible subskills. Cross-Skill-Area mapping prohibited.

Eligible clubs per Skill Area are filtered from the user’s configured bag at Session start.

4.3 Input Modes & Metric Schema Framework

Metric schemas are system-defined only. Users cannot create custom schemas.

Each schema defines: input mode, required fields, valid value ranges, validation rules, and scoring adapter binding.

Schema is immutable once drill is created.

Input Modes

Each Metric Schema uses one of four input modes:

Grid Cell Selection

User taps which cell the shot landed in. The Instance entry screen displays the resolved target (distance, box dimensions) for the selected club so the user can accurately judge which cell to select.

Grid types: 3×3 (Multi-Output), 1×3 (direction only, Shared), 3×1 (distance only, Shared).

Continuous Measurement

User enters a numeric value (e.g. distance in yards, deviation in metres). Scored directly via anchor interpolation.

Raw Data Entry

User enters a numeric value with no spatial target (e.g. swing speed in mph). Scored directly via anchor interpolation.

Binary Hit/Miss

User taps Hit or Miss. Used for drills where the performance measure is whether the user achieved their declared intention (e.g. intended shot shape for Shape Control, intended trajectory for Flight Control). Scored metric = hit-rate percentage = (number of Hits / total Instances) × 100. This percentage is run through the drill's Min / Scratch / Pro anchors using standard linear interpolation. No spatial target, no grid, and no numeric value is involved. At Session start, the user declares their intention (e.g. 'draw' or 'fade'); the declaration is stored on the Session for reference but has no scoring impact. Binary Hit/Miss schemas do not carry HardMinInput or HardMaxInput and are excluded from integrity detection (Section 11), identical to Grid Cell Selection.

Grid Scoring Model

3×3 Grid (Multi-Output)

Nine cells. The center box is the target. Two independent scores produced:

• Direction subskill: Center column (top-center, center, bottom-center) = hit. Left and right columns = miss.

• Distance subskill: Middle row (left-ideal, center, right-ideal) = hit. Top row (long) and bottom row (short) = miss.

Center cell = hit for both. Edge-center cells = hit for one, miss for the other. Corners = miss for both.

1×3 Grid (Direction Only)

Three cells: Left, Center, Right. Center = hit.

3×1 Grid (Distance Only)

Three cells: Long, Ideal, Short. Ideal = hit.

Scoring Metric

For all grid types: scored metric = hit-rate percentage = (hits / total Instances) × 100. This percentage is run through the drill’s Min / Scratch / Pro anchors using standard linear interpolation.

For 3×3 Multi-Output: each subskill’s hit-rate is calculated independently and scored against its own anchor set.

Multi-Output Model (Non-Grid)

One drill execution captures data that produces two independent performance metrics (e.g. lateral deviation for Direction Control, depth deviation for Distance Control). Each subskill has its own independent anchor set. Strict linear interpolation applies. Occupancy = 0.5 per subskill.

4.4 Target Definition

Required for all grid-based drills. Defines the physical meaning of the center box shown to the user on the Instance entry screen.

Target Distance

How far away the target is. Three modes available at drill creation:

• Fixed: A set value (e.g. 150 yards) regardless of club.

• Club Carry: Uses the selected club’s carry distance from the user’s bag configuration.

• Percentage of Club Carry: A defined percentage of the selected club’s carry distance (e.g. 80%).

Club Carry and Percentage of Club Carry modes require the user to have entered carry distances for their eligible clubs. These modes are greyed out at drill creation until the required data is complete. See Section 9 (Golf Bag & Club Configuration) for full bag setup specification.

Target Size

The dimensions of the center box. Two modes available at drill creation:

• Fixed: Set dimensions in metres or yards (e.g. 10m wide, 15m deep).

• Percentage of Target Distance: Dimensions defined as a percentage of the resolved target distance (e.g. width = 7% of target distance).

Dimension Requirements by Grid Type

• 3×3 Grid: Width and depth required.

• 1×3 Grid (direction only): Width only.

• 3×1 Grid (distance only): Depth only.

Scaling Behaviour

The target box size scales by club (via the resolved target distance) but does not scale by anchor level. One target box is resolved and displayed per Instance based on that Instance’s selected club.

Anchors for grid-based drills are always hit-rate percentages against the defined target box. The difficulty scaling between Min, Scratch, and Pro is expressed through the hit-rate thresholds, not through changes to the box size.

Target Definition fields (Target Distance Mode, Target Distance Value, Target Size Mode, Target Size Width, Target Size Depth) are immutable post-creation. Changing target geometry requires creation of a new Drill. Historical Instances retain their snapshot target values regardless of any drill-level changes.

4.5 Club Selection

SelectedClub on Instance

The club used for each shot is stored on the Instance entity. Every Instance records a SelectedClub, even when the club does not change between shots. SelectedClub determines the resolved target distance and target box size displayed for that Instance.

The Drill definition no longer stores a fixed SelectedClub. Eligible clubs are derived from the Drill’s Skill Area filtered against the user’s bag.

Club Selection Mode

A drill-level setting that governs how clubs are assigned per Instance. Applicable to drills in Skill Areas where the user has configured two or more eligible clubs.

• Random: System selects from eligible clubs. User cannot override.

• Guided: System suggests a club. User may override.

• User Led: User selects the club for each Instance. This is the default.

For Skill Areas where the user has configured only one eligible club, the system auto-selects and this setting is not displayed. Eligible clubs are determined by the user’s Skill Area Club Mappings (Section 9).

4.6 Instance Entry Model

Default

One-shot entry. For grid-based drills, the user sees the resolved target (distance, box dimensions for the selected club) then taps the cell.

Bulk Entry

• Applies only to the active Set

• Cannot exceed remaining capacity of current Set (structured drills)

• No overflow into next Set

• Hard validation block if overflow attempted

• Unlimited for unstructured drills (RequiredAttemptsPerSet=null)

• Generates individual Instance records

• Assigns sequential micro-offset timestamps

• Maintains deterministic ordering

• For bulk entry, each Instance in the batch uses the same SelectedClub (the club active at time of bulk entry)

Validation

• Hard blocking of invalid values

• All required fields mandatory (including SelectedClub)

• No partial Instance saves

• No silent correction

Instance Edits (During Active Session)

Instances may be edited and deleted freely during an active Session. These changes are pre-scoring and do not trigger reflow. Edits do not change chronological ordering. SelectedClub may be edited on an Instance (e.g. if logged incorrectly).

Post-Close Editing Rules (Structured Drills)

Structured drills (RequiredSetCount ≥1 and RequiredAttemptsPerSet ≥1):

• Instance value may be edited (grid cell selection or metric value). Triggers reflow.

• Individual Instance deletion is prohibited. Removing an Instance would leave a Set with fewer than RequiredAttemptsPerSet, violating structural integrity.

• Individual Set deletion is prohibited. Removing a Set would leave a Session with fewer than RequiredSetCount, violating structural integrity.

• The entire Session may be deleted. Triggers reflow.

Post-Close Editing Rules (Unstructured Drills)

Unstructured drills (RequiredSetCount=1 and RequiredAttemptsPerSet=null):

• Instance value may be edited. Triggers reflow.

• Individual Instances may be deleted. Triggers reflow.

• If the last remaining Instance is deleted, the Session is automatically discarded. Triggers reflow.

• The entire Session may be deleted. Triggers reflow.

All post-close edits and deletions follow the reflow pipeline defined in Section 7 (Reflow Governance System).

Schema Plausibility Bounds

Each Metric Schema using Continuous Measurement or Raw Data Entry input modes defines two additional system-level fields: HardMinInput (decimal) and HardMaxInput (decimal). These define the absolute plausibility range for raw metric values entered against the schema. Values outside this range are saved normally but trigger an integrity flag on the parent Session (see Section 11). Grid Cell Selection and Binary Hit/Miss schemas do not carry plausibility bounds.

HardMinInput and HardMaxInput are system-defined, immutable, not user-editable, not per-drill, and not per-user. They are not reflow triggers. Negativity is governed by HardMinInput: schemas permitting negative values define a negative HardMinInput.

Numeric Input Field Default

The UI default for all numeric input fields (Continuous Measurement and Raw Data Entry) is blank (displayed as a dash), not zero. A zero value must be intentionally entered by the user. The existing validation layer enforces that all required fields are completed before an Instance may be saved.

4.7 Scoring Adapters

All scoring adapters (scored drills only — Technique Block drills have no adapter):

• Use strict linear 0–5 interpolation model

• Minimum → 0

• Scratch → 3.5

• Pro → 5

• No nonlinear curves

• No sigmoid scaling

Input Mode Scoring

• Grid Cell Selection: Scored metric = hit-rate percentage. Anchors define Min/Scratch/Pro hit-rate thresholds.

• Continuous Measurement: Scored metric = the entered value. Anchors define Min/Scratch/Pro performance values.

• Raw Data Entry: Scored metric = the entered value. Anchors define Min/Scratch/Pro performance values.

• Binary Hit/Miss: Scored metric = hit-rate percentage. Anchors define Min/Scratch/Pro hit-rate thresholds. Identical scoring mechanic to Grid Cell Selection.

Session Score

Simple average of all Instance 0–5 scores across all Sets. No system-level minimum attempt threshold for scoring. Single Instance valid for scoring in unstructured drills.

Set and Session Completion Enforcement

• Sets are strictly sequential. Set N+1 cannot begin until Set N is complete.

• No interleaving. No parallel Sets.

• Structured drills: Session auto-closes when final Instance of final Set is logged.

• Incomplete structured Sessions cannot be saved. User must complete or discard.

• Unstructured drills: Session requires manual End Drill.

• Set structure does not affect scoring calculation; only Session closure eligibility.

4.8 Live Feedback & Preview Logic

During Active Session

• Show shot confirmation

• Show hit/miss vs target (grid drills: highlight the tapped cell)

• If structured drill: show Set and attempt progress (e.g. “Set 2/3 — Attempt 4/10”)

• Show resolved target for next Instance (distance, box dimensions for current club)

• Do not display per-shot 0–5

• Do not display running average

At Session End

• Display final 0–5 drill score

• Display impact on 1000-point overall score

• Do not expose window mechanics

4.9 Structural Guarantees

• Deterministic scoring behaviour

• Strict linear interpolation across all schemas and input modes

• No schema-level scoring deviation

• Immutable structural mappings post-creation

• No cross-area inflation

• Hard validation integrity

• Fully recalculable historical scoring

• SelectedClub recorded per Instance for full audit trail

End of Section 4 — Drill Entry System (4v.g9 Consolidated)

