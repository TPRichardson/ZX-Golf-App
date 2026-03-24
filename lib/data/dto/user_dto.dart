import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — User DTO serialisation.

extension UserSyncDto on User {
  Map<String, dynamic> toSyncDto() => {
        'UserID': userId,
        'DisplayName': displayName,
        'Email': email,
        'Timezone': timezone,
        'WeekStartDay': weekStartDay,
        'UnitPreferences': jsonDecode(unitPreferences),
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

UsersCompanion userFromSyncDto(Map<String, dynamic> json) => UsersCompanion(
      userId: Value(json['UserID'] as String),
      displayName: Value(json['DisplayName'] as String?),
      email: Value(json['Email'] as String),
      timezone: Value(json['Timezone'] as String),
      weekStartDay: Value(json['WeekStartDay'] as int),
      unitPreferences: Value(
        json['UnitPreferences'] is String
            ? json['UnitPreferences'] as String
            : jsonEncode(json['UnitPreferences']),
      ),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
