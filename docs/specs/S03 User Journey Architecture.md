Section 3 — User Journey Architecture

Version 3v.g8 — Consolidated

This document defines the canonical User Journey Architecture. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 6 (Data Model 6v.b7), Section 8 (Practice Planning Layer 8v.a8), Section 10 (Settings & Configuration 10v.a5), Section 12 (UI/UX Structural Architecture 12v.a5), and the Canonical Definitions (0v.f1).

ZX Golf App priority order: 1. Tracker 2. Scorer 3. Planner

3.1 Core Object Hierarchy

The system is built on six structural layers: Drill → Routine → PracticeBlock → Session → Set → Instance

3.1.1 Drill

Permanent definition object containing:

-   Name

-   Skill Area

-   Subskill mapping (1 or 2 only)

-   Scoring anchors (Min / Scratch / Pro) — one set per mapped subskill

-   Scoring mode (Shared or Multi-Output)

-   Metric Schema (system-defined, immutable post-creation)

-   Available clubs (scored drills only)

-   RequiredSetCount (integer ≥1) — immutable post-creation

-   RequiredAttemptsPerSet (integer ≥1, or null for open-ended) — immutable post-creation

-   Drill Type (mandatory): Technique Block, Transition, or Pressure — immutable post-creation

Drill Type governs scoring interaction:

-   Technique Block: No scoring anchors, no subskill mapping, no window entry. Open-ended only (RequiredSetCount=1, RequiredAttemptsPerSet=null).

-   Transition: Session enters Transition window.

-   Pressure: Session enters Pressure window.

Scoring anchors, scoring mode, subskill mapping, and selected club are required for scored drills (Transition and Pressure) only.

Drill Definition Immutability

RequiredSetCount and RequiredAttemptsPerSet are immutable post-creation for all drills (System and User Custom). Changing volume structure requires creation of a new Drill. Anchor edits remain permitted for User Custom Drills and trigger full recalculation.

3.1.2 Routine

Blueprint object containing an ordered list of entries. Each entry is either a fixed Drill reference or a Generation Criterion (a parameterised instruction for the system to select a drill at application time; see Section 8). Instantiation creates a PracticeBlock and snapshots the entry list with all criteria resolved to specific DrillIDs. Template linkage is severed after creation. Editing a Routine does not affect existing PracticeBlocks.

A Routine references Drills (for fixed entries) but does not own them. Generation Criterion entries reference Skill Areas and Drill Types, not specific Drills, and are unaffected by individual drill lifecycle changes. Deleting a Routine has no effect on any Drill or its historical data.

Referential Integrity

If a Drill referenced by a Routine is deleted or retired, the Drill is automatically removed from the template. The template continues to function with its remaining Drills.

If all Drills have been removed from a Routine (leaving it empty), the template is auto-deleted.

Retirement

Routines may be retired (hidden from new use but preserved) or deleted. Retirement and deletion of a Routine have no effect on any Drill, Session, or scoring data.

3.1.3 PracticeBlock

Execution container representing a real-world practice occurrence.

Created via: 1) Routine selection, 2) Manual drill selection, 3) System-generated build, or 4) Calendar-initiated practice (Section 8). When created from the Calendar, the PracticeBlock is built from the CalendarDay’s filled Slots in Slot order. Any unresolved Generation Criteria are resolved at this point.

Contains an ordered drill list, Sessions, start timestamp, and end timestamp.

Persisted only if at least one Session exists. If no Session is started, auto-deleted.

Closure

-   Manual: User presses End Practice.

-   Safeguard: Auto-end if no new Session started within 4 hours.

Precedence

1.  PracticeBlock cannot close while a Session is Active.

2.  If Session auto-closes, PracticeBlock timer becomes eligible again.

3.  Auto-end generates passive notification only.

3.1.4 Session

Runtime execution of a single Drill. Created only when user presses Start Drill.

Constraints

1.  Only one authoritative active Session per user.

2.  Activation is explicit.

3.  Termination is manual or inactivity-based.

4.  Structured drills: auto-close on final Instance of final Set.

5.  Unstructured drills: manual or inactivity-based termination only.

Completion Timestamp Authority

1.  Manual End (unstructured drills): Timestamp = exact moment user presses End Drill.

2.  Structured Completion: Timestamp = timestamp of final Instance of final Set.

3.  Auto-Close (inactivity): Timestamp = timestamp of last logged Instance.

4.  Server does not alter device-recorded completion timestamp.

Session Stores

1.  Completion timestamp (window ordering key)

2.  Sets (containing Instances)

3.  Derived drill score (simple average of all Instance 0–5 scores across all Sets; not persisted — see Section 6)

Window Entry

1.  Session is the atomic scored execution unit. Scored Sessions (Transition, Pressure) enter subskill windows. Technique Block Sessions do not enter windows, have no subskill mapping, and produce no 0–5 score.

2.  Occupancy = 1.0 if single subskill; 0.5 per subskill if dual-mapped.

3.  Placement determined solely by completion timestamp.

4.  Editing Instances does not alter timestamp or window position.

Session Integrity

Sessions reference the Drill definition active at creation time. No retrospective structural reinterpretation occurs because structure cannot change.

3.1.5 Set

Sequential attempt container within a Session. Sets are strictly sequential: Set N+1 cannot begin until Set N is complete. No interleaving or parallel Sets.

