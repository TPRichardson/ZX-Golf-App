TD-08 — Claude Code Prompt Architecture

Version TD-08v.a3 — Canonical

Harmonised with: Section 0 (0v.f1), Section 1 (1v.g2), Section 2 (2v.f1), Section 3 (3v.g8), Section 4 (4v.g9), Section 5 (5v.d6), Section 6 (6v.b7), Section 7 (7v.b9), Section 8 (8v.a8), Section 9 (9v.a2), Section 10 (10v.a5), Section 11 (11v.a5), Section 12 (12v.a5), Section 13 (13v.a7), Section 14 (14v.a4), Section 15 (15v.a3), Section 16 (16v.a5), Section 17 (17v.a4), TD-01 (TD-01v.a4), TD-02 (TD-02v.a6), TD-03 (TD-03v.a5), TD-04 (TD-04v.a4), TD-05 (TD-05v.a3), TD-06 (TD-06v.a6), TD-07 (TD-07v.a4).

This document defines how Claude Code consumes the ZX Golf App specification suite during development. It specifies which documents are loaded for each build phase, the CLAUDE.md governance file, prompt templates for each task type, codebase conventions, and verification checkpoints. Claude Code must treat this document as authoritative for all session configuration and prompting decisions.

1. Purpose

The ZX Golf App specification suite comprises 18 product specification sections (Section 0–17) and 8 technical design documents (TD-01–TD-08). These 26 documents exceed the context window capacity of any single Claude Code session. TD-08 solves this constraint by defining a context loading strategy that provides each session with the minimum necessary and sufficient documentation to build its assigned phase correctly.

TD-06 is the master sequencing document that defines what is built in each phase. TD-08 is the companion document that defines what Claude Code reads in each phase. Together they govern all Claude Code sessions.

Deliverable: This specification document plus a draft CLAUDE.md file for the project repository.

2. Complete Artifact Inventory

The following table lists every document in the specification suite. Each document is assigned a short reference ID used throughout this document and in CLAUDE.md.

2.1 Product Specification Sections

  --------- -------------------------------------------- --------- -------------
  ID        Title                                        Version   Est. Tokens

  S00       Canonical Terminology & Definitions          0v.f1     Medium

  S01       Scoring Engine                               1v.g2     Large

  S02       Skill Architecture & Weighting Framework     2v.f1     Medium

  S03       User Journey Architecture                    3v.g8     Large

  S04       Drill Entry System                           4v.g9     Large

  S05       Review: SkillScore & Analysis                5v.d6     Medium

  S06       Data Model & Persistence Layer               6v.b7     Large

  S07       Reflow Governance System                     7v.b9     Large

  S08       Practice Planning Layer                      8v.a8     Large

  S09       Golf Bag & Club Configuration                9v.a2     Medium

  S10       Settings & Configuration                     10v.a5    Medium

  S11       Metrics Integrity & Safeguards               11v.a5    Medium

  S12       UI/UX Structural Architecture                12v.a5    Medium

  S13       Live Practice Workflow                       13v.a7    Large

  S14       Drill Entry Screens & System Drill Library   14v.a4    Large

  S15       Branding & Design System                     15v.a3    Large

  S16       Database Architecture                        16v.a5    Large

  S17       Real-World Application Layer                 17v.a4    Large
  --------- -------------------------------------------- --------- -------------

2.2 Technical Design Documents

  --------- ------------------------------------------------- ----------- -------------
  ID        Title                                             Version     Est. Tokens

  TD-01     Technology Stack Decisions                        TD-01v.a3   Large

  TD-02     Database DDL Schema                               TD-02v.a4   Large

  TD-03     API Contract Layer                                TD-03v.a4   Large

  TD-04     Entity State Machines & Reflow Process            TD-04v.a3   Large

  TD-05     Scoring Engine Test Cases                         TD-05v.a3   Large

  TD-06     Phased Build Plan                                 TD-06v.a4   Large

  TD-07     Error Handling Patterns                           TD-07v.a4   Large

  TD-08     Claude Code Prompt Architecture (this document)   TD-08v.a3   Large
  --------- ------------------------------------------------- ----------- -------------

3. Context Loading Strategy

Every Claude Code session loads two categories of context: Always-Loaded Context (present in every session regardless of phase) and Phase-Specific Context (additional documents loaded for the current build phase). The CLAUDE.md file provides persistent project-level context and is always present by virtue of residing in the repository root.

3.1 Always-Loaded Context

