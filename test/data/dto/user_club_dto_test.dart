import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/user_club_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('UserClub DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final club = makeUserClub();
      final json = club.toSyncDto();
      final companion = userClubFromSyncDto(json);

      expect(companion.clubId.value, club.clubId);
      expect(companion.userId.value, club.userId);
      expect(companion.clubType.value, ClubType.i7);
      expect(companion.make.value, 'Titleist');
      expect(companion.model.value, 'T200');
      expect(companion.loft.value, 34.0);
      expect(companion.status.value, UserClubStatus.active);
    });

    test('nullable fields handle null', () {
      final json = makeUserClub().toSyncDto();
      json['Make'] = null;
      json['Model'] = null;
      json['Loft'] = null;
      final companion = userClubFromSyncDto(json);
      expect(companion.make.value, isNull);
      expect(companion.model.value, isNull);
      expect(companion.loft.value, isNull);
    });
  });
}
