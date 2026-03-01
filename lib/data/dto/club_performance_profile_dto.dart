import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §5.2.5 — ClubPerformanceProfile DTO serialisation.
// No UserID (child of UserClub). EffectiveFromDate → date-only.

extension ClubPerformanceProfileSyncDto on ClubPerformanceProfile {
  Map<String, dynamic> toSyncDto() => {
        'ProfileID': profileId,
        'ClubID': clubId,
        'EffectiveFromDate':
            effectiveFromDate.toIso8601String().split('T')[0],
        'CarryDistance': carryDistance,
        'DispersionLeft': dispersionLeft,
        'DispersionRight': dispersionRight,
        'DispersionShort': dispersionShort,
        'DispersionLong': dispersionLong,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

ClubPerformanceProfilesCompanion clubPerformanceProfileFromSyncDto(
        Map<String, dynamic> json) =>
    ClubPerformanceProfilesCompanion(
      profileId: Value(json['ProfileID'] as String),
      clubId: Value(json['ClubID'] as String),
      effectiveFromDate:
          Value(DateTime.parse(json['EffectiveFromDate'] as String)),
      carryDistance: Value(json['CarryDistance'] != null
          ? (json['CarryDistance'] as num).toDouble()
          : null),
      dispersionLeft: Value(json['DispersionLeft'] != null
          ? (json['DispersionLeft'] as num).toDouble()
          : null),
      dispersionRight: Value(json['DispersionRight'] != null
          ? (json['DispersionRight'] as num).toDouble()
          : null),
      dispersionShort: Value(json['DispersionShort'] != null
          ? (json['DispersionShort'] as num).toDouble()
          : null),
      dispersionLong: Value(json['DispersionLong'] != null
          ? (json['DispersionLong'] as num).toDouble()
          : null),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
