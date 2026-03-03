TD-07 Error Handling Patterns — Phase 1 Extract (TD-07v.a4)
Sections: §2 Error Type Hierarchy, §3 Error Propagation Model, §10 User-Facing Error Messaging, §15 Error Handling by Build Phase
============================================================

2. Error Type Hierarchy

TD-03 §7.2 defines the base exception class and categories. This section consolidates the complete hierarchy with the specific exception types used throughout this document.

2.1 Base Class

All application errors extend ZxGolfAppException, which carries a machine-readable code (String), a human-readable message (String), and an optional context map (Map<String, dynamic>) for diagnostic metadata. The code field uses the CATEGORY_SPECIFIC_ERROR naming convention (e.g. SYNC_UPLOAD_FAILED, VALIDATION_INVALID_ANCHORS).

2.2 Exception Categories

  ------------ -------------- ---------------------------------------------- -------------------------------------------
  Category     Prefix         Scope                                          User Impact

  Validation   VALIDATION_*   Input rejected before persistence              Inline field error; operation blocked

  Reflow       REFLOW_*       Scoring pipeline failure                       Temporary scoring freeze; auto-recovery

  Sync         SYNC_*         Transport or merge failure                     Sync deferred; local operation unaffected

  System       SYSTEM_*       Infrastructure failure (DB, storage, memory)   Feature degradation; may require restart

  Conflict     CONFLICT_*     Cross-device state divergence                  Informational; auto-resolved or surfaced

  Auth         AUTH_*         Authentication or authorisation failure        Re-authentication prompt; local data safe
  ------------ -------------- ---------------------------------------------- -------------------------------------------

2.3 Complete Exception Catalogue

The following table enumerates every exception code used in the application. Each code maps to exactly one recovery pattern defined in subsequent sections.

  ---------------------------------- ------------------------------------------ --------------------------------
  Code                               Thrown By                                  Recovery Pattern

  VALIDATION_INVALID_ANCHORS         DrillRepository.createDrill, editAnchors   §4.1 — Inline validation

  VALIDATION_INVALID_STRUCTURE       DrillRepository.createDrill                §4.1 — Inline validation

  VALIDATION_REQUIRED_FIELD          Any Repository create/update               §4.1 — Inline validation

  VALIDATION_STATE_TRANSITION        Any Repository state change                §4.2 — Guard rejection

  VALIDATION_DUPLICATE_ENTRY         Repository insert operations               §4.1 — Inline validation

  VALIDATION_SINGLE_ACTIVE_SESSION   PracticeRepository.startSession            §4.3 — Active Session conflict

  REFLOW_LOCK_TIMEOUT                ScoringRepository.executeReflow            §5.1 — Lock retry exhaustion

  REFLOW_TRANSACTION_FAILED          ScoringRepository.executeReflow            §5.2 — Transaction rollback

  REFLOW_REBUILD_TIMEOUT             ScoringRepository.executeFullRebuild       §5.3 — Rebuild timeout

  SYNC_UPLOAD_FAILED                 SyncEngine.upload                          §6.1 — Transport retry

  SYNC_DOWNLOAD_FAILED               SyncEngine.download                        §6.1 — Transport retry

  SYNC_MERGE_FAILED                  SyncEngine.merge                           §6.2 — Merge rollback

  SYNC_MERGE_TIMEOUT                 SyncWriteGate (60s hard timeout)           §6.3 — Gate timeout

  SYNC_SCHEMA_MISMATCH               SyncEngine.validateSchema                  §6.4 — Schema version block

  SYNC_PAYLOAD_TOO_LARGE             SyncEngine.upload                          §6.5 — Payload splitting

  SYNC_NETWORK_UNAVAILABLE           ConnectivityMonitor                        §6.6 — Offline deferral

  SYSTEM_DATABASE_CORRUPT            Drift startup or query                     §7.1 — Database recovery

  SYSTEM_STORAGE_FULL                Drift write operation                      §7.2 — Storage pressure

  SYSTEM_OUT_OF_MEMORY               Reflow or rebuild at scale                 §7.3 — Memory pressure

  SYSTEM_MIGRATION_FAILED            Drift schema migration                     §7.4 — Migration failure

  SYSTEM_REFERENTIAL_INTEGRITY       Drift FK constraint violation              §14.1 — Referential integrity

  CONFLICT_DUAL_ACTIVE_SESSION       SyncEngine.merge (Session)                 §8.1 — LWW resolution

  CONFLICT_STRUCTURAL_DIVERGENCE     SyncEngine.merge (Drill, etc.)             §8.2 — Silent LWW merge

  CONFLICT_SLOT_COLLISION            SyncEngine.merge (CalendarDay)             §8.3 — Slot-level merge

  AUTH_TOKEN_EXPIRED                 Supabase client                            §9.1 — Token refresh

  AUTH_REFRESH_FAILED                Supabase client                            §9.2 — Re-authentication

  AUTH_SESSION_REVOKED               Supabase client                            §9.3 — Forced re-auth
  ---------------------------------- ------------------------------------------ --------------------------------

