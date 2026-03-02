Section 12 — UI/UX Structural Architecture

Version 12v.a5 — Expanded & Consolidated

This document defines the canonical UI/UX structural architecture. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 3 (User Journey Architecture 3v.g7), Section 4 (Drill Entry System 4v.g8), Section 5 (Review 5v.d6), Section 6 (Data Model & Persistence Layer 6v.b7), Section 7 (Reflow Governance System 7v.b9), Section 8 (Practice Planning Layer 8v.a8), Section 9 (Golf Bag & Club Configuration 9v.a2), Section 10 (Settings & Configuration 10v.a5), Section 11 (Metrics Integrity & Safeguards 11v.a5), Section 15 (Branding & Design System 15v.a3), and the Canonical Definitions (0v.f1).

12.1 Architectural Philosophy

Section 12 defines the canonical UI/UX structural architecture of the application. This layer governs visual hierarchy, navigation state transitions, interaction rules, and cross-domain consistency. It does not alter scoring logic, window mechanics, or persistence behaviour defined in Sections 1–11.

The architecture follows five governing principles:

-   Practice-first prioritisation — execution is always frictionless.

-   Deterministic structure — UI behaviour mirrors backend rules without hidden overrides.

-   Cross-domain consistency — Plan, Track, and Review share symmetrical internal patterns.

-   State isolation — Live Practice is an immersive execution state, fully separated from the application shell.

-   Progressive density — information is layered from high-level to deep detail.

12.2 Top-Level Navigation Model

The application uses a three-domain bottom navigation model:

Plan | Track | Review

The application launches to a Home Dashboard. Home is not a bottom navigation tab; it is a persistent launch layer accessible via a top-left Home control from any tab. Tapping Home does not reset the current tab’s state; it overlays the Home surface. Returning to a tab restores the user’s previous position within that tab.

Settings is accessible via a gear icon in the top-right corner of the Home Dashboard. Settings is not visible from other tabs.

12.2.1 Live Practice State

Live Practice is not a tab. It is a full-screen immersive execution state. When Live Practice is active:

-   Bottom navigation is hidden completely.

-   Cross-tab navigation is disabled.

-   User must explicitly end practice to exit.

-   Ending practice routes to the Post-Session Summary screen (see §12.8), then to Home Dashboard.

12.2.2 Live Practice Entry Points

Live Practice may be launched from the following surfaces:

-   Home Dashboard — Start Today’s Practice or Start Clean Practice (primary entry point).

-   Track — Start action on any Drill or Routine.

-   Plan → Calendar — Start Practice from a CalendarDay or Slot.

-   Plan → Create — Save & Practice action after creating a new Drill.

-   Any Drill detail page — Practice This Drill action.

All entry points create a new PracticeBlock and enter Live Practice in the same immersive state regardless of origin.

12.3 Home Dashboard

Home is execution-oriented. Information appears at the top. Actions appear at the bottom to align with thumb-zone ergonomics on mobile.

12.3.1 Top Section — Informational

4.  Overall Score (0–1000 scale).

5.  Today’s Slot Summary: filled count / total SlotCapacity with a visual progress indicator.

12.3.2 Bottom Section — Action Zone

The action zone contains up to two buttons depending on context:

Start Today’s Practice: Visible only when today’s CalendarDay has at least one filled Slot. Launches Live Practice pre-loaded with today’s planned Slots in Slot order. If today has no filled Slots, this button is not displayed.

Start Clean Practice: Always visible. Launches Live Practice with an empty PracticeBlock. The user adds drills within the Live Practice workflow (Section 13).

Drill and Routine selection is handled entirely within the Live Practice workflow. Home does not contain a mini-picker or Quick Start drill/routine selector.

12.3.3 Home Exclusions

The following are intentionally excluded from Home to avoid duplicating Review:

6.  Weakness highlights.

7.  Trend sparklines.

8.  Plan Adherence percentage.

9.  Last Session summary.

12.4 Plan Architecture

Plan uses a dual-tab internal structure for consistency with Track and Review:

Calendar | Create

12.4.1 Calendar — 3-Day View (Default)

Default calendar mode displays a rolling 3-day window: Today + 2 days forward. The view is horizontally swipeable infinitely in both directions (past and future).

Each day displays:

5.  SlotCapacity.

6.  Filled Slots (with Drill name).

7.  Empty Slots (visually distinct).

8.  Completion state per Slot: Incomplete, Completed (linked), Completed (manual), or Overflow.

9.  Ownership indicator per Slot: Manual, RoutineInstance-owned, or ScheduleInstance-owned.

Slot Interactions (3-Day View)

Tap empty Slot: Opens the Calendar Bottom Drawer (see §12.4.4) allowing the user to add a Drill, apply a Routine, or apply a Schedule.

