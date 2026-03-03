TD-05 — Scoring Engine Test Cases

Version TD-05v.a3 — Canonical

Harmonised with: Section 0 (0v.f1), Section 1 (1v.g2), Section 2 (2v.f1), Section 4 (4v.g9), Section 6 (6v.b7), Section 7 (7v.b9), Section 9 (9v.a2), Section 11 (11v.a5), Section 14 (14v.a4), TD-01 (TD-01v.a4), TD-02 (TD-02v.a6), TD-03 (TD-03v.a5), TD-04 (TD-04v.a4).

1. Purpose

This document provides concrete, numerically verified test cases for the ZX Golf App scoring engine. Each test case follows the Given → When → Then format with exact numeric expected values. Claude Code must be able to run these test cases against its scoring implementation and verify correctness at every layer of the scoring pipeline.

Test cases are organised by scoring pipeline layer, from lowest (Instance) to highest (Overall SkillScore), followed by reflow scenarios, edge cases, anchor validation, and determinism verification. All anchor values are drawn from the V1 System Drill Library (Section 14) unless explicitly noted as User Custom Drill examples.

Deliverable: This specification document. Convertible to automated tests during Phase 2 of the build (TD-06).

2. Precision & Rounding Policy

All scoring calculations must produce deterministic results across all devices and platforms. This section defines the numeric precision contract that all test assertions depend on.

2.1 Internal Precision

All intermediate and final scoring calculations use IEEE 754 double-precision floating point (float64 / Dart double). No intermediate rounding is applied at any step in the pipeline. The full double-precision value propagates from Instance score through to Overall SkillScore. Integer truncation, single-precision floats, and fixed-point arithmetic are prohibited in the scoring pipeline.

2.2 Assertion Tolerance

All test assertions use an absolute epsilon tolerance of 1e-9 (0.000000001). A test passes if |expected − actual| < 1e-9. This tolerance accounts for floating-point representation error while rejecting any algorithmic deviation. The tolerance is applied at every assertion point: Instance score, Session score, WindowAverage, WeightedAverage, SubskillPoints, SkillAreaScore, and OverallScore.

2.3 Display Precision

Display rounding is a UI-layer concern, not a scoring-engine concern. The scoring engine stores and returns full double-precision values. The UI rounds for display only and never feeds rounded values back into calculations. Recommended display precision: 0–5 scores to 1 decimal place, SubskillPoints to 1 decimal place, SkillAreaScore to 1 decimal place, OverallScore to 0 decimal places. These are UI recommendations only and do not affect test assertions.

2.4 Deterministic Equality

When this document states that two scoring states must be 'identical' (e.g. post-rebuild convergence), this means: for every row in every materialised table, every numeric column satisfies |value_A − value_B| < 1e-9, and every non-numeric column (SubskillID, PracticeType, UserID) is byte-equal. Materialised table comparison is performed row-by-row after sorting by composite primary key. No hash-based comparison is required; row-level numeric comparison with the defined tolerance is sufficient.

2.5 Algebraic Rearrangement

Formulas are written in a canonical form (e.g. Allocation × (WeightedAverage / 5)). Implementations may use algebraically equivalent rearrangements (e.g. (Allocation × WeightedAverage) / 5) provided the result satisfies the §2.2 assertion tolerance. This prevents over-constraining implementation while preserving determinism. Under IEEE 754 float64, most simple rearrangements produce bit-identical results for the value ranges in ZX Golf App, but the tolerance is the formal contract.

3. Reference Data for Test Cases

3.1 Subskill Allocations

From Section 2 (§2.3) and TD-02 SubskillRef seed data:

  ------------------------- ------------------------------- -------------
  Skill Area                Subskill                        Allocation

  Irons (280)               Distance Control                110

                            Direction Control               110

                            Shape Control                   60

  Driving (240)             Distance Maximum                95

                            Direction Control               95

                            Shape Control                   50

  Putting (200)             Distance Control                100

                            Direction Control               100

  Pitching (100)            Distance Control                40

                            Direction Control               40

                            Flight Control                  20

  Chipping (100)            Distance Control                40

                            Direction Control               40

                            Flight Control                  20

  Woods (50)                Distance Control                20

                            Direction Control               20

                            Shape Control                   10

  Bunkers (30)              Distance Control                15

                            Direction Control               15
  ------------------------- ------------------------------- -------------

Total: 1000. WeightedAverage = (TransitionAvg × 0.35) + (PressureAvg × 0.65).

3.2 Anchor Reference Values (V1 System Drills)

  --------------------------------------- ---------- ------------ ---------- -------------
  Drill / Category                        Min        Scratch      Pro        Metric

  Direction (1×3) — most drills           30%        70%          90%        Hit-rate %

  Direction — Putting                     20%        60%          80%        Hit-rate %

  Direction — Bunkers                     10%        50%          70%        Hit-rate %

  Distance (3×1) — Irons/Woods/Pitching   30%        70%          90%        Hit-rate %

  Distance — Putting                      20%        60%          80%        Hit-rate %

  Distance — Chipping                     10%        50%          70%        Hit-rate %

  Distance — Bunkers                      10%        40%          60%        Hit-rate %

  Driving Carry                           180        250          300        Yards

  Driving Ball Speed                      130        155          170        mph

  Driving Club Speed                      85         105          115        mph

  Shape Control (Binary)                  30%        70%          90%        Hit-rate %

  Flight Control (Binary)                 30%        70%          90%        Hit-rate %
  --------------------------------------- ---------- ------------ ---------- -------------

3.3 Scoring Formula Reference

Two-segment linear interpolation (Section 1, §1.4):

Case 1 — Below Min: Score = 0.

Case 2 — Min to Scratch: Score = 3.5 × (p − min) / (scratch − min).

Case 3 — Scratch to Pro: Score = 3.5 + 1.5 × (p − scratch) / (pro − scratch).

Case 4 — Above Pro: Score = 5 (hard cap).

4. Instance Scoring Test Cases

Instance scoring converts raw metrics into a 0–5 score using the drill's anchors and the two-segment linear interpolation formula.

4.1 Grid Cell Selection (Hit-Rate)

