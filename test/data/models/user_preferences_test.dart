import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/models/user_preferences.dart';

// Phase 8 — UserPreferences model tests.

void main() {
  group('UserPreferences', () {
    test('default constructor has correct defaults', () {
      const prefs = UserPreferences();
      expect(prefs.distanceUnit, DistanceUnit.yards);
      expect(prefs.smallLengthUnit, SmallLengthUnit.inches);
      expect(prefs.defaultAnalysisResolution, 'weekly');
      expect(prefs.defaultClubSelectionModes, isEmpty);
      expect(prefs.reminderEnabled, false);
      expect(prefs.reminderTime, isNull);
    });

    test('fromJson with empty string returns defaults', () {
      final prefs = UserPreferences.fromJson('');
      expect(prefs.distanceUnit, DistanceUnit.yards);
      expect(prefs.smallLengthUnit, SmallLengthUnit.inches);
    });

    test('fromJson with empty object returns defaults', () {
      final prefs = UserPreferences.fromJson('{}');
      expect(prefs.distanceUnit, DistanceUnit.yards);
      expect(prefs.reminderEnabled, false);
    });

    test('fromJson with invalid JSON returns defaults', () {
      final prefs = UserPreferences.fromJson('not-valid-json');
      expect(prefs.distanceUnit, DistanceUnit.yards);
    });

    test('JSON round-trip preserves all fields', () {
      final original = UserPreferences(
        distanceUnit: DistanceUnit.metres,
        smallLengthUnit: SmallLengthUnit.centimetres,
        defaultAnalysisResolution: 'daily',
        defaultClubSelectionModes: {
          SkillArea.driving: ClubSelectionMode.guided,
          SkillArea.putting: ClubSelectionMode.userLed,
        },
        reminderEnabled: true,
        reminderTime: '09:30',
      );

      final json = original.toJson();
      final restored = UserPreferences.fromJson(json);

      expect(restored.distanceUnit, DistanceUnit.metres);
      expect(restored.smallLengthUnit, SmallLengthUnit.centimetres);
      expect(restored.defaultAnalysisResolution, 'daily');
      expect(restored.defaultClubSelectionModes[SkillArea.driving],
          ClubSelectionMode.guided);
      expect(restored.defaultClubSelectionModes[SkillArea.putting],
          ClubSelectionMode.userLed);
      expect(restored.reminderEnabled, true);
      expect(restored.reminderTime, '09:30');
    });

    test('toJson produces valid JSON string', () {
      const prefs = UserPreferences();
      final json = prefs.toJson();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['distanceUnit'], 'Yards');
      expect(decoded['smallLengthUnit'], 'Inches');
      expect(decoded['defaultAnalysisResolution'], 'weekly');
      expect(decoded['reminderEnabled'], false);
      expect(decoded.containsKey('reminderTime'), false);
    });

    test('copyWith replaces specified fields only', () {
      const original = UserPreferences();
      final modified = original.copyWith(
        distanceUnit: DistanceUnit.metres,
        reminderEnabled: true,
      );

      expect(modified.distanceUnit, DistanceUnit.metres);
      expect(modified.reminderEnabled, true);
      // Unchanged fields preserved.
      expect(modified.smallLengthUnit, SmallLengthUnit.inches);
      expect(modified.defaultAnalysisResolution, 'weekly');
    });

    test('fromJson with partial data fills defaults for missing fields', () {
      final json = jsonEncode({'distanceUnit': 'Metres'});
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.distanceUnit, DistanceUnit.metres);
      expect(prefs.smallLengthUnit, SmallLengthUnit.inches);
      expect(prefs.defaultAnalysisResolution, 'weekly');
    });

    test('invalid club selection mode entries are skipped', () {
      final json = jsonEncode({
        'defaultClubSelectionModes': {
          'Driving': 'Guided',
          'InvalidArea': 'Random',
        },
      });
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.defaultClubSelectionModes.length, 1);
      expect(prefs.defaultClubSelectionModes[SkillArea.driving],
          ClubSelectionMode.guided);
    });
  });
}
