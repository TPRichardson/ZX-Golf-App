# TD-06 Phased Build Plan — Phase 2.5 Extract (TD-06v.a6)
Sections: §6 Phase 2.5 — Server Foundation
============================================================

6. Phase 2.5 — Server Foundation

6.1 Scope

Phase 2.5 deploys the Supabase schema, validates server connectivity, and confirms that the sync round-trip works at a basic level. This is sequenced after Phase 2A and before Phase 2B so that the server infrastructure and DTO layer are validated on a proven scoring math foundation, before reflow orchestration adds complexity. Materialised tables are not populated at this point (reflow has not been built), but all source tables (PracticeBlock, Session, Set, Instance, Drill, etc.) are available for round-trip validation. Materialised tables are local-only and never synced (TD-01 §2.10), so their absence does not affect server validation.

6.1.1 Spec Sections In Play

-   Section 16 (Database Architecture) — Postgres DDL deployment, RLS policies, indexes

-   Section 17 (Real-World Application Layer) — sync transport basics

-   TD-01 (Technology Stack) — Supabase project setup, authentication

-   TD-02 (Database DDL) — 001_create_schema.sql, 002_seed_reference_data.sql deployed to Supabase

-   TD-03 §5 (Sync Transport Layer) — sync_upload and sync_download RPC functions, DTO layer

6.1.2 Deliverables

-   Supabase project created and configured

-   001_create_schema.sql executed against Supabase Postgres (28 tables, 21 enum types, 16 triggers, 41 indexes, 28 RLS policies)

-   002_seed_reference_data.sql executed (reference data and V1 System Drill Library)

-   Google Sign-In authentication flow functional (Supabase Auth)

-   sync_upload RPC function deployed and tested (TD-03 §5.2)

-   sync_download RPC function deployed and tested (TD-03 §5.3)

-   DTO serialisation layer (sync_dto.dart) for upload and download payloads (TD-03 §5.2.5)

-   Basic sync engine class with upload and download methods (full merge logic deferred to Phase 7B)

-   Schema version gating: client validates schema_version on sync (TD-01 §2.9)

6.2 Dependencies

Phase 2A (scoring math proven, type definitions available for DTO serialisation). Phase 1 (Drift schema, seed data).

6.3 Stubs

-   Merge algorithm: Phase 2.5 downloads remote changes but does not implement the full merge logic. Phase 7B completes this.

-   SyncWriteGate: class exists with acquire/release methods, but gating is not enforced until Phase 7B.

-   Sync triggers: manual only (button press). Automatic triggers deferred to Phase 7A.

-   Payload batching: single-batch upload only. 2MB batching logic deferred to Phase 7A.

6.4 Acceptance Criteria

-   Supabase schema deployed without errors (all 28 tables, 21 enum types, 16 triggers, 41 indexes, 28 RLS policies)

-   Seed data present on server (16 EventTypes, 19 Subskills, 8 MetricSchemas, 28 System Drills)

-   Google Sign-In completes and returns valid JWT

-   sync_upload accepts a payload with 1 PracticeBlock, 1 Session, 1 Set, and 3 Instances. Server confirms receipt. RLS passes.

-   sync_download returns the uploaded data for the authenticated user. No data from other users is returned.

-   RLS join performance validated: Instance query through 4-join chain (Instance → Set → Session → PracticeBlock → UserID) completes in < 50ms with 1,000 representative rows per table.

-   Schema version mismatch correctly returns SCHEMA_VERSION_MISMATCH error

-   Upload idempotency verified: same payload sent twice produces identical server state (TD-03 §5.2.3)

-   DTO round-trip verified: entity serialised to JSON, uploaded, downloaded, deserialised back to Drift entity with all fields matching

-   Synthetic bulk payload test: generate and upload a payload representing 100 Sessions with 1,000 Instances (10 Instances per Session). Validates payload serialisation performance, transport overhead, and server ingestion at a volume representative of a moderate practice history. This catches DTO performance and payload size issues before Phase 7A introduces real user-generated data at scale.

6.5 Acceptance Test Cases

Automated (required): DTO serialisation round-trip tests for all synced entity types. Upload idempotency test. Schema version validation test. RLS isolation test (two users, verify data isolation). Synthetic bulk payload test (100 Sessions / 1,000 Instances upload and download).

Manual (required): Google Sign-In flow on physical device. RLS join performance benchmark.