Grid drills score on hit-rate percentage: (hits / total) × 100. The percentage is interpolated through anchors. For grid drills, the 0–5 score is computed once at Session level from the aggregate hit-rate, not per-Instance. Using Irons Direction anchors: Min=30, Scratch=70, Pro=90.

TC-4.1.1: Exactly at Minimum

Given: Hit-rate = 30% (3 Centre out of 10). Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

Score = 3.5 × (30 − 30) / (70 − 30) = 3.5 × 0 / 40 = 0.0.

Expected: 0.0.

TC-4.1.2: Below Minimum

Given: Hit-rate = 20%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

20 < 30 (below Min). Case 1.

Expected: 0.0.

TC-4.1.3: Mid-Range Between Min and Scratch

Given: Hit-rate = 50%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

Score = 3.5 × (50 − 30) / (70 − 30) = 3.5 × 20 / 40 = 1.75.

Expected: 1.75.

TC-4.1.4: Exactly at Scratch

Given: Hit-rate = 70%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

Score = 3.5 × (70 − 30) / (70 − 30) = 3.5 × 1.0 = 3.5.

Expected: 3.5.

TC-4.1.5: Between Scratch and Pro

Given: Hit-rate = 80%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

Score = 3.5 + 1.5 × (80 − 70) / (90 − 70) = 3.5 + 1.5 × 0.5 = 4.25.

Expected: 4.25.

TC-4.1.6: Exactly at Pro

Given: Hit-rate = 90%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

Score = 3.5 + 1.5 × (90 − 70) / (90 − 70) = 3.5 + 1.5 = 5.0.

Expected: 5.0.

TC-4.1.7: Above Pro (Cap)

Given: Hit-rate = 100%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score the hit-rate.

Then:

Uncapped = 3.5 + 1.5 × (100 − 70) / (90 − 70) = 5.75. Hard cap applies.

Expected: 5.0.

4.2 Grid — Bunkers Direction (Different Anchors)

Anchors: Min=10, Scratch=50, Pro=70.

TC-4.2.1: Below Min — Bunkers

Given: Hit-rate = 5%. Anchors: Min=10, Scratch=50, Pro=70.

When: Score the hit-rate.

Then:

5 < 10 (below Min). Case 1.

Expected: 0.0.

TC-4.2.2: Mid-Range — Bunkers

Given: Hit-rate = 30%. Anchors: Min=10, Scratch=50, Pro=70.

When: Score the hit-rate.

Then:

Score = 3.5 × (30 − 10) / (50 − 10) = 3.5 × 20 / 40 = 1.75.

Expected: 1.75.

TC-4.2.3: Above Scratch — Bunkers

Given: Hit-rate = 60%. Anchors: Min=10, Scratch=50, Pro=70.

When: Score the hit-rate.

Then:

Score = 3.5 + 1.5 × (60 − 50) / (70 − 50) = 3.5 + 1.5 × 0.5 = 4.25.

Expected: 4.25.

4.3 Raw Data Entry — Driving Carry

Anchors: Min=180, Scratch=250, Pro=300. Per-Instance scoring (each Instance scored individually).

TC-4.3.1: Below Min

Given: Raw = 160 yards. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

160 < 180. Case 1.

Expected: 0.0.

TC-4.3.2: At Min

Given: Raw = 180. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

Score = 3.5 × (180 − 180) / (250 − 180) = 0.0.

Expected: 0.0.

TC-4.3.3: Quarter Between Min and Scratch

Given: Raw = 197.5. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

Score = 3.5 × (197.5 − 180) / (250 − 180) = 3.5 × 17.5 / 70 = 0.875.

Expected: 0.875.

TC-4.3.4: At Scratch

Given: Raw = 250. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

Score = 3.5 × (250 − 180) / (250 − 180) = 3.5.

Expected: 3.5.

TC-4.3.5: Between Scratch and Pro

Given: Raw = 275. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

Score = 3.5 + 1.5 × (275 − 250) / (300 − 250) = 3.5 + 0.75 = 4.25.

Expected: 4.25.

TC-4.3.6: At Pro

Given: Raw = 300. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

Score = 3.5 + 1.5 × (300 − 250) / (300 − 250) = 5.0.

Expected: 5.0.

TC-4.3.7: Above Pro

Given: Raw = 320. Anchors: Min=180, Scratch=250, Pro=300.

When: Score Instance.

Then:

Uncapped = 3.5 + 1.5 × (320 − 250) / (300 − 250) = 5.6. Hard cap.

Expected: 5.0.

4.4 Raw Data Entry — Ball Speed

Anchors: Min=130, Scratch=155, Pro=170.

TC-4.4.1: Mid-Range — Ball Speed

Given: Raw = 142.5 mph. Anchors: Min=130, Scratch=155, Pro=170.

When: Score Instance.

Then:

Score = 3.5 × (142.5 − 130) / (155 − 130) = 3.5 × 12.5 / 25 = 1.75.

Expected: 1.75.

TC-4.4.2: Above Scratch — Ball Speed

Given: Raw = 162.5. Anchors: Min=130, Scratch=155, Pro=170.

When: Score Instance.

Then:

Score = 3.5 + 1.5 × (162.5 − 155) / (170 − 155) = 3.5 + 0.75 = 4.25.

Expected: 4.25.

4.5 Binary Hit/Miss

Identical scoring mechanic to Grid Cell Selection. Anchors: Min=30, Scratch=70, Pro=90.

TC-4.5.1: 6 of 10 Hits

Given: 6 Hits, 4 Misses. Hit-rate = 60%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score Session.

Then:

Score = 3.5 × (60 − 30) / (70 − 30) = 3.5 × 0.75 = 2.625.

Expected: 2.625.

TC-4.5.2: All Hits

Given: 10 Hits, 0 Misses. Hit-rate = 100%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score Session.

Then:

Uncapped = 5.75. Hard cap.

Expected: 5.0.

TC-4.5.3: Zero Hits

Given: 0 Hits, 10 Misses. Hit-rate = 0%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score Session.

Then:

0 < 30. Case 1.

Expected: 0.0.

4.6 User Custom Drill — Non-Standard Anchors

User Custom Drill for Irons Distance Control. Anchors: Min=20, Scratch=50, Pro=75.

