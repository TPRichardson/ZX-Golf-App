import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'enums.dart';
import 'converters.dart';
import 'tables/event_type_refs.dart';
import 'tables/metric_schemas.dart';
import 'tables/subskill_refs.dart';
import 'tables/users.dart';
import 'tables/drills.dart';
import 'tables/practice_blocks.dart';
import 'tables/sessions.dart';
import 'tables/sets.dart';
import 'tables/instances.dart';
import 'tables/practice_entries.dart';
import 'tables/user_drill_adoptions.dart';
import 'tables/user_clubs.dart';
import 'tables/club_performance_profiles.dart';
import 'tables/user_skill_area_club_mappings.dart';
import 'tables/routines.dart';
import 'tables/schedules.dart';
import 'tables/calendar_days.dart';
import 'tables/routine_instances.dart';
import 'tables/schedule_instances.dart';
import 'tables/materialised_window_states.dart';
import 'tables/materialised_subskill_scores.dart';
import 'tables/materialised_skill_area_scores.dart';
import 'tables/materialised_overall_scores.dart';
import 'tables/event_logs.dart';
import 'tables/user_devices.dart';
import 'tables/user_scoring_locks.dart';
import 'tables/matrix_runs.dart';
import 'tables/matrix_axes.dart';
import 'tables/matrix_axis_values.dart';
import 'tables/matrix_cells.dart';
import 'tables/matrix_attempts.dart';
import 'tables/performance_snapshots.dart';
import 'tables/snapshot_clubs.dart';
import 'tables/user_training_items.dart';
import 'tables/sync_metadata.dart';
import 'seed_data.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  // Reference tables (3)
  EventTypeRefs,
  MetricSchemas,
  SubskillRefs,
  // Source tables (11)
  Users,
  Drills,
  PracticeBlocks,
  Sessions,
  Sets,
  Instances,
  PracticeEntries,
  UserDrillAdoptions,
  UserClubs,
  ClubPerformanceProfiles,
  UserSkillAreaClubMappings,
  // Planning tables (5)
  Routines,
  Schedules,
  CalendarDays,
  RoutineInstances,
  ScheduleInstances,
  // Materialised tables (4)
  MaterialisedWindowStates,
  MaterialisedSubskillScores,
  MaterialisedSkillAreaScores,
  MaterialisedOverallScores,
  // System tables (3)
  EventLogs,
  UserDevices,
  UserScoringLocks,
  // Matrix tables (7) — Matrix §8.3
  MatrixRuns,
  MatrixAxes,
  MatrixAxisValues,
  MatrixCells,
  MatrixAttempts,
  PerformanceSnapshots,
  SnapshotClubs,
  // Training Kit (1)
  UserTrainingItems,
  // Local-only (1)
  SyncMetadataEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await seedReferenceData(this);
          await _createIndexes();
        },
        // TD-06 §18 — Migration framework.
        // Column additions are safe. Column type changes require explicit transforms.
        // Materialised tables can be truncated and rebuilt.
        // Raw execution data is sacred — never delete/truncate.
        onUpgrade: (Migrator m, int from, int to) async {
          for (var version = from; version < to; version++) {
            switch (version) {
              case 1:
                await _migrateV1ToV2(m);
              case 2:
                await _migrateV2ToV3(m);
              case 3:
                await _migrateV3ToV4(m);
              case 4:
                await _migrateV4ToV5(m);
              case 5:
                await _migrateV5ToV6(m);
              case 6:
                await _migrateV6ToV7(m);
              case 7:
                await _migrateV7ToV8(m);
              case 8:
                await _migrateV8ToV9(m);
              case 9:
                await _migrateV9ToV10(m);
              case 10:
                await _migrateV10ToV11(m);
              case 11:
                await _migrateV11ToV12(m);
              case 12:
                await _migrateV12ToV13(m);
              case 13:
                await _migrateV13ToV14(m);
              case 14:
                await _migrateV14ToV15(m);
              case 15:
                await _migrateV15ToV16(m);
            }
          }
        },
      );

  Future<void> _migrateV1ToV2(Migrator m) async {
    await _createIndexes();
  }

  // 5F — Add LastAppliedAt column to Routine table for MRU sorting.
  Future<void> _migrateV2ToV3(Migrator m) async {
    await customStatement(
        'ALTER TABLE Routine ADD COLUMN LastAppliedAt INTEGER');
  }

  // 8A — Partial indexes on IsDeleted=false for high-traffic queries.
  Future<void> _migrateV3ToV4(Migrator m) async {
    await _createPartialIndexes();
  }

  // Add Target column to Drill table for custom drill targets.
  Future<void> _migrateV6ToV7(Migrator m) async {
    await customStatement('ALTER TABLE Drill ADD COLUMN Target REAL');
  }

  // Add WindowSize column to SubskillRef for per-subskill window capacity.
  // Sets rebuildNeeded flag so startup check triggers a full rebuild with
  // the new accumulation scoring formula.
  Future<void> _migrateV7ToV8(Migrator m) async {
    await customStatement(
        'ALTER TABLE SubskillRef ADD COLUMN WindowSize INTEGER NOT NULL DEFAULT 25');
    await reseedSubskillRefs(this);
    await into(syncMetadataEntries).insertOnConflictUpdate(
      SyncMetadataEntriesCompanion.insert(
        key: 'rebuildNeeded',
        value: 'true',
      ),
    );
  }

  // Add EnvironmentType column to PracticeBlock table.
  Future<void> _migrateV8ToV9(Migrator m) async {
    await customStatement(
        'ALTER TABLE PracticeBlock ADD COLUMN EnvironmentType TEXT');
  }

  // Server-authoritative standard drills: add HasUnseenUpdate, remove local standard drills.
  Future<void> _migrateV10ToV11(Migrator m) async {
    await customStatement(
        'ALTER TABLE UserDrillAdoption ADD COLUMN HasUnseenUpdate INTEGER NOT NULL DEFAULT 0');
    // Standard drills are now server-authoritative — remove local copies.
    await customStatement("DELETE FROM Drill WHERE UserID IS NULL");
  }

  // Rename SkillArea 'Irons' → 'Approach' and subskill IDs 'irons_*' → 'approach_*'.
  Future<void> _migrateV11ToV12(Migrator m) async {
    // Update SkillArea TEXT in all 6 tables that store it.
    for (final table in [
      'Drill',
      'SubskillRef',
      'MaterialisedSkillAreaScore',
      'MaterialisedSubskillScore',
      'MaterialisedWindowState',
      'UserSkillAreaClubMapping',
    ]) {
      await customStatement(
          "UPDATE $table SET SkillArea = 'Approach' WHERE SkillArea = 'Irons'");
    }
    // Rename subskill IDs.
    await customStatement(
        "UPDATE SubskillRef SET SubskillID = 'approach_distance_control' WHERE SubskillID = 'irons_distance_control'");
    await customStatement(
        "UPDATE SubskillRef SET SubskillID = 'approach_direction_control' WHERE SubskillID = 'irons_direction_control'");
    await customStatement(
        "UPDATE SubskillRef SET SubskillID = 'approach_shape_control' WHERE SubskillID = 'irons_shape_control'");
    // Update Subskill foreign keys in materialised tables.
    for (final table in [
      'MaterialisedSubskillScore',
      'MaterialisedWindowState',
    ]) {
      await customStatement(
          "UPDATE $table SET Subskill = REPLACE(Subskill, 'irons_', 'approach_') WHERE Subskill LIKE 'irons_%'");
    }
    // Update SubskillMapping JSON in Drill table (contains subskill ID strings).
    await customStatement(
        "UPDATE Drill SET SubskillMapping = REPLACE(SubskillMapping, 'irons_', 'approach_') WHERE SubskillMapping LIKE '%irons_%'");
  }

  // Add RequiredEquipment JSON column to Drill table.
  Future<void> _migrateV12ToV13(Migrator m) async {
    await customStatement(
        "ALTER TABLE Drill ADD COLUMN RequiredEquipment TEXT NOT NULL DEFAULT '[]'");
  }

  // Add EnvironmentType column to Session table so each session records
  // its own environment independently of the practice block.
  Future<void> _migrateV13ToV14(Migrator m) async {
    await customStatement(
        'ALTER TABLE Session ADD COLUMN EnvironmentType TEXT');
  }

  // Add Description, TargetDistanceUnit, TargetSizeUnit to Drill table + seed first system drill.
  Future<void> _migrateV9ToV10(Migrator m) async {
    await customStatement('ALTER TABLE Drill ADD COLUMN Description TEXT');
    await customStatement(
        'ALTER TABLE Drill ADD COLUMN TargetDistanceUnit TEXT');
    await customStatement('ALTER TABLE Drill ADD COLUMN TargetSizeUnit TEXT');
    // System drills previously seeded here; now server-authoritative (v11 deletes them).
  }

  // SelectedClub: nullable (technique blocks have no club).
  // SQLite doesn't enforce NOT NULL changes, so no ALTER needed.
  // Clean-slate migration — old data uses type strings, new data uses club UUIDs.
  Future<void> _migrateV15ToV16(Migrator m) async {
    // No-op: SQLite TEXT columns accept NULL regardless of schema declaration.
    // The Drift codegen handles the nullable type at the Dart level.
  }

  // Training Kit table + RecommendedEquipment column on Drill.
  Future<void> _migrateV14ToV15(Migrator m) async {
    await m.createTable(userTrainingItems);
    await customStatement(
        "ALTER TABLE Drill ADD COLUMN RecommendedEquipment TEXT NOT NULL DEFAULT '[]'");
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_user_training_item_user_id '
        'ON UserTrainingItem (UserID)');
  }

  // Add SurfaceType column to PracticeBlock and Session tables.
  Future<void> _migrateV5ToV6(Migrator m) async {
    await customStatement(
        'ALTER TABLE PracticeBlock ADD COLUMN SurfaceType TEXT');
    await customStatement(
        'ALTER TABLE Session ADD COLUMN SurfaceType TEXT');
  }

  // M1 — Matrix & Gapping System tables (7 new tables + indexes).
  Future<void> _migrateV4ToV5(Migrator m) async {
    await m.createTable(matrixRuns);
    await m.createTable(matrixAxes);
    await m.createTable(matrixAxisValues);
    await m.createTable(matrixCells);
    await m.createTable(matrixAttempts);
    await m.createTable(performanceSnapshots);
    await m.createTable(snapshotClubs);
    await _createMatrixIndexes();
  }

  /// Matrix FK indexes for query performance.
  Future<void> _createMatrixIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_matrix_axis_run_id '
        'ON MatrixAxis (MatrixRunID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_matrix_axis_value_axis_id '
        'ON MatrixAxisValue (MatrixAxisID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_matrix_cell_run_id '
        'ON MatrixCell (MatrixRunID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_matrix_attempt_cell_id '
        'ON MatrixAttempt (MatrixCellID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_snapshot_club_snapshot_id '
        'ON SnapshotClub (SnapshotID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_matrix_run_user_id '
        'ON MatrixRun (UserID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_performance_snapshot_user_id '
        'ON PerformanceSnapshot (UserID)');
  }

  /// Secondary indexes for FK lookup columns. Drift Dart DSL doesn't support
  /// declarative indexes, so these are created via raw SQL.
  Future<void> _createIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_session_practice_block_id '
        'ON Session (PracticeBlockID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_session_drill_id '
        'ON Session (DrillID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_instance_set_id '
        'ON Instance (SetID)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_practice_block_user_end '
        'ON PracticeBlock (UserID, EndTimestamp)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_drill_user_id '
        'ON Drill (UserID)');
    await _createPartialIndexes();
    await _createMatrixIndexes();
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_user_training_item_user_id '
        'ON UserTrainingItem (UserID)');
  }

  /// 8A — Partial indexes for IsDeleted=false on high-traffic tables.
  /// UserClub excluded — uses Status column, not IsDeleted.
  Future<void> _createPartialIndexes() async {
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_drills_active '
        'ON Drill (UserID, SkillArea) WHERE IsDeleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sessions_active '
        'ON Session (DrillID, CompletionTimestamp) WHERE IsDeleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_instances_active '
        'ON Instance (SetID) WHERE IsDeleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_practice_blocks_active '
        'ON PracticeBlock (UserID) WHERE IsDeleted = 0');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Use AppSupport (AppData/Roaming on Windows) not Documents,
    // to avoid OneDrive sync locking the SQLite file.
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'zx_golf_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
