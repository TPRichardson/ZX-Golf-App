import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/user_skill_area_club_mapping_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('UserSkillAreaClubMapping DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final mapping = makeUserSkillAreaClubMapping();
      final json = mapping.toSyncDto();
      final companion = userSkillAreaClubMappingFromSyncDto(json);

      expect(companion.mappingId.value, mapping.mappingId);
      expect(companion.userId.value, mapping.userId);
      expect(companion.clubType.value, ClubType.i7);
      expect(companion.skillArea.value, SkillArea.approach);
      expect(companion.isMandatory.value, true);
    });

    test('enum values serialise to correct strings', () {
      final json = makeUserSkillAreaClubMapping().toSyncDto();
      expect(json['ClubType'], 'i7');
      expect(json['SkillArea'], 'Approach');
    });
  });
}
