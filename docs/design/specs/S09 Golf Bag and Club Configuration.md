Section 9 — Golf Bag & Club Configuration

Version 9v.a2 — Consolidated

This document defines the canonical Golf Bag & Club Configuration model. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 3 (User Journey Architecture 3v.g7), Section 4 (Drill Entry System 4v.g8), Section 6 (Data Model & Persistence Layer 6v.b7), and Section 8 (Practice Planning Layer 8v.a8).

9.1 Club Identity Model

Clubs are physical objects with unique identity. Each club in the user’s bag is a distinct entity. Multiple clubs of the same ClubType are permitted (e.g. two different SW models). There is no maximum bag size.

9.1.1 ClubType Enumeration

ClubType is a fixed system-defined enumeration. Users cannot create custom ClubTypes. The canonical list contains 36 types:

  ------------------------------------------------------------------------
  Category        Count       ClubTypes
  --------------- ----------- --------------------------------------------
  Driver          1           Driver

  Woods           9           W1, W2, W3, W4, W5, W6, W7, W8, W9

  Hybrids         9           H1, H2, H3, H4, H5, H6, H7, H8, H9

  Irons           9           i1, i2, i3, i4, i5, i6, i7, i8, i9

  Wedges          6           PW, AW, GW, SW, UW, LW

  Specialty       1           Chipper

  Putter          1           Putter
  ------------------------------------------------------------------------

Total: 36 ClubTypes.

9.1.2 UserClub Entity

Each club in the user’s bag is represented by a UserClub entity:

-   ClubID (UUID, PK)

-   UserID (FK)

-   ClubType (enum — from canonical list)

-   Make (optional — descriptive only)

-   Model (optional — descriptive only)

-   Loft (optional — analytics only)

-   Status (Active, Retired)

-   CreatedAt (UTC)

-   UpdatedAt (UTC)

Make, Model, and Loft are descriptive metadata only. They have no structural or scoring effect.

9.2 Skill Area Club Mappings

ClubType → Skill Area mappings determine which clubs are eligible for drills in each Skill Area. Mappings are user-configurable with mandatory minimums and system defaults.

9.2.1 Mapping Model

Each user maintains a set of ClubType → Skill Area assignments. A single ClubType may be assigned to multiple Skill Areas simultaneously (e.g. SW can be in Chipping, Pitching, and Bunkers). Mappings are stored per user and may be edited at any time.

9.2.2 Mandatory Mappings

The following mappings cannot be removed by the user:

-   Driver → Driving

-   Putter → Putting

-   i1–i9 → Irons (all Irons are mandatory in the Irons Skill Area)

These mappings are enforced at the system level. The user may add additional ClubTypes to these Skill Areas but cannot remove the mandatory ones.

9.2.3 Default Mappings

On bag creation (including quick-start preset), the following defaults are applied. Users may add or remove any non-mandatory mapping.

  -----------------------------------------------------------------------------------------
  Skill Area   Mandatory    Default (Modifiable)                      Notes
  ------------ ------------ ----------------------------------------- ---------------------
  Driving      Driver       Driver                                    None

  Irons        i1–i9        i1–i9                                     All Irons mandatory

  Putting      Putter       Putter                                    None

  Pitching     —            i9, PW, AW, GW, SW, LW                    All modifiable

  Chipping     —            i7, i8, i9, PW, AW, GW, SW, LW, Chipper   All modifiable

  Woods        —            W1–W9, H1–H9                              All modifiable

  Bunkers      —            i7, i8, i9, PW, AW, GW, SW, LW, Chipper   All modifiable
  -----------------------------------------------------------------------------------------

9.2.4 Multi-Area Assignment

A ClubType may be assigned to any number of Skill Areas. This reflects real-world practice — a SW is used for chipping, pitching, and bunker shots. The system does not enforce exclusivity.

9.3 Hard Gating Model

9.3.1 Scored Drill Requirement

For any scored drill (Transition or Pressure), the user must have configured at least one eligible club for that Skill Area before the drill may be:

-   Created (User Custom Drill)

-   Adopted (System Drill)

-   Added to a Routine

-   Added to a Schedule

-   Assigned to a Calendar Slot

-   Executed in a Session

Eligibility is determined dynamically: the user’s bag must contain at least one Active club whose ClubType is mapped to the target Skill Area.

9.3.2 Technique Block Exception

Technique Block drills:

-   Do not require configured clubs

-   Do not require SelectedClub

-   May be executed without Bag setup

-   Do not participate in window scoring

9.3.3 Gate on Club Retirement