Tap filled Slot: Opens Slot Detail showing: Drill information (name, Skill Area, Drill Type), Replace action, Remove action, Start Practice shortcut (launches Live Practice with this Drill queued), and Ownership display (Manual / Routine / Schedule source).

Drag and drop: Allowed into empty Slots only. Dropping onto a filled Slot is visually blocked. Overwriting filled Slots is prohibited, consistent with Section 8 guarantees.

12.4.2 Calendar — 2-Week View

Toggle available at top of Calendar: 3-Day | 2-Week.

2-Week view displays a 14-day grid. Each day shows a compact summary: X / Y (filled / capacity). No individual Slot rendering. No per-Slot visuals.

Interactions (2-Week View)

Tap a day: Switches to 3-Day View centred on the tapped date.

Drag Drill onto a day: Fills the first empty Slot on that day. If no empty Slots exist, the drop is blocked (no auto-expansion of SlotCapacity).

Drag Routine onto a day: Fills remaining empty Slots on that day in entry order. Excess Routine entries are discarded. No overwrite. No prompt.

Drag Schedule onto a day: Opens a date picker. Start date is pre-filled with the drop date. User selects an end date or a duration (e.g. 2 weeks, 4 weeks, custom). A preview is presented showing all resolved Slot assignments across the date range. User must confirm before Slots are committed. This follows the same behaviour as Schedule drops in 3-Day View.

2-Week View Exclusions

4.  No individual Slot editing.

5.  No Slot tap-to-open detail.

6.  No Slot reorder.

7.  No Slot-level ownership inspection.

2-Week View is a strategic planning surface, not a micro-editing layer.

12.4.3 Calendar View Switch

The Calendar provides an explicit toggle control: 3-Day | 2-Week. No gesture dependency (pinch-to-zoom). No hidden interactions. The toggle is always visible at the top of the Calendar surface.

12.4.4 Calendar Bottom Drawer

When the bottom drawer opens (via tapping an empty Slot in 3-Day View, or initiated via an add action), content is structured with a segmented control:

Drills | Routines | Schedules

Each segment provides:

5.  Search bar.

6.  Filters (Skill Area, Drill Type where applicable).

7.  Scrollable list of matching objects.

8.  Drag handles on each item for drag-and-drop into Calendar Slots.

The bottom drawer is persistent and scrollable while the Calendar remains visible above it.

12.4.5 Create Surface

Create presents three equal tiles with benefit-led descriptions:

4.  Create Drill — “Design a new practice test.”

5.  Create Routine — “Build a repeatable session.”

6.  Create Schedule — “Plan multiple days at once.”

Tiles are equal weight. No hierarchical bias is expressed visually.

Save & Practice

After completing Drill creation, the user is presented with two actions:

3.  Save — returns to Plan.

4.  Save & Practice — saves the Drill and immediately launches Live Practice with the newly created Drill queued.

This supports the practice-first philosophy by eliminating friction between creation and execution.

12.5 Track Architecture

Track uses a segmented control at the top:

Drills | Routines

12.5.1 Segment Behaviour

3.  Filters persist independently per segment (Drills and Routines maintain separate filter state).

4.  A clear Reset Filters control is visible whenever filters are active.

5.  Switching segments does not clear filter state on the other segment.

6.  Scroll position does not persist across segment switches.

7.  Default state = no filters applied.

12.5.2 Drill Library Structure

Drills are grouped into seven collapsible Skill Area sections, matching the canonical Skill Tree (Section 2). Sections are collapsible inline (accordion behaviour). Filters are available above the grouped list: Skill Area, Drill Type (Transition / Pressure / Technique Block), Subskill, and Scoring Mode (Shared / Multi-Output).

No flat global list is the default. Users always see structural grouping first.

12.5.3 Routine Library Structure

Routines are displayed as a flat list. Default sort order is most recently used. Routines are not grouped by Skill Area because a single Routine may span multiple Skill Areas.

12.5.4 Drill Detail View (Track Context)

Track is read-only for drill details. The user may view all drill information (Skill Area, Subskill mapping, Drill Type, Scoring Mode, anchors, Set structure, Target Definition) but may not edit any field from within Track.

An “Edit Drill” button is displayed on the Drill detail view. Tapping it navigates the user to the drill editing surface in Plan. The button label is “Edit Drill” with no reference to Plan in the button text.

For System Drills (where user editing is not permitted), the Edit Drill button is not displayed.

12.5.5 Track is Execution-Preparation Only

Track is the browsing and selection surface. It is not the execution surface. Starting a Drill or Routine from Track transitions the user into the separate Live Practice state. Track and Live Practice are architecturally distinct.

12.6 Review Architecture

Review uses a dual-tab internal structure:

Dashboard | Analysis

12.6.1 Review Dashboard

The Review Dashboard displays the following components:

