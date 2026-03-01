import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/dto/user_dto.dart';
import '../../fixtures/dto_fixtures.dart';

void main() {
  group('User DTO round-trip', () {
    test('full entity serialises and deserialises correctly', () {
      final user = makeUser();
      final json = user.toSyncDto();
      final companion = userFromSyncDto(json);

      expect(companion.userId.value, user.userId);
      expect(companion.displayName.value, user.displayName);
      expect(companion.email.value, user.email);
      expect(companion.timezone.value, user.timezone);
      expect(companion.weekStartDay.value, user.weekStartDay);
      expect(companion.createdAt.value, user.createdAt);
      expect(companion.updatedAt.value, user.updatedAt);
    });

    test('UnitPreferences JSONB round-trips as object', () {
      final user = makeUser();
      final json = user.toSyncDto();
      expect(json['UnitPreferences'], isA<Map>());
      expect(json['UnitPreferences']['distance'], 'yards');

      final companion = userFromSyncDto(json);
      final decoded = jsonDecode(companion.unitPreferences.value);
      expect(decoded['distance'], 'yards');
    });

    test('empty UnitPreferences round-trips', () {
      final user = makeUser();
      final json = user.toSyncDto();
      json['UnitPreferences'] = {};
      final companion = userFromSyncDto(json);
      expect(companion.unitPreferences.value, '{}');
    });

    test('nullable fields handle null', () {
      final json = makeUser().toSyncDto();
      json['DisplayName'] = null;
      json['Email'] = null;
      final companion = userFromSyncDto(json);
      expect(companion.displayName.value, isNull);
      expect(companion.email.value, isNull);
    });
  });
}
