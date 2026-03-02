Section 11 — Metrics Integrity & Safeguards

Version 11v.a5 — Consolidated

This document defines the canonical Metrics Integrity & Safeguards layer. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 4 (Drill Entry System 4v.g8), Section 5 (Review 5v.d6), Section 6 (Data Model & Persistence Layer 6v.b7), Section 7 (Reflow Governance System 7v.b9), Section 10 (Settings & Configuration 10v.a5), Section 14 (Drill Entry Screens & System Drill Library 14v.a4), and the Canonical Definitions (0v.f1).

11.1 Core Philosophy

The Metrics Integrity layer is strictly observational. It detects and surfaces potential input errors but never alters scoring engine behaviour. The scoring engine (Sections 1–7) remains mathematically pure and deterministic.

All safeguards:

-   Detect plausibility breaches

-   Flag affected Sessions

-   Surface indicators in the UI

-   Log events to the EventLog

No safeguard may:

-   Suppress, exclude, or down-weight window entries

-   Alter Instance scores or Session scores

-   Block window entry or roll-off

-   Trigger reflow

-   Freeze scoring

-   Require confirmation before window entry

-   Automatically adjust anchors or structural parameters

The system does not perform behavioural modelling, statistical anomaly detection, historical comparison, user-relative analysis, intent inference, or anti-gaming enforcement. Responsibility for score integrity sits with the user.

11.2 Scope & Purpose

The sole purpose of Section 11 is to catch obvious fat-finger input mistakes on numeric entry fields.

Detection operates at the Instance level only. The flag surfaces at the Session level.

Integrity safeguards apply only to Metric Schemas using the following input modes:

-   Continuous Measurement

-   Raw Data Entry

The following are excluded from integrity detection:

-   Grid Cell Selection schemas (3×3, 1×3, 3×1) — inputs are discrete and validated by the grid enum

  Binary Hit/Miss schemas — inputs are discrete (Hit or Miss) with no numeric value; identical exclusion rationale to Grid Cell Selection
  Technique Block duration schemas use Raw Data Entry (time) input mode and are included in integrity detection. Duration values are numeric and subject to fat-finger risk via manual override. HardMinInput = 0 (seconds), HardMaxInput = 43200 (seconds, equivalent to 12 hours).

-   Derived hit-rate percentages

-   Calculated 0–5 scores

-   Window averages, Subskill points, Skill Area scores, and Overall score

-   Any aggregated or derived metric

11.3 Schema Plausibility Bounds

11.3.1 Definition

Each numeric-entry Metric Schema defines two plausibility bound fields:

-   HardMinInput — the minimum value the schema considers plausible

-   HardMaxInput — the maximum value the schema considers plausible

These fields are:

-   System-defined

-   Immutable

-   Not user-editable

-   Not per-drill

-   Not per-user

-   Not reflow triggers

Negativity is governed entirely by HardMinInput. There is no separate AllowNegative flag. Schemas that permit negative values define a negative HardMinInput (e.g. lateral deviation: HardMinInput = –200). Schemas that prohibit negative values define HardMinInput ≥ 0.

11.3.2 Zero Value Handling

Zero is treated like any other numeric value. If zero falls within the HardMinInput/HardMaxInput range, it is valid and no flag is raised. No special-case zero logic exists.

The UI default for all numeric input fields is blank (dash), not zero. A zero value must be intentionally entered by the user. This is enforced at the UI layer (Section 4), not by the integrity system.

11.3.3 Illustrative Bounds

The following are representative examples. Actual values are defined per schema in the system configuration.

  ------------------------------------------------------------------------
  Schema                 HardMinInput    HardMaxInput    Unit
  ---------------------- --------------- --------------- -----------------
  Carry Distance         0               500             metres

  Lateral Deviation      –200            200             metres

  Depth Deviation        –200            200             metres

  Swing Speed            0               250             mph

  Putt Distance          0               100             metres
  ------------------------------------------------------------------------

11.4 Detection Model

11.4.1 Evaluation Trigger

Plausibility is evaluated at two points:

-   Instance save — immediately when an Instance is created during an active Session

-   Post-close Instance edit — immediately when an Instance value is edited after Session close

There is no deferred batch pass, no Session-close sweep, and no scheduled re-evaluation. Detection is purely event-driven.

11.4.2 Breach Condition

An Instance is in breach if its raw metric value falls outside the schema’s HardMinInput/HardMaxInput range:

-   RawMetric < HardMinInput → breach

-   RawMetric > HardMaxInput → breach

Values exactly equal to HardMinInput or HardMaxInput are not in breach.

11.4.3 Behaviour on Breach

When a breach is detected:

-   The Instance is saved normally

-   Session scoring proceeds normally

-   Window entry proceeds normally

