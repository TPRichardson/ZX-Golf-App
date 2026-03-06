# ZX Golf App — Spec Compliance Checklist

Each section is split into items Claude Code can verify via automated tests and items you must verify manually in the running app.

---

## S01 — Scoring Engine

### Claude Code Can Test
- [ ] Overall score sums to 1000 maximum across all Skill Areas
- [ ] Skill Area allocations match spec: Irons 280, Driving 240, Putting 200, Pitching 100, Chipping 100, Woods 50, Bunkers 30
- [ ] Subskill allocations match spec (e.g. Irons: Distance 110, Direction 110, Shape 60)
- [ ] All Skill Area subskills sum exactly to their Skill Area allocation
- [ ] Linear interpolation: below min → 0, min to scratch → 0–3.5, scratch to pro → 3.5–5, above pro → 5
- [ ] Score capped strictly at 5 per drill (no overperformance)
- [ ] Pressure/Transition weighting is 65/35 globally
- [ ] Window size fixed at 25 occupancy units per window
- [ ] Single-mapped drill → occupancy 1.0; dual-mapped → 0.5 per subskill
- [ ] Minimum occupancy unit is 0.5 (no fractional splitting below 0.5)
- [ ] Shared mode: one score, same score stored in both subskills
- [ ] Multi-Output mode: independent score per subskill, independent anchors
- [ ] Window average = weighted sum / total occupancy
- [ ] Roll-off removes oldest entries first, in 0.5 increments
- [ ] Roll-off preserves original 0–5 score, only reduces occupancy
- [ ] Subskill Points = Allocation × (Weighted Average / 5)
- [ ] Unfilled occupancy contributes 0 (not excluded from denominator)
- [ ] Overall Score = sum of all Skill Area Scores
- [ ] Technique Block drills produce no score and no window entry
- [ ] Drill retirement retains historical data; deletion removes all data and triggers reflow
- [ ] Anchor edit triggers full historical recalculation
- [ ] Reflow produces identical output on repeated execution (determinism)
- [ ] No time decay, smoothing, outlier filtering, or volatility dampening present in code

### User Verifies
- [ ] Scores displayed against full 1000-point scale (never a reduced "attainable" total)
- [ ] No emotional framing of score drops anywhere in the UI

---

## S02 — Skill Architecture & Weighting Framework

### Claude Code Can Test
- [ ] Canonical skill tree matches spec exactly (7 Skill Areas, 19 subskills)
- [ ] Subskill weighted average formula: (TransitionAvg × 0.35) + (PressureAvg × 0.65)
- [ ] No redistribution occurs between subskills for unused capacity
- [ ] Cross-Skill-Area subskill mapping prohibited (enforced in code)
- [ ] Drill maps to at least 1 and at most 2 subskills (enforced)

### User Verifies
- [ ] Skill Area selection shown before club selection in drill creation
- [ ] Only eligible clubs shown for selected Skill Area

---

## S03 — User Journey Architecture

### Claude Code Can Test
- [ ] Only one authoritative active Session per user (enforced)
- [ ] PracticeBlock persisted only if at least one Session exists; auto-deleted otherwise
- [ ] PracticeBlock cannot close while Session is Active
- [ ] Session auto-close after 2 hours inactivity
- [ ] PracticeBlock auto-end after 4 hours without new Session
- [ ] Structured drills auto-close on final Instance of final Set
- [ ] Completion timestamp authority: manual end = moment pressed, structured = final Instance timestamp, auto-close = last Instance timestamp
- [ ] Session discard = hard delete, no scoring trace
- [ ] Closed Session deletion triggers full recalculation
- [ ] Editing Instances does not alter timestamp or window position
- [ ] Sets strictly sequential (Set N+1 cannot begin until Set N complete)
- [ ] Incomplete structured Sessions cannot be saved (must complete or discard)
- [ ] Routine template linkage severed after PracticeBlock creation
- [ ] If all Drills removed from Routine, Routine auto-deleted

