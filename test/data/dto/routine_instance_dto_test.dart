import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/routine_instance_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('RoutineInstance DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final ri = makeRoutineInstance();
      final json = ri.toSyncDto();
      final companion = routineInstanceFromSyncDto(json);

      expect(companion.routineInstanceId.value, ri.routineInstanceId);
      expect(companion.routineId.value, ri.routineId);
      expect(companion.userId.value, ri.userId);
    });

    test('CalendarDayDate serialises as date-only', () {
      final json = makeRoutineInstance().toSyncDto();
      expect(json['CalendarDayDate'], '2026-03-01');
    });

    test('OwnedSlots JSONB round-trips as array', () {
      final json = makeRoutineInstance().toSyncDto();
      expect(json['OwnedSlots'], isA<List>());
      expect(json['OwnedSlots'], [0, 1]);

      final companion = routineInstanceFromSyncDto(json);
      final decoded = jsonDecode(companion.ownedSlots.value);
      expect(decoded, [0, 1]);
    });

    test('nullable RoutineID handles null', () {
      final json = makeRoutineInstance().toSyncDto();
      json['RoutineID'] = null;
      final companion = routineInstanceFromSyncDto(json);
      expect(companion.routineId.value, isNull);
    });
  });
}
