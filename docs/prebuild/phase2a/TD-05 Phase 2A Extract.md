TD-05 Scoring Engine Test Cases — Phase 2A Extract (TD-05v.a3)
Sections: §4 Instance Scoring, §5 Session Scoring, §6 Window Composition, §7 Subskill Scoring, §8 Skill Area Scoring, §9 Overall SkillScore
============================================================

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