The following artefacts must be present in every Claude Code session. They provide the foundational vocabulary, structural decisions, and phase scoping that every task requires.

  ------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Artefact                                          Justification

  CLAUDE.md (project root)                          Persistent conventions, directory map, naming rules, source-of-truth hierarchy. Loaded automatically by Claude Code.

  S00 — Canonical Definitions                       Every session must use correct terminology. Misaligned terminology produces specification violations.

  S06 — Data Model (Sections 1–5 only)              Entity definitions and relationship overview. Required to understand any data operation. The full cascade rules and JSON column specifications are loaded phase-specifically when needed.

  TD-01 — Technology Stack                          Platform, sync, security, and scale decisions govern all implementation choices. Always needed.

  TD-02 — DDL Schema (machine-generated snapshot)   A machine-generated DDL snapshot table that includes: every table name, every column with type, NOT NULL, DEFAULT value, FK target, ON DELETE behaviour, and index coverage. This snapshot must be auto-generated from the canonical TD-02 DDL — never hand-summarised. Hand summarisation risks omitting sync columns, CHECK constraints, or trigger rules that produce catastrophic divergence. The full DDL is loaded phase-specifically for schema work.

  TD-06 — Build Plan (current phase only)           The specific phase section from TD-06 that defines scope, deliverables, stubs, and acceptance criteria. Only the current phase section is loaded, not the full document.

  TD-07 — Error Handling (§2, §3, §10 only)         Error type hierarchy (§2), propagation model (§3), and user-facing message catalogue (§10). These three sections govern error handling patterns in every phase. Phase-specific error sections are loaded when relevant.

  TD-03 §2.1.1 — SyncWriteGate summary              The SyncWriteGate coordinates Repository writes and Sync merge exclusivity. Even pre-sync phases must structure Repository writes to be gate-compatible: all writes through transactions, no long-held write locks, no assumptions about uninterrupted write access. Loading this summary in every session prevents Phase 3–6 repository code from being structurally incompatible with sync.
  ------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

The always-loaded context is deliberately minimal. It provides vocabulary (S00), data structure awareness (S06 summary, TD-02 snapshot), platform decisions (TD-01), sync-awareness (TD-03 SyncWriteGate), phase scope (TD-06 extract), error patterns (TD-07 extract), and project conventions (CLAUDE.md). Everything else is phase-specific.

Entity structure conflict rule: S06 (Product Spec) describes entities narratively. TD-02 (DDL Schema) defines them as executable SQL with exact column types, constraints, defaults, and foreign key behaviour. When entity definitions in S06 and TD-02 diverge — on nullability, default values, column types, or constraint behaviour — TD-02 governs. This is a specific application of the general source-of-truth hierarchy (§5.4) but is stated explicitly here because S06 and TD-02 are both always-loaded, making silent divergence a persistent risk.

3.2 Phase-Specific Context

Each build phase loads additional documents beyond the always-loaded set. The following table maps each phase to its required context. Documents listed as “full” are loaded in their entirety. Documents listed with section numbers are loaded as extracts.

