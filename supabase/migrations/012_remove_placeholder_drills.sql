-- ============================================================
-- ZX Golf App — Clean Slate: Remove All User & Drill Data
-- Migration: 012_remove_placeholder_drills.sql
-- ============================================================
-- Wipes all user-generated and placeholder data from Supabase.
-- Preserves reference tables (EventTypeRef, SubskillRef, MetricSchema)
-- and system tables (SystemMaintenanceLock, MigrationLog).
-- ============================================================

-- Delete bottom-up to respect FK constraints.

-- 1. Matrix data (deepest children first)
DELETE FROM "MatrixAttempt";
DELETE FROM "MatrixCell";
DELETE FROM "MatrixAxisValue";
DELETE FROM "MatrixAxis";
DELETE FROM "SnapshotClub";
DELETE FROM "PerformanceSnapshot";
DELETE FROM "MatrixRun";

-- 2. Deepest practice children
DELETE FROM "Instance";
DELETE FROM "Set";

-- 3. Session + PracticeEntry + PracticeBlock
DELETE FROM "PracticeEntry";
DELETE FROM "Session";
DELETE FROM "PracticeBlock";

-- 4. Scoring materialised tables
DELETE FROM "MaterialisedOverallScore";
DELETE FROM "MaterialisedSkillAreaScore";
DELETE FROM "MaterialisedSubskillScore";
DELETE FROM "MaterialisedWindowState";

-- 5. Club data
DELETE FROM "ClubPerformanceProfile";
DELETE FROM "UserSkillAreaClubMapping";
DELETE FROM "UserClub";

-- 6. Planning data
DELETE FROM "ScheduleInstance";
DELETE FROM "RoutineInstance";
DELETE FROM "CalendarDay";
DELETE FROM "Schedule";
DELETE FROM "Routine";

-- 7. Drill adoption + drills
DELETE FROM "UserDrillAdoption";
DELETE FROM "Drill";

-- 8. Event log + devices + locks
DELETE FROM "EventLog";
DELETE FROM "UserDevice";
DELETE FROM "UserScoringLock";

-- 9. Users
DELETE FROM "User";

-- ============================================================
-- Record this migration
-- ============================================================
INSERT INTO "MigrationLog" ("SequenceNumber", "Filename")
VALUES (12, '012_remove_placeholder_drills.sql')
ON CONFLICT ("SequenceNumber") DO NOTHING;
