# ZX Golf App — CLAUDE.md (v.a6)

> Persistent context for all Claude Code sessions. Full pre-trim backup: `docs/CLAUDE.md.bak`

---

## Project Identity

- **Application:** ZX Golf App — Golf practice performance tracking and scoring
- **Platform:** Android (Flutter). iOS deployment deferred to post-V1.
- **Backend:** Supabase (Postgres, Auth, Edge Functions, RLS)
- **Local Database:** Drift (SQLite) with code-generated typed Dart classes
- **State Management:** Riverpod
- **Architecture:** Offline-first. All operations execute locally. Sync is additive.
- **Scoring Model:** Deterministic merge-and-rebuild. No device holds authoritative scoring state. All devices converge from identical raw data.

---

## Workflow Rules

- **NEVER use compound shell commands.** `&&`, `;`, and `||` are **forbidden** in all Bash tool calls. This is a hard rule, not a suggestion.
  - **Wrong:** `cd /c/development/projects/claudecode/zx-golf-app && git status`
  - **Right:** `git -C /c/development/projects/claudecode/zx-golf-app status`
  - For non-git commands, issue separate Bash tool calls instead of chaining.
- **Git workflow.** Batch changes into meaningful commits — do not commit/push after every small change. Stage only files relevant to the work done (don't include unrelated changes). Commit and push when explicitly asked.
- **Push notifications.** Pushover notifications are configured via `~/.claude/pushover/notify.py`. The user controls this with "alerts on" / "alerts off". When **alerts are on**, send a notification on every pause where user input is needed — include a brief description of what's needed. When **alerts are off**, never send. Default is **off** unless the user says otherwise. Send via: `python ~/.claude/pushover/notify.py "Your message here"`. If `~/.claude/pushover/notify.py` does not exist on this machine, inform the user and point them to `~/.claude/pushover/SETUP.md` for installation instructions.

---

## Source-of-Truth Hierarchy

When documents conflict, higher precedence wins:

1. **(Lowest)** Product Specification (S00–S17)
2. Technical Design documents (TD-01–TD-08)
3. CLAUDE.md Known Deviations
4. **(Highest)** Operator instruction in the current session

**Exception:** S00 (Canonical Definitions) governs terminology at all levels.

**Entity structure rule:** When entity definitions in S06 and TD-02 diverge (nullability, defaults, column types, constraints), TD-02 governs.

**Operator override rule:** Any operator instruction that contradicts a TD or Product Spec rule must be recorded in Known Deviations **before** implementation proceeds (TD-08 §4.2 Rule 3).

---

## Architectural Integrity Rules

- **No invented architecture.** Do not introduce new architectural layers, abstraction tiers, service wrappers, or structural patterns not explicitly defined in a TD document. Flag as an open issue if you believe one is needed (TD-08 §4.2 Rule 5).
- **CLAUDE.md scope restriction.** This file may only summarise existing spec/TD rules or record deviations. It must not create new behavioural rules or undocumented conventions (TD-08 §4.2 Rule 6).
- **SyncWriteGate awareness.** All Repository writes must be structured for gate compatibility from Phase 1 onward: writes through transactions, no long-held write locks, no assumptions about uninterrupted write access (TD-03 §2.1.1).
- **Cross-screen deduplication.** When implementing 3+ screens with the same parent concept, extract shared scaffolding into a single host widget with swappable content.

---

## Current Build Phase

> **Complete (V1 + Matrix & Gapping System + Server-Authoritative Drills)**
>
> All 8 core phases + 10 matrix phases implemented. Standard drills are server-authoritative.
> 1090 tests passing, 12 pre-existing C-1 scoring pipeline failures (phantom drill IDs).

---

## Naming Conventions

| Element              | Convention                                    | Example                              |
|----------------------|-----------------------------------------------|--------------------------------------|
| Dart files           | `snake_case.dart`. One public class per file. | `scoring_repository.dart`            |
| Classes / types      | `UpperCamelCase` + purpose suffix.            | `ScoringRepository`, `DrillWidget`   |
| Functions            | `lowerCamelCase`. Verb-first for actions.     | `closeSession()`, `getDrillById()`   |
| Variables / fields   | `lowerCamelCase`. No abbreviations.           | `sessionScore`, `practiceBlock`      |
| Constants            | `lowerCamelCase` with `k` prefix.             | `kMaxWindowOccupancy = 25.0`         |
| Riverpod providers   | `lowerCamelCase` + `Provider`.                | `scoringRepositoryProvider`          |
| Drift tables (Dart)  | `UpperCamelCase` plural.                      | `class Sessions extends Table {}`    |
| DB columns           | `UpperCamelCase` per S06.                     | `UserID`, `CompletionTimestamp`      |
| Test files           | `snake_case_test.dart`.                       | `instance_scoring_test.dart`         |
| JSON keys            | `camelCase` per TD-03 §9.                     | `hitRate`, `minAnchor`               |

---

## Code Comment Conventions

| Type              | Format                                                                 | When Required                                     |
|-------------------|------------------------------------------------------------------------|---------------------------------------------------|
| Spec reference    | `// Spec: S07 §7.2 — Reflow trigger: anchor edit`                     | Every method implementing a specific spec rule.   |
| TD reference      | `// TD-04 §3.2 Step 4 — Scope determination`                          | Every method implementing a specific TD decision. |
| Deviation note    | `// DEVIATION: [description]. See CLAUDE.md Known Deviations.`         | Every deviation from spec.                        |
| Non-obvious logic | `// Dual-mapped drills contribute 0.5 to each subskill window`         | Complex business logic.                           |

Do not comment obvious code. Target ~1 spec/TD reference per public repository/scoring method.

---

## Known Deviations

| Spec Reference | Deviation | Rationale | Date |
|----------------|-----------|-----------|------|
| TD-06 §4.4 "28 Drift tables" | 34 Drift tables (26 from DDL + SyncMetadata + 7 matrix tables). SystemMaintenanceLock and MigrationLog excluded. | TD-02 §8 specifies these are server-only. Matrix tables added in Matrix M1-M3. | 2026-02-27 |
| TD-02 §3.5 `Sets` table | Generated data class renamed to `PracticeSet` via `@DataClassName('PracticeSet')`. | Drift generates singular `Set` from `Sets`, clashing with `dart:core.Set`. | 2026-02-27 |
| Phase 7C StorageMonitor | `StorageMonitor._defaultCheck()` returns `false` (stub). No real disk space detection. | `dart:io` doesn't expose free space without FFI/native plugin. Infrastructure wired for Phase 8 activation. | 2026-03-02 |
| S10 §10.10 Notifications | Reminder toggle + time picker persist preferences but do not schedule system notifications. | `flutter_local_notifications` deferred to post-V1 to avoid native dependency complexity. | 2026-03-02 |
| S10 §10.5 Account Deletion | Local cascade deletion only. Server-side Supabase data not deleted. | Server-side cascade requires Supabase Edge Function (deferred to post-V1). | 2026-03-02 |
| S10 §10.11 Data Export | Data export (JSON) stubbed — settings screen shows placeholder. | `share_plus` dependency deferred to post-V1. | 2026-03-02 |
| Riverpod `.autoDispose` | 16 family providers lack `.autoDispose`. Provider instances accumulate when family parameters change. | Adding `.autoDispose` risks breaking `ref.read()` call sites. Must be addressed before production release. | 2026-03-03 |
| TD-02 `MatrixAxes` table | Generated data class renamed to `MatrixAxis` via `@DataClassName('MatrixAxis')`. | Drift generates 'MatrixAxe' from 'MatrixAxes', incorrect singularization. | 2026-03-06 |
| S01 §1.11 Scoring model | Accumulation model replaces averaging. Variable per-subskill window sizes in `SubskillRef.WindowSize` replace global `kMaxWindowOccupancy = 25`. | Averaging model meant 1 drill at 3/5 = same score as 25 drills at 3/5. Accumulation rewards practice volume. | 2026-03-09 |
| C-1 scoring pipeline tests | 12 tests reference phantom drill IDs from old 28-drill placeholder stubs. | Tests need updating to use `seedTestDrill()` fixture or the real `system-putting-gate-40cm` drill. | 2026-03-13 |
| S14 Standard Drill Catalogue | Standard drills require network connectivity to browse. Offline shows empty state. | Server-authoritative model enables central updates without app releases. | 2026-03-13 |
