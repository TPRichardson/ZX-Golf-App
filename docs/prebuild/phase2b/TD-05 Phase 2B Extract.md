# TD-05 Scoring Engine Test Cases — Phase 2B Extract (TD-05v.a3)
Sections: §10 Reflow Scenarios, §11 Edge Cases, §12 Determinism Verification
============================================================

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
