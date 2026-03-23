-- ============================================================
-- Fix: UserDrillAdoption upsert ON CONFLICT targets PK only,
-- but the table has UNIQUE ("UserID", "DrillID"). When a drill
-- is re-adopted locally with a new UUID, the INSERT hits the
-- unique constraint instead of the PK conflict path.
--
-- Fix: use delete-then-insert pattern (same as CalendarDay).
-- Only the UserDrillAdoption section changes from 027.
-- ============================================================

-- Patch sync_upload only — sync_download unchanged.

CREATE OR REPLACE FUNCTION sync_upload(
  schema_version TEXT,
  device_id TEXT,
  changes JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_server_ts TIMESTAMPTZ := NOW();
  v_rejected JSONB := '[]'::JSONB;
  v_row JSONB;
  v_existing RECORD;
BEGIN
  IF schema_version != '1' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SCHEMA_VERSION_MISMATCH',
      'error_message', format('Server expects schema version 1, got %s', schema_version),
      'server_timestamp', v_server_ts
    );
  END IF;

  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'AUTH_REQUIRED',
      'error_message', 'Authentication required for sync',
      'server_timestamp', v_server_ts
    );
  END IF;

  -- === User ===
  IF changes ? 'User' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'User')
    LOOP
      INSERT INTO "User" ("UserID", "DisplayName", "Email", "Timezone", "WeekStartDay", "UnitPreferences", "CreatedAt")
      VALUES (
        v_user_id, v_row->>'DisplayName', v_row->>'Email',
        COALESCE(v_row->>'Timezone', 'UTC'), COALESCE((v_row->>'WeekStartDay')::INTEGER, 1),
        COALESCE(v_row->'UnitPreferences', '{}'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("UserID") DO UPDATE SET
        "DisplayName" = EXCLUDED."DisplayName", "Email" = EXCLUDED."Email",
        "Timezone" = EXCLUDED."Timezone", "WeekStartDay" = EXCLUDED."WeekStartDay",
        "UnitPreferences" = EXCLUDED."UnitPreferences";
    END LOOP;
  END IF;

  -- === Drill (with WindowCap) ===
  IF changes ? 'Drill' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Drill')
    LOOP
      SELECT "SkillArea", "DrillType", "InputMode", "MetricSchemaID", "SubskillMapping", "Origin"
      INTO v_existing FROM "Drill" WHERE "DrillID" = (v_row->>'DrillID')::UUID;
      IF FOUND THEN
        IF v_existing."SkillArea"::TEXT != v_row->>'SkillArea'
           OR v_existing."DrillType"::TEXT != v_row->>'DrillType'
           OR v_existing."InputMode"::TEXT != v_row->>'InputMode'
           OR v_existing."MetricSchemaID" != v_row->>'MetricSchemaID'
           OR v_existing."SubskillMapping"::TEXT != (v_row->'SubskillMapping')::TEXT
           OR v_existing."Origin"::TEXT != v_row->>'Origin'
        THEN
          v_rejected := v_rejected || jsonb_build_array(jsonb_build_object(
            'table', 'Drill', 'id', v_row->>'DrillID', 'reason', 'STRUCTURAL_IMMUTABILITY_VIOLATION'));
          CONTINUE;
        END IF;
      END IF;
      INSERT INTO "Drill" (
        "DrillID", "UserID", "Name", "SkillArea", "DrillType", "ScoringMode",
        "InputMode", "MetricSchemaID", "GridType", "SubskillMapping",
        "ClubSelectionMode", "TargetDistanceMode", "TargetDistanceValue",
        "TargetSizeMode", "TargetSizeWidth", "TargetSizeDepth",
        "RequiredSetCount", "RequiredAttemptsPerSet", "Anchors",
        "Target", "Description", "TargetDistanceUnit", "TargetSizeUnit",
        "RequiredEquipment", "RecommendedEquipment", "WindowCap",
        "Origin", "Status", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'DrillID')::UUID,
        CASE WHEN v_row->>'UserID' IS NULL THEN NULL ELSE (v_row->>'UserID')::UUID END,
        v_row->>'Name', (v_row->>'SkillArea')::skill_area, (v_row->>'DrillType')::drill_type,
        CASE WHEN v_row->>'ScoringMode' IS NULL THEN NULL ELSE (v_row->>'ScoringMode')::scoring_mode END,
        (v_row->>'InputMode')::input_mode, v_row->>'MetricSchemaID',
        CASE WHEN v_row->>'GridType' IS NULL THEN NULL ELSE (v_row->>'GridType')::grid_type END,
        COALESCE(v_row->'SubskillMapping', '[]'::JSONB),
        CASE WHEN v_row->>'ClubSelectionMode' IS NULL THEN NULL ELSE (v_row->>'ClubSelectionMode')::club_selection_mode END,
        CASE WHEN v_row->>'TargetDistanceMode' IS NULL THEN NULL ELSE (v_row->>'TargetDistanceMode')::target_distance_mode END,
        (v_row->>'TargetDistanceValue')::DECIMAL,
        CASE WHEN v_row->>'TargetSizeMode' IS NULL THEN NULL ELSE (v_row->>'TargetSizeMode')::target_size_mode END,
        (v_row->>'TargetSizeWidth')::DECIMAL, (v_row->>'TargetSizeDepth')::DECIMAL,
        COALESCE((v_row->>'RequiredSetCount')::INTEGER, 1), (v_row->>'RequiredAttemptsPerSet')::INTEGER,
        COALESCE(v_row->'Anchors', '{}'::JSONB), (v_row->>'Target')::DECIMAL,
        v_row->>'Description', v_row->>'TargetDistanceUnit', v_row->>'TargetSizeUnit',
        COALESCE(v_row->'RequiredEquipment', '[]'::JSONB),
        COALESCE(v_row->'RecommendedEquipment', '[]'::JSONB),
        (v_row->>'WindowCap')::INTEGER,
        (v_row->>'Origin')::drill_origin, COALESCE((v_row->>'Status')::drill_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("DrillID") DO UPDATE SET
        "Name" = EXCLUDED."Name", "ScoringMode" = EXCLUDED."ScoringMode",
        "GridType" = EXCLUDED."GridType", "ClubSelectionMode" = EXCLUDED."ClubSelectionMode",
        "TargetDistanceMode" = EXCLUDED."TargetDistanceMode", "TargetDistanceValue" = EXCLUDED."TargetDistanceValue",
        "TargetSizeMode" = EXCLUDED."TargetSizeMode", "TargetSizeWidth" = EXCLUDED."TargetSizeWidth",
        "TargetSizeDepth" = EXCLUDED."TargetSizeDepth", "RequiredSetCount" = EXCLUDED."RequiredSetCount",
        "RequiredAttemptsPerSet" = EXCLUDED."RequiredAttemptsPerSet", "Anchors" = EXCLUDED."Anchors",
        "Target" = EXCLUDED."Target", "Description" = EXCLUDED."Description",
        "TargetDistanceUnit" = EXCLUDED."TargetDistanceUnit", "TargetSizeUnit" = EXCLUDED."TargetSizeUnit",
        "RequiredEquipment" = EXCLUDED."RequiredEquipment", "RecommendedEquipment" = EXCLUDED."RecommendedEquipment",
        "WindowCap" = EXCLUDED."WindowCap",
        "Status" = EXCLUDED."Status", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === PracticeBlock ===
  IF changes ? 'PracticeBlock' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'PracticeBlock')
    LOOP
      INSERT INTO "PracticeBlock" (
        "PracticeBlockID", "UserID", "SourceRoutineID", "DrillOrder",
        "StartTimestamp", "EndTimestamp", "ClosureType", "EnvironmentType", "SurfaceType",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'PracticeBlockID')::UUID, v_user_id,
        CASE WHEN v_row->>'SourceRoutineID' IS NULL THEN NULL ELSE (v_row->>'SourceRoutineID')::UUID END,
        COALESCE(v_row->'DrillOrder', '[]'::JSONB),
        (v_row->>'StartTimestamp')::TIMESTAMPTZ, (v_row->>'EndTimestamp')::TIMESTAMPTZ,
        CASE WHEN v_row->>'ClosureType' IS NULL THEN NULL ELSE (v_row->>'ClosureType')::closure_type END,
        CASE WHEN v_row->>'EnvironmentType' IS NULL THEN NULL ELSE (v_row->>'EnvironmentType')::environment_type END,
        CASE WHEN v_row->>'SurfaceType' IS NULL THEN NULL ELSE (v_row->>'SurfaceType')::surface_type END,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("PracticeBlockID") DO UPDATE SET
        "SourceRoutineID" = EXCLUDED."SourceRoutineID", "DrillOrder" = EXCLUDED."DrillOrder",
        "StartTimestamp" = EXCLUDED."StartTimestamp", "EndTimestamp" = EXCLUDED."EndTimestamp",
        "ClosureType" = EXCLUDED."ClosureType", "EnvironmentType" = EXCLUDED."EnvironmentType",
        "SurfaceType" = EXCLUDED."SurfaceType", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Session ===
  IF changes ? 'Session' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Session')
    LOOP
      INSERT INTO "Session" (
        "SessionID", "DrillID", "PracticeBlockID", "CompletionTimestamp",
        "Status", "IntegrityFlag", "IntegritySuppressed", "EnvironmentType", "SurfaceType",
        "UserDeclaration", "SessionDuration", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'SessionID')::UUID, (v_row->>'DrillID')::UUID, (v_row->>'PracticeBlockID')::UUID,
        (v_row->>'CompletionTimestamp')::TIMESTAMPTZ,
        COALESCE((v_row->>'Status')::session_status, 'Active'),
        COALESCE((v_row->>'IntegrityFlag')::BOOLEAN, false),
        COALESCE((v_row->>'IntegritySuppressed')::BOOLEAN, false),
        CASE WHEN v_row->>'EnvironmentType' IS NULL THEN NULL ELSE (v_row->>'EnvironmentType')::environment_type END,
        CASE WHEN v_row->>'SurfaceType' IS NULL THEN NULL ELSE (v_row->>'SurfaceType')::surface_type END,
        v_row->>'UserDeclaration', (v_row->>'SessionDuration')::INTEGER,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SessionID") DO UPDATE SET
        "CompletionTimestamp" = EXCLUDED."CompletionTimestamp", "Status" = EXCLUDED."Status",
        "IntegrityFlag" = EXCLUDED."IntegrityFlag", "IntegritySuppressed" = EXCLUDED."IntegritySuppressed",
        "EnvironmentType" = EXCLUDED."EnvironmentType", "SurfaceType" = EXCLUDED."SurfaceType",
        "UserDeclaration" = EXCLUDED."UserDeclaration", "SessionDuration" = EXCLUDED."SessionDuration",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Set ===
  IF changes ? 'Set' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Set')
    LOOP
      INSERT INTO "Set" ("SetID", "SessionID", "SetIndex", "IsDeleted", "CreatedAt")
      VALUES (
        (v_row->>'SetID')::UUID, (v_row->>'SessionID')::UUID,
        (v_row->>'SetIndex')::INTEGER,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SetID") DO UPDATE SET
        "SetIndex" = EXCLUDED."SetIndex", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Instance (with ShotShape + ShotEffort) ===
  IF changes ? 'Instance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Instance')
    LOOP
      INSERT INTO "Instance" (
        "InstanceID", "SetID", "SelectedClub", "RawMetrics", "Timestamp",
        "ResolvedTargetDistance", "ResolvedTargetWidth", "ResolvedTargetDepth",
        "ShotShape", "ShotEffort",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'InstanceID')::UUID, (v_row->>'SetID')::UUID,
        CASE WHEN v_row->>'SelectedClub' IS NULL THEN NULL ELSE (v_row->>'SelectedClub')::UUID END,
        COALESCE(v_row->'RawMetrics', '{}'::JSONB),
        (v_row->>'Timestamp')::TIMESTAMPTZ,
        (v_row->>'ResolvedTargetDistance')::DECIMAL,
        (v_row->>'ResolvedTargetWidth')::DECIMAL,
        (v_row->>'ResolvedTargetDepth')::DECIMAL,
        v_row->>'ShotShape',
        (v_row->>'ShotEffort')::INTEGER,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("InstanceID") DO UPDATE SET
        "SelectedClub" = EXCLUDED."SelectedClub",
        "RawMetrics" = EXCLUDED."RawMetrics",
        "Timestamp" = EXCLUDED."Timestamp",
        "ResolvedTargetDistance" = EXCLUDED."ResolvedTargetDistance",
        "ResolvedTargetWidth" = EXCLUDED."ResolvedTargetWidth",
        "ResolvedTargetDepth" = EXCLUDED."ResolvedTargetDepth",
        "ShotShape" = EXCLUDED."ShotShape",
        "ShotEffort" = EXCLUDED."ShotEffort",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === PracticeEntry ===
  IF changes ? 'PracticeEntry' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'PracticeEntry')
    LOOP
      INSERT INTO "PracticeEntry" (
        "PracticeEntryID", "PracticeBlockID", "DrillID", "SessionID",
        "EntryType", "PositionIndex", "CreatedAt"
      ) VALUES (
        (v_row->>'PracticeEntryID')::UUID, (v_row->>'PracticeBlockID')::UUID,
        (v_row->>'DrillID')::UUID,
        CASE WHEN v_row->>'SessionID' IS NULL THEN NULL ELSE (v_row->>'SessionID')::UUID END,
        COALESCE((v_row->>'EntryType')::practice_entry_type, 'PendingDrill'),
        (v_row->>'PositionIndex')::INTEGER,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("PracticeEntryID") DO UPDATE SET
        "DrillID" = EXCLUDED."DrillID", "SessionID" = EXCLUDED."SessionID",
        "EntryType" = EXCLUDED."EntryType", "PositionIndex" = EXCLUDED."PositionIndex";
    END LOOP;
  END IF;

  -- === UserDrillAdoption (FIX: handle dual-constraint like CalendarDay) ===
  -- Delete any existing row with the same (UserID, DrillID) but different PK first,
  -- then upsert on PK as normal. This prevents the unique constraint violation.
  IF changes ? 'UserDrillAdoption' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserDrillAdoption')
    LOOP
      DELETE FROM "UserDrillAdoption"
      WHERE "UserID" = v_user_id
        AND "DrillID" = (v_row->>'DrillID')::UUID
        AND "UserDrillAdoptionID" != (v_row->>'UserDrillAdoptionID')::UUID;

      INSERT INTO "UserDrillAdoption" (
        "UserDrillAdoptionID", "UserID", "DrillID", "Status", "HasUnseenUpdate", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'UserDrillAdoptionID')::UUID, v_user_id, (v_row->>'DrillID')::UUID,
        COALESCE((v_row->>'Status')::adoption_status, 'Active'),
        COALESCE((v_row->>'HasUnseenUpdate')::BOOLEAN, false),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("UserDrillAdoptionID") DO UPDATE SET
        "Status" = EXCLUDED."Status", "HasUnseenUpdate" = EXCLUDED."HasUnseenUpdate",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === UserClub ===
  IF changes ? 'UserClub' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserClub')
    LOOP
      INSERT INTO "UserClub" ("ClubID", "UserID", "ClubType", "Make", "Model", "Loft", "Status", "CreatedAt")
      VALUES (
        (v_row->>'ClubID')::UUID, v_user_id, (v_row->>'ClubType')::club_type,
        v_row->>'Make', v_row->>'Model', (v_row->>'Loft')::DECIMAL,
        COALESCE((v_row->>'Status')::user_club_status, 'Active'),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ClubID") DO UPDATE SET
        "ClubType" = EXCLUDED."ClubType", "Make" = EXCLUDED."Make",
        "Model" = EXCLUDED."Model", "Loft" = EXCLUDED."Loft", "Status" = EXCLUDED."Status";
    END LOOP;
  END IF;

  -- === UserTrainingItem ===
  IF changes ? 'UserTrainingItem' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserTrainingItem')
    LOOP
      INSERT INTO "UserTrainingItem" (
        "ItemID", "UserID", "Category", "SkillAreas", "Name", "Properties", "LinkedClubID", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'ItemID')::UUID, v_user_id, v_row->>'Category',
        COALESCE(v_row->'SkillAreas', '[]'::JSONB), v_row->>'Name',
        COALESCE(v_row->'Properties', '{}'::JSONB),
        CASE WHEN v_row->>'LinkedClubID' IS NULL THEN NULL ELSE (v_row->>'LinkedClubID')::UUID END,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ItemID") DO UPDATE SET
        "Category" = EXCLUDED."Category", "SkillAreas" = EXCLUDED."SkillAreas",
        "Name" = EXCLUDED."Name", "Properties" = EXCLUDED."Properties",
        "LinkedClubID" = EXCLUDED."LinkedClubID", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === ClubPerformanceProfile ===
  IF changes ? 'ClubPerformanceProfile' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'ClubPerformanceProfile')
    LOOP
      INSERT INTO "ClubPerformanceProfile" (
        "ProfileID", "ClubID", "EffectiveFromDate",
        "CarryDistance", "DispersionLeft", "DispersionRight",
        "DispersionShort", "DispersionLong", "CreatedAt"
      ) VALUES (
        (v_row->>'ProfileID')::UUID, (v_row->>'ClubID')::UUID, (v_row->>'EffectiveFromDate')::DATE,
        (v_row->>'CarryDistance')::DECIMAL, (v_row->>'DispersionLeft')::DECIMAL,
        (v_row->>'DispersionRight')::DECIMAL, (v_row->>'DispersionShort')::DECIMAL,
        (v_row->>'DispersionLong')::DECIMAL,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ProfileID") DO UPDATE SET
        "EffectiveFromDate" = EXCLUDED."EffectiveFromDate", "CarryDistance" = EXCLUDED."CarryDistance",
        "DispersionLeft" = EXCLUDED."DispersionLeft", "DispersionRight" = EXCLUDED."DispersionRight",
        "DispersionShort" = EXCLUDED."DispersionShort", "DispersionLong" = EXCLUDED."DispersionLong";
    END LOOP;
  END IF;

  -- === UserSkillAreaClubMapping ===
  IF changes ? 'UserSkillAreaClubMapping' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserSkillAreaClubMapping')
    LOOP
      INSERT INTO "UserSkillAreaClubMapping" (
        "MappingID", "UserID", "ClubType", "SkillArea", "IsMandatory", "CreatedAt"
      ) VALUES (
        (v_row->>'MappingID')::UUID, v_user_id,
        (v_row->>'ClubType')::club_type, (v_row->>'SkillArea')::skill_area,
        COALESCE((v_row->>'IsMandatory')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MappingID") DO UPDATE SET
        "ClubType" = EXCLUDED."ClubType", "SkillArea" = EXCLUDED."SkillArea",
        "IsMandatory" = EXCLUDED."IsMandatory";
    END LOOP;
  END IF;

  -- === Routine ===
  IF changes ? 'Routine' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Routine')
    LOOP
      INSERT INTO "Routine" ("RoutineID", "UserID", "Name", "Entries", "Status", "IsDeleted", "CreatedAt")
      VALUES (
        (v_row->>'RoutineID')::UUID, v_user_id, v_row->>'Name',
        COALESCE(v_row->'Entries', '[]'::JSONB),
        COALESCE((v_row->>'Status')::routine_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("RoutineID") DO UPDATE SET
        "Name" = EXCLUDED."Name", "Entries" = EXCLUDED."Entries",
        "Status" = EXCLUDED."Status", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Schedule ===
  IF changes ? 'Schedule' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Schedule')
    LOOP
      INSERT INTO "Schedule" (
        "ScheduleID", "UserID", "Name", "ApplicationMode", "Entries", "Status", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'ScheduleID')::UUID, v_user_id, v_row->>'Name',
        (v_row->>'ApplicationMode')::schedule_app_mode,
        COALESCE(v_row->'Entries', '[]'::JSONB),
        COALESCE((v_row->>'Status')::schedule_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ScheduleID") DO UPDATE SET
        "Name" = EXCLUDED."Name", "ApplicationMode" = EXCLUDED."ApplicationMode",
        "Entries" = EXCLUDED."Entries", "Status" = EXCLUDED."Status", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === CalendarDay ===
  -- Handle both PK conflict (CalendarDayID) and unique (UserID, Date) conflict.
  -- Delete any existing row with the same (UserID, Date) but different ID first.
  IF changes ? 'CalendarDay' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'CalendarDay')
    LOOP
      DELETE FROM "CalendarDay"
      WHERE "UserID" = v_user_id
        AND "Date" = (v_row->>'Date')::DATE
        AND "CalendarDayID" != (v_row->>'CalendarDayID')::UUID;

      INSERT INTO "CalendarDay" ("CalendarDayID", "UserID", "Date", "SlotCapacity", "Slots", "CreatedAt")
      VALUES (
        (v_row->>'CalendarDayID')::UUID, v_user_id, (v_row->>'Date')::DATE,
        COALESCE((v_row->>'SlotCapacity')::INTEGER, 0),
        COALESCE(v_row->'Slots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("CalendarDayID") DO UPDATE SET
        "Date" = EXCLUDED."Date", "SlotCapacity" = EXCLUDED."SlotCapacity", "Slots" = EXCLUDED."Slots";
    END LOOP;
  END IF;

  -- === RoutineInstance ===
  IF changes ? 'RoutineInstance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'RoutineInstance')
    LOOP
      INSERT INTO "RoutineInstance" ("RoutineInstanceID", "RoutineID", "UserID", "CalendarDayDate", "OwnedSlots", "CreatedAt")
      VALUES (
        (v_row->>'RoutineInstanceID')::UUID,
        CASE WHEN v_row->>'RoutineID' IS NULL THEN NULL ELSE (v_row->>'RoutineID')::UUID END,
        v_user_id, (v_row->>'CalendarDayDate')::DATE,
        COALESCE(v_row->'OwnedSlots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("RoutineInstanceID") DO UPDATE SET
        "RoutineID" = EXCLUDED."RoutineID", "CalendarDayDate" = EXCLUDED."CalendarDayDate",
        "OwnedSlots" = EXCLUDED."OwnedSlots";
    END LOOP;
  END IF;

  -- === ScheduleInstance ===
  IF changes ? 'ScheduleInstance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'ScheduleInstance')
    LOOP
      INSERT INTO "ScheduleInstance" (
        "ScheduleInstanceID", "ScheduleID", "UserID", "StartDate", "EndDate", "OwnedSlots", "CreatedAt"
      ) VALUES (
        (v_row->>'ScheduleInstanceID')::UUID,
        CASE WHEN v_row->>'ScheduleID' IS NULL THEN NULL ELSE (v_row->>'ScheduleID')::UUID END,
        v_user_id, (v_row->>'StartDate')::DATE, (v_row->>'EndDate')::DATE,
        COALESCE(v_row->'OwnedSlots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ScheduleInstanceID") DO UPDATE SET
        "ScheduleID" = EXCLUDED."ScheduleID", "StartDate" = EXCLUDED."StartDate",
        "EndDate" = EXCLUDED."EndDate", "OwnedSlots" = EXCLUDED."OwnedSlots";
    END LOOP;
  END IF;

  -- === EventLog (append-only) ===
  IF changes ? 'EventLog' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'EventLog')
    LOOP
      INSERT INTO "EventLog" (
        "EventLogID", "UserID", "DeviceID", "EventTypeID",
        "Timestamp", "AffectedEntityIDs", "AffectedSubskills", "Metadata", "CreatedAt"
      ) VALUES (
        (v_row->>'EventLogID')::UUID, v_user_id, (v_row->>'DeviceID')::UUID, v_row->>'EventTypeID',
        (v_row->>'Timestamp')::TIMESTAMPTZ, v_row->'AffectedEntityIDs',
        v_row->'AffectedSubskills', v_row->'Metadata',
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("EventLogID") DO NOTHING;
    END LOOP;
  END IF;

  -- === UserDevice ===
  IF changes ? 'UserDevice' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserDevice')
    LOOP
      INSERT INTO "UserDevice" ("DeviceID", "UserID", "DeviceLabel", "RegisteredAt", "LastSyncAt", "IsDeleted")
      VALUES (
        (v_row->>'DeviceID')::UUID, v_user_id, v_row->>'DeviceLabel',
        COALESCE((v_row->>'RegisteredAt')::TIMESTAMPTZ, v_server_ts),
        (v_row->>'LastSyncAt')::TIMESTAMPTZ,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false)
      )
      ON CONFLICT ("DeviceID") DO UPDATE SET
        "DeviceLabel" = EXCLUDED."DeviceLabel", "LastSyncAt" = EXCLUDED."LastSyncAt",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  RETURN jsonb_build_object('success', true, 'server_timestamp', v_server_ts, 'rejected_rows', v_rejected);

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('success', false, 'error_code', 'SERVER_ERROR', 'error_message', SQLERRM, 'server_timestamp', NOW());
END;
$$;
