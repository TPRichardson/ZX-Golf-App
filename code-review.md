# Code Efficiency Review

## Layer 1: Database Queries

**Status:** In progress — analyze clean, tests pending

### 1.1 Missing Indexes (5 added)

| Table | Column(s) | Index Name | Priority | Rationale |
|-------|-----------|------------|----------|-----------|
| Session | PracticeBlockID | `idx_session_practice_block_id` | HIGH | FK lookup on every session query by block |
| Session | DrillID | `idx_session_drill_id` | HIGH | FK lookup when enriching sessions with drill data |
| Instance | SetID | `idx_instance_set_id` | HIGH | FK lookup on every instance query by set |
| PracticeBlock | UserID, EndTimestamp | `idx_practice_block_user_end` | MEDIUM | Active PB query filters on both columns |
| Drill | UserID | `idx_drill_user_id` | MEDIUM | Custom drill queries filter by user |

**Note:** `Sets(SessionID)` and `PracticeEntries(PracticeBlockID)` already have implicit indexes from their UNIQUE constraints on `{sessionId, setIndex}` and `{practiceBlockId, positionIndex}` respectively (SQLite uses the leftmost column).

**Files changed:**
- `lib/data/database.dart` — schema version 1 -> 2, added `_createIndexes()` helper called from both `onCreate` and `onUpgrade`, added `_migrateV1ToV2` migration step

### 1.2 N+1 Query Fixes (3 fixed)

| Location | Problem | Fix |
|----------|---------|-----|
| `watchPracticeBlock()` (line ~648) | Per-entry drill + session fetch in a loop (2N queries) | Batch fetch all drills via `isIn()`, batch fetch all sessions via `isIn()` (2 queries total) |
| `_countNonDeletedInstancesInSession()` (line ~1492) | Fetched all sets, then looped per-set to fetch instances and count `.length` | Single `JOIN + COUNT(*)` via `customSelect` |
| `_reevaluateIntegrityFlag()` (line ~1593) | Fetched all sets, then looped per-set to fetch instances | Fetch set IDs once, then batch fetch all instances via `isIn()` |

### 1.3 Duplicate Query Elimination (1 fixed)

| Location | Problem | Fix |
|----------|---------|-----|
| `deleteInstance()` (lines ~1315 + ~1341) | Same drill fetched twice — once for Fix 5 structured guard, once for Fix 6 auto-discard | Hoisted drill fetch before both checks, reuse single result |

### 1.4 Count-by-Fetch Replaced with COUNT(*) (2 fixed)

| Method | Before | After |
|--------|--------|-------|
| `getInstanceCount(setId)` | `SELECT * ... .get()` then `.length` | `SELECT COUNT(*) ... WHERE SetID = ? AND IsDeleted = 0` |
| `getSetCount(sessionId)` | `SELECT * ... .get()` then `.length` | `SELECT COUNT(*) ... WHERE SessionID = ? AND IsDeleted = 0` |

### 1.5 Not Changed (assessed, no action needed)

| Item | Reason |
|------|--------|
| `Sets(SessionID)` index | Already covered by UNIQUE constraint on `{sessionId, setIndex}` |
| `PracticeEntries(PracticeBlockID)` index | Already covered by UNIQUE constraint on `{practiceBlockId, positionIndex}` |
| `watchAllPracticeBlocks` / `watchAllSessions` broad watches | Used only in sync/merge pipeline where full table watch is correct |

**Files changed:**
- `lib/data/repositories/practice_repository.dart` — 6 query optimisations across `watchPracticeBlock`, `_countNonDeletedInstancesInSession`, `_reevaluateIntegrityFlag`, `deleteInstance`, `getInstanceCount`, `getSetCount`