3. Error Propagation Model

Errors propagate through three layers: Repository, Provider, and UI. Each layer has a distinct responsibility.

3.1 Repository Layer

Repository methods throw typed ZxGolfAppException subclasses. They never catch and swallow exceptions silently. Every thrown exception carries a diagnostic context map with at minimum: the operation name, the entity type, and the entity ID (where applicable). Repository methods wrap Drift transactions in try-catch blocks. If a Drift transaction fails, the Repository wraps the underlying DatabaseException in the appropriate ZxGolfAppException subclass before re-throwing.

3.2 Riverpod Provider Layer

Providers expose errors as AsyncError states on AsyncValue. When a Repository method throws, the provider transitions to AsyncError with the ZxGolfAppException as the error object. Providers never catch exceptions for the purpose of suppressing them. Providers may catch exceptions for the purpose of mapping them to a more specific AsyncError state (e.g. adding retry metadata).

Reactive streams (Drift watch queries) emit errors through the stream error channel. The provider surfaces these as AsyncError. Stream errors do not terminate the stream; the provider remains subscribed and will emit the next successful value when the underlying query succeeds.

3.3 UI Layer

The UI layer consumes AsyncValue and renders error states using a consistent ErrorDisplay widget. The widget pattern is defined in §10. The UI never catches exceptions directly from Repository calls; all error handling flows through Riverpod’s AsyncValue.when() pattern.

Unhandled exceptions that escape the Riverpod error boundary are caught by a top-level FlutterError.onError handler and the Dart Zone error handler. These log the error (domain: system, level: error) and display a generic fallback error message. The app does not crash on unhandled exceptions; it degrades gracefully.


============================================================

10. User-Facing Error Messaging

All error messages follow the branding and communication principles from Section 15 §15.2: factual, neutral, actionable. No apologetic language, no exclamation marks, no emoji, no blame attribution.

10.1 Message Structure

Every user-facing error message has exactly two components: a statement of what happened (factual, one sentence) and an action the user can take (specific, one sentence). Messages that cannot offer an action state that the issue will resolve automatically.

Good: “Scores are updating. This may take a moment.”

Bad: “Oops! Something went wrong with your scores. We’re really sorry about that!”

10.2 Display Patterns

Error messages are displayed using one of four patterns, selected based on severity and user-action requirement:

  -------------------- ----------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Pattern              Use Case                                  Behaviour

  Inline field error   Validation failures on specific fields    Red text below the field. Appears on field change or form submission. Dismisses when the field is corrected.

  Toast / snackbar     Transient informational messages          Appears at bottom of screen. Auto-dismisses after 4 seconds. No user action required. Used for: sync status, conflict resolution notifications, auto-recovery confirmations.

  Persistent banner    Ongoing conditions requiring awareness    Appears below the app bar. Does not auto-dismiss. Includes a dismiss action or resolves when the condition clears. Used for: offline indicator, storage warning, schema mismatch, auth expiry.

  Blocking dialog      Rare conditions requiring user decision   Modal dialog. Requires user action to dismiss. Used only for: cross-device active Session conflict (confirm discard), database corruption recovery (Tier 2/3 requiring acknowledgement), sync auto-disable notification.
  -------------------- ----------------------------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

10.3 Complete Message Catalogue

The following table lists every user-facing error message in the application. Messages are referenced by their exception code for traceability.

  ---------------------------------- ------------------- ----------------------------------------------------------------------------------------------------------------
  Code                               Pattern             Message

  VALIDATION_INVALID_ANCHORS         Inline              Min must be less than Scratch, and Scratch must be less than Pro.

  VALIDATION_INVALID_STRUCTURE       Inline              This field cannot be changed after the drill is created.

  VALIDATION_REQUIRED_FIELD          Inline              {field_name} is required.

  VALIDATION_STATE_TRANSITION        Toast               This action is no longer available. The screen will refresh.

  VALIDATION_SINGLE_ACTIVE_SESSION   Toast               You have an active session in progress.

  REFLOW_LOCK_TIMEOUT                None (auto-retry)   (Loading indicator on score displays only)

  REFLOW_TRANSACTION_FAILED          None (auto-retry)   (Scores show pre-edit values until retry succeeds)

  REFLOW_REBUILD_TIMEOUT             Banner              Scores are temporarily unavailable. They will update shortly.

  SYNC_UPLOAD_FAILED                 Toast               Sync could not complete. Will retry automatically.

  SYNC_DOWNLOAD_FAILED               Toast               Sync could not complete. Will retry automatically.

  SYNC_MERGE_FAILED (recurring)      Banner              Sync is experiencing repeated issues. Your data is safe locally.

  SYNC_MERGE_TIMEOUT                 Toast               Sync timed out. Will retry automatically.

  SYNC_SCHEMA_MISMATCH               Banner + Dialog     An app update is required to sync across devices. Your data is safe locally.

  SYSTEM_DATABASE_CORRUPT            Dialog              (Tier-specific message per §7.1)

  SYSTEM_STORAGE_FULL                Banner              Could not save. Your device storage is full. Please free up space.

  SYSTEM_MIGRATION_FAILED            Banner              The app update could not be fully applied. Please restart the app.

  CONFLICT_DUAL_ACTIVE_SESSION       Toast (6s)          A session with {N} logged attempts from this device was replaced by a more recent session from another device.

  AUTH_REFRESH_FAILED                Banner              Please sign in again to sync across devices. Your data is safe.

  AUTH_SESSION_REVOKED               Banner              Please sign in again to sync across devices. Your data is safe.

  SYSTEM_REFERENTIAL_INTEGRITY       Dialog              An unexpected data error occurred. Please restart the app.
  ---------------------------------- ------------------- ----------------------------------------------------------------------------------------------------------------

