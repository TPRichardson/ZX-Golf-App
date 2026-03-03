# Phase 2B Context Bundle — Reflow & Lock Layer

Per TD-08 §3.1–3.2, every Phase 2B Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.docx` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.docx` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 2B section) | Extract | `docs/phase2b/TD-06 Phase 2B Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 2B Specific Context
| Document | Load | Location |
|---|---|---|
| S07 — Reflow Governance | Full | `docs/specs/S07 Reflow Governance System.docx` |
| TD-04 §3–4 — Reflow Process & Cross-Cutting Concerns | Extract | `docs/phase2b/TD-04 Phase 2B Extract.md` |
| TD-05 §10–12 — Reflow Scenarios, Edge Cases, Determinism | Extract | `docs/phase2b/TD-05 Phase 2B Extract.md` |
| TD-03 §4 — Reflow Process Contract | Extract | `docs/phase2b/TD-03 Phase 2B Extract.md` |
| TD-07 §5 — Reflow Errors | Extract | `docs/phase2b/TD-07 Phase 2B Extract.md` |
| S16 §16.1.6 — Materialised Tables | Extract | `docs/phase2b/S16 Phase 2B Extract.md` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