TC-4.6.1: Custom Anchors — Mid-Range

Given: Hit-rate = 35%. Anchors: Min=20, Scratch=50, Pro=75.

When: Score.

Then:

Score = 3.5 × (35 − 20) / (50 − 20) = 3.5 × 15 / 30 = 1.75.

Expected: 1.75.

TC-4.6.2: Custom Anchors — Above Scratch

Given: Hit-rate = 62.5%. Anchors: Min=20, Scratch=50, Pro=75.

When: Score.

Then:

Score = 3.5 + 1.5 × (62.5 − 50) / (75 − 50) = 3.5 + 0.75 = 4.25.

Expected: 4.25.

5. Session Scoring Test Cases

Session score = simple average of all Instance 0–5 scores across all Sets. Set boundaries have no weighting effect. For grid and binary drills, the Session produces a single 0–5 score from the aggregate hit-rate.

5.1 Grid Drill — Single Set

TC-5.1.1: Grid Drill Session Score

Given: Irons Direction drill (1×10). 7 Centre, 2 Left, 1 Right. Hit-rate = 70%. Anchors: Min=30, Scratch=70, Pro=90.

When: Score Session.

Then:

Hit-rate 70% → Score = 3.5 (at Scratch).

Session score = 3.5.

Expected: 3.5.

5.2 Raw Data Entry — Per-Instance Averaging

Driving Carry drill (1×10). Anchors: Min=180, Scratch=250, Pro=300.

TC-5.2.1: 10 Instances with Varied Values

Given: 10 Instances: 200, 230, 250, 260, 270, 240, 255, 280, 245, 220.

When: Score each Instance, then compute Session average.

Then:

200 → 3.5 × 20/70 = 1.0

230 → 3.5 × 50/70 = 2.5

250 → 3.5 (at Scratch)

260 → 3.5 + 1.5 × 10/50 = 3.8

270 → 3.5 + 1.5 × 20/50 = 4.1

240 → 3.5 × 60/70 = 3.0

255 → 3.5 + 1.5 × 5/50 = 3.65

280 → 3.5 + 1.5 × 30/50 = 4.4

245 → 3.5 × 65/70 = 3.25

220 → 3.5 × 40/70 = 2.0

Sum = 1.0 + 2.5 + 3.5 + 3.8 + 4.1 + 3.0 + 3.65 + 4.4 + 3.25 + 2.0 = 31.2.

Session score = 31.2 / 10 = 3.12.

Expected: 3.12.

Note: The per-Instance values shown (e.g. 3.8, 4.1, 3.65) are exact results of the interpolation formula under float64 arithmetic, not display-rounded approximations. For example, 3.5 + 1.5 × 10/50 = 3.8 exactly in float64. All values in this test case are rational numbers with exact float64 representations.

5.3 Multi-Set Structured Drill

User Custom Drill, 3×5 structure. Driving Carry anchors: Min=180, Scratch=250, Pro=300.

TC-5.3.1: Flat Average Across All Sets

Given: Set 1: 250, 260, 270, 240, 255. Set 2: 200, 210, 230, 220, 215. Set 3: 280, 290, 300, 285, 295.

When: Score all 15 Instances. Compute single flat Session average.

Then:

Set 1 scores: 3.5, 3.8, 4.1, 3.0, 3.65. Subtotal = 18.05.

Set 2: 200→1.0, 210→3.5×30/70=1.5, 230→2.5, 220→2.0, 215→3.5×35/70=1.75. Subtotal = 8.75.

Set 3: 280→4.4, 290→3.5+1.5×40/50=4.7, 300→5.0, 285→3.5+1.5×35/50=4.55, 295→3.5+1.5×45/50=4.85. Subtotal = 23.5.

Total = 18.05 + 8.75 + 23.5 = 50.3.

Session score = 50.3 / 15 = 3.353333333333333.

Expected: 3.353333333333333 (repeating).

5.4 Single Instance — Unstructured

TC-5.4.1: Single Instance Valid for Scoring

Given: Unstructured Driving Carry. 1 Instance: 265 yards.

When: Score Instance. Session score = that Instance's score.

Then:

Score = 3.5 + 1.5 × (265 − 250) / (300 − 250) = 3.5 + 0.45 = 3.95.

Session score = 3.95.

Expected: 3.95.

6. Window Composition Test Cases

Each subskill maintains two windows (Transition, Pressure) of 25 occupancy units. Sessions ordered by CompletionTimestamp DESC, SessionID DESC. Occupancy = 1.0 single-mapped, 0.5 dual-mapped.

6.1 Basic Window Fill

TC-6.1.1: 5 Single-Mapped Sessions

Given: 5 Sessions for irons_direction_control (Transition), single-mapped (1.0 each). Scores: S1=3.5, S2=4.0, S3=2.5, S4=3.0, S5=4.25 (newest).

When: Compose Transition window.

Then:

Entries: S5(4.25,1.0), S4(3.0,1.0), S3(2.5,1.0), S2(4.0,1.0), S1(3.5,1.0).

TotalOccupancy = 5.0.

WeightedSum = 4.25 + 3.0 + 2.5 + 4.0 + 3.5 = 17.25.

WindowAverage = 17.25 / 5.0 = 3.45.

Expected WindowAverage: 3.45.

6.2 Full Window — 25 Units

TC-6.2.1: 25 Sessions, All Score 3.0

Given: 25 single-mapped Sessions, all score 3.0, occupancy 1.0 each.

When: Compose window.

Then:

TotalOccupancy = 25.0. WeightedSum = 75.0. WindowAverage = 75.0 / 25.0 = 3.0.

Expected WindowAverage: 3.0.

6.3 Overflow — Eviction

TC-6.3.1: 26th Session Evicts Oldest

Given: 25 Sessions fill window (1.0 each, all score 3.0). S1 is oldest. S26 arrives with score 5.0.

When: Compose window.

Then:

S1 evicted. Window: S26(5.0,1.0) + S25..S2 (24×3.0, 1.0 each).

TotalOccupancy = 25.0.

WeightedSum = 5.0 + 72.0 = 77.0.

WindowAverage = 77.0 / 25.0 = 3.08.

Expected WindowAverage: 3.08.

6.4 Dual-Mapped — 0.5 Occupancy

