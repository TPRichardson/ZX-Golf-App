Section 14 — Drill Entry Screens & System Drill Library

Version 14v.a4 — Consolidated

This document defines the canonical System Drill Library and Drill Entry Screen UI specification for ZX Golf App V1. It is fully harmonised with Section 0 (0v.f1), Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 4 (Drill Entry System 4v.g8), Section 6 (Data Model & Persistence Layer 6v.b7), Section 12 (UI/UX Structural Architecture 12v.a5), and Section 13 (Live Practice Workflow 13v.a6).

PART 1: SYSTEM DRILL LIBRARY

14.1 V1 Library Scope

The V1 System Drill Library provides minimum viable coverage of the canonical Skill Tree. The design principle is one straightforward drill per subskill for Transition, plus one Technique Block per Skill Area. Pressure drills are deferred to a future release.

V1 Totals

Technique Blocks: 7 (one per Skill Area)

Transition Drills: 21 (one or more per subskill)

Pressure Drills: 0 (deferred). The scoring engine and Pressure windows are fully operational from launch. Users may create User Custom Pressure drills from day one to populate Pressure windows. System Pressure drills are deferred to a future release.

Total: 28 System Drills

Subskill Coverage Note

The canonical Skill Tree contains 19 subskills across 7 Skill Areas: Irons (3: Distance Control, Direction Control, Shape Control), Driving (3: Distance Maximum, Direction Control, Shape Control), Putting (2: Distance Control, Direction Control), Pitching (3: Distance Control, Direction Control, Flight Control), Chipping (3: Distance Control, Direction Control, Flight Control), Woods (3: Distance Control, Direction Control, Shape Control), and Bunkers (2: Distance Control, Direction Control). The 21 Transition drill count reflects 19 subskills plus 2 additional Distance Maximum drills (Ball Speed and Club Head Speed) providing alternative measurement approaches for Driving’s Distance Maximum subskill.

14.2 Technique Blocks

One Technique Block per Skill Area. No scoring anchors. No subskill mapping. No window entry. Open-ended only (RequiredSetCount=1, RequiredAttemptsPerSet=null). These exist to allow users to log non-scored mechanical practice time. Technique Block Sessions record a single Instance with duration as the data field (see §14.10.8).

  -------------------------------------------------------------------------
  Drill Name            Skill Area      Drill Type         Set Structure
  --------------------- --------------- ------------------ ----------------
  Driving Technique     Driving         Technique Block    Open-ended

  Irons Technique       Irons           Technique Block    Open-ended

  Putting Technique     Putting         Technique Block    Open-ended

  Pitching Technique    Pitching        Technique Block    Open-ended

  Chipping Technique    Chipping        Technique Block    Open-ended

  Woods Technique       Woods           Technique Block    Open-ended

  Bunkers Technique     Bunkers         Technique Block    Open-ended
  -------------------------------------------------------------------------

14.3 Scored Transition Drills

All scored Transition drills share the following properties unless otherwise stated:

Drill Type: Transition

Scoring Mode: Shared

Subskill Mapping: Single subskill

Set Structure: 1 × 10 (RequiredSetCount=1, RequiredAttemptsPerSet=10)

Club Selection Mode: User Led

14.3.1 Direction Control (7 Drills)

Input Mode: 1×3 Grid (Left / Centre / Right). Scored metric = centre-column hit-rate percentage. Target distance provides setup context only; the scored dimension is direction.

  -----------------------------------------------------------------------------
  Skill Area   Target Distance   Target Width       Min      Scratch   Pro
  ------------ ----------------- ------------------ -------- --------- --------
  Driving      Club Carry        7% of Club Carry   30%      70%       90%

  Irons        Club Carry        7% of Club Carry   30%      70%       90%

  Woods        Club Carry        7% of Club Carry   30%      70%       90%

  Pitching     Club Carry        7% of Club Carry   30%      70%       90%

  Putting      Fixed 10ft        The hole           20%      60%       80%

  Chipping     Fixed 30ft        Fixed 3ft          30%      70%       90%

  Bunkers      Fixed 20ft        Fixed 10ft         10%      50%       70%
  -----------------------------------------------------------------------------

Note: Putting target width represents the hole diameter. The 1×3 grid centre column maps to ‘holed’ vs ‘missed left’ / ‘missed right’.

