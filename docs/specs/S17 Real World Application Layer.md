Section 17 — Real-World Application Layer

Version 17v.a4 — Canonical

This document defines the canonical Real-World Application Layer for ZX Golf App. It is fully harmonised with Section 1 (Scoring Engine 1v.g2), Section 2 (Skill Architecture 2v.f1), Section 3 (User Journey Architecture 3v.g7), Section 4 (Drill Entry System 4v.g8), Section 5 (Review 5v.d6), Section 6 (Data Model & Persistence Layer 6v.b7), Section 7 (Reflow Governance System 7v.b9), Section 8 (Practice Planning Layer 8v.a8), Section 9 (Golf Bag & Club Configuration 9v.a2), Section 10 (Settings & Configuration 10v.a5), Section 11 (Metrics Integrity & Safeguards 11v.a5), Section 12 (UI/UX Structural Architecture 12v.a5), Section 13 (Live Practice Workflow 13v.a6), Section 14 (Drill Entry Screens & System Drill Library 14v.a4), Section 15 (Branding & Design System 15v.a3), Section 16 (Database Architecture 16v.a5), and the Canonical Definitions (0v.f1). This layer governs environmental behaviour: physical usage context, offline operation, multi-device synchronisation, export constraints, and practical runtime limits. It introduces no new scoring logic and does not modify the deterministic guarantees defined in Sections 1–7.

17.1 Training-Only Positioning

ZX Golf App is strictly a structured training system. It is not a competitive round companion, does not provide rules-aware assistance, and does not support tournament play.

Architectural Consequences

-   No on-course mode exists. The application has no concept of holes, rounds, stroke-play scoring, or course context.

-   No GPS, location tracking, geofencing, or yardage assistance is provided.

-   No competition locking, anti-assistance mechanisms, or Rules of Golf compliance logic is required.

-   No hybrid workflows exist for logging practice shots during a competitive round.

-   All functionality is designed for controlled training environments: driving ranges, short-game areas, putting greens, indoor simulators, and practice facilities.

The system assumes the user is stationary and in a training context. There is no support for mobile shot-by-shot walking workflows. If a user chooses to use the app on a course during non-competitive play, the full Live Practice workflow is available, but no course-specific features or adaptations are provided.

17.2 Range & Practice Ground Usage Model

The full Live Practice workflow (Section 13) is available in all training environments. There is no environmental mode switching, no location-aware adaptation, and no context detection.

Execution Characteristics

-   PracticeBlocks behave identically regardless of physical location.

-   All drill types (Technique Block, Transition, Pressure) execute normally.

-   Window insertion and scoring operate without environmental awareness.

-   Calendar completion matching (Section 8, §8.3.2) functions identically.

-   Club Selection Mode operates per the Drill definition without location-based modification.

-   The Drill Entry Screen (Section 14) is optimised for practice-ground conditions: large tap targets, 80% screen takeover, portrait-only, minimum-click submission.

17.3 Offline-First Architecture

ZX Golf App operates fully offline. Every device that runs the application contains a complete local relational mirror of the canonical database schema (Section 16) and a full local scoring engine. The server is not the scoring authority.

17.3.1 Offline Capabilities

The following operations are fully supported without network connectivity:

-   Create, edit, retire, and delete Drills (User Custom only).

-   Adopt and unadopt System Drills.

-   Create, edit, retire, and delete Routines and Schedules.

-   Apply Routines and Schedules to the Calendar.

-   Edit CalendarDay SlotCapacity and Slot assignments.

-   Start and end PracticeBlocks.

-   Start, execute, and close Sessions.

-   Log Sets and Instances.

-   Execute scoring (0–5 Instance scores, Session scores, window insertion, roll-off).

-   Execute reflow (full deterministic recalculation from raw Instance data).

-   View SkillScore, Analysis, Heatmap, Weakness Ranking, and Plan Adherence.

-   Modify anchors on User Custom Drills (triggers local reflow).

-   Edit club configuration, carry distances, Skill Area mappings.

-   Edit Settings (units, analytics preferences, calendar defaults).

-   Calendar completion matching for locally closed Sessions.

17.3.2 Connectivity Requirements

The following operations require network connectivity:

6.  Account creation (one-time). A server-side UserID is required to anchor all future synchronisation.

7.  Multi-device synchronisation (Section 17.4).

8.  Receiving System Drill updates published centrally.

9.  Data export to external formats (if server-side generation is used).

Account creation is the only operation that blocks first-use without connectivity. After account creation, the user may operate entirely offline for any duration.

17.3.3 System Drill Library Distribution

