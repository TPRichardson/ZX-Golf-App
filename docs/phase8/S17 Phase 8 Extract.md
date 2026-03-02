# S17 Real World Application Layer — Phase 8 Extract
Sections: §17.3.5 Local Storage Model (Storage Monitoring)
============================================================

17.3.5 Local Storage Model

Each device maintains a full relational mirror of the Section 16 schema, including all Source Tables, Planning Tables, Materialised Tables, and System Tables. No automatic data pruning occurs in V1. All raw data is retained locally indefinitely.

The window cap of 25 occupancy units per subskill (Section 1, §1.6) puts a natural ceiling on materialised state size. Instance data is lightweight. EventLog is append-only and retained in full.

If local device storage becomes critically low, the application displays a warning notification advising the user to free device storage. The application does not auto-delete any user data. Optional local archival (e.g. purging synced EventLog entries older than a defined threshold from the local store while retaining them server-side) is explicitly deferred to V2. Reflow operates only on window-relevant data (current occupancy entries per subskill); historical raw data beyond the active windows does not impact reflow complexity or execution time.

