Section 10 — Settings & Configuration

Version 10v.a5 — Canonical

This document defines the canonical Settings & Configuration model for ZX Golf App. It is fully harmonised with Sections 1–9, Section 11 (11v.a5), Section 13 (13v.a6), Section 14 (14v.a4), Section 16 (16v.a5) and encodes all configuration decisions agreed in the specification process. All scoring architecture remains system-governed unless explicitly stated otherwise.

10.1 Configuration Scope

All settings are strictly per-user. There are no device-level overrides, no global presets, no onboarding modes (Beginner / Elite), and no environment-dependent configuration. The user profile is the single configuration authority.

Each user configures a home timezone. This governs CalendarDay boundaries, Completion Matching date logic, and Plan Adherence rollup boundaries.

10.2 Scoring Governance (System-Governed)

The following structural components are permanently system-governed and are not user-editable:

-   Skill Area allocations (total = 1000 points)

-   Subskill allocations within each Skill Area

-   Pressure / Transition weighting (65% / 35%)

-   Subskill rolling window size (25 occupancy units per window)

-   Window mechanics and roll-off logic

-   Weakness Detection algorithm and sensitivity

Metrics integrity detection (schema plausibility bounds, IntegrityFlag, IntegritySuppressed) is system-governed and not user-configurable. See Section 11.

These constraints preserve deterministic scoring, bounded reflow cost, and cross-user comparability.

10.3 Drill Library Management

State model:

-   Active

-   Retired

-   Deleted

No additional 'Hidden' visibility state exists.

No tagging or folder hierarchy is supported. Library remains flat and filter-driven. Permitted filters: Skill Area, Drill Type (Technique / Transition / Pressure), Subskill, and Scoring Mode (Shared / Multi-Output).

Drill duplication is supported for both System and User Custom drills:

-   Duplicating a System Drill creates a new User Custom Drill (new DrillID, Origin = UserCustom).

-   Duplicating a User Custom Drill creates a new User Custom Drill (new DrillID).

-   Structural identity fields remain immutable post-creation.

-   Anchors are copied and editable.

10.4 Anchor Governance

Validation rule:

-   Min < Scratch < Pro (strictly increasing).

No additional realism constraints are enforced.

Anchors are editable one drill at a time only.

Anchor edits are blocked while a Drill is in Retired state. The user must reactivate the Drill to Active before editing anchors.

All anchor edits trigger reflow (see 10.5 Confirmation Model).

10.5 Confirmation Model

Two confirmation tiers exist:

Soft confirmation (simple modal: “This action will recalculate your scores.” Confirm / Cancel):

-   Anchor edit

-   Post-close Instance edit

-   Session deletion

-   Drill deletion with scored data
    PracticeBlock deletion

No preview simulation. No impact estimation.

Strong confirmation (type-to-confirm):

-   Full account deletion (irreversible, destructive scope)

10.6 Units & Measurement Preferences

Distance Units:

-   User selects global preference: Yards or Metres.

-   All stored values are normalised internally.

-   Display and input respect user preference.

Small Length Units:

-   User selects global preference: Inches or Centimetres.

-   Display-layer only. No scoring impact.

Speed / Raw Metric Units:

-   Global default per metric type (e.g., mph).

-   Per-drill unit override allowed at drill creation.

-   Unit immutable post-creation.

-   Canonical internal storage ensures scoring stability.

10.7 Execution Defaults

Default Club Selection Mode is configurable per Skill Area:

-   Random

-   Guided

-   User Led

Applies only when 2+ eligible clubs exist.

On drill creation, ClubSelectionMode is pre-filled from the Skill Area default. User may override. ClubSelectionMode is immutable after drill creation.

Inactivity Timers:

-   PracticeBlock auto-end: 4 hours

-   Session inactivity auto-close: 2 hours (fixed system constant)

-   Not user-configurable

10.8 Calendar Defaults

System default SlotCapacity pattern: 5 per day.

User may modify 7-day default pattern at any time.

Changes apply only to future non-persisted CalendarDays.

No adaptive behaviour or automatic capacity adjustment.

10.9 Analytics Preferences

User may select default Analysis resolution:

-   Daily

-   Weekly

-   Monthly

Weekly remains system default until user changes preference.

User may configure week start day: Monday or Sunday. This governs weekly and monthly rollup boundaries in Plan Adherence and Analysis.

All analytics preferences are pure presentation-layer settings. No scoring impact.

Date range persistence (fixed system behaviour, not user-configurable): user-selected date range and resolution persist for 1 hour from last Analysis screen visit. After 1 hour of no access, Analysis resets to last 3 months at weekly resolution. Plan Adherence resets to last 4 weeks.

10.10 Notifications (Version 1 Scope)

-   Optional daily practice reminder.

-   User selects reminder time.

-   No reminder on rest days (SlotCapacity = 0).

-   No reminder if all Slots completed.

-   No streaks, weakness alerts, or scoring notifications in V1.

-   One reminder per day maximum.

-   Per-user toggle (On / Off).

Broader notification framework deferred to V2.

10.11 Account Controls

Data Export:

-   Full user-scoped export (JSON primary format). Export includes: Drills (User Custom and adopted references), Sessions, Sets, Instances (including RawMetrics and SelectedClub), Club configuration, Calendar entities, Routines and Schedules, and EventLog entries.

-   Optional CSV session summary export.

-   Snapshot at export time.

-   No re-import capability in V1.

Full Account Deletion:

-   Hard delete user record.

-   Cascade delete all related entities: Drills, Sessions, Instances, Calendar entities, Routines and Schedules, EventLog entries, and Club data.

-   Irreversible.

-   Requires strong confirmation (type-to-confirm; see 10.5 Confirmation Model).

Section 10 concludes the Settings & Configuration layer. All scoring mechanics remain system-governed. All settings are strictly per-user. User configuration is limited to unit preferences, execution defaults, calendar planning defaults, analytics resolution, minimal notifications, and account-level controls.

