import 'package:drift/drift.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — UserSkillAreaClubMapping DTO serialisation.

extension UserSkillAreaClubMappingSyncDto on UserSkillAreaClubMapping {
  Map<String, dynamic> toSyncDto() => {
        'MappingID': mappingId,
        'UserID': userId,
        'ClubType': clubType.dbValue,
        'SkillArea': skillArea.dbValue,
        'IsMandatory': isMandatory,
        'CreatedAt': createdAt.toUtc().toIso8601String(),
        'UpdatedAt': updatedAt.toUtc().toIso8601String(),
      };
}

UserSkillAreaClubMappingsCompanion userSkillAreaClubMappingFromSyncDto(
        Map<String, dynamic> json) =>
    UserSkillAreaClubMappingsCompanion(
      mappingId: Value(json['MappingID'] as String),
      userId: Value(json['UserID'] as String),
      clubType: Value(ClubType.fromString(json['ClubType'] as String)),
      skillArea:
          Value(SkillArea.fromString(json['SkillArea'] as String)),
      isMandatory: Value(json['IsMandatory'] as bool),
      createdAt: Value(DateTime.parse(json['CreatedAt'] as String)),
      updatedAt: Value(DateTime.parse(json['UpdatedAt'] as String)),
    );
