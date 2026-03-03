Scoring Engine — Canonical Specification

Version 1v.g2 — Consolidated

This replaces Section 1 in full. It encodes every final architectural decision.

1.1 Core Principles

The scoring engine is: Linear, Deterministic, Fully recalculable, Occupancy-weighted, Subskill-granular, and Globally weighted (65/35 Pressure/Transition).

There is: No time decay, No smoothing algorithms, No volatility dampening, No outlier filtering, No diversity enforcement, and No difficulty multipliers.

Scores change only when: New drills are logged, Old drills roll off windows, or Structural scoring parameters are edited (triggering reflow).

There is one canonical scoring model at any time.

1.2 Overall Score Structure

Total Score = 1000 points.

Skill Area Allocations (system-controlled, not user-editable):

• Irons – 280

• Driving – 240

• Putting – 200

• Pitching – 100

• Chipping – 100

• Woods – 50

• Bunkers – 30

1.3 Subskill Allocation (Rounded Canonical Values)

Irons (280)

Distance Control – 110, Direction Control – 110, Shape Control – 60

Driving (240)

Distance Maximum – 95, Direction Control – 95, Shape Control – 50

Putting (200)

Distance Control – 100, Direction Control – 100

Pitching (100)

Distance Control – 40, Direction Control – 40, Flight Control – 20

Chipping (100)

Distance Control – 40, Direction Control – 40, Flight Control – 20

Woods (50)

Distance Control – 20, Direction Control – 20, Shape Control – 10

Bunkers (30)

Distance Control – 15, Direction Control – 15

Each Skill Area score is the sum of its subskill scores. It is mathematically impossible to max a Skill Area while ignoring a subskill. Subskill allocations are system-controlled and not user-editable.

1.4 Drill Scoring Model

Every scored drill must define, per mapped subskill:

• Minimum Viable Performance → maps to 0

• Scratch Benchmark → maps to 3.5

• Pro Threshold → maps to 5

Linear interpolation is used.

Let p = performance metric, min = minimum viable, scratch = scratch benchmark, pro = pro threshold.

Case 1 – Below Minimum: Score = 0.

Case 2 – Between Minimum and Scratch: Score = 3.5 × (p – min) / (scratch – min).

Case 3 – Between Scratch and Pro: Score = 3.5 + 1.5 × (p – scratch) / (pro – scratch).

Case 4 – Above Pro: Score = 5.

Score is strictly capped at 5. No nonlinear curves. No logistic scaling. No asymptotic ceilings.

1.5 Drill Type Weighting (Global)

Applied identically to every subskill:

• Pressure = 65%

• Transition = 35%

The 65/35 weighting is a system-level constant and is not configurable per skill, subskill, or user.

1.6 Subskill Rolling Window Model

Windows exist only at the subskill level. Each subskill maintains:

• 25 Transition occupancy units

• 25 Pressure occupancy units

Window size is fixed at 25 occupancy units per window. It is a system-level constant and is not user-configurable.

No skill-level windows exist.

1.7 Occupancy Unit Mechanics

A drill must contribute to at least 1 subskill and may contribute to at most 2 subskills.

Occupancy Rules

If drill contributes to 1 subskill → occupancy = 1.0.

If drill contributes to 2 subskills → occupancy = 0.5 per subskill.

Minimum occupancy unit = 0.5. No fractional splitting below 0.5.

1.8 Shared vs Multi-Output Scoring Modes

Shared Mode (Default)

Drill produces one score. One anchor set (Min / Scratch / Pro) defines the scoring scale.

If mapped to two subskills: Occupancy = 0.5 each. Same score stored in both. Effective contribution per subskill = score × 0.5 occupancy.

Multi-Output Mode

Drill maps to exactly two subskills and produces an independent score per subskill. Each subskill has its own independent anchor set (Min / Scratch / Pro). Each subskill receives its own independently calculated 0–5 score. Occupancy = 0.5 each. Both subskills are scored using the same linear interpolation model but against their own anchor values.

Total system influence equals one full drill.

1.9 Window Averaging Formula

For each practice type window:

Let s_i = score of entry i, o_i = occupancy of entry i.

Total Occupancy = sum of all o_i.

Weighted Sum = sum of (s_i × o_i).

Window Average = Weighted Sum / Total Occupancy.

Window is “full” when Total Occupancy = 25.

1.10 Roll-Off Logic

When adding a new entry:

If total occupancy + new occupancy ≤ 25 → append normally.

If total occupancy + new occupancy > 25 → remove oldest occupancy units first.

Removal occurs in 0.5 increments only.

If removing from a 1.0 entry: Remove 0.5. Reduce stored occupancy. The original 0–5 score is preserved unchanged; only the occupancy weight changes. Remove entry entirely if occupancy reaches 0.

If removing from a 0.5 entry: Remove the entire entry (0.5 is the minimum occupancy unit and cannot be subdivided further).

Roll-off is proportional and symmetric with entry behaviour.

1.11 Subskill Score Conversion

For each subskill: Maximum possible = 5.

Subskill Points Earned = Allocation × (Weighted Average / 5).

Unfilled occupancy contributes 0. Subskills contribute from the first qualifying drill.

1.12 Skill Area Score

Skill Area Score = sum of its Subskill Points.

1.13 Overall Score

Overall Score = sum of all Skill Area Scores.

Always displayed against the full 1000-point scale. The system never calculates or displays a reduced “attainable” total based on which subskills currently have data. A user with data in only one subskill still sees their score out of 1000.

No emotional framing of drops.

1.14 Zero Baseline Behaviour

All subskills start at 0. All windows start empty. Empty capacity contributes 0. Score builds upward over time.

1.15 Reflow Governance

Any change to structural scoring parameters triggers: Full historical recalculation, window reprocessing, skill recomputation, overall recomputation, logged “Scoring Model Updated” event, and timeline annotated as recalculated.

Execution Model

Reflow executes as a background process, triggered immediately after the structural edit is committed. The UI displays a loading state until recalculation is complete. Scores are not available for display during reflow. There is no on-read recalculation.

User-Initiated Triggers

Drill anchor edits (User Custom Drills only).

System-Initiated Triggers

Skill Area allocation edits, Subskill allocation edits, 65/35 weighting edits, scoring formula edits, and System Drill anchor edits.

Not Reflow Triggers

Window size (fixed system constant, not editable).

There is one canonical scoring model. No legacy model branches.

1.16 Ceiling Behaviour

Score capped strictly at 5 per drill. No overperformance tracking. No automatic anchor adjustment. Calibration edits are manual.

1.17 Drill Retirement and Deletion

Retirement and Deletion are distinct actions with different scoring consequences.

Retired Drills

• Hidden from drill library and unavailable for new Sessions

• Historical Sessions and scoring data fully retained

• Remain in historical windows and roll off naturally

• Cannot be manually purged from scoring

Deleted Drills

• Permanently removed along with all Sessions and Instances

• Full recalculation triggered

• Irreversible action

1.18 System Guarantees

The engine guarantees: Deterministic outputs, Linear performance mapping, Occupancy-weighted fairness, No inflation from split drills, No hidden smoothing, Structural integrity across edits, and Full recalculability.

Section 1 is now mathematically closed and fully harmonised.

End of Section 1 — Scoring Engine (1v.g2 Consolidated)

