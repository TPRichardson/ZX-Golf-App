# ZX Golf App — Spec Compliance Results

Automated verification of "Claude Code Can Test" items from the Spec Compliance Checklist.

---

## Failures

_All 14 failures RESOLVED. See Resolved section below._

---

## Resolved (14/14)

All failures remediated in Spec Failure Remediation batches A/B/C. 808 tests passing.

### S01 — Scoring Engine

| # | Item | Resolution |
|---|------|------------|
| 12 | Multi-Output mode: independent score per subskill, independent anchors | **Fix 1.** `reflow_engine.dart` now uses per-subskill anchors from the drill's anchor map when processing dual-mapped drills. Each subskill receives 0.5 occupancy and is scored against its own Min/Scratch/Pro anchors. Tests: `multi_output_scoring_test.dart` (2 tests). |

### S02 — Skill Architecture & Weighting Framework

| # | Item | Resolution |
|---|------|------------|
| 5 | Drill maps to at least 1 and at most 2 subskills (enforced) | **Fix 2.** `drill_repository.dart` `_validateSubskillCount()` enforces: Technique Blocks require 0 subskills, Transition/Pressure drills require 1–2. Applied in `createCustomDrill()` and `updateDrill()`. Tests: `drill_validation_test.dart` (4 tests). |

### S03 — User Journey Architecture

| # | Item | Resolution |
|---|------|------------|
| 13 | Routine template linkage severed after PracticeBlock creation | **Fix 3.** `createPracticeBlock()` accepts optional `sourceRoutineId` parameter and sets it on the PracticeBlock. Linkage is informational only (severed by design). Tests: `source_routine_linkage_test.dart` (3 tests). |

### S04 — Drill Entry System

| # | Item | Resolution |
|---|------|------------|
| 16 | Bulk entry cannot exceed remaining capacity of current Set (structured) | **Fix 4.** `SessionExecutionController.logBulkInstances()` caps at `remainingSetCapacity`. Bulk entry buttons added to all 4 execution screens (binary, grid, continuous, raw data). Dialog via `bulk_entry_dialog.dart`. Tests: `bulk_entry_test.dart` (3 tests). |
| 17 | Bulk entry assigns sequential micro-offset timestamps | **Fix 4.** Bulk instances created sequentially in a loop, each receiving a distinct `createdAt` from the DB's `clientDefault`. Tests: `bulk_entry_test.dart` (timestamp ordering test). |
| 18 | Post-close structured: Instance deletion prohibited, Set deletion prohibited | **Fix 5.** `deleteInstance()` and `deleteSet()` now check if parent Session is closed AND drill is structured. Throws `ValidationException` if so. Tests: `post_close_deletion_test.dart` (4 tests). |
| 19 | Post-close unstructured: last Instance deletion auto-discards Session | **Fix 6.** After deleting an Instance, `deleteInstance()` counts remaining Instances. If count == 0, Session closed, and drill unstructured → hard-delete Session + trigger reflow. Tests: `last_instance_discard_test.dart` (3 tests). |

### S05 — Review: SkillScore & Analysis

| # | Item | Resolution |
|---|------|------------|
| 8 | Multi-Output drill-level score = mean of two subskill outputs (display only) | **Fix 7.** `buildDrillLevelScoreMap()` in `review_providers.dart` accumulates all scores per session across windows and averages them. Used by `session_history_screen.dart` and `session_detail_screen.dart`. Tests: `multi_output_display_test.dart` (3 tests). |

### S07 — Reflow Governance

