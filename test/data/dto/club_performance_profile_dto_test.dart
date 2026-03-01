import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/club_performance_profile_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('ClubPerformanceProfile DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final profile = makeClubPerformanceProfile();
      final json = profile.toSyncDto();
      final companion = clubPerformanceProfileFromSyncDto(json);

      expect(companion.profileId.value, profile.profileId);
      expect(companion.clubId.value, profile.clubId);
      expect(companion.carryDistance.value, 165.0);
      expect(companion.dispersionLeft.value, 5.0);
      expect(companion.dispersionRight.value, 5.0);
      expect(companion.dispersionShort.value, 3.0);
      expect(companion.dispersionLong.value, 4.0);
    });

    test('EffectiveFromDate serialises as date-only string', () {
      final json = makeClubPerformanceProfile().toSyncDto();
      expect(json['EffectiveFromDate'], '2026-01-15');
    });

    test('EffectiveFromDate parses date-only string back', () {
      final json = makeClubPerformanceProfile().toSyncDto();
      final companion = clubPerformanceProfileFromSyncDto(json);
      expect(companion.effectiveFromDate.value.year, 2026);
      expect(companion.effectiveFromDate.value.month, 1);
      expect(companion.effectiveFromDate.value.day, 15);
    });

    test('nullable dispersion fields handle null', () {
      final json = makeClubPerformanceProfile().toSyncDto();
      json['CarryDistance'] = null;
      json['DispersionLeft'] = null;
      json['DispersionRight'] = null;
      json['DispersionShort'] = null;
      json['DispersionLong'] = null;
      final companion = clubPerformanceProfileFromSyncDto(json);
      expect(companion.carryDistance.value, isNull);
      expect(companion.dispersionLeft.value, isNull);
    });
  });
}