6.  Overall Score (0–1000).

7.  Skill Area Heatmap (7 tiles, expandable inline to Subskills — accordion behaviour).

8.  Context-aware Trend Snapshot.

9.  Plan Adherence headline percentage (small secondary metric positioned below the Trend Snapshot; not competing with Overall Score).

10. CTA: View Weakness Ranking.

Heatmap Behaviour

Default state: 7 Skill Area tiles. No full Subskill grid at first glance.

Tap a Skill Area tile: expands inline to reveal its Subskills. No navigation stack change. Collapse restores the compact dashboard.

This maintains the Review Dashboard as a single coherent surface without navigation depth.

Trend Snapshot Behaviour

Default: displays the Overall score trend.

When a user taps and expands a Skill Area tile in the Heatmap, the Trend Snapshot automatically switches context to display that Skill Area’s trend. When the Skill Area is collapsed, the Trend Snapshot reverts to Overall. No separate toggle required. This creates a tight coupling between the spatial Heatmap and the temporal Trend.

Weakness Ranking Access

Weakness Ranking is accessible from two locations:

4.  Review Dashboard — via the “View Weakness Ranking” CTA.

5.  Planning tab — accessible from within the Planning surface to inform generation decisions.

The Weakness Ranking view displays all Subskills in priority order as defined by the Weakness Detection Engine (Section 8, §8.7). It is informational and does not trigger planning or generation actions from within Review.

12.6.2 Analysis

Analysis is chart-centric with a filter-driven scope model. The user interacts with one dynamic chart surface, not hierarchical drill-down navigation.

Chart Toggle

A toggle control appears above the chart area:

Performance | Volume | Both

9.  Performance: line chart showing 0–5 score trends.

10. Volume: stacked bar chart showing Session execution count.

11. Both: combined view with trend line and volume bars.

Top Filter Row

Four filters are always visible:

Scope: Overall | Skill Area | Drill.

Drill Type: All | Transition | Pressure. Technique Block is excluded from this filter because Technique drills do not enter windows, produce no scored output, and do not participate in the 65/35 weighting model. Technique drills remain visible when Scope = Drill and the selected drill is a Technique Block.

Time Resolution: Daily | Weekly | Monthly.

Date Range: Last 4 weeks | Last 3 months | Last 6 months | Last 12 months | Custom.

Conditional Filters Based on Scope

If Scope = Skill Area: A secondary Skill Area selector appears (7 areas). A tertiary Subskill selector appears within the chosen area (e.g. Irons → All | Distance Control | Direction Control | Shape Control). Subskills are always nested under their parent Skill Area and never appear as a top-level scope option.

If Scope = Drill: A Drill selector appears listing drills from the user’s Practice Pool, filtered by the active Drill Type selection. If the selected Drill is a Technique Block, the Drill Type filter auto-locks and the chart shows Session data without Pressure/Transition segmentation.

Session History (Drill Scope)

When Scope = Drill, a “View Session History” button appears below the chart. Tapping it opens a dedicated session list view for the selected drill showing all historical Sessions with date, 0–5 score, and Set/Instance summary. This is the primary entry point for session-level inspection within Analysis.

Volume Chart Specification

X-axis: Date buckets respecting the selected Time Resolution.

Y-axis: Count of Sessions completed.

Stacking model:

5.  Primary segmentation = Skill Area. Each of the 7 Skill Areas has a base colour.

6.  Within each Skill Area segment, shade variation indicates Drill Type: lighter shade = Transition, darker shade = Pressure, neutral/grey-tinted shade = Technique Block.

Legend model: The legend displays 7 Skill Areas by their base colour. A separate key explains the shade convention (Light = Transition, Dark = Pressure, Neutral = Technique). The legend does not list 21 individual segments.

12.6.3 Comparative Analytics

V1 includes one comparison mode: time range vs time range.

The user may select two date ranges and compare performance across the same scope. The comparison overlay displays both ranges on the same chart with visual differentiation (e.g. solid line for Range A, dashed line for Range B).

Comparison mode is available for all Scope levels (Overall, Skill Area, Drill) and respects all active filters (Drill Type, Subskill selection).

Comparison Activation

Comparison is activated via a toggle or button within Analysis (e.g. “Compare”). When active, the Date Range selector changes from a single range to two range selectors: Range A and Range B. The user selects both independently.

Comparison Constraints

8.  Only time range vs time range is supported in V1.

9.  Drill vs Drill comparison is deferred to V2.

10. Skill Area vs Skill Area comparison is deferred to V2.

11. Pressure vs Transition split view is deferred to V2.

12. Planned vs Executed (Adherence crossover) is deferred to V2.

12.7 Live Practice Architecture (Structural Scope)