The drill definition determines Set structure via two fields: RequiredSetCount (how many Sets constitute a complete Session) and RequiredAttemptsPerSet (how many Instances complete each Set; null = open-ended).

Structured drill example (3 × 10): RequiredSetCount=3, RequiredAttemptsPerSet=10.

Unstructured drill: RequiredSetCount=1, RequiredAttemptsPerSet=null. Manual End required.

Set is not an independent scoring unit. Session score = mean of all Instance 0–5 scores across all Sets.

Incomplete structured Sessions (not all Sets/Instances completed) are discarded entirely. No partial saves.

3.1.6 Instance

Atomic logged attempt created within an active Set. Stores performance metric(s), timestamp, and derived 0–5 score.

Edits are allowed during active Session and after Session close, trigger recalculation, and do not change chronological ordering.

3.2 First-Time User Flow

1.  User lands on empty Dashboard.

2.  No forced onboarding.

3.  Context-aware prompts displayed.

Bag rule: If bag not configured, Technique Block only allowed.

Drill Library: Canonical drills preloaded; custom creation enabled.

Start Practice CTA visible immediately.

3.3 Returning User Flow

Home Dashboard is root state.

Home Dashboard layout (see Section 12 for full specification):

Top Section (Informational)

1.  Overall Score (0–1000).

2.  Today’s Slot Summary (filled/total with visual progress indicator).

Bottom Section (Action Zone)

1.  Start Today’s Practice — visible only when today’s CalendarDay has at least one filled Slot. Launches Live Practice pre-loaded with today’s planned Slots.

2.  Start Clean Practice — always visible. Launches Live Practice with an empty PracticeBlock.

If Session Active → auto-resume.

If PracticeBlock auto-ended → passive banner.

Settings accessible via gear icon in the top-right corner of Home Dashboard.

3.4 Session Lifecycle

Activation

Start Drill only. Duplicate taps ignored.

Termination — Structured Drills

Session auto-closes when final Instance of final Set is logged. If user attempts to end early, prompted to complete or discard. No partial saves.

Termination — Unstructured Drills

User presses End Drill to close Session manually.

Inactivity Safeguard

1.  2 hours with no new Instance → auto-close.

2.  If zero Instances → discarded.

3.  If structured drill and not all Sets complete → discarded (incomplete). Popup banner on next app open.

4.  If all Sets complete or unstructured drill with ≥1 Instance → saved and scored.

5.  Passive notification for all auto-close events.

Manual End Practice While Session Active

Prompt user. On confirmation: End Session, then close PracticeBlock.

Discard

Hard delete. All Sets and Instances removed. No scoring impact.

Closed Sessions may be hard deleted. Deletion triggers full recalculation.

Post-Session Summary

When Live Practice ends (PracticeBlock closes with at least one completed Session), a dedicated Post-Session Summary screen is displayed before the user returns to the application. This is a distinct application state, not a modal or toast.

The Post-Session Summary displays:

1.  Final 0–5 drill score(s) for each Session completed in the PracticeBlock.

2.  Impact on the 1000-point Overall Score (delta).

3.  Key session statistics (as defined by Section 4, §4.8 end-of-session feedback).

The user must tap Done to proceed. Tapping Done returns the user to the Home Dashboard. No automatic timeout or auto-dismiss. Scores displayed reflect the updated engine state (post-reflow if applicable).

Exit always routes to Home Dashboard, regardless of the surface that launched Live Practice. No navigation stack is restored. Practice is treated as a completed event. See Section 12 (§12.8) for full specification.

3.5 Concurrency Model

Single authoritative active Session.

If second device attempts to start: Warning displayed. On confirmation, previous Session is hard discarded (Instances deleted) and new Session becomes authoritative.

Server enforces last-write-wins. Displaced device returns to dashboard on sync. When both devices are offline, cross-device Session overlap is permitted and resolved chronologically on sync. Server-mediated conflict detection applies only when connectivity exists. See Section 17 (§17.4.7) for full cross-device concurrency rules.

3.6 Offline Behaviour

Offline supports: Start PracticeBlock, Start Session, Log Instances, End Session, and local scoring.

Sync model: Device completion timestamp is authoritative, stored in UTC for ordering. Server does not mutate completion time. Section 17 (Real-World Application Layer) is the canonical authority for offline capability, multi-device synchronisation, and the deterministic merge-and-rebuild model. Scoring does not require server connectivity.

3.7 State Model

Valid States

1.  Idle

2.  PracticeBlock Active

3.  Session Active

4.  Session Closed

5.  Post-Session Summary (displayed after PracticeBlock close, before return to Home)

6.  PracticeBlock Closed (Manual)

7.  PracticeBlock Auto-Closed

8.  Session Discarded

Invalid States

1.  Multiple active Sessions

2.  Session without PracticeBlock

3.  Instance without Set

4.  Set without Session

3.8 Deterministic Lifecycle Guarantee

Session validity, completion, and scoring remain fully derived from the Drill definition, raw Instances, and the canonical scoring model.

3.9 Structural Guarantees

1.  Deterministic runtime structure

2.  Strict chronological window ordering

3.  No hidden timestamp mutation

4.  Clear separation of intention vs execution

5.  Tracker-first UX priority

6.  Fully recalculable scoring impact

7.  Post-Session Summary displayed as a dedicated state after every completed practice

End of Section 3 — User Journey Architecture (3v.g8 Consolidated)