-   No suppression, blocking, or recalculation deviation occurs

-   The parent Session receives IntegrityFlag = true

-   An EventLog entry of type IntegrityFlagRaised is written

11.5 Session-Level Flag

11.5.1 Aggregation Rule

IntegrityFlag is a simple boolean on the Session entity.

-   If ≥1 Instance in the Session is currently in breach → IntegrityFlag = true

-   If all Instances are within bounds → IntegrityFlag = false

There are no severity levels, no breach counts, and no graduated indicators. The flag is purely binary.

11.5.2 Auto-Resolution

IntegrityFlag is state-derived, not event-derived. It reflects the current data state of the Session’s Instances.

If a user edits a breaching Instance to a valid value, and no other Instances remain in breach, the flag automatically resolves to false. An EventLog entry of type IntegrityFlagAutoResolved is written.

No manual intervention is required for auto-resolution.

11.5.3 UI Indicator

When IntegrityFlag = true and IntegritySuppressed = false, a subtle warning icon is displayed at the Session level. The indicator appears in:

-   Session summary (drill history)

The indicator does not appear in:

-   SkillScore views

-   Overall or Skill Area score displays

-   Analysis trend charts

-   Window Detail View entries

The indicator carries no scoring connotation. It is a data-quality signal only.

11.6 Manual Clear & Suppression

11.6.1 Clear Action

The user may clear an integrity flag on any flagged Session. Clearing is an acknowledgement that the user has seen the flag and accepts the data as entered.

11.6.2 Suppression Model

On clear:

-   UI indicator is removed immediately

-   Session’s IntegritySuppressed field is set to true

-   IntegritySuppressed is persisted on the Session entity and survives app restarts

-   An EventLog entry of type IntegrityFlagCleared is written

Suppression rules:

-   Suppression remains active until any edit occurs to any Instance in that Session

-   On any Instance edit: IntegritySuppressed resets to false, full plausibility re-check runs, and if a breach still exists the flag reappears

-   Suppression does not survive structural recalculation (reflow)

-   Suppression has zero scoring impact

-   Suppression is per-Session, not global

-   Suppression does not block detection for new Instances added before Session close

11.6.3 Reflow Interaction with Suppression

IntegritySuppressed is UI-layer state only and does not survive any reflow event. When a reflow executes, IntegritySuppressed is reset to false on all Sessions affected by that reflow, regardless of whether the reflow was related to the integrity event. This means:

-   If a user suppresses a flag on Session A, and a subsequent anchor edit on an unrelated Drill triggers a reflow that touches Session A’s Subskill window, Session A’s IntegritySuppressed is cleared.

-   The IntegrityFlag is then re-evaluated against current Instance data. If the breach still exists, the UI indicator reappears.

-   This is consistent with the principle that suppression is a transient acknowledgement, not a permanent exemption.

Integrity changes themselves are not reflow triggers (§7.2). IntegritySuppressed is cleared only as a side-effect of reflows triggered by other structural changes.

11.6.4 Constraints

Clearing does not:

-   Alter detection logic

-   Remove historical EventLog records

-   Modify any Instance value

-   Affect scoring, windows, or derived state

-   Create a permanent exemption

11.7 Intentionally Omitted Subsections

The following subsections from the original project outline have been evaluated and are intentionally omitted from this specification. Each is architecturally incompatible with the passive, absolute-rule-based integrity model.

11.7.1 Spike Detection (Original 11.2)

Not implemented. True spike detection requires historical comparison, statistical baselines, or intra-session delta analysis — all of which are excluded from the integrity model. Any numeric value large enough to represent a fat-finger error is already captured by HardMinInput/HardMaxInput. No intra-session delta thresholds, no cross-session spike logic, and no additional detection mechanisms exist beyond schema plausibility bounds.

11.7.2 Minimum Attempt Thresholds (Original 11.3)

Not implemented. The scoring engine (Section 1, §1.6) explicitly guarantees that a single Instance is valid for scoring in unstructured drills. Structured drills enforce volume through RequiredSetCount and RequiredAttemptsPerSet (Section 4). No additional minimum attempt rules, low-volume warnings, quality thresholds, or attempt floors for window entry exist. The engine’s existing structural governance is sufficient.

11.7.3 Anti-Gaming Controls (Original 11.4)

Not implemented. The system does not attempt to detect intentional score manipulation. No behavioural pattern detection, no statistical anomaly detection, no cross-session comparison, no volatility analysis, no suppression logic, no score freezing, no recalibration, and no integrity penalties exist. If a user chooses to inflate their score intentionally, the system records what is entered and processes it deterministically. Responsibility for score integrity sits with the user.

11.7.4 Manual Override Flags (Original 11.5)

