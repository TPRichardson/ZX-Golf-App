# TD-06 Phased Build Plan — Phase 6 Extract (TD-06v.a6)
Sections: §11 Phase 6 — Review & Analysis
============================================================

11. Phase 6 — Review & Analysis

11.1 Scope

Phase 6 builds the Review surface: SkillScore dashboard, subskill trends, Skill Area breakdowns, drill history, and window visualisation. This phase is read-only — it reads from materialised tables. No new write operations.

11.1.1 Spec Sections In Play

-   Section 5 (Review) — dashboard, Skill Area detail, subskill detail, drill history, window detail

-   Section 12 (UI/UX Structural Architecture) — Review tab structure, navigation patterns

11.1.2 Deliverables

-   SkillScore dashboard: Overall SkillScore (0–1000), 7 Skill Area scores, heatmap visualisation

-   Skill Area detail: subskill breakdown, allocation weights, Transition/Pressure split

-   Subskill detail: window contents, Session entries, occupancy visualisation

-   Window detail view: ordered entries with scores, occupancy, timestamps

-   Drill history: per-drill Session list with scores and dates

-   Trend visualisation: subskill score over time

-   Heatmap rendering: grey-to-green continuous opacity scaling per §15.3.3. No hard-banded tiers.

-   Score display: tabular lining numerals, no animated counting, neutral presentation (§15.2)

-   Zero state: dashboard displays correctly when no scoring data exists

-   IntegrityFlag indicators at Session level in drill history only (not in SkillScore views per §15.8.5)

-   All reads from materialised tables via ScoringRepository reactive streams

11.2 Dependencies

Phase 4 (closed Sessions populate materialised tables). Phase 2A/2B (scoring engine). Phase 1 (design system).

11.3 Stubs

None. Phase 6 consumes existing data.

11.4 Acceptance Criteria

-   Dashboard shows Overall SkillScore and all 7 Skill Area scores

-   Skill Area detail shows correct subskill breakdown matching SubskillRef seed data

-   Window detail shows entries ordered by CompletionTimestamp DESC with correct scores and occupancy

-   Heatmap uses continuous grey-to-green opacity (no discrete bands, no red)

-   Score communication is neutral: no celebratory text, no emotional framing (§15.2)

-   Zero state handled: empty dashboard renders correctly

-   Cold-start: dashboard loads in < 1 second from materialised tables on Pixel 5a (TD-01 §4.2)

-   WCAG AA minimum contrast on all surfaces, AAA on SkillScore and Subskill score displays

11.5 Acceptance Test Cases

Manual (required): Full Review navigation. Numeric verification against expected scoring. Heatmap visual verification. Zero state. Cold-start timing on Pixel 5a. Contrast verification (WCAG AAA on critical surfaces).