TC-6.4.1: Dual-Mapped Session in Both Windows

Given: User Custom Shared drill maps to irons_distance_control and irons_direction_control (Transition). Session score = 4.0.

When: Insert into both windows.

Then:

irons_distance_control Transition: entry score=4.0, occupancy=0.5.

irons_direction_control Transition: entry score=4.0, occupancy=0.5.

Expected occupancy per window: 0.5. Expected score in each: 4.0.

6.5 Mixed Occupancy

TC-6.5.1: Window with 1.0 and 0.5 Entries

Given: irons_direction_control Transition: 3 single-mapped (1.0, scores 3.0, 3.5, 4.0) + 2 dual-mapped (0.5, scores 2.5, 4.5). Newest first.

When: Compose window.

Then:

TotalOccupancy = 3×1.0 + 2×0.5 = 4.0.

WeightedSum = 3.0 + 3.5 + 4.0 + (2.5×0.5) + (4.5×0.5) = 10.5 + 1.25 + 2.25 = 14.0.

WindowAverage = 14.0 / 4.0 = 3.5.

Expected WindowAverage: 3.5.

6.6 Boundary — 0.5 Fits, 1.0 Does Not

TC-6.6.1: At 24.5 Occupancy

Given: Window has 24.5 units. Next candidates by timestamp: Session A (1.0 occupancy, score 4.0, more recent) then Session B (0.5 occupancy, score 3.0, older).

When: Evaluate inclusion.

Then:

Session A: 24.5 + 1.0 = 25.5 > 25.0 → excluded.

Session B: 24.5 + 0.5 = 25.0 ≤ 25.0 → included.

Final TotalOccupancy = 25.0.

Session A is excluded despite being more recent than Session B.

Expected: Session B included, Session A excluded.

6.7 Partial Roll-Off: 1.0 Entry Reduced to 0.5

Section 1 (§1.10) defines that when a new entry would overflow, the oldest entry's occupancy is reduced in 0.5 increments. A 1.0 entry can be reduced to 0.5 with the original score preserved.

TC-6.7.1: 1.0 Entry Partially Rolled Off to 0.5

Given: Window has 25.0 occupancy (25 single-mapped Sessions, 1.0 each). Oldest Session S1 has score 2.0. New Session S26 arrives (dual-mapped, 0.5 occupancy, score 4.5).

When: Roll off 0.5 from S1, then insert S26.

Then:

S1 occupancy reduced from 1.0 to 0.5. S1 score remains 2.0 (unchanged).

S26 inserted with occupancy 0.5.

TotalOccupancy = 0.5 + (24 × 1.0) + 0.5 = 25.0.

WeightedSum: S1 contributes 2.0 × 0.5 = 1.0 (was 2.0 × 1.0 = 2.0). S26 contributes 4.5 × 0.5 = 2.25.

Net change to WeightedSum: −1.0 + 2.25 = +1.25.

If prior WeightedSum = 75.0, new WeightedSum = 75.0 − 1.0 + 2.25 = 76.25.

WindowAverage = 76.25 / 25.0 = 3.05.

Expected WindowAverage: 3.05. Expected S1 score: 2.0 (unchanged). Expected S1 occupancy: 0.5.

TC-6.7.2: Full Roll-Off: 0.5 Entry Removed Entirely

Given: Window has 25.0 occupancy. Oldest entry S1 has occupancy 0.5 (dual-mapped), score 2.0. New Session S26 arrives (single-mapped, 1.0 occupancy, score 4.0). 0.5 units must be freed, but S1 is already 0.5.

When: Remove S1 entirely (0.5 is minimum; cannot subdivide). Then check if S26 fits.

Then:

After removing S1: TotalOccupancy = 24.5. S26 (1.0): 24.5 + 1.0 = 25.5 > 25.0 → still does not fit.

Next oldest entry S2 must also be partially rolled off. If S2 is 1.0 occupancy: reduce to 0.5, freeing 0.5 more.

After S2 reduction: TotalOccupancy = 24.0. S26 (1.0): 24.0 + 1.0 = 25.0 ≤ 25.0 → included.

Expected: S1 removed, S2 reduced to 0.5 (score preserved), S26 included. TotalOccupancy = 25.0.

TC-6.7.3: 0.5 Entry Swapped for 0.5 Entry — No Cascade

Given: Window has 25.0 occupancy. Oldest entry S1 has occupancy 0.5 (dual-mapped), score 2.0. New Session S26 arrives (dual-mapped, 0.5 occupancy, score 4.0).

When: Remove S1 (0.5), insert S26 (0.5).

Then:

After removing S1: TotalOccupancy = 24.5. S26 (0.5): 24.5 + 0.5 = 25.0 ≤ 25.0 → included.

No cascading needed. Single removal, single insertion.

If prior WeightedSum = 75.0, new WeightedSum = 75.0 − (2.0×0.5) + (4.0×0.5) = 75.0 − 1.0 + 2.0 = 76.0.

WindowAverage = 76.0 / 25.0 = 3.04.

Expected WindowAverage: 3.04. Expected S1: removed. Expected S26: occupancy 0.5.

6.8 Deterministic Ordering — Identical Timestamps

TC-6.8.1: Tiebreak on SessionID DESC

Given: Sessions S-AAA and S-ZZZ have identical CompletionTimestamp. S-ZZZ is lexicographically later. Both single-mapped to irons_direction_control (Transition).

When: Compose window with ORDER BY CompletionTimestamp DESC, SessionID DESC.

Then:

S-ZZZ appears before S-AAA in window.

Expected ordering: [S-ZZZ, S-AAA].

SessionID comparison uses canonical UUID string lexicographic order (RFC 4122 lowercase hex with hyphens). This is consistent across Postgres (uuid type), SQLite (text), and Dart (String.compareTo). All platforms must use the same string-based comparison to guarantee cross-device convergence at window boundaries.

7. Subskill Scoring Test Cases

SubskillPoints = Allocation × (WeightedAverage / 5). WeightedAverage = (TransitionAvg × 0.35) + (PressureAvg × 0.65).

TC-7.1.1: Both Windows Populated

Given: irons_direction_control. Allocation=110. TransitionAvg=3.5. PressureAvg=4.0.

