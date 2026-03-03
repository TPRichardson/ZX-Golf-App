-- ============================================================
-- ZX Golf App — Database Schema (Postgres / Supabase)
-- Migration: 001_create_schema.sql
-- Version: TD-02v.a7
-- ============================================================
-- This migration creates the complete V1 schema.
-- Harmonised with: Section 6 (6v.b7), Section 16 (16v.a5), TD-01 (TD-01v.a4), TD-03 (TD-03v.a5).
-- ============================================================

-- gen_random_uuid() is a Postgres 13+ built-in function.
-- Supabase runs Postgres 15. No extension required.

-- ============================================================
-- HELPER: set_updated_at trigger function
-- Per TD-01 §2.1: UpdatedAt is always server-assigned.
-- Client never writes UpdatedAt directly.
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW."UpdatedAt" = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- STABLE ENUMERATIONS (Section 16, §16.1.2)
-- Fixed values enforced via Postgres ENUM types.
-- Adding a value requires a schema migration.
-- ============================================================

CREATE TYPE skill_area AS ENUM (
  'Driving', 'Irons', 'Putting', 'Pitching', 'Chipping', 'Woods', 'Bunkers'
);

CREATE TYPE drill_type AS ENUM (
  'TechniqueBlock', 'Transition', 'Pressure'
);

CREATE TYPE scoring_mode AS ENUM (
  'Shared', 'MultiOutput'
);

CREATE TYPE input_mode AS ENUM (
  'GridCell', 'ContinuousMeasurement', 'RawDataEntry', 'BinaryHitMiss'
);

CREATE TYPE grid_type AS ENUM (
  'ThreeByThree', 'OneByThree', 'ThreeByOne'
);

CREATE TYPE club_type AS ENUM (
  'Driver',
  'W1', 'W2', 'W3', 'W4', 'W5', 'W6', 'W7', 'W8', 'W9',
  'H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7', 'H8', 'H9',
  'i1', 'i2', 'i3', 'i4', 'i5', 'i6', 'i7', 'i8', 'i9',
  'PW', 'AW', 'GW', 'SW', 'UW', 'LW',
  'Chipper', 'Putter'
);

CREATE TYPE drill_origin AS ENUM (
  'System', 'UserCustom'
);

CREATE TYPE drill_status AS ENUM (
  'Active', 'Retired', 'Deleted'
);

CREATE TYPE session_status AS ENUM (
  'Active', 'Closed', 'Discarded'
);

CREATE TYPE club_selection_mode AS ENUM (
  'Random', 'Guided', 'UserLed'
);

CREATE TYPE target_distance_mode AS ENUM (
  'Fixed', 'ClubCarry', 'PercentageOfClubCarry'
);

CREATE TYPE target_size_mode AS ENUM (
  'Fixed', 'PercentageOfTargetDistance'
);

CREATE TYPE completion_state AS ENUM (
  'Incomplete', 'CompletedLinked', 'CompletedManual'
);

CREATE TYPE slot_owner_type AS ENUM (
  'Manual', 'RoutineInstance', 'ScheduleInstance'
);

CREATE TYPE closure_type AS ENUM (
  'Manual', 'AutoClosed'
);

CREATE TYPE adoption_status AS ENUM (
  'Active', 'Retired'
);

CREATE TYPE schedule_app_mode AS ENUM (
  'List', 'DayPlanning'
);

CREATE TYPE practice_entry_type AS ENUM (
  'PendingDrill', 'ActiveSession', 'CompletedSession'
);

CREATE TYPE user_club_status AS ENUM (
  'Active', 'Retired'
);

CREATE TYPE routine_status AS ENUM (
  'Active', 'Retired', 'Deleted'
);

CREATE TYPE schedule_status AS ENUM (
  'Active', 'Retired', 'Deleted'
);

-- ============================================================
-- REFERENCE TABLES (Section 16, §16.1.2, §16.1.4)
-- Extensible enumerations enforced via FK lookup.
-- ============================================================

CREATE TABLE "EventTypeRef" (
  "EventTypeID"   TEXT PRIMARY KEY,
  "Name"          TEXT NOT NULL,
  "Description"   TEXT
);

