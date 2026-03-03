# ZX Golf App — Operational Documentation

## Recovery Point Objective (RPO)

RPO is implicitly ~5 minutes, determined by the periodic sync interval
(`kSyncPeriodicInterval = Duration(minutes: 5)` in `lib/core/constants.dart`).

Data committed locally between sync cycles is at risk only if the device is lost
or the app is uninstalled before the next successful sync. In practice, sync also
fires on post-session and connectivity-restored triggers, reducing effective RPO.

## Recovery Time Objective (RTO)

- **Local:** Immediate. All operations execute against the on-device Drift SQLite
  database. The app is fully functional offline.
- **Server:** Dependent on Supabase managed infrastructure. Supabase provides
  99.9% uptime SLA on Pro plans with automatic failover.

## Backup Strategy

| Layer | Mechanism | Frequency | Retention |
|-------|-----------|-----------|-----------|
| Server (Supabase Postgres) | Continuous WAL archiving + daily snapshots | Continuous / daily | Per Supabase plan (7 days on Pro) |
| Local (Drift SQLite) | On-device file at `getApplicationDocumentsDirectory()/zx_golf_app.sqlite` | N/A (persistent) | Survives app updates; lost on app uninstall |
| Cross-device | Sync engine replicates raw execution data to server | Every ~5 minutes + event-driven | Server-side retention applies |

**Note:** Local SQLite data is not independently backed up to external storage.
The sync engine serves as the de facto backup path — all raw execution data
syncs to the server and can be pulled down to any authenticated device.

## Transaction Isolation

SQLite uses **Serializable** isolation by default. All Drift `.transaction()` calls
execute under this strictest isolation level. No configuration change is needed.

This satisfies S16 §16.4 (transaction isolation requirements). Concurrent reads
are permitted, but only one write transaction executes at a time. The
`SyncWriteGate` mechanism (TD-03 §2.1.1) provides additional application-level
coordination to prevent sync writes from interleaving with user writes.

## Sync Architecture Summary

- **Conflict resolution:** Row-level Last-Writer-Wins (LWW) by `UpdatedAt` timestamp.
  Delete-always-wins for soft-deleted rows. CalendarDay uses slot-level merge.
- **Ordering:** Parent-before-child on upload, child-before-parent on delete.
- **Payload limit:** 2MB per upload batch (`kSyncMaxPayloadBytes`).
- **Failure handling:** Exponential backoff with jitter (1s, 2s, 4s). Auto-disable
  after 5 consecutive failures (`kSyncMaxConsecutiveFailures`).
- **Post-merge:** Full scoring rebuild ensures deterministic convergence across devices.
