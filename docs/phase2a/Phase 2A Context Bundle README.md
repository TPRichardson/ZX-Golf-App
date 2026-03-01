# Phase 2A Context Bundle — Pure Scoring Library

Per TD-08 §3.1–3.2, every Phase 2A Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.docx` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.docx` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 2A section) | Extract | `docs/phase2a/TD-06 Phase 2A Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 2A Specific Context
| Document | Load | Location |
|---|---|---|
| S01 — Scoring Engine | Full | `docs/specs/S01 Scoring Engine.docx` |
| S02 — Skill Architecture & Weighting Framework | Full | `docs/specs/S02 Skill Architecture and Weighting Framework.docx` |
| TD-05 §4–9 — Scoring Test Cases | Extract | `docs/phase2a/TD-05 Phase 2A Extract.md` |
| S14 §14.1–14.6 — V1 drill anchors (test fixture reference data) | Extract | `docs/phase2a/S14 Phase 2A Extract.md` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
