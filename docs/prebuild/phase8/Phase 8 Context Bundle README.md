# Phase 8 Context Bundle — Polish & Hardening

Per TD-08 §3.1–3.2, every Phase 8 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.md` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.md` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 8 section + §18–19) | Extract | `docs/phase8/TD-06 Phase 8 Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 8 Specific Context
| Document | Load | Location |
|---|---|---|
| S10 — Settings & Configuration | Full | `docs/specs/S10 Settings and Configuration.md` |
| S11 — Metrics Integrity & Safeguards | Full | `docs/specs/S11 Metrics Integrity and Safeguards.md` |
| S12 — UI/UX Structural Architecture | Full | `docs/specs/S12 UI UX Structural Architecture.md` |
| S15 — Branding & Design System | Full | `docs/specs/S15 Branding and Design System.md` |
| S17 §17.3.5 — Local Storage Model (Storage Monitoring) | Extract | `docs/phase8/S17 Phase 8 Extract.md` |
| TD-07 §7, §13, §14 — System Errors, Partial Save Recovery, Data Integrity | Extract | `docs/phase8/TD-07 Phase 8 Extract.md` |


## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