14.3.2 Distance Control (6 Drills)

Input Mode: 3×1 Grid (Long / Ideal / Short). Scored metric = ideal-row hit-rate percentage. Target distance provides setup context; the scored dimension is depth control.

  -----------------------------------------------------------------------------
  Skill Area   Target Distance   Target Depth       Min      Scratch   Pro
  ------------ ----------------- ------------------ -------- --------- --------
  Irons        Club Carry        4% of Club Carry   30%      70%       90%

  Woods        Club Carry        5% of Club Carry   30%      70%       90%

  Pitching     Club Carry        3% of Club Carry   30%      70%       90%

  Putting      Fixed 30ft        Fixed 4ft          20%      60%       80%

  Chipping     Fixed 30ft        Fixed 6ft          10%      50%       70%

  Bunkers      Fixed 30ft        Fixed 10ft         10%      40%       60%
  -----------------------------------------------------------------------------

14.3.3 Distance Maximum (3 Drills)

Three drills measuring raw output for Driving → Distance Maximum. Input Mode: Raw Data Entry. Auto-select Driver (mandatory Driving club).

  ------------------------------------------------------------------------------------
  Drill Name        Metric                      Unit     Min       Scratch   Pro
  ----------------- --------------------------- -------- --------- --------- ---------
  Carry Distance    Carry distance per shot     Yards    180       250       300

  Ball Speed        Ball speed off face         mph      130       155       170

  Club Head Speed   Club head speed at impact   mph      85        105       115
  ------------------------------------------------------------------------------------

14.3.4 Shape Control (3 Drills)

Input Mode: Binary Hit/Miss. The user declares their intended shot shape (draw or fade) at Session start. All 10 attempts target the same shape. Scored metric = hit-rate percentage. The Binary Hit/Miss input mode is defined in Section 4 (§4.3).

  --------------------------------------------------------------------------
  Skill Area    Input Mode         Min           Scratch       Pro
  ------------- ------------------ ------------- ------------- -------------
  Irons         Binary Hit/Miss    30%           70%           90%

  Driving       Binary Hit/Miss    30%           70%           90%

  Woods         Binary Hit/Miss    30%           70%           90%
  --------------------------------------------------------------------------

No target definition required. No grid displayed.

14.3.5 Flight Control (2 Drills)

Input Mode: Binary Hit/Miss. The user declares their intended trajectory (e.g. high or low) at Session start. All 10 attempts target the same trajectory. Scored metric = hit-rate percentage.

  --------------------------------------------------------------------------
  Skill Area    Input Mode         Min           Scratch       Pro
  ------------- ------------------ ------------- ------------- -------------
  Pitching      Binary Hit/Miss    30%           70%           90%

  Chipping      Binary Hit/Miss    30%           70%           90%
  --------------------------------------------------------------------------

No target definition required. No grid displayed.

14.4 Complete V1 Drill Catalogue

