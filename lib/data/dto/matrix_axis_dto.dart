import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Phase M3 — MatrixAxis DTO serialisation.

extension MatrixAxisSyncDto on MatrixAxis {
  Map<String, dynamic> toSyncDto() => {
        'MatrixAxisID': matrixAxisId,
        'MatrixRunID': matrixRunId,
        'AxisType': axisType.dbValue,
        'AxisName': axisName,
        'AxisOrder': axisOrder,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

MatrixAxesCompanion matrixAxisFromSyncDto(Map<String, dynamic> json) =>
    MatrixAxesCompanion(
      matrixAxisId: Value(json['MatrixAxisID'] as String),
      matrixRunId: Value(json['MatrixRunID'] as String),
      axisType: Value(AxisType.fromString(json['AxisType'] as String)),
      axisName: Value(json['AxisName'] as String),
      axisOrder: Value(json['AxisOrder'] as int),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
