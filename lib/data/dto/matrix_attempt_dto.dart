import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase M3 — MatrixAttempt DTO serialisation.

extension MatrixAttemptSyncDto on MatrixAttempt {
  Map<String, dynamic> toSyncDto() => {
        'MatrixAttemptID': matrixAttemptId,
        'MatrixCellID': matrixCellId,
        'AttemptTimestamp': attemptTimestamp.toUtc().toIso8601String(),
        'CarryDistanceMeters': carryDistanceMeters,
        'TotalDistanceMeters': totalDistanceMeters,
        'LeftDeviationMeters': leftDeviationMeters,
        'RightDeviationMeters': rightDeviationMeters,
        'RolloutDistanceMeters': rolloutDistanceMeters,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

MatrixAttemptsCompanion matrixAttemptFromSyncDto(
        Map<String, dynamic> json) =>
    MatrixAttemptsCompanion(
      matrixAttemptId: Value(json['MatrixAttemptID'] as String),
      matrixCellId: Value(json['MatrixCellID'] as String),
      attemptTimestamp:
          Value(DateTime.parse(json['AttemptTimestamp'] as String)),
      carryDistanceMeters: Value(json['CarryDistanceMeters'] != null
          ? (json['CarryDistanceMeters'] as num).toDouble()
          : null),
      totalDistanceMeters: Value(json['TotalDistanceMeters'] != null
          ? (json['TotalDistanceMeters'] as num).toDouble()
          : null),
      leftDeviationMeters: Value(json['LeftDeviationMeters'] != null
          ? (json['LeftDeviationMeters'] as num).toDouble()
          : null),
      rightDeviationMeters: Value(json['RightDeviationMeters'] != null
          ? (json['RightDeviationMeters'] as num).toDouble()
          : null),
      rolloutDistanceMeters: Value(json['RolloutDistanceMeters'] != null
          ? (json['RolloutDistanceMeters'] as num).toDouble()
          : null),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
