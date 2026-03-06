# Gap Remediation Implementation Plan v1

> **Source:** Gap Reconciliation Report v1 — 43 Not Implemented, 9 Partially Implemented, 1 Partially Resolved conflict.
>
> **Organised into 10 phases**, sequenced by dependency order and risk. Each phase is self-contained with a clear definition of done. Complete one phase fully before starting the next. Run the full test suite after each phase.

---

## Rules for All Phases

1. Read `CLAUDE.md` before starting if you have not already done so this session.
2. Do not break any existing passing tests. Run the full suite after each phase.
3. Every code change must have at least one test. Prefer unit tests; use widget tests for UI work.
4. Follow existing patterns — use the same repository/provider/screen architecture already in the codebase.
5. Commit after each phase with message format: `fix(spec): Phase N — [short description]`.
6. If you encounter something that cannot be implemented without broader architectural change, document it in a `DEFERRED.md` at the repo root (create if it doesn't exist) and move on.

---

## Phase 1: Conflict Resolution & Immutable Field Guard

**Items:** Conflict #1 (Partially Resolved), Gap 11 (Partially Implemented)
**Risk:** Low — isolated validation logic
**Estimated scope:** 2 files changed, 3–5 tests added

### 1A: Add ScoringMode and InputMode to immutable field guard

**Context:** `drill_repository.dart:712-779` — `_rejectImmutableFieldChanges()` guards 11 fields per S00. TD-03 additionally requires ScoringMode and InputMode to be immutable post-creation. Currently omitted.

**Actions:**
1. Open `lib/data/repositories/drill_repository.dart`.
2. In `_rejectImmutableFieldChanges()`, add guards for `scoringMode` and `inputMode` using the same pattern as the existing field checks.
3. Add 2 tests to `drill_repository_test.dart`:
   - Attempt to change `scoringMode` on an existing drill → expect `ValidationException`.
   - Attempt to change `inputMode` on an existing drill → expect `ValidationException`.

### 1B: Wire Session.UserDeclaration for Binary Hit/Miss

**Context:** `sessions.dart:22-23` — Column exists. `binary_hit_miss_screen.dart:104-109` — Intention data stored per-Instance but never on Session.UserDeclaration.

**Actions:**
1. In `binary_hit_miss_screen.dart` (or its controller/provider), identify where the user selects their intention (draw/fade or high/low) at session start.
2. When `startSession()` is called for a Binary Hit/Miss drill, pass the selected declaration string to the Session creation.
3. In `practice_repository.dart` → `startSession()` (or `createSession()`), accept an optional `userDeclaration` parameter and persist it on the Session row.
4. Add a test: start a Binary Hit/Miss Session with a declaration → verify the Session record has `userDeclaration` populated.

**Definition of done:** All existing tests pass. The 2 new immutability tests pass. UserDeclaration is written for Binary Hit/Miss sessions.

---

## Phase 2: Session Duration Tracking

**Items:** Gap 36 (Not Implemented), Gap 38 (column exists), Phase 4F partial (duration never calculated)
**Risk:** Low — column exists, logic is straightforward
**Estimated scope:** 3–4 files changed, 3–5 tests added

### 2A: Calculate and persist duration on Session close

**Context:** `Session.SessionDuration` column exists but is never written to. Duration = last Instance timestamp minus first Instance timestamp, in seconds.

**Actions:**
1. In `practice_repository.dart` → `closeSession()` (or `_executeSessionClosePipeline()` per the compliance fix), after scoring:
   - Query all Instances for the Session, ordered by timestamp.
   - If ≥ 2 Instances: `duration = lastInstance.createdAt - firstInstance.createdAt` in seconds.
   - If 1 Instance: `duration = 0`.
   - If Technique Block: read duration from the Instance's `rawMetrics` JSON (already stored as seconds).
   - Write `sessionDuration` to the Session record.
2. Add tests:
   - Close a Session with 10 Instances spanning 5 minutes → verify `sessionDuration ≈ 300`.
   - Close a Technique Block Session → verify `sessionDuration` matches the raw metric value.
   - Close a Session with 1 Instance → verify `sessionDuration = 0`.

### 2B: Display duration in UI

**Actions:**
1. In `post_session_summary_screen.dart`, add a duration display (formatted as mm:ss or hh:mm:ss) for completed Sessions. Show nothing if duration is null.
2. In `session_detail_screen.dart`, add duration to the Session info section.
3. Add a widget test: render `post_session_summary_screen` with a Session that has `sessionDuration = 300` → verify "5:00" (or equivalent) is displayed.

**Definition of done:** Duration calculated and stored on every Session close. Duration visible in post-session summary and session detail.

---

## Phase 3: Golf Bag Hard Gates

**Items:** 9 Not Implemented items from Phase 5A (S09 §9.3)
**Risk:** Medium — touches multiple repositories and screens
**Estimated scope:** 5–8 files changed, 10–15 tests added

> This is the single largest unimplemented feature cluster.

### 3A: Create a shared gate validation helper

**Actions:**
1. Create a helper method, either in `club_repository.dart` or as a standalone utility (e.g. `lib/core/validation/bag_gate.dart`):
   ```
   Future<void> validateClubEligibility(int userId, SkillArea skillArea)
   ```
   - Query `UserSkillAreaClubMapping` for active clubs mapped to the given Skill Area.
   - If count == 0 and the drill is scored (not Technique Block), throw `ValidationException` with a clear message.
2. Add a unit test: no clubs mapped to Driving → call helper → expect exception.
3. Add a unit test: 1 club mapped to Driving → call helper → no exception.
4. Add a unit test: Technique Block drill → call helper → no exception regardless of club state.

### 3B: Enforce gate across all 6 contexts

**Actions — add a call to the gate helper in each of these locations:**

1. **Drill creation** — `drill_repository.dart` → `createCustomDrill()`. Before insert, validate club eligibility for the drill's Skill Area if the drill is scored.
2. **Drill adoption** — `drill_repository.dart` → `adoptDrill()`. Before insert, same check.
3. **Routine creation** — `planning_repository.dart` → when adding a fixed Drill entry to a Routine, validate the Drill's Skill Area has eligible clubs.
4. **Schedule application** — `schedule_application.dart` → when resolving Schedule entries that reference scored Drills, validate each Drill's Skill Area.
5. **Calendar Slot assignment** — `planning_repository.dart` → `assignDrillToSlot()`. Before assignment, validate the Drill's Skill Area.
6. **Session start** — `practice_repository.dart` → `startSession()` (or `createSession()`). Before creating the Session, validate club eligibility.

**For each context, add a test:**
- Attempt the operation with no eligible club → expect `ValidationException`.
- Attempt the operation with an eligible club → expect success.

### 3C: Gate activation on last-club retirement

**Actions:**
1. In `club_repository.dart` → `retireClub()`, after the retirement update, no additional cascade is needed. The gate from 3B will block execution-time operations naturally.
2. Add an integration test: create a club → map it to Driving → create a scored Driving drill → retire the club → attempt to start a Session for the drill → expect failure.

### 3D: Bag setup during onboarding (if applicable)

**Actions:**
1. Check `CLAUDE.md` and the auth flow (`auth_gate.dart`, `main.dart`) for any onboarding mechanism.
2. If no onboarding exists and this is a known deviation, add to `DEFERRED.md` and skip.
3. If an onboarding screen exists or can be added:
   - Create `lib/features/onboarding/bag_setup_screen.dart`.
   - Present the standard 14-club preset: Driver, 3W, 5W, 4i–9i, PW, GW, SW, LW, Putter.
   - User can accept immediately or customise (add/remove clubs) before confirming.
   - On confirm, create the clubs via `club_repository` and apply default Skill Area mappings.
   - Route to the onboarding screen on first login (check if user has any clubs; if not, show setup).
4. Add tests: accept preset → verify 14 clubs created with correct types and default mappings.

**Definition of done:** Bag gate enforced in all 6 contexts. Last-club retirement blocks drill execution. Onboarding handled or explicitly deferred.

---

## Phase 4: Reflow Lock UI Awareness

**Items:** Gaps 39–42 (Not Implemented), Gap 43 (Not Implemented)
**Risk:** Medium — requires wiring lock state to UI layer
**Estimated scope:** 4–6 files changed, 5–8 tests added

> Gap 44 (system-initiated parallel reflow) is a server-side orchestration feature — defer to `DEFERRED.md`.

### 4A: Expose lock state to UI

**Actions:**
1. Create a Riverpod provider that watches the `UserScoringLock` state (or have the reflow engine expose an observable lock status). Something like:
   ```dart
   final scoringLockActiveProvider = StreamProvider<bool>((ref) { ... });
   ```
2. The provider should emit `true` when the user's scoring lock is held, `false` otherwise.

### 4B: Disable submission during lock

**Actions:**
1. In all 4 execution screens (`grid_cell_screen.dart`, `binary_hit_miss_screen.dart`, `continuous_measurement_screen.dart`, `raw_data_entry_screen.dart`):
   - Watch `scoringLockActiveProvider`.
   - When lock is active: input fields remain visible but submission buttons are disabled (greyed out).
   - Show a brief inline indicator (e.g. "Updating scores…") while locked.
2. This satisfies Gap 42 (fields visible but submission disabled) and implicitly satisfies Gaps 39–41 (no buffering, no partial save, no retry queue — submission is simply blocked).
3. Add widget tests:
   - Render execution screen with lock active → verify submit button is disabled.
   - Render execution screen with lock inactive → verify submit button is enabled.

### 4C: Maintenance banner for global scoring lock

**Context:** Gap 43 specifies a global scoring lock with maintenance banner for system-initiated changes. Since system-initiated reflow is deferred, implement the banner infrastructure only.

**Actions:**
1. Add a global `SystemMaintenanceBanner` widget that can be shown at the top of `ShellScreen` when a system-level lock is active.
2. For now, the trigger for this banner does not exist (system-initiated reflow is deferred). But the widget and its provider slot should be in place so it can be wired later.
3. Add this to `DEFERRED.md`: "System-initiated parallel reflow (Gap 44) and global scoring lock trigger deferred to post-V1. Banner widget ready at ShellScreen level."

**Definition of done:** Lock state observable by UI. Submission disabled during scoring lock across all execution screens. Maintenance banner infrastructure in place.

---

## Phase 5: Settings & Configuration Gaps

**Items:** Week start day (Partially Implemented), Portrait-only (Not Implemented), Manual sync trigger (Not Implemented)
**Risk:** Low — isolated settings and configuration changes
**Estimated scope:** 4–6 files changed, 4–6 tests added

### 5A: Wire week start day setting

**Context:** `users.dart:13-14` has `weekStartDay` INT column (default 1 = Monday). Column exists in DB but is not in `user_preferences.dart`, not in settings UI, and not consumed by CalendarScreen.

**Actions:**
1. Add `weekStartDay` to the `UserPreferences` model in `user_preferences.dart`. Include it in `toJson()` / `fromJson()`.
2. In the settings screen (likely `settings_screen.dart` or a dedicated preferences screen), add a toggle: "Week starts on" → Monday / Sunday.
3. Read/write via the existing `updatePreferences()` path.
4. In `calendar_screen.dart`, consume the setting when calculating week boundaries and the 2-week view grid.
5. In `review_providers.dart` where rollup boundaries are calculated (adherence, analysis buckets), use the week start day instead of hardcoded Monday.
6. Add tests:
   - Set week start to Sunday → verify calendar week boundaries shift.
   - Set week start to Monday → verify default behaviour unchanged.

### 5B: Enforce portrait-only orientation

**Actions:**
1. In `main.dart`, before `runApp()`, add:
   ```dart
   await SystemChrome.setPreferredOrientations([
     DeviceOrientation.portraitUp,
     DeviceOrientation.portraitDown,
   ]);
   ```
2. This is a one-line change with no test requirement (platform-level enforcement).

### 5C: Add manual sync trigger to Settings

**Context:** `SyncTrigger.manual` is defined in `sync_types.dart:12-18` but never invoked. No "Sync Now" button exists in settings.

**Actions:**
1. In the settings screen, add a "Sync Now" button (or list tile).
2. On tap, invoke the sync orchestrator with `SyncTrigger.manual`.
3. Show a brief loading indicator while sync is in progress, then a success/failure snackbar.
4. Add a test: tap Sync Now → verify `triggerSync(SyncTrigger.manual)` is called.

**Definition of done:** Week start day fully wired from DB to UI to calendar and rollup logic. App locked to portrait. Manual sync accessible from settings.

---

## Phase 6: Live Practice Workflow Enhancements

**Items:** Save Practice as Routine (Not Implemented), Undo Last Instance (Not Implemented), Set Transition interstitial (Not Implemented), Deferred Post-Session Summary (Partially Implemented)
**Risk:** Medium — new features in the practice flow
**Estimated scope:** 5–8 files changed, 8–12 tests added

### 6A: Save Practice as Routine

**Context:** S13 §13.12 — save current queue as a Routine from the queue view.

**Actions:**
1. In `practice_queue_screen.dart`, add a "Save as Routine" action button (e.g. in the AppBar overflow menu or as a prominent CTA).
2. On tap:
   - Read all PracticeEntries for the current PracticeBlock (all states: Pending, Active, Completed).
   - Extract the DrillID from each entry, in PositionIndex order.
   - Call `planning_repository.createRoutine()` with these DrillIDs as fixed entries.
   - Show a confirmation snackbar with the Routine name.
3. The new Routine is immediately available in Track and Plan — no additional wiring needed.
4. Add tests:
   - Queue with 3 entries → Save as Routine → verify Routine created with 3 entries in order.
   - Queue with 0 entries → Save as Routine button should be hidden or disabled.

### 6B: Undo Last Instance

**Context:** S14 §14.10 — available immediately after saving an Instance, until the next Instance is logged.

**Actions:**
1. In `session_execution_controller.dart`, add an `undoLastInstance()` method:
   - Delete the most recently created Instance for the current Set.
   - Decrement the Instance count.
   - This is a pre-scoring operation (Instance not yet part of a closed Session), so no reflow is triggered.
2. In all 4 execution screens, add an "Undo" button (small, secondary style). Visible only when:
   - At least 1 Instance exists in the current Set.
   - The Session is still active.
3. After undo, the button remains visible if more Instances exist, hidden if the Set is now empty.
4. Add tests:
   - Log 3 Instances → undo → verify 2 remain.
   - Log 1 Instance → undo → verify 0 remain, undo button hidden.
   - Undo on empty Set → button not visible (no action possible).

### 6C: Set Transition interstitial

**Context:** S14 §14.10 — visual feedback between Sets in structured drills.

**Actions:**
1. In `session_execution_controller.dart` → `advanceSet()`, set a transient state flag (e.g. `showSetTransition = true`).
2. In execution screens, when this flag is true, display an overlay or brief interstitial: "Set N Complete — Starting Set N+1". Auto-dismiss after 1.5 seconds (using `MotionTokens.slow` or a short `Future.delayed`), then resume input.
3. The interstitial should not block or require user action — it is informational only.
4. Add a widget test: advance Set → verify interstitial text appears → verify it auto-dismisses.

### 6D: Deferred Post-Session Summary after auto-end

**Context:** When a PracticeBlock auto-ends (4h timer), the summary should be shown on next app open if Sessions exist.

**Actions:**
1. In the auto-end logic (`practice_providers.dart:219-242` or wherever the 4h timer fires):
   - After closing the PracticeBlock, persist a flag (e.g. in SharedPreferences or a lightweight DB field): `pendingPostSessionSummary = true` with the PracticeBlockID.
2. On app startup (in `startup_checks.dart` or the shell's `initState`):
   - Check for the pending flag.
   - If true, and the PracticeBlock has ≥1 Session, navigate to `PostSessionSummaryScreen` with the block's data.
   - Clear the flag.
   - If the PracticeBlock had 0 Sessions (empty, discarded), show a passive snackbar: "Your practice session ended with no completed drills."
3. Add tests:
   - Auto-end with 2 Sessions → next launch → verify summary screen shown.
   - Auto-end with 0 Sessions → next launch → verify snackbar shown, no summary screen.

**Definition of done:** Save as Routine functional from queue view. Undo Last Instance available in all execution screens. Set transition interstitial displays between Sets. Deferred summary shown after auto-end on next app open.

---

## Phase 7: Plan Architecture Enhancements

**Items:** Save & Practice (Not Implemented), Clone Routine (Not Implemented), "Edit Drill" cross-navigation (Not Implemented), Volume chart legend (Not Implemented)
**Risk:** Low-Medium — discrete UI additions
**Estimated scope:** 4–6 files changed, 5–8 tests added

### 7A: Save & Practice shortcut on drill creation

**Actions:**
1. In `drill_create_screen.dart`, add a secondary action button: "Save & Practice".
2. On tap:
   - Save the drill (same as existing "Create Drill" logic).
   - Create a PracticeBlock with a single PracticeEntry for the new DrillID.
   - Navigate to `PracticeQueueScreen` (or directly to the execution screen).
3. Add a test: tap Save & Practice → verify drill created AND PracticeBlock exists with one entry.

### 7B: Clone Routine

**Actions:**
1. In `routine_detail_screen.dart`, add a "Duplicate" option to the PopupMenu.
2. On tap, create a new Routine with the same entries (deep copy), appending " (Copy)" to the name.
3. Navigate to the new Routine's detail screen.
4. Add a test: duplicate a Routine with 4 entries → verify new Routine exists with 4 identical entries and a different ID.

### 7C: "Edit Drill" cross-navigation from Review

**Actions:**
1. In `session_detail_screen.dart`, for User Custom drills, add an "Edit Drill" button that navigates to the drill's edit screen in the Plan/Create context.
2. For System Drills, hide this button (already confirmed: System Drills have no edit menu).
3. Add a widget test: render session detail for a User Custom drill → verify "Edit Drill" button present. Render for System Drill → verify button absent.

### 7D: Volume chart legend

**Actions:**
1. In `volume_chart.dart`, add a legend widget below the chart that maps each Skill Area colour to its label.
2. Use the existing SkillArea enum and the colour tokens already assigned to each area.
3. Add a widget test: render volume chart with data → verify 7 legend entries are present.

**Definition of done:** Save & Practice works from drill creation. Clone Routine available. Edit Drill navigable from Review. Volume chart has a legend.

---

## Phase 8: Review Diagnostic Visualisations

**Items:** Gaps 23–26 (all Not Implemented) — grid distribution, 3×3 derived views, histograms, hit/miss ratio
**Risk:** Medium — new chart widgets, but data already exists in Instance.rawMetrics
**Estimated scope:** 4–6 new widget files, 4–8 tests added

> These are S05 Analysis features. The data is captured — it just needs visualisation.

### 8A: Grid Cell Distribution visualisation

**Actions:**
1. Create `lib/features/review/widgets/grid_distribution_chart.dart`.
2. For drills using Grid Cell Selection input mode, aggregate Instance rawMetrics by cell position.
3. Display a visual grid (matching the drill's grid type: 1×3, 3×1, or 3×3) with cell hit counts or percentages overlaid.
4. Integrate into the Analysis screen when the scope is a grid-based drill.
5. Add a test: provide 20 Instances with grid data → verify chart renders with correct cell counts.

### 8B: 3×3 Derived summary views

**Actions:**
1. For 3×3 Multi-Output drills, derive 1×3 (direction summary) and 3×1 (distance summary) views by collapsing the grid along one axis.
2. Display these as secondary views within the grid distribution chart.
3. Add a test: provide 3×3 data → verify derived 1×3 totals match column sums.

### 8C: Histogram for Continuous Measurement / Raw Data Entry

**Actions:**
1. Create `lib/features/review/widgets/histogram_chart.dart`.
2. For drills using Continuous Measurement or Raw Data Entry, bucket the raw metric values and display as a histogram.
3. Use 10–20 auto-sized bins between the drill's HardMinInput and HardMaxInput.
4. Integrate into the Analysis screen at drill scope for these input modes.
5. Add a test: provide 50 raw data Instances → verify histogram renders with correct bin counts.

### 8D: Binary Hit/Miss ratio display

**Actions:**
1. Create `lib/features/review/widgets/hit_miss_ratio_bar.dart`.
2. For Binary Hit/Miss drills, aggregate hit/miss counts across the selected date range and display as a ratio bar (green portion = hits, grey portion = misses) with percentage labels.
3. Integrate into the Analysis screen at drill scope for Binary Hit/Miss input mode.
4. Add a test: provide 30 Instances (20 hits, 10 misses) → verify ratio bar shows 67% / 33%.

**Definition of done:** All 4 diagnostic visualisation types render correctly for their respective input modes in the Analysis screen.

---

## Phase 9: Technique Block Filter & Comparative Analytics

**Items:** Technique Block filter exclusion (Partially Implemented), Comparative Analytics (Not Implemented), Filter persistence (Not Implemented)
**Risk:** Medium — analysis screen logic changes
**Estimated scope:** 3–5 files changed, 5–8 tests added

### 9A: Fix Technique Block filter exclusion

**Context:** `analysis_filters.dart:164-165` excludes Technique from DrillType chips, but `_filterSessions()` does not actively exclude Technique sessions under "All" selection.

**Actions:**
1. In the session filtering logic, when DrillType filter is "All" at Skill Area or Overall scope, exclude Technique Block sessions.
2. At Drill scope, Technique Block should appear if the selected drill is a Technique Block.
3. Add a test: filter "All" drill types at Skill Area scope → verify Technique Block sessions excluded from chart data.

### 9B: Filter persistence across segment switches

**Context:** `practice_pool_screen.dart:35,74` — filter state is local, lost on navigation.

**Actions:**
1. Replace local `_selectedFilter` with a Riverpod `StateProvider` (one per segment: Drills and Routines).
2. Segment switches preserve the other segment's filter state.
3. Add a test: set Drill filter to "Irons" → switch to Routines → switch back to Drills → verify "Irons" filter still active.

### 9C: Comparative Analytics (time range vs time range)

**Actions:**
1. In `analysis_screen.dart`, add a "Compare" toggle button.
2. When active, show two date range selectors instead of one.
3. Render a second data series on the performance chart (using a dashed line or different opacity) for the comparison range.
4. Show a summary delta (e.g. "↑ +0.3 avg score" or "↓ -12% volume") between the two ranges.
5. Add tests:
   - Activate compare mode → verify two date range selectors visible.
   - Provide data for two ranges → verify both series rendered.

**Definition of done:** Technique Block correctly excluded from "All" filter. Filters persist across navigation. Comparative Analytics functional with two date ranges.

---

## Phase 10: Infrastructure & Documentation

**Items:** Partial indexes (Not Implemented), WCAG verification (Not Implemented), RPO/RTO documentation (Not Implemented), device deregistration (Not Implemented)
**Risk:** Low — database and documentation work
**Estimated scope:** 2–4 files changed, 2–4 tests added, 1–2 documentation files created

### 10A: Partial indexes on IsDeleted=false

**Actions:**
1. Create a new migration file (e.g. `005_add_partial_indexes.sql`).
2. Add partial indexes on high-traffic tables where `IsDeleted=false` filtering is common: Drills, Sessions, Instances, PracticeBlocks, UserClubs.
3. Pattern: `CREATE INDEX IF NOT EXISTS idx_drills_active ON "Drills" ("UserID", "SkillArea") WHERE "IsDeleted" = false;`
4. Update the Drift migration strategy in `database.dart` to apply the new migration.
5. No functional test needed — this is a performance optimisation. Verify migration runs without error.

### 10B: WCAG contrast verification

**Actions:**
1. Create a test file: `test/core/theme/contrast_test.dart`.
2. For the 4 critical surfaces identified in S15 §15.13 (Overall Score, Session Score, Integrity warning, Destructive dialog), calculate the contrast ratio between foreground and background colours using the WCAG formula.
3. Assert AAA compliance (7:1) for these 4 surfaces.
4. Assert AA compliance (4.5:1) for general text against the primary surface colour.

### 10C: Document RPO/RTO and backup strategy

**Actions:**
1. Create or update `docs/operations.md` (or equivalent).
2. Document:
   - Implicit RPO: ~5 minutes (sync interval from `kSyncPeriodicInterval`).
   - RTO: dependent on Supabase managed infrastructure.
   - Backup: Supabase managed continuous backups (WAL) + daily snapshots.
   - Local data: Drift SQLite on-device, survives app updates, lost on app uninstall.
3. This is documentation only — no code change.

### 10D: Device deregistration (if time permits)

**Actions:**
1. In `settings_screen.dart`, add a "Devices" section listing registered devices from the `UserDevices` table.
2. Allow the user to deregister (soft-delete) any device except the current one.
3. Add a method in the sync layer: `deregisterDevice(deviceId)` → sets `isDeleted = true`.
4. Deregistration removes the device from the roster but does not delete any data.
5. If this is too complex for this phase, add to `DEFERRED.md`.

**Definition of done:** Partial indexes added. WCAG contrast tests passing. Operational documentation written. Device deregistration implemented or deferred.

---

## Summary of All Phases

| Phase | Items | Risk | Focus |
|-------|-------|------|-------|
| 1 | 3 | Low | Immutable field guard + UserDeclaration |
| 2 | 3 | Low | Session duration tracking |
| 3 | 12 | Medium | Golf Bag hard gates (largest cluster) |
| 4 | 5 | Medium | Reflow lock UI awareness |
| 5 | 4 | Low | Settings (week start, portrait, sync) |
| 6 | 6 | Medium | Live Practice enhancements |
| 7 | 4 | Low-Med | Plan architecture enhancements |
| 8 | 5 | Medium | Diagnostic visualisations |
| 9 | 4 | Medium | Analysis filters & comparisons |
| 10 | 4 | Low | Infrastructure & documentation |
| **Total** | **~50** | | |

### Items explicitly deferred (add to DEFERRED.md)

| Item | Reason |
|------|--------|
| System-initiated parallel reflow (Gap 44) | Server-side orchestration, post-V1 |
| Global scoring lock trigger (Gap 43 trigger, not banner) | Requires server-side reflow initiation |
| Calendar drag-and-drop (S12 §12.4) | Major UX overhaul, post-V1 |
| Calendar Bottom Drawer (S12 §12.4) | Coupled with drag-and-drop |
| Crash recovery UX (S13 §13.14) | Edge case, existing startup checks sufficient for V1 |
| Per-drill unit override (S10 §10.6) | Architectural decision needed on unit storage model |
| Sync-triggered rebuild priority (S17 §17.4) | Requires reflow priority queue architecture |
| 80% Screen Takeover pattern (S14 §14.10.7) | Visual design pattern, not functional gap |
| Submit + Save dual-action (S14 §14.9) | Current Record/End pattern is functional |

---

*End of Implementation Plan*
