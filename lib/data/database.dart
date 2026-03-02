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
  // Local-only (1)
  SyncMetadataEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await seedReferenceData(this);
        },
        // TD-06 §18 — Migration framework.
        // Column additions are safe. Column type changes require explicit transforms.
        // Materialised tables can be truncated and rebuilt.
        // Raw execution data is sacred — never delete/truncate.
        onUpgrade: (Migrator m, int from, int to) async {
          for (var version = from; version < to; version++) {
            switch (version) {
              // Future migrations go here:
              // case 1: await _migrateV1ToV2(m); break;
            }
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'zx_golf_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
