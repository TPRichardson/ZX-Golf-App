import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — Drill DTO serialisation. Most complex entity (10 enums, 2 JSONB).

extension DrillSyncDto on Drill {
  Map<String, dynamic> toSyncDto() => {
        'DrillID': drillId,
        'UserID': userId,
        'Name': name,
        'SkillArea': skillArea.dbValue,
        'DrillType': drillType.dbValue,
        'ScoringMode': scoringMode?.dbValue,
        'InputMode': inputMode.dbValue,
        'MetricSchemaID': metricSchemaId,
        'GridType': gridType?.dbValue,
        'SubskillMapping': jsonDecode(subskillMapping),
        'ClubSelectionMode': clubSelectionMode?.dbValue,
        'TargetDistanceMode': targetDistanceMode?.dbValue,
        'TargetDistanceValue': targetDistanceValue,
        'TargetSizeMode': targetSizeMode?.dbValue,
        'TargetSizeWidth': targetSizeWidth,
        'TargetSizeDepth': targetSizeDepth,
        'RequiredSetCount': requiredSetCount,
        'RequiredAttemptsPerSet': requiredAttemptsPerSet,
        'Anchors': jsonDecode(anchors),
        'Origin': origin.dbValue,
        'Status': status.dbValue,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

DrillsCompanion drillFromSyncDto(Map<String, dynamic> json) => DrillsCompanion(
      drillId: Value(json['DrillID'] as String),
      userId: Value(json['UserID'] as String?),
      name: Value(json['Name'] as String),
      skillArea: Value(SkillArea.fromString(json['SkillArea'] as String)),
      drillType: Value(DrillType.fromString(json['DrillType'] as String)),
      scoringMode: Value(json['ScoringMode'] != null
          ? ScoringMode.fromString(json['ScoringMode'] as String)
          : null),
      inputMode: Value(InputMode.fromString(json['InputMode'] as String)),
      metricSchemaId: Value(json['MetricSchemaID'] as String),
      gridType: Value(json['GridType'] != null
          ? GridType.fromString(json['GridType'] as String)
          : null),
      subskillMapping: Value(
        json['SubskillMapping'] is String
            ? json['SubskillMapping'] as String
            : jsonEncode(json['SubskillMapping']),
      ),
      clubSelectionMode: Value(json['ClubSelectionMode'] != null
          ? ClubSelectionMode.fromString(json['ClubSelectionMode'] as String)
          : null),
      targetDistanceMode: Value(json['TargetDistanceMode'] != null
          ? TargetDistanceMode.fromString(json['TargetDistanceMode'] as String)
          : null),
      targetDistanceValue: Value(
          json['TargetDistanceValue'] != null
              ? (json['TargetDistanceValue'] as num).toDouble()
              : null),
      targetSizeMode: Value(json['TargetSizeMode'] != null
          ? TargetSizeMode.fromString(json['TargetSizeMode'] as String)
          : null),
      targetSizeWidth: Value(
          json['TargetSizeWidth'] != null
              ? (json['TargetSizeWidth'] as num).toDouble()
              : null),
      targetSizeDepth: Value(
          json['TargetSizeDepth'] != null
              ? (json['TargetSizeDepth'] as num).toDouble()
              : null),
      requiredSetCount: Value(json['RequiredSetCount'] as int),
      requiredAttemptsPerSet:
          Value(json['RequiredAttemptsPerSet'] as int?),
      anchors: Value(
        json['Anchors'] is String
            ? json['Anchors'] as String
            : jsonEncode(json['Anchors']),
      ),
      origin: Value(DrillOrigin.fromString(json['Origin'] as String)),
      status: Value(DrillStatus.fromString(json['Status'] as String)),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