When: Compute SubskillPoints.

Then:

WeightedAvg = (3.5 × 0.35) + (4.0 × 0.65) = 1.225 + 2.6 = 3.825.

SubskillPoints = 110 × (3.825 / 5) = 110 × 0.765 = 84.15.

Expected: 84.15.

TC-7.1.2: Transition Only — Empty Pressure

Given: Allocation=110. TransitionAvg=3.5. PressureAvg=0.0.

When: Compute SubskillPoints.

Then:

WeightedAvg = (3.5 × 0.35) + (0.0 × 0.65) = 1.225.

SubskillPoints = 110 × (1.225 / 5) = 110 × 0.245 = 26.95.

Expected: 26.95.

Note: Maximum Transition-only = Allocation × 0.35 = 38.5 (at 5.0 TransitionAvg).

TC-7.1.3: Pressure Only — Empty Transition

Given: Allocation=110. TransitionAvg=0.0. PressureAvg=4.0.

When: Compute SubskillPoints.

Then:

WeightedAvg = 0.0 + (4.0 × 0.65) = 2.6.

SubskillPoints = 110 × (2.6 / 5) = 110 × 0.52 = 57.2.

Expected: 57.2.

TC-7.1.4: Both Empty

Given: Allocation=110. TransitionAvg=0.0. PressureAvg=0.0.

When: Compute SubskillPoints.

Then:

WeightedAvg = 0.0. SubskillPoints = 0.0.

Expected: 0.0.

TC-7.1.5: Perfect Score

Given: Allocation=110. TransitionAvg=5.0. PressureAvg=5.0.

When: Compute SubskillPoints.

Then:

WeightedAvg = 1.75 + 3.25 = 5.0. SubskillPoints = 110 × 1.0 = 110.0.

Expected: 110.0 (equals Allocation).

TC-7.1.6: Small Allocation — Woods Shape Control

Given: Allocation=10. TransitionAvg=3.0. PressureAvg=4.0.

When: Compute SubskillPoints.

Then:

WeightedAvg = (3.0 × 0.35) + (4.0 × 0.65) = 1.05 + 2.6 = 3.65.

SubskillPoints = 10 × (3.65 / 5) = 10 × 0.73 = 7.3.

Expected: 7.3.

8. Skill Area Scoring Test Cases

SkillAreaScore = sum of SubskillPoints for all subskills in the Skill Area.

TC-8.1.1: Irons — All Subskills Populated

Given: Distance Control: 84.15. Direction Control: 84.15. Shape Control (Alloc=60, WeightedAvg=3.0): 60 × 0.6 = 36.0.

When: Compute Irons SkillAreaScore.

Then:

SkillAreaScore = 84.15 + 84.15 + 36.0 = 204.3.

Expected: 204.3. Max possible: 280.

TC-8.1.2: Irons — One Subskill Empty

Given: Distance Control: 84.15. Direction Control: 84.15. Shape Control: 0.0.

When: Compute Irons SkillAreaScore.

Then:

SkillAreaScore = 84.15 + 84.15 + 0.0 = 168.3.

Expected: 168.3. No redistribution.

TC-8.1.3: Bunkers — Two Subskills

Given: Distance Control (Alloc=15, WeightedAvg=3.5): 15 × 0.7 = 10.5. Direction Control (Alloc=15, WeightedAvg=4.0): 15 × 0.8 = 12.0.

When: Compute Bunkers SkillAreaScore.

Then:

SkillAreaScore = 10.5 + 12.0 = 22.5.

Expected: 22.5. Max possible: 30.

9. Overall SkillScore Test Cases

OverallScore = sum of all 7 SkillAreaScores. Maximum = 1000.

TC-9.1.1: All Areas Populated

Given: Irons=204.3, Driving=180.0, Putting=140.0, Pitching=70.0, Chipping=65.0, Woods=35.0, Bunkers=22.5.

When: Compute OverallScore.

Then:

OverallScore = 204.3 + 180.0 + 140.0 + 70.0 + 65.0 + 35.0 + 22.5 = 716.8.

Expected: 716.8.

TC-9.1.2: Single Subskill Only

Given: One Session for irons_direction_control (Transition), score 3.5. All else empty.

When: Compute OverallScore.

Then:

TransitionAvg=3.5, PressureAvg=0.0. WeightedAvg=1.225. SubskillPoints=110×0.245=26.95.

Irons SkillArea=26.95. All others=0.

OverallScore = 26.95.

Expected: 26.95.

TC-9.1.3: Perfect 1000

Given: All 19 subskills have WeightedAvg = 5.0.

When: Compute OverallScore.

Then:

Every SubskillPoints = Allocation. Sum of allocations = 1000.

Expected: 1000.0.

TC-9.1.4: Zero — No Data

Given: No Sessions. All windows empty.

When: Compute OverallScore.

Then:

All SubskillPoints = 0. All SkillAreas = 0.

Expected: 0.0.

10. Reflow Scenarios

Reflow triggers a pure rebuild from raw Instance data. These tests verify anchor edits, deletions, and rebuilds produce correct results.

10.1 Anchor Edit — Single Subskill

TC-10.1.1: Anchor Edit Recalculates Historical Scores

Given: User Custom Drill, irons_direction_control (Transition). Original anchors: Min=30, Scratch=70, Pro=90. 3 Sessions in window with hit-rates: 50%, 70%, 80%. User edits anchors to: Min=20, Scratch=60, Pro=80.

When: Reflow. Recompute all scores with new anchors.

Then:

Original scores: 50%→1.75, 70%→3.5, 80%→4.25. Original WindowAvg = 9.5/3.0 = 3.166666666666667.

New scores with Min=20, Scratch=60, Pro=80:

50% → 3.5 × (50−20)/(60−20) = 3.5 × 30/40 = 2.625.

70% → 3.5 + 1.5 × (70−60)/(80−60) = 3.5 + 0.75 = 4.25.

80% → 3.5 + 1.5 × (80−60)/(80−60) = 3.5 + 1.5 = 5.0.

New WindowAvg = (2.625 + 4.25 + 5.0) / 3.0 = 11.875 / 3.0 = 3.958333333333333.