If a user retires or removes a club that was the last eligible club for a Skill Area, the hard gate activates for that Skill Area. Existing drills, Routines, and Schedules referencing that Skill Area are not deleted — they remain but cannot be executed until a new eligible club is configured. No scoring data is affected.

9.4 Club Selection Mode

Club Selection Mode is a drill-level setting that governs how clubs are assigned per Instance. The setting is dynamic based on the user’s bag at Session start:

-   If 1 eligible club for the Skill Area: system auto-selects. Club Selection Mode is not displayed.

-   If 2+ eligible clubs for the Skill Area: Club Selection Mode is displayed. Three options:

-   Random — system selects from eligible clubs. User cannot override.

-   Guided — system suggests a club. User may override.

-   User Led — user selects the club for each Instance (default).

There are no hardcoded exceptions. Any Skill Area with multiple eligible clubs shows the selection mode. Any Skill Area with one eligible club auto-selects.

9.5 Club Performance Profiles (Time-Versioned)

Carry distance and dispersion are versioned performance characteristics stored separately from the UserClub entity. Entry is optional — users are not required to enter performance data. Club Carry and Percentage of Club Carry target modes remain greyed out until carry data is entered for the relevant clubs.

9.5.1 ClubPerformanceProfile Entity

-   ClubPerformanceProfileID (UUID, PK)

-   ClubID (FK)

-   EffectiveFromDate (UTC date)

-   CarryDistance (decimal)

-   DispersionLeft (optional, decimal)

-   DispersionRight (optional, decimal)

-   DispersionShort (optional, decimal)

-   DispersionLong (optional, decimal)

-   CreatedAt (UTC)

The active profile at any timestamp is the most recent profile with EffectiveFromDate ≤ timestamp.

9.5.2 Dispersion Model

Dispersion uses four independent asymmetric values: DispersionLeft, DispersionRight, DispersionShort, DispersionLong. This allows the user to express directional bias (e.g. misses further left than right). All four values are optional and independent. Dispersion data is analytics-only — it has no scoring or target resolution impact.

9.5.3 Bulk Performance Updates

Users may update carry and dispersion for individual clubs or the entire set in a single operation:

-   Creates new ClubPerformanceProfile rows with a new EffectiveFromDate

-   Preserves all historical profiles

-   No scoring impact

-   No reflow triggered

9.6 Target Resolution Behaviour

For grid-based drills using Club Carry or Percentage of Club Carry target modes, target resolution occurs at Instance creation time. The following values are snapshot-stored on the Instance:

-   ResolvedTargetDistance

-   ResolvedTargetWidth

-   ResolvedTargetDepth

Subsequent carry or dispersion edits do not alter historical Instances. The snapshot ensures scoring integrity — the user judged their shot against the target displayed at the time.

9.7 Club Lifecycle Governance

9.7.1 Retirement

-   A club may be retired at any time

-   If a club has any historical Instance references, it cannot be deleted and may only be retired

-   Retired clubs are hidden from new use (not offered for club selection in Sessions)

-   Historical Instances remain intact

-   No scoring impact

-   No reflow triggered

-   If the retired club was the last eligible club for a Skill Area, the hard gate activates for that area

9.7.2 Deletion

-   Hard deletion is permitted only if the club has no Instance references and no performance profiles

-   Deletion has no scoring impact and does not trigger reflow

-   If the deleted club was the last eligible club for a Skill Area, the hard gate activates for that area

9.7.3 Metadata Edits

Edits to Make, Model, and Loft are treated as if always true (no versioning). No scoring impact.

9.8 Bag Setup & Onboarding

9.8.1 Onboarding Flow

Bag setup is required during onboarding. The user is presented with a quick-start option: a standard 14-club preset that can be accepted immediately or customised before confirming.

9.8.2 Standard Preset

One system-defined preset containing 14 clubs:

  -----------------------------------------------------------------------
  Slot      Club
  --------- -------------------------------------------------------------
  1         Driver

  2         3W

  3         5W

  4         4i

  5         5i

  6         6i

  7         7i

  8         8i

  9         9i

  10        PW

  11        GW

  12        SW

  13        LW

  14        Putter
  -----------------------------------------------------------------------

On acceptance, default Skill Area mappings (§9.2.3) are applied automatically. The user may customise both the bag contents and the mappings after setup.

9.8.3 Post-Onboarding Editing

After initial setup, the user may at any time:

-   Add or remove clubs from their bag

-   Edit club metadata (Make, Model, Loft)

-   Enter or update performance profiles (carry, dispersion)

-   Add or remove ClubType → Skill Area mappings (subject to mandatory minimums)

-   Retire or reactivate clubs

9.9 Measurement Unit System