CREATE TABLE "MetricSchema" (
  "MetricSchemaID"        TEXT PRIMARY KEY,
  "Name"                  TEXT NOT NULL,
  "InputMode"             input_mode NOT NULL,
  "HardMinInput"          DECIMAL,
  "HardMaxInput"          DECIMAL,
  "ValidationRules"       JSONB,
  "ScoringAdapterBinding" TEXT NOT NULL
);

CREATE TABLE "SubskillRef" (
  "SubskillID"    TEXT PRIMARY KEY,
  "SkillArea"     skill_area NOT NULL,
  "Name"          TEXT NOT NULL,
  "Allocation"    INTEGER NOT NULL
);

-- ============================================================
-- SOURCE TABLES (Section 16, §16.1.3)
-- Authoritative user data. Single source of truth.
-- ============================================================

-- User (Section 6 §6.2, Section 10)
CREATE TABLE "User" (
  "UserID"            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "DisplayName"       TEXT,
  "Email"             TEXT,
  "Timezone"          TEXT NOT NULL DEFAULT 'UTC',
  "WeekStartDay"      INTEGER NOT NULL DEFAULT 1 CHECK ("WeekStartDay" BETWEEN 0 AND 6),
  "UnitPreferences"   JSONB NOT NULL DEFAULT '{}',
  "CreatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("UnitPreferences") = 'object')
);

-- Drill (Section 6 §6.2)
CREATE TABLE "Drill" (
  "DrillID"                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"                  UUID REFERENCES "User"("UserID"),  -- NULL for System Drills
  "Name"                    TEXT NOT NULL,
  "SkillArea"               skill_area NOT NULL,
  "DrillType"               drill_type NOT NULL,
  "ScoringMode"             scoring_mode,
  "InputMode"               input_mode NOT NULL,
  "MetricSchemaID"          TEXT NOT NULL REFERENCES "MetricSchema"("MetricSchemaID"),
  "GridType"                grid_type,
  "SubskillMapping"         JSONB NOT NULL,  -- Array of 1-2 SubskillIDs
  "ClubSelectionMode"       club_selection_mode,
  "TargetDistanceMode"      target_distance_mode,
  "TargetDistanceValue"     DECIMAL,
  "TargetSizeMode"          target_size_mode,
  "TargetSizeWidth"         DECIMAL,
  "TargetSizeDepth"         DECIMAL,
  "RequiredSetCount"        INTEGER NOT NULL DEFAULT 1 CHECK ("RequiredSetCount" >= 1),
  "RequiredAttemptsPerSet"  INTEGER CHECK ("RequiredAttemptsPerSet" >= 1),  -- NULL = open-ended
  "Anchors"                 JSONB NOT NULL DEFAULT '{}',
  "Origin"                  drill_origin NOT NULL,
  "Status"                  drill_status NOT NULL DEFAULT 'Active',
  "IsDeleted"               BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F1: ScoringMode NULL iff TechniqueBlock (duration-only, no scored output).
  CHECK (
    ("DrillType" = 'TechniqueBlock' AND "ScoringMode" IS NULL) OR
    ("DrillType" IN ('Transition', 'Pressure') AND "ScoringMode" IS NOT NULL)
  ),
  -- F3: JSONB structural type guards.
  CHECK (jsonb_typeof("SubskillMapping") = 'array'),
  CHECK (jsonb_typeof("Anchors") = 'object'),
  -- F7: Prevent Active + soft-deleted contradiction.
  CHECK (NOT ("IsDeleted" = TRUE AND "Status" = 'Active'))
);

-- PracticeBlock (Section 6 §6.2)
CREATE TABLE "PracticeBlock" (
  "PracticeBlockID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"            UUID NOT NULL REFERENCES "User"("UserID"),
  "SourceRoutineID"   UUID,  -- FK to Routine, nullable; set below after Routine created
  "DrillOrder"        JSONB NOT NULL DEFAULT '[]',
  "StartTimestamp"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "EndTimestamp"      TIMESTAMPTZ,
  "ClosureType"       closure_type,
  "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("DrillOrder") = 'array')
);