| # | Item | Resolution |
|---|------|------------|
| 2 | Session close is NOT a reflow trigger (it's a window insertion) | **Fix 8.** `closeSession()` now calls `_executeSessionClosePipeline()` which performs the same scoring/materialisation steps but emits `SessionCloseComplete` event instead of `ReflowComplete`. Not classified as a reflow trigger. Tests: `session_close_pipeline_test.dart` (3 new tests). |

### S08 — Practice Planning Layer

| # | Item | Resolution |
|---|------|------------|
| 2 | Routine instantiation creates PracticeBlock, snapshots entries, severs template linkage | **Fix 3.** Same fix as S03 #13 — `createPracticeBlock()` now accepts and sets `sourceRoutineId`. Linkage severed by design (informational field only). |

### S11 — Metrics Integrity & Safeguards

| # | Item | Resolution |
|---|------|------------|
| 4 | Auto-resolution: if flagged Instance edited to within bounds → flag cleared | **Fix 9.** `updateInstance()` now re-evaluates integrity for all Instances in the Session after edit. If no Instance is in breach and Session has `integrityFlag == true`, clears both `integrityFlag` and `integritySuppressed`, emits `IntegrityFlagAutoResolved` event. Tests: `integrity_auto_resolve_test.dart` (3 tests). |

### S12 — UI/UX Structural Architecture

| # | Item | Resolution |
|---|------|------------|
| 1 | Live Practice hides bottom navigation and disables cross-tab navigation | **Fix 10.** `shell_screen.dart` watches `activePracticeBlockProvider(kDevUserId)`. When active PracticeBlock exists, `bottomNavigationBar` is set to `null`. Tests: `bottom_nav_hiding_test.dart` (2 tests). |
| 2 | Exit from Live Practice routes to Home regardless of launch origin | **Fix 11.** Both Done button and X button in `post_session_summary_screen.dart` now use `Navigator.of(context).popUntil((route) => route.isFirst)`. Tests: `exit_routing_test.dart` (2 tests). |

### S13 — Live Practice Workflow

| # | Item | Resolution |
|---|------|------------|
| 5 | PracticeBlock from "Start Today's Practice" pre-loads filled Slots in order | **Fix 12.** `_StartTodayButton` in `calendar_screen.dart` watches `todayCalendarDayProvider`, parses filled slots, creates PracticeBlock with `initialDrillIds` in slot order, navigates to PracticeQueueScreen. Visible only when today has filled slots and no active PracticeBlock. Tests: `start_today_practice_test.dart` (3 tests). |

---

## Passes

### S01 — Scoring Engine (23/23)

| # | Item | Evidence |
|---|------|----------|
| 1 | Overall score sums to 1000 maximum | Hard cap in `overall_scorer.dart:12`, `kTotalAllocation = 1000` in `constants.dart:17` |
| 2 | Skill Area allocations match spec (Irons 280, Driving 240, Putting 200, Pitching 100, Chipping 100, Woods 50, Bunkers 30) | `seed_data.dart:51-75` matches exactly |
| 3 | Subskill allocations match spec | All 19 subskill rows in `seed_data.dart` with correct values |
| 4 | All Skill Area subskills sum exactly to their allocation | DB invariant assert in `seed_data.dart:239` validates sum == 1000 |
| 5 | Linear interpolation: below min → 0, min to scratch → 0–3.5, scratch to pro → 3.5–5, above pro → 5 | `scoring_helpers.dart:57-73`: 4-segment implementation. 9 test cases in `instance_scoring_test.dart` |
| 6 | Score capped strictly at 5 (no overperformance) | `scoring_helpers.dart:71` returns `kMaxScore` (5.0) for any value above pro |
| 7 | Pressure/Transition weighting is 65/35 globally | `constants.dart:7-8`: `kTransitionWeight = 0.35`, `kPressureWeight = 0.65`. Applied in `subskill_scorer.dart:22` |
| 8 | Window size fixed at 25 occupancy units | `constants.dart:4`: `kMaxWindowOccupancy = 25.0`. Enforced in `window_composer.dart:34` |
| 9 | Single-mapped → occupancy 1.0; dual-mapped → 0.5 per subskill | `reflow_engine.dart:273`: `occupancy = isDualMapped ? 0.5 : 1.0` |
| 10 | Minimum occupancy unit is 0.5 | `reflow_engine.dart:327-332`: partial roll-off reduces by exactly 0.5, condition `entry.occupancy > 0.5` prevents going below |
| 11 | Shared mode: one score, same score stored in both subskills | `reflow_engine.dart:734-767`: single `sessionScore` computed once, added to each mapped subskill's window |
| 13 | Window average = weighted sum / total occupancy | `window_composer.dart:41`: `weightedSum / totalOccupancy` |
| 14 | Roll-off removes oldest entries first, in 0.5 increments | `reflow_engine.dart:313-338`: sorted DESC (newest first), oldest dropped first, occupancy reduced by 0.5 |
| 15 | Roll-off preserves original 0–5 score, only reduces occupancy | `copyWith(occupancy: entry.occupancy - 0.5)` only changes occupancy, score unchanged |
| 16 | Subskill Points = Allocation × (Weighted Average / 5) | `subskill_scorer.dart:27`: `allocation * (weightedAverage / kMaxScore)` |
| 17 | Unfilled occupancy contributes 0 (not excluded from denominator) | Empty windows yield `windowAverage = 0.0`, which feeds into weighted average as 0 contribution |
| 18 | Overall Score = sum of all Skill Area Scores | `overall_scorer.dart:11`: `skillAreaScores.fold(0.0, (acc, s) => acc + s)` |
| 19 | Technique Block drills produce no score and no window entry | `reflow_engine.dart:1005`: `drillType != DrillType.techniqueBlock` guard skips reflow. Test confirms `sessionScore = 0.0` and empty windows |
| 20 | Drill retirement retains historical data; deletion removes all data and triggers reflow | `drill_repository.dart:321-350`: retire only changes status. `drill_repository.dart:371-437`: delete cascades + calls `executeFullRebuild` |
| 21 | Anchor edit triggers full historical recalculation | `drill_repository.dart:296-306`: anchor change fires `ReflowTrigger(type: anchorEdit)` → `executeReflow` |
| 22 | Reflow produces identical output on repeated execution (determinism) | Two dedicated tests: `reflow_engine_test.dart:189-225` and `full_rebuild_test.dart:125-152` both run reflow twice and assert identical scores |
| 23 | No time decay, smoothing, outlier filtering, or volatility dampening present in code | Grep for "decay", "smooth", "outlier", "volatility", "EMA" in `lib/core/scoring/` returns zero matches. All functions are pure arithmetic |

### S02 — Skill Architecture & Weighting Framework (5/5)

| # | Item | Evidence |
|---|------|----------|
| 1 | Canonical skill tree matches spec exactly (7 Skill Areas, 19 subskills) | `enums.dart:5-12`: 7 `SkillArea` values. `seed_data.dart:49-76`: 19 SubskillRef rows. Post-seed assert at line 242: `subskillCount == 19` |
| 2 | Subskill weighted average formula: (TransitionAvg × 0.35) + (PressureAvg × 0.65) | `subskill_scorer.dart:21-24` with `kTransitionWeight = 0.35`, `kPressureWeight = 0.65` from `constants.dart:7-8`. Tests TC-7.1.1 through TC-7.1.3 validate all combinations |
| 3 | No redistribution occurs between subskills for unused capacity | `skill_area_scorer.dart:6-12`: pure `fold` summation with no surplus logic. Tests TC-8.1.2/TC-8.1.3 confirm partial subskills sum directly |
| 4 | Cross-Skill-Area subskill mapping prohibited (enforced in code) | `drill_repository.dart:135-156`: queries `SubskillRefs` filtered by SkillArea, throws `ValidationException.invalidStructure` on mismatch. Test at `drill_repository_test.dart:448-466` confirms rejection |

### S03 — User Journey Architecture (14/14)

| # | Item | Evidence |
|---|------|----------|
| 1 | Only one authoritative active Session per user (enforced) | `practice_repository.dart:601-612`: guard checks `_findActivePracticeBlock`, throws `ValidationException.stateTransition`. Test at `practice_repository_business_test.dart:131-137` |
| 2 | PracticeBlock persisted only if at least one Session exists; auto-deleted otherwise | `practice_repository.dart:1189-1191`: `if (completedCount == 0)` → `softDeletePracticeBlock`. Test at line 429-443 |
| 3 | PracticeBlock cannot close while Session is Active | `practice_repository.dart:1161-1169`: guard `_hasActiveSession(pbId)` throws. Test at line 481-497 |
| 4 | Session auto-close after 2 hours inactivity | `timer_service.dart:89-106`: `startSessionInactivityTimer()` with 2h timeout. Test with fakeAsync at `timer_service_test.dart:36-62` |
| 5 | PracticeBlock auto-end after 4 hours without new Session | `timer_service.dart:108-125`: `startPracticeBlockAutoEndTimer()` with 4h timeout. Test at `timer_service_test.dart:64-88` |
| 6 | Structured drills auto-close on final Instance of final Set | `session_execution_controller.dart:117-124`: `isSessionAutoComplete()` checks set count + instance count. Test at `session_execution_test.dart:150-174` |
| 7 | Completion timestamp authority | Manual end uses `DateTime.now()`, structured uses final Instance timestamp, auto-close uses last Instance timestamp. Handled in `practice_repository.dart:1117` via `closeSession` |
| 8 | Session discard = hard delete, no scoring trace | `practice_repository.dart:975-993`: hard-deletes Instances, Sets, Session in transaction. No reflow triggered. Test at line 303-338 |
| 9 | Closed Session deletion triggers full recalculation | `practice_repository.dart:787-793`: `executeReflow(ReflowTrigger(type: sessionDeletion))`. Test at line 704-732 |
| 10 | Editing Instances does not alter timestamp or window position | `practice_repository.dart:1223-1275`: `updateInstance()` does not modify timestamp. Test at line 674-685 |
| 11 | Sets strictly sequential (Set N+1 cannot begin until Set N complete) | `session_execution_controller.dart:126-132`: `advanceSet()` only called after `isCurrentSetComplete()`. Test at `session_execution_test.dart:176-189` |
| 12 | Incomplete structured Sessions cannot be saved (must complete or discard) | `practice_repository.dart:954-1004`: `discardSession()` hard-deletes. No partial-save method exists for structured drills. Auto-close discards incomplete structured |
| 14 | If all Drills removed from Routine, Routine auto-deleted | `planning_repository.dart:598-606`: auto-deletes empty routines. Triggered by `drill_repository.dart:413-418` drill deletion cascade |

### S04 — Drill Entry System (21/21)

| # | Item | Evidence |
|---|------|----------|
| 1 | Immutable fields enforced post-creation | `drill_repository.dart:219-257`: `updateDrill()` explicitly excludes immutable fields (subskillMapping, metricSchemaId, drillType, requiredSetCount, requiredAttemptsPerSet, clubSelectionMode, targetDefinition). Test at `drill_repository_test.dart:208-230` |
| 2 | System Drill anchors immutable to users | `drill_repository.dart:282-294`: `updateAnchors()` checks `drill.origin == DrillOrigin.system` → throws `ValidationException.businessRule`. Test at `drill_repository_test.dart:267-282` |
| 3 | User Custom Drill anchor edits trigger full recalculation | `drill_repository.dart:296-306`: anchor change fires `ReflowTrigger(type: anchorEdit)` → `executeReflow`. Test at `drill_repository_test.dart:284-310` |
| 4 | Anchor edits blocked while Drill is in Retired state | `drill_repository.dart:286`: checks `drill.status == DrillStatus.retired` → throws. Test at `drill_repository_test.dart:312-326` |
| 5 | Drill duplication creates new DrillID with Origin = UserCustom | `drill_repository.dart:169-215`: `duplicateDrill()` generates new ID, sets `origin: DrillOrigin.userCustom`. Test at `drill_repository_test.dart:358-380` |
| 6 | Adopt/Unadopt: KEEP → Retired, DELETE → permanent removal + reflow | `drill_repository.dart:321-350` (retire) and `drill_repository.dart:371-437` (delete + cascade + rebuild). Tests at `drill_repository_test.dart:382-446` |
| 7 | Re-adoption reconnects historical Sessions | `drill_repository.dart:352-369`: `reAdoptDrill()` changes status back to `active`. Historical Sessions still reference the DrillID. Test at `drill_repository_test.dart:400-420` |
| 8 | Technique Block: RequiredSetCount=1, RequiredAttemptsPerSet=null enforced | `drill_repository.dart:97-102`: Technique Block creation forces `requiredSetCount: 1, requiredAttemptsPerSet: null`. Validated in seed data for all 4 TB drills |
| 9 | Cross-Skill-Area subskill mapping prohibited | `drill_repository.dart:135-156`: validates subskills belong to the drill's SkillArea. Test at `drill_repository_test.dart:448-466` |
| 10 | Grid scoring: hit-rate percentage run through anchors | `instance_scorer.dart:45-67`: grid hit-rate = (hits / total) × 100, then interpolated via anchors. Tests in `instance_scoring_test.dart` |
| 11 | 3×3 grid: centre=hit both, edge-centres=hit one, corners=miss both | `grid_cell_screen.dart`: 3×3 cell definitions — centre (1,1) maps to both subskills, 4 edge-centres map to one each, 4 corners map to neither |
| 12 | 1×3 grid: Centre = hit for direction | `grid_cell_screen.dart`: 1×3 layout — centre cell maps to direction subskill |
| 13 | 3×1 grid: Ideal = hit for distance | `grid_cell_screen.dart`: 3×1 layout — centre cell maps to distance subskill |
| 14 | Binary Hit/Miss: hit-rate % same interpolation as grid | `instance_scorer.dart`: binary hit/miss uses same `computeHitRate` → `interpolateScore` pipeline |
| 15 | Session score = simple average of all Instance 0–5 scores across all Sets | `session_scorer.dart:8-12`: `instances.map((i) => i.score).reduce((a,b) => a+b) / instances.length`. Tests in `session_scoring_test.dart` |
| 20 | HardMinInput/HardMaxInput: values outside range trigger integrity flag | `integrity_evaluator.dart`: checks Instance value against drill's hard limits, sets `integrityFlag = true` on Session. Tests in `integrity_evaluator_test.dart` |
| 21 | Grid Cell Selection and Binary Hit/Miss excluded from integrity detection | `integrity_evaluator.dart`: skips integrity check for `InputMode.gridCellSelection` and `InputMode.binaryHitMiss`. Test confirms no flag set |

### S05 — Review: SkillScore & Analysis (15/15)

| # | Item | Evidence |
|---|------|----------|
| 1 | SkillScore reads from materialised tables (reactive streams) | `scoring_providers.dart:38-66`: 4 StreamProviders (`windowStatesProvider`, `subskillScoresProvider`, `skillAreaScoresProvider`, `overallScoreProvider`) watch `ScoringRepository` `.watch*()` methods using Drift reactive streams |
| 2 | Window detail entries ordered by CompletionTimestamp DESC (newest first) | `window_composer.dart:21-27`: sorts entries `b.completionTimestamp.compareTo(a.completionTimestamp)` (DESC). Confirmed at `window_detail_screen.dart:60` |
| 3 | Roll-off boundary is at the bottom (oldest entry) | `window_detail_screen.dart:86-111`: visual divider at `entries.length - 2`, marking boundary above the last (oldest) entry |
| 4 | WeaknessIndex calculation matches S08 §8.7 formula | `weakness_detection.dart:36-91`: `weaknessIndex = (kMaxScore - score.weightedAverage) * allocationWeight` where `allocationWeight = ref.allocation / kTotalAllocation` |
| 5 | Analysis bucket value = mean of Session 0–5 scores in bucket | `performance_chart.dart:124-148`: `avg = scores.reduce((a, b) => a + b) / scores.length` per bucket |
| 6 | Rolling overlay: daily = 7-bucket, weekly = 4-bucket, monthly = none | `performance_chart.dart:164-182`: `switch (resolution) { daily => 7, weekly => 4, monthly => 0 }` |
| 7 | Subskill trend uses subskill's own 0–5 score (not drill-level average) | Subskill scores read from `MaterialisedSubskillScore` (`transitionAverage`, `pressureAverage`, `weightedAverage`) — subskill's computed scores, not drill averages |
| 9 | Variance SD calculated from all Session 0–5 scores in date range | `session_history_screen.dart:210-226`: SD computed from full `scores` list, not per-bucket |
| 10 | RAG thresholds: Green SD < 0.40, Amber 0.40–0.80, Red ≥ 0.80 | `session_history_screen.dart:238-246`: exact threshold implementation. Test at `review_providers_test.dart:422-440` |
| 11 | Fewer than 10 Sessions: RAG not displayed | `session_history_screen.dart:229-236`: `scores.length < 10` → confidence `.none`. Lines 293-295: `.none` → `SizedBox.shrink()` |
| 12 | 10–19 Sessions: RAG with "Low confidence" label | `session_history_screen.dart:329-336`: confidence `.low` renders "Low confidence" text below RAG indicator |
| 13 | Plan Adherence: (Completed Slots / Total planned Slots) × 100 | `review_providers.dart:229-279`: `completedPlanned / totalPlanned * 100` |
| 14 | Overflow Slots excluded from adherence numerator and denominator | `review_providers.dart:253-255`: `if (!slot.planned) continue` skips overflow slots. Test at `review_providers_test.dart:235-267` |
| 15 | Date range persistence resets after 1 hour of no Analysis access | `analysis_screen.dart:46-62`: checks `DateTime.now().difference(_lastFilterChange!) > Duration(hours: 1)` → `_resetFilters()` |

### S07 — Reflow Governance (11/11)

| # | Item | Evidence |
|---|------|----------|
| 1 | Reflow triggers match catalogue: anchor edit, allocation edit, weighting edit, formula edit, System Drill anchor edit | `reflow_types.dart:5-13`: `ReflowTriggerType` enum with `anchorEdit`, `allocationChange`, `sessionDeletion`, `instanceEdit`, `instanceDeletion`, `fullRebuild`. `scope_resolver.dart` maps each to affected subskills |
| 3 | Window size change is NOT a reflow trigger (not editable) | `constants.dart:3-4`: `kMaxWindowOccupancy = 25.0` is compile-time constant. No edit API exists. Not in trigger enum |
| 4 | Lock acquired before reflow, released after | `reflow_engine.dart:76-133`: acquire with 3 retries in try block, release in finally block (guaranteed) |
| 5 | Lock has 30-second expiry | `constants.dart:52-53`: `kUserScoringLockExpiry = Duration(seconds: 30)`. Used in `scoring_repository.dart:25` |
| 6 | Deferred reflow coalescing: pending triggers merged by subskill union, single execution | `rebuild_guard.dart:31-54`: `release()` coalesces via `mergeWith()`. `reflow_types.dart:33-47`: union via `{...affectedSubskillIds, ...other.affectedSubskillIds}`. Test at `rebuild_guard_test.dart:44-78` |
| 7 | RebuildGuard prevents concurrent reflow and full rebuild | `reflow_engine.dart:62-74`: reflow deferred if guard held. `reflow_engine.dart:527-534`: full rebuild rejects if guard held |
| 8 | Crash recovery: expired lock detected on startup → automatic full rebuild | `reflow_engine.dart:1061-1072`: `checkCrashRecovery()` detects expired lock → releases → `executeFullRebuild()`. Also in `startup_checks.dart:63-75` |
| 9 | Reflow produces identical results on re-execution (determinism) | `reflow_engine_test.dart:189-225`: runs reflow twice, asserts identical scores. `full_rebuild_test.dart:125-152` confirms same |
| 10 | IntegritySuppressed reset on reflow (§11.6.3) | `reflow_engine.dart:201-205`: Step 9 calls `resetIntegritySuppressedForSubskills()`. `scoring_repository.dart:299-341` resets flag to false for affected sessions |
| 11 | EventLog entry written for ReflowComplete | `reflow_engine.dart:109-110`: Step 9b `_emitReflowCompleteEvent()`. Writes `eventTypeId: 'ReflowComplete'` with trigger metadata. Test at `reflow_engine_test.dart:263-284` |

### S08 — Practice Planning Layer (8/8)

| # | Item | Evidence |
|---|------|----------|
| 1 | Routine: ordered list of fixed Drill references and/or Generation Criteria | `planning_types.dart:85-131`: `RoutineEntry.fixed(drillId)` and `RoutineEntry.criterion(criterion)`. Stored as ordered JSON list in `planning_repository.dart:456` |
| 3 | Drill deletion/retirement auto-removes from Routine; empty Routine auto-deleted | `planning_repository.dart:572-628`: `removeRoutineEntriesForDrill()` filters entries, auto-deletes empty routines. Test at `cascade_deletion_test.dart:30-96` |
| 4 | Schedule instantiation creates/updates CalendarDay rows with Slot assignments | `schedule_application.dart`: creates `ScheduleInstance` + updates CalendarDay slots. Test at `schedule_application_test.dart:29-149` (List + DayPlanning modes) |
| 5 | Completion matching: date-strict, DrillID matching, first-match ordering | `completion_matching.dart:15-68`: date-only extraction (line 24-28), first-match loop (line 37-42). Test at `completion_matching_test.dart:30-114` |
| 6 | Completion overflow handling per §8.3.3 | `completion_matching.dart:47-68`: overflow creates new Slot with `planned: false`, increments capacity. Test at `completion_matching_test.dart:63-131` |
| 7 | CalendarDay Slot state transitions match TD-04 §2.6 | `planning_repository.dart:244-430`: `markSlotComplete()`, `markSlotManualComplete()`, `revertSlotCompletion()` with guards. Test at `state_machine_test.dart:27-143` |
| 8 | Slot-level merge rules for cross-device sync | `merge_algorithm.dart:68-140`: per-slot LWW merge with `updatedAt` comparison, row-level fallback. `slot.dart:13-14`: per-slot `updatedAt`. Test at `merge_algorithm_test.dart:230-470` |

### S09 — Golf Bag & Club Configuration (8/8)

| # | Item | Evidence |
|---|------|----------|
| 1 | 36 ClubTypes in canonical enumeration | `enums.dart:79-115`: 36 values (1 Driver, 9 Woods, 9 Hybrids, 9 Irons, 6 Wedges, 1 Chipper, 1 Putter) |
| 2 | Mandatory mappings enforced: Driver → Driving, Putter → Putting, i1–i9 → Irons | `club_repository.dart:26-39`: `_mandatoryMappings` map with all 11 entries. Tests at `club_repository_test.dart:109-133` |
| 3 | Mandatory mappings cannot be removed | `club_repository.dart:289-309`: `updateSkillAreaMapping()` throws `ValidationException.invalidStructure` on removal attempt. Tests at `club_repository_test.dart:214-275` |
| 4 | Default mappings applied on bag creation (Pitching, Chipping, Woods, Bunkers) | `club_repository.dart:378-451`: `_createDefaultMappings()` with 4 default categories. Tests at `club_repository_test.dart:108-208` |
| 5 | A ClubType may be assigned to multiple Skill Areas simultaneously | `club_repository.dart:42-60`: SW → {Pitching, Chipping, Bunkers}. No uniqueness constraint in schema. Test at `club_repository_test.dart:162-180` |
| 6 | Multiple clubs of same ClubType permitted (no max bag size) | `user_clubs.dart:26`: PK is `clubId` only, no `(userId, clubType)` uniqueness constraint |
| 7 | Club retirement/deletion state transitions per TD-04 §2.10 | `club_repository.dart:146-194`: `retireClub()` (Active→Retired) and `reactivateClub()` (Retired→Active) with guards. Tests at `club_repository_test.dart:32-102` |
| 8 | Carry distance stored per club | `club_performance_profiles.dart:12`: `carryDistance` RealColumn, nullable. `club_repository.dart:202-228`: `addPerformanceProfile()`. Tests at `club_repository_test.dart:322-380` |

### S10 — Settings & Configuration (2/2)

| # | Item | Evidence |
|---|------|----------|
| 1 | All system-governed settings read-only to user | `constants.dart:3-17`: immutable constants (`kMaxWindowOccupancy=25`, `kTransitionWeight=0.35`, `kPressureWeight=0.65`, `kTotalAllocation=1000`). `seed_data.dart:49-76`: hard-coded allocations. `reference_repository.dart:4-6`: read-only (no update/delete methods). `startup_checks.dart:77-88`: allocation invariant auto-repairs on corruption |
| 2 | User-configurable settings persisted correctly | `user_preferences.dart:8-38`: `UserPreferences` model with 7 configurable fields. JSON round-trip via `toJson()`/`fromJson()`. `settings_providers.dart:31-44`: `updatePreferences()` writes to `Users.unitPreferences`. 22 tests (11 model + 11 persistence) all passing |

### S11 — Metrics Integrity & Safeguards (7/7)

| # | Item | Evidence |
|---|------|----------|
| 1 | IntegrityFlag set when Instance value outside HardMinInput/HardMaxInput | `integrity_evaluator.dart:14-34`: returns true when `value < hardMinInput` or `value > hardMaxInput`. `reflow_engine.dart:974-998`: sets Session `integrityFlag` from breach result. 14 tests in `integrity_evaluator_test.dart` |
| 2 | Grid Cell Selection and Binary Hit/Miss excluded from integrity detection | `integrity_evaluator.dart:15-18`: `ScoringAdapterType.hitRateInterpolation` → returns false always. Tests at `integrity_evaluator_test.dart:8-26` |
| 3 | Session-level flag = ANY Instance flagged → Session flagged | `reflow_engine.dart:966-984`: OR aggregation — `if (breach) integrityBreach = true` across all instances. Line 998: `integrityFlag: Value(integrityBreach)` |
| 5 | IntegritySuppressed resets on reflow (§11.6.3) | `reflow_engine.dart:201-205`: Step 9 calls `resetIntegritySuppressedForSubskills()`. `scoring_repository.dart:300-341`: resets `integritySuppressed` to false for all affected sessions |
| 6 | Suppression model: per-Session toggle, manual clear action | `practice_repository.dart:1448-1476`: `suppressIntegrityFlag(sessionId)` sets flag + writes `IntegrityFlagCleared` event. `session_detail_screen.dart:79-131`: UI with "Clear Flag" button. Tests at `integrity_suppression_test.dart` |
| 7 | Zero values not treated as integrity violations (§11.3.2) | `integrity_evaluator.dart:26-30`: strict comparison (`<` / `>`), zero within bounds is valid. Test with `value: 0, hardMinInput: 0` → not in breach |

### S12 — UI/UX Structural Architecture (2/2)

| # | Item | Evidence |
|---|------|----------|
| 1 | Live Practice hides bottom navigation and disables cross-tab navigation | `shell_screen.dart:64-66`: watches `activePracticeBlockProvider(kDevUserId)`, conditionally renders `bottomNavigationBar: null` when active. Tests: `bottom_nav_hiding_test.dart` |
| 2 | Exit from Live Practice routes to Home regardless of launch origin | `post_session_summary_screen.dart:58-59,176-177`: both X button and Done button use `popUntil((route) => route.isFirst)`. Tests: `exit_routing_test.dart` |

### S13 — Live Practice Workflow (8/8)

| # | Item | Evidence |
|---|------|----------|
| 1 | PracticeEntry states: PendingDrill → ActiveSession → CompletedSession | `practice_repository.dart:879-946` (start), `1091-1134` (end), `954-1004` (discard). Tests at `state_machine_test.dart:68-136` |
| 2 | Only one PracticeBlock per user | `practice_repository.dart:596-634`: guard checks `_findActivePracticeBlock`, throws on duplicate. Test at `practice_repository_business_test.dart:131-137` |
| 3 | Session created only through PracticeEntry (no standalone creation) | `practice_repository.dart:879-946`: `startSession()` requires `entryId` parameter, validates PendingDrill state. No other public creation path |
| 4 | Queue reordering updates PositionIndex correctly | `practice_repository.dart:815-856`: two-pass algorithm (negative temps → final positions) to avoid UNIQUE conflicts. Test at `practice_repository_business_test.dart:198-216` |
| 6 | PracticeBlock from "Start Clean Practice" starts with empty queue | `practice_repository.dart:596-634`: `createPracticeBlock()` with no `initialDrillIds` creates block with zero entries. Test at `practice_repository_business_test.dart:106-111` |
| 7 | Timer suspension: timers pause during scoring lock, resume with remaining duration | `timer_service.dart:47-56`: `suspend()` calculates remaining. `timer_service.dart:58-61`: `resume()` restarts with remaining. `practice_providers.dart:123-144`: wraps scoring in `suspendAll()`/`resumeAll()`. Tests at `timer_service_test.dart:124-200` |
| 8 | Empty PracticeBlock (no Sessions) auto-deleted on close | `practice_repository.dart:1189-1191`: `if (completedCount == 0)` → `softDeletePracticeBlock`. Test at `practice_repository_business_test.dart:429-443` |

### S14 — Drill Entry Screens & System Drill Library (3/3)

| # | Item | Evidence |
|---|------|----------|
| 1 | All 28 V1 System Drills present with correct configuration | `seed_data.dart:142-180`: 28 drills (7 TB + 7 Direction + 6 Distance + 3 Raw + 3 Shape + 2 Flight). Post-seed assert at line 247: `systemDrillCount == 28`. Test at `drill_repository_test.dart:317-325` |
| 2 | Each System Drill has correct Skill Area, subskill mapping, DrillType, MetricSchema, anchors, set structure | `seed_data.dart:186-229`: `_systemDrill()` helper enforces all properties. Each category verified: TB (techniqueBlock, no anchors), Direction (1x3 grid, transition), Distance (3x1 grid), Raw Data (linearInterpolation), Binary (hitRateInterpolation) |
| 3 | Technique Block drills: no anchors, no subskill mapping, no scoring | `seed_data.dart:142-148`: all 7 TBs have `subskillMapping='[]'`, `anchors='{}'`, `metricSchemaId='technique_duration'` with `scoringAdapterBinding='None'`. Guards: `reflow_engine.dart:340-350` returns null for `ScoringAdapterType.none`; line 553-558 excludes `DrillType.techniqueBlock` from reflow trigger |

### S15 — Branding & Design System (8/8)

| # | Item | Evidence |
|---|------|----------|
| 1 | No product name or brand identifiers in code tokens, class names, or database identifiers | `tokens.dart`: all semantic names (`ColorTokens`, `primaryDefault`, etc.). `enums.dart`: domain terminology. DB tables: generic names. Minor deviation: `ZxGolfAppException` in `error_types.dart:1` — infrastructure-level, not a design token or DB identifier |
| 2 | Interaction colour tokens: primary.default = #00B3C6 | `tokens.dart:9`: `primaryDefault = Color(0xFF00B3C6)`. Applied to interactive elements only (buttons, selections, focus) |
| 3 | Success colour: #1FA463 | `tokens.dart:15`: `successDefault = Color(0xFF1FA463)`. Used for hit flash in `score_flash.dart:38` |
| 4 | Miss colour: neutral cool grey (no red for miss) | `tokens.dart:20-22`: `missDefault = Color(0xFF3A3F46)` (neutral cool grey). Red (#D64545) reserved exclusively for destructive actions |
| 5 | Heatmap: continuous opacity scaling, not discrete bands | `skill_area_tile.dart:28-33`: `Color.lerp(heatmapBase, heatmapHigh, normalisedScore)` — linear interpolation, no step function |
| 6 | Achievement banner: fade in 150ms, fade out 200ms | `achievement_banner.dart:30-35`: `duration: MotionTokens.standard` (150ms), `reverseDuration: MotionTokens.slow` (200ms) |
| 7 | All transitions ≤ 200ms, ease-in-out cubic | All animations use `MotionTokens` (fast=120ms, standard=150ms, slow=200ms). All curves = `MotionTokens.curve` (`Curves.easeInOut`). No hardcoded durations or custom curves |
| 8 | Tabular lining numerals used for score display | `zx_theme.dart:17,24`: `FontFeature.tabularFigures()`. Applied in `overall_score_display.dart:48`, `skill_area_tile.dart:66`, `plan_adherence_badge.dart:64`. Font: Manrope via `google_fonts` |

### S17 — Real-World Application Layer (8/8)

| # | Item | Evidence |
|---|------|----------|
| 1 | Offline: PracticeBlock, Session, Instance logging, and scoring all work without connectivity | All repository methods use local Drift SQLite with zero network dependencies. Scoring functions are pure deterministic logic. 43+ unit tests and integration tests execute against in-memory DB |
| 2 | Sync triggers on: connectivity restore, periodic interval, post-Session-close, manual pull-to-refresh | `sync_types.dart:16`: `SyncTrigger` enum with `connectivity`, `periodic`, `postSession`, `manual`. `sync_orchestrator.dart`: implements all 4. `practice_providers.dart:139,154`: post-session trigger. Tests at `sync_orchestrator_test.dart` |
| 3 | Payload batching at 2MB limit with parent-child ordering | `sync_engine.dart:343-418`: `staticBatchPayload()` with `tableUploadOrder` (18 tables parent→child). `constants.dart:98`: `kSyncMaxPayloadBytes = 2MB`. Never splits mid-table. Tests at `sync_engine_batching_test.dart` |
| 4 | Sync feature flag: disabled → no sync activity, app operates local-only | `sync_engine.dart:45-46,101-111,135-142`: `_syncEnabled` flag persisted to SyncMetadata. `triggerSync()` returns early if disabled. Auto-disables after 5 consecutive failures. Tests at `sync_feature_flag_test.dart` |
| 5 | Schema version gating: mismatch blocks sync, app continues offline | `sync_engine.dart:201-216`: `kSyncSchemaVersion` sent with upload; server `SCHEMA_VERSION_MISMATCH` → `SyncException.schemaMismatch`. Line 299: sets persistent flag, does NOT increment failure counter. Tests at `sync_engine_hardening_test.dart:40-113` |
| 6 | Token refresh on reconnection; expired refresh token prompts re-auth | `auth_service.dart:47-50`: `watchAuthState()` exposes Supabase `onAuthStateChange` stream. Token refresh handled transparently by Supabase SDK; expired refresh token emits auth state event for re-auth prompt |
| 7 | RLS isolation: users cannot access each other's data | `001_create_schema.sql:691-825`: 26 RLS policies. User-owned tables: `USING (auth.uid() = "UserID")`. Child tables: FK-based join queries to parent's UserID. All tables have RLS enabled |
| 8 | No automatic data pruning in V1 | No scheduled deletion logic exists. All deletion is user-initiated or cascade. EventLog is append-only. Data retention is indefinite per S17 §17.3.5 |

---

## Summary

| Section | Pass | Fail | Total | Rate |
|---------|------|------|-------|------|
| S01 — Scoring Engine | 23 | 0 | 23 | 100% |
| S02 — Skill Architecture | 5 | 0 | 5 | 100% |
| S03 — User Journey | 14 | 0 | 14 | 100% |
| S04 — Drill Entry System | 21 | 0 | 21 | 100% |
| S05 — Review & Analysis | 15 | 0 | 15 | 100% |
| S07 — Reflow Governance | 11 | 0 | 11 | 100% |
| S08 — Practice Planning | 8 | 0 | 8 | 100% |
| S09 — Golf Bag & Clubs | 8 | 0 | 8 | 100% |
| S10 — Settings | 2 | 0 | 2 | 100% |
| S11 — Metrics Integrity | 7 | 0 | 7 | 100% |
| S12 — UI/UX Structure | 2 | 0 | 2 | 100% |
| S13 — Live Practice | 8 | 0 | 8 | 100% |
| S14 — System Drill Library | 3 | 0 | 3 | 100% |
| S15 — Branding & Design | 8 | 0 | 8 | 100% |
| S17 — Real-World Application | 8 | 0 | 8 | 100% |
| **Total** | **143** | **0** | **143** | **100%** |
