// App-wide constants per S01, S02, TD-03.

// Default window occupancy. Per-subskill sizes defined in SubskillRef.windowSize.
const kMaxWindowOccupancy = 25.0;

// Spec: S02 §2.5 — Subskill weighting: Transition vs Pressure.
const kTransitionWeight = 0.35;
const kPressureWeight = 0.65;

// Spec: S01 §1.2 — Maximum possible score value.
const kMaxScore = 5.0;

// Spec: S01 §1.4 — Score at scratch benchmark.
const kScratchScore = 3.5;

// Spec: S02 §2.3 — Total allocation across all subskills.
const kTotalAllocation = 1000;

// TD-03 §2.1.1 — SyncWriteGate drain period.
const kSyncWriteGateDrainPeriod = Duration(seconds: 2);

// TD-03 §2.1.1 — SyncWriteGate hard timeout.
const kSyncWriteGateHardTimeout = Duration(seconds: 60);

// Phase 1 stub — hardcoded dev user ID for local development.
// TD-06 §4.3 — Authentication stub.
const kDevUserId = '00000000-0000-4000-8000-000000000000';

// TD-03 §5.2 — Sync schema version. Server rejects mismatches.
const kSyncSchemaVersion = '1';

// TD-07 §6.1 — Exponential backoff retry delays for sync RPCs.
const kSyncRetryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
];

// TD-07 §6.1 — Jitter added to retry delays (±250ms).
const kSyncRetryJitter = Duration(milliseconds: 250);

// TD-07 §6.2 — Max consecutive sync failures before escalation.
const kSyncMaxConsecutiveFailures = 5;

// TD-07 §6.2 — Failures before escalation notification.
const kSyncEscalationThreshold = 3;

// ---------------------------------------------------------------------------
// Phase 2B — Reflow & Lock constants
// ---------------------------------------------------------------------------

// TD-04 §3.2 Step 1 — UserScoringLock expiry duration.
const kUserScoringLockExpiry = Duration(seconds: 30);

// TD-04 §3.2 Step 1 — Maximum retry attempts for lock acquisition.
const kLockMaxRetries = 3;

// TD-04 §3.2 Step 1 — Delay between lock acquisition retries.
const kLockRetryDelay = Duration(milliseconds: 500);

// TD-03 §4.5 — RebuildGuard timeout before auto-release.
const kRebuildGuardTimeout = Duration(seconds: 30);

// TD-06 §7.1.2 — Scoped reflow p95 performance target.
const kScopedReflowTarget = Duration(milliseconds: 150);

// TD-06 §7.1.2 — Full rebuild p95 performance target.
const kFullRebuildTarget = Duration(seconds: 1);

// ---------------------------------------------------------------------------
// Phase 4 — Live Practice timer constants
// ---------------------------------------------------------------------------

// S13 §13.5.3 — Session inactivity timeout (2 hours).
const kSessionInactivityTimeout = Duration(hours: 2);

// S13 §13.10.2 — PracticeBlock auto-end timeout (4 hours).
const kPracticeBlockAutoEndTimeout = Duration(hours: 4);

// ---------------------------------------------------------------------------
// Phase 5 — Planning Layer constants
// ---------------------------------------------------------------------------

// S08 §8.13.1 — Default slot capacity for new calendar days.
const kDefaultSlotCapacity = 5;

// ---------------------------------------------------------------------------
// Phase 7A — Sync Transport & Orchestration constants
// ---------------------------------------------------------------------------

// TD-03 §5.1 — Periodic sync interval.
const kSyncPeriodicInterval = Duration(minutes: 5);

// TD-07 §6.1.1 — Debounce window for rapid triggers.
const kSyncDebounceWindow = Duration(milliseconds: 500);

// Idle threshold: skip automatic syncs if no user activity within this window.
const kSyncIdleThreshold = Duration(minutes: 10);

// TD-03 §5.2 — Maximum upload payload size in bytes (2MB).
const kSyncMaxPayloadBytes = 2 * 1024 * 1024;

// ---------------------------------------------------------------------------
// Phase 7C — Conflict UI & Offline Hardening constants
// ---------------------------------------------------------------------------

// TD-07 §6.2 — Merge timeout threshold for separate banner.
const kSyncMergeTimeoutThreshold = 3;

// Phase 7C — Low storage warning threshold (100MB).
const kLowStorageThresholdBytes = 100 * 1024 * 1024;
