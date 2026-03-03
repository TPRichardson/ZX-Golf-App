# Code Efficiency Review

## Layer 1: Database Queries

**Status:** Complete — 808 tests pass, analyze clean

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

---

## Layer 2: State Management

**Status:** Complete — 808 tests pass, analyze clean

### 2.1 DateTime.now() Family Parameter Instability (HIGH — fixed)

| File | Problem | Fix |
|------|---------|-----|
| `plan_adherence_badge.dart` (line 17) | `DateTime.now()` produces microsecond-different values on every rebuild, creating a new `.family` parameter each time. Re-executes full adherence calculation on every parent rebuild. | Normalised to `DateUtils.dateOnly(DateTime.now())` so the parameter is stable within a calendar day. |

### 2.2 Hardcoded kDevUserId in Provider (HIGH — fixed)

| File | Problem | Fix |
|------|---------|-----|
| `session_detail_screen.dart` (line 230) | `_sessionDetailProvider` used `kDevUserId` instead of the widget's actual `userId`. Would break multi-user support and ignores the parameter passed to the widget. | Changed family parameter from `String sessionId` to `({String userId, String sessionId})` record. Updated both call sites. Removed unused `constants.dart` import. |

### 2.3 JSON Parsing in Build Method (HIGH — fixed)

| File | Problem | Fix |
|------|---------|-----|
| `analysis_screen.dart` (lines 108-117) | `parseWindowEntries()` called inline in `build()`, deserializing all window entry JSON on every widget rebuild. O(windows x entries) synchronous work on UI thread. | Created `sessionScoreMapProvider` in `review_providers.dart` that wraps `buildDrillLevelScoreMap()`. The provider caches the result and only recomputes when `windowStatesProvider` changes. Removed `scoring_providers.dart` import from analysis_screen. |

### 2.4 Redundant DB Call in Drill Sessions Provider (MEDIUM — fixed)

| File | Problem | Fix |
|------|---------|-----|
| `review_providers.dart` (line 204) | `drillSessionsProvider` called `getAllClosedSessionsForUser()` directly — a fresh DB query for each drillId. Same data already cached by `closedSessionsProvider`. | Changed from `FutureProvider.family` to `Provider.family<AsyncValue<...>>` that reads from `closedSessionsProvider` and filters in-memory. Eliminates redundant DB round-trip. |

### 2.5 SyncStatusBanner Over-Broad Watches (MEDIUM — fixed)

| File | Problem | Fix |
|------|---------|-----|
| `sync_status_banner.dart` (lines 20-28) | Banner watches 8 separate providers. Any change to any one of them triggers a full rebuild of the banner widget + all its children. | Created `syncBannerInputProvider` in `sync_providers.dart` that consolidates all 8 watches into a single derived record. Banner now makes 1 watch instead of 8. The consolidated provider still watches all 8 sources, but the banner only rebuilds when the derived record actually changes. Removed unused `sync_types.dart` import. |

### 2.6 Not Changed (assessed, no action needed)

| Item | Reason |
|------|--------|
| Missing `.autoDispose` on family providers | Adding `.autoDispose` would break any `ref.read()` call sites that access providers after the last watcher disposes. Requires case-by-case analysis to avoid regressions. Deferred to focused refactor. |
| `session_detail_screen.dart` window parsing in provider | Already inside a `FutureProvider`, not a build method. JSON parsing happens once per provider evaluation, not per frame. Acceptable. |

**Files changed:**
- `lib/features/review/widgets/plan_adherence_badge.dart` — date-only normalisation
- `lib/features/review/screens/session_detail_screen.dart` — userId in provider family param
- `lib/features/review/screens/analysis_screen.dart` — use sessionScoreMapProvider
- `lib/providers/review_providers.dart` — new `sessionScoreMapProvider`, refactored `drillSessionsProvider`
- `lib/providers/sync_providers.dart` — new `syncBannerInputProvider`
- `lib/features/shell/widgets/sync_status_banner.dart` — use consolidated provider
