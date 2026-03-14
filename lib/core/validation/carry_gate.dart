import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// Carry gate: block adoption of drills that use ClubCarry targeting
// when the user's active clubs in the drill's skill area lack carry distances.

/// Validates that all active clubs mapped to [skillArea] have carry distances
/// set in their performance profiles.
/// Throws [ValidationException] listing clubs without carry data.
Future<void> validateCarryDistances(
  AppDatabase db,
  String userId,
  SkillArea skillArea,
) async {
  // Find active clubs mapped to this skill area.
  final clubQuery = db.select(db.userClubs).join([
    innerJoin(
      db.userSkillAreaClubMappings,
      db.userSkillAreaClubMappings.clubType
              .equalsExp(db.userClubs.clubType) &
          db.userSkillAreaClubMappings.userId.equalsExp(db.userClubs.userId),
    ),
  ]);
  clubQuery
    ..where(db.userClubs.userId.equals(userId))
    ..where(db.userClubs.status.equalsValue(UserClubStatus.active))
    ..where(db.userSkillAreaClubMappings.skillArea.equalsValue(skillArea));

  final clubRows = await clubQuery.get();
  if (clubRows.isEmpty) return; // Bag gate handles the no-clubs case.

  // For each club, check for a performance profile with carry distance.
  final missingCarry = <String>[];
  for (final row in clubRows) {
    final club = row.readTable(db.userClubs);
    final profile = await (db.select(db.clubPerformanceProfiles)
          ..where((t) => t.clubId.equals(club.clubId))
          ..where((t) => t.carryDistance.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveFromDate)])
          ..limit(1))
        .getSingleOrNull();

    if (profile == null) {
      missingCarry.add(club.clubType.dbValue);
    }
  }

  if (missingCarry.isNotEmpty) {
    final names = missingCarry.join(', ');
    throw ValidationException(
      code: ValidationException.invalidStructure,
      message:
          'Carry distances required for: $names. '
          'Set carry distances in your golf bag before adopting this drill.',
      context: {
        'missingCarry': missingCarry,
        'skillArea': skillArea.dbValue,
      },
    );
  }
}