Live Practice is an immersive full-screen execution state. Its detailed internal architecture (drill selection, Instance entry, Set/Session management) is deferred to Section 13 (Live Practice Workflow). Section 12 defines only its structural relationship to the rest of the application.

12.7.1 Entry

Live Practice is launched from any of the entry points defined in §12.2.2. All entry points create a new PracticeBlock. When launched via Start Clean Practice, the PracticeBlock starts empty; the user adds drills within Live Practice. When launched via Start Today’s Practice, the PracticeBlock is pre-loaded with today’s planned Slots in Slot order.

12.7.2 State Isolation

When Live Practice is active:

1.  Bottom navigation is hidden.

2.  No cross-tab navigation is possible.

3.  The application is in an immersive execution state.

4.  Lifecycle timers (PracticeBlock 4-hour auto-end, Session 2-hour inactivity) operate as defined in Section 3.

12.7.3 Exit

When the user ends practice (PracticeBlock closes), the flow is:

1.  Live Practice ends.

2.  Post-Session Summary screen is displayed (see §12.8).

3.  User taps Done.

4.  Application returns to Home Dashboard.

Exit always routes to Home, regardless of the surface that launched Live Practice. No navigation stack is restored. Practice is treated as a completed event.

12.8 Post-Session Summary Screen

A dedicated summary screen is displayed after Live Practice ends and before the user returns to Home. This screen provides psychological closure and score reinforcement.

12.8.1 Content

The Post-Session Summary displays:

1.  Final 0–5 drill score(s) for each Session completed in the PracticeBlock.

2.  Impact on the 1000-point Overall Score (delta).

3.  Key session statistics (as defined by Section 4, §4.8 end-of-session feedback).

12.8.2 Behaviour

1.  The summary is a dedicated state, not a modal or toast.

2.  The user must tap Done to proceed.

3.  Tapping Done returns the user to Home Dashboard.

4.  No automatic timeout or auto-dismiss.

5.  Scores displayed reflect the updated engine state (post-reflow if any reflow was triggered).

12.9 Structural Consistency Model

Each primary domain follows a consistent two-tab internal pattern:

1.  Plan: Calendar | Create

2.  Track: Drills | Routines

3.  Review: Dashboard | Analysis

This symmetry reduces cognitive load and creates predictable navigation behaviour. All three domains use the same interaction pattern: a top-level segmented control toggling between two sub-surfaces within the tab.

12.10 Cross-Shortcut Model

The application is non-dogmatic about cross-domain shortcuts. If a logical action exists on a given surface, it should be accessible without forcing the user back to the “correct” tab.

12.10.1 Confirmed Cross-Shortcuts

1.  Plan → Live Practice: Start Practice from Calendar Slot, Save & Practice from Drill creation.

2.  Track → Live Practice: Start action on any Drill or Routine.

3.  Track → Plan: Edit Drill button on Drill detail navigates to Plan editing surface.

4.  Review → Weakness Ranking: CTA on Review Dashboard.

5.  Planning tab → Weakness Ranking: accessible to inform generation decisions.

6.  Any Drill detail page → Live Practice: Practice This Drill action.

7.  Home → Live Practice: Start Today’s Practice or Start Clean Practice.

12.10.2 Shortcut Philosophy

Cross-shortcuts are asymmetrical. The primary flow is encouraged through visual hierarchy and CTA placement. Shortcuts are secondary and do not compete for visual dominance. The primary flow for execution is: Home → Start Practice → Live Practice. All other entry points are convenience shortcuts.

12.11 Interaction Guarantees

The UI guarantees:

1.  No UI action overrides structural backend rules defined in Sections 1–11.

2.  No hidden Slot overwrites — existing Slot assignments are never overwritten by system actions.

3.  No automatic SlotCapacity expansion from UI actions (only completion overflow as defined in Section 8).

4.  Deterministic drag-and-drop behaviour — drop targets and blocking are visually explicit.

5.  Clear separation between planning (Plan), preparation (Track), and execution (Live Practice).

6.  Live Practice state isolation — no cross-tab navigation during execution.

7.  Consistent two-tab internal pattern across Plan, Track, and Review.

8.  Post-Session Summary always displayed before returning to Home.

9.  Filter persistence within segments but clear reset capability.

10. Read-only drill details in Track with explicit Edit Drill navigation to Plan.

12.12 Explicit Non-Goals

Section 12 intentionally excludes:

1.  Animation design specifications.

2.  Colour palette definitions.

3.  Typography system.

4.  Micro-interaction timing.

5.  Accessibility compliance rules.

6.  Responsive web breakpoints.

7.  Live Practice internal workflow (deferred to Section 13).

These are defined in Section 15 (Branding & Design System 15v.a4) and Section 13 (Live Practice Workflow 13v.a4).

End of Section 12 — UI/UX Structural Architecture (12v.a5 Consolidated)

