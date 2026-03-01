import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/schedule_instance_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('ScheduleInstance DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final si = makeScheduleInstance();
      final json = si.toSyncDto();
      final companion = scheduleInstanceFromSyncDto(json);

      expect(companion.scheduleInstanceId.value, si.scheduleInstanceId);
      expect(companion.scheduleId.value, si.scheduleId);
      expect(companion.userId.value, si.userId);
    });

    test('StartDate and EndDate serialise as date-only', () {
      final json = makeScheduleInstance().toSyncDto();
      expect(json['StartDate'], '2026-03-01');
      expect(json['EndDate'], '2026-03-07');
    });

    test('OwnedSlots JSONB round-trips as array', () {
      final json = makeScheduleInstance().toSyncDto();
      expect(json['OwnedSlots'], isA<List>());
      expect(json['OwnedSlots'], [2]);

      final companion = scheduleInstanceFromSyncDto(json);
      final decoded = jsonDecode(companion.ownedSlots.value);
      expect(decoded, [2]);
    });

    test('nullable ScheduleID handles null', () {
      final json = makeScheduleInstance().toSyncDto();
      json['ScheduleID'] = null;
      final companion = scheduleInstanceFromSyncDto(json);
      expect(companion.scheduleId.value, isNull);
    });
  });
}
