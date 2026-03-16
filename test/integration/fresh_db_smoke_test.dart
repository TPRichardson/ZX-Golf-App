// Fresh database smoke test — verifies seed data, system drills,
// default bag mappings, and zero-state dashboard readiness.
@Tags(['smoke'])
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/core/constants.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/club_repository.dart';
import 'package:zx_golf_app/data/repositories/scoring_repository.dart';
import 'package:zx_golf_app/core/sync/sync_write_gate.dart';

void main() {
  late AppDatabase db;
  late SyncWriteGate gate;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gate = SyncWriteGate();
  });

  tearDown(() => db.close());

  group('Fresh database smoke test', () {
    test('schema version is 16', () {
      expect(db.schemaVersion, 16);
    });

    test('35 tables are created', () async {
      final tables = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      ).get();
      // 27 original + 7 Matrix tables + 1 UserTrainingItem = 35.
      expect(tables.length, 35);
    });

    test('17 indexes are created', () async {
      final indexes = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
      ).get();
      final names = indexes.map((r) => r.read<String>('name')).toList()..sort();
      // 9 original + 7 Matrix indexes + 1 UserTrainingItem = 17.
      expect(names, [
        'idx_drill_user_id',
        'idx_drills_active',
        'idx_instance_set_id',
        'idx_instances_active',
        'idx_matrix_attempt_cell_id',
        'idx_matrix_axis_run_id',
        'idx_matrix_axis_value_axis_id',
        'idx_matrix_cell_run_id',
        'idx_matrix_run_user_id',
        'idx_performance_snapshot_user_id',
        'idx_practice_block_user_end',
        'idx_practice_blocks_active',
        'idx_session_drill_id',
        'idx_session_practice_block_id',
        'idx_sessions_active',
        'idx_snapshot_club_snapshot_id',
        'idx_user_training_item_user_id',
      ]);
    });

    test('19 SubskillRefs seeded with allocation summing to 1000', () async {
      final refs = await db.select(db.subskillRefs).get();
      expect(refs.length, 19);
      final totalAllocation = refs.fold<int>(0, (sum, r) => sum + r.allocation);
      expect(totalAllocation, 1000);
    });

    test('16 EventTypeRefs seeded', () async {
      final refs = await db.select(db.eventTypeRefs).get();
      expect(refs.length, 16);
    });

    test('0 local standard drills (server-authoritative)', () async {
      final drills = await (db.select(db.drills)
            ..where((t) => t.userId.isNull()))
          .get();
      expect(drills.length, 0);
    });

    test('MetricSchemas seeded', () async {
      final schemas = await db.select(db.metricSchemas).get();
      expect(schemas.length, greaterThan(0));
    });

    test('dev user can be created and retrieved', () async {
      // Seed a dev user like the app does.
      await db.into(db.users).insert(UsersCompanion.insert(
        userId: kDevUserId,
        displayName: const Value('Dev User'),
      ));
      final user = await (db.select(db.users)
            ..where((t) => t.userId.equals(kDevUserId)))
          .getSingleOrNull();
      expect(user, isNotNull);
      expect(user!.displayName, 'Dev User');
    });

    test('default bag clubs and mappings can be created', () async {
      // Create dev user first.
      await db.into(db.users).insert(UsersCompanion.insert(
        userId: kDevUserId,
        displayName: const Value('Dev User'),
      ));

      final clubRepo = ClubRepository(db, gate);

      // Add a driver (mandatory club).
      final club = await clubRepo.addClub(
        kDevUserId,
        UserClubsCompanion.insert(
          clubId: 'test-driver-001',
          userId: kDevUserId,
          clubType: ClubType.driver,
        ),
      );
      expect(club.clubType, ClubType.driver);

      // S09 §9.2.3 — addClub creates default mappings automatically.
      final mappings = await (db.select(db.userSkillAreaClubMappings)
            ..where((t) => t.userId.equals(kDevUserId)))
          .get();
      expect(mappings.length, greaterThan(0),
          reason: 'Default skill area club mappings should be created');

      // Driver should map to Driving skill area (mandatory).
      final drivingMapping = mappings.where(
          (m) => m.skillArea == SkillArea.driving && m.isMandatory);
      expect(drivingMapping.length, 1,
          reason: 'Driver should have mandatory Driving mapping');
    });

    test('zero-state: no practice blocks exist', () async {
      final blocks = await db.select(db.practiceBlocks).get();
      expect(blocks, isEmpty);
    });

    test('zero-state: no sessions exist', () async {
      final sessions = await db.select(db.sessions).get();
      expect(sessions, isEmpty);
    });

    test('zero-state: no materialised scores exist', () async {
      final windows = await db.select(db.materialisedWindowStates).get();
      final subskills = await db.select(db.materialisedSubskillScores).get();
      final skillAreas = await db.select(db.materialisedSkillAreaScores).get();
      final overall = await db.select(db.materialisedOverallScores).get();
      expect(windows, isEmpty);
      expect(subskills, isEmpty);
      expect(skillAreas, isEmpty);
      expect(overall, isEmpty);
    });

    test('zero-state: scoring repository returns empty for user', () async {
      final scoringRepo = ScoringRepository(db);
      final windows =
          await scoringRepo.getWindowStatesForUser(kDevUserId);
      expect(windows, isEmpty);
    });

    test('zero-state: no calendar days or routines exist', () async {
      final days = await db.select(db.calendarDays).get();
      final routines = await db.select(db.routines).get();
      final schedules = await db.select(db.schedules).get();
      expect(days, isEmpty);
      expect(routines, isEmpty);
      expect(schedules, isEmpty);
    });
  });
}
