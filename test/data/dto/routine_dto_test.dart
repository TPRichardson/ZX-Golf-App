import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/routine_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('Routine DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final routine = makeRoutine();
      final json = routine.toSyncDto();
      final companion = routineFromSyncDto(json);

      expect(companion.routineId.value, routine.routineId);
      expect(companion.userId.value, routine.userId);
      expect(companion.name.value, routine.name);
      expect(companion.status.value, RoutineStatus.active);
      expect(companion.isDeleted.value, false);
    });

    test('Entries JSONB round-trips as array', () {
      final json = makeRoutine().toSyncDto();
      expect(json['Entries'], isA<List>());
      expect(json['Entries'][0]['drillId'], 'd-001');

      final companion = routineFromSyncDto(json);
      final decoded = jsonDecode(companion.entries.value);
      expect(decoded[0]['drillId'], 'd-001');
    });
  });
}
