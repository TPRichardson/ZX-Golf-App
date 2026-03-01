import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — UserClub DTO serialisation.

extension UserClubSyncDto on UserClub {
  Map<String, dynamic> toSyncDto() => {
        'ClubID': clubId,
        'UserID': userId,
        'ClubType': clubType.dbValue,
        'Make': make,
        'Model': model,
        'Loft': loft,
        'Status': status.dbValue,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

UserClubsCompanion userClubFromSyncDto(Map<String, dynamic> json) =>
    UserClubsCompanion(
      clubId: Value(json['ClubID'] as String),
      userId: Value(json['UserID'] as String),
      clubType: Value(ClubType.fromString(json['ClubType'] as String)),
      make: Value(json['Make'] as String?),
      model: Value(json['Model'] as String?),
      loft: Value(json['Loft'] != null
          ? (json['Loft'] as num).toDouble()
          : null),
      status: Value(
          UserClubStatus.fromString(json['Status'] as String)),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