The following table lists all 28 System Drills in the V1 library.

  -----------------------------------------------------------------------------------------------------------
  #    Drill Name           Skill Area   Drill Type        Subskill            Input Mode        Structure
  ---- -------------------- ------------ ----------------- ------------------- ----------------- ------------
  1    Driving Technique    Driving      Technique Block   —                   Timer             Open-ended

  2    Irons Technique      Irons        Technique Block   —                   Timer             Open-ended

  3    Putting Technique    Putting      Technique Block   —                   Timer             Open-ended

  4    Pitching Technique   Pitching     Technique Block   —                   Timer             Open-ended

  5    Chipping Technique   Chipping     Technique Block   —                   Timer             Open-ended

  6    Woods Technique      Woods        Technique Block   —                   Timer             Open-ended

  7    Bunkers Technique    Bunkers      Technique Block   —                   Timer             Open-ended

  8    Driving Direction    Driving      Transition        Direction Control   1×3 Grid          1 × 10

  9    Irons Direction      Irons        Transition        Direction Control   1×3 Grid          1 × 10

  10   Woods Direction      Woods        Transition        Direction Control   1×3 Grid          1 × 10

  11   Pitching Direction   Pitching     Transition        Direction Control   1×3 Grid          1 × 10

  12   Putting Direction    Putting      Transition        Direction Control   1×3 Grid          1 × 10

  13   Chipping Direction   Chipping     Transition        Direction Control   1×3 Grid          1 × 10

  14   Bunkers Direction    Bunkers      Transition        Direction Control   1×3 Grid          1 × 10

  15   Irons Distance       Irons        Transition        Distance Control    3×1 Grid          1 × 10

  16   Woods Distance       Woods        Transition        Distance Control    3×1 Grid          1 × 10

  17   Pitching Distance    Pitching     Transition        Distance Control    3×1 Grid          1 × 10

  18   Putting Distance     Putting      Transition        Distance Control    3×1 Grid          1 × 10

  19   Chipping Distance    Chipping     Transition        Distance Control    3×1 Grid          1 × 10

  20   Bunkers Distance     Bunkers      Transition        Distance Control    3×1 Grid          1 × 10

  21   Driving Carry        Driving      Transition        Distance Maximum    Raw Data Entry    1 × 10

  22   Driving Ball Speed   Driving      Transition        Distance Maximum    Raw Data Entry    1 × 10

  23   Driving Club Speed   Driving      Transition        Distance Maximum    Raw Data Entry    1 × 10

  24   Irons Shape          Irons        Transition        Shape Control       Binary Hit/Miss   1 × 10

  25   Driving Shape        Driving      Transition        Shape Control       Binary Hit/Miss   1 × 10

  26   Woods Shape          Woods        Transition        Shape Control       Binary Hit/Miss   1 × 10

  27   Pitching Flight      Pitching     Transition        Flight Control      Binary Hit/Miss   1 × 10

  28   Chipping Flight      Chipping     Transition        Flight Control      Binary Hit/Miss   1 × 10
  -----------------------------------------------------------------------------------------------------------

14.5 Binary Hit/Miss Input Mode

V1 introduces Binary Hit/Miss as a fourth input mode in the Metric Schema framework. This input mode is required for Shape Control and Flight Control drills where the performance measure is whether the user achieved their declared intention.

Definition

The user is presented with two buttons: Hit and Miss. Each Instance records a single binary outcome. No spatial target, no grid, and no numeric value is involved.

Scored Metric

Hit-rate percentage = (number of Hits / total Instances) × 100. This percentage is run through the drill’s Min / Scratch / Pro anchors using standard linear interpolation to produce a 0–5 score. This is identical to the grid scoring metric.

User Declaration

At Session start, the user declares their intention (e.g. ‘draw’ or ‘fade’ for Shape Control; ‘high’ or ‘low’ for Flight Control). The declaration is stored on the Session as UserDeclaration (Section 6) for reference but has no scoring impact — only the Hit/Miss outcome per Instance is scored.

Schema Properties

Binary Hit/Miss schemas do not carry HardMinInput or HardMaxInput (Section 11). Inputs are discrete and validated by the binary enum, identical to Grid Cell Selection exclusion from integrity detection.

Cross-Section Impact

The introduction of Binary Hit/Miss requires updates to:

Section 0 (Canonical Definitions) — add Binary Hit/Miss to Input Modes.

Section 4 (Drill Entry System) — add Binary Hit/Miss to Input Modes and Scoring Adapters.

Section 6 (Data Model) — add BinaryHitMiss to InputMode enumeration; add UserDeclaration field to Session entity.

14.6 Anchor Governance

All anchors in the V1 System Drill Library are system-defined and immutable to users, consistent with the System Drill governance model defined in Section 4 (§4.1). Central anchor edits trigger full reflow (Section 7).

Users who wish to practise with different anchor thresholds may duplicate any System Drill to create a User Custom Drill with editable anchors.

PART 2: DRILL ENTRY SCREEN UI SPECIFICATION

14.7 Design Philosophy

The Drill Entry Screen is the primary execution interface within Live Practice (Section 13). It is designed for a practice ground context: potentially poor lighting, quick interactions between shots, and single-handed operation. Every design decision optimises for minimum taps to log an Instance.

14.7.1 Core Principles

Minimum-Click Submission. An Instance is saved as soon as the last required field is completed. For Grid Cell Selection and Binary Hit/Miss, a single tap on the grid cell or button saves the Instance immediately. For Raw Data Entry, the user enters a value and taps Submit. No separate confirmation step exists for any input mode.