New WeightedAvg (Transition only, Pressure=0): 3.958333333333333 × 0.35 = 1.385416666666667.

New SubskillPoints = 110 × (1.385416666666667 / 5) = 110 × 0.277083333333333 = 30.479166666666667.

IntegritySuppressed reset to false on all 3 Sessions.

Expected WindowAvg: 3.958333333333333. Expected SubskillPoints: 30.479166666666667.

10.2 Session Deletion

TC-10.2.1: Deleting a Session Recomposes Window

Given: irons_direction_control Transition: S1=2.0, S2=3.0, S3=4.0, S4=3.5, S5=3.5 (all 1.0 occupancy). WindowAvg = 16.0/5.0 = 3.2. User deletes S3.

When: Reflow. Window recomposed.

Then:

Remaining: S1=2.0, S2=3.0, S4=3.5, S5=3.5.

TotalOccupancy = 4.0. WeightedSum = 2.0+3.0+3.5+3.5 = 12.0.

WindowAverage = 12.0/4.0 = 3.0.

Expected WindowAverage: 3.0.

10.3 Deletion — Window Backfill

TC-10.3.1: Deletion Admits Previously Evicted Session

Given: Full window (25 sessions, 1.0 each, scores all 3.0). S0 was evicted (oldest, score 4.5). User deletes S15 (score 3.0).

When: Reflow. Window recomposed from all remaining Closed Sessions.

Then:

24 Sessions remain in window candidates. S0 is now within 25-unit cap.

New window: 24 remaining + S0 = 25 sessions, 25.0 occupancy.

WeightedSum = (24 × 3.0) + 4.5 = 72.0 + 4.5 = 76.5.

WindowAverage = 76.5 / 25.0 = 3.06.

Expected WindowAverage: 3.06.

10.4 Dual-Mapped Reflow Scope

TC-10.4.1: Two Subskills Affected

Given: User Custom Shared drill maps to irons_distance_control and irons_direction_control. Anchor edit.

When: Reflow determines scope.

Then:

Both irons_distance_control and irons_direction_control windows rebuilt.

Both SubskillScores recalculated. Irons SkillArea and Overall recalculated.

Driving, Putting, Pitching, Chipping, Woods, Bunkers unchanged.

Expected: exactly 2 subskills in affected scope.

10.5 Full Rebuild Convergence

TC-10.5.1: Full Rebuild Produces Identical Results

Given: Complete scoring state exists. Sync merge completes with no new data.

When: executeFullRebuild(). All materialised tables truncated and rebuilt.

Then:

All 38 materialised rows (19 subskills × 2 practice types) recomposed.

All 19 SubskillScores recomputed. All 7 SkillAreaScores recomputed. OverallScore recomputed.

For every numeric column in every materialised row: |pre_value − post_value| < 1e-9.

Non-numeric columns (SubskillID, PracticeType, UserID) are byte-equal.

Expected: deterministic equality per §2.4 definition.

10.6 Interrupted Reflow — Idempotent Re-Run

TC-10.6.1: Crash Recovery Produces Identical Output

Given: Reflow A completes successfully, producing materialised state M_A. The same raw data and anchors exist. Reflow B is triggered (simulating crash recovery after lock expiry).

When: Reflow B re-runs the full pipeline.

Then:

Reflow B produces materialised state M_B.

For every row and column: |M_A − M_B| < 1e-9 (numeric) or byte-equal (non-numeric).

Expected: M_A and M_B are identical per §2.4.

10.7 Post-Sync Dual-Device Convergence

TC-10.7.1: Two Devices Converge After Sync

Given: Device A and Device B both complete sync and hold identical raw data (Sessions, Instances, Drills, anchors). Both execute executeFullRebuild() independently.

When: Compare materialised state from Device A and Device B.

Then:

For every materialised row: |value_A − value_B| < 1e-9.

Window membership is identical (same SessionIDs in same order).

WindowAverages, SubskillPoints, SkillAreaScores, OverallScore all within tolerance.

Expected: deterministic equality per §2.4.

11. Edge Cases

TC-11.1.1: Technique Block — No Window Entry

Given: User completes an Irons Technique Block Session (30 minutes).

When: Scoring pipeline processes Session close.

Then:

No 0–5 score calculated. No window entry. No SubskillPoints change. No reflow.

Session persisted for Calendar completion matching only.

Expected: zero scoring impact.

TC-11.1.2: Soft-Deleted Session Excluded

Given: S3 in irons_direction_control Transition window, score 4.0, occupancy 1.0. S3 soft-deleted (IsDeleted=true).

When: Reflow recomposes window.

Then:

S3 excluded (IsDeleted=true). Window recomposes without S3.

If prior window had 5 entries totalling 16.0 WeightedSum / 5.0 occupancy = 3.2 avg,

new window has 4 entries: WeightedSum = 16.0 − 4.0 = 12.0, TotalOccupancy = 4.0.

Expected WindowAverage: 12.0 / 4.0 = 3.0.

TC-11.1.3: Zero Hit-Rate

Given: Irons Direction drill. 10 Instances, 0 Centre hits. Hit-rate = 0%. Anchors Min=30.

When: Score Session.

Then:

0 < 30. Case 1. Score = 0.0. Session enters window with score 0.0.

Expected: 0.0.

TC-11.1.4: Post-Close Edit Triggers Reflow

Given: Closed unstructured Driving Carry Session. 5 Instances: 250, 260, 270, 240, 255. Scores: 3.5, 3.8, 4.1, 3.0, 3.65. Session score = 18.05/5 = 3.61. User edits Instance 3 from 270 to 290.

When: Reflow. Recompute from raw data.

Then:

Instance 3 new score: 3.5 + 1.5 × (290−250)/(300−250) = 3.5 + 1.2 = 4.7.

New Session score = (3.5 + 3.8 + 4.7 + 3.0 + 3.65) / 5 = 18.65 / 5 = 3.73.

Window, Subskill, SkillArea, and Overall recalculated.

Expected Session score: 3.73.

TC-11.1.5: Integrity Flag — No Scoring Impact

Given: Driving Carry Session. One Instance = 600 yards (exceeds HardMaxInput). IntegrityFlag = true.

When: Score Session. Insert into window.

