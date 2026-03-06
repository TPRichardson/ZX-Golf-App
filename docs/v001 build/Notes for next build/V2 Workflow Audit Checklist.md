# V2 Workflow Audit Checklist

> **Purpose:** Walk through every key workflow in the app, in dependency order, to identify changes, improvements, and new features for V2. Work through each workflow sequentially — earlier workflows inform later ones.
>
> **How to use:** For each workflow, open the relevant screens and walk the happy path end-to-end. Then walk the edge cases. Record anything that needs to change in the V2 Change Register (separate template).

---

## A — First Launch & Onboarding

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| A1 | App cold start (first install) | What does the user see? Is there an onboarding flow or do they land straight on the shell? What's the zero-state experience? |
| A2 | Authentication | Sign-up, sign-in, token refresh, session expiry. Is the flow smooth? Any missing states (e.g. email verification, password reset)? |
| A3 | Bag setup (onboarding) | Does the user get prompted to set up their golf bag? Is the 14-club preset offered? Can they skip and come back? |
| A4 | First-time empty states | Walk every tab with zero data. Are the empty states helpful? Do they guide the user to the right first action? |

## B — Home Dashboard

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| B1 | Home Dashboard display | Overall score, today's slot summary, action buttons. Is everything rendering correctly with real data? With zero data? |
| B2 | Start Today's Practice | Filled slots → queue population → practice launch. Does the flow feel right? Edge case: what happens with 0 filled slots? |
| B3 | Start Clean Practice | Empty queue creation → practice launch. Smooth? |
| B4 | Resume Practice | Active PracticeBlock exists → Resume button → returns to queue. Does state restore correctly? |
| B5 | Home → Settings navigation | Settings gear accessible? Does returning from settings preserve Home state? |

## C — Golf Bag & Club Management

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| C1 | Add club to bag | All 36 ClubTypes available? Default Skill Area mappings applied? |
| C2 | Edit club Skill Area mappings | Mandatory mappings protected? Multi-mapping works? |
| C3 | Retire / reactivate club | State transitions correct? Does retiring the last club for a Skill Area trigger the bag gate? |
| C4 | Carry distance management | Add, edit, remove carry distance per club. |
| C5 | Bag gate enforcement | Try to create/adopt/schedule/play a scored drill with no eligible club for its Skill Area. Is the gate working in all 6 contexts? |

## D — Drill Lifecycle

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| D1 | Browse System Drill library | All 28 V1 drills present? Correct categories? Can the user see drill details without editing? |
| D2 | Adopt a System Drill | Adoption flow, confirmation, drill appears in user's list. |
| D3 | Create a Custom Drill (7-step wizard) | Every step: Skill Area, subskill mapping, input mode, metric schema, anchors, set structure, name. Validation at each step? |
| D4 | Edit a Custom Drill | Which fields are editable post-creation? Are immutable fields properly locked? |
| D5 | Edit anchors (Custom Drill) | Min < Scratch < Pro validation. Triggers full recalculation. Blocked on Retired drills. |
| D6 | Duplicate a drill | New ID, Origin = UserCustom, correct field copy. |
| D7 | Retire a drill | Active → Retired. Historical data retained. Drill removed from active lists. |
| D8 | Reactivate a drill | Retired → Active. Historical sessions reconnected. |
| D9 | Delete a drill | Cascade deletion. Reflow triggered. Removed from Routines (empty Routine auto-deleted). |
| D10 | Unadopt a System Drill (KEEP vs DELETE) | Both paths: Retire vs permanent removal + reflow. |

## E — Practice Planning

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| E1 | Create a Routine | Add drills, order them, name the routine. Fixed entries and/or generation criteria. |
| E2 | Edit a Routine | Reorder, add, remove entries. Empty routine auto-deletes. |
| E3 | Duplicate a Routine | Clone with "(Copy)" suffix. Independent entries. |
| E4 | Create a Schedule | Day assignments, drill/routine references. |
| E5 | Apply a Schedule to Calendar | CalendarDay rows created/updated. Slot assignments correct. |
| E6 | Calendar — Day view | View slots, fill/empty status, completion status. |
| E7 | Calendar — 2-Week view | Toggle between 3-Day and 2-Week. Week start day respected. |
| E8 | Calendar — Assign drill to slot | Manual slot filling. Bag gate enforced. |
| E9 | Calendar — Slot completion matching | After session close, does the right slot get matched? Overflow handling? |
| E10 | Calendar — Week start day | Does changing the setting in Settings actually shift the calendar grid? |

