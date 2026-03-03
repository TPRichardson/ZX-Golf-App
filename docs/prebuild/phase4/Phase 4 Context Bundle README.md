# Phase 4 Context Bundle — Live Practice

Per TD-08 §3.1–3.2, every Phase 4 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.md` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.md` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 4 section) | Extract | `docs/phase4/TD-06 Phase 4 Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 4 Specific Context
| Document | Load | Location |
|---|---|---|
| S03 — User Journey Architecture | Full | `docs/specs/S03 User Journey Architecture.md` |
| S04 — Drill Entry System | Full | `docs/specs/S04 Drill Entry System.md` |
| S13 — Live Practice Workflow | Full | `docs/specs/S13 Live Practice Workflow.md` |
| S14 — Drill Entry Screens & System Drill Library | Full | `docs/specs/S14 Drill Entry Screens and System Drill Library.md` |
| S11 §11.1–11.6 — Metrics Integrity | Extract | `docs/phase4/S11 Phase 4 Extract.md` |
| TD-03 §3.3.3, §4.4 — PracticeRepository, Session Close Pipeline | Extract | `docs/phase4/TD-03 Phase 4 Extract.md` |
| TD-04 §2.1–2.3 — PracticeEntry, Session, PracticeBlock state machines | Extract | `docs/phase4/TD-04 Phase 4 Extract.md` |
| TD-07 §4, §13 — Validation Errors, Partial Save Recovery | Extract | `docs/phase4/TD-07 Phase 4 Extract.md` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
