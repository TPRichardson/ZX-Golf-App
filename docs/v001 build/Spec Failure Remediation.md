# Spec Compliance — Failure Remediation

Read this file and fix every failure below. For each fix, write or update the relevant test to confirm the fix. Run `flutter test` after all fixes to confirm no regressions.

---

## Fix 1 — S01 #12: Multi-Output scoring not implemented

**File:** `reflow_engine.dart` around line 734
**Problem:** `ScoringMode.multiOutput` enum exists but is never read during scoring. Code always uses the first subskill's anchors. Multi-Output drills should score each subskill independently against its own anchor set.
**Fix:** When a drill's `scoringMode == ScoringMode.multiOutput`, use each mapped subskill's own Min/Scratch/Pro anchors to produce an independent 0–5 score per subskill. Each subskill receives 0.5 occupancy.
**Test:** Add a test with a Multi-Output drill mapped to 2 subskills with different anchors. Verify each subskill receives a different score.

---

## Fix 2 — S02 #5: No subskill count validation on drill creation

**File:** `drill_repository.dart` around line 141
**Problem:** No validation that Transition/Pressure drills have 1–2 subskill mappings. Empty arrays and 3+ subskills accepted.
**Fix:** In `createDrill()` and `updateDrill()`, enforce:
- Technique Block: 0 subskills required
- Transition/Pressure: exactly 1 or 2 subskills required
Throw `ValidationException` if violated.
**Test:** Test that creating a Pressure drill with 0 subskills throws. Test that creating one with 3 throws. Test that 1 and 2 pass.

---

## Fix 3 — S03 #13 + S08 #2: Routine template linkage never set on PracticeBlock

