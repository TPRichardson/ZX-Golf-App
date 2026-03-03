# Phase 5 Context Bundle — Planning Layer

Per TD-08 §3.1–3.2, every Phase 5 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.md` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.md` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 5 section) | Extract | `docs/phase5/TD-06 Phase 5 Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 5 Specific Context
| Document | Load | Location |
|---|---|---|
| S08 — Practice Planning Layer | Full | `docs/specs/S08 Practice Planning Layer.md` |
| TD-03 §3.3.6 — PlanningRepository | Extract | `docs/phase5/TD-03 Phase 5 Extract.md` |
| TD-04 §2.6, §2.8–2.9 — CalendarDay Slot, Routine, Schedule state machines | Extract | `docs/phase5/TD-04 Phase 5 Extract.md` |
| TD-07 §4 — Validation Errors | Extract | `docs/phase3/TD-07 Phase 3 Extract.md` (reuse from Phase 3) |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