The V1 System Drill Library (28 drills, Section 14) is bundled with the application binary at install time. Users have immediate access to all System Drills without requiring network connectivity after initial account creation. System Drill updates published centrally are delivered to devices via the synchronisation pipeline (Section 17.4) and trigger automatic local reflow on receipt.

17.3.4 Server Role Definition

The server performs four functions:

10. Synchronisation broker — receives and distributes raw data and structural edits across devices.

11. Backup layer — maintains a canonical copy of all raw data for disaster recovery.

12. System Drill distribution — publishes central updates to System Drill definitions.

13. Account management — UserID creation and device registration.

The server is not the scoring authority. It does not execute reflow, does not maintain materialised scoring state, and does not resolve scoring calculations. All scoring is performed locally on-device. Deterministic architecture guarantees that all devices converge to identical scoring state from identical raw data.

17.3.5 Local Storage Model

Each device maintains a full relational mirror of the Section 16 schema, including all Source Tables, Planning Tables, Materialised Tables, and System Tables. No automatic data pruning occurs in V1. All raw data is retained locally indefinitely.

The window cap of 25 occupancy units per subskill (Section 1, §1.6) puts a natural ceiling on materialised state size. Instance data is lightweight. EventLog is append-only and retained in full.

If local device storage becomes critically low, the application displays a warning notification advising the user to free device storage. The application does not auto-delete any user data. Optional local archival (e.g. purging synced EventLog entries older than a defined threshold from the local store while retaining them server-side) is explicitly deferred to V2. Reflow operates only on window-relevant data (current occupancy entries per subskill); historical raw data beyond the active windows does not impact reflow complexity or execution time.

17.4 Multi-Device Synchronisation Model

ZX Golf App uses a deterministic merge-and-rebuild synchronisation model. Because the scoring engine is fully deterministic and all scoring state is derivable from raw Instance data plus structural parameters, no device and no server holds authoritative scoring state. All devices converge to identical results after sync.

17.4.1 Device Identity Model

Each device generates a unique DeviceID (UUID) on first application launch. The DeviceID is registered against the user’s account on first successful server connection.

10. No limit on the number of registered devices per user in V1.

11. DeviceID is used for sync bookkeeping only: tracking last sync timestamp per device, identifying data origin for audit purposes, and annotating EventLog entries.

12. DeviceID has no scoring impact, no structural impact, and is not exposed in the UI beyond a simple device list in Settings.

13. Deregistering a device (e.g. lost phone) removes the DeviceID from the sync roster. No data is deleted — all data contributed by that device is already merged into the canonical raw dataset.

17.4.2 Canonical Data Rules

Raw Execution Data (Append-Only)

The following entities are append-only and merged additively during sync. No raw execution data is ever discarded during synchronisation:

8.  PracticeBlocks

9.  PracticeEntries

10. Sessions

11. Sets

12. Instances

13. EventLog entries

Each entity carries a globally unique UUID primary key generated on the originating device. UUID collisions are statistically impossible and no deduplication by content is required. EventLog entries additionally carry the originating DeviceID for audit trail purposes.

Structural Configuration (Last-Write-Wins)

The following entities are mutable and resolved via Last-Write-Wins (LWW) based on UTC timestamp (UpdatedAt field):

9.  User Custom Drill definitions (including anchor edits)

10. Club configuration (UserClub, ClubPerformanceProfile, UserSkillAreaClubMapping)

11. Routine and Schedule definitions

12. CalendarDay SlotCapacity and individual Slot assignments (LWW per Slot position)

13. User Settings and preferences

For CalendarDay Slot conflicts: if Device A wrote Slot 3 at 10:00 UTC and Device B wrote Slot 3 at 10:05 UTC, Device B’s assignment wins. If a Slot’s content changes via LWW, ownership references from the losing write are broken, consistent with the manual-edit-breaks-ownership rule in Section 8 (§8.2.4).

Soft-Delete Propagation

Soft-delete flags (IsDeleted = true) are synced using the same LWW timestamp governance as structural edits. Deletion always propagates forward and is never reversed by sync. If Device A deletes an entity and Device B has not, the delete wins regardless of which device syncs first. A soft-deleted record cannot be un-deleted by older state arriving from another device.

Materialised Scoring State (Never Synced)

The following are never transmitted during synchronisation:

7.  MaterialisedWindowState

8.  MaterialisedSubskillScore

9.  MaterialisedSkillAreaScore

10. MaterialisedOverallScore

11. Any derived analytics or trend cache

Materialised scoring state is a rebuildable cache, not a source of truth (Section 16, §16.4; Section 7, §7.11.1). It is always locally derived from raw Instance data and the current structural parameters. After sync, each device rebuilds its materialised state locally via deterministic reflow.