+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase                                    | Additional Documents (Full)                      | Additional Documents (Extracts)                                                  |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 1 Data Foundation & Design System  | S15 — Branding & Design System                   | S06 — Data Model (full, replacing summary)                                       |
|                                          |                                                  |                                                                                  |
|                                          | S16 — Database Architecture                      | TD-03 §2.2, §3.1–3.2 (Repository Layer Principles, Repository org, CRUD pattern) |
|                                          |                                                  |                                                                                  |
|                                          | TD-02 — DDL Schema (full)                        | TD-07 §15 (Error handling by build phase, Phase 1)                               |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 2A Pure Scoring Library            | S01 — Scoring Engine                             | S14 §V1 drill anchors table (reference data for test fixtures)                   |
|                                          |                                                  |                                                                                  |
|                                          | S02 — Skill Architecture                         |                                                                                  |
|                                          |                                                  |                                                                                  |
|                                          | TD-05 — Scoring Test Cases (§4–9)                |                                                                                  |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 2.5 Server Foundation              | S16 — Database Architecture                      | S17 §17.4.1–17.4.3 (sync transport basics)                                       |
|                                          |                                                  |                                                                                  |
|                                          | TD-02 — DDL Schema (full)                        | TD-03 §5 (Sync Transport Layer)                                                  |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-03 §8 (Authentication)                                                        |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-07 §6, §9 (Sync errors, Auth errors)                                          |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 2B Reflow & Lock Layer             | S07 — Reflow Governance                          | TD-03 §4 (Reflow Process Contract)                                               |
|                                          |                                                  |                                                                                  |
|                                          | TD-04 — State Machines & Reflow (§3–4)           | TD-07 §5 (Reflow errors)                                                         |
|                                          |                                                  |                                                                                  |
|                                          | TD-05 — Scoring Test Cases (§10–12)              | S16 §16.1.6 (Materialised tables)                                                |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 3 Drill & Bag Configuration        | S04 — Drill Entry System                         | TD-03 §3.3.2, §3.3.5 (DrillRepository, ClubRepository)                           |
|                                          |                                                  |                                                                                  |
|                                          | S09 — Golf Bag & Club Configuration              | TD-04 §2.4–2.5, §2.10 (Drill, Adoption, UserClub state machines)                 |
|                                          |                                                  |                                                                                  |
|                                          | S14 — Drill Entry Screens & System Drill Library | TD-07 §4 (Validation errors)                                                     |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 4 Live Practice                    | S03 — User Journey Architecture                  | S04 (loaded if not already from Phase 3)                                         |
|                                          |                                                  |                                                                                  |
|                                          | S13 — Live Practice Workflow                     | S11 — Metrics Integrity (§11.1–11.6)                                             |
|                                          |                                                  |                                                                                  |
|                                          | S14 — Drill Entry Screens & System Drill Library | TD-03 §3.3.3, §4.4 (PracticeRepository, Session Close Pipeline)                  |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-04 §2.1–2.3 (PracticeEntry, Session, PracticeBlock state machines)            |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-07 §4, §13 (Validation errors, Partial save recovery)                         |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 5 Planning Layer                   | S08 — Practice Planning Layer                    | TD-03 §3.3.6 (PlanningRepository)                                                |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-04 §2.6, §2.8–2.9 (CalendarDay Slot, Routine, Schedule state machines)        |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-07 §4 (Validation errors)                                                     |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 6 Review & Analysis                | S05 — Review: SkillScore & Analysis              | TD-03 §3.3.4 (ScoringRepository read methods)                                    |
|                                          |                                                  |                                                                                  |
|                                          | S12 — UI/UX Structural Architecture              | S16 §16.1.6 (Materialised tables)                                                |
|                                          |                                                  |                                                                                  |
|                                          | S15 — Branding & Design System                   |                                                                                  |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 7A Sync Transport & DTO            | S17 — Real-World Application Layer               | TD-03 §5 (Sync Transport Layer, full)                                            |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-07 §6 (Sync errors)                                                           |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-01 §2 (Sync Strategy, full — always loaded but ensure §2.5–2.11 are present)  |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 7B Merge & Rebuild                 | S17 — Real-World Application Layer               | TD-01 §2.3–2.6 (Merge Precedence, CalendarDay Merge, Pipeline, Atomicity)        |
|                                          |                                                  |                                                                                  |
|                                          | TD-04 — State Machines & Reflow (full)           | TD-03 §5.4–5.5 (Merge Algorithm, Post-Merge Pipeline)                            |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-07 §6, §8 (Sync errors, Conflict resolution)                                  |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 7C Conflict UI & Offline Hardening | S17 — Real-World Application Layer               | TD-01 §2.9, §3.3 (Schema gating, Token lifecycle)                                |
|                                          |                                                  |                                                                                  |
|                                          | S15 — Branding & Design System                   | TD-07 §6, §9, §12 (Sync, Auth, Graceful degradation)                             |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+
| Phase 8 Polish & Hardening               | S10 — Settings & Configuration                   | S12 — UI/UX Structural Architecture                                              |
|                                          |                                                  |                                                                                  |
|                                          | S11 — Metrics Integrity                          | S17 §17.3.5 (Storage monitoring)                                                 |
|                                          |                                                  |                                                                                  |
|                                          | S15 — Branding & Design System                   | TD-07 §7, §13, §14 (System errors, Partial save, Data integrity)                 |
|                                          |                                                  |                                                                                  |
|                                          |                                                  | TD-06 §18–19 (Data migration, Deferred items)                                    |
+------------------------------------------+--------------------------------------------------+----------------------------------------------------------------------------------+

3.3 Context Loading Rules

Rule 1 — Phase boundary enforcement. Claude Code must not load documents for a future phase. If a task requires understanding a future phase’s scope, load only the phase summary row from TD-06 §2, not the full phase section.

Rule 2 — Additive loading. If a task within a phase requires a document not listed in the phase context table, the operator may add it. The phase context table defines the minimum set, not the maximum. However, operator-added documents must belong to the current phase or a prior phase. Loading a document that belongs to a future phase requires explicit justification recorded in the session prompt. This prevents accidental scope contamination — for example, loading the full Phase 7B merge specification during a Phase 3 session would risk Claude Code designing repository methods around merge concerns that are not yet relevant.

Rule 3 — Extract discipline. When a section reference specifies paragraph numbers (e.g. §3.3.2), only those paragraphs are loaded. This prevents context window saturation with irrelevant material.

Rule 4 — CLAUDE.md always wins. If a document extract and CLAUDE.md contain the same information, CLAUDE.md governs. CLAUDE.md is updated as phases complete; document extracts are static.

Rule 5 — No document omission. If the always-loaded or phase-specific context table lists a document for the current phase, it must be loaded. Omitting a listed document is a configuration error.

4. CLAUDE.md Governance

CLAUDE.md resides at the project root and is automatically loaded by Claude Code at the start of every session. It provides persistent context that survives across sessions: project conventions, directory structure, naming rules, and the source-of-truth hierarchy. CLAUDE.md is a living document that is updated as phases complete.

4.1 CLAUDE.md Structure

