import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';

// Phase 3 — ClubRepository tests.
// Covers: UserClub state machine (TD-04 §2.10.1), default mappings (S09 §9.2.3),
// mandatory mapping enforcement, performance profiles.

void main() {
  late AppDatabase db;
  late ClubRepository repo;

  const userId = 'test-user-club';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ClubRepository(db, SyncWriteGate());
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // UserClub state machine — TD-04 §2.10.1
  // ---------------------------------------------------------------------------
  group('UserClub state machine (TD-04 §2.10.1)', () {
    test('addClub creates club with Active status + default mappings',
        () async {
      final club = await repo.addClub(
        userId,
        UserClubsCompanion(
          clubType: const Value(ClubType.driver),
          make: const Value('TaylorMade'),
          model: const Value('Stealth 2'),
        ),
      );

      expect(club.status, UserClubStatus.active);
      expect(club.userId, userId);
      expect(club.clubType, ClubType.driver);
      expect(club.make, 'TaylorMade');
    });

    test('retireClub: Active→Retired', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );

      final retired = await repo.retireClub(userId, club.clubId);
      expect(retired.status, UserClubStatus.retired);
    });

    test('reactivateClub: Retired→Active', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );
      await repo.retireClub(userId, club.clubId);

      final reactivated = await repo.reactivateClub(userId, club.clubId);
      expect(reactivated.status, UserClubStatus.active);
    });

    test('retireClub on Retired throws stateTransition', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );
      await repo.retireClub(userId, club.clubId);

      expect(
        () => repo.retireClub(userId, club.clubId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });

    test('reactivateClub on Active throws stateTransition', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );

      expect(
        () => repo.reactivateClub(userId, club.clubId),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.stateTransition,
        )),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Default mappings — S09 §9.2.3
  // ---------------------------------------------------------------------------
  group('Default mappings (S09 §9.2.3)', () {
    test('addClub(Driver) creates Driving mapping (mandatory)', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final drivingMapping = mappings.where(
          (m) => m.clubType == ClubType.driver && m.skillArea == SkillArea.driving);
      expect(drivingMapping, hasLength(1));
      expect(drivingMapping.first.isMandatory, true);
    });

    test('addClub(Putter) creates Putting mapping (mandatory)', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.putter)),
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final puttingMapping = mappings.where(
          (m) => m.clubType == ClubType.putter && m.skillArea == SkillArea.putting);
      expect(puttingMapping, hasLength(1));
      expect(puttingMapping.first.isMandatory, true);
    });

    test('addClub(i7) creates Irons (mandatory) + Chipping + Bunkers',
        () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final i7Mappings = mappings.where((m) => m.clubType == ClubType.i7);

      // S09 §9.2.3: i7 → Irons (mandatory) + Chipping + Bunkers.
      // i7 is NOT in Pitching defaults (only i9, PW, AW, GW, SW, LW).
      expect(i7Mappings.length, 3);

      final ironsMandatory = i7Mappings.where(
          (m) => m.skillArea == SkillArea.irons && m.isMandatory);
      expect(ironsMandatory, hasLength(1));

      final chipping =
          i7Mappings.where((m) => m.skillArea == SkillArea.chipping);
      expect(chipping, hasLength(1));

      final bunkers =
          i7Mappings.where((m) => m.skillArea == SkillArea.bunkers);
      expect(bunkers, hasLength(1));
    });

    test('addClub(SW) creates Pitching + Chipping + Bunkers (non-mandatory)',
        () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.sw)),
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final swMappings = mappings.where((m) => m.clubType == ClubType.sw);

      // Pitching, Chipping, Bunkers — all non-mandatory.
      expect(swMappings.length, 3);
      for (final m in swMappings) {
        expect(m.isMandatory, false);
      }

      final areas = swMappings.map((m) => m.skillArea).toSet();
      expect(areas, {SkillArea.pitching, SkillArea.chipping, SkillArea.bunkers});
    });

    test('addClub(W3) creates Woods mapping (non-mandatory)', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.w3)),
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final w3Mappings = mappings.where((m) => m.clubType == ClubType.w3);

      expect(w3Mappings.length, 1);
      expect(w3Mappings.first.skillArea, SkillArea.woods);
      expect(w3Mappings.first.isMandatory, false);
    });

    test('addClub(H4) creates Woods mapping (non-mandatory)', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.h4)),
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final h4Mappings = mappings.where((m) => m.clubType == ClubType.h4);

      expect(h4Mappings.length, 1);
      expect(h4Mappings.first.skillArea, SkillArea.woods);
    });
  });

  // ---------------------------------------------------------------------------
  // Mandatory mapping enforcement — S09 §9.2.3
  // ---------------------------------------------------------------------------
  group('Mandatory mapping enforcement', () {
    test('remove Driver→Driving throws invalidStructure', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );

      expect(
        () => repo.updateSkillAreaMapping(
          userId,
          ClubType.driver,
          SkillArea.driving,
          false,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('remove Putter→Putting throws invalidStructure', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.putter)),
      );

      expect(
        () => repo.updateSkillAreaMapping(
          userId,
          ClubType.putter,
          SkillArea.putting,
          false,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('remove i5→Irons throws invalidStructure', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i5)),
      );

      expect(
        () => repo.updateSkillAreaMapping(
          userId,
          ClubType.i5,
          SkillArea.irons,
          false,
        ),
        throwsA(isA<ValidationException>().having(
          (e) => e.code,
          'code',
          ValidationException.invalidStructure,
        )),
      );
    });

    test('remove SW→Chipping succeeds (non-mandatory)', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.sw)),
      );

      // Should not throw.
      await repo.updateSkillAreaMapping(
        userId,
        ClubType.sw,
        SkillArea.chipping,
        false,
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final swChipping = mappings.where(
          (m) => m.clubType == ClubType.sw && m.skillArea == SkillArea.chipping);
      expect(swChipping, isEmpty);
    });

    test('add mapping creates new entry', () async {
      // Add a club with no initial Putting mapping.
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.sw)),
      );

      // SW doesn't default to Putting, so add it.
      await repo.updateSkillAreaMapping(
        userId,
        ClubType.sw,
        SkillArea.putting,
        true,
      );

      final mappings = await repo.watchMappingsByUser(userId).first;
      final swPutting = mappings.where(
          (m) => m.clubType == ClubType.sw && m.skillArea == SkillArea.putting);
      expect(swPutting, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // Performance profiles
  // ---------------------------------------------------------------------------
  group('Performance profiles', () {
    test('addPerformanceProfile creates profile', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );

      final profile = await repo.addPerformanceProfile(
        club.clubId,
        ClubPerformanceProfilesCompanion(
          effectiveFromDate: Value(DateTime(2026, 3, 1)),
          carryDistance: const Value(155.0),
          dispersionLeft: const Value(10.0),
          dispersionRight: const Value(12.0),
        ),
      );

      expect(profile.clubId, club.clubId);
      expect(profile.carryDistance, 155.0);
    });

    test('getActiveProfile returns most recent ≤ today', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );

      // Older profile.
      await repo.addPerformanceProfile(
        club.clubId,
        ClubPerformanceProfilesCompanion(
          effectiveFromDate: Value(DateTime(2025, 1, 1)),
          carryDistance: const Value(150.0),
        ),
      );

      // Newer profile (still ≤ now).
      await repo.addPerformanceProfile(
        club.clubId,
        ClubPerformanceProfilesCompanion(
          effectiveFromDate: Value(DateTime(2026, 2, 1)),
          carryDistance: const Value(155.0),
        ),
      );

      // Future profile (should be excluded).
      await repo.addPerformanceProfile(
        club.clubId,
        ClubPerformanceProfilesCompanion(
          effectiveFromDate: Value(DateTime(2099, 1, 1)),
          carryDistance: const Value(200.0),
        ),
      );

      final active = await repo.getActiveProfile(club.clubId);
      expect(active, isNotNull);
      expect(active!.carryDistance, 155.0);
    });
  });

  // ---------------------------------------------------------------------------
  // watchClubsForSkillArea
  // ---------------------------------------------------------------------------
  group('watchClubsForSkillArea', () {
    test('returns Active clubs mapped to SkillArea', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i8)),
      );
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );

      // Irons skill area should include i7 and i8, not Driver.
      final ironsClubs =
          await repo.watchClubsForSkillArea(userId, SkillArea.irons).first;
      final clubTypes = ironsClubs.map((c) => c.clubType).toSet();
      expect(clubTypes, contains(ClubType.i7));
      expect(clubTypes, contains(ClubType.i8));
      expect(clubTypes, isNot(contains(ClubType.driver)));
    });

    test('excludes Retired clubs', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );
      await repo.retireClub(userId, club.clubId);

      final ironsClubs =
          await repo.watchClubsForSkillArea(userId, SkillArea.irons).first;
      expect(ironsClubs, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // updateClub
  // ---------------------------------------------------------------------------
  group('updateClub', () {
    test('updates Make, Model, Loft', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.i7)),
      );

      final updated = await repo.updateClub(
        club.clubId,
        const UserClubsCompanion(
          make: Value('Titleist'),
          model: Value('T200'),
          loft: Value(34.0),
        ),
      );

      expect(updated.make, 'Titleist');
      expect(updated.model, 'T200');
      expect(updated.loft, 34.0);
    });
  });

  // ---------------------------------------------------------------------------
  // watchUserBag
  // ---------------------------------------------------------------------------
  group('watchUserBag', () {
    test('returns clubs in user bag', () async {
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.putter)),
      );

      final bag = await repo.watchUserBag(userId).first;
      expect(bag.length, 2);
    });

    test('filters by status', () async {
      final club = await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.driver)),
      );
      await repo.addClub(
        userId,
        const UserClubsCompanion(clubType: Value(ClubType.putter)),
      );
      await repo.retireClub(userId, club.clubId);

      final activeBag =
          await repo.watchUserBag(userId, status: UserClubStatus.active).first;
      expect(activeBag.length, 1);
      expect(activeBag.first.clubType, ClubType.putter);

      final retiredBag = await repo
          .watchUserBag(userId, status: UserClubStatus.retired)
          .first;
      expect(retiredBag.length, 1);
      expect(retiredBag.first.clubType, ClubType.driver);
    });
  });
}
