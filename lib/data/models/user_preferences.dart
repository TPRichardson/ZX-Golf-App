import 'dart:convert';

import 'package:zx_golf_app/data/enums.dart';

// S10 §10.6–10.10 — User preferences model.
// Serialized to/from the Users.unitPreferences JSON column (TEXT, default '{}').

class UserPreferences {
  /// S10 §10.6 — Distance unit for display (yards or metres).
  final DistanceUnit distanceUnit;

  /// S10 §10.6 — Small length unit for display (inches or centimetres).
  final SmallLengthUnit smallLengthUnit;

  /// S10 §10.9 — Default analysis chart resolution.
  final String defaultAnalysisResolution;

  /// S10 §10.7 — Default ClubSelectionMode per SkillArea.
  final Map<SkillArea, ClubSelectionMode> defaultClubSelectionModes;

  /// S10 §10.8 — 7-day slot capacity pattern (Mon–Sun).
  final List<int> defaultSlotCapacityPattern;

  /// S10 §10.10 — Whether daily reminder notifications are enabled.
  final bool reminderEnabled;

  /// S10 §10.10 — Reminder time in HH:mm format.
  final String? reminderTime;

  /// Week start day: 1 = Monday (ISO 8601), 7 = Sunday.
  final int weekStartDay;

  const UserPreferences({
    this.distanceUnit = DistanceUnit.yards,
    this.smallLengthUnit = SmallLengthUnit.inches,
    this.defaultAnalysisResolution = 'weekly',
    this.defaultClubSelectionModes = const {},
    this.defaultSlotCapacityPattern = const [3, 3, 3, 3, 3, 0, 0],
    this.reminderEnabled = false,
    this.reminderTime,
    this.weekStartDay = 1,
  });

  factory UserPreferences.fromJson(String json) {
    if (json.isEmpty || json == '{}') return const UserPreferences();
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return UserPreferences(
        distanceUnit: map['distanceUnit'] != null
            ? DistanceUnit.fromString(map['distanceUnit'] as String)
            : DistanceUnit.yards,
        smallLengthUnit: map['smallLengthUnit'] != null
            ? SmallLengthUnit.fromString(map['smallLengthUnit'] as String)
            : SmallLengthUnit.inches,
        defaultAnalysisResolution:
            (map['defaultAnalysisResolution'] as String?) ?? 'weekly',
        defaultClubSelectionModes: _parseClubModes(
            map['defaultClubSelectionModes'] as Map<String, dynamic>?),
        defaultSlotCapacityPattern: _parseCapacityPattern(
            map['defaultSlotCapacityPattern'] as List<dynamic>?),
        reminderEnabled: (map['reminderEnabled'] as bool?) ?? false,
        reminderTime: map['reminderTime'] as String?,
        weekStartDay: (map['weekStartDay'] as num?)?.toInt() ?? 1,
      );
    } on FormatException {
      return const UserPreferences();
    }
  }

  String toJson() {
    final map = <String, dynamic>{
      'distanceUnit': distanceUnit.dbValue,
      'smallLengthUnit': smallLengthUnit.dbValue,
      'defaultAnalysisResolution': defaultAnalysisResolution,
      'defaultClubSelectionModes': defaultClubSelectionModes.map(
        (k, v) => MapEntry(k.dbValue, v.dbValue),
      ),
      'defaultSlotCapacityPattern': defaultSlotCapacityPattern,
      'reminderEnabled': reminderEnabled,
      if (reminderTime != null) 'reminderTime': reminderTime,
      'weekStartDay': weekStartDay,
    };
    return jsonEncode(map);
  }

  UserPreferences copyWith({
    DistanceUnit? distanceUnit,
    SmallLengthUnit? smallLengthUnit,
    String? defaultAnalysisResolution,
    Map<SkillArea, ClubSelectionMode>? defaultClubSelectionModes,
    List<int>? defaultSlotCapacityPattern,
    bool? reminderEnabled,
    String? reminderTime,
    int? weekStartDay,
  }) {
    return UserPreferences(
      distanceUnit: distanceUnit ?? this.distanceUnit,
      smallLengthUnit: smallLengthUnit ?? this.smallLengthUnit,
      defaultAnalysisResolution:
          defaultAnalysisResolution ?? this.defaultAnalysisResolution,
      defaultClubSelectionModes:
          defaultClubSelectionModes ?? this.defaultClubSelectionModes,
      defaultSlotCapacityPattern:
          defaultSlotCapacityPattern ?? this.defaultSlotCapacityPattern,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      weekStartDay: weekStartDay ?? this.weekStartDay,
    );
  }

  static Map<SkillArea, ClubSelectionMode> _parseClubModes(
      Map<String, dynamic>? raw) {
    if (raw == null) return {};
    final result = <SkillArea, ClubSelectionMode>{};
    for (final entry in raw.entries) {
      try {
        result[SkillArea.fromString(entry.key)] =
            ClubSelectionMode.fromString(entry.value as String);
      } on ArgumentError {
        // Skip invalid entries.
      }
    }
    return result;
  }

  static List<int> _parseCapacityPattern(List<dynamic>? raw) {
    if (raw == null || raw.length != 7) return const [3, 3, 3, 3, 3, 0, 0];
    return raw.map((e) => (e as num).toInt().clamp(0, 10)).toList();
  }
}
