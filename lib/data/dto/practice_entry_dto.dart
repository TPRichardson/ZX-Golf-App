import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — PracticeEntry DTO serialisation.

extension PracticeEntrySyncDto on PracticeEntry {
  Map<String, dynamic> toSyncDto() => {
        'PracticeEntryID': practiceEntryId,
        'PracticeBlockID': practiceBlockId,
        'DrillID': drillId,
        'SessionID': sessionId,
        'EntryType': entryType.dbValue,
        'PositionIndex': positionIndex,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

PracticeEntriesCompanion practiceEntryFromSyncDto(
        Map<String, dynamic> json) =>
    PracticeEntriesCompanion(
      practiceEntryId: Value(json['PracticeEntryID'] as String),
      practiceBlockId: Value(json['PracticeBlockID'] as String),
      drillId: Value(json['DrillID'] as String),
      sessionId: Value(json['SessionID'] as String?),
      entryType: Value(
          PracticeEntryType.fromString(json['EntryType'] as String)),
      positionIndex: Value(json['PositionIndex'] as int),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
