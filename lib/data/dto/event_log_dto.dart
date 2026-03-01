import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — EventLog DTO serialisation.
// Append-only: no UpdatedAt column. Uses CreatedAt for sync window.

extension EventLogSyncDto on EventLog {
  Map<String, dynamic> toSyncDto() => {
        'EventLogID': eventLogId,
        'UserID': userId,
        'DeviceID': deviceId,
        'EventTypeID': eventTypeId,
        'Timestamp': timestamp.toUtc().toIso8601String(),
        'AffectedEntityIDs': affectedEntityIds != null
            ? jsonDecode(affectedEntityIds!)
            : null,
        'AffectedSubskills': affectedSubskills != null
            ? jsonDecode(affectedSubskills!)
            : null,
        'Metadata':
            metadata != null ? jsonDecode(metadata!) : null,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
      };
}

EventLogsCompanion eventLogFromSyncDto(Map<String, dynamic> json) =>
    EventLogsCompanion(
      eventLogId: Value(json['EventLogID'] as String),
      userId: Value(json['UserID'] as String),
      deviceId: Value(json['DeviceID'] as String?),
      eventTypeId: Value(json['EventTypeID'] as String),
      timestamp: Value(DateTime.parse(json['Timestamp'] as String)),
      affectedEntityIds: Value(json['AffectedEntityIDs'] != null
          ? (json['AffectedEntityIDs'] is String
              ? json['AffectedEntityIDs'] as String
              : jsonEncode(json['AffectedEntityIDs']))
          : null),
      affectedSubskills: Value(json['AffectedSubskills'] != null
          ? (json['AffectedSubskills'] is String
              ? json['AffectedSubskills'] as String
              : jsonEncode(json['AffectedSubskills']))
          : null),
      metadata: Value(json['Metadata'] != null
          ? (json['Metadata'] is String
              ? json['Metadata'] as String
              : jsonEncode(json['Metadata']))
          : null),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
    );
