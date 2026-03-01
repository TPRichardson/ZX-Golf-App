import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/user_drill_adoption_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('UserDrillAdoption DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final adoption = makeUserDrillAdoption();
      final json = adoption.toSyncDto();
      final companion = userDrillAdoptionFromSyncDto(json);

      expect(companion.userDrillAdoptionId.value, adoption.userDrillAdoptionId);
      expect(companion.userId.value, adoption.userId);
      expect(companion.drillId.value, adoption.drillId);
      expect(companion.status.value, AdoptionStatus.active);
      expect(companion.isDeleted.value, false);
    });
  });
}