The CLAUDE.md file is divided into the following sections. Each section has a defined owner (who updates it) and update trigger (when it is updated).

  -------------------------------- ----------------------------------------------------------------------------------------------------------------------------- ------------ ------------------------------------------------
  Section                          Content                                                                                                                       Owner        Update Trigger

  Project Identity                 Application name, description, target platform, technology stack summary (Flutter, Supabase, Drift, Riverpod).                TD-08        Initial creation only.

  Spec Version Registry            Table mapping each spec document ID to its current version string. Used to verify context documents are current.              Operator     When any spec document is revised.

  Source-of-Truth Hierarchy        Precedence rules: TD documents > Product Spec when conflicts exist. S00 governs terminology. CLAUDE.md governs conventions.   TD-08        Initial creation only.

  Current Build Phase              Active phase number (e.g. “Phase 2A”) and one-line scope summary. Claude Code must not generate code outside this scope.      Operator     At the start of each new phase.

  Directory Architecture           Full folder tree with purpose annotations. Mirrors TD-06 §3.1.                                                                Operator     When a phase adds new directories.

  Naming Conventions               File, class, function, variable, database column, and API naming rules (§5.2).                                                TD-08        Initial creation only.

  Code Comment Conventions         When to comment, comment style, spec reference format (§5.3).                                                                 TD-08        Initial creation only.

  Design Token Reference           Colour tokens, typography, spacing, shape values from S15. Quick-reference for every UI session.                              Operator     After Phase 1 establishes the design system.

  Error Handling Quick Reference   Exception class names, propagation pattern summary, log level rules. Condensed from TD-07.                                    Operator     After Phase 1 establishes the error hierarchy.

  Phase Completion Log             Dated entries recording which phases are complete and any deviations from TD-06.                                              Operator     At the end of each phase.

  Known Deviations                 Any implementation decisions that deviate from the spec, with rationale and spec reference.                                   Operator     When a deviation is accepted.
  -------------------------------- ----------------------------------------------------------------------------------------------------------------------------- ------------ ------------------------------------------------

4.2 CLAUDE.md Update Rules

Rule 1 — Version gating. Before starting work, Claude Code must verify that the Spec Version Registry in CLAUDE.md matches the document versions loaded in the session context. If a mismatch is detected, Claude Code must flag it before proceeding.

Rule 2 — Phase lock. The Current Build Phase field in CLAUDE.md is the authoritative scope boundary. Claude Code must not generate code, tests, or configurations that belong to a future phase, even if the prompt asks for it.

Rule 3 — Deviation recording before implementation. If Claude Code discovers that an implementation decision conflicts with the spec (e.g. a Drift limitation prevents exact DDL replication), it must record the deviation in the Known Deviations section before implementing the deviating code. The record must include: the spec reference, the deviation description, and the rationale. This ordering is mandatory — recording after implementation risks the deviation being forgotten or under-documented.

Rule 4 — No arbitrary additions. CLAUDE.md must not contain information that is not sourced from the spec suite or from a recorded deviation. Claude Code must not invent conventions that are not defined in TD-08 §5.

Rule 5 — No invented architecture. Claude Code must not introduce new architectural layers, abstraction tiers, service wrappers, or structural patterns that are not explicitly defined in a TD document. Examples of prohibited inventions: an abstraction service layer not defined in TD-03, a DTO mapper pattern not in TD-03, an additional domain layer between Repository and Drift. If Claude Code believes an additional layer is necessary, it must flag this as an open issue for operator decision and record it as a Known Deviation before proceeding.

Rule 6 — CLAUDE.md must not introduce behavioural rules. CLAUDE.md may only summarise existing rules from the spec suite or record deviations from them. It must not become an informal policy layer that creates new constraints, overrides spec rules without deviation recording, or accumulates undocumented conventions. If a convention in CLAUDE.md cannot be traced to a specific TD or Product Spec source, it must be removed or recorded as a deviation.

5. Codebase Conventions

These conventions are embedded in CLAUDE.md and enforced consistently across all Claude Code sessions. They prevent structural drift when multiple sessions build different parts of the application.

5.1 Directory Architecture Standard

The project follows the feature-first directory structure established in TD-06 §3.1. The following is the canonical directory tree. Claude Code must place files in the correct directory. No new top-level directories may be created without operator approval.

  --------------------------- --------------------------------------------------------------------- ----------------
  Path                        Purpose                                                               Established In

  lib/core/                   Design tokens, theme, shared widgets, constants, error types.         Phase 1

  lib/core/scoring/           Pure scoring functions (Phase 2A), reflow orchestration (Phase 2B).   Phase 2A

  lib/core/sync/              Sync engine, merge algorithm, SyncWriteGate.                          Phase 2.5

  lib/core/instrumentation/   Logging, diagnostics, profiling, dev tools.                           Phase 2B

  lib/core/services/          TimerService and other shared service abstractions.                   Phase 4

  lib/data/                   Drift database definition, DAOs, repository layer.                    Phase 1

  lib/data/dto/               Sync DTO serialisation classes.                                       Phase 2.5

  lib/features/drill/         Drill browsing, creation, editing UI.                                 Phase 3

  lib/features/bag/           Golf bag configuration UI.                                            Phase 3

  lib/features/practice/      Live practice workflow UI.                                            Phase 4

  lib/features/planning/      Routines, Schedules, Calendar UI.                                     Phase 5

  lib/features/review/        SkillScore dashboard, analysis screens.                               Phase 6

  lib/features/settings/      Settings screens.                                                     Phase 8

  lib/providers/              Riverpod providers, organised by domain.                              Phase 1

  test/                       Mirrors lib/ structure. Unit and integration tests.                   Phase 1

  test/fixtures/              Shared test data builders and factory methods.                        Phase 2A

  supabase/migrations/        001_create_schema.sql, 002_seed_reference_data.sql, etc.              Phase 2.5
  --------------------------- --------------------------------------------------------------------- ----------------

