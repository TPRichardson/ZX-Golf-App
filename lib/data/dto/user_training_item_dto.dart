import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Training Kit item DTO serialisation.

extension UserTrainingItemSyncDto on UserTrainingItem {
  Map<String, dynamic> toSyncDto() => {
        'ItemID': itemId,
        'UserID': userId,
        'Category': category.dbValue,
        'SkillAreas': jsonDecode(skillAreas),
        'Name': name,
        'Properties': jsonDecode(properties),
        'LinkedClubID': linkedClubId,
        'IsDeleted': isDeleted,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

UserTrainingItemsCompanion userTrainingItemFromSyncDto(
        Map<String, dynamic> json) =>
    UserTrainingItemsCompanion(
      itemId: Value(json['ItemID'] as String),
      userId: Value(json['UserID'] as String),
      category: Value(
          EquipmentCategory.fromString(json['Category'] as String)),
      skillAreas: Value(
        json['SkillAreas'] is String
            ? json['SkillAreas'] as String
            : jsonEncode(json['SkillAreas'] ?? []),
      ),
      name: Value(json['Name'] as String),
      properties: Value(
        json['Properties'] is String
            ? json['Properties'] as String
            : jsonEncode(json['Properties'] ?? {}),
      ),
      linkedClubId: Value(json['LinkedClubID'] as String?),
      isDeleted: Value(json['IsDeleted'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
