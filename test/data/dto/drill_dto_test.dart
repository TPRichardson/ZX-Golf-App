import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/drill_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('Drill DTO round-trip', () {
    test('full entity with all enums and JSONB', () {
      final drill = makeDrill();
      final json = drill.toSyncDto();
      final companion = drillFromSyncDto(json);

      expect(companion.drillId.value, drill.drillId);
      expect(companion.userId.value, drill.userId);
      expect(companion.name.value, drill.name);
      expect(companion.skillArea.value, drill.skillArea);
      expect(companion.drillType.value, drill.drillType);
      expect(companion.scoringMode.value, drill.scoringMode);
      expect(companion.inputMode.value, drill.inputMode);
      expect(companion.metricSchemaId.value, drill.metricSchemaId);
      expect(companion.gridType.value, drill.gridType);
      expect(companion.clubSelectionMode.value, drill.clubSelectionMode);
      expect(companion.targetDistanceMode.value, drill.targetDistanceMode);
      expect(companion.targetDistanceValue.value, drill.targetDistanceValue);
      expect(companion.targetSizeMode.value, drill.targetSizeMode);
      expect(companion.targetSizeWidth.value, drill.targetSizeWidth);
      expect(companion.targetSizeDepth.value, drill.targetSizeDepth);
      expect(companion.requiredSetCount.value, drill.requiredSetCount);
      expect(
          companion.requiredAttemptsPerSet.value, drill.requiredAttemptsPerSet);
      expect(companion.description.value, drill.description);
      expect(companion.targetDistanceUnit.value, drill.targetDistanceUnit);
      expect(companion.targetSizeUnit.value, drill.targetSizeUnit);
      expect(companion.origin.value, drill.origin);
      expect(companion.status.value, drill.status);
      expect(companion.isDeleted.value, drill.isDeleted);
    });

    test('SubskillMapping JSONB round-trips as array', () {
      final drill = makeDrill();
      final json = drill.toSyncDto();
      expect(json['SubskillMapping'], isA<List>());
      expect(json['SubskillMapping'][0], 'approach_direction_control');

      final companion = drillFromSyncDto(json);
      final decoded = jsonDecode(companion.subskillMapping.value);
      expect(decoded, ['approach_direction_control']);
    });

    test('Anchors JSONB round-trips as object', () {
      final drill = makeDrill();
      final json = drill.toSyncDto();
      expect(json['Anchors'], isA<Map>());

      final companion = drillFromSyncDto(json);
      final decoded = jsonDecode(companion.anchors.value);
      expect(decoded['approach_direction_control']['Min'], 30);
    });

    test('minimal drill with all nullable enums null', () {
      final drill = makeDrillMinimal();
      final json = drill.toSyncDto();

      expect(json['ScoringMode'], isNull);
      expect(json['GridType'], isNull);
      expect(json['ClubSelectionMode'], isNull);
      expect(json['TargetDistanceMode'], isNull);
      expect(json['TargetSizeMode'], isNull);
      expect(json['Description'], isNull);
      expect(json['TargetDistanceUnit'], isNull);
      expect(json['TargetSizeUnit'], isNull);
      expect(json['SubskillMapping'], isEmpty);
      expect(json['Anchors'], isEmpty);

      final companion = drillFromSyncDto(json);
      expect(companion.scoringMode.value, isNull);
      expect(companion.gridType.value, isNull);
      expect(companion.clubSelectionMode.value, isNull);
      expect(companion.targetDistanceMode.value, isNull);
      expect(companion.targetSizeMode.value, isNull);
      expect(companion.description.value, isNull);
      expect(companion.targetDistanceUnit.value, isNull);
      expect(companion.targetSizeUnit.value, isNull);
      expect(companion.subskillMapping.value, '[]');
      expect(companion.anchors.value, '{}');
    });

    test('enum values serialise to correct strings', () {
      final json = makeDrill().toSyncDto();
      expect(json['SkillArea'], 'Approach');
      expect(json['DrillType'], 'Transition');
      expect(json['InputMode'], 'GridCell');
      expect(json['Origin'], 'System');
      expect(json['Status'], 'Active');
    });
  });
}