17.4.3 Sync Pipeline

When a device initiates synchronisation, the following steps execute in order:

Step 1 — Upload Local Changes

The device transmits all locally created or modified entities since its last successful sync timestamp to the server. This includes new raw execution data, structural edits, soft-delete flags, and EventLog entries.

Step 2 — Download Remote Changes

The device receives all entities created or modified by other devices (or centrally) since its last successful sync timestamp. This includes raw execution data from other devices, structural edits, soft-delete flags, System Drill updates, and EventLog entries from other devices.

Step 3 — Merge

Raw execution data is appended (no conflict possible due to unique UUIDs). Structural edits are resolved via LWW timestamp governance. Soft-deletes propagate forward. System Drill definitions are updated to the latest central version.

Step 4 — Completion Matching

Calendar completion matching (Section 8, §8.3.2) re-runs against all newly merged Closed Sessions. Matching follows standard rules: date-strict in user’s home timezone, DrillID matching, first-match ordering for duplicates. Completion overflow (Section 8, §8.3.3) applies normally if a merged Session has no matching Slot.

Step 5 — Deterministic Rebuild

A full local deterministic reflow executes from raw Instance data and the current structural parameters (post-merge). All materialised scoring tables are rebuilt atomically. This guarantees convergence: every device produces identical scoring state from identical raw data.

Step 6 — Confirm

The device’s last successful sync timestamp is updated. The sync cycle is complete.

17.4.4 Sync Trigger Model

5.  Automatic on connectivity restore — the moment the device detects a network connection after being offline, sync begins silently in the background.

6.  Periodic background sync — while online, sync runs at a regular interval to catch changes from other devices or centrally published System Drill updates.

7.  Manual trigger — a manual sync option is available in Settings as a convenience. Not required for normal operation.

17.4.5 Sync UX Model

Synchronisation is silent and non-blocking. The user continues to interact with the application normally during sync. Scoring views remain accessible throughout.

If the post-sync deterministic rebuild completes within the expected sub-1-second window (likely given the 25-occupancy-unit window cap), the user does not perceive any interruption. If the rebuild takes longer (edge case involving large data merges), a subtle non-blocking “Updating…” indicator is displayed. This is not a hard scoring lock — it is a visual hint only. The Section 7 full scoring lock model does not apply to sync-triggered rebuilds because sync is a background reconciliation process, not a user-initiated structural edit.

If a user-initiated structural edit (e.g. anchor change) coincides with a sync-triggered rebuild, the user-initiated reflow takes priority. The sync rebuild is deferred until the user-initiated reflow completes, then re-executes to incorporate any additional merged data.

17.4.6 Sync Failure & Recovery

If sync fails mid-pipeline (network interruption, server unavailability):

8.  No partial merge is committed. Each entity merge is atomic. The sync pipeline guarantees consistency even if interrupted: either the full pipeline completes or no changes are applied.

9.  The device continues operating against its current local state.

10. Sync retries automatically on the next trigger (connectivity restore or periodic interval).

11. No data loss occurs. All locally logged data remains intact.

12. No user action is required for recovery.

17.4.7 Cross-Device Session Concurrency

The single active Session per user rule (Section 3, §3.5; Section 13, §13.5.2) is enforced as follows:

Same Device

Single active Session enforced at runtime. Unchanged from Section 3 and Section 13.

Cross-Device While Online

Server-mediated conflict detection as defined in Section 3 (§3.5). If a second device attempts to start a Session while another device has an active Session, a warning is displayed. On confirmation, the previous Session is hard discarded and the new Session becomes authoritative.

Cross-Device While Offline

No runtime enforcement is possible. Both devices may independently start and complete Sessions. This is accepted by design. On sync, both Sessions merge and enter Subskill windows chronologically by CompletionTimestamp. No data is discarded. PracticeBlock boundaries remain device-scoped. Window logic is chronological and device-agnostic. Cross-device online enforcement is advisory rather than protective. Offline overlap is considered a valid edge case and not a violation.

  --------------------------------------------------------------------------------
  Rule                     Behaviour
  ------------------------ -------------------------------------------------------
  Single ActiveSession     Enforced per device at runtime

  Cross-device (online)    Server-mediated conflict detection (Section 3 model)

  Cross-device (offline)   Both Sessions allowed; merged chronologically on sync

  Window insertion         Strictly chronological by CompletionTimestamp

  PracticeBlock scope      Device-local grouping

  Data discarded on sync   Never
  --------------------------------------------------------------------------------

17.4.8 System Drill Update Delivery