80% Screen Takeover. When the user interacts with any input element (grid, club selector, numeric keypad), that element expands to occupy at least 80% of the reachable screen area. This ensures large, easily tappable targets in all conditions. The element collapses back to its default state after interaction completes.

Top-to-Bottom Flow. The screen is ordered so that informational and prerequisite fields (drill info, club selection) sit at the top, and the primary input action (grid, Hit/Miss buttons, numeric keypad) sits at the bottom. The user’s natural flow is: glance at info → confirm or change club → tap the input element → Instance saved.

Portrait Only. The Drill Entry Screen is portrait-orientation only. Landscape is not supported.

14.8 Screen Structure

The Drill Entry Screen consists of the following zones, ordered top to bottom:

14.8.1 Title Bar

Persistent header displaying:

Drill name and Skill Area.

Set and Instance progress (e.g. “Set 1/3 — Attempt 4/10” for structured drills; running Instance count for unstructured drills).

Resolved target information (e.g. “150yd target”) for drills with target definitions.

User declaration reminder for Binary Hit/Miss drills (e.g. “Draw”).

14.8.2 Club Selector

Collapsed by default, displaying the currently selected club. Tapping the club selector expands it into large selectable buttons occupying the 80% screen takeover area. After selection, the element collapses back.

User Led Mode: Club selector is tappable. Expands to show all eligible clubs as large buttons.

Guided Mode: Club selector displays the system-suggested club. Tappable to expand and override. System suggestion is visually distinguished.

Random Mode: Club selector displays the system-selected club. Not tappable. No expansion. Visual indicator that the club was system-assigned.

For Skill Areas where only one club is eligible, the club is auto-selected and the selector is not displayed (Section 9, §9.4).

14.8.3 Primary Input Area

The primary input area occupies the lower portion of the screen. Its content depends on the drill’s input mode. On interaction, the input area expands to 80% screen takeover. Specific layouts per input mode are defined in §14.9.

14.8.4 Instance List

A scrollable list of submitted Instances within the current Set, displayed below the title bar when not in 80% takeover mode. Shows each Instance’s result (grid cell, Hit/Miss, or numeric value) and the club used. Tapping an Instance allows inline editing to correct fat-finger errors. During an active Session, edits are pre-scoring and do not trigger reflow (Section 4, §4.6).

14.9 Input Mode Layouts

14.9.1 Grid Cell Selection (1×3 and 3×1)

The grid is rendered at the bottom of the screen as large, labelled tap targets.

1×3 Grid (Direction): Three cells arranged horizontally: Left, Centre, Right. Centre cell represents the target.

3×1 Grid (Distance): Three cells arranged vertically: Long, Ideal, Short. Ideal cell represents the target.

3×3 Grid (Multi-Output, future): Nine cells in a 3×3 matrix. Centre cell is the target.

Target Integration: Resolved target dimensions are displayed integrated into the grid itself. Width dimensions label the horizontal edges; depth dimensions label the vertical edges. Target distance is shown above the grid. This presents the grid as a visual target diagram rather than abstract buttons.

Cell Colours: Grid cells use the system hit colour for target cells (Centre, Ideal) and the system miss colour for non-target cells. These colours are defined in Section 15 (Branding & Design System) and are used consistently across all grid views, Binary Hit/Miss buttons, and diagnostic visualisations.

Tapping a cell saves the Instance immediately (minimum-click principle). The tapped cell receives a brief visual flash and the device vibrates as confirmation.

14.9.2 Binary Hit/Miss

Two large buttons arranged side by side at the bottom of the screen. Hit on the left, Miss on the right. Buttons use the system hit colour (Hit) and system miss colour (Miss), consistent with grid cell colouring.

Tapping either button saves the Instance immediately. Confirmation via vibration.

The user’s declared intention (e.g. “Draw”, “High”) is displayed in the title bar as a persistent reminder throughout the Session.

14.9.3 Raw Data Entry

A custom large-button numeric keypad is rendered at the bottom of the screen, styled like a calculator. The keypad includes digits 0–9, decimal point, backspace, and an action button.

Action Button Behaviour

Submit (primary): Displayed when the numeric field is the last piece of information required. Tapping Submit saves the value and creates the Instance in one action.

Save (secondary, smaller): A secondary button that saves the current field value without submitting the Instance. This allows the user to move to another field (e.g. change club) before submitting. Always visible alongside the primary action button.

