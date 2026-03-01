import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — UserDrillAdoption DTO serialisation.

extension UserDrillAdoptionSyncDto on UserDrillAdoption {
  Map<String, dynamic> toSyncDto() => {
        'UserDrillAdoptionID': userDrillAdoptionId,
        'UserID': userId,
        'DrillID': drillId,
        'Status': status.dbValue,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

UserDrillAdoptionsCompanion userDrillAdoptionFromSyncDto(
        Map<String, dynamic> json) =>
    UserDrillAdoptionsCompanion(
      userDrillAdoptionId: Value(json['UserDrillAdoptionID'] as String),
      userId: Value(json['UserID'] as String),
      drillId: Value(json['DrillID'] as String),
      status:
          Value(AdoptionStatus.fromString(json['Status'] as String)),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