## F — Live Practice

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| F1 | Queue management | Add drills, reorder (PositionIndex), remove. |
| F2 | Start a Session from queue entry | PendingDrill → ActiveSession. Only one active Session enforced. |
| F3 | Discard a Session | Hard delete, no scoring trace. PracticeEntry returns to PendingDrill (or is removed). |
| F4 | Session auto-close (2h inactivity) | Timer fires, session closes, scoring runs. |
| F5 | PracticeBlock auto-end (4h) | Timer fires, block closes. Deferred summary on next launch? |
| F6 | Queue reordering during practice | Can the user reorder remaining PendingDrill entries while a Session is active? |
| F7 | Save Practice as Routine | From queue view → creates Routine from current entries in order. |
| F8 | Bottom nav hiding during practice | Tabs hidden while PracticeBlock active. |
| F9 | Exit from practice → Home | Both Done and X route to Home. |
| F10 | Crash/force-quit during practice | Reopen app → what happens? Resume button? Orphan detection? |

## G — Drill Execution (per input mode)

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| G1 | Grid Cell Selection (3×3) | Tap cells, centre/edge/corner mapping correct. Hit-rate calculated. |
| G2 | Grid Cell Selection (1×3) | Direction grid. Centre = hit. |
| G3 | Grid Cell Selection (3×1) | Distance grid. Centre = hit. |
| G4 | Binary Hit/Miss | Hit/miss recording. UserDeclaration stored on Session. Hit-rate → anchors → score. |
| G5 | Continuous Measurement | Numeric input. Value → anchors → score. |
| G6 | Raw Data Entry | Free-form numeric. Same scoring pipeline. |
| G7 | Technique Block (timer) | Duration capture. No scoring. No anchors. No subskill mapping. |
| G8 | Structured drill — Set progression | Set N must complete before Set N+1. Set transition interstitial. |
| G9 | Structured drill — Auto-close on final Instance | Final Set, final Instance → Session auto-completes. |
| G10 | Unstructured drill — Manual close | User decides when to end. |
| G11 | Bulk Entry | Dialog, capacity enforcement, micro-offset timestamps. |
| G12 | Undo Last Instance | Remove most recent Instance. Button visibility rules. |
| G13 | Haptic feedback on Instance save | All 4 input screens. |
| G14 | Scoring lock — submission disabled | While reflow is running, buttons greyed out, "Updating scores…" indicator. |
| G15 | Integrity flag triggering | Value outside HardMin/HardMax → Session flagged. Boundary values (exactly equal) NOT flagged. |

## H — Session Close & Post-Session

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| H1 | Manual Session close | Completion timestamp, duration calculated, scoring pipeline runs. |
| H2 | Structured auto-close | Final Instance → auto-close → score. |
| H3 | Post-Session Summary screen | Score, duration, instance count, drill details. All rendering correctly? |
| H4 | Session duration display | Calculated and shown in summary and detail screens. |
| H5 | Slot completion matching post-close | Session close → CalendarDay slot matched → completion recorded. |
| H6 | Reflow triggered by close | Window insertion (not classified as a reflow trigger per S07). |
| H7 | Close with integrity breach | Flag set on Session. Visible in UI. Suppressible. |