All measurable values are stored in canonical base units internally and displayed according to user settings.

9.9.1 Supported Unit Settings

-   Distance: Yards or Metres

-   Small Length: Inches or Centimetres

-   Speed (future-compatible): mph or km/h

-   Weight (future-compatible): grams or ounces

Unit changes do not mutate stored values, do not affect scoring, and do not trigger reflow. Conversion is display-layer only.

9.9.2 Canonical Base Units

-   Distance: Metres (internal)

-   Small Length: Centimetres (internal)

-   Speed: m/s (internal, future)

-   Weight: grams (internal, future)

9.10 Analytics Usage

Carry distance and dispersion may be used for:

-   Analytics overlays in Review

-   Target suggestions (future)

-   Gapping analysis (future)

-   Club comparison diagnostics (future)

They do not influence scoring, window mechanics, or weakness ranking. Equipment data is strictly separated from the scoring engine.

9.11 Data Model Additions

Section 9 introduces the following additions to the persistence layer defined in Section 6.

9.11.1 New Entities

UserClub

-   ClubID (UUID, PK)

-   UserID (FK)

-   ClubType (enum)

-   Make (optional string)

-   Model (optional string)

-   Loft (optional decimal)

-   Status (Active, Retired)

-   CreatedAt (UTC), UpdatedAt (UTC)

ClubPerformanceProfile

-   ClubPerformanceProfileID (UUID, PK)

-   ClubID (FK)

-   EffectiveFromDate (UTC date)

-   CarryDistance (decimal)

-   DispersionLeft (optional decimal)

-   DispersionRight (optional decimal)

-   DispersionShort (optional decimal)

-   DispersionLong (optional decimal)

-   CreatedAt (UTC)

UserSkillAreaClubMapping

-   MappingID (UUID, PK)

-   UserID (FK)

-   SkillArea (enum)

-   ClubType (enum)

-   IsMandatory (boolean — true for system-enforced mappings)

-   CreatedAt (UTC)

9.11.2 Instance Extension

The existing Instance entity (Section 6) stores SelectedClub (ClubID FK) and the following snapshot fields for grid-based drills:

-   ResolvedTargetDistance (decimal, nullable)

-   ResolvedTargetWidth (decimal, nullable)

-   ResolvedTargetDepth (decimal, nullable)

9.11.3 Referential Integrity

-   UserClub references UserID but is not owned by any Drill or Session

-   ClubPerformanceProfile references ClubID — deleted when parent UserClub is deleted

-   UserSkillAreaClubMapping references UserID, SkillArea, and ClubType

-   Instance.SelectedClub references ClubID. If a Club is retired, the reference is preserved (historical integrity). If a Club is deleted, the reference is preserved as a soft reference (ClubID remains but the entity is gone).

-   Deleting a UserClub is blocked if any Instance references it

9.11.4 Indexing

-   UserClub(UserID) — bag queries

-   ClubPerformanceProfile(ClubID, EffectiveFromDate) — active profile resolution

-   UserSkillAreaClubMapping(UserID, SkillArea) — eligible club lookups

9.11.5 No Scoring Impact

UserClub, ClubPerformanceProfile, and UserSkillAreaClubMapping entities have no relationship to the scoring engine beyond target resolution snapshotting. They do not trigger reflow, do not enter windows, and do not affect any derived scoring state.

9.12 Settings Additions

Section 9 introduces the following user-configurable settings:

-   Distance unit preference: Yards or Metres

-   Small length unit preference: Inches or Centimetres

-   Speed unit preference (future): mph or km/h

-   Weight unit preference (future): grams or ounces

9.13 Structural Guarantees

The Golf Bag & Club Configuration layer guarantees:

-   Deterministic Skill Area gating — dynamic, based on user’s bag and mappings

-   No historical reinterpretation of target geometry — targets snapshot at Instance time

-   No scoring mutation from equipment edits — carry/dispersion changes have zero scoring effect

-   Time-versioned performance characteristics — full history preserved

-   Snapshot target resolution per Instance — immutable after creation

-   Unlimited club count — no bag size maximum

-   Optional dispersion model — four-value asymmetric, analytics only

-   Canonical unit storage — display conversion only, no data mutation

-   No reflow triggers from Bag changes — strict separation between equipment data and scoring engine

-   User-configurable Skill Area mappings — mandatory minimums plus modifiable defaults

-   Multi-area club assignment — a single ClubType may belong to multiple Skill Areas

-   Dynamic Club Selection Mode — auto-select for single-club areas, mode choice for multi-club areas

End of Section 9 — Golf Bag & Club Configuration (9v.a2 Consolidated)