**File:** `practice_repository.dart` around line 596–634
**Problem:** `sourceRoutineId` field exists on PracticeBlocks but `createPracticeBlock()` never sets it. When a PracticeBlock is created from a Routine, the sourceRoutineId should be recorded then treated as informational only (linkage severed — edits to Routine don't affect the PracticeBlock).
**Fix:** Add optional `sourceRoutineId` parameter to `createPracticeBlock()`. When creating from a Routine, pass the Routine ID. Ensure no code reads this field to alter PracticeBlock behaviour (linkage is informational/severed).
**Test:** Test that PracticeBlock created from Routine has sourceRoutineId set. Test that editing the Routine after creation does not affect the PracticeBlock.

---

## Fix 4 — S04 #16–17: Bulk entry not implemented

**File:** Execution screens (per input mode)
**Problem:** No bulk entry feature exists. Spec requires: enter multiple Instances at once for the active Set, cannot exceed remaining capacity (structured), assigns sequential micro-offset timestamps.
**Fix:** Add a bulk entry option on each execution screen (except Technique Block). For structured drills, cap at remaining Set capacity. For unstructured, unlimited. Each Instance in a bulk batch uses the same SelectedClub. Assign timestamps with 1ms micro-offsets for ordering.
**Test:** Test bulk entry of 5 Instances. Test that structured drill bulk entry is capped at remaining capacity. Test timestamp ordering.

---

## Fix 5 — S04 #18: Post-close structured drill deletion not guarded

**File:** `practice_repository.dart` — `deleteInstance()` and `deleteSet()`
**Problem:** No guard prevents Instance or Set deletion on closed structured Sessions. Spec: post-close structured drills allow Instance value edit only. Instance deletion, Set deletion prohibited. Session deletion allowed.
**Fix:** In `deleteInstance()` and `deleteSet()`, check if the parent Session is closed AND the drill is structured (RequiredAttemptsPerSet != null). If so, throw `ValidationException`. Leave `deleteSession()` unrestricted.
**Test:** Test that deleting an Instance from a closed structured Session throws. Test that deleting from a closed unstructured Session succeeds. Test that Session-level deletion still works for both.

---

## Fix 6 — S04 #19: Last Instance deletion doesn't auto-discard unstructured Session

**File:** `practice_repository.dart` — `deleteInstance()`
**Problem:** When the last remaining Instance of a closed unstructured Session is deleted, the Session should be automatically discarded (hard delete) and trigger reflow.
**Fix:** After deleting an Instance, check remaining Instance count for that Session. If zero and Session is unstructured, hard-delete the Session and trigger reflow.
**Test:** Create an unstructured Session with 2 Instances, close it. Delete one Instance — Session remains. Delete last Instance — Session auto-discarded. Verify reflow triggered.

---

## Fix 7 — S05 #8: Multi-Output drill-level display score not implemented

**File:** Review/analysis display layer
**Problem:** For Multi-Output drills, the drill-level display score should be the mean of the two subskill 0–5 outputs. This is display-only and does not feed back into the scoring engine.
**Fix:** Where drill-level Session scores are displayed (review screens, drill history, analysis trends), calculate as mean of the two subskill scores for Multi-Output drills. For Shared mode, continue using the single score.
**Test:** Test that a Multi-Output drill with subskill scores 3.0 and 5.0 displays 4.0 at drill level.

---

## Fix 8 — S07 #2: Session close incorrectly treated as reflow trigger

**File:** `reflow_engine.dart` around line 1003–1014, `reflow_types.dart`
**Problem:** Session close calls `executeReflow()` with `ReflowTriggerType.sessionClose`. Per spec, Session close is a window insertion, not a reflow trigger. The Session close scoring pipeline should: calculate Instance scores, calculate Session score, insert into window, recompute subskill/SkillArea/Overall from the updated window — but this should be implemented as the Session Close Scoring Pipeline (TD-03 §4.4), not as a reflow.
**Fix:** Rename or restructure so Session close follows the Session Close Pipeline path (insert into window, update materialised tables) rather than the full reflow path. The key difference: Session close should NOT acquire the UserScoringLock in the same way reflow does (TD-03 §4.4 specifies it runs outside the lock). Remove `sessionClose` from `ReflowTriggerType` enum. Ensure the pipeline still updates all materialised tables correctly.
**Note:** This is architecturally sensitive. Verify all existing tests still pass. If the current implementation produces correct scores via the reflow path, the refactor should preserve that correctness while fixing the trigger classification.
**Test:** Verify Session close does not emit a `ReflowComplete` EventLog with trigger type `sessionClose`. Verify materialised tables are still updated correctly after Session close.

---

## Fix 9 — S11 #4: Integrity flag auto-resolution not implemented

**File:** `practice_repository.dart` — `updateInstance()`
**Problem:** When a flagged Instance is edited to a value within HardMinInput/HardMaxInput bounds, the integrity flag should auto-clear. Currently the flag persists and only manual suppression clears it.
**Fix:** After Instance edit, re-evaluate integrity for all Instances in the Session. If no Instance is in breach, clear the Session's `integrityFlag`. Emit `IntegrityFlagAutoResolved` event.
**Test:** Create Instance outside bounds (flag set). Edit to within bounds. Verify flag auto-cleared and event emitted.

---

## Fix 10 — S12 #1: Bottom navigation not hidden during Live Practice

**File:** `shell_screen.dart` around line 82–102
**Problem:** BottomNavigationBar renders unconditionally. During Live Practice, bottom nav should be hidden and cross-tab navigation disabled.
**Fix:** Watch practice state (active PracticeBlock/Session). When Live Practice is active, hide the BottomNavigationBar and prevent tab switching. Use a fullscreen route or conditional rendering.
**Test:** This is primarily a UI fix. Add a widget test that verifies BottomNavigationBar is not in the widget tree when a PracticeBlock is active.

---

## Fix 11 — S12 #2: Live Practice exit doesn't route to Home

**File:** `post_session_summary_screen.dart` around line 173
**Problem:** Done button uses `Navigator.pop()` which returns to the execution stack. Should route to Home Dashboard regardless of launch origin.
**Fix:** Replace `Navigator.pop()` with `Navigator.of(context).popUntil((route) => route.isFirst)` or equivalent to clear the navigation stack and return to Home.
**Test:** Widget test: push multiple routes simulating Live Practice flow, tap Done, verify navigator returns to root.

---

## Fix 12 — S13 #5: "Start Today's Practice" not wired to Calendar Slots

**File:** Home Dashboard UI
**Problem:** Repository supports `createPracticeBlock(initialDrillIds)` but no UI button connects today's Calendar Slots to PracticeBlock creation.
**Fix:** On Home Dashboard, add "Start Today's Practice" button. Visible only when today's CalendarDay has at least one filled Slot. On tap: query today's CalendarDay, collect filled Slot DrillIDs in Slot order, call `createPracticeBlock(initialDrillIds: drillIds)`, navigate to Live Practice.
**Test:** Widget test: mock CalendarDay with filled Slots, verify button visible. Mock empty day, verify button hidden. Tap test: verify PracticeBlock created with correct DrillIDs.

---

## After All Fixes

Run `flutter test` and confirm all tests pass. Then update `docs/post-build/spec-failures.md` to mark all items as RESOLVED with the fix applied.
