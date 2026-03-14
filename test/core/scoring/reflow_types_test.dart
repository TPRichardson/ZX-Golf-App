import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';

// Phase 2B — Reflow types tests.

void main() {
  group('ReflowTriggerType', () {
    test('has all expected values', () {
      expect(ReflowTriggerType.values, hasLength(7));
      expect(ReflowTriggerType.values, contains(ReflowTriggerType.sessionClose));
      expect(ReflowTriggerType.values, contains(ReflowTriggerType.anchorEdit));
      expect(ReflowTriggerType.values, contains(ReflowTriggerType.instanceEdit));
      expect(
          ReflowTriggerType.values, contains(ReflowTriggerType.instanceDeletion));
      expect(
          ReflowTriggerType.values, contains(ReflowTriggerType.sessionDeletion));
      expect(ReflowTriggerType.values,
          contains(ReflowTriggerType.allocationChange));
      expect(ReflowTriggerType.values, contains(ReflowTriggerType.fullRebuild));
    });
  });

  group('ReflowTrigger', () {
    test('constructs with required fields', () {
      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: 'user-1',
        affectedSubskillIds: {'approach_distance_control'},
      );
      expect(trigger.type, ReflowTriggerType.sessionClose);
      expect(trigger.userId, 'user-1');
      expect(trigger.affectedSubskillIds, {'approach_distance_control'});
      expect(trigger.sessionId, isNull);
      expect(trigger.drillId, isNull);
    });

    test('constructs with optional fields', () {
      final trigger = ReflowTrigger(
        type: ReflowTriggerType.sessionClose,
        userId: 'user-1',
        affectedSubskillIds: {'approach_distance_control'},
        sessionId: 'session-1',
        drillId: 'drill-1',
      );
      expect(trigger.sessionId, 'session-1');
      expect(trigger.drillId, 'drill-1');
    });

    group('mergeWith', () {
      test('unions affectedSubskillIds', () {
        final a = ReflowTrigger(
          type: ReflowTriggerType.sessionClose,
          userId: 'user-1',
          affectedSubskillIds: {'approach_distance_control'},
        );
        final b = ReflowTrigger(
          type: ReflowTriggerType.anchorEdit,
          userId: 'user-1',
          affectedSubskillIds: {'approach_direction_control', 'approach_shape_control'},
        );
        final merged = a.mergeWith(b);
        expect(merged.affectedSubskillIds, {
          'approach_distance_control',
          'approach_direction_control',
          'approach_shape_control',
        });
        expect(merged.userId, 'user-1');
      });

      test('fullRebuild wins when first trigger is fullRebuild', () {
        final a = ReflowTrigger(
          type: ReflowTriggerType.fullRebuild,
          userId: 'user-1',
          affectedSubskillIds: {'a'},
        );
        final b = ReflowTrigger(
          type: ReflowTriggerType.sessionClose,
          userId: 'user-1',
          affectedSubskillIds: {'b'},
        );
        expect(a.mergeWith(b).type, ReflowTriggerType.fullRebuild);
      });

      test('fullRebuild wins when second trigger is fullRebuild', () {
        final a = ReflowTrigger(
          type: ReflowTriggerType.sessionClose,
          userId: 'user-1',
          affectedSubskillIds: {'a'},
        );
        final b = ReflowTrigger(
          type: ReflowTriggerType.fullRebuild,
          userId: 'user-1',
          affectedSubskillIds: {'b'},
        );
        expect(a.mergeWith(b).type, ReflowTriggerType.fullRebuild);
      });

      test('preserves first type when neither is fullRebuild', () {
        final a = ReflowTrigger(
          type: ReflowTriggerType.anchorEdit,
          userId: 'user-1',
          affectedSubskillIds: {'a'},
        );
        final b = ReflowTrigger(
          type: ReflowTriggerType.sessionClose,
          userId: 'user-1',
          affectedSubskillIds: {'b'},
        );
        expect(a.mergeWith(b).type, ReflowTriggerType.anchorEdit);
      });

      test('coalesces 3 triggers correctly', () {
        final triggers = [
          ReflowTrigger(
            type: ReflowTriggerType.sessionClose,
            userId: 'user-1',
            affectedSubskillIds: {'a'},
          ),
          ReflowTrigger(
            type: ReflowTriggerType.anchorEdit,
            userId: 'user-1',
            affectedSubskillIds: {'b'},
          ),
          ReflowTrigger(
            type: ReflowTriggerType.instanceDeletion,
            userId: 'user-1',
            affectedSubskillIds: {'c'},
          ),
        ];
        final merged = triggers.reduce((acc, t) => acc.mergeWith(t));
        expect(merged.affectedSubskillIds, {'a', 'b', 'c'});
      });
    });
  });

  group('ReflowResult', () {
    test('successful result has all fields', () {
      final result = ReflowResult(
        success: true,
        elapsed: Duration(milliseconds: 50),
        subskillsRebuilt: 2,
        windowEntriesProcessed: 10,
        newOverallScore: 450.0,
      );
      expect(result.success, isTrue);
      expect(result.elapsed.inMilliseconds, 50);
      expect(result.subskillsRebuilt, 2);
      expect(result.windowEntriesProcessed, 10);
      expect(result.newOverallScore, 450.0);
      expect(result.errorCode, isNull);
    });

    test('failure result has error code', () {
      final result = ReflowResult.failure(
        elapsed: Duration(milliseconds: 100),
        errorCode: 'REFLOW_LOCK_TIMEOUT',
      );
      expect(result.success, isFalse);
      expect(result.subskillsRebuilt, 0);
      expect(result.windowEntriesProcessed, 0);
      expect(result.newOverallScore, isNull);
      expect(result.errorCode, 'REFLOW_LOCK_TIMEOUT');
    });
  });

  group('SessionScoringResult', () {
    test('constructs with all fields', () {
      final result = SessionScoringResult(
        sessionId: 'session-1',
        drillId: 'drill-1',
        sessionScore: 3.5,
        integrityBreach: false,
        subskillIds: {'approach_distance_control'},
        drillType: 'Transition',
        isDualMapped: false,
      );
      expect(result.sessionId, 'session-1');
      expect(result.drillId, 'drill-1');
      expect(result.sessionScore, 3.5);
      expect(result.integrityBreach, isFalse);
      expect(result.subskillIds, {'approach_distance_control'});
      expect(result.drillType, 'Transition');
      expect(result.isDualMapped, isFalse);
    });

    test('dual-mapped session has two subskillIds', () {
      final result = SessionScoringResult(
        sessionId: 'session-2',
        drillId: 'drill-2',
        sessionScore: 2.0,
        integrityBreach: true,
        subskillIds: {'approach_distance_control', 'approach_direction_control'},
        drillType: 'Pressure',
        isDualMapped: true,
      );
      expect(result.isDualMapped, isTrue);
      expect(result.subskillIds, hasLength(2));
    });
  });
}
