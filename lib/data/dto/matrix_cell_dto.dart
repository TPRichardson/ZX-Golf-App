import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase M3 — MatrixCell DTO serialisation.

extension MatrixCellSyncDto on MatrixCell {
  Map<String, dynamic> toSyncDto() => {
        'MatrixCellID': matrixCellId,
        'MatrixRunID': matrixRunId,
        'AxisValueIDs': jsonDecode(axisValueIds),
        'ExcludedFromRun': excludedFromRun,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

MatrixCellsCompanion matrixCellFromSyncDto(Map<String, dynamic> json) =>
    MatrixCellsCompanion(
      matrixCellId: Value(json['MatrixCellID'] as String),
      matrixRunId: Value(json['MatrixRunID'] as String),
      axisValueIds: Value(
        json['AxisValueIDs'] is String
            ? json['AxisValueIDs'] as String
            : jsonEncode(json['AxisValueIDs']),
      ),
      excludedFromRun: Value(json['ExcludedFromRun'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
