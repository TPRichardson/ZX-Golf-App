# TD-06 Phased Build Plan — Phase 8 Extract (TD-06v.a6)
Sections: §15 Phase 8 — Polish & Hardening, §18 Data Migration Strategy, §19 Deferred Items
============================================================

15. Phase 8 — Polish & Hardening

15.1 Scope

Phase 8 is the final phase. It covers Settings screens, integrity safeguards UI (suppression toggle), accessibility audit, motion refinement, data migration playbook, and any remaining Section 15 polish. This phase does not introduce new core features — it refines everything built in Phases 1–7C.

15.1.1 Spec Sections In Play

-   Section 10 (Settings & Configuration) — all settings screens

-   Section 11 (Metrics Integrity & Safeguards) — integrity UI: suppression toggle

-   Section 15 (Branding & Design System) — final polish: motion, haptics, accessibility

-   Section 17 (Real-World Application Layer) — environmental edge cases

15.1.2 Deliverables

-   Settings screens (Section 10): all user-configurable settings

-   IntegritySuppressed toggle UI (Section 11 §11.6): per-Session, observational language only

-   Motion refinement: verify all transitions ≤ 200ms, ease-in-out cubic, haptic tick on grid tap

-   Achievement banners (§15.8.4): fade in 150ms, fade out 200ms, factual text, no celebratory effects

-   Accessibility audit: WCAG AA global, AAA on designated critical surfaces, outdoor readability for drill entry screens

-   Error messaging review: all messages factual and actionable (§15.2)

-   Edge case hardening: app crash mid-reflow recovery, empty database cold start, schema migration on update

-   Font finalisation: confirm Technical Geometric Sans choice, tabular numeral verification

-   Product-name agnosticism verification: no brand/title identifiers in tokens, classes, or database identifiers (§15.12, §15.14)

-   Data migration playbook:

    -   Schema evolution strategy: how Drift migrations are written, tested, and deployed

    -   Backwards compatibility test: raw execution data logged under current schema remains valid after migration

    -   Migration timing budget: migrations must complete within 1-second budget or display progress indicator (TD-01 §4.3)

    -   Rollback path: if migration fails, app remains on previous schema version with clear user messaging

    -   Test matrix: migration tested from V1 schema to V1.1 schema with representative data volumes (1K, 10K, 100K Instances)

15.2 Dependencies

All prior phases (1–7C). Phase 8 touches every surface.

15.3 Stubs

None. Phase 8 is the final phase. All stubs from prior phases are resolved or listed in Section 19 (Deferred Items).

15.4 Acceptance Criteria

-   All Settings screens functional per Section 10

-   IntegritySuppressed toggle works per-Session with observational language

-   All transitions verified ≤ 200ms, no prohibited motion patterns (§15.10.4)

-   WCAG AA met on all surfaces, AAA on designated critical surfaces (§15.13)

-   App survives crash mid-reflow: restart triggers full rebuild, scores correct

-   Empty database cold start: dashboard shows zero state in < 1 second

-   No product name or brand identifiers in codebase tokens or database identifiers

-   All error messages factual and actionable

-   Data migration playbook documented and tested at representative volumes

-   Full end-to-end journey: sign in → configure bag → browse drills → plan practice → execute practice → review scores → sync across devices

15.5 Acceptance Test Cases

Manual (required): Full end-to-end journey on Pixel 5a. Settings walkthrough. Integrity suppression toggle. Crash recovery test (force-kill during reflow). Accessibility audit with TalkBack. Motion timing verification. Product-name audit. Migration test at 1K, 10K, 100K Instances.

16. Testing Strategy Summary

Automated tests cover invisible logic layers. Manual verification covers visible UI.

  --------------------------------------- ------------------------------ ----------- ----------------------------------------------------
  Layer                                   Test Type                      Phase       Coverage

  Instance/Session/Window scoring         Automated unit                 2A          100% of TD-05 §4–9

  DTO serialisation round-trip            Automated unit                 2.5         All synced entity types + 100-Session bulk payload

18. Data Migration Strategy

Schema evolution is inevitable. The deterministic rebuild architecture provides a strong foundation: materialised tables can always be rebuilt from raw data. However, migration errors on raw execution data are unrecoverable. This section defines the migration governance.

18.1 Principles

-   Raw execution data is sacred. Migrations must never delete, truncate, or reinterpret Instance, Set, Session, or PracticeBlock rows. Column additions are safe. Column type changes require explicit data transformation with rollback path.

-   Materialised tables are disposable. Any migration that affects scoring structure can safely truncate all four materialised tables. A full rebuild will repopulate them correctly.

-   Seed data is additive. New SubskillRef, MetricSchema, or EventTypeRef rows can be added. Existing rows must not be modified without a migration that also updates all referencing entities.

-   Schema version gating (TD-01 §2.9) prevents sync between mismatched versions. The app continues offline until updated.

18.2 Migration Timing Budget

Drift runs schema migrations on app launch, before the UI is populated. Migrations must complete within the 1-second cold-start budget (TD-01 §4.3). If a migration is expected to exceed this budget (e.g. backfilling a new column across 100K+ rows), the app must display a one-time migration progress indicator.

18.3 Test Matrix

Every schema migration must be tested against three volume tiers before release:

-   Tier 1: 1,000 Instances (typical new user after 1–2 months)

-   Tier 2: 10,000 Instances (active user after 6–12 months)

-   Tier 3: 100,000 Instances (heavy user at realistic ceiling)

Each tier test verifies: migration completes without error, raw data is preserved, materialised tables rebuild correctly, and timing is within budget.

19. Deferred Items

The following items are explicitly out of scope for all V1 phases. They are documented here to prevent scope creep and to provide a clear V2 backlog.

-   Real-time Supabase subscriptions (TD-01 §2.11)

-   Field-level merge beyond CalendarDay (TD-01 §2.11)

-   EventLog archival to cold storage (Section 16 §16.7.4)

-   Batch Instance logging / launch monitor paste (TD-03 §10)

-   Push notification triggers via Edge Functions (TD-03 §10)

-   Server-side SlotUpdatedAt normalisation (TD-03 §5.4.4, V2)

-   Soft-delete partial indexes (TD-02 §10)

-   GIN indexes on JSON columns (TD-02 §10)

-   Snapshot immutability triggers (TD-02 §10)

-   Advisory locks for performance optimisation (TD-02 §10)

-   Multi-user / Coach access (Section 17 §17.6)

-   Undo support for state transitions (TD-04 §5)

-   Drill version history (TD-04 §5)

-   iOS deployment (TD-01 §1.2 — Flutter supports iOS; platform-specific setup deferred)

-   Remote log aggregation (V1 uses platform console only)