### User Verifies
- [ ] Home Dashboard shows Overall Score (0–1000) in top section
- [ ] Home Dashboard shows Today's Slot Summary (filled/total)
- [ ] "Start Today's Practice" button visible only when today has filled Slots
- [ ] "Start Clean Practice" button always visible
- [ ] Settings accessible via gear icon in top-right of Home Dashboard
- [ ] Post-Session Summary shown after PracticeBlock close (dedicated screen, not modal/toast)
- [ ] Post-Session Summary shows final 0–5 score per Session, impact on overall score, key stats
- [ ] Post-Session Summary requires tap on Done to dismiss (no auto-timeout)
- [ ] Exit from Live Practice always routes to Home Dashboard
- [ ] If Session is active on app reopen → auto-resume
- [ ] If PracticeBlock auto-ended → passive banner shown

---

## S04 — Drill Entry System

### Claude Code Can Test
- [ ] Immutable fields enforced post-creation: subskill mapping, MetricSchema, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ClubSelectionMode, TargetDefinition
- [ ] System Drill anchors immutable to users
- [ ] User Custom Drill anchor edits trigger full recalculation
- [ ] Anchor edits blocked while Drill is in Retired state
- [ ] Drill duplication creates new DrillID with Origin = UserCustom
- [ ] Adopt/Unadopt: KEEP → Retired state, historical data retained; DELETE → permanent removal, reflow
- [ ] Re-adoption reconnects historical Sessions
- [ ] Technique Block: RequiredSetCount=1, RequiredAttemptsPerSet=null enforced
- [ ] Cross-Skill-Area subskill mapping prohibited
- [ ] Grid scoring: hit-rate percentage = (hits / total) × 100, run through anchors
- [ ] 3×3 grid: centre = hit for both subskills, edge-centres = hit for one, corners = miss for both
- [ ] 1×3 grid: Centre = hit for direction
- [ ] 3×1 grid: Ideal = hit for distance
- [ ] Binary Hit/Miss: scored metric = hit-rate %, same interpolation as grid
- [ ] Session score = simple average of all Instance 0–5 scores across all Sets
- [ ] Bulk entry cannot exceed remaining capacity of current Set (structured)
- [ ] Bulk entry assigns sequential micro-offset timestamps
- [ ] Post-close structured: Instance value edit allowed (triggers reflow), Instance deletion prohibited, Set deletion prohibited, Session deletion allowed
- [ ] Post-close unstructured: Instance value edit allowed, Instance deletion allowed, last Instance deletion auto-discards Session
- [ ] HardMinInput/HardMaxInput: values outside range saved but trigger integrity flag
- [ ] Grid Cell Selection and Binary Hit/Miss excluded from integrity detection

### User Verifies
- [ ] Drill creation flow: Skill Area → subskill mapping → input mode → anchors → set structure
- [ ] Grid cell tap shows resolved target (distance, box dimensions) for selected club
- [ ] Club Selection Mode working: Random (no override), Guided (override allowed), User Led (user picks)
- [ ] Putting drills: Putter auto-selected, no club selector shown
- [ ] For single-eligible-club Skill Areas: auto-select, no selector displayed
- [ ] Numeric input fields default to blank (dash), not zero
- [ ] During active Session: shot confirmation shown, hit/miss highlighted, set/attempt progress shown
- [ ] During active Session: per-shot 0–5 NOT displayed, running average NOT displayed
- [ ] At Session end: final 0–5 score displayed, impact on overall score displayed
- [ ] Window mechanics NOT exposed to user at Session end

---

## S05 — Review: SkillScore & Analysis

### Claude Code Can Test
- [ ] SkillScore reads from materialised tables (reactive streams)
- [ ] Window detail entries ordered by CompletionTimestamp DESC (newest first)
- [ ] Roll-off boundary is at the bottom (oldest entry)
- [ ] WeaknessIndex calculation matches Section 8 §8.7 formula
- [ ] Analysis bucket value = mean of Session 0–5 scores in bucket
- [ ] Rolling overlay: daily = 7-bucket, weekly = 4-bucket, monthly = none
- [ ] Subskill trend uses subskill's own 0–5 score (not drill-level average)
- [ ] Multi-Output drill-level score = mean of two subskill outputs (display only)
- [ ] Variance SD calculated from all Session 0–5 scores in date range (not per bucket)
- [ ] RAG thresholds: Green SD < 0.40, Amber 0.40–0.80, Red ≥ 0.80
- [ ] Fewer than 10 Sessions: RAG not displayed
- [ ] 10–19 Sessions: RAG with "Low confidence" label
- [ ] Plan Adherence: (Completed Slots / Total planned Slots) × 100
- [ ] Overflow Slots excluded from adherence numerator and denominator
- [ ] Date range persistence resets after 1 hour of no Analysis access

