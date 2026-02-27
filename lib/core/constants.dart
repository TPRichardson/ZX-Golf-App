// App-wide constants per S01, S02, TD-03.

// Spec: S01 §1.4 — Scoring window maximum occupancy.
const kMaxWindowOccupancy = 25.0;

// Spec: S02 §2.5 — Subskill weighting: Transition vs Pressure.
const kTransitionWeight = 0.35;
const kPressureWeight = 0.65;

// Spec: S01 §1.2 — Maximum possible score value.
const kMaxScore = 5.0;

// Spec: S02 §2.3 — Total allocation across all subskills.
const kTotalAllocation = 1000;

// TD-03 §2.1.1 — SyncWriteGate drain period.
const kSyncWriteGateDrainPeriod = Duration(seconds: 2);

// TD-03 §2.1.1 — SyncWriteGate hard timeout.
const kSyncWriteGateHardTimeout = Duration(seconds: 60);

// Phase 1 stub — hardcoded dev user ID for local development.
// TD-06 §4.3 — Authentication stub.
const kDevUserId = '00000000-0000-4000-8000-000000000000';
