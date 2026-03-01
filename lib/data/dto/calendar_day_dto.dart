import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — CalendarDay DTO serialisation. Date → date-only.

extension CalendarDaySyncDto on CalendarDay {
  Map<String, dynamic> toSyncDto() => {
        'CalendarDayID': calendarDayId,
        'UserID': userId,
        'Date': date.toIso8601String().split('T')[0],
        'SlotCapacity': slotCapacity,
        'Slots': jsonDecode(slots),
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

CalendarDaysCompanion calendarDayFromSyncDto(Map<String, dynamic> json) =>
    CalendarDaysCompanion(
      calendarDayId: Value(json['CalendarDayID'] as String),
      userId: Value(json['UserID'] as String),
      date: Value(DateTime.parse(json['Date'] as String)),
      slotCapacity: Value(json['SlotCapacity'] as int),
      slots: Value(
        json['Slots'] is String
            ? json['Slots'] as String
            : jsonEncode(json['Slots']),
      ),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