## I — Scoring & Reflow

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| I1 | Window composition | 25-occupancy window. Newest first. Oldest roll off in 0.5 increments. |
| I2 | Subskill scoring | Transition/Pressure weighting (35/65). Window average formula. |
| I3 | Skill Area scoring | Sum of subskill points. No redistribution. |
| I4 | Overall scoring | Sum of all Skill Areas. Cap at 1000. |
| I5 | Single-mapped vs Dual-mapped | Occupancy 1.0 vs 0.5. Shared mode: one score, both subskills. Multi-Output: independent scores. |
| I6 | Anchor edit → full recalculation | Edit anchors → reflow → all historical scores recalculated. Deterministic. |
| I7 | Drill deletion → reflow | Cascade delete → rebuild. |
| I8 | Lock acquisition and release | 3 retries × 500ms. 30s expiry. Dual-lock (DB + in-memory). |
| I9 | Deferred reflow coalescing | Multiple triggers during guard → merged → single execution. |
| I10 | Crash recovery | Expired lock on startup → auto-release → full rebuild. |
| I11 | Determinism | Run reflow twice → identical output. |

## J — Review & Analysis

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| J1 | SkillScore dashboard | Overall score, Skill Area tiles, heatmap colours, subskill breakdown. |
| J2 | Window detail view | Entries ordered newest first. Roll-off boundary visible. |
| J3 | Weakness detection | WeaknessIndex formula correct. Surface in UI. |
| J4 | Performance chart (line) | Daily/weekly/monthly buckets. Rolling overlay (7/4/none). |
| J5 | Volume chart (stacked bar) | Skill Area segments. Legend present and labelled. |
| J6 | Variance / RAG indicator | SD calculation. Thresholds (< 0.40 / 0.40–0.80 / ≥ 0.80). < 10 sessions = hidden. 10–19 = low confidence. |
| J7 | Plan Adherence | (Completed / Planned) × 100. Overflow excluded. |
| J8 | Date range presets & persistence | 4 presets. 1-hour reset timer. |
| J9 | Session history list | Ordered by date. Drill-level scores for Multi-Output. |
| J10 | Session detail screen | All Instance data, score, duration, integrity status. Edit Drill navigation (Custom only). |
| J11 | Analysis filters | Skill Area, DrillType, Drill scope. Technique Block excluded from "All" at non-drill scope. Filters persist. |

## K — Settings & Configuration

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| K1 | User preferences | Unit preferences, week start day. Persisted and consumed correctly. |
| K2 | Sync Now button | Manual trigger. Loading indicator. Success/failure feedback. |
| K3 | Sync status display | Last sync time, connection state. |
| K4 | Account deletion | Local-only for V1. Clear communication to user. |
| K5 | Data export | Stubbed for V1. What does the user see? |
| K6 | Device management | List registered devices. Deregister non-current device. |
| K7 | System-governed settings | Read-only display: window size, weights, allocations. |

## L — Sync & Offline

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| L1 | Full offline operation | Airplane mode: practice, score, plan. Everything works? |
| L2 | Connectivity restore → sync | Auto-trigger. Payload batching at 2MB. Parent-child ordering. |
| L3 | Periodic sync | Interval fires. Silent success. |
| L4 | Post-session sync | Session close → sync triggered. |
| L5 | Sync failure handling | Exponential backoff. 5 consecutive failures → auto-disable. |
| L6 | Schema version mismatch | Blocks sync, app continues offline. Not counted as failure. |
| L7 | Sync feature flag | Disabled → no sync activity. App continues local-only. |
| L8 | Merge conflicts | LWW per field. Slot-level merge. Deterministic rebuild. |
| L9 | Manual pull-to-refresh | Where available, triggers sync. |

## M — Cross-Cutting Concerns

| # | Workflow | What to Evaluate |
|---|----------|-----------------|
| M1 | Portrait-only enforcement | Rotation locked across all screens. |
| M2 | Design token consistency | Colours, spacing, radii, motion timing match tokens.dart across all screens. |
| M3 | Accessibility | WCAG contrast on critical surfaces. Tabular lining numerals. |
| M4 | Error handling | Validation errors shown to user. Unexpected errors handled gracefully. |
| M5 | Performance | Reflow time on large data sets. Scroll performance. Startup time. |
| M6 | State preservation | Tab switches, Home navigation, background/foreground cycling. |

---

**Total: 13 categories, ~95 workflows.**

Work through A → M in order. For each item where a change is needed, record it in the V2 Change Register using the template provided.
