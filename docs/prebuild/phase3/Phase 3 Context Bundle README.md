# Phase 3 Context Bundle — Drill & Bag Configuration

Per TD-08 §3.1–3.2, every Phase 3 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.docx` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.docx` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 3 section) | Extract | `docs/phase3/TD-06 Phase 3 Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 3 Specific Context
| Document | Load | Location |
|---|---|---|
| S04 — Drill Entry System | Full | `docs/specs/S04 Drill Entry System.docx` |
| S09 — Golf Bag & Club Configuration | Full | `docs/specs/S09 Golf Bag and Club Configuration.docx` |
| S14 — Drill Entry Screens & System Drill Library | Full | `docs/specs/S14 Drill Entry Screens and System Drill Library.docx` |
| TD-03 §3.3.2, §3.3.5 — DrillRepository, ClubRepository | Extract | `docs/phase3/TD-03 Phase 3 Extract.md` |
| TD-04 §2.4–2.5, §2.10 — Drill, Adoption, UserClub state machines | Extract | `docs/phase3/TD-04 Phase 3 Extract.md` |
| TD-07 §4 — Validation Errors | Extract | `docs/phase3/TD-07 Phase 3 Extract.md` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
