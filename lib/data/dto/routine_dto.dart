import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — Routine DTO serialisation.

extension RoutineSyncDto on Routine {
  Map<String, dynamic> toSyncDto() => {
        'RoutineID': routineId,
        'UserID': userId,
        'Name': name,
        'Entries': jsonDecode(entries),
        'Status': status.dbValue,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

RoutinesCompanion routineFromSyncDto(Map<String, dynamic> json) =>
    RoutinesCompanion(
      routineId: Value(json['RoutineID'] as String),
      userId: Value(json['UserID'] as String),
      name: Value(json['Name'] as String),
      entries: Value(
        json['Entries'] is String
            ? json['Entries'] as String
            : jsonEncode(json['Entries']),
      ),
      status:
          Value(RoutineStatus.fromString(json['Status'] as String)),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