Not implemented. The only manual interaction within the integrity system is the clear action defined in §11.6. There is no manual flagging capability, no admin override layer, no force-flag, no force-clear persistence, no “mark as suspect” function, and no scoring exclusion mechanism.

11.8 EventLog Integration

Section 11 introduces three new event types that extend the canonical EventType enumeration defined in Section 7 (§7.9). The canonical EventType enumeration is defined exclusively in Section 7. Section 11 extends that enumeration but does not redefine it. Section 7 remains the single source of truth for the complete EventType list.

  -----------------------------------------------------------------------------------------------------------------------------------
  EventType                   Description
  --------------------------- -------------------------------------------------------------------------------------------------------
  IntegrityFlagRaised         Instance saved with raw metric outside schema plausibility bounds. Session IntegrityFlag set to true.

  IntegrityFlagCleared        User manually cleared an active integrity flag. Session IntegritySuppressed set to true.

  IntegrityFlagAutoResolved   All Instances in Session now within bounds following edit. Session IntegrityFlag set to false.
  -----------------------------------------------------------------------------------------------------------------------------------

Each EventLog entry includes: event type, timestamp (UTC), affected SessionID, affected InstanceID (for FlagRaised), UserID, and a metadata field containing the breaching value and applicable schema bounds.

11.9 Data Model Additions

Section 11 introduces the following additions to the persistence layer defined in Section 6.

11.9.1 Session Entity Extension

-   IntegrityFlag (boolean, default false) — true if ≥1 Instance currently breaches schema plausibility bounds

-   IntegritySuppressed (boolean, default false, persisted) — true if user has manually cleared the flag; resets to false on any Instance edit within the Session, and resets to false on any reflow affecting the Session

11.9.2 Metric Schema Extension

Each numeric-entry Metric Schema (Continuous Measurement and Raw Data Entry) defines:

-   HardMinInput (decimal) — minimum plausible value

-   HardMaxInput (decimal) — maximum plausible value

These fields are system-defined and immutable. They are not present on Grid Cell Selection or Binary Hit/Miss schemas.

11.9.3 No Scoring Impact

IntegrityFlag, IntegritySuppressed, HardMinInput, and HardMaxInput have no relationship to the scoring engine. They do not trigger reflow, do not enter windows, do not affect derived scoring state, and are not part of the materialised derived state model defined in Section 7 (§7.11). IntegritySuppressed is persisted UI-layer state only.

11.10 Cross-Section Impact

Section 11 requires the following updates to existing specification documents:

-   Section 0 (Canonical Definitions, 0v.e7) — add terms: IntegrityFlag, IntegritySuppressed, HardMinInput, HardMaxInput, IntegrityFlagRaised, IntegrityFlagCleared, IntegrityFlagAutoResolved

-   Section 4 (Drill Entry System, 4v.g6) — extend Metric Schema Framework (§4.3) to include HardMinInput and HardMaxInput as schema-level fields. Specify UI default for numeric input fields as blank (dash), not zero.

-   Section 6 (Data Model, 6v.b2) — add IntegrityFlag and IntegritySuppressed fields to Session entity. Add HardMinInput and HardMaxInput to Metric Schema definition. Explicitly note no scoring impact.

-   Section 7 (Reflow Governance, 7v.b8) — add three new EventTypes to canonical enumeration (§7.9). Add explicit “Not Reflow Triggers” entry for integrity flags.

-   Section 10 (Settings, 10v.a4) — add statement in Scoring Governance (§10.2) that integrity detection is system-governed and not user-configurable.

11.11 Structural Guarantees

The Metrics Integrity & Safeguards layer guarantees:

-   No scoring mutation — integrity flags have zero effect on Instance scores, Session scores, window averages, Subskill points, Skill Area scores, or Overall score

-   No reflow triggers — no integrity event triggers recalculation

-   No engine interference — window entry, roll-off, and all scoring mechanics proceed identically regardless of flag state

-   Deterministic detection — same raw metric and same schema bounds always produce the same flag result

-   State-derived flags — IntegrityFlag reflects current Instance data, not historical events

-   Automatic resolution — corrective edits resolve flags without manual intervention

-   Suppression cleared by reflow — IntegritySuppressed is reset on any reflow affecting the Session, preventing stale suppression state

-   Minimal state footprint — two boolean fields on Session, two decimal fields on schema

-   Full audit trail — all flag lifecycle events recorded in EventLog

-   Architectural isolation — complete separation from Sections 1–7 scoring mechanics

-   No behavioural modelling — no statistical, historical, adaptive, or intent-based detection

-   Canonical EventType authority deferred to Section 7 — Section 11 extends the enumeration but does not redefine it

End of Section 11 — Metrics Integrity & Safeguards (11v.a5 Consolidated)