Then:

600 → 3.5 + 1.5 × (600−250)/(300−250) = 3.5 + 10.5 = 14.0 → capped at 5.0.

Session score includes the 5.0 normally. IntegrityFlag has zero scoring effect.

IntegrityFlag does not alter scoring; plausibility validation (HardMaxInput) does not clamp input before interpolation. The scoring cap at 5.0 is purely an interpolation-formula ceiling, applied independently of any validation flag.

Expected: Instance score 5.0. Session enters window normally.

TC-11.1.6: Last Instance Deletion — Auto-Discard

Given: Closed unstructured Session with 1 Instance. User deletes the Instance.

When: Session auto-discards.

Then:

Session hard-deleted. Window entry removed. Reflow fires.

EventLog: SessionAutoDiscarded.

Expected: Session removed from window. Subskill recalculated.

TC-11.1.7: Instance Edit Does Not Change Window Ordering

Given: Closed Session S1, CompletionTimestamp = 2025-06-15T10:00:00Z. User edits an Instance's RawMetric value.

When: Verify CompletionTimestamp is immutable.

Then:

CompletionTimestamp remains 2025-06-15T10:00:00Z after edit.

Window ordering unchanged. Session's position relative to other Sessions is preserved.

Expected: CompletionTimestamp immutable. Window order unchanged.

12. Multi-Output Mode Test Cases

Multi-Output 3×3 grid drills are deferred to a future release for System Drills, but the engine must support Multi-Output from launch for User Custom Drills. These test cases compute through to SubskillPoints.

TC-12.1.1: 3×3 Grid — Independent Scores Through to SubskillPoints

Given: User Custom Multi-Output drill for Irons. Maps to irons_direction_control and irons_distance_control (Transition). Direction anchors: Min=30, Scratch=70, Pro=90. Distance anchors: Min=30, Scratch=70, Pro=90. 10 Instances: Centre(3), Top-Centre(1), Bottom-Centre(1), Left-Ideal(1), Right-Ideal(1), Top-Left(1), Top-Right(1), Bottom-Left(1). This is the only Session for these subskills. Pressure windows empty.

When: Calculate independent scores and propagate to SubskillPoints.

Then:

Direction hits (centre column): Centre(3) + Top-Centre(1) + Bottom-Centre(1) = 5. Hit-rate = 50%.

Distance hits (middle row): Centre(3) + Left-Ideal(1) + Right-Ideal(1) = 5. Hit-rate = 50%.

Direction score = 3.5 × (50−30)/(70−30) = 1.75.

Distance score = 3.5 × (50−30)/(70−30) = 1.75.

irons_direction_control Transition window: entry score=1.75, occupancy=0.5. WindowAvg=1.75.

irons_distance_control Transition window: entry score=1.75, occupancy=0.5. WindowAvg=1.75.

irons_direction_control: WeightedAvg = (1.75×0.35)+(0×0.65) = 0.6125. Points = 110×(0.6125/5) = 13.475.

irons_distance_control: WeightedAvg = 0.6125. Points = 110×(0.6125/5) = 13.475.

Irons SkillArea = 13.475 + 13.475 + 0 (shape) = 26.95.

OverallScore = 26.95.

Expected direction score: 1.75. Expected distance score: 1.75.

Expected irons_direction_control SubskillPoints: 13.475.

Expected irons_distance_control SubskillPoints: 13.475.

Expected OverallScore: 26.95.

TC-12.1.2: 3×3 Grid — Asymmetric Performance

Given: Same drill. 10 Instances: Centre(5), Left-Ideal(3), Top-Right(2). Same anchors. Only Session for these subskills. Pressure empty.

When: Calculate independent scores and propagate.

Then:

Direction hits: Centre(5) = 5. Hit-rate = 50%.

Distance hits: Centre(5) + Left-Ideal(3) = 8. Hit-rate = 80%.

Direction score = 3.5 × (50−30)/(70−30) = 1.75.

Distance score = 3.5 + 1.5 × (80−70)/(90−70) = 4.25.

irons_direction_control: WindowAvg=1.75. WeightedAvg=0.6125. Points=13.475.

irons_distance_control: WindowAvg=4.25. WeightedAvg=4.25×0.35=1.4875. Points=110×(1.4875/5)=32.725.

Irons SkillArea = 13.475 + 32.725 + 0 = 46.2.

OverallScore = 46.2.

Expected direction SubskillPoints: 13.475.

Expected distance SubskillPoints: 32.725.

Expected OverallScore: 46.2.

13. Anchor Validation Test Cases

Anchors must satisfy Min < Scratch < Pro (strictly increasing). The validation layer must reject invalid anchor configurations before they reach the scoring engine.

TC-13.1.1: Valid Anchors — Accepted

Given: User creates drill with Min=30, Scratch=70, Pro=90.

When: Validate anchor configuration.

Then:

30 < 70 < 90. Strictly increasing.

Expected: validation passes.

TC-13.1.2: Min = Scratch — Rejected (Division by Zero)

Given: User creates drill with Min=50, Scratch=50, Pro=90.

When: Validate anchor configuration.

Then:

50 = 50. Not strictly increasing. Formula denominator (scratch − min) = 0.

Expected: VALIDATION_INVALID_ANCHORS. Drill not created.

TC-13.1.3: Scratch = Pro — Rejected (Division by Zero)

Given: User creates drill with Min=30, Scratch=70, Pro=70.

When: Validate anchor configuration.

Then:

70 = 70. Not strictly increasing. Formula denominator (pro − scratch) = 0.

Expected: VALIDATION_INVALID_ANCHORS. Drill not created.

TC-13.1.4: Min > Scratch — Rejected

Given: User creates drill with Min=80, Scratch=50, Pro=90.

When: Validate anchor configuration.

Then:

80 > 50. Not strictly increasing.

Expected: VALIDATION_INVALID_ANCHORS.

TC-13.1.5: Scratch > Pro — Rejected

Given: User creates drill with Min=30, Scratch=90, Pro=70.

When: Validate anchor configuration.

Then:

90 > 70. Not strictly increasing.

Expected: VALIDATION_INVALID_ANCHORS.

TC-13.1.6: All Equal — Rejected

