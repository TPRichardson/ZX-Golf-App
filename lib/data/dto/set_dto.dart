import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — Set DTO serialisation.
// DEVIATION: Extension on PracticeSet (renamed from Set). Upload key = 'Set'.
// See CLAUDE.md Known Deviations.

extension PracticeSetSyncDto on PracticeSet {
  Map<String, dynamic> toSyncDto() => {
        'SetID': setId,
        'SessionID': sessionId,
        'SetIndex': setIndex,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

SetsCompanion practiceSetFromSyncDto(Map<String, dynamic> json) =>
    SetsCompanion(
      setId: Value(json['SetID'] as String),
      sessionId: Value(json['SessionID'] as String),
      setIndex: Value(json['SetIndex'] as int),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
