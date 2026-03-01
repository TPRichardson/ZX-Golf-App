# ZX Golf App — Build Baseline Declaration v3

**Date:** 2026-02-27
**Purpose:** This document declares the exact document versions that form the build input for ZX Golf App V1. All Claude Code sessions must verify loaded context against these versions before starting work (CLAUDE.md §4.2 Rule 1).

---

## Product Specification

| ID  | Document                                   | Version  |
|-----|--------------------------------------------|----------|
| S00 | Canonical Terminology & Definitions        | 0v.f1    |
| S01 | Scoring Engine                             | 1v.g2    |
| S02 | Skill Architecture & Weighting Framework   | 2v.f1    |
| S03 | User Journey Architecture                  | 3v.g8    |
| S04 | Drill Entry System                         | 4v.g9    |
| S05 | Review: SkillScore & Analysis              | 5v.d6    |
| S06 | Data Model & Persistence Layer             | 6v.b7    |
| S07 | Reflow Governance System                   | 7v.b9    |
| S08 | Practice Planning Layer                    | 8v.a8    |
| S09 | Golf Bag & Club Configuration              | 9v.a2    |
| S10 | Settings & Configuration                   | 10v.a5   |
| S11 | Metrics Integrity & Safeguards             | 11v.a5   |
| S12 | UI/UX Structural Architecture              | 12v.a5   |
| S13 | Live Practice Workflow                     | 13v.a7   |
| S14 | Drill Entry Screens & System Drill Library | 14v.a4   |
| S15 | Branding & Design System                   | 15v.a3   |
| S16 | Database Architecture                      | 16v.a5   |
| S17 | Real-World Application Layer               | 17v.a4   |

## Technical Design Documents

| ID    | Document                              | Version    | Filename                                                |
|-------|---------------------------------------|------------|---------------------------------------------------------|
| TD-01 | Technology Stack Decisions            | TD-01v.a4  | TD-01v-a4 Technology Stack Decisions.docx                |
| TD-02 | Database DDL Schema                   | TD-02v.a6  | TD-02v a6 Database DDL Schema.docx                      |
| TD-03 | API Contract Layer                    | TD-03v.a5  | TD-03v a5 API Contract Layer.docx                       |
| TD-04 | Entity State Machines & Reflow Process| TD-04v.a4  | TD-04v a4 Entity State Machines and Reflow Process.docx  |
| TD-05 | Scoring Engine Test Cases             | TD-05v.a3  | TD-05v_a3_Scoring_Engine_Test_Cases.docx                |
| TD-06 | Phased Build Plan                     | TD-06v.a6  | TD-06v a6 Phased Build Plan.docx                        |
| TD-07 | Error Handling Patterns               | TD-07v.a4  | TD-07v_a4_Error_Handling_Patterns.docx                  |
| TD-08 | Claude Code Prompt Architecture       | TD-08v.a3  | TD-08v_a3_Claude_Code_Prompt_Architecture.docx          |

## SQL Files

| File                            | Version    |
|---------------------------------|------------|
| 001_create_schema_v_a8.sql      | TD-02v.a8  |
| 002_seed_reference_data_v_a6.sql| TD-02v.a6  |

## Governance

| File      | Version |
|-----------|---------|
| CLAUDE.md | v.a5    |

---

## Cross-Document Consistency Statement

This baseline was produced after a 15-finding cross-document review and four-stage fix process:

- **Stage 1:** Schema fixes (DDL + seed data) — IsDeleted, UserDevice sync columns, redundant indexes, missing EventTypes
- **Stage 2:** Algorithm and contract fixes — partial roll-off, structural immutability guard, completion matching ownership, EventLog sync path, PracticeEntry query safety, InputMode correction, SyncWriteGate timeout validation, sync download indexes, deferred reflow coalescing
- **Stage 3:** Version alignment — all harmonisation lines, CLAUDE.md registry, this declaration
- **Stage 4:** Verification pass — completed 2026-02-27. All A-section fixes confirmed applied, no new cross-document inconsistencies found. Product rename (ZX Golf App) applied across all documents.

All harmonisation lines in TD-01 through TD-06 and both SQL files have been verified to reference current versions. The CLAUDE.md Spec Version Registry matches this declaration.
