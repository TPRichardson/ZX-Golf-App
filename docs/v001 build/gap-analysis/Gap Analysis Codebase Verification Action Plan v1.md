# Claude Code Action Plan: Gap Analysis vs Codebase Verification

> **Purpose:** Systematically compare the consolidated gap analysis (S00–S17 vs TD) against the actual codebase to determine which gaps have been addressed in implementation, which conflicts have been resolved, and which items remain outstanding.
>
> **Input:** `S00 S17 vs TD Consolidated Gap Analysis v1.md` — contains 222 gaps, 7 conflicts, and ~25 TD-only items.
>
> **Output:** A reconciliation report classifying every gap and conflict as: **Implemented**, **Partially Implemented**, **Not Implemented**, or **Cannot Determine**.

---

## General Instructions

- Work through each phase sequentially. Complete one phase fully before moving to the next.
- For each phase, produce a structured markdown section as output. Append each phase's results to a single running output file: `Gap Reconciliation Report v1.md`.
- When searching the codebase, prioritise evidence from: Dart/Flutter source files, database schema/migration files, seed data, state machine definitions, test files, and configuration files.
- For each item you verify, record: the item description, the file(s) and line(s) where evidence was found (or "No evidence found"), and your classification.
- Do not modify any source files. This is a read-only audit.
- If a phase has more items than you can reliably verify in one pass, break it into sub-phases and work through them sequentially. State clearly when you are doing this.
- If you encounter a CLAUDE.md or similar project context file, read it first as it may contain known deviations and architectural decisions.

---

## Phase 0: Codebase Orientation

**Goal:** Understand the project structure before any verification begins.

**Actions:**

1. Read `CLAUDE.md` (or equivalent project context file) at the repository root. Note any known deviations, deferred features, or architectural decisions documented there.
2. Map the top-level directory structure (2 levels deep).
3. Identify and record the locations of:
   - Database schema definitions (Drift/SQLite table classes)
   - Migration files
   - Seed data files (System Drills, MetricSchema, SubskillRef, EventTypeRef, etc.)
   - State machine implementations
   - Repository classes (DrillRepository, PracticeRepository, ClubRepository, etc.)
   - Reflow/scoring engine
   - UI screen files (organised by feature/phase)
   - Design tokens file (tokens.dart or equivalent)
   - Test files
   - Sync engine components
4. Record the file count and confirm the technology stack (Flutter/Dart, Drift, Supabase, etc.).
5. Write the orientation summary as the opening section of `Gap Reconciliation Report v1.md`.

**Output format:**

```markdown
## Phase 0: Codebase Orientation

### Project Context (from CLAUDE.md)
[Summary of known deviations and architectural decisions]

### Directory Map
[Top-level structure]

### Key File Locations
| Component | Path(s) |
|-----------|---------|
| Schema definitions | ... |
| Migrations | ... |
| Seed data | ... |
| State machines | ... |
| Repositories | ... |
| Scoring engine | ... |
| UI screens | ... |
| Design tokens | ... |
| Tests | ... |
| Sync engine | ... |
```

---

## Phase 1: Conflict Verification (7 items)

**Goal:** Determine the actual implementation state for each of the 7 unique conflicts.

**Actions:**

For each conflict below, search the codebase for the relevant implementation and determine which version (Spec or TD) the code follows, or whether the conflict has been resolved.

| # | Conflict | What to Search For |
|---|----------|--------------------|
| 1 | Immutable post-creation field lists diverge (S00 vs TD-03) | Find the structural immutability guard in the Drill repository or model. List exactly which fields are treated as immutable post-creation. Compare against both S00's list (SubskillMapping, MetricSchema, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ClubSelectionMode, TargetDefinition) and TD-03's list (SubskillMapping, MetricSchemaID, DrillType, RequiredSetCount, RequiredAttemptsPerSet, ScoringMode, InputMode). |
| 2 | PracticeBlock.ClosureType values (S06: 2 values vs TD-04: 3 values) | Find the ClosureType enum or equivalent. Count the values. |
| 3 | Session columns UserDeclaration and SessionDuration (S06 defines, TD-02 may omit) | Check the Session table/model definition for these two columns. |
| 4 | Reflow timeout (S07: 60s vs TD-04: 30s) | Find the reflow timeout constant(s). Record actual value(s). |
| 5 | Reflow retry count (S07: 3 attempts vs TD-07: 1 retry + fallback) | Find the retry logic in the reflow/rebuild engine. Record actual strategy. |
| 6 | Structural edit queuing prohibition (S07: no queuing vs TD-04: deferred coalescing) | Search for any reflow queuing, coalescing, or deferred trigger logic. |
| 7 | User scoring lock mechanism (S16: advisory lock vs TD-04: in-memory mutex) | Find the scoring lock implementation. Determine if it is database-level or in-memory. |

