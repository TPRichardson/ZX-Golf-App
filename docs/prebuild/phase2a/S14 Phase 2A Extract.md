S14 Drill Entry Screens — Phase 2A Extract
Sections: §14.1-14.6 (V1 Library Scope, Anchor Tables, Complete Drill Catalogue, Binary Hit/Miss, Anchor Governance)
============================================================

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

