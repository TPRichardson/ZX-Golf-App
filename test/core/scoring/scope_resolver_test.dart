import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/scoring/reflow_types.dart';
import 'package:zx_golf_app/core/scoring/scope_resolver.dart';

// Phase 2B — ScopeResolver tests.

void main() {
  const userId = 'test-user';

  group('fromSessionClose', () {
    test('single-mapped drill produces 1 subskill', () {
      final trigger = ScopeResolver.fromSessionClose(
        userId: userId,
        sessionId: 'session-1',
        drillId: 'drill-1',
        subskillMappingJson: '["irons_distance_control"]',
      );
      expect(trigger.type, ReflowTriggerType.sessionClose);
      expect(trigger.userId, userId);
      expect(trigger.affectedSubskillIds, {'irons_distance_control'});
      expect(trigger.sessionId, 'session-1');
      expect(trigger.drillId, 'drill-1');
    });

    test('dual-mapped drill produces 2 subskills', () {
      final trigger = ScopeResolver.fromSessionClose(
        userId: userId,
        sessionId: 'session-2',
        drillId: 'drill-2',
        subskillMappingJson:
            '["irons_distance_control", "irons_direction_control"]',
      );
      expect(trigger.affectedSubskillIds, {
        'irons_distance_control',
        'irons_direction_control',
      });
    });

    test('empty mapping produces empty set', () {
      final trigger = ScopeResolver.fromSessionClose(
        userId: userId,
        sessionId: 'session-3',
        drillId: 'drill-3',
        subskillMappingJson: '[]',
      );
      expect(trigger.affectedSubskillIds, isEmpty);
    });
  });

  group('fromAnchorEdit', () {
    test('produces correct trigger type and subskills', () {
      final trigger = ScopeResolver.fromAnchorEdit(
        userId: userId,
        drillId: 'drill-1',
        subskillMappingJson: '["driving_direction_control"]',
      );
      expect(trigger.type, ReflowTriggerType.anchorEdit);
      expect(trigger.affectedSubskillIds, {'driving_direction_control'});
      expect(trigger.drillId, 'drill-1');
    });
  });

  group('fromInstanceEdit', () {
    test('produces correct trigger type', () {
      final trigger = ScopeResolver.fromInstanceEdit(
        userId: userId,
        drillId: 'drill-1',
        subskillMappingJson: '["irons_distance_control"]',
      );
      expect(trigger.type, ReflowTriggerType.instanceEdit);
    });
  });

  group('fromInstanceDeletion', () {
    test('produces correct trigger type', () {
      final trigger = ScopeResolver.fromInstanceDeletion(
        userId: userId,
        drillId: 'drill-1',
        subskillMappingJson: '["irons_distance_control"]',
      );
      expect(trigger.type, ReflowTriggerType.instanceDeletion);
    });
  });

  group('fromSessionDeletion', () {
    test('produces correct trigger type', () {
      final trigger = ScopeResolver.fromSessionDeletion(
        userId: userId,
        drillId: 'drill-1',
        subskillMappingJson: '["putting_direction_control"]',
      );
      expect(trigger.type, ReflowTriggerType.sessionDeletion);
      expect(trigger.affectedSubskillIds, {'putting_direction_control'});
    });
  });

  group('fromAllocationChange', () {
    test('includes all subskills in skill area', () {
      final trigger = ScopeResolver.fromAllocationChange(
        userId: userId,
        subskillIdsInArea: {
          'irons_distance_control',
          'irons_direction_control',
          'irons_shape_control',
        },
      );
      expect(trigger.type, ReflowTriggerType.allocationChange);
      expect(trigger.affectedSubskillIds, hasLength(3));
    });
  });

  group('forFullRebuild', () {
    test('includes all 19 subskills', () {
      final allIds = {
        'irons_distance_control',
        'irons_direction_control',
        'irons_shape_control',
        'driving_distance_maximum',
        'driving_direction_control',
        'driving_shape_control',
        'putting_distance_control',
        'putting_direction_control',
        'pitching_distance_control',
        'pitching_direction_control',
        'pitching_flight_control',
        'chipping_distance_control',
        'chipping_direction_control',
        'chipping_flight_control',
        'woods_distance_control',
        'woods_direction_control',
        'woods_shape_control',
        'bunkers_distance_control',
        'bunkers_direction_control',
      };
      final trigger = ScopeResolver.forFullRebuild(
        userId: userId,
        allSubskillIds: allIds,
      );
      expect(trigger.type, ReflowTriggerType.fullRebuild);
      expect(trigger.affectedSubskillIds, hasLength(19));
    });
  });
}
