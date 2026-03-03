# Phase 6 Context Bundle — Review & Analysis

Per TD-08 §3.1–3.2, every Phase 6 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.md` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.md` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 6 section) | Extract | `docs/phase6/TD-06 Phase 6 Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 6 Specific Context
| Document | Load | Location |
|---|---|---|
| S05 — Review: SkillScore & Analysis | Full | `docs/specs/S05 Review SkillScore and Analysis.md` |
| S12 — UI/UX Structural Architecture | Full | `docs/specs/S12 UI UX Structural Architecture.md` |
| S15 — Branding & Design System | Full | `docs/specs/S15 Branding and Design System.md` |
| TD-03 §3.3.4 — ScoringRepository read methods | Extract | `docs/phase6/TD-03 Phase 6 Extract.md` |
| S16 §16.1.6 — Materialised Tables | Extract | `docs/phase2b/S16 Phase 2B Extract.md` (reuse from Phase 2B) |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
