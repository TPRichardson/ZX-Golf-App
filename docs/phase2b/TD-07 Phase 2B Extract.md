# TD-07 Error Handling — Phase 2B Extract (TD-07v.a4)
Sections: §5 Reflow Errors
============================================================

5. Reflow Errors

The reflow pipeline (TD-04 §3) is the most architecturally critical error domain. Because reflow is a pure deterministic rebuild from raw data, most reflow errors are recoverable by re-running the pipeline. The primary risk is not incorrect results but temporary scoring unavailability.

5.1 Lock Retry Exhaustion

When ScoringRepository.executeReflow attempts to acquire UserScoringLock and the lock is already held by another reflow, it retries up to 3 times at 500ms intervals (TD-04 §3.2, Step 1). If all retries fail:

Exception: REFLOW_LOCK_TIMEOUT.

Diagnostic log: Domain: scoring, Level: warning. Context: trigger type, lock holder timestamp, retry count.

Recovery: The reflow trigger is enqueued for deferred execution (same mechanism as TD-04 §3.3.3 deferred coalescing). When the current lock holder releases, the deferred queue drains. No user intervention is required.

User impact: The UI displays a brief loading indicator on the affected score displays. The indicator dismisses when the deferred reflow completes. If the deferred reflow has not completed within 5 seconds, the indicator text changes to “Scores are updating. This may take a moment.”

Escalation: If the deferred reflow also times out (i.e. the lock is perpetually held), the expired-lock recovery path activates: after 30 seconds the lock expires, the next operation force-acquires, and a full rebuild executes (TD-04 §3.4.1). This is the terminal recovery path for all lock contention scenarios.

5.2 Transaction Rollback

If the Drift transaction wrapping the reflow algorithm (Steps 1–10) fails at any step:

Exception: REFLOW_TRANSACTION_FAILED.

Diagnostic log: Domain: scoring, Level: error. Context: trigger type, step number where failure occurred, underlying Drift exception message.

Recovery: The Drift transaction rolls back completely. No partial materialised state is written. The scoring lock is released in a finally block (Step 10 always executes, even on error). The reflow trigger is re-enqueued for immediate retry (single retry). If the retry also fails, the trigger is enqueued with a 2-second delay. If the delayed retry fails, the system logs at error level and falls back to the expired-lock full-rebuild recovery path on next app launch.

User impact: Materialised scores remain at their pre-reflow values. These values are stale but consistent (they represent the state before the triggering edit). The user sees no corruption — only a delay in score updates.

5.3 Rebuild Timeout

The full rebuild (TD-04 §3.3, post-sync) is bounded by the RebuildGuard 30-second timeout. If the rebuild exceeds this:

Exception: REFLOW_REBUILD_TIMEOUT.

Diagnostic log: Domain: scoring, Level: error. Context: elapsed duration, subskill count processed before timeout, Instance count in database.

Recovery: The Drift transaction rolls back. Materialised tables retain their pre-rebuild state. A retry is scheduled on next app foreground event. The profiling benchmark harness (TD-06 §7.1.2) is designed to catch this scenario in testing; a rebuild timeout in production indicates data volumes exceeding the tested envelope.

User impact: “Scores are temporarily unavailable. They will update shortly.” Scores display the last known values with a subtle staleness indicator (dimmed opacity, not a warning colour).

5.4 Crash Mid-Reflow

If the app is force-killed or crashes between Steps 1 and 10 of the reflow algorithm:

Detection: On next app launch, the startup sequence checks UserScoringLock. If IsLocked = true and LockExpiresAt < now, the lock is expired.

Recovery: The startup sequence force-acquires the lock and initiates a full rebuild (executeFullRebuild). Because reflow is a pure function of raw data plus current structural parameters, re-running produces identical results (TD-04 §3.4.1). No user intervention is required.

Diagnostic log: Domain: scoring, Level: warning. Context: expired lock timestamp, time since expiry.

User impact: The user sees the standard cold-start loading state. The full rebuild adds to the startup time. At typical data volumes (under 5K Sessions / 50K Instances), the rebuild completes within the 1-second cold-start target (TD-01 §4.2). At higher data volumes approaching the 50K Sessions / 500K Instances ceiling, the full rebuild may exceed 1 second. The Phase 2B profiling benchmark harness validates the actual rebuild duration at target volumes; if the 1-second cold-start target cannot be met at high volumes during a crash-recovery rebuild, a progress indicator is shown and the target is treated as a best-effort goal rather than a hard gate for this specific scenario. The 1-second target remains a hard gate for normal cold starts (where no rebuild is needed) and for full rebuilds at the Phase 2B validated volume tier.