**Output format per conflict:**

```markdown
### Conflict #N: [Title]
- **Code evidence:** [file:line references]
- **Implementation follows:** Spec / TD / Hybrid / Neither
- **Details:** [What was actually implemented]
- **Status:** Resolved / Unresolved / Partially Resolved
```

---

## Phase 2: High-Risk Gap Verification (5 items)

**Goal:** Verify the 5 High-risk gaps first, as these represent the most architecturally significant findings.

**Items:**

| Gap # | Spec | Item | What to Search For |
|-------|------|------|--------------------|
| 62 | S12 §12.2 | Home Dashboard as persistent launch layer | Search for a Home Dashboard screen, a persistent widget above tab navigation, or a dedicated home route. Check the shell/navigation structure. |
| 65 | S12 §12.2.2 | Home Dashboard entry points (Start Today's / Start Clean) | Search for "Start Today" or "Start Clean" or "StartPractice" buttons/CTAs on a home screen. |
| 66 | S12 §12.3 | All Home Dashboard content items (score, slots, buttons, exclusions) | If a Home Dashboard exists, check what content it renders: overall score, slot summary, practice CTAs. |
| 89 | S13 §13.2.1 | Start Today's Practice queue population | Search for logic that populates a practice queue from CalendarDay filled slots. |
| 117 | S14 §14.10.5 | Bulk Entry mode (entire feature) | Search for "bulk" in UI files, any batch-entry screen, or a single/bulk toggle in drill entry. |

**Output format per gap:** Same as conflicts but classified as Implemented / Partially Implemented / Not Implemented / Cannot Determine.

---

## Phase 3: Scoring Engine & Core Data Model (S00–S02, S06–S07)

**Goal:** Verify Medium-risk gaps from the scoring core and data model.

**Items to verify (30 gaps from these specs):**

Search the codebase for each of the following. Group your searches by file area to be efficient (e.g., check all schema-related gaps together, all reflow gaps together).

**Schema & Data Model (S06):**
- Gap 37: Session.UserDeclaration column — check Session model/table
- Gap 38: Session.SessionDuration column — check Session model/table

**Scoring Prohibitions (S01):**
- Gap 1: No overperformance tracking — search for any score > 5.0 handling or cap logic
- Gap 2: No automatic anchor adjustment — search for any auto-adjust logic on anchors

**Reflow Governance (S07):**
- Gap 43: Global scoring lock + maintenance banner for system-initiated changes
- Gap 44: System-initiated parallel reflow with concurrency cap
- Gaps 39–42: Client-side prohibitions during lock (buffering, partial save, retry queue, field disabling)

**Drill Entry (S04):**
- Gap 8: Anchor edits blocked while Drill in Retired state — check Drill edit guards
- Gap 9: User must reactivate Drill before editing anchors
- Gap 11: Binary Hit/Miss intention declaration stored on Session
- Gap 14: Bulk Entry mechanism — check for any bulk entry logic

**Review/Analysis (S05):**
- Gaps 23–26: Diagnostic visualisation features (grid distribution, 3x3 derived views, histograms, hit/miss ratio)
- Gap 36: Session duration in Analysis

**Output:** Structured table per sub-group.

---

## Phase 4: UI/UX & Workflow Verification (S03, S05, S08, S12–S14)

**Goal:** Verify Medium and Low-risk gaps related to UI screens, navigation, and workflow features.

**Break into sub-phases:**

### Phase 4A: Navigation & Home Dashboard (S12 §12.2–12.3)
Verify all Home Dashboard gaps (already partially covered in Phase 2). Additionally check:
- Home icon on all tabs
- Tab state preservation on Home navigation
- Settings gear restricted to Home only
- Exit from Live Practice routes to Home

### Phase 4B: Plan Architecture (S12 §12.4, S08)
- Calendar drag-and-drop mechanics
- 2-Week View interactions
- Calendar Bottom Drawer structure
- Save & Practice action after drill creation
- Save as Manual (Clone) feature for Routines

### Phase 4C: Track Architecture (S12 §12.5)
- Filter persistence rules
- Routine list sort order (MRU)
- "Edit Drill" cross-navigation and System Drill hiding

### Phase 4D: Review Architecture (S12 §12.6)
- Comparative Analytics (time range vs time range)
- Technique Block filter exclusion rules
- Volume chart legend specification

### Phase 4E: Live Practice (S13)
- Save Practice as Routine (entire feature)
- Create Drill from Session
- Crash recovery UX
- Deferred Post-Session Summary after auto-end
- Calendar independence rules

### Phase 4F: Drill Entry Screens (S14)
- 80% Screen Takeover pattern
- Undo Last Instance mechanism
- Session Duration Tracking (passive)
- Haptic feedback on Instance save
- Set Transition interstitial
- Portrait-only enforcement
- Submit + Save dual-action buttons

**Output:** Structured table per sub-phase.

---

## Phase 5: Configuration & Integrity Verification (S09–S11)

**Goal:** Verify gaps related to Golf Bag, Settings, and Metrics Integrity.

### Phase 5A: Golf Bag (S09)
- Hard gate enforcement across all 6 contexts (creation, adoption, Routine, Schedule, Calendar Slot, Session)
- Gate activation on last-club retirement
- Bag setup during onboarding
- Standard 14-club preset in seed data or onboarding flow

### Phase 5B: Settings (S10)
- Anchor edits blocked in Retired state (repeat verification if not covered in Phase 3)
- Per-drill unit override at creation with post-creation immutability
- Week start day setting
- Date range persistence (1 hour timer)
- No preview simulation / no impact estimation

### Phase 5C: Metrics Integrity (S11)
- Technique Block duration bounds (0-43200s) in MetricSchema seed data
- Boundary values (exactly equal) not in breach — check comparison operators (< vs <=)
- No deferred batch/sweep/scheduled evaluation

**Output:** Structured table per sub-phase.

---

## Phase 6: Infrastructure & Design System (S15–S17)

**Goal:** Verify gaps in branding, database operations, and application-layer constraints.

### Phase 6A: Design Tokens & Branding (S15)
Focus on items that can be verified in code (skip informational/governance items):
- color.primary.focus token (60% opacity focus ring)
- surface.scrim token
- Segmented control radius values
- Motion timing tokens (verify 200ms max)
- WCAG contrast ratios on critical surfaces (check if any accessibility testing exists)

### Phase 6B: Database Operations (S16)
- Partial indexes on IsDeleted=false — check migration files
- Transaction isolation levels (Repeatable Read default, Serializable for materialised swap)
- Retry parameters (6 categories) — search for retry logic
- RPO/RTO configuration or documentation
- Backup strategy configuration
- Connection pooling configuration
- Performance monitoring setup

### Phase 6C: Application Layer (S17)
- Sync-triggered rebuild priority model (non-blocking, user-initiated takes priority)
- Manual sync trigger in Settings
- Schema migration backward compatibility checks
- Device deregistration behaviour
- No automatic data pruning enforcement

**Output:** Structured table per sub-phase.

---

## Phase 7: Report Assembly

**Goal:** Produce the final consolidated reconciliation report.

**Actions:**

1. Compile all phase outputs into the final `Gap Reconciliation Report v1.md`.
2. Add a master summary table at the top:

```markdown
## Executive Summary

| Category | Total | Implemented | Partially Implemented | Not Implemented | Cannot Determine |
|----------|-------|-------------|----------------------|-----------------|-----------------|
| Conflicts | 7 | | | | |
| High-risk gaps | 5 | | | | |
| Medium-risk gaps | 61 | | | | |
| Low-risk gaps (sampled) | X | | | | |
| **Total verified** | | | | | |
```

3. Add a "Critical Findings" section listing:
   - Any High-risk gaps that are Not Implemented
   - Any conflicts that remain Unresolved
   - Any Medium-risk gaps classified as Not Implemented that have functional impact

4. Add a "Recommendations" section with prioritised next steps.

5. Ensure every gap number from the consolidated analysis is traceable in the report.

---

## Execution Notes

- **Estimated scope:** ~222 gaps + 7 conflicts. Phases 3–6 contain the bulk of the work.
- **Efficiency tip:** When searching for a group of related items, open the relevant files once and check multiple items against them rather than searching file-by-file per item.
- **Low-risk items:** For Low-risk gaps (156 items), you do not need to verify every single one exhaustively. Prioritise those with functional impact (validation rules, data model columns, feature existence). For design governance items (prohibition lists, tone guidelines, spacing rules), a spot-check of 3–5 representative items per category is sufficient — note which were spot-checked.
- **If the codebase is very large:** Focus Phases 3–6 on Medium and High-risk items first. Low-risk items can be deferred to a follow-up pass if needed.
- **Known deviations:** If CLAUDE.md or equivalent documents any item as intentionally deferred or known deviation, classify it as "Not Implemented (Known Deviation)" rather than just "Not Implemented".

---

*End of Action Plan*
