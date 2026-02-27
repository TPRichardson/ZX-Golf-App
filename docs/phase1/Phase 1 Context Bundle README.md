# Phase 1 Context Bundle — Data Foundation & Design System

Per TD-08 §3.1–3.2, every Phase 1 Claude Code session must load the following context.

## Auto-Loaded (project root)
- `CLAUDE.md` (v.a5) — loaded automatically by Claude Code

## Always-Loaded Context (every session, every phase)
| Document | Load | Location |
|---|---|---|
| S00 — Canonical Terminology & Definitions | Full | `docs/specs/S00 Canonical Terminology and Definitions.docx` |
| TD-01 — Technology Stack Decisions | Full | `docs/td/TD-01v a4 Technology Stack Decisions.docx` |
| TD-03 §2.1.1 — SyncWriteGate summary | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (included) |
| TD-06 — Build Plan (current phase) | Extract | `docs/phase1/TD-06 Phase 1 Extract.md` (included) |
| TD-07 §2, §3, §10 — Error hierarchy, propagation, messages | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (included) |

## Phase 1 Specific Context
| Document | Load | Location |
|---|---|---|
| S06 — Data Model & Persistence Layer | Full (replaces always-loaded summary) | `docs/specs/S06 Data Model and Persistence Layer.docx` |
| S15 — Branding & Design System | Full | `docs/specs/S15 Branding and Design System.docx` |
| S16 — Database Architecture | Full | `docs/specs/S16 Database Architecture.docx` |
| TD-02 — DDL Schema | Full (replaces always-loaded snapshot) | `docs/td/TD-02v a6 Database DDL Schema.docx` |
| TD-03 §2.2, §3.1–3.2 — Repository Layer | Extract | `docs/phase1/TD-03 Phase 1 Extract.md` (included) |
| TD-07 §15 — Error handling by build phase | Extract | `docs/phase1/TD-07 Phase 1 Extract.md` (included) |

## SQL Reference Files
| File | Location |
|---|---|
| 001 create schema v a8.sql | `docs/sql/001 create schema v a8.sql` |
| 002 seed reference data v a6.sql | `docs/sql/002 seed reference data v a6.sql` |

## Verification
Before starting work, Claude Code must check the Spec Version Registry in CLAUDE.md (§1) and confirm all loaded document versions match the Build Baseline Declaration v2.