### User Verifies
- [ ] Overall Score displayed (0–1000) on dashboard
- [ ] All 7 Skill Area scores visible on dashboard
- [ ] Window detail view accessible by tapping into a window
- [ ] Window entries show: drill name, date, 0–5 score, occupancy (1.0 or 0.5)
- [ ] Visual divider marks roll-off boundary
- [ ] Window detail is read-only (no editing/deletion)
- [ ] Weakness Ranking view accessible from SkillScore
- [ ] Analysis resolution toggle: Daily / Weekly (default) / Monthly
- [ ] Drill-level analysis shows Session score trend and raw metric diagnostics
- [ ] Grid diagnostic shows hit/miss distribution across cells
- [ ] Binary Hit/Miss diagnostic shows hit count, miss count, hit-rate %
- [ ] Continuous/Raw diagnostics show average value and distribution histogram
- [ ] Plan Adherence shows weekly and monthly rollups with Skill Area breakdown
- [ ] Zero state: dashboard renders correctly with no data
- [ ] Heatmap: continuous grey-to-green opacity (no discrete bands, no red)
- [ ] Score communication is neutral (no "well done", no emotional framing)

---

## S07 — Reflow Governance

### Claude Code Can Test
- [ ] Reflow triggers match catalogue: anchor edit, allocation edit, weighting edit, formula edit, System Drill anchor edit
- [ ] Session close is NOT a reflow trigger (it's a window insertion)
- [ ] Window size change is NOT a reflow trigger (not editable)
- [ ] Lock acquired before reflow, released after
- [ ] Lock has 30-second expiry
- [ ] Deferred reflow coalescing: pending triggers merged by subskill union, single execution
- [ ] RebuildGuard prevents concurrent reflow and full rebuild
- [ ] Crash recovery: expired lock detected on startup → automatic full rebuild
- [ ] Reflow produces identical results on re-execution (determinism)
- [ ] IntegritySuppressed reset on reflow (§11.6.3)
- [ ] EventLog entry written for ReflowComplete

### User Verifies
- [ ] UI shows loading state during reflow (scores unavailable until complete)

---

## S08 — Practice Planning Layer

### Claude Code Can Test
- [ ] Routine: ordered list of fixed Drill references and/or Generation Criteria
- [ ] Routine instantiation creates PracticeBlock, snapshots entries, severs template linkage
- [ ] Drill deletion/retirement auto-removes from Routine; empty Routine auto-deleted
- [ ] Schedule instantiation creates/updates CalendarDay rows with Slot assignments
- [ ] Completion matching: date-strict (user timezone), DrillID matching, first-match ordering
- [ ] Completion overflow handling per §8.3.3
- [ ] CalendarDay Slot state transitions match TD-04 §2.6
- [ ] Slot-level merge rules for cross-device sync

### User Verifies
- [ ] Routine creation UI: add fixed drills and generation criteria, reorder entries
- [ ] Schedule creation in List mode and DayPlanning mode
- [ ] Calendar view shows days with Slots, manual drill assignment works
- [ ] After Session close, correct Slot auto-matched (completion matching visible)
- [ ] Routine instantiation launches PracticeBlock with correct drills

---

## S09 — Golf Bag & Club Configuration

### Claude Code Can Test
- [ ] 36 ClubTypes in canonical enumeration
- [ ] Mandatory mappings enforced: Driver → Driving, Putter → Putting, i1–i9 → Irons
- [ ] Mandatory mappings cannot be removed
- [ ] Default mappings applied on bag creation (Pitching, Chipping, Woods, Bunkers defaults)
- [ ] A ClubType may be assigned to multiple Skill Areas simultaneously
- [ ] Multiple clubs of same ClubType permitted (no max bag size)
- [ ] Club retirement/deletion state transitions per TD-04 §2.10
- [ ] Carry distance stored per club

### User Verifies
- [ ] Golf Bag screen: add club, set carry distance, map to Skill Areas
- [ ] Default mappings pre-populated on first bag setup
- [ ] User can add/remove non-mandatory mappings
- [ ] Quick-start preset applies defaults correctly

---

## S10 — Settings & Configuration

### Claude Code Can Test
- [ ] All system-governed settings read-only to user (Skill Area allocations, subskill allocations, 65/35 weighting, window size)
- [ ] User-configurable settings persisted correctly

### User Verifies
- [ ] All settings screens accessible and functional
- [ ] System-governed values displayed but not editable
- [ ] User-configurable values editable and saved
- [ ] Settings accessible via gear icon from Home Dashboard

---

## S11 — Metrics Integrity & Safeguards

### Claude Code Can Test
- [ ] IntegrityFlag set when Instance value outside HardMinInput/HardMaxInput
- [ ] Grid Cell Selection and Binary Hit/Miss excluded from integrity detection
- [ ] Session-level flag = ANY Instance flagged → Session flagged
- [ ] Auto-resolution: if flagged Instance edited to within bounds → flag cleared
- [ ] IntegritySuppressed resets on reflow (§11.6.3)
- [ ] Suppression model: per-Session toggle, manual clear action
- [ ] Zero values not treated as integrity violations (§11.3.2)

### User Verifies
- [ ] Integrity warning uses observational language ("Value outside expected range")
- [ ] No blame, alarm, or emotional framing in integrity messages
- [ ] IntegrityFlag indicator shown at Session level in drill history only
- [ ] IntegrityFlag NOT shown in SkillScore views (§15.8.5)
- [ ] Suppression toggle accessible per-Session with observational language

---

## S12 — UI/UX Structural Architecture

### Claude Code Can Test
- [ ] Live Practice hides bottom navigation and disables cross-tab navigation
- [ ] Exit from Live Practice routes to Home regardless of launch origin

### User Verifies
- [ ] Bottom navigation: correct tabs present (Home, Track, Plan, Review)
- [ ] Live Practice is immersive (no bottom nav, no cross-tab)
- [ ] Live Practice entry points all function: Start Today's Practice, Start Clean Practice, Start from Track, Save & Practice
- [ ] Navigation stack not restored after Live Practice exit
- [ ] Tab state preserved when switching between tabs (except Live Practice reset)

---

## S13 — Live Practice Workflow

### Claude Code Can Test
- [ ] PracticeEntry states: PendingDrill → ActiveSession → CompletedSession
- [ ] Only one PracticeBlock per user
- [ ] Session created only through PracticeEntry (no standalone creation)
- [ ] Queue reordering updates PositionIndex correctly
- [ ] PracticeBlock from "Start Today's Practice" pre-loads filled Slots in order
- [ ] PracticeBlock from "Start Clean Practice" starts with empty queue
- [ ] Timer suspension: timers pause during scoring lock, resume with remaining duration
- [ ] Empty PracticeBlock (no Sessions) auto-deleted on close

### User Verifies
- [ ] Queue management: add drills from Practice Pool, remove, reorder
- [ ] Start Drill button creates Session from PracticeEntry
- [ ] Structured drill: auto-closes on final Instance of final Set
- [ ] Unstructured drill: requires manual End Drill
- [ ] Technique Block: shows timer only, no scoring input
- [ ] Session discard available (hard delete, no trace)
- [ ] Post-close editing: edit Instance values, delete Instances (unstructured only)
- [ ] Manual End Practice while Session active: confirmation prompt shown
- [ ] All six input mode screens functional during execution
- [ ] Real-time scoring: Instance 0–5 score visible after each attempt

---

## S14 — Drill Entry Screens & System Drill Library

### Claude Code Can Test
- [ ] All 28 V1 System Drills present with correct configuration
- [ ] Each System Drill has correct: Skill Area, subskill mapping, DrillType, MetricSchema, anchors, set structure
- [ ] Technique Block drills: no anchors, no subskill mapping, no scoring

### User Verifies
- [ ] System Drill library browsable by Skill Area
- [ ] Each input mode screen renders correctly: Grid (1×3, 3×1, 3×3), Continuous Measurement, Raw Data Entry, Binary Hit/Miss, Technique Block
- [ ] Grid cell tap: 120ms colour flash, single haptic tick
- [ ] Resolved target displayed on Instance entry screen (distance, box dimensions for club)
- [ ] Set and attempt progress displayed during structured drills (e.g. "Set 2/3 — Attempt 4/10")

---

## S15 — Branding & Design System

### Claude Code Can Test
- [ ] No product name or brand identifiers in code tokens, class names, or database identifiers
- [ ] Interaction colour tokens: primary.default = #00B3C6
- [ ] Success colour: #1FA463
- [ ] Miss colour: neutral cool grey (no red for miss)
- [ ] Heatmap: continuous opacity scaling, not discrete bands
- [ ] Achievement banner: fade in 150ms, fade out 200ms
- [ ] All transitions ≤ 200ms, ease-in-out cubic
- [ ] Tabular lining numerals used for score display

### User Verifies
- [ ] Dark theme applied consistently across all screens
- [ ] Cyan accent (#00B3C6) used for interactive elements only (not scoring)
- [ ] No red used for miss states (neutral grey instead)
- [ ] No exclamation marks in system messages
- [ ] No motivational language in scoring displays
- [ ] No celebratory effects (no confetti, no animated counting, no theatrics)
- [ ] Achievement banners: factual text only
- [ ] Error messages: factual and actionable
- [ ] Font: Technical Geometric Sans, tabular numerals verified
- [ ] Grid cell tap: 120ms colour flash + haptic tick
- [ ] WCAG AA contrast on all surfaces
- [ ] WCAG AAA contrast on SkillScore and Subskill score displays
- [ ] Outdoor readability on drill entry screens
- [ ] Score presentation is neutral (no emotional framing of increases or drops)
- [ ] Heatmap: grey-to-green continuous opacity (no discrete bands, no red)
- [ ] Overall feel: performance-focused, analytical, not gamified or lifestyle

---

## S17 — Real-World Application Layer

### Claude Code Can Test
- [ ] Offline: PracticeBlock, Session, Instance logging, and scoring all work without connectivity
- [ ] Sync triggers on: connectivity restore, periodic interval, post-Session-close, manual pull-to-refresh
- [ ] Payload batching at 2MB limit with parent-child ordering
- [ ] Sync feature flag: disabled → no sync activity, app operates local-only
- [ ] Schema version gating: mismatch blocks sync, app continues offline
- [ ] Token refresh on reconnection; expired refresh token prompts re-auth
- [ ] RLS isolation: users cannot access each other's data
- [ ] No automatic data pruning in V1

### User Verifies
- [ ] Offline indicator visible when connectivity lost, disappears on reconnect
- [ ] Sync progress indicator shown during extended downloads
- [ ] Schema version mismatch: clear "update required" message
- [ ] Sync feature flag off: "Sync disabled" message visible in Settings/status
- [ ] Last sync timestamp visible in settings or status bar
- [ ] Low-storage warning displayed when device storage critically low
- [ ] Cross-device: data created on one device appears on another after sync
- [ ] Token expiry: seamless re-auth prompt, no data loss

---

## How To Use This Checklist

**Stage 1 — Claude Code audit.** Open a Claude Code session and prompt:

```
Read the spec compliance checklist in docs/post-build/Spec Compliance Checklist.md. 
Run through every item in the "Claude Code Can Test" sections. For each item, 
write a test or verify the existing codebase. Report which items PASS and which FAIL 
with specific details on failures.
```

**Stage 2 — Your manual audit.** Walk through the app with this checklist open. Tick off each "User Verifies" item. Note failures in `spec-failures.md`.

**Stage 3 — Remediation.** Feed failures to Claude Code grouped by section for fixes.
