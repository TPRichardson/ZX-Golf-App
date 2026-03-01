import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — ScheduleInstance DTO serialisation.

extension ScheduleInstanceSyncDto on ScheduleInstance {
  Map<String, dynamic> toSyncDto() => {
        'ScheduleInstanceID': scheduleInstanceId,
        'ScheduleID': scheduleId,
        'UserID': userId,
        'StartDate': startDate.toIso8601String().split('T')[0],
        'EndDate': endDate.toIso8601String().split('T')[0],
        'OwnedSlots': jsonDecode(ownedSlots),
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

ScheduleInstancesCompanion scheduleInstanceFromSyncDto(
        Map<String, dynamic> json) =>
    ScheduleInstancesCompanion(
      scheduleInstanceId: Value(json['ScheduleInstanceID'] as String),
      scheduleId: Value(json['ScheduleID'] as String?),
      userId: Value(json['UserID'] as String),
      startDate: Value(DateTime.parse(json['StartDate'] as String)),
      endDate: Value(DateTime.parse(json['EndDate'] as String)),
      ownedSlots: Value(
        json['OwnedSlots'] is String
            ? json['OwnedSlots'] as String
            : jsonEncode(json['OwnedSlots']),
      ),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
