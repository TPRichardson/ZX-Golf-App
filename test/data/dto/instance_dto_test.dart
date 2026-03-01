import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/instance_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('Instance DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final instance = makeInstance();
      final json = instance.toSyncDto();
      final companion = instanceFromSyncDto(json);

      expect(companion.instanceId.value, instance.instanceId);
      expect(companion.setId.value, instance.setId);
      expect(companion.selectedClub.value, 'i7');
      expect(companion.timestamp.value, instance.timestamp);
      expect(companion.resolvedTargetDistance.value, 150.0);
      expect(companion.resolvedTargetWidth.value, 10.5);
      expect(companion.resolvedTargetDepth.value, isNull);
      expect(companion.isDeleted.value, false);
    });

    test('RawMetrics JSONB round-trips as object', () {
      final instance = makeInstance();
      final json = instance.toSyncDto();
      expect(json['RawMetrics'], isA<Map>());
      expect(json['RawMetrics']['cellIndex'], 1);

      final companion = instanceFromSyncDto(json);
      final decoded = jsonDecode(companion.rawMetrics.value);
      expect(decoded['cellIndex'], 1);
    });

    test('no UserID in output (child entity)', () {
      final json = makeInstance().toSyncDto();
      expect(json.containsKey('UserID'), isFalse);
    });

    test('SelectedClub is plain text, not enum', () {
      final json = makeInstance().toSyncDto();
      expect(json['SelectedClub'], 'i7');
    });
  });
}
