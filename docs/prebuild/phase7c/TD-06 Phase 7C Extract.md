# TD-06 Phased Build Plan — Phase 7C Extract (TD-06v.a6)
Sections: §14 Phase 7C — Conflict UI & Offline Hardening
============================================================

14. Phase 7C — Conflict UI & Offline Hardening

14.1 Scope

Phase 7C completes the sync layer with user-facing elements: offline indicator, sync progress UI, schema version gating UI, token lifecycle management, and storage monitoring integration. This phase does not introduce new merge logic — it surfaces the existing merge behaviour to the user and hardens edge cases.

14.1.1 Spec Sections In Play

-   Section 17 (Real-World Application Layer) — offline indicator, storage warning, schema gating UI

-   TD-01 §2.9 (Schema Version Gating) — user message on mismatch

-   TD-01 §3.3 (Token Lifecycle) — refresh, re-authentication prompt

14.1.2 Deliverables

-   Offline indicator: clear UI signal when operating without connectivity

-   Sync progress UI: visual indicator during extended downloads

-   Schema version gating UI: "App update required to sync" message (TD-01 §2.9). App continues offline.

-   Token lifecycle management (TD-01 §3.3): automatic refresh on reconnection, re-authentication prompt on expired refresh token, no data loss during re-auth

-   Cross-device active Session warning (TD-01 §2.7): online conflict detection, confirmation dialog, hard-discard of previous Session on confirmation

-   Storage monitoring integration (Section 17 §17.3.5): low-storage warning when device storage is critically low. No auto-deletion.

-   Sync status: last sync timestamp visible in settings or status bar

-   Sync-disabled indicator: when the sync feature flag (§17.1) is off, a persistent UI message in Settings and/or the status area states "Sync disabled — data not shared across devices." This prevents users on multiple devices from assuming data consistency when sync is inactive.

14.2 Dependencies

Phase 7B (merge logic must be complete and stable). Phase 7A (transport and feature flag).

14.3 Stubs

None. Phase 7C completes the sync layer.

14.4 Acceptance Criteria

-   Offline indicator appears when connectivity is lost, disappears on reconnection

-   Sync progress shown during extended downloads

-   Schema version mismatch: clear message displayed, sync blocked, app continues offline

-   Token refresh: seamless on reconnection. Expired refresh token: re-auth prompt, no data loss.

-   Cross-device active Session: warning displayed, confirmation required, previous Session discarded on confirmation

-   Low-storage warning displayed when appropriate. No data auto-deleted.

-   All sync-related UI uses design system tokens

-   Sync feature flag off: "Sync disabled" message clearly visible in Settings and/or status area

14.5 Acceptance Test Cases

Manual (required): Airplane mode toggle: offline indicator and sync-on-reconnect. Schema version mismatch simulation. Token expiry simulation (extended offline period). Cross-device active Session conflict on two devices. Low-storage simulation.