System Drill updates published centrally are delivered to devices as part of the standard sync pipeline (Step 2). On receipt:

11. The device detects that the central System Drill definition has changed since its last sync.

12. The updated definition replaces the local copy.

13. A full local reflow is triggered automatically as part of the sync deterministic rebuild (Step 5).

14. No user action is required. The reflow executes silently in the background.

15. If the device remains offline indefinitely, it continues operating against the last-known System Drill definitions. Scoring remains deterministic against those definitions. The device converges on the next successful sync.

17.4.9 App Version Compatibility

Sync requires matching schema versions between the device’s local database and the server’s current canonical schema.

6.  If a device’s local schema version is older than the server’s current canonical schema, sync is blocked.

7.  A clear message is displayed: “App update required to sync.”

8.  The device continues to function fully offline against its current local schema while awaiting the app update. No data loss. No degradation.

9.  On app update, the application runs any required local schema migrations, then sync proceeds normally with a full deterministic rebuild. All schema migrations must preserve backward compatibility of raw execution entities. Data logged under an older schema version must remain valid and interpretable after migration, ensuring that offline-first multi-device operation is never compromised by schema evolution.

10. This prevents corrupted merges from schema mismatches while preserving the offline-first guarantee.

17.5 Data Export & Sharing

Data export is manual and user-initiated, consistent with Section 10 (§10.11).

Export Characteristics

12. Primary format: JSON (complete user-scoped dataset snapshot).

13. Optional format: CSV session summary.

14. Snapshot reflects state at time of export.

15. No re-import capability in V1.

16. No shareable links, hosted dashboards, or external viewing portals.

17. No real-time coach feeds or live shared access.

18. No server-hosted public endpoints exposing scoring data.

Export scope includes: Drills (User Custom and adopted references), Sessions, Sets, Instances (including RawMetrics and SelectedClub), Club configuration, Calendar entities, Routines and Schedules, and EventLog entries. The user controls when and how the exported file is shared. No application-mediated sharing mechanism exists.

17.6 Coach/Admin Access

Version 1 contains no coach, admin, or secondary user role. All access is strictly per-user. The application enforces single-user scoping at every layer.

7.  No shared accounts.

8.  No delegated access models.

9.  No cross-user visibility or comparison layers.

10. No internal permission model beyond user-level authority.

11. No admin override layer beyond system-governed structural parameters (Section 10, §10.2).

Any coach interaction in V1 occurs externally via exported data files (Section 17.5). The coach receives a JSON or CSV export and reviews it using their own tools. No in-app collaboration exists.

Future Compatibility

The data model and sync architecture are designed to accommodate a future coach/shared access layer without schema breakage. UserID scoping, DeviceID separation, and the append-only EventLog provide the structural foundation for role-based access in a future version. No V1 design decision precludes this extension.

17.7 User Behaviour Constraints

ZX Golf App does not enforce behavioural realism constraints. The system records what the user enters and processes it deterministically. Responsibility for score integrity sits with the user, consistent with Section 11 (§11.1).

Explicitly Not Enforced

13. Maximum Sessions per hour or per day.

14. Maximum Instances per minute.

15. Minimum realistic time between shots.

16. Prevention of back-dated or future-dated Session creation.

17. Continuous activity duration limits beyond PracticeBlock auto-end.

18. Shot-rate throttling.

19. Volume caps on daily or weekly practice.

20. Anti-gaming detection or scoring penalties.

21. Competition mode detection.

Structural Constraints (Existing)

The only constraints on user behaviour are structural integrity rules already defined in Sections 1–14:

5.  Single active Session per device at runtime (Section 3, §3.5; Section 13, §13.5.2).

6.  Session inactivity auto-close after 2 hours (Section 3, §3.4).

7.  PracticeBlock auto-end after 4 hours without new Session (Section 3, §3.1.3).

8.  Schema plausibility bounds on numeric entry fields (Section 11, §11.3).

9.  Hard validation of required fields and value ranges (Section 4, §4.6).

10. Incomplete structured Sessions cannot be saved (Section 4, §4.7).

17.8 Practical Session Time Limits

The sole duration constraints are the existing structural safeguards:

5.  Session inactivity auto-close: 2 hours with no new Instance (Section 3, §3.4).

6.  PracticeBlock auto-end: 4 hours without a new Session being started (Section 3, §3.1.3).

No additional hard maximum PracticeBlock duration is imposed. No per-Session absolute time cap exists. No daily cumulative practice limit exists. These timers are system-level constants and are not user-configurable (Section 10, §10.7).

17.9 Data Model Additions

Section 17 introduces the following additions to the persistence layer defined in Section 6 and Section 16.