-- Session (Section 6 §6.2)
CREATE TABLE "Session" (
  "SessionID"             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "DrillID"               UUID NOT NULL REFERENCES "Drill"("DrillID"),
  "PracticeBlockID"       UUID NOT NULL REFERENCES "PracticeBlock"("PracticeBlockID"),
  "CompletionTimestamp"   TIMESTAMPTZ,
  "Status"                session_status NOT NULL DEFAULT 'Active',
  "IntegrityFlag"         BOOLEAN NOT NULL DEFAULT FALSE,
  "IntegritySuppressed"   BOOLEAN NOT NULL DEFAULT FALSE,
  "UserDeclaration"       TEXT,
  "SessionDuration"       INTEGER,  -- Seconds
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Set (Section 6 §6.2)
CREATE TABLE "Set" (
  "SetID"       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "SessionID"   UUID NOT NULL REFERENCES "Session"("SessionID"),
  "SetIndex"    INTEGER NOT NULL CHECK ("SetIndex" >= 1),
  "IsDeleted"   BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F8: Prevent duplicate set ordering within a Session.
  UNIQUE ("SessionID", "SetIndex")
);

-- Instance (Section 6 §6.2)
CREATE TABLE "Instance" (
  "InstanceID"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "SetID"                   UUID NOT NULL REFERENCES "Set"("SetID"),
  "SelectedClub"            UUID NOT NULL,  -- FK to UserClub, added below
  "RawMetrics"              JSONB NOT NULL,
  "Timestamp"               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "ResolvedTargetDistance"  DECIMAL,
  "ResolvedTargetWidth"     DECIMAL,
  "ResolvedTargetDepth"     DECIMAL,
  "IsDeleted"               BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PracticeEntry (Section 13, §13.3)
CREATE TABLE "PracticeEntry" (
  "PracticeEntryID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "PracticeBlockID"   UUID NOT NULL REFERENCES "PracticeBlock"("PracticeBlockID"),
  "DrillID"           UUID NOT NULL REFERENCES "Drill"("DrillID"),
  "SessionID"         UUID REFERENCES "Session"("SessionID"),
  "EntryType"         practice_entry_type NOT NULL DEFAULT 'PendingDrill',
  "PositionIndex"     INTEGER NOT NULL CHECK ("PositionIndex" >= 0),
  "CreatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F8: Prevent duplicate position ordering within a PracticeBlock.
  UNIQUE ("PracticeBlockID", "PositionIndex")
);

-- UserDrillAdoption (Section 6 §6.2)
CREATE TABLE "UserDrillAdoption" (
  "UserDrillAdoptionID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"                UUID NOT NULL REFERENCES "User"("UserID"),
  "DrillID"               UUID NOT NULL REFERENCES "Drill"("DrillID"),
  "Status"                adoption_status NOT NULL DEFAULT 'Active',
  "IsDeleted"             BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE ("UserID", "DrillID")
);

-- UserClub (Section 9 §9.11.1)
CREATE TABLE "UserClub" (
  "ClubID"      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"      UUID NOT NULL REFERENCES "User"("UserID"),
  "ClubType"    club_type NOT NULL,
  "Make"        TEXT,
  "Model"       TEXT,
  "Loft"        DECIMAL,
  "Status"      user_club_status NOT NULL DEFAULT 'Active',
  "CreatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Now add the FK from Instance.SelectedClub to UserClub
ALTER TABLE "Instance"
  ADD CONSTRAINT "fk_instance_selectedclub"
  FOREIGN KEY ("SelectedClub") REFERENCES "UserClub"("ClubID");

-- ClubPerformanceProfile (Section 9 §9.5)
CREATE TABLE "ClubPerformanceProfile" (
  "ProfileID"         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "ClubID"            UUID NOT NULL REFERENCES "UserClub"("ClubID"),
  "EffectiveFromDate" DATE NOT NULL,
  "CarryDistance"      DECIMAL,
  "DispersionLeft"    DECIMAL,
  "DispersionRight"   DECIMAL,
  "DispersionShort"   DECIMAL,
  "DispersionLong"    DECIMAL,
  "CreatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW()
  -- Insert-only, time-versioned (Section 16, §16.6.1).
  -- UpdatedAt included for sync uniformity (never updated in practice).
);

-- UserSkillAreaClubMapping (Section 9 §9.2)
CREATE TABLE "UserSkillAreaClubMapping" (
  "MappingID"     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"        UUID NOT NULL REFERENCES "User"("UserID"),
  "ClubType"      club_type NOT NULL,
  "SkillArea"     skill_area NOT NULL,
  "IsMandatory"   BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW()
  -- Created/deleted only, not edited. UpdatedAt for sync uniformity.
);

-- ============================================================
-- PLANNING TABLES (Section 16, §16.1.5)
-- JSON array columns for Slots and entries.
-- ============================================================

-- Routine (Section 6 §6.2, Section 8 §8.1.2)
CREATE TABLE "Routine" (
  "RoutineID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"      UUID NOT NULL REFERENCES "User"("UserID"),
  "Name"        TEXT NOT NULL,
  "Entries"     JSONB NOT NULL DEFAULT '[]',
  "Status"      routine_status NOT NULL DEFAULT 'Active',
  "IsDeleted"   BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("Entries") = 'array'),
  -- F7: Prevent Active + soft-deleted contradiction.
  CHECK (NOT ("IsDeleted" = TRUE AND "Status" = 'Active'))
);

-- Now add FK from PracticeBlock.SourceRoutineID
ALTER TABLE "PracticeBlock"
  ADD CONSTRAINT "fk_practiceblock_routine"
  FOREIGN KEY ("SourceRoutineID") REFERENCES "Routine"("RoutineID")
  ON DELETE SET NULL;

-- Schedule (Section 6 §6.2, Section 8 §8.1.3)
CREATE TABLE "Schedule" (
  "ScheduleID"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"            UUID NOT NULL REFERENCES "User"("UserID"),
  "Name"              TEXT NOT NULL,
  "ApplicationMode"   schedule_app_mode NOT NULL,
  "Entries"           JSONB NOT NULL DEFAULT '[]',  -- List mode entries OR DayPlanning template days
  "Status"            schedule_status NOT NULL DEFAULT 'Active',
  "IsDeleted"         BOOLEAN NOT NULL DEFAULT FALSE,
  "CreatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("Entries") = 'array'),
  -- F7: Prevent Active + soft-deleted contradiction.
  CHECK (NOT ("IsDeleted" = TRUE AND "Status" = 'Active'))
);

-- CalendarDay (Section 8 §8.13.1)
CREATE TABLE "CalendarDay" (
  "CalendarDayID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"          UUID NOT NULL REFERENCES "User"("UserID"),
  "Date"            DATE NOT NULL,
  "SlotCapacity"    INTEGER NOT NULL DEFAULT 0 CHECK ("SlotCapacity" >= 0),
  "Slots"           JSONB NOT NULL DEFAULT '[]',
  "CreatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("Slots") = 'array'),
  UNIQUE ("UserID", "Date")
);

-- RoutineInstance (Section 8 §8.2.4)
CREATE TABLE "RoutineInstance" (
  "RoutineInstanceID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "RoutineID"           UUID REFERENCES "Routine"("RoutineID") ON DELETE SET NULL,
  "UserID"              UUID NOT NULL REFERENCES "User"("UserID"),
  "CalendarDayDate"     DATE NOT NULL,
  "OwnedSlots"          JSONB NOT NULL DEFAULT '[]',
  "CreatedAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("OwnedSlots") = 'array')
);

-- ScheduleInstance (Section 8 §8.2.5)
CREATE TABLE "ScheduleInstance" (
  "ScheduleInstanceID"  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "ScheduleID"          UUID REFERENCES "Schedule"("ScheduleID") ON DELETE SET NULL,
  "UserID"              UUID NOT NULL REFERENCES "User"("UserID"),
  "StartDate"           DATE NOT NULL,
  "EndDate"             DATE NOT NULL,
  "OwnedSlots"          JSONB NOT NULL DEFAULT '[]',
  "CreatedAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("OwnedSlots") = 'array'),
  -- F9: EndDate must not precede StartDate.
  CHECK ("EndDate" >= "StartDate")
);

-- ============================================================
-- MATERIALISED TABLES (Section 16, §16.1.6)
-- Derived scoring cache. Replaceable — not source of truth.
-- ============================================================

CREATE TABLE "MaterialisedWindowState" (
  "UserID"          UUID NOT NULL REFERENCES "User"("UserID"),
  "SkillArea"       skill_area NOT NULL,
  "Subskill"        TEXT NOT NULL,
  "PracticeType"    drill_type NOT NULL CHECK ("PracticeType" IN ('Transition', 'Pressure')),
  "Entries"         JSONB NOT NULL DEFAULT '[]',
  "TotalOccupancy"  DECIMAL NOT NULL DEFAULT 0,
  "WeightedSum"     DECIMAL NOT NULL DEFAULT 0,
  "WindowAverage"   DECIMAL NOT NULL DEFAULT 0,
  -- F3: JSONB structural type guard.
  CHECK (jsonb_typeof("Entries") = 'array'),
  PRIMARY KEY ("UserID", "SkillArea", "Subskill", "PracticeType")
);

CREATE TABLE "MaterialisedSubskillScore" (
  "UserID"              UUID NOT NULL REFERENCES "User"("UserID"),
  "SkillArea"           skill_area NOT NULL,
  "Subskill"            TEXT NOT NULL,
  "TransitionAverage"   DECIMAL NOT NULL DEFAULT 0,
  "PressureAverage"     DECIMAL NOT NULL DEFAULT 0,
  "WeightedAverage"     DECIMAL NOT NULL DEFAULT 0,
  "SubskillPoints"      DECIMAL NOT NULL DEFAULT 0,
  "Allocation"          INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY ("UserID", "SkillArea", "Subskill")
);

CREATE TABLE "MaterialisedSkillAreaScore" (
  "UserID"          UUID NOT NULL REFERENCES "User"("UserID"),
  "SkillArea"       skill_area NOT NULL,
  "SkillAreaScore"  DECIMAL NOT NULL DEFAULT 0,
  "Allocation"      INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY ("UserID", "SkillArea")
);

CREATE TABLE "MaterialisedOverallScore" (
  "UserID"        UUID PRIMARY KEY REFERENCES "User"("UserID"),
  "OverallScore"  DECIMAL NOT NULL DEFAULT 0
);

-- ============================================================
-- SYSTEM TABLES (Section 16, §16.1.7)
-- ============================================================

-- EventLog (Section 6 §6.2, Section 7 §7.9)
CREATE TABLE "EventLog" (
  "EventLogID"          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"              UUID NOT NULL REFERENCES "User"("UserID"),
  "DeviceID"            UUID,  -- FK to UserDevice, nullable
  "EventTypeID"         TEXT NOT NULL REFERENCES "EventTypeRef"("EventTypeID"),
  "Timestamp"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "AffectedEntityIDs"   JSONB,
  "AffectedSubskills"   JSONB,
  "Metadata"            JSONB,
  "CreatedAt"           TIMESTAMPTZ NOT NULL DEFAULT NOW()
  -- No UpdatedAt: append-only (Section 6 §6.2)
);

-- UserDevice (Section 17)
CREATE TABLE "UserDevice" (
  "DeviceID"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"          UUID NOT NULL REFERENCES "User"("UserID"),
  "DeviceLabel"     TEXT,
  "RegisteredAt"    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "LastSyncAt"      TIMESTAMPTZ,
  "IsDeleted"       BOOLEAN NOT NULL DEFAULT FALSE,
  "UpdatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- FK for EventLog.DeviceID
ALTER TABLE "EventLog"
  ADD CONSTRAINT "fk_eventlog_device"
  FOREIGN KEY ("DeviceID") REFERENCES "UserDevice"("DeviceID")
  ON DELETE SET NULL;

-- UserScoringLock (Section 16, §16.4.3)
CREATE TABLE "UserScoringLock" (
  "UserID"          UUID PRIMARY KEY REFERENCES "User"("UserID"),
  "IsLocked"        BOOLEAN NOT NULL DEFAULT FALSE,
  "LockedAt"        TIMESTAMPTZ,
  "LockExpiresAt"   TIMESTAMPTZ
);

-- SystemMaintenanceLock (Section 16, §16.4.4)
CREATE TABLE "SystemMaintenanceLock" (
  "LockID"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "IsActive"      BOOLEAN NOT NULL DEFAULT FALSE,
  "ActivatedAt"   TIMESTAMPTZ,
  "Reason"        TEXT
);

-- Migration tracking
CREATE TABLE "MigrationLog" (
  "MigrationID"       SERIAL PRIMARY KEY,
  "SequenceNumber"    INTEGER NOT NULL UNIQUE,
  "Filename"          TEXT NOT NULL,
  "AppliedAt"         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "ExecutionDurationMs" INTEGER
);

-- ============================================================
-- TRIGGERS: server-assigned UpdatedAt (TD-01 §2.1)
-- Applied to all synced tables with UpdatedAt column.
-- ============================================================

CREATE TRIGGER trg_user_updated_at BEFORE UPDATE ON "User"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_drill_updated_at BEFORE UPDATE ON "Drill"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_practiceblock_updated_at BEFORE UPDATE ON "PracticeBlock"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_session_updated_at BEFORE UPDATE ON "Session"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON "Set"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_instance_updated_at BEFORE UPDATE ON "Instance"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_practiceentry_updated_at BEFORE UPDATE ON "PracticeEntry"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_userdrilladoption_updated_at BEFORE UPDATE ON "UserDrillAdoption"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_userclub_updated_at BEFORE UPDATE ON "UserClub"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_routine_updated_at BEFORE UPDATE ON "Routine"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_schedule_updated_at BEFORE UPDATE ON "Schedule"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_calendarday_updated_at BEFORE UPDATE ON "CalendarDay"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_clubperformanceprofile_updated_at BEFORE UPDATE ON "ClubPerformanceProfile"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_userskillareachubmapping_updated_at BEFORE UPDATE ON "UserSkillAreaClubMapping"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_routineinstance_updated_at BEFORE UPDATE ON "RoutineInstance"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_scheduleinstance_updated_at BEFORE UPDATE ON "ScheduleInstance"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_userdevice_updated_at BEFORE UPDATE ON "UserDevice"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- INDEXES (Section 16, §16.3)
-- ============================================================

-- Core Query Indexes (§16.3.2)
CREATE INDEX ix_session_drill_completion ON "Session" ("DrillID", "CompletionTimestamp" DESC);
CREATE INDEX ix_session_practiceblock ON "Session" ("PracticeBlockID");
CREATE INDEX ix_session_status ON "Session" ("Status") WHERE "Status" = 'Active';
CREATE INDEX ix_instance_set ON "Instance" ("SetID");
CREATE INDEX ix_instance_timestamp ON "Instance" ("SetID", "Timestamp" ASC);
CREATE INDEX ix_set_session ON "Set" ("SessionID", "SetIndex" ASC);
CREATE INDEX ix_pb_user_start ON "PracticeBlock" ("UserID", "StartTimestamp" DESC);
CREATE INDEX ix_pe_practiceblock_pos ON "PracticeEntry" ("PracticeBlockID", "PositionIndex" ASC);
CREATE INDEX ix_pe_session ON "PracticeEntry" ("SessionID") WHERE "SessionID" IS NOT NULL;

-- Equipment & Mapping Indexes (§16.3.3)
CREATE INDEX ix_userclub_user ON "UserClub" ("UserID");
CREATE INDEX ix_clubprofile_club_date ON "ClubPerformanceProfile" ("ClubID", "EffectiveFromDate" DESC);
CREATE INDEX ix_mapping_user_skillarea ON "UserSkillAreaClubMapping" ("UserID", "SkillArea");
CREATE INDEX ix_instance_selectedclub ON "Instance" ("SelectedClub");

-- Planning Indexes (§16.3.4)
-- CalendarDay has UNIQUE("UserID", "Date") which creates an index
CREATE INDEX ix_ri_user_date ON "RoutineInstance" ("UserID", "CalendarDayDate");
CREATE INDEX ix_si_user_daterange ON "ScheduleInstance" ("UserID", "StartDate", "EndDate");
CREATE INDEX ix_routine_user ON "Routine" ("UserID");
CREATE INDEX ix_schedule_user ON "Schedule" ("UserID");
CREATE INDEX ix_drill_user_skillarea ON "Drill" ("UserID", "SkillArea", "Status");
CREATE INDEX ix_drill_system ON "Drill" ("Origin", "Status") WHERE "Origin" = 'System';
CREATE INDEX ix_adoption_user ON "UserDrillAdoption" ("UserID", "Status");

-- System Indexes (§16.3.5)
CREATE INDEX ix_eventlog_user_timestamp ON "EventLog" ("UserID", "Timestamp" DESC);
CREATE INDEX ix_eventlog_type_timestamp ON "EventLog" ("EventTypeID", "Timestamp" DESC);
CREATE INDEX ix_eventlog_archival ON "EventLog" ("Timestamp" ASC);
CREATE INDEX ix_userdevice_userid ON "UserDevice" ("UserID");
CREATE INDEX ix_eventlog_deviceid ON "EventLog" ("DeviceID");

-- Sync Download Indexes (TD-03 §5.3.3)
-- Composite (UserID, UpdatedAt) indexes on parent synced tables for efficient
-- delta download queries: WHERE UserID = auth.uid() AND UpdatedAt > last_sync.
-- Child tables (Session, Set, Instance, ClubPerformanceProfile) lack a UserID
-- column; their download queries JOIN to the parent table for RLS scoping,
-- with UpdatedAt on the child supporting the timestamp range scan.
CREATE INDEX ix_sync_practiceblock ON "PracticeBlock" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_drill ON "Drill" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_userdrilladoption ON "UserDrillAdoption" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_userclub ON "UserClub" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_usamc ON "UserSkillAreaClubMapping" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_calendarday ON "CalendarDay" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_routine ON "Routine" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_schedule ON "Schedule" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_routineinstance ON "RoutineInstance" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_scheduleinstance ON "ScheduleInstance" ("UserID", "UpdatedAt");
CREATE INDEX ix_sync_userdevice ON "UserDevice" ("UserID", "UpdatedAt");
-- Child tables: UpdatedAt-only index for range scan in JOIN-based download queries.
CREATE INDEX ix_sync_session ON "Session" ("UpdatedAt");
CREATE INDEX ix_sync_set ON "Set" ("UpdatedAt");
CREATE INDEX ix_sync_instance ON "Instance" ("UpdatedAt");
CREATE INDEX ix_sync_clubprofile ON "ClubPerformanceProfile" ("UpdatedAt");
-- EventLog: append-only, uses CreatedAt instead of UpdatedAt (TD-02 §3.5).
CREATE INDEX ix_sync_eventlog ON "EventLog" ("UserID", "CreatedAt");

-- Foreign Key Indexes (§16.3.6)
-- Covers FK columns not already leading a composite index above.
CREATE INDEX ix_session_drillid ON "Session" ("DrillID");
CREATE INDEX ix_pe_practiceblockid ON "PracticeEntry" ("PracticeBlockID");
CREATE INDEX ix_pe_drillid ON "PracticeEntry" ("DrillID");
CREATE INDEX ix_uda_drillid ON "UserDrillAdoption" ("DrillID");
CREATE INDEX ix_cpp_clubid ON "ClubPerformanceProfile" ("ClubID");
CREATE INDEX ix_drill_metricschema ON "Drill" ("MetricSchemaID");
CREATE INDEX ix_ri_routineid ON "RoutineInstance" ("RoutineID");
CREATE INDEX ix_si_scheduleid ON "ScheduleInstance" ("ScheduleID");

-- Materialised Table Indexes (§16.3.8)
-- Primary keys serve as unique indexes on materialised tables.

-- ============================================================
-- ROW-LEVEL SECURITY (TD-01 §3.2)
-- Enforced at Postgres level. Application bugs cannot bypass.
-- ============================================================

ALTER TABLE "User" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Drill" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PracticeBlock" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Session" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Set" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Instance" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PracticeEntry" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "UserDrillAdoption" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "UserClub" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ClubPerformanceProfile" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "UserSkillAreaClubMapping" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Routine" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "Schedule" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "CalendarDay" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "RoutineInstance" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "ScheduleInstance" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "EventLog" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "UserDevice" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "UserScoringLock" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MaterialisedWindowState" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MaterialisedSubskillScore" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MaterialisedSkillAreaScore" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MaterialisedOverallScore" ENABLE ROW LEVEL SECURITY;

-- Direct UserID tables: standard pattern with write enforcement
CREATE POLICY user_self ON "User" FOR ALL
  USING (auth.uid() = "UserID")
  WITH CHECK (auth.uid() = "UserID");

-- Drill: users read System Drills (NULL UserID) + own drills; write own drills only
CREATE POLICY drill_read ON "Drill" FOR SELECT
  USING ("UserID" = auth.uid() OR "UserID" IS NULL);
CREATE POLICY drill_write ON "Drill" FOR INSERT
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY drill_update ON "Drill" FOR UPDATE
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY drill_delete ON "Drill" FOR DELETE
  USING ("UserID" = auth.uid());

CREATE POLICY pb_owner ON "PracticeBlock" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY uda_owner ON "UserDrillAdoption" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY uc_owner ON "UserClub" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY usamc_owner ON "UserSkillAreaClubMapping" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY routine_owner ON "Routine" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY schedule_owner ON "Schedule" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY calday_owner ON "CalendarDay" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY ri_owner ON "RoutineInstance" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY si_owner ON "ScheduleInstance" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY eventlog_owner ON "EventLog" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY device_owner ON "UserDevice" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY lock_owner ON "UserScoringLock" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY mws_owner ON "MaterialisedWindowState" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY mss_owner ON "MaterialisedSubskillScore" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY msas_owner ON "MaterialisedSkillAreaScore" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());
CREATE POLICY mos_owner ON "MaterialisedOverallScore" FOR ALL
  USING ("UserID" = auth.uid())
  WITH CHECK ("UserID" = auth.uid());

-- Child tables: join through parent chain for RLS
-- Session → PracticeBlock → UserID
CREATE POLICY session_owner ON "Session" FOR ALL
  USING (EXISTS (
    SELECT 1 FROM "PracticeBlock" pb
    WHERE pb."PracticeBlockID" = "Session"."PracticeBlockID"
    AND pb."UserID" = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "PracticeBlock" pb
    WHERE pb."PracticeBlockID" = "Session"."PracticeBlockID"
    AND pb."UserID" = auth.uid()
  ));

-- Set → Session → PracticeBlock → UserID
CREATE POLICY set_owner ON "Set" FOR ALL
  USING (EXISTS (
    SELECT 1 FROM "Session" s
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE s."SessionID" = "Set"."SessionID"
    AND pb."UserID" = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "Session" s
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE s."SessionID" = "Set"."SessionID"
    AND pb."UserID" = auth.uid()
  ));

-- Instance → Set → Session → PracticeBlock → UserID
CREATE POLICY instance_owner ON "Instance" FOR ALL
  USING (EXISTS (
    SELECT 1 FROM "Set" st
    JOIN "Session" s ON s."SessionID" = st."SessionID"
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE st."SetID" = "Instance"."SetID"
    AND pb."UserID" = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "Set" st
    JOIN "Session" s ON s."SessionID" = st."SessionID"
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE st."SetID" = "Instance"."SetID"
    AND pb."UserID" = auth.uid()
  ));

-- PracticeEntry → PracticeBlock → UserID
CREATE POLICY pe_owner ON "PracticeEntry" FOR ALL
  USING (EXISTS (
    SELECT 1 FROM "PracticeBlock" pb
    WHERE pb."PracticeBlockID" = "PracticeEntry"."PracticeBlockID"
    AND pb."UserID" = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "PracticeBlock" pb
    WHERE pb."PracticeBlockID" = "PracticeEntry"."PracticeBlockID"
    AND pb."UserID" = auth.uid()
  ));

-- ClubPerformanceProfile → UserClub → UserID
CREATE POLICY cpp_owner ON "ClubPerformanceProfile" FOR ALL
  USING (EXISTS (
    SELECT 1 FROM "UserClub" uc
    WHERE uc."ClubID" = "ClubPerformanceProfile"."ClubID"
    AND uc."UserID" = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM "UserClub" uc
    WHERE uc."ClubID" = "ClubPerformanceProfile"."ClubID"
    AND uc."UserID" = auth.uid()
  ));

-- Reference tables: read-only for all authenticated users
ALTER TABLE "EventTypeRef" ENABLE ROW LEVEL SECURITY;
CREATE POLICY eventtype_read ON "EventTypeRef" FOR SELECT USING (auth.uid() IS NOT NULL);

ALTER TABLE "MetricSchema" ENABLE ROW LEVEL SECURITY;
CREATE POLICY metricschema_read ON "MetricSchema" FOR SELECT USING (auth.uid() IS NOT NULL);

ALTER TABLE "SubskillRef" ENABLE ROW LEVEL SECURITY;
CREATE POLICY subskillref_read ON "SubskillRef" FOR SELECT USING (auth.uid() IS NOT NULL);

-- SystemMaintenanceLock: read-only for authenticated users
ALTER TABLE "SystemMaintenanceLock" ENABLE ROW LEVEL SECURITY;
CREATE POLICY sml_read ON "SystemMaintenanceLock" FOR SELECT USING (auth.uid() IS NOT NULL);

-- ============================================================
-- Record this migration
-- ============================================================
INSERT INTO "MigrationLog" ("SequenceNumber", "Filename")
VALUES (1, '001_create_schema.sql')
ON CONFLICT ("SequenceNumber") DO NOTHING;
