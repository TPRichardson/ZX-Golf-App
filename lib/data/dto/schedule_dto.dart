import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — Schedule DTO serialisation.

extension ScheduleSyncDto on Schedule {
  Map<String, dynamic> toSyncDto() => {
        'ScheduleID': scheduleId,
        'UserID': userId,
        'Name': name,
        'ApplicationMode': applicationMode.dbValue,
        'Entries': jsonDecode(entries),
        'Status': status.dbValue,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

SchedulesCompanion scheduleFromSyncDto(Map<String, dynamic> json) =>
    SchedulesCompanion(
      scheduleId: Value(json['ScheduleID'] as String),
      userId: Value(json['UserID'] as String),
      name: Value(json['Name'] as String),
      applicationMode: Value(
          ScheduleAppMode.fromString(json['ApplicationMode'] as String)),
      entries: Value(
        json['Entries'] is String
            ? json['Entries'] as String
            : jsonEncode(json['Entries']),
      ),
      status: Value(
          ScheduleStatus.fromString(json['Status'] as String)),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