5.2 Naming Conventions

  --------------------------------- -------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------
  Element                           Convention                                                                                                           Examples

  Dart files                        snake_case.dart. One public class per file. File name matches class name.                                            scoring_repository.dart, practice_block.dart

  Dart classes / types              UpperCamelCase. Suffix with purpose: Repository, Provider, Service, Widget, State, Exception.                        ScoringRepository, PracticeBlockState, DrillWidget

  Dart functions                    lowerCamelCase. Verb-first for actions. Noun-first for getters.                                                      closeSession(), executeReflow(), getDrillById()

  Dart variables / fields           lowerCamelCase. No abbreviations except universally understood (id, url, dto).                                       sessionScore, practiceBlock, userId

  Dart constants                    lowerCamelCase with k prefix for non-obvious constants. Enum-like constants in SCREAMING_SNAKE_CASE only in enums.   kMaxWindowOccupancy = 25.0, kTransitionWeight = 0.35

  Riverpod providers                lowerCamelCase + Provider suffix. Match the repository or service they expose.                                       scoringRepositoryProvider, drillRepositoryProvider

  Drift tables (Dart)               UpperCamelCase plural for table class. Singular for companion row class (Drift convention).                          class Sessions extends Table {}, Session row class

  Database columns (SQL/Drift)      UpperCamelCase matching entity field names in S06. Drift generates snake_case SQL from these.                        UserID, CompletionTimestamp, IsDeleted, UpdatedAt

  Supabase RPC functions            snake_case. Verb_noun pattern.                                                                                       sync_upload, sync_download

  Test files                        snake_case_test.dart. Match the file under test.                                                                     scoring_repository_test.dart, instance_scoring_test.dart

  Test methods                      Descriptive sentence with underscores or descriptive lowerCamelCase. Clearly state the scenario.                     test('scoreInstance returns 0 when rawValue below min')

  JSON keys (RawMetrics, Anchors)   camelCase matching the field names in TD-03 §9 payload shapes.                                                       hitRate, carryDistance, minAnchor, scratchAnchor

  Feature branch names              phase/N-short-description. Lowercase with hyphens.                                                                   phase/2a-pure-scoring, phase/4-live-practice
  --------------------------------- -------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------

5.3 Code Comment Conventions

Comments exist to link implementation to specification, explain non-obvious decisions, and mark phase boundaries. Claude Code must not write comments that restate what the code does.

  --------------------- --------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------
  Comment Type          Format                                                                                                                When Required

  Spec reference        // Spec: S07 §7.2 — Reflow trigger: anchor edit                                                                       Every method that implements a specific spec rule. Links auditable implementation to spec source.

  TD reference          // TD-04 §3.2 Step 4 — Scope determination                                                                            Every method that implements a specific TD design decision.

  Deviation note        // DEVIATION: TD-02 specifies CHECK constraint; Drift enforces via Dart validation. See CLAUDE.md Known Deviations.   Every implementation that deviates from spec.

  Phase boundary        // Phase 3 stub — replaced in Phase 5 (completion matching)                                                           Every stub placeholder that will be replaced in a future phase.

  Non-obvious logic     // Dual-mapped drills contribute 0.5 to each subskill window, not 1.0                                                 Complex business logic where the reasoning is not self-evident from the code.

  No comment required   —                                                                                                                     Standard CRUD operations, obvious Dart idioms, self-descriptive method names.
  --------------------- --------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------

Comment density target: approximately one spec or TD reference comment per public method in the repository and scoring layers. UI widget code requires fewer comments; the spec section reference in the file header is usually sufficient.

5.4 Source-of-Truth Hierarchy

When documents conflict, the following precedence applies. Higher-numbered items take precedence over lower-numbered items.

  ------------- ------------------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Precedence    Source                                     Rationale

  1 (lowest)    Product Specification (S00–S17)            Defines business rules and user-facing behaviour. Written first; may contain ambiguities resolved by TD documents.

  2             Technical Design documents (TD-01–TD-08)   Resolves implementation ambiguities in the product spec. Written later with full knowledge of the spec. TD documents are more specific and more recent.

  3             CLAUDE.md Known Deviations                 Records intentional departures from both spec and TD documents, with rationale. These represent reality.

  4 (highest)   Operator instruction in session            Real-time corrections or clarifications override all written documents for the current session. Any operator instruction that contradicts a TD or Product Spec rule must be recorded in Known Deviations before implementation proceeds (§4.2 Rule 3). This prevents offhand clarifications from silently overriding critical rules such as the scoring model or sync determinism.
  ------------- ------------------------------------------ ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

