import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase M3 — MatrixAxisValue DTO serialisation.

extension MatrixAxisValueSyncDto on MatrixAxisValue {
  Map<String, dynamic> toSyncDto() => {
        'AxisValueID': axisValueId,
        'MatrixAxisID': matrixAxisId,
        'Label': label,
        'SortOrder': sortOrder,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

MatrixAxisValuesCompanion matrixAxisValueFromSyncDto(
        Map<String, dynamic> json) =>
    MatrixAxisValuesCompanion(
      axisValueId: Value(json['AxisValueID'] as String),
      matrixAxisId: Value(json['MatrixAxisID'] as String),
      label: Value(json['Label'] as String),
      sortOrder: Value(json['SortOrder'] as int),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
