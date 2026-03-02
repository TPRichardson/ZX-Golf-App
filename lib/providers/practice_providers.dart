// Phase 4 — Practice workflow Riverpod providers.
// S13 — Live Practice Workflow.
// Bridges PracticeRepository + TimerService to UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';
import 'package:zx_golf_app/core/services/timer_service.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/practice_repository.dart';
import 'package:zx_golf_app/features/planning/completion_matching.dart';

import 'planning_providers.dart';
import 'repository_providers.dart';

/// S13 §13.5.3 — Singleton TimerService.
final timerServiceProvider = Provider<TimerService>((ref) {
  final service = TimerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// S13 §13.2 — Stream of user's active practice block.
final activePracticeBlockProvider =
    StreamProvider.family<PracticeBlock?, String>((ref, userId) {
  return ref.watch(practiceRepositoryProvider).getActivePracticeBlock(userId);
});

/// S13 §13.3 — Composite stream: PB + entries with drill info.
final practiceBlockWithEntriesProvider =
    StreamProvider.family<PracticeBlockWithEntries?, String>((ref, pbId) {
  return ref.watch(practiceRepositoryProvider).watchPracticeBlock(pbId);
});

/// Phase 4 — Stream of sessions for a practice block.
final sessionsForBlockProvider =
    StreamProvider.family<List<Session>, String>((ref, pbId) {
  return ref.watch(practiceRepositoryProvider).watchSessionsByBlock(pbId);
});

/// Phase 4 — Stream of instances for a set.
final currentSetInstancesProvider =
    StreamProvider.family<List<Instance>, String>((ref, setId) {
  return ref.watch(practiceRepositoryProvider).watchInstancesBySet(setId);
});

/// Phase 4 — Coordinator for practice actions that bridge repository + timers.
/// Encapsulates timer lifecycle tied to practice state transitions.
class PracticeActions {
  final PracticeRepository _repo;
  final TimerService _timerService;
  final CompletionMatcher _completionMatcher;

  PracticeActions(this._repo, this._timerService, this._completionMatcher);

  /// S13 §13.2 — Start a new practice block with optional initial drills.
  Future<PracticeBlock> startPracticeBlock(
    String userId, {
    List<String>? initialDrillIds,
  }) async {
    final pb = await _repo.createPracticeBlock(
      userId,
      initialDrillIds: initialDrillIds,
    );

    // S13 §13.10.2 — Start 4-hour auto-end timer.
    _timerService.startPracticeBlockAutoEndTimer(
      pb.practiceBlockId,
      kPracticeBlockAutoEndTimeout,
      () => _autoEndPracticeBlock(pb.practiceBlockId, userId),
    );

    return pb;
  }

  /// S13 §13.5 — Start a session for a practice entry.
  Future<Session> startSession(String entryId, String userId) async {
    final session = await _repo.startSession(entryId, userId);

    // S13 §13.5.3 — Start 2-hour inactivity timer.
    _timerService.startSessionInactivityTimer(
      session.sessionId,
      kSessionInactivityTimeout,
      () => _autoCloseSession(session.sessionId, userId),
    );

    return session;
  }

  /// S13 §13.6 — Log an instance and reset inactivity timer.
  Future<Instance> logInstance(
    String setId,
    InstancesCompanion data,
    String sessionId,
  ) async {
    final instance = await _repo.logInstance(setId, data, sessionId);

    // S13 §13.5.3 — Reset inactivity timer on each new Instance.
    _timerService.resetSessionInactivityTimer(
      sessionId,
      kSessionInactivityTimeout,
    );

    return instance;
  }

  /// S13 §13.9 — End a session and cancel its timer.
  /// S08 §8.3.2 — After scoring, execute completion matching.
  Future<SessionScoringResult> endSession(
    String sessionId,
    String userId,
  ) async {
    // TD-04 §2.3.4 — Suspend timers during scoring lock.
    _timerService.suspendAll();
    try {
      final result = await _repo.endSession(sessionId, userId);
      _timerService.cancelSessionTimer(sessionId);

      // S08 §8.3.2 — Completion matching: auto-match to CalendarDay slots.
      await _completionMatcher.executeCompletionMatching(
        result.sessionId, result.drillId, userId, DateTime.now());

      return result;
    } finally {
      _timerService.resumeAll();
    }
  }

  /// S13 §13.10 — End a practice block, cancel all timers.
  Future<void> endPracticeBlock(String pbId, String userId) async {
    await _repo.endPracticeBlock(pbId, userId);
    _timerService.cancelBlockTimer(pbId);
    _timerService.cancelAll();
  }

  /// Discard a session and cancel its timer.
  Future<void> discardSession(String entryId, String sessionId) async {
    _timerService.cancelSessionTimer(sessionId);
    await _repo.discardSession(entryId);
  }

  // Auto-close callback: S13 §13.5.3 — 2h inactivity.
  Future<void> _autoCloseSession(String sessionId, String userId) async {
    // Check if session has instances; if not, discard.
    final session = await _repo.getSessionById(sessionId);
    if (session == null || session.status != SessionStatus.active) return;

    final currentSet = await _repo.getCurrentSet(sessionId);
    if (currentSet == null) return;

    final instanceCount = await _repo.getInstanceCount(currentSet.setId);
    final totalSets = await _repo.getSetCount(sessionId);

    // If no instances at all across any set, find the entry and discard.
    if (instanceCount == 0 && totalSets <= 1) {
      // Find entry for this session.
      final entry = await _findEntryForSession(sessionId);
      if (entry != null) {
        await _repo.discardSession(entry.practiceEntryId);
      }
    } else {
      await _repo.endSession(sessionId, userId);
    }
  }

  // Auto-end callback: S13 §13.10.2 — 4h practice block timeout.
  Future<void> _autoEndPracticeBlock(
      String pbId, String userId) async {
    // Discard any active session first.
    final activeSession = await _repo.getActiveSessionInBlock(pbId);
    if (activeSession != null) {
      final entry = await _findEntryForSession(activeSession.sessionId);
      if (entry != null) {
        final currentSet =
            await _repo.getCurrentSet(activeSession.sessionId);
        if (currentSet != null) {
          final count =
              await _repo.getInstanceCount(currentSet.setId);
          if (count > 0) {
            await _repo.endSession(activeSession.sessionId, userId);
          } else {
            await _repo.discardSession(entry.practiceEntryId);
          }
        }
      }
    }

    await _repo.endPracticeBlock(pbId, userId);
  }

  Future<PracticeEntry?> _findEntryForSession(String sessionId) async {
    // Use the DB to find the entry with this sessionId.
    return _repo.getPracticeEntryBySessionId(sessionId);
  }
}

/// Phase 4+5 — Provider for PracticeActions coordinator.
/// Injects CompletionMatcher for S08 §8.3.2 slot matching.
final practiceActionsProvider = Provider<PracticeActions>((ref) {
  return PracticeActions(
    ref.watch(practiceRepositoryProvider),
    ref.watch(timerServiceProvider),
    ref.watch(completionMatcherProvider),
  );
});