S00 (Canonical Definitions) has a special status: it governs terminology across all documents at all precedence levels. If a TD document uses a term differently from S00, S00 governs.

5.5 Spec Version Tracking

The codebase records which specification version it was built against using two mechanisms.

Mechanism 1 — CLAUDE.md Spec Version Registry. A table in CLAUDE.md maps each document ID (S00, S01, … S17, TD-01, … TD-08) to its version string (e.g. 0v.f1, TD-01v.a3). The operator updates this table when a spec document is revised. Claude Code checks this table at session start.

Mechanism 2 — Code-level spec references. Comment references (// Spec: S07 §7.2) link code to the spec section that governs it. If a spec section is revised, a search for “Spec: S07” identifies all code that may need updating. This provides a lightweight traceability mechanism without introducing formal requirements management tooling.

No build-time version check is required. Version tracking is a human-readable audit trail, not an automated enforcement mechanism.

6. Prompt Templates

The following templates define the standard prompt structure for each type of Claude Code task. The operator customises the template parameters for each session. The structure ensures Claude Code receives consistent, complete instructions.

6.1 New Module Prompt

Used when building a new feature module within the current phase.

  --------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Section               Content

  Phase Context         You are working on Phase [N] of the ZX Golf App build. Scope: [one-line summary from TD-06]. Do not implement anything outside this phase scope.

  Task                  Implement [module name]. This module covers: [bullet list of deliverables from TD-06 for this task].

  Spec References       The following specification sections govern this module: [list loaded documents with section numbers]. Read them carefully before generating code.

  Conventions           Follow all conventions in CLAUDE.md. In particular: [highlight any conventions especially relevant to this module].

  Stubs                 The following dependencies are stubbed for this phase: [list from TD-06 stubs section]. Do not implement stub internals.

  Acceptance Criteria   This module is complete when: [paste relevant acceptance criteria from TD-06].

  Output Format         Generate files in the correct directory per CLAUDE.md directory architecture. Include spec reference comments. Include unit tests in the corresponding test/ directory if automated tests are required for this module.
  --------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

6.2 Test Writing Prompt

Used when generating automated tests for a completed or in-progress module.

  ---------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Section          Content

  Phase Context    You are writing tests for Phase [N] of the ZX Golf App build.

  Test Source      Implement the following test cases from TD-05: [list specific sections, e.g. §4.1–4.6 for Instance scoring]. Each test case is defined as Given → When → Then with exact expected values.

  Test Framework   Use Flutter’s test package. Group tests by section. Use descriptive test names that reference the TD-05 section (e.g. “TD-05 §4.1 — Grid Cell Selection hit-rate scoring”).

  Precision        All numeric assertions use 1e-9 tolerance (TD-05 §2.2). No intermediate rounding.

  Fixtures         Place shared test data builders in test/fixtures/. Reuse existing fixtures where available.

  Coverage         Every test case listed in the Test Source section must have a corresponding test method. The test runner must report 100% pass rate for the specified sections.
  ---------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

6.3 Bug Fix Prompt

Used when Claude Code must diagnose and fix a defect.

  -------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------
  Section              Content

  Symptom              Describe the observed behaviour: [what happens, when, with what inputs].

  Expected Behaviour   Per [spec reference], the correct behaviour is: [paste the spec rule that defines correct behaviour].

  Reproduction         [Steps to reproduce, or the failing test case name and output].

  Scope Constraint     Fix must not alter behaviour outside the affected module. If the fix requires a design change, flag it as a potential deviation before implementing.

  Verification         The fix is complete when: [the specific test case passes / the acceptance criterion is met].
  -------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------

6.4 Refactoring Prompt

Used when restructuring existing code without changing behaviour.

  ---------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Section          Content

  Motivation       Describe why the refactoring is needed: [e.g. preparing for Phase 7B merge logic, extracting shared utility].

  Scope            Refactoring is limited to: [list files or modules affected].

  Invariant        All existing tests must pass before and after the refactoring. No test modifications are permitted unless a test is testing internal implementation details rather than behaviour.

  Conventions      The refactored code must comply with CLAUDE.md conventions. This is an opportunity to correct any naming or structure drift.

  Output           Provide the refactored files and confirm all tests pass.
  ---------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

7. Verification Checkpoints

At the end of each Claude Code session, the operator verifies output against the spec using the following checkpoint categories. Not every checkpoint applies to every session; the operator selects the relevant checks.

7.1 Structural Verification

  ------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Checkpoint                     Verification Method

  Files in correct directories   Compare generated file paths against CLAUDE.md directory architecture.

  Naming conventions followed    Spot-check: file names (snake_case), class names (UpperCamelCase + suffix), provider names (lowerCamelCase + Provider).

  No future-phase code           Search for class names, imports, or features that belong to a phase after the current one.

  Stubs present and minimal      Verify stub classes exist with correct method signatures but no implementation beyond what the current phase requires.

  No orphan files                Every generated file is either imported by another file or is a test file.

  No invented architecture       No new layers, services, or abstraction tiers exist that are not defined in TD-03 or another TD document. Every class must trace to a TD-defined pattern (§4.2 Rule 5).
  ------------------------------ -------------------------------------------------------------------------------------------------------------------------------------------------------------------------

7.2 Behavioural Verification

  --------------------------------- --------------------------------------------------------------------------------------------------------------------------
  Checkpoint                        Verification Method

  Acceptance criteria met           Walk through each acceptance criterion from TD-06 for the current phase. Verify manually or via test output.

  Required tests pass               Run test suite. All tests for the current phase must pass (100% for automated test phases).

  Spec rule compliance              For each spec reference comment in the generated code, verify the implementation matches the referenced spec rule.

  State machine guard enforcement   For phases with state machines (3, 4, 5, 7B): verify every prohibited transition in TD-04 is guarded.

  Error handling present            Verify repository methods return ZxGolfAppException subclasses per TD-07. No raw exceptions escape the repository layer.
  --------------------------------- --------------------------------------------------------------------------------------------------------------------------

7.3 Data Integrity Verification

  ------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Checkpoint                      Verification Method

  DDL alignment                   Compare Drift table definitions against TD-02. Every NOT NULL, DEFAULT, and FK must match.

  Seed data completeness          Verify all seed data from TD-02 is loaded: 19 Subskills (allocations sum to 1000), 28 System Drills, 13 EventTypes, 8 MetricSchemas.

  Sync column presence            Every synced table has UpdatedAt and IsDeleted. EventLog has CreatedAt only.

  Materialised table isolation    Materialised tables are local-only. No sync DTO references them. No RLS policy references them.

  JSON payload shape compliance   RawMetrics, Anchors, SubskillMapping, Slots, and Entries JSON structures match TD-03 §9 exactly.

  DTO-to-DDL consistency          For phases that modify Drift entity shapes (Phases 3–8) or DTO serialisation (Phases 2.5, 7A): verify that every synced entity’s DTO serialisation round-trips correctly against the current Drift schema. A Drift column addition or type change without a corresponding DTO update produces silent sync data loss. This check is mandatory before any phase that touches both data layers is marked complete.
  ------------------------------- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

7.4 Performance Verification

Performance verification applies to specific phases as defined in TD-06. Performance targets are hard phase gates: if a performance target listed below is not met for the current phase, the phase cannot be marked complete. This is consistent with TD-06’s instrumentation-first design decision and TD-01’s deterministic reflow model, which requires predictable performance under defined data volumes.

  ------------ ----------------------------------------------- -------------------
  Phase        Performance Check                               Target

  Phase 1      App launch on Pixel 5a emulator                 < 3 seconds

  Phase 2.5    RLS 4-join query at 1,000 rows/table            < 50ms

  Phase 2B     Scoped reflow at 500 Sessions / 5K Instances    < 150ms (p95)

  Phase 2B     Full rebuild at 5K Sessions / 50K Instances     < 1 second (p95)

  Phase 2B     Peak heap during 50K Instance rebuild           ≤ 256MB

  Phase 6      Dashboard cold-start from materialised tables   < 1 second

  Phase 7A     RLS query at 100K Instances, cold cache         < 200ms
  ------------ ----------------------------------------------- -------------------

Measurement discipline: all performance measurements must be reproducible. Latency targets (p50, p95, p99) are captured using the profiling benchmark harness built in Phase 2B (TD-06 §7.1.2), which executes the operation over 10 consecutive runs and reports percentile timings. Heap allocation is captured via Dart’s ProcessInfo or equivalent runtime introspection. App launch timing uses Android’s reported time-to-first-frame on the Pixel 5a emulator baseline (TD-01 §4.2). Each performance measurement recorded in the Phase Completion Log must include: the harness or tool used, the data volume under test, and the observed p95 value. Subjective timing estimates (e.g. “felt fast enough”) are not acceptable evidence of target compliance.

8. Session Workflow

Every Claude Code session follows this sequence. Steps 1–3 are pre-session setup by the operator. Steps 4–6 are the Claude Code working session. Step 7 is post-session verification.

  ------ ------------------------------------------------------------------------------------------------------------------------------------------------- -------------
  Step   Action                                                                                                                                            Responsible

  1      Update CLAUDE.md: set Current Build Phase, verify Spec Version Registry, update Directory Architecture if the previous phase added directories.   Operator

  2      Assemble context: load always-loaded documents + phase-specific documents per §3.2.                                                               Operator

  3      Select prompt template (§6.1–6.4) and customise parameters for the specific task.                                                                 Operator

  4      Claude Code reads CLAUDE.md. Verifies Spec Version Registry matches loaded documents. Flags any mismatch.                                         Claude Code

  5      Claude Code executes the task per the prompt. Generates code, tests, and spec reference comments. Records any deviations.                         Claude Code

  6      Claude Code outputs a session summary: files created/modified, tests written, deviations recorded, known issues.                                  Claude Code

  7      Operator runs verification checkpoints (§7). Updates CLAUDE.md Phase Completion Log if phase is complete.                                         Operator
  ------ ------------------------------------------------------------------------------------------------------------------------------------------------- -------------

8.1 Session Summary Format

At the end of every working session, Claude Code must output a structured summary containing the following fields. This enables the operator to quickly verify output and maintain the Phase Completion Log.

  --------------------- ----------------------------------------------------------------------------
  Field                 Content

  Phase                 Current build phase (e.g. Phase 2A).

  Task                  One-line description of what was built or fixed.

  Files Created         List of new files with their directory paths.

  Files Modified        List of modified files with a brief description of changes.

  Tests Written         Count of new test methods and which TD-05/TD-06 sections they cover.

  Tests Passing         Count of passing tests out of total. Must be 100% for the session’s scope.

  Deviations            Any new entries for the Known Deviations section of CLAUDE.md, or “None.”

  Stubs Created         Any new stubs for future phases, with the target phase noted.

  Open Issues           Any unresolved questions or issues requiring operator decision.
  --------------------- ----------------------------------------------------------------------------

9. Draft CLAUDE.md

The following is the initial CLAUDE.md to be placed at the project root before Phase 1 begins. The operator maintains this file across sessions per the update rules in §4.2. Sections marked [PLACEHOLDER] are populated during or after the indicated phase.

The draft CLAUDE.md content is provided as a companion deliverable to this document. It is not embedded inline because CLAUDE.md is a Markdown file intended for the repository, not a subsection of a Word document. The companion file is named CLAUDE.md and follows the structure defined in §4.1.

10. Dependency Map

TD-08 is consumed by the operator during Claude Code session setup. It does not have downstream TD document dependencies because it is the final document in the technical design sequence.

TD-08 depends on all preceding documents:

  ---------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Dependency       What TD-08 Uses From It

  TD-01            Technology stack decisions govern CLAUDE.md project identity, naming conventions (Dart, Flutter, Riverpod patterns), and always-loaded context selection.

  TD-02            DDL schema defines the condensed schema reference for always-loaded context and the full schema for Phase 1 / Phase 2.5 loading.

  TD-03            API contract layer defines repository method signatures referenced in naming conventions and phase-specific context for repository work.

  TD-04            Entity state machines define the state machine guard verification checkpoint and phase-specific context for Phases 3, 4, 5, and 7B.

  TD-05            Scoring test cases define the test writing prompt template structure and Phase 2A/2B context requirements.

  TD-06            Phased Build Plan is the primary input. Phase definitions determine every row in the context loading table (§3.2), all acceptance criteria in verification checkpoints (§7), and the session workflow (§8).

  TD-07            Error handling patterns define the always-loaded error context extracts and phase-specific error sections.

  S00–S17          All product specification sections are mapped to phases in the context loading table. Section content determines which phases require which documents.
  ---------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

11. Version History

  --------------- --------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Version         Date            Changes

  TD-08v.a1       2026-02-27      Initial draft. Complete context loading strategy, CLAUDE.md governance, codebase conventions, prompt templates, verification checkpoints, and session workflow.

  TD-08v.a2       2026-02-27      Incorporated eight refinements: (1) TD-02 always-loaded extract changed from hand-summarised to machine-generated DDL snapshot; (2) explicit S06/TD-02 conflict resolution rule added; (3) TD-03 §2.2 Repository Layer Principles added to Phase 1 context; (4) SyncWriteGate summary (TD-03 §2.1.1) added to always-loaded context; (5) Rule 5 added: no invented architectural layers; (6) Rule 6 added: CLAUDE.md must not introduce behavioural rules; (7) Operator override deviation recording required before implementation (§4.2 Rule 3, §5.4); (8) Performance targets made hard phase gates (§7.4). Structural verification checkpoint added for architectural compliance.

  TD-08v.a3       2026-02-27      Three refinements: (1) Additive loading rule (§3.3 Rule 2) tightened — operator-added documents must belong to current or prior phases; future-phase loading requires explicit justification. (2) DTO-to-DDL consistency verification checkpoint added (§7.3) — mandatory for phases that modify both Drift entity shapes and DTO serialisation. (3) Performance measurement discipline specified (§7.4) — harness methodology, required evidence, and subjective estimates explicitly prohibited.
  --------------- --------------- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

End of TD-08 — Claude Code Prompt Architecture (TD-08v.a3 Canonical)