Given: User creates drill with Min=50, Scratch=50, Pro=50.

When: Validate anchor configuration.

Then:

Not strictly increasing. Double division-by-zero.

Expected: VALIDATION_INVALID_ANCHORS.

TC-13.1.7: Negative Anchors — Valid if Strictly Increasing

Given: User creates Continuous Measurement drill for lateral deviation. Min=-50, Scratch=0, Pro=25.

When: Validate anchor configuration.

Then:

-50 < 0 < 25. Strictly increasing.

Expected: validation passes.

Scoring: value=-25 → 3.5 × (-25−(-50))/(0−(-50)) = 3.5 × 25/50 = 1.75. Expected: 1.75.

TC-13.1.8: Anchor Edit on Existing Drill — Same Rules

Given: User edits User Custom Drill anchors from Min=30,Scratch=70,Pro=90 to Min=70,Scratch=50,Pro=90.

When: Validate new anchors before applying.

Then:

70 > 50. Not strictly increasing.

Expected: VALIDATION_INVALID_ANCHORS. Edit rejected. No reflow triggered.

14. End-to-End Scoring Scenario

Complete worked example from raw data through to OverallScore. User has data in Irons only.

14.1 Raw Data

irons_direction_control — Transition (3 Sessions, single-mapped, 1.0 each):

Anchors: Min=30, Scratch=70, Pro=90.

Session A: hit-rate 50% → score = 3.5×20/40 = 1.75.

Session B: hit-rate 70% → score = 3.5.

Session C: hit-rate 80% → score = 3.5+1.5×10/20 = 4.25.

irons_direction_control — Pressure (1 Session, User Custom, single-mapped, 1.0):

Same anchors. Session D: hit-rate 60% → score = 3.5×30/40 = 2.625.

irons_distance_control — Transition (2 Sessions, single-mapped, 1.0 each):

Anchors: Min=30, Scratch=70, Pro=90.

Session E: hit-rate 60% → score = 3.5×30/40 = 2.625.

Session F: hit-rate 80% → score = 3.5+1.5×10/20 = 4.25.

irons_distance_control Pressure: empty. irons_shape_control: both windows empty. All other Skill Areas: empty.

14.2 Window Averages

irons_direction_control Transition:

WeightedSum = 1.75 + 3.5 + 4.25 = 9.5. TotalOccupancy = 3.0. WindowAvg = 9.5/3.0 = 3.166666666666667.

irons_direction_control Pressure:

WeightedSum = 2.625. TotalOccupancy = 1.0. WindowAvg = 2.625.

irons_distance_control Transition:

WeightedSum = 2.625 + 4.25 = 6.875. TotalOccupancy = 2.0. WindowAvg = 6.875/2.0 = 3.4375.

irons_distance_control Pressure:

Empty. WindowAvg = 0.0.

14.3 Subskill Scores

irons_direction_control (Allocation = 110):

WeightedAvg = (3.166666666666667 × 0.35) + (2.625 × 0.65) = 1.108333333333333 + 1.70625 = 2.814583333333333.

SubskillPoints = 110 × (2.814583333333333 / 5) = 110 × 0.562916666666667 = 61.920833333333333.

irons_distance_control (Allocation = 110):

WeightedAvg = (3.4375 × 0.35) + (0.0 × 0.65) = 1.203125.

SubskillPoints = 110 × (1.203125 / 5) = 110 × 0.240625 = 26.46875.

irons_shape_control (Allocation = 60):

WeightedAvg = 0.0. SubskillPoints = 0.0.

14.4 Skill Area and Overall Score

Irons SkillAreaScore = 61.920833333333333 + 26.46875 + 0.0 = 88.389583333333333.

All other Skill Areas = 0.0.

OverallScore = 88.389583333333333.

Expected values:

irons_direction_control WindowAvg (Transition): 3.166666666666667.

irons_direction_control WindowAvg (Pressure): 2.625.

irons_direction_control SubskillPoints: 61.920833333333333.

irons_distance_control WindowAvg (Transition): 3.4375.

irons_distance_control SubskillPoints: 26.46875.

Irons SkillAreaScore: 88.389583333333333.

OverallScore: 88.389583333333333.

15. Deferred Items

The following test case categories are explicitly deferred. Each entry identifies the owning document or phase.

Continuous Measurement System Drills (Phase 2, TD-06): No V1 System Drills use Continuous Measurement. The scoring adapter is identical to Raw Data Entry (direct value interpolation). Test cases in §4.3 cover this path via User Custom Drill examples.

Pressure System Drills (Future Section 14 expansion): No V1 System Pressure drills. Pressure window behaviour is tested via User Custom Drill examples (TC-7.1.1, TC-7.1.3, TC-12.1.1, §14 end-to-end).

Cross-device sync reflow convergence — multi-device harness (Phase 7, TD-06): TC-10.7.1 defines the expected outcome. The physical multi-device test harness to execute this test is a Phase 7 deliverable.

Performance envelope tests (TD-06 acceptance criteria): Reflow latency targets (200ms user, 500ms rebuild) are defined in TD-01 §4.2 and validated as TD-06 phase acceptance criteria. TD-05 covers correctness, not performance.

Lock acquisition, retry, and release mechanics (TD-07): UserScoringLock acquisition failure, retry timing, and release-on-failure behaviour are error handling patterns owned by TD-07. TD-05 §10.6 tests idempotent re-run correctness only.

LWW structural resolution (TD-03, Phase 7): Last-Write-Wins merge resolution for structural edits (Drill definitions, club config) is a sync-layer concern. TD-05 tests the scoring pipeline that runs after merge resolution is complete.

16. Dependency Map

TD-05 is consumed by:

TD-06 (Phased Build Plan): Test cases define Phase 2 acceptance criteria. All test cases must pass before Phase 2 is complete. Performance envelope tests are TD-06 acceptance criteria.

TD-07 (Error Handling): Anchor validation test cases (§13) define the validation boundary. Lock/retry/failure mechanics are TD-07 scope.

TD-08 (Claude Code Prompt Architecture): Test case IDs, expected values, and precision policy are referenced in Claude Code prompts for scoring module verification.

End of TD-05 — Scoring Engine Test Cases (TD-05v.a3 Canonical)
