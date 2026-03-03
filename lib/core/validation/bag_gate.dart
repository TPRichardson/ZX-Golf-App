import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// S09 §9.3 — Golf Bag hard gate: block scored drill operations
// when no active club is mapped to the drill's Skill Area.

/// Validates that the user has at least one active club mapped to [skillArea].
/// Throws [ValidationException] if no eligible club exists and the drill is
/// scored (not TechniqueBlock).
///
/// TechniqueBlock drills are exempt because they don't require club selection.
Future<void> validateClubEligibility(
  AppDatabase db,
  String userId,
  SkillArea skillArea,
  DrillType drillType,
) async {
  // TechniqueBlock drills are exempt — no club selection needed.
  if (drillType == DrillType.techniqueBlock) return;

  // Query active clubs mapped to this Skill Area via join.
  final query = db.select(db.userClubs).join([
    innerJoin(
      db.userSkillAreaClubMappings,
      db.userSkillAreaClubMappings.clubType
              .equalsExp(db.userClubs.clubType) &
          db.userSkillAreaClubMappings.userId
              .equalsExp(db.userClubs.userId),
    ),
  ]);
  query
    ..where(db.userClubs.userId.equals(userId))
    ..where(db.userClubs.status.equalsValue(UserClubStatus.active))
    ..where(
        db.userSkillAreaClubMappings.skillArea.equalsValue(skillArea));

  final rows = await query.get();

  if (rows.isEmpty) {
    throw ValidationException(
      code: ValidationException.invalidStructure,
      message:
          'No active club mapped to ${skillArea.dbValue}. '
          'Add a club to your bag before using this drill.',
      context: {'userId': userId, 'skillArea': skillArea.dbValue},
    );
  }
}
