import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — Session DTO serialisation. No UserID (child entity).

extension SessionSyncDto on Session {
  Map<String, dynamic> toSyncDto() => {
        'SessionID': sessionId,
        'DrillID': drillId,
        'PracticeBlockID': practiceBlockId,
        'CompletionTimestamp':
            completionTimestamp?.toUtc().toIso8601String(),
        'Status': status.dbValue,
        'IntegrityFlag': integrityFlag,
        'IntegritySuppressed': integritySuppressed,
        'EnvironmentType': environmentType?.dbValue,
        'SurfaceType': surfaceType?.dbValue,
        'UserDeclaration': userDeclaration,
        'SessionDuration': sessionDuration,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

SessionsCompanion sessionFromSyncDto(Map<String, dynamic> json) =>
    SessionsCompanion(
      sessionId: Value(json['SessionID'] as String),
      drillId: Value(json['DrillID'] as String),
      practiceBlockId: Value(json['PracticeBlockID'] as String),
      completionTimestamp: Value(json['CompletionTimestamp'] != null
          ? DateTime.parse(json['CompletionTimestamp'] as String)
          : null),
      status:
          Value(SessionStatus.fromString(json['Status'] as String)),
      integrityFlag: Value(json['IntegrityFlag'] as bool),
      integritySuppressed: Value(json['IntegritySuppressed'] as bool),
      environmentType: Value(json['EnvironmentType'] != null
          ? EnvironmentType.fromString(json['EnvironmentType'] as String)
          : null),
      surfaceType: Value(json['SurfaceType'] != null
          ? SurfaceType.fromString(json['SurfaceType'] as String)
          : null),
      userDeclaration: Value(json['UserDeclaration'] as String?),
      sessionDuration: Value(json['SessionDuration'] as int?),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
