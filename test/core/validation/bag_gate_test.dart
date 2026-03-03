import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/core/validation/bag_gate.dart' as bag_gate;
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';

// S09 §9.3 — Bag gate unit tests.

void main() {
  late AppDatabase db;
  late ClubRepository clubRepo;

  const userId = 'test-user-bag-gate';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    clubRepo = ClubRepository(db, SyncWriteGate());
  });

  tearDown(() async {
    await db.close();
  });

  group('validateClubEligibility (S09 §9.3)', () {
    test('throws when no clubs mapped to Skill Area', () async {
      // No clubs at all — Driving has no mapped clubs.
      expect(
        () => bag_gate.validateClubEligibility(
            db, userId, SkillArea.driving, DrillType.transition),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('passes when an active club is mapped to Skill Area', () async {
      // Add a driver → gets default Driving mapping.
      await clubRepo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );

      // Should not throw.
      await bag_gate.validateClubEligibility(
          db, userId, SkillArea.driving, DrillType.transition);
    });

    test('TechniqueBlock drills are exempt regardless of clubs', () async {
      // No clubs, but TechniqueBlock is exempt.
      await bag_gate.validateClubEligibility(
          db, userId, SkillArea.driving, DrillType.techniqueBlock);
    });

    test('throws after last club for Skill Area is retired', () async {
      final club = await clubRepo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );

      // Passes with active club.
      await bag_gate.validateClubEligibility(
          db, userId, SkillArea.driving, DrillType.pressure);

      // Retire the only club.
      await clubRepo.retireClub(userId, club.clubId);

      // Now should throw.
      expect(
        () => bag_gate.validateClubEligibility(
            db, userId, SkillArea.driving, DrillType.pressure),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
