# Phase 7C Context Bundle — Conflict UI & Offline Hardening

Per TD-08 §3.1–3.2, every Phase 7C Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.md` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.md` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 7C section) | Extract | `docs/phase7c/TD-06 Phase 7C Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 7C Specific Context
| Document | Load | Location |
|---|---|---|
| S17 — Real-World Application Layer | Full | `docs/specs/S17 Real World Application Layer.md` |
| S15 — Branding & Design System | Full | `docs/specs/S15 Branding and Design System.md` |
| TD-01 §2.9, §3.3 — Schema Version Gating, Token Lifecycle | Extract | `docs/phase7c/TD-01 Phase 7C Extract.md` |
| TD-07 §6, §9, §12 — Sync Errors, Auth Errors, Graceful Degradation | Extract | `docs/phase7c/TD-07 Phase 7C Extract.md` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
