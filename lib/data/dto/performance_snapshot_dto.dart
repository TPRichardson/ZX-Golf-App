import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Phase M3 — PerformanceSnapshot DTO serialisation.

extension PerformanceSnapshotSyncDto on PerformanceSnapshot {
  Map<String, dynamic> toSyncDto() => {
        'SnapshotID': snapshotId,
        'UserID': userId,
        'MatrixRunID': matrixRunId,
        'MatrixType': matrixType?.dbValue,
        'IsPrimary': isPrimary,
        'Label': label,
        'SnapshotTimestamp':
            snapshotTimestamp.toUtc().toIso8601String(),
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

PerformanceSnapshotsCompanion performanceSnapshotFromSyncDto(
        Map<String, dynamic> json) =>
    PerformanceSnapshotsCompanion(
      snapshotId: Value(json['SnapshotID'] as String),
      userId: Value(json['UserID'] as String),
      matrixRunId: Value(json['MatrixRunID'] as String?),
      matrixType: Value(json['MatrixType'] != null
          ? MatrixType.fromString(json['MatrixType'] as String)
          : null),
      isPrimary: Value(json['IsPrimary'] as bool),
      label: Value(json['Label'] as String?),
      snapshotTimestamp:
          Value(DateTime.parse(json['SnapshotTimestamp'] as String)),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
