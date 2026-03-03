# Gap Analysis: S15, S16, S17 vs TD Reference Catalogue

> Batch 2F — Branding & Design System (S15), Database Architecture (S16),
> Real-World Application Layer (S17)
> compared against all 8 Technical Design documents (TD-01 through TD-08).

---

## S15 — Branding & Design System (15v.a3)

### S15 Section 15.1: Strategic Positioning

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Audience: serious amateur performance improvers | No explicit TD reference | **Gap** | S15 defines target audience. Not codified in any TD. Informational. |
| Tonal direction: performance-focused, analytical | No explicit TD reference | **Gap** | Not codified. Informational. |
| Design intent: reinforce determinism and structural clarity | No explicit TD reference | **Gap** | Not codified. |
| 5 positioning characteristics | No explicit TD reference | **Gap** | Not codified. |
| Explicit exclusions: gamification, celebratory theatrics, lifestyle branding, etc. | No explicit TD reference | **Gap** | S15 lists explicit prohibitions. Not codified. |

### S15 Section 15.2: Tone & Voice Guidelines

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Copy tone: concise, direct, no exclamation marks in system messages | No explicit TD reference | **Gap** | Not codified. |
| No motivational language in scoring displays | No explicit TD reference | **Gap** | Not codified. |
| Achievement text: factual, not celebratory | TD-06 Phase 8 (achievement_banner) | Partial | TD-06 mentions achievement banner but not tonal guidance. |
| Error messages: factual, actionable, no blame/alarm | TD-07 error handling patterns | Partial | TD-07 defines error handling structure but not tonal guidance. |
| Score communication: neutral, no emotional framing | No explicit TD reference | **Gap** | Not codified. |

