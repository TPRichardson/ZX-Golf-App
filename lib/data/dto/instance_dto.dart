import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — Instance DTO serialisation.
// SelectedClub stores UserClub.ClubID (UUID), nullable for technique blocks.

extension InstanceSyncDto on Instance {
  Map<String, dynamic> toSyncDto() => {
        'InstanceID': instanceId,
        'SetID': setId,
        'SelectedClub': selectedClub,
        'RawMetrics': jsonDecode(rawMetrics),
        'Timestamp': timestamp.toUtc().toIso8601String(),
        'ResolvedTargetDistance': resolvedTargetDistance,
        'ResolvedTargetWidth': resolvedTargetWidth,
        'ResolvedTargetDepth': resolvedTargetDepth,
        'ShotShape': shotShape,
        'ShotEffort': shotEffort,
        'Flight': flight,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

InstancesCompanion instanceFromSyncDto(Map<String, dynamic> json) =>
    InstancesCompanion(
      instanceId: Value(json['InstanceID'] as String),
      setId: Value(json['SetID'] as String),
      selectedClub: Value(json['SelectedClub'] as String?),
      rawMetrics: Value(
        json['RawMetrics'] is String
            ? json['RawMetrics'] as String
            : jsonEncode(json['RawMetrics']),
      ),
      timestamp: Value(DateTime.parse(json['Timestamp'] as String)),
      resolvedTargetDistance: Value(json['ResolvedTargetDistance'] != null
          ? (json['ResolvedTargetDistance'] as num).toDouble()
          : null),
      resolvedTargetWidth: Value(json['ResolvedTargetWidth'] != null
          ? (json['ResolvedTargetWidth'] as num).toDouble()
          : null),
      resolvedTargetDepth: Value(json['ResolvedTargetDepth'] != null
          ? (json['ResolvedTargetDepth'] as num).toDouble()
          : null),
      shotShape: Value(json['ShotShape'] as String?),
      shotEffort: Value(json['ShotEffort'] as int?),
      flight: Value(json['Flight'] as int?),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