The numeric input field displays the unit label (e.g. “yards”, “mph”) as defined by the Metric Schema. HardMinInput and HardMaxInput plausibility bounds are enforced at submission time (Section 11).

14.9.4 Continuous Measurement (Deferred — Structural Stub)

Continuous Measurement drills are not included in the V1 System Drill Library. However, the input mode is defined in the Metric Schema framework (Section 4, §4.3) and User Custom Drills may use it from launch. The UI specification for Continuous Measurement is structurally equivalent to Raw Data Entry (§14.9.3): a custom large-button numeric keypad with the same Submit/Save button hierarchy and the same 80% screen takeover behaviour. The key distinction is contextual: Continuous Measurement drills have a spatial target reference (e.g. distance in yards to a defined point), whereas Raw Data Entry drills measure an output with no spatial reference (e.g. swing speed). The input field, keypad, and submission flow are identical. When System Drills using Continuous Measurement are introduced in a future version, any additional UI requirements (e.g. target context display) will be specified at that time.

14.9.5 Technique Block (Timer)

Technique Block drills use a dedicated timer interface. One Instance per Session. The timer records duration as the data field.

Timer Controls: Start / Stop button. The timer runs in the background when the phone is pocketed. On return, the user sees the elapsed duration.

Manual Override: After stopping the timer, the user may edit the recorded duration (e.g. if they left the timer running too long or forgot to start it). The override value replaces the timer value.

Session Close: The user presses End Drill to close the Session. The single Instance with the duration value is persisted. No scoring occurs. No window entry.

14.10 Interaction Behaviours

14.10.1 Shot Confirmation Feedback

After an Instance is saved (grid tap, Hit/Miss tap, or Submit on numeric entry):

The device vibrates briefly (haptic feedback).

For grid drills: the tapped cell receives a brief colour flash.

For Binary Hit/Miss: the tapped button receives a brief colour flash.

The Instance appears immediately in the Instance list.

No sound is played on standard shot confirmation. Sound is reserved for achievement banners (§14.10.3).

14.10.2 Undo Last Instance

A dedicated Undo action is available immediately after an Instance is saved. This provides a quick correction path for accidental taps without requiring the user to scroll the Instance list and edit.

Undo removes the most recently saved Instance from the current Set. The undo action is available until the next Instance is saved or the user navigates away. After undo, the Instance count decrements and the Instance is removed from the list.

During an active Session, undo is a pre-scoring operation and does not trigger reflow.

14.10.3 Achievement Banners

Positive reinforcement moments are delivered as transient banner notifications at the top of the screen, accompanied by a positive “ping” sound. Banners are display-only celebrations and have no effect on scoring mechanics.

Trigger candidates (V1):

Best streak — consecutive hits in a grid or Binary Hit/Miss drill within the current Session.

Best set score — highest hit-rate in a completed Set (multi-Set structured drills).

Personal best Session score — highest 0–5 Session score achieved for this Drill.

Banners auto-dismiss after a brief display period. They do not interrupt the input flow or block the next Instance entry.

14.10.4 Set Transition (Structured Drills)

When a structured drill completes a Set (final Instance of Set N logged), the UI automatically advances to Set N+1. A brief interstitial indicates the Set transition (e.g. “Set 1 Complete — Starting Set 2”). The title bar updates the Set counter. No user action is required to advance between Sets.

When the final Instance of the final Set is logged, the Session auto-closes per Section 3 (§3.4) and the user returns to the queue view.

14.10.5 Bulk Entry

Bulk entry is accessed via a tab toggle at the top of the primary input area. Two tabs: Single (default) and Bulk.

Switching to Bulk presents a modified interface appropriate to the input mode:

Grid drills: counter per cell. The user taps cells to increment counts, then submits the batch.

Binary Hit/Miss: numeric entry for total Hits and total Misses, then submit.

Raw Data Entry: multi-row numeric input, one row per Instance, then submit batch.

Bulk entry rules follow Section 4 (§4.6): applies to active Set only, cannot exceed remaining Set capacity for structured drills, unlimited for unstructured drills. Each bulk entry generates individual Instance records with sequential micro-offset timestamps. All Instances in a bulk batch use the same SelectedClub.

14.10.6 End, Discard, and Restart Controls