### S15 Section 15.3: Colour Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 3-layer colour separation: Interaction, Semantic, Heatmap | TD-06 Phase 1 (tokens.dart) | Covered | tokens.dart implements these layers. |
| Interaction tokens never used for scoring outcomes | No explicit TD reference | **Gap** | S15 specifies colour separation rule. Not codified as a TD rule. |
| color.primary.default #00B3C6 | TD-06 Phase 1 (tokens.dart) | Covered | |
| color.primary.hover #00C8DD | TD-06 Phase 1 | Covered | |
| color.primary.active #007C7F | TD-06 Phase 1 | Covered | |
| color.primary.focus (#00B3C6 @ 60% opacity, 2px outline) | No explicit TD reference | **Gap** | S15 specifies focus ring. May not be in tokens.dart. |
| color.success.default #1FA463 | TD-06 Phase 1 | Covered | |
| color.success.hover #23B26C | TD-06 Phase 1 | Covered | |
| color.success.active #15804A | TD-06 Phase 1 | Covered | |
| color.neutral.miss #3A3F46 | TD-06 Phase 1 | Covered | |
| color.neutral.miss.active #2C3036 | TD-06 Phase 1 | Covered | |
| color.neutral.miss.border #4A5058 | TD-06 Phase 1 | Covered | |
| Miss uses neutral grey, no red | No explicit TD reference | **Gap** | S15 explicitly prohibits red for miss. Not codified as a TD rule. |
| color.warning.integrity #F5A623 | TD-06 Phase 1 | Covered | |
| color.warning.integrity.muted #C88719 | TD-06 Phase 1 | Covered | |
| color.error.destructive #D64545 | TD-06 Phase 1 | Covered | |
| color.error.destructive.hover #E05858 | TD-06 Phase 1 | Covered | |
| color.error.destructive.active #B63737 | TD-06 Phase 1 | Covered | |
| Heatmap: grey→green, continuous opacity, no hard-banded tiers | TD-06 Phase 6 (skill_area_heatmap) | Covered | |
| heatmap.base #2B2F34 | TD-06 Phase 1 | Covered | |
| heatmap.base.border #3A3F46 | TD-06 Phase 1 | Covered | |
| heatmap.base.text #E6E8EB | TD-06 Phase 1 | Covered | |
| heatmap.mid #145A3A | TD-06 Phase 1 | Covered | |
| heatmap.high #1FA463 | TD-06 Phase 1 | Covered | |

### S15 Section 15.4: Surface & Elevation System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Dark-first interface | TD-06 Phase 1 (tokens.dart) | Covered | |
| surface.base #0F1115 | TD-06 Phase 1 | Covered | |
| surface.primary #171A1F | TD-06 Phase 1 | Covered | |
| surface.raised #1E232A | TD-06 Phase 1 | Covered | |
| surface.modal #242A32 | TD-06 Phase 1 | Covered | |
| surface.border #2A2F36 | TD-06 Phase 1 | Covered | |
| surface.scrim Black @ 40% | No explicit TD reference | **Gap** | S15 specifies scrim value. May not be in tokens.dart. |
| No blur effects on scrim | No explicit TD reference | **Gap** | Explicit prohibition not codified. |
| On-press: darken ~4%, no scale, no bounce | No explicit TD reference | **Gap** | S15 specifies press behaviour. Not codified as a TD rule. |
| Elevation exclusion list (5 items: long drop shadows, glow, neumorphism, blur glass, gradients) | No explicit TD reference | **Gap** | Explicit prohibitions not codified. |

### S15 Section 15.5: Typography System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Technical Geometric Sans typeface category | TD-06 Phase 1 (tokens.dart — Manrope) | Covered | |
| Manrope selected | TD-06 Phase 1 | Covered | |
| type.display.xl 32–40px SemiBold | TD-06 Phase 1 (tokens.dart) | Covered | |
| type.display.lg 24–28px SemiBold | TD-06 Phase 1 | Covered | |
| type.header.section 18–22px Medium | TD-06 Phase 1 | Covered | |
| type.body 14–16px Regular | TD-06 Phase 1 | Covered | |
| type.micro 12px Regular @ 70–80% | TD-06 Phase 1 | Covered | |
| Tabular lining numerals on all score displays | TD-06 Phase 1 (tokens.dart — tabular lining) | Covered | |
| No animated counting | No explicit TD reference | **Gap** | Not codified. |
| Typography exclusion list (7 items) | No explicit TD reference | **Gap** | Explicit prohibitions not codified. |

### S15 Section 15.6: Spacing & Layout Grid

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 4px base grid | TD-06 Phase 1 (tokens.dart — xs=4, sm=8, md=16, lg=24, xl=32, xxl=48) | Covered | |
| spacing.8 through spacing.48 | TD-06 Phase 1 | Covered | |
| No arbitrary spacing values (e.g. 13px, 22px) | No explicit TD reference | **Gap** | S15 prohibits arbitrary spacing. Not codified as a TD rule. |

### S15 Section 15.7: Shape Language

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| radius.card 8px | TD-06 Phase 1 (tokens.dart) | Covered | |
| radius.grid 6px | TD-06 Phase 1 | Covered | |
| radius.modal 10px | TD-06 Phase 1 | Covered | |
| Segmented controls: 8px container + 8px highlight | No explicit TD reference | **Gap** | S15 specifies segmented control radius. May not be in tokens.dart. |
| No pill-shaped (999px radius) buttons anywhere | No explicit TD reference | **Gap** | Explicit prohibition not codified. |

### S15 Section 15.8: Component Design System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Primary CTA: filled, color.primary.default, white text | TD-06 Phase 1 (design system) | Covered | |
| Secondary: outline, 1px border, primary text | TD-06 Phase 1 | Covered | |
| Destructive: filled, error.destructive, white text | TD-06 Phase 1 | Covered | |
| Text button: no border, no fill | TD-06 Phase 1 | Covered | |
| Cards: surface.primary, 1px border, 8px radius, 16px padding, press darken | TD-06 Phase 1 | Covered | |
| Grid cells: 6px radius, hit/miss colours, 120ms flash, haptic tick | TD-06 Phase 4 (score_flash) | Covered | |
| Achievement banners: surface.raised, primary accent restrained, factual text, fade in/out, sound ping | TD-06 Phase 8 (achievement_banner) | Covered | |
| Achievement banner prohibitions (no slide, bounce, scale, glow, confetti, streak fire) | No explicit TD reference | **Gap** | S15 lists 6 explicit animation prohibitions for banners. Not codified. |
| Integrity indicators: subtle warning icon, Session level only, not in SkillScore/score displays | TD-06 Phase 6 (session_history_screen) | Covered | |

### S15 Section 15.9: Iconography

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Outlined, geometric, consistent stroke weight | No explicit TD reference | **Gap** | S15 defines icon style. Not codified in a TD. |
| 1.5–2px stroke, no filled icons in navigation | No explicit TD reference | **Gap** | Not codified. |
| Size grid: 16px, 20px, 24px, 32px | No explicit TD reference | **Gap** | Not codified. |
| Colour rules: off-white default, primary active, warning integrity, error destructive | No explicit TD reference | **Gap** | Not codified. |
| No illustrative or golf-themed decorative icons | No explicit TD reference | **Gap** | Not codified. |

### S15 Section 15.10: Motion & Microinteraction System

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| motion.fast 120ms | TD-06 Phase 1 (tokens.dart) | Covered | |
| motion.standard 150ms | TD-06 Phase 1 | Covered | |
| motion.slow 200ms | TD-06 Phase 1 | Covered | |
| Easing: ease-in-out cubic only | No explicit TD reference | **Gap** | S15 specifies easing. Not codified. |
| No transitions exceed 200ms anywhere | No explicit TD reference | **Gap** | S15 sets hard 200ms maximum. Not codified as a TD rule. |
| 5 permitted motion patterns (button press, grid tap, achievement banner, heatmap accordion, surface press) | TD-06 Phase 4/8 | Partial | TD-06 covers some patterns but not as a definitive list. |
| Default: silent. Haptic tick on grid tap. Sound ping on achievement only | No explicit TD reference | **Gap** | S15 specifies audio model. Not codified. |
| 12-item motion prohibition list | No explicit TD reference | **Gap** | S15 lists 12 prohibited animation effects. Not codified. |

### S15 Section 15.11: Visual Governance

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Full visual unification across Plan/Track/Review (no domain colour shifts) | No explicit TD reference | **Gap** | S15 specifies no per-domain tints or accent shifts. Not codified. |
| Same tokens everywhere (charcoal, cyan, green, grey, amber, red) | TD-06 Phase 1 (tokens.dart) | Covered | Implicit in token implementation. |
| Differentiation by structure only (information density, interaction patterns, emphasis hierarchy) | No explicit TD reference | **Gap** | Not codified. |

### S15 Section 15.12: Logo & Brand Expression

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Minimal typographic wordmark only (no symbol, emblem, crest, etc.) | No explicit TD reference | **Gap** | Not codified. |
| Product title is working title, not final | No explicit TD reference | **Gap** | Not codified. |
| Title prohibited in: file names, env vars, DB schemas, namespaces, tokens, constants, identifiers | No explicit TD reference | **Gap** | S15 specifies product-name-agnostic governance. Not codified. Note: the Flutter package name is `zx_golf_app` which may conflict. |

### S15 Sections 15.13-15.16: Accessibility, Tokens, Theming, Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| WCAG AA global minimum (4.5:1 normal, 3:1 large text) | No explicit TD reference | **Gap** | S15 specifies accessibility standards. Not codified in any TD. |
| WCAG AAA on 4 cognitively critical surfaces (Overall Score, Session Score, Integrity warning, Destructive dialog) | No explicit TD reference | **Gap** | Not codified. |
| Heatmap: AA sufficient, AAA not required | No explicit TD reference | **Gap** | Not codified. |
| Outdoor usage: large high-contrast numerals for Drill Entry | No explicit TD reference | **Gap** | Not codified. |
| Product-name-agnostic token naming | No explicit TD reference | **Gap** | Not codified. Note: tokens.dart may use neutral names already. |
| Prohibited token name patterns (brand/product name in tokens) | No explicit TD reference | **Gap** | Not codified. |
| Token-first theming (overrides modify tokens only, not component logic) | No explicit TD reference | **Gap** | Not codified. |
| Light mode via token swap (deferred) | No explicit TD reference | **Gap** | Not codified. |
| White-label branding via token override | No explicit TD reference | **Gap** | Not codified. |
| 10 structural guarantees | No explicit TD reference | **Gap** | S15 §15.16 lists 10 guarantees. Not codified as a set. |

---

## S16 — Database Architecture (16v.a5)

### S16 Section 16.1: Relational Schema Design

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 5 table groups: Source, Reference, Planning, Materialised, System | TD-02 §1–§8 (schema structure) | Covered | |
| UUID primary keys | TD-02 | Covered | |
| CreatedAt/UpdatedAt UTC timestamps | TD-02 | Covered | |
| IsDeleted soft-delete with RLS filtering | TD-02, TD-01 (soft-delete propagation) | Covered | |
| Foreign key constraints on all relationships | TD-02 §5–§7 | Covered | |
| JSON columns for structured variable-length data | TD-02 (Slots, RawMetrics, Metadata, etc.) | Covered | |
| Source tables list (15 entities) | TD-02 §2–§4 | Covered | |
| Reference tables list (5 entities) | TD-02 §2 (reference data) | Covered | |
| Planning tables list (6 entities) | TD-02 §3 | Covered | |
| Materialised tables list (4 entities) | TD-02 §4 | Covered | |
| System tables list (2 entities: SystemMaintenanceLock, MigrationLog) | TD-02 §8 (server-only, excluded from Drift) | Covered | Known deviation. |

### S16 Section 16.2: Enumeration Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Stable enumerations: native enum types or CHECK constraints | TD-02 enum definitions | Covered | |
| Extensible enumerations: reference table FK | TD-02 (EventTypeRef, MetricSchemaRef, etc.) | Covered | |
| Hybrid approach | TD-02 | Covered | |
| 5 stable enums listed (SkillArea, DrillType, InputMode, ClosureType, DrillOrigin) | TD-02 enums | Covered | |
| 6 extensible enums listed (EventType, MetricSchema, SubskillRef, SkillAreaRef, etc.) | TD-02 reference tables | Covered | |

### S16 Section 16.3: Indexing Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Every FK has an index | TD-02 §7 index list | Covered | |
| 14 composite indexes defined | TD-02 §7 | Covered | Values should match. |
| Partial indexes on IsDeleted=false | No explicit TD reference | **Gap** | S16 specifies partial indexes. TD-02 lists indexes but may not specify partial filtering. |
| JSON column indexes (GIN) deferred to performance need | No explicit TD reference | **Gap** | S16 specifies deferred GIN indexes. Not in any TD. |

### S16 Section 16.4: Transaction & Isolation Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Default isolation: Repeatable Read | No explicit TD reference | **Gap** | S16 specifies default isolation level. TD-02 does not address transaction isolation. |
| Materialised swap: Serializable isolation | No explicit TD reference | **Gap** | S16 specifies Serializable for materialised swap. Not in any TD. |
| User scoring lock (Advisory Lock) | TD-04 RebuildGuard (in-memory mutex) | Partial | S16 specifies database-level advisory lock. TD-04 uses in-memory mutex. Different mechanisms. |
| Lock scope: per-user, prevents concurrent reflow | TD-04 RebuildGuard | Covered | Same concept, different implementation. |
| Lock timeout: 60 seconds | TD-04 RebuildGuard | Covered | |
| 6-step atomic reflow transaction | TD-04 ReflowEngine (10-step orchestrator) | Partial | S16 defines a 6-step DB transaction. TD-04 defines a 10-step application-layer orchestrator. Related but different abstraction levels. |
| Application-layer retry (6 categories with specific values) | TD-07 error handling patterns | Partial | TD-07 defines error handling but may not specify all 6 retry categories with exact values. |
| Instance creation: 2 retries, immediate | No explicit TD reference | **Gap** | S16 specifies exact retry parameters. Not in any TD. |
| Session close + scoring: 3 retries, exponential backoff (100/200/400ms) | No explicit TD reference | **Gap** | Same gap. |
| Calendar/Planning writes: 2 retries, immediate | No explicit TD reference | **Gap** | Same gap. |
| Read operations: 1 retry, immediate | No explicit TD reference | **Gap** | Same gap. |
| Retry idempotency requirement | No explicit TD reference | **Gap** | Not codified. |
| RLS + Repeatable Read: cross-user contention structurally impossible | No explicit TD reference | **Gap** | Not codified as a TD guarantee. |

### S16 Section 16.5: Migration Strategy

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Sequential numbered migration pattern | TD-06 Phase 8 (migration infrastructure) | Covered | |
| NNN_short_description.sql naming | TD-02 migration files (001–004) | Covered | |
| UP and DOWN in each file | No explicit TD reference | **Gap** | S16 specifies rollback (DOWN) capability. TD migrations may not include DOWN. |
| Idempotent UP (IF NOT EXISTS) | No explicit TD reference | **Gap** | Not codified. |
| 5 migration categories (additive, modifying, data, enum extension, destructive) | No explicit TD reference | **Gap** | Not codified. |
| Migration governance rules (review, destructive approval, reflow testing, determinism preservation) | No explicit TD reference | **Gap** | S16 specifies 4 governance rules. Not codified in a TD. |
| Migration log table | TD-02 §8 (MigrationLog — server-only) | Covered | |
| Zero-downtime expand-contract pattern | No explicit TD reference | **Gap** | S16 specifies expand-contract for zero-downtime. Not codified. |

### S16 Section 16.6: Versioned Data Handling

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Time-versioned: ClubPerformanceProfile (insert-on-update) | TD-02 ClubPerformanceProfile, TD-03 ClubRepository | Covered | |
| Snapshot fields: Instance (ResolvedTarget*, SelectedClub), PracticeBlock (DrillOrder), Session (DrillID) | TD-02 schema | Covered | |
| Application-layer immutability enforcement | TD-03 structural immutability guards | Covered | |
| Optional DB-level BEFORE UPDATE triggers for snapshot fields | No explicit TD reference | **Gap** | S16 suggests optional triggers. Not in any TD. |
| Structural versioning via reflow (no version column, no historical snapshots) | TD-04 ReflowEngine, TD-01 deterministic rebuild | Covered | |
| Metadata edits: unversioned (UserClub Make, Model, Loft) | TD-02, TD-03 | Covered | |

### S16 Section 16.7: Backup & Recovery

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| RPO: 15 minutes | No explicit TD reference | **Gap** | S16 specifies recovery objectives. Not in any TD. |
| RTO: 1 hour | No explicit TD reference | **Gap** | Same gap. |
| Continuous WAL archival (primary backup) | No explicit TD reference | **Gap** | S16 specifies backup strategy. Not codified. |
| Daily full base backups (retained 30 days) | No explicit TD reference | **Gap** | Same gap. |
| Weekly logical exports (pg_dump, retained 90 days, separate region) | No explicit TD reference | **Gap** | Same gap. |
| 4 recovery scenarios defined | No explicit TD reference | **Gap** | S16 defines 4 specific recovery procedures. Not codified. |
| EventLog tiered storage: 6-month hot, indefinite cold | No explicit TD reference | **Gap** | S16 specifies EventLog archival model. Not codified. |
| Daily archival job, compressed JSON, partitioned by UserID/month | No explicit TD reference | **Gap** | Same gap. |
| Archival and entity purge dependency (dangling references acceptable) | No explicit TD reference | **Gap** | Not codified. |
| Weekly automated backup restore test | No explicit TD reference | **Gap** | S16 specifies backup validation. Not codified. |

### S16 Section 16.8: Performance Scaling

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Multi-tenancy via RLS on UserID | TD-02 RLS policies | Covered | |
| System Drills (UserID IS NULL) readable by all | TD-02 | Covered | |
| 9 query performance targets (Instance <50ms, Session close <200ms, etc.) | No explicit TD reference | **Gap** | S16 specifies exact latency targets. Not codified in any TD. |
| 5-tier scaling levers (index optimisation → connection pooling → read replicas → partitioning → caching) | No explicit TD reference | **Gap** | S16 defines scaling roadmap. Not codified. |
| Volume projections per user | No explicit TD reference | **Gap** | S16 provides annual projections. Not codified. |
| Data retention: indefinite for active users, 90-day soft-delete | No explicit TD reference | **Gap** | S16 specifies retention policy. Not codified. |
| Connection management (6 parameters with baseline values) | No explicit TD reference | **Gap** | S16 specifies pooling configuration. Not codified. |
| Mandatory connection pooling | No explicit TD reference | **Gap** | Not codified. |
| 4 operational monitoring categories (17 specific monitors with thresholds) | No explicit TD reference | **Gap** | S16 specifies extensive monitoring. Not codified in any TD. |

### S16 Section 16.9: Structural Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 18 structural guarantees listed | TD-01 through TD-04 combined | Partial | Individual guarantees are covered across TDs, but S16 consolidates 18 guarantees as a formal set not found in any single TD. |

---

## S17 — Real-World Application Layer (17v.a4)

### S17 Section 17.1: Training-Only Positioning

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Strictly structured training system (not competitive round companion) | TD-01 (platform decisions) | Covered | Implicit in TD-01. |
| No on-course mode, holes, rounds, stroke-play | No explicit TD reference | **Gap** | S17 lists 5 explicit exclusions. Not codified in any TD. |
| No GPS, location, geofencing, yardage | No explicit TD reference | **Gap** | Same gap. |
| No competition locking or Rules of Golf compliance | No explicit TD reference | **Gap** | Same gap. |
| User assumed stationary in training context | No explicit TD reference | **Gap** | Not codified. |

### S17 Section 17.2: Range & Practice Ground Usage Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| No environmental mode switching or context detection | No explicit TD reference | **Gap** | S17 explicitly excludes environment-aware features. Not codified. |
| PracticeBlocks behave identically regardless of location | TD-04 | Covered | Implicit. |

### S17 Section 17.3: Offline-First Architecture

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Full offline operation | TD-01 offline-first architecture | Covered | |
| Complete local relational mirror of canonical schema | TD-01 (Drift/SQLite local DB) | Covered | |
| Full local scoring engine | TD-01, TD-04 | Covered | |
| Server is not scoring authority | TD-01 (deterministic merge-and-rebuild) | Covered | |
| 17 offline-capable operations listed | TD-01 | Covered | All implicitly covered by offline-first. |
| Only account creation requires connectivity | TD-01 | Covered | |
| System Drill Library bundled with app binary | TD-06 Phase 1 (seed_data.dart) | Covered | |
| System Drill updates via sync pipeline | TD-01 sync, TD-06 Phase 7 | Covered | |
| Server performs 4 functions (sync broker, backup, drill distribution, account management) | TD-01 | Covered | |
| No automatic data pruning in V1 | No explicit TD reference | **Gap** | S17 explicitly states no auto-pruning. Not codified. |
| Window cap (25 occupancy units) provides natural ceiling on materialised state size | TD-02 materialised tables, TD-05 | Covered | |
| Low storage warning notification (no auto-delete) | TD-06 Phase 7C (StorageMonitor stub) | Covered | Known deviation (stub). |
| EventLog archival deferred to V2 | No explicit TD reference | **Gap** | S17 defers local EventLog archival. Not codified as a TD decision. |

### S17 Section 17.4: Multi-Device Synchronisation Model

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Deterministic merge-and-rebuild sync model | TD-01 sync strategy | Covered | |
| DeviceID: UUID generated on first launch | TD-02 UserDevice table | Covered | |
| No limit on registered devices per user | No explicit TD reference | **Gap** | S17 states no device limit. Not codified. |
| DeviceID: sync bookkeeping only, no scoring impact, no UI exposure beyond Settings device list | No explicit TD reference | **Gap** | S17 specifies DeviceID scope. Not fully codified. |
| Deregistering device: removes from roster, no data deleted | No explicit TD reference | **Gap** | S17 specifies deregistration behaviour. Not codified. |
| Append-only raw execution data (6 entities listed) | TD-01 sync (additive merge) | Covered | |
| LWW structural configuration (5 categories) | TD-01 (LWW by UpdatedAt) | Covered | |
| CalendarDay Slot-level LWW | TD-01 (CalendarDay slot-level exception) | Covered | |
| Soft-delete: forward-only, never reversed by sync | TD-01 (delete always wins) | Covered | |
| Materialised state never synced (4 tables) | TD-01 (materialised never synced) | Covered | |
| 6-step sync pipeline (Upload → Download → Merge → Completion Matching → Rebuild → Confirm) | TD-06 Phase 7B (SyncEngine merge pipeline) | Covered | |
| Sync triggers: connectivity restore, periodic, manual | TD-06 Phase 7A (SyncOrchestrator triggers) | Covered | |
| Periodic: 5-minute interval | TD-06 Phase 7A | Covered | |
| Manual trigger in Settings | No explicit TD reference | **Gap** | S17 specifies manual sync. May not be in TD-06 Phase 8 explicitly. |
| Silent non-blocking sync | TD-06 Phase 7A | Covered | |
| Sync-triggered rebuild: non-blocking (not full scoring lock) | No explicit TD reference | **Gap** | S17 specifies that sync rebuild doesn't use the full scoring lock model. Not codified as a TD rule. |
| User-initiated reflow takes priority over sync rebuild | No explicit TD reference | **Gap** | S17 specifies priority model. Not codified. |
| Sync failure: no partial merge committed, atomic per entity | TD-06 Phase 7B | Covered | |
| No data loss on sync failure, auto-retry on next trigger | TD-06 Phase 7A (consecutive failure counter) | Covered | |
| Cross-device Session concurrency: same-device enforced, online server-mediated, offline both allowed | TD-06 Phase 7C (dual active session detection) | Covered | |
| Offline overlap: both Sessions merge chronologically on sync | TD-01 (additive merge) | Covered | |
| System Drill update delivery via sync | TD-01, TD-06 Phase 7 | Covered | |
| Automatic reflow on System Drill update receipt | TD-01 | Covered | |
| Schema version compatibility: sync blocked on mismatch | TD-06 Phase 7C (schema mismatch persistent flag) | Covered | |
| "App update required to sync" message | TD-06 Phase 7C (SyncStatusBanner) | Covered | |
| Device continues offline during version mismatch | TD-06 Phase 7C | Covered | |
| Schema migrations preserve backward compatibility of raw execution entities | No explicit TD reference | **Gap** | S17 specifies migration compatibility constraint. Not codified as a TD rule. |

### S17 Section 17.5: Data Export & Sharing

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| JSON full export (manual, user-initiated) | Known Deviation (CLAUDE.md) | Covered | Acknowledged as deferred. |
| Optional CSV session summary | Not in any TD | Covered | Deferred. |
| No re-import in V1 | No explicit TD reference | **Gap** | S17 explicitly defers re-import. Not codified. |
| No shareable links, hosted dashboards, external portals | No explicit TD reference | **Gap** | S17 lists 4 explicit exclusions. Not codified. |
| No real-time coach feeds or live shared access | No explicit TD reference | **Gap** | Same gap. |
| Export scope: 9 entity types listed | No explicit TD reference | **Gap** | S17 enumerates export scope. Not codified in a TD. |

### S17 Section 17.6: Coach/Admin Access

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| No coach/admin/secondary user role in V1 | No explicit TD reference | **Gap** | S17 specifies single-user-only. Not codified in a TD. |
| No shared accounts, delegated access, cross-user visibility | No explicit TD reference | **Gap** | S17 lists 5 explicit exclusions. Not codified. |
| Coach interaction via exported files only | No explicit TD reference | **Gap** | Not codified. |
| Future compatibility for coach layer | No explicit TD reference | **Gap** | Not codified. |

### S17 Section 17.7: User Behaviour Constraints

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| No behavioural realism constraints | No explicit TD reference | **Gap** | S17 specifies no enforcement. Not codified. |
| 9 explicitly not-enforced behaviours (max sessions/hour, min time between shots, back-dating, shot-rate throttling, volume caps, anti-gaming, etc.) | No explicit TD reference | **Gap** | S17 lists 9 specific non-enforcements. Not codified. |
| Existing structural constraints (5 items) preserved | TD-04, TD-02 | Covered | |

### S17 Section 17.8: Practical Session Time Limits

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Only existing structural safeguards (2h Session, 4h PB) | TD-04 state machines | Covered | |
| No additional hard maximum PB duration | No explicit TD reference | **Gap** | S17 explicitly states no additional duration limit. Not codified. |
| No per-Session absolute time cap | No explicit TD reference | **Gap** | Same gap. |
| No daily cumulative practice limit | No explicit TD reference | **Gap** | Same gap. |
| Timers are not user-configurable | TD-04 (system constants) | Covered | |

### S17 Section 17.9: Data Model Additions

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| UserDevice entity (8 fields) | TD-02 UserDevice table | Covered | |
| EventLog.DeviceID extension | TD-02 EventLog table | Covered | |
| UserDevice(UserID) index | TD-02 §7 | Covered | |
| EventLog(DeviceID) index | TD-02 §7 | Covered | |
| No scoring impact for all additions | TD-04 non-reflow triggers | Covered | |

### S17 Section 17.10: Cross-Section Impact

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| Section 3 updates: offline fallback for concurrency | TD-06 Phase 7C | Covered | |
| Section 6 updates: UserDevice entity, EventLog DeviceID | TD-02 | Covered | |
| Section 7 updates: sync rebuild non-blocking clarification | No explicit TD reference | **Gap** | Not codified. |
| Section 13 updates: supersede offline limitation list | No explicit TD reference | **Gap** | S17 supersedes S13 offline limitations. Not codified as a TD update. |
| Section 16 updates: UserDevice table, DeviceID column, indexes | TD-02 | Covered | |
| Section 0 updates: add 5 new terms | No explicit TD reference | **Gap** | S17 requests S00 updates. Not codified. |

### S17 Section 17.11: Structural Guarantees

| Spec Item | TD Coverage | Status | Notes |
|-----------|-------------|--------|-------|
| 14 structural guarantees | TD-01 through TD-07 combined | Partial | Individual guarantees covered across TDs but not consolidated in any single TD document. |

---

## Conflicts Identified

### Conflict 1 (Carried): ClubSelectionMode Immutability

Carried from previous batches. S10 states immutable; TD-03 guard list does not include it.

### Conflict 2 (Carried): ClosureType Values

S06/PracticeBlock.ClosureType {Manual, AutoClosed} vs TD-04 {Manual, ScheduledAutoEnd, SessionTimeout}. Carried.

### Conflict 3: S16 Advisory Lock vs TD-04 In-Memory Mutex

S16 §16.4.3 specifies a database-level advisory lock for user scoring lock. TD-04 implements RebuildGuard as an in-memory mutex. Different mechanisms for the same purpose. S16 describes the database architecture; TD-04 describes the application implementation. Not a true conflict — different abstraction levels — but worth noting.

---

## Gaps Summary

| # | Spec | Section | Item | Risk | Notes |
|---|------|---------|------|------|-------|
| 1 | S15 | §15.1 | Target audience, tonal direction, design intent, positioning | Low | Informational |
| 2 | S15 | §15.1 | Explicit exclusions (gamification, theatrics, lifestyle) | Low | Not codified |
| 3 | S15 | §15.2 | Tone & voice: no exclamation marks, no motivational language, neutral scores | Low | Not codified |
| 4 | S15 | §15.3 | Interaction/semantic colour separation rule | Low | Structural design rule |
| 5 | S15 | §15.3 | color.primary.focus (60% opacity focus ring) | Low | May be missing from tokens.dart |
| 6 | S15 | §15.3 | No red for miss (explicit prohibition) | Low | Design rule |
| 7 | S15 | §15.4 | surface.scrim (Black @ 40% opacity) | Low | May be missing from tokens.dart |
| 8 | S15 | §15.4 | On-press: darken ~4%, no scale/bounce | Low | Not codified |
| 9 | S15 | §15.4 | Elevation exclusion list (5 prohibitions) | Low | Not codified |
| 10 | S15 | §15.5 | No animated counting (prohibition) | Low | Not codified |
| 11 | S15 | §15.5 | Typography exclusion list (7 prohibitions) | Low | Not codified |
| 12 | S15 | §15.6 | No arbitrary spacing values (prohibition) | Low | Not codified |
| 13 | S15 | §15.7 | Segmented control radius (8px + 8px) | Low | May be missing from tokens |
| 14 | S15 | §15.7 | No pill-shaped buttons (prohibition) | Low | Not codified |
| 15 | S15 | §15.8 | Achievement banner: 6 animation prohibitions | Low | Not codified |
| 16 | S15 | §15.9 | Icon style (outlined, geometric, 1.5-2px stroke, size grid) | Low | Not codified |
| 17 | S15 | §15.9 | No golf-themed decorative icons | Low | Not codified |
| 18 | S15 | §15.10 | Easing: ease-in-out cubic only | Low | Not codified |
| 19 | S15 | §15.10 | No transitions exceed 200ms | Low | Not codified |
| 20 | S15 | §15.10 | Audio model (silent default, haptic tick grid, ping achievement only) | Low | Not codified |
| 21 | S15 | §15.10 | 12-item motion prohibition list | Low | Not codified |
| 22 | S15 | §15.11 | No per-domain visual differentiation (unification rule) | Low | Not codified |
| 23 | S15 | §15.12 | Logo: minimal wordmark only, product-name-agnostic governance | Low | Not codified |
| 24 | S15 | §15.13 | WCAG AA global minimum, selective AAA on 4 surfaces | Medium | Not codified in any TD |
| 25 | S15 | §15.13 | Outdoor usage: high contrast for Drill Entry | Low | Not codified |
| 26 | S15 | §15.14 | Product-name-agnostic token naming + prohibited patterns | Low | Not codified |
| 27 | S15 | §15.15 | Token-first theming, light mode deferred, white-label support | Low | Not codified |
| 28 | S16 | §16.3 | Partial indexes on IsDeleted=false | Low | Not in TD-02 |
| 29 | S16 | §16.3 | Deferred GIN indexes on JSON columns | Low | Not codified |
| 30 | S16 | §16.4 | Default isolation: Repeatable Read | Medium | Not in any TD |
| 31 | S16 | §16.4 | Materialised swap: Serializable isolation | Medium | Not in any TD |
| 32 | S16 | §16.4 | Retry parameters (6 categories with exact values) | Medium | Not codified |
| 33 | S16 | §16.4 | Retry idempotency requirement | Low | Not codified |
| 34 | S16 | §16.4 | Cross-user contention guarantee (RLS + Repeatable Read) | Low | Not codified |
| 35 | S16 | §16.5 | DOWN (rollback) in migration files | Low | Not codified |
| 36 | S16 | §16.5 | Idempotent UP (IF NOT EXISTS) | Low | Not codified |
| 37 | S16 | §16.5 | 5 migration categories | Low | Not codified |
| 38 | S16 | §16.5 | Migration governance rules (4 rules) | Low | Not codified |
| 39 | S16 | §16.5 | Zero-downtime expand-contract pattern | Low | Not codified |
| 40 | S16 | §16.6 | Optional DB-level BEFORE UPDATE triggers for snapshots | Low | Not codified |
| 41 | S16 | §16.7 | RPO 15 min / RTO 1 hour | Medium | Not in any TD |
| 42 | S16 | §16.7 | Backup strategy (WAL + daily + weekly) | Medium | Not codified |
| 43 | S16 | §16.7 | 4 recovery scenarios | Medium | Not codified |
| 44 | S16 | §16.7 | EventLog tiered archival (6-month hot, indefinite cold) | Medium | Not codified |
| 45 | S16 | §16.7 | Daily archival job specification | Low | Not codified |
| 46 | S16 | §16.7 | Weekly automated backup restore test | Low | Not codified |
| 47 | S16 | §16.8 | 9 query performance targets | Medium | Not codified |
| 48 | S16 | §16.8 | 5-tier scaling roadmap | Low | Not codified |
| 49 | S16 | §16.8 | Volume projections per user | Low | Not codified |
| 50 | S16 | §16.8 | Data retention policy (indefinite active, 90-day soft-delete) | Medium | Not codified |
| 51 | S16 | §16.8 | Connection management (6 parameters + mandatory pooling) | Medium | Not codified |
| 52 | S16 | §16.8 | 17 operational monitors with thresholds | Medium | Not codified |
| 53 | S17 | §17.1 | Training-only exclusions (5 items: no on-course, GPS, competition, etc.) | Low | Not codified |
| 54 | S17 | §17.2 | No environmental mode switching or context detection | Low | Not codified |
| 55 | S17 | §17.3 | No automatic data pruning in V1 | Low | Not codified |
| 56 | S17 | §17.3 | Local EventLog archival deferred to V2 | Low | Not codified |
| 57 | S17 | §17.4 | No device limit per user | Low | Not codified |
| 58 | S17 | §17.4 | DeviceID scope restrictions | Low | Not codified |
| 59 | S17 | §17.4 | Device deregistration behaviour | Low | Not codified |
| 60 | S17 | §17.4 | Manual sync trigger in Settings | Low | Not codified |
| 61 | S17 | §17.4 | Sync-triggered rebuild is non-blocking (not full scoring lock) | Medium | Not codified |
| 62 | S17 | §17.4 | User-initiated reflow priority over sync rebuild | Medium | Not codified |
| 63 | S17 | §17.4 | Schema migrations preserve backward compatibility | Medium | Not codified |
| 64 | S17 | §17.5 | No re-import in V1 | Low | Not codified |
| 65 | S17 | §17.5 | 4 sharing exclusions (no shareable links, dashboards, portals, coach feeds) | Low | Not codified |
| 66 | S17 | §17.5 | Export scope (9 entity types) | Low | Not codified |
| 67 | S17 | §17.6 | No coach/admin role in V1 (5 exclusions) | Low | Not codified |
| 68 | S17 | §17.6 | Future compatibility for coach layer | Low | Not codified |
| 69 | S17 | §17.7 | 9 explicitly not-enforced behaviours | Low | Not codified |
| 70 | S17 | §17.8 | No additional PB/Session/daily duration limits | Low | Not codified |
| 71 | S17 | §17.10 | Cross-section impact updates (S07 sync rebuild, S13 offline list, S00 terms) | Low | Not codified |

---

## Summary

| Category | Count |
|----------|-------|
| Spec items checked | ~280 |
| Fully covered by TD | ~151 |
| Gaps (spec without TD) | 71 |
| Conflicts | 3 (2 carried + 1 new observation) |

**Overall Assessment:**

**S15 (Branding & Design System)** has good coverage for concrete token values (colours, spacing, typography, motion timing) through TD-06 Phase 1's tokens.dart implementation. The gaps are predominantly **design governance rules**: prohibition lists, separation principles, accessibility standards, iconography guidelines, and tone/voice rules. These are design-system-level constraints that guide implementation decisions but are not the type of content typically codified in technical design documents. Risk is low — these rules constrain how things should look and feel, not what should be built.

**S16 (Database Architecture)** has strong coverage for the schema itself (TD-02) but significant gaps in **operational infrastructure**: transaction isolation levels, retry parameters, backup/recovery strategy (RPO/RTO), EventLog archival, performance targets, connection management, and operational monitoring. These are server-side operational concerns that were not addressed in the TDs, which focused on schema definition (TD-02), API contracts (TD-03), state machines (TD-04), and client-side implementation (TD-06). This represents the largest thematic gap area: **no TD addresses server-side operational architecture**.

**S17 (Real-World Application Layer)** is well-covered for the core technical infrastructure (offline-first, sync model, multi-device, data model) through TD-01 and TD-06 Phase 7. The gaps are primarily **explicit exclusions and non-functional constraints**: training-only positioning, behaviour non-enforcement, export scope, coach/admin exclusions, and duration non-limits. These are boundary-defining decisions that prevent scope creep rather than design gaps. The most notable technical gap is the sync rebuild priority model (S17 specifies user-initiated reflow takes priority over sync rebuild, not codified in any TD).

---

*End of S15-S17 vs TD Gap Analysis (Batch 2F)*