10.4 Messages That Are Never Shown

The following events are handled silently with no user-facing message. They are logged for diagnostic purposes only: SYNC_NETWORK_UNAVAILABLE (the offline indicator is shown instead, which is a status indicator, not an error message), CONFLICT_STRUCTURAL_DIVERGENCE (silent LWW resolution), CONFLICT_SLOT_COLLISION (silent per-Slot LWW), AUTH_TOKEN_EXPIRED with successful refresh, REFLOW_LOCK_TIMEOUT with successful deferred retry, individual sync transport retries (only the final failure is potentially surfaced), execution data additive merge (this is normal operation, not a conflict).


============================================================

15. Error Handling by Build Phase

This section maps error handling deliverables to the TD-06 build phases. Each phase introduces specific error patterns that must be implemented and tested.

  ------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  Phase                     Error Handling Deliverables

  1 — Data Foundation       ZxGolfAppException base class and all subclasses. Top-level FlutterError.onError and Zone error handlers. ErrorDisplay widget (all four display patterns). Startup allocation invariant check.

  2A — Pure Scoring         Anchor validation (VALIDATION_INVALID_ANCHORS). Division-by-zero prevention in interpolation. Score cap enforcement (never > 5.0). No error handling for orchestration (pure functions).

  2.5 — Server Foundation   SYNC_SCHEMA_MISMATCH detection and UI. AUTH_TOKEN_EXPIRED and AUTH_REFRESH_FAILED handling. Basic transport error detection (HTTP status codes). DTO validation on download.

  2B — Reflow & Lock        REFLOW_LOCK_TIMEOUT with deferred retry. REFLOW_TRANSACTION_FAILED with rollback and retry. Crash mid-reflow detection and full rebuild. Startup scoring lock check. RebuildNeeded flag mechanism with UI staleness contract. OOM consecutive failure counter. Error-specific developer instrumentation.

  3 — Drill & Bag           VALIDATION_INVALID_STRUCTURE for immutability enforcement. VALIDATION_STATE_TRANSITION for Drill/UserDrillAdoption/UserClub state machines. Anchor edit reflow error propagation.

  4 — Live Practice         VALIDATION_SINGLE_ACTIVE_SESSION. Session close pipeline error handling with explicit idempotency guard (Status = Active check). Timer error handling (TimerService failures). Instance logging crash recovery. PracticeBlock crash recovery.

  5 — Planning              Completion matching error handling (no match found is not an error). Cascade deletion error propagation. CalendarDay Slot validation.

  6 — Review                Graceful rendering with empty/stale materialised data. Zero-state handling. Cold-start performance validation.

  7A — Sync Transport       SYNC_UPLOAD_FAILED / SYNC_DOWNLOAD_FAILED with retry strategy. SYNC_PAYLOAD_TOO_LARGE handling. SYNC_NETWORK_UNAVAILABLE deferral. Partial upload state tracking and resumption. Sync concurrency control (single active sync invariant, retry cancellation on connectivity change, trigger debouncing). Sync diagnostic logging.

  7B — Merge & Rebuild      SYNC_MERGE_FAILED with rollback. SYNC_MERGE_TIMEOUT with gate release. CONFLICT_DUAL_ACTIVE_SESSION resolution with Instance count logging. Merge transaction atomicity enforcement. Post-merge rebuild error propagation. Consecutive failure counter persistence. Auto-disable state machine (5-failure threshold, persisted state, re-enable rules, schema mismatch bypass).

  7C — Conflict UI          All user-facing sync error messages. Offline indicator. Schema mismatch banner. Auth re-authentication banner. Cross-device Session conflict dialog. Storage monitoring with download resume trigger (100MB threshold hysteresis). Sync-disabled indicator. Merge failure banner tied to consecutive failure counter.

  8 — Polish                Error message audit (all messages factual and actionable). SYSTEM_DATABASE_CORRUPT tiered recovery. SYSTEM_MIGRATION_FAILED rollback. SYSTEM_STORAGE_FULL handling with sync asymmetry. SYSTEM_OUT_OF_MEMORY fail-hard with restart recovery and 2-failure escalation. SYSTEM_REFERENTIAL_INTEGRITY generic dialog. RebuildNeeded UI staleness verification. Full end-to-end error scenario testing.
  ------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

