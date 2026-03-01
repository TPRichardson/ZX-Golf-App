import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — RoutineInstance DTO serialisation.

extension RoutineInstanceSyncDto on RoutineInstance {
  Map<String, dynamic> toSyncDto() => {
        'RoutineInstanceID': routineInstanceId,
        'RoutineID': routineId,
        'UserID': userId,
        'CalendarDayDate':
            calendarDayDate.toIso8601String().split('T')[0],
        'OwnedSlots': jsonDecode(ownedSlots),
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

RoutineInstancesCompanion routineInstanceFromSyncDto(
        Map<String, dynamic> json) =>
    RoutineInstancesCompanion(
      routineInstanceId: Value(json['RoutineInstanceID'] as String),
      routineId: Value(json['RoutineID'] as String?),
      userId: Value(json['UserID'] as String),
      calendarDayDate:
          Value(DateTime.parse(json['CalendarDayDate'] as String)),
      ownedSlots: Value(
        json['OwnedSlots'] is String
            ? json['OwnedSlots'] as String
            : jsonEncode(json['OwnedSlots']),
      ),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
