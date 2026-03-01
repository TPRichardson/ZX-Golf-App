import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/schedule_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('Schedule DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final schedule = makeSchedule();
      final json = schedule.toSyncDto();
      final companion = scheduleFromSyncDto(json);

      expect(companion.scheduleId.value, schedule.scheduleId);
      expect(companion.userId.value, schedule.userId);
      expect(companion.name.value, schedule.name);
      expect(companion.applicationMode.value, ScheduleAppMode.dayPlanning);
      expect(companion.status.value, ScheduleStatus.active);
      expect(companion.isDeleted.value, false);
    });

    test('Entries JSONB round-trips as array', () {
      final json = makeSchedule().toSyncDto();
      expect(json['Entries'], isA<List>());

      final companion = scheduleFromSyncDto(json);
      final decoded = jsonDecode(companion.entries.value);
      expect(decoded[0]['routineId'], 'r-001');
    });

    test('enum value serialises correctly', () {
      final json = makeSchedule().toSyncDto();
      expect(json['ApplicationMode'], 'DayPlanning');
      expect(json['Status'], 'Active');
    });
  });
}
