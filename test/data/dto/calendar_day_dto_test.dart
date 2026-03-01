import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/calendar_day_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('CalendarDay DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final day = makeCalendarDay();
      final json = day.toSyncDto();
      final companion = calendarDayFromSyncDto(json);

      expect(companion.calendarDayId.value, day.calendarDayId);
      expect(companion.userId.value, day.userId);
      expect(companion.slotCapacity.value, 3);
    });

    test('Date serialises as date-only string', () {
      final json = makeCalendarDay().toSyncDto();
      expect(json['Date'], '2026-03-01');
    });

    test('Date parses date-only string back', () {
      final json = makeCalendarDay().toSyncDto();
      final companion = calendarDayFromSyncDto(json);
      expect(companion.date.value.year, 2026);
      expect(companion.date.value.month, 3);
      expect(companion.date.value.day, 1);
    });

    test('Slots JSONB round-trips as array', () {
      final json = makeCalendarDay().toSyncDto();
      expect(json['Slots'], isA<List>());

      final companion = calendarDayFromSyncDto(json);
      final decoded = jsonDecode(companion.slots.value);
      expect(decoded[0]['ownerType'], 'Manual');
    });
  });
}