17.9.1 New Entity: UserDevice

  -----------------------------------------------------------------------------------------
  Field                  Type                       Notes
  ---------------------- -------------------------- ---------------------------------------
  DeviceID               UUID (PK)                  Generated locally on first app launch

  UserID                 UUID (FK)                  Owner

  DeviceName             String nullable            User-facing label (e.g. "iPhone 15")

  LastSyncTimestamp      Timestamp (UTC) nullable   Last successful sync completion

  SchemaVersion          String                     Local database schema version

  Status                 Enum                       Active, Deregistered

  CreatedAt              Timestamp (UTC)            

  UpdatedAt              Timestamp (UTC)            
  -----------------------------------------------------------------------------------------

17.9.2 EventLog Extension

The EventLog entity (Section 6, §6.2) is extended with:

4.  DeviceID (UUID, nullable) — the originating device for the event. Null for server-generated events (e.g. System Drill updates). Enables full audit trail across devices. Device timestamps are treated as best-effort ordering hints; chronological ordering for scoring always uses CompletionTimestamp as defined in Section 3 (§3.1.4). Cross-device EventLog entries may exhibit clock drift and are not guaranteed to reflect causal ordering.

17.9.3 Indexing

6.  UserDevice(UserID) — device list per user.

7.  EventLog(DeviceID) — device-origin audit queries.

17.9.4 No Scoring Impact

UserDevice and the EventLog DeviceID extension have no relationship to the scoring engine. They do not trigger reflow, do not enter windows, and do not affect any derived scoring state. They are pure synchronisation infrastructure.

17.10 Cross-Section Impact

Section 17 requires the following updates to existing specification documents:

-   Section 3 (User Journey Architecture, 3v.g6) — §3.5 Concurrency Model: add offline fallback clause. When both devices are offline, cross-device Session overlap is permitted and resolved chronologically on sync. Server-mediated conflict detection applies only when connectivity exists. §3.6 Offline Behaviour: update to reference Section 17 as the canonical authority for offline capability. Remove any implication that scoring requires server connectivity.

-   Section 6 (Data Model & Persistence Layer, 6v.b5) — Add UserDevice entity to §6.1 Core Domain Objects (Relationship Objects). Add DeviceID field to EventLog entity schema. Add indexing entries for UserDevice(UserID) and EventLog(DeviceID).

-   Section 7 (Reflow Governance System, 7v.b8) — §7.5 Lock Conditions: add clarification that the full scoring lock model does not apply to sync-triggered deterministic rebuilds. Sync rebuilds are background reconciliation processes and use a non-blocking model. User-initiated reflows retain priority.

10. Section 13 (Live Practice Workflow, 13v.a4) — §13.14.5 Offline Behaviour: supersede the current offline limitation list. Remove reflow, Calendar completion matching, and Drill creation from the “Not supported offline” list. Section 17 is the canonical authority for offline capability. All operations listed in §17.3.1 are fully supported offline.

14. Section 16 (Database Architecture, 16v.a3) — Add UserDevice table to §16.1 Source Tables. Add DeviceID column to EventLog table. Add sync-related indexes.

14. Section 0 (Canonical Definitions, 0v.e9) — Add terms: DeviceID, UserDevice, Last-Write-Wins (LWW), Deterministic Merge-and-Rebuild, Sync Pipeline.

17.11 Structural Guarantees

The Real-World Application Layer guarantees:

14. Training-only positioning — no on-course, competitive, or rules-aware functionality.

15. Full offline-first capability — every device is a standalone node with complete local scoring engine and data mirror.

16. Server is not scoring authority — all scoring executes locally on-device.

17. Deterministic convergence — identical raw data always produces identical scoring state across all devices.

18. No append-only execution data is ever discarded during sync — raw Instances, Sessions, Sets, PracticeBlocks, and EventLog entries are always preserved.

19. Last-Write-Wins for structural edits — predictable, timestamp-governed conflict resolution.

20. Forward-only soft-delete propagation — deletions are never reversed by sync.

21. Silent background sync — non-blocking, low-friction, automatic.

22. Schema version gating — sync blocked on version mismatch; full offline operation continues.

23. No behavioural enforcement — determinism over policing.

24. No coach/admin layer in V1 — single-user scoped, future-compatible.

25. Manual export only — no shared links, no hosted dashboards, no external access.

26. Existing structural safeguards preserved — all Section 1–14 constraints remain in force.

27. Full compatibility with Sections 0–16 — no architectural deviation from the canonical scoring model, data model, reflow governance, or database architecture.

End of Section 17 — Real-World Application Layer (17v.a4 Canonical)
