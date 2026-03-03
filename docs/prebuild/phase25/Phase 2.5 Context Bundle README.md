# Phase 2.5 Context Bundle — Server Foundation

Per TD-08 §3.1–3.2, every Phase 2.5 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.docx` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.docx` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (reuse from Phase 1) |
| TD-06 — Build Plan (Phase 2.5 section) | Extract | `docs/phase25/TD-06 Phase 2.5 Extract.md` |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (reuse §2/§3/§10 only) |

## Phase 2.5 Specific Context
| Document | Load | Location |
|---|---|---|
| S16 — Database Architecture | Full | `docs/specs/S16 Database Architecture.docx` |
| TD-02 — DDL Schema | Full | `docs/td/TD-02v a6 DDL Schema.docx` |
| TD-03 §5 — Sync Transport Layer | Extract | `docs/phase25/TD-03 Phase 2.5 Extract.md` |
| TD-03 §8 — Authentication & Authorisation | Extract | `docs/phase25/TD-03 Phase 2.5 Extract.md` |
| TD-07 §6 — Sync Errors | Extract | `docs/phase25/TD-07 Phase 2.5 Extract.md` |
| TD-07 §9 — Authentication Errors | Extract | `docs/phase25/TD-07 Phase 2.5 Extract.md` |
| S17 §17.4.1–17.4.3 — Sync transport basics | Extract | `docs/phase25/S17 Phase 2.5 Extract.md` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md and confirm all loaded document versions match the Build Baseline Declaration v3.
