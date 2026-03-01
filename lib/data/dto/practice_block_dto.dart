import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — PracticeBlock DTO serialisation.

extension PracticeBlockSyncDto on PracticeBlock {
  Map<String, dynamic> toSyncDto() => {
        'PracticeBlockID': practiceBlockId,
        'UserID': userId,
        'SourceRoutineID': sourceRoutineId,
        'DrillOrder': jsonDecode(drillOrder),
        'StartTimestamp': startTimestamp.toUtc().toIso8601String(),
        'EndTimestamp': endTimestamp?.toUtc().toIso8601String(),
        'ClosureType': closureType?.dbValue,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

PracticeBlocksCompanion practiceBlockFromSyncDto(Map<String, dynamic> json) =>
    PracticeBlocksCompanion(
      practiceBlockId: Value(json['PracticeBlockID'] as String),
      userId: Value(json['UserID'] as String),
      sourceRoutineId: Value(json['SourceRoutineID'] as String?),
      drillOrder: Value(
        json['DrillOrder'] is String
            ? json['DrillOrder'] as String
            : jsonEncode(json['DrillOrder']),
      ),
      startTimestamp: Value(DateTime.parse(json['StartTimestamp'] as String)),
      endTimestamp: Value(json['EndTimestamp'] != null
          ? DateTime.parse(json['EndTimestamp'] as String)
          : null),
      closureType: Value(json['ClosureType'] != null
          ? ClosureType.fromString(json['ClosureType'] as String)
          : null),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
