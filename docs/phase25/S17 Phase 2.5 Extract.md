# S17 Real World Application Layer — Phase 2.5 Extract
Sections: §17.4.1 Device Identity Model, §17.4.2 Canonical Data Rules, §17.4.3 Sync Pipeline
============================================================

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

