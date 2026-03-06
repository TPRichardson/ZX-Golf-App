import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// Phase M3 — SnapshotClub DTO serialisation.

extension SnapshotClubSyncDto on SnapshotClub {
  Map<String, dynamic> toSyncDto() => {
        'SnapshotClubID': snapshotClubId,
        'SnapshotID': snapshotId,
        'ClubID': clubId,
        'CarryDistanceMeters': carryDistanceMeters,
        'TotalDistanceMeters': totalDistanceMeters,
        'DispersionLeftMeters': dispersionLeftMeters,
        'DispersionRightMeters': dispersionRightMeters,
        'RolloutDistanceMeters': rolloutDistanceMeters,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

SnapshotClubsCompanion snapshotClubFromSyncDto(
        Map<String, dynamic> json) =>
    SnapshotClubsCompanion(
      snapshotClubId: Value(json['SnapshotClubID'] as String),
      snapshotId: Value(json['SnapshotID'] as String),
      clubId: Value(json['ClubID'] as String),
      carryDistanceMeters: Value(json['CarryDistanceMeters'] != null
          ? (json['CarryDistanceMeters'] as num).toDouble()
          : null),
      totalDistanceMeters: Value(json['TotalDistanceMeters'] != null
          ? (json['TotalDistanceMeters'] as num).toDouble()
          : null),
      dispersionLeftMeters: Value(json['DispersionLeftMeters'] != null
          ? (json['DispersionLeftMeters'] as num).toDouble()
          : null),
      dispersionRightMeters:
          Value(json['DispersionRightMeters'] != null
              ? (json['DispersionRightMeters'] as num).toDouble()
              : null),
      rolloutDistanceMeters:
          Value(json['RolloutDistanceMeters'] != null
              ? (json['RolloutDistanceMeters'] as num).toDouble()
              : null),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
