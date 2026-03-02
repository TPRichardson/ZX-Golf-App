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
      expect(prefs.defaultSlotCapacityPattern, [3, 3, 3, 3, 3, 0, 0]);
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
        defaultSlotCapacityPattern: [5, 5, 5, 5, 5, 2, 2],
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
      expect(restored.defaultSlotCapacityPattern, [5, 5, 5, 5, 5, 2, 2]);
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

    test('slot capacity pattern clamped to 0-10', () {
      final json = jsonEncode({
        'defaultSlotCapacityPattern': [15, -3, 5, 5, 5, 5, 5],
      });
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.defaultSlotCapacityPattern[0], 10);
      expect(prefs.defaultSlotCapacityPattern[1], 0);
    });

    test('invalid slot capacity pattern length returns default', () {
      final json = jsonEncode({
        'defaultSlotCapacityPattern': [1, 2, 3],
      });
      final prefs = UserPreferences.fromJson(json);
      expect(prefs.defaultSlotCapacityPattern, [3, 3, 3, 3, 3, 0, 0]);
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
