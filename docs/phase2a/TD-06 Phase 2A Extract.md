TD-06 Phased Build Plan — Phase 2A Extract (TD-06v.a6)
Sections: §5 Phase 2A — Pure Scoring Library
============================================================

5. Phase 2A — Pure Scoring Library

5.1 Scope

Phase 2A implements all scoring functions as pure, side-effect-free Dart functions. No database writes, no locks, no reflow orchestration, no repository dependencies. Each function takes input data and returns a computed result. This isolation guarantees that any test failure in Phase 2A is a scoring logic bug, not an orchestration or persistence bug.

5.1.1 Spec Sections In Play

-   Section 1 (Scoring Engine) — two-segment linear interpolation, window composition, aggregation

-   Section 2 (Skill Architecture) — subskill allocations, 65/35 weighting

-   TD-05 (Scoring Engine Test Cases) — Sections 4–9 (Instance, Session, Window, Subskill, Skill Area, Overall)

5.1.2 Deliverables

-   scoreInstance(rawMetrics, anchors, metricSchema) → double (0–5). Two-segment linear interpolation with hard cap at 5. Pure function.

-   Scoring adapters per MetricSchema: grid_1x3_direction, grid_3x1_distance, grid_3x3_multioutput, binary_hit_miss, raw_carry_distance, raw_ball_speed, raw_club_head_speed. Each adapter extracts the relevant metric from RawMetrics JSON and delegates to scoreInstance.

-   scoreSession(instances) → double. Simple average of all Instance 0–5 scores across all Sets. Pure function.

-   composeWindow(sessions, maxOccupancy) → WindowState. Orders by CompletionTimestamp DESC, SessionID DESC. Walks forward summing occupancy (1.0 single-mapped, 0.5 dual-mapped). Includes entries up to ≤ 25.0 occupancy. Handles partial roll-off (1.0 → 0.5 with score preserved). Returns entries list, totalOccupancy, weightedSum, windowAverage. Pure function.

-   scoreSubskill(transitionWindow, pressureWindow, allocation) → SubskillScore. WeightedAverage = (TransitionAvg × 0.35) + (PressureAvg × 0.65). SubskillPoints = Allocation × (WeightedAverage / 5). Handles empty windows (average = 0.0). Pure function.

-   scoreSkillArea(subskillScores) → double. Sum of SubskillPoints. Pure function.

-   scoreOverall(skillAreaScores) → double. Sum of all 7 Skill Area scores. Maximum 1000. Pure function.

-   evaluateIntegrity(instances, metricSchema) → bool. Checks HardMinInput/HardMaxInput bounds per Section 11. Grid Cell Selection and Binary Hit/Miss excluded. Values at boundary are not in breach. Pure function.

-   Automated test suite covering TD-05 Sections 4–9

5.2 Dependencies

Phase 1 (Drift schema for type definitions, seed data for SubskillRef allocations and System Drill anchors used in test fixtures).

5.3 Stubs

-   No database writes — all functions operate on in-memory data structures

-   No reflow — functions are called directly in tests with constructed inputs

-   No lock mechanics — pure functions have no concurrency concerns

5.4 Acceptance Criteria

-   All TD-05 test cases in Sections 4–9 pass (Instance scoring, Session scoring, window composition, subskill scoring, Skill Area scoring, Overall SkillScore)

-   scoreInstance produces exact results for all boundary cases: below Min (→0.0), at Min (→0.0), mid-range, at Scratch (→3.5), between Scratch and Pro, at Pro (→5.0), above Pro (→5.0 capped)

-   composeWindow handles: empty window, partial fill, full 25-unit fill, overflow eviction, dual-mapped 0.5 occupancy, mixed occupancy, boundary case (0.5 fits but 1.0 does not), partial roll-off (1.0 → 0.5)

-   All calculations use IEEE 754 double-precision. No intermediate rounding. Assertions use 1e-9 tolerance (TD-05 §2.2).

-   evaluateIntegrity correctly identifies breaches and non-breaches, excludes Grid/Binary schemas

5.5 Acceptance Test Cases

Automated (required): All TD-05 Sections 4–9 implemented as Dart unit tests. Each test case follows the Given → When → Then format from TD-05. Test runner must report 100% pass rate.

