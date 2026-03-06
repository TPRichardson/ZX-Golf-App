import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Phase M3 — MatrixRun DTO serialisation.

extension MatrixRunSyncDto on MatrixRun {
  Map<String, dynamic> toSyncDto() => {
        'MatrixRunID': matrixRunId,
        'UserID': userId,
        'MatrixType': matrixType.dbValue,
        'RunNumber': runNumber,
        'RunState': runState.dbValue,
        'StartTimestamp': startTimestamp.toUtc().toIso8601String(),
        'EndTimestamp': endTimestamp?.toUtc().toIso8601String(),
        'SessionShotTarget': sessionShotTarget,
        'ShotOrderMode': shotOrderMode.dbValue,
        'DispersionCaptureEnabled': dispersionCaptureEnabled,
        'MeasurementDevice': measurementDevice,
        'EnvironmentType': environmentType?.dbValue,
        'SurfaceType': surfaceType?.dbValue,
        'GreenSpeed': greenSpeed,
        'GreenFirmness': greenFirmness?.dbValue,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

MatrixRunsCompanion matrixRunFromSyncDto(Map<String, dynamic> json) =>
    MatrixRunsCompanion(
      matrixRunId: Value(json['MatrixRunID'] as String),
      userId: Value(json['UserID'] as String),
      matrixType:
          Value(MatrixType.fromString(json['MatrixType'] as String)),
      runNumber: Value(json['RunNumber'] as int),
      runState: Value(RunState.fromString(json['RunState'] as String)),
      startTimestamp:
          Value(DateTime.parse(json['StartTimestamp'] as String)),
      endTimestamp: Value(json['EndTimestamp'] != null
          ? DateTime.parse(json['EndTimestamp'] as String)
          : null),
      sessionShotTarget: Value(json['SessionShotTarget'] as int),
      shotOrderMode: Value(
          ShotOrderMode.fromString(json['ShotOrderMode'] as String)),
      dispersionCaptureEnabled:
          Value(json['DispersionCaptureEnabled'] as bool),
      measurementDevice: Value(json['MeasurementDevice'] as String?),
      environmentType: Value(json['EnvironmentType'] != null
          ? EnvironmentType.fromString(
              json['EnvironmentType'] as String)
          : null),
      surfaceType: Value(json['SurfaceType'] != null
          ? SurfaceType.fromString(json['SurfaceType'] as String)
          : null),
      greenSpeed: Value(json['GreenSpeed'] != null
          ? (json['GreenSpeed'] as num).toDouble()
          : null),
      greenFirmness: Value(json['GreenFirmness'] != null
          ? GreenFirmness.fromString(json['GreenFirmness'] as String)
          : null),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
