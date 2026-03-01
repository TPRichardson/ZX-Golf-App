// App-wide constants per S01, S02, TD-03.

// Spec: S01 §1.4 — Scoring window maximum occupancy.
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