Session lifecycle controls are placed in a secondary menu (e.g. overflow/ellipsis menu) to prevent accidental activation. The secondary menu contains:

End Drill: Available for unstructured drills. Closes the Session manually. Structured drills auto-close on final Instance and do not display this option.

Restart: Discards the current Session and resets the PracticeEntry to PendingDrill. The user may then start the same drill again with a fresh Session (Section 13, §13.5.4).

Discard: Hard-deletes the current Session, all Sets, and all Instances. No scoring impact. Returns to the queue view (Section 13, §13.5.5).

Restart and Discard require a confirmation prompt before execution to prevent accidental data loss.

14.10.7 80% Screen Takeover Behaviour

When the user taps an interactive element (grid, club selector, numeric keypad, bulk entry), that element expands to occupy at least 80% of the reachable screen area. During takeover:

The title bar remains visible but is compressed.

The Instance list is hidden.

Other input elements are hidden or pushed off-screen.

Only the active element and its controls are interactive.

The takeover collapses automatically after the interaction completes (e.g. grid cell tapped, club selected, numeric value submitted). No explicit dismiss action is required.

14.10.8 Session Duration Tracking

Duration is tracked on all Sessions regardless of drill type:

Technique Block: Duration is the primary data field. Captured via user-facing start/stop timer with manual override. Stored as the Instance’s raw metric value. One Instance per Session.

Transition and Pressure: Duration is tracked passively in the background. Calculated as the elapsed time from the first Instance’s timestamp to the last Instance’s timestamp within the Session. No user interaction required. Stored on the Session entity for analytics purposes. Does not affect scoring.

Duration data is available in Review (Section 5) for time-based practice analysis.

14.11 Future Scope

The following are explicitly deferred from V1:

Pressure drills for all subskills. Behavioural note for future implementation: Pressure versions of Binary Hit/Miss drills (Shape Control, Flight Control) should randomise the declared intention per attempt (e.g. alternating draw/fade calls) rather than allowing the user to repeat the same shape for all attempts. This randomisation is the defining distinction between Transition (same intention ×10) and Pressure (randomised intention) for these drill types. The randomisation algorithm and UI presentation will be specified when Pressure drills are implemented.

Multi-Output drills (3×3 Grid producing independent Direction and Distance scores).

Continuous Measurement System Drills. The input mode is available for User Custom Drills from launch, and the UI specification is provided as a structural stub (§14.9.4). System Drills using Continuous Measurement will be introduced in a future version.

Achievement banner trigger list finalisation and tuning.

Actual colour values for system hit/miss colours (deferred to Section 15, Branding & Design System).

These will be addressed in subsequent versions of this document or in dedicated specification documents.

14.12 Data Model Additions

Section 14 introduces the following additions to the persistence layer defined in Section 6:

Session Entity Extension

SessionDuration (integer, nullable) — elapsed time in seconds from first Instance timestamp to last Instance timestamp. Derived for Transition and Pressure drills. Primary data for Technique Block drills. No scoring impact. Not a reflow trigger.

Technique Block Instance

Technique Block Instances store duration (in seconds) as their raw metric value via a Raw Data Entry (time) Metric Schema. The schema defines duration as the single metric field with HardMinInput = 0 and HardMaxInput = 43200 (12 hours). Duration values are subject to integrity detection (Section 11) due to manual override capability. No anchors, no 0–5 score, no window entry.

14.13 Structural Guarantees

The V1 System Drill Library and Drill Entry Screen guarantee:

Complete subskill coverage — every subskill has at least one Transition drill.

Technique Block coverage — every Skill Area has one non-scored practice drill.

Consistent set structure — all scored drills use 1 × 10.

Deterministic scoring — all drills use strict linear interpolation against defined anchors.

No cross-area mapping — every drill maps to exactly one subskill within one Skill Area.

System immutability — all structural fields and anchors are immutable to users.

Minimum-click execution — Instance saved on final required field completion.

Practice-ground optimised — 80% screen takeover, large tap targets, portrait only.

Consistent visual language — system hit/miss colours used across all input modes and diagnostics.

Duration tracking on all Sessions — user-facing for Technique Blocks, passive for scored drills.

Achievement feedback — positive banners with sound, no scoring impact.

End of Section 14 — Drill Entry Screens & System Drill Library (14v.a4 Consolidated)

