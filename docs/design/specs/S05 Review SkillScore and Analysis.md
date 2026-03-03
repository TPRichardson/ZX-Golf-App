Section 5 — Review: SkillScore & Analysis

Version 5v.d6 — Consolidated

This document defines the Review module of ZX Golf App. Review contains three distinct components: SkillScore (engine state), Analysis (trend & diagnostic layer), and Plan Adherence (practice discipline metrics). The three components are architecturally separate and serve different purposes. Fully harmonised with Section 8 (Practice Planning Layer 8v.a8).

5.1 SkillScore (Engine State View)

Purpose

SkillScore displays the user’s current scoring engine state.

SkillScore reflects: 65/35 Transition/Pressure weighting, Subskill rolling windows (25 occupancy units each, fixed), Occupancy mechanics, Allocation mathematics, and Deterministic scoring logic.

SkillScore is not bucket-based and does not use session grouping.

Displayed Values

• Overall Score (0–1000) — always against the full 1000-point scale; never a reduced attainable total

• Skill Area Scores

• Subskill Scores (0–5 effective weighted average)

• Transition & Pressure window saturation (e.g., 18/25)

• Current weighted averages per subskill

All values represent the current engine state only.

Structural Guarantees

• No smoothing

• No time decay

• No bucket aggregation

• Fully recalculable from historical data

• Deterministic output

Window Detail View

User may tap into any Transition or Pressure window from the SkillScore view.

Window detail displays a chronological list of all entries currently in the window.

Ordering

• Newest entries at the top

• Oldest entries at the bottom

• Roll-off occurs from the bottom (oldest first)

Each Entry Shows

• Drill name

• Date

• 0–5 score

• Occupancy consumed (1.0 or 0.5)

A visual divider marks the boundary above the next entry eligible for roll-off. The bottom-most entry is always the next to drop when new occupancy is added.

Read-only inspection only. No editing or deletion permitted from this view.

Weakness Ranking View

Accessible as a secondary view from SkillScore, the Weakness Ranking displays all Subskills in priority order as determined by the Weakness Detection Engine (Section 8, §8.7). This view is informational and does not trigger any planning or generation action from within Review.

For each Subskill, the ranking displays:

• Rank position

• Subskill name and Skill Area

• Current weighted average (0–5)

• Window saturation (e.g. 12/25 Transition, 25/25 Pressure)

• WeaknessIndex value (allocation-weighted priority metric)

• Allocation (e.g. 110/1000)

The same ranking is also accessible from the Planning tab (Section 8, §8.7.3), where it informs generation decisions.

5.2 Analysis (Trend & Diagnostic View)

Purpose

Analysis displays performance trends and behavioural diagnostics over time. Analysis is session-native and independent of window mechanics.

Score-Level Trends

Applies to: Overall, Skill Area, and Subskill levels.

Vertical Axis: 0–5 scale only.

Resolution Toggle

• Daily

• Weekly (default)

• Monthly

Bucket Value

Mean of Session 0–5 scores within that bucket. Bucket displays Session count. No reconstruction of allocation or 1000-point scale occurs.

Subskill Trend Clarification

At the Subskill level, each subskill’s trend is populated by that subskill’s own independent 0–5 score. For Multi-Output drills, each subskill receives its own score directly. The drill-level averaged score (used for drill-level display only) does not feed into subskill trends.

Rolling Overlay Rules

• Daily view: 7-bucket rolling average

• Weekly view: 4-bucket rolling average

• Monthly view: No rolling overlay

Rolling overlay operates across buckets only.

Drill-Level Analysis

Drill view contains: 1) Session score trend (0–5), and 2) Raw metric diagnostics.

Multi-Output Drills

Drill-level Session score = mean of the two subskill 0–5 outputs. Single trend line displayed. This is a display convention only — this averaged value does not feed back into the scoring engine or affect window entries.

Raw Diagnostics

Raw diagnostics visualise the distribution of Instance results. The visualisation type depends on the drill’s input mode:

Grid Cell Selection drills: The diagnostic displays the grid with hit/miss distribution across cells. The grid is rendered at the same dimensions as the Instance entry grid. Each cell shows the count and percentage of Instances that landed in it. The center box hit-rate (the scored metric) is highlighted.

For 3×3 grids, two additional summary views are derived:

• 1×3 direction summary: Aggregates columns into Left / Center / Right totals.

• 3×1 distance summary: Aggregates rows into Long / Ideal / Short totals.

Continuous Measurement drills: Average raw metric value, distribution histogram.

Raw Data Entry drills: Average raw metric value, distribution histogram.

Binary Hit/Miss drills: Total hit count, total miss count, and hit-rate percentage. Displayed as a simple ratio visualisation (e.g. hit/miss bar). No grid or spatial distribution applies.

All grid diagnostic visualisations display data for the resolved target box. Where clubs varied across Instances (Random or Guided club selection), diagnostics aggregate all Instances regardless of club — the hit/miss judgment was made per Instance against the correct target for that Instance’s club.

Set Aggregation

Raw diagnostics aggregate all Instances across all Sets within a Session. No per-Set breakdown.

Raw analytics default to last 3 months. User may adjust date range.

Variance Tracking

Applies to drill level only.

A single standard deviation value is calculated from all Session 0–5 scores within the user’s selected date range. This is not calculated per bucket — it is one SD value representing consistency across the entire date range.

Multi-Output Drills

SD calculated separately for each subskill’s 0–5 scores. Two independent RAG indicators displayed.

Confidence Tiers

• Fewer than 10 Sessions in date range: RAG indicator not displayed. Message shown: “Insufficient data for variance analysis.”

• 10–19 Sessions in date range: RAG indicator displayed with “Low confidence” label.

• 20+ Sessions in date range: RAG indicator displayed at full confidence.

RAG Thresholds (fixed, system-defined)

• Green: SD < 0.40

• Amber: 0.40 ≤ SD < 0.80

• Red: SD ≥ 0.80

Date Range Persistence

• User-selected date range and resolution persist for 1 hour.

• Timer measures time since last visit to any Analysis screen.

• Visiting Analysis resets the timer.

• After 1 hour of no Analysis access, system resets to: Last 3 months, Weekly resolution.

Persistence applies across all Analysis views.

5.3 Plan Adherence

Purpose

Plan Adherence displays practice discipline metrics based on the Calendar defined in Section 8. It measures whether the user completed the practice they planned.

Metric

Adherence = (Completed planned Slots / Total planned Slots) × 100, expressed as a percentage.

Only Slots with a DrillID assigned count as planned (empty capacity excluded). Overflow Slots (auto-created for unplanned completions, Planned = false) are excluded from both numerator and denominator. Adherence measures discipline against the original plan, not bonus work.

Segmentation

• Weekly and monthly rollups

• Skill Area breakdown: of all planned Slots containing Drills in a given Skill Area, what percentage were completed

Time Period Options

• Custom date range

• Last 12 months

• Last 6 months

• Last 3 months

• Last 4 weeks

Date Range Persistence

User-selected date range persists for 1 hour, consistent with the Analysis persistence model (§5.2). After 1 hour of no access, the system resets to: last 4 weeks.

Rollup boundaries use the user’s home timezone and the user’s configured week start day (Monday or Sunday).

5.4 Structural Separation

SkillScore, Analysis, and Plan Adherence are architecturally distinct.

SkillScore = current engine state. Analysis = session-native performance trends.

No window mechanics are exposed within Analysis.

Plan Adherence = Calendar-native discipline tracking. No interaction with scoring engine, windows, or derived scores.

Session duration data (Section 14, §14.10.8) is available within Analysis for time-based practice analytics. Duration is tracked passively on all scored Sessions (first Instance to last Instance) and recorded as the primary data field for Technique Block Sessions. Duration data has no scoring impact and does not interact with window mechanics.

End of Section 5 — Review: SkillScore & Analysis (5v.d6 Consolidated)

