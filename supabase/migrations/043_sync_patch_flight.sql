-- ============================================================
-- ZX Golf App — Sync Function Patch for Instance.Flight
-- ============================================================
-- Adds Instance.Flight to sync_upload and sync_download.
-- Full replacement of both functions to include the new column.
-- ============================================================

-- ============================================================
-- 1. SYNC UPLOAD (client → server)
-- ============================================================
CREATE OR REPLACE FUNCTION sync_upload(changes JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_row JSONB;
  v_server_ts TIMESTAMPTZ := NOW();
  v_upload_count INTEGER := 0;
BEGIN
  -- Authenticate.
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- === User ===
  IF changes ? 'User' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'User')
    LOOP
      INSERT INTO "User" (
        "UserID", "DisplayName", "Email", "Timezone", "WeekStartDay",
        "UnitPreferences", "CreatedAt", "UpdatedAt"
      ) VALUES (
        v_user_id, v_row->>'DisplayName',
        COALESCE(v_row->>'Email', v_user_id::TEXT || '@placeholder.local'),
        COALESCE(v_row->>'Timezone', 'UTC'),
        COALESCE((v_row->>'WeekStartDay')::INTEGER, 1),
        COALESCE(v_row->'UnitPreferences', '{}'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts),
        v_server_ts
      )
      ON CONFLICT ("UserID") DO UPDATE SET
        "DisplayName" = EXCLUDED."DisplayName",
        "Email" = EXCLUDED."Email",
        "Timezone" = EXCLUDED."Timezone",
        "WeekStartDay" = EXCLUDED."WeekStartDay",
        "UnitPreferences" = EXCLUDED."UnitPreferences",
        "UpdatedAt" = v_server_ts;
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === UserDevice ===
  IF changes ? 'UserDevice' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserDevice')
    LOOP
      INSERT INTO "UserDevice" (
        "DeviceID", "UserID", "DeviceName", "Platform",
        "AppVersion", "LastSeenAt", "CreatedAt"
      ) VALUES (
        (v_row->>'DeviceID')::UUID, v_user_id,
        v_row->>'DeviceName', v_row->>'Platform',
        v_row->>'AppVersion',
        COALESCE((v_row->>'LastSeenAt')::TIMESTAMPTZ, v_server_ts),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("DeviceID") DO UPDATE SET
        "DeviceName" = EXCLUDED."DeviceName",
        "Platform" = EXCLUDED."Platform",
        "AppVersion" = EXCLUDED."AppVersion",
        "LastSeenAt" = EXCLUDED."LastSeenAt";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === UserClub ===
  IF changes ? 'UserClub' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserClub')
    LOOP
      INSERT INTO "UserClub" (
        "ClubID", "UserID", "ClubType", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'ClubID')::UUID, v_user_id,
        (v_row->>'ClubType')::club_type,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ClubID") DO UPDATE SET
        "ClubType" = EXCLUDED."ClubType", "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === ClubPerformanceProfile ===
  IF changes ? 'ClubPerformanceProfile' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'ClubPerformanceProfile')
    LOOP
      INSERT INTO "ClubPerformanceProfile" (
        "ProfileID", "ClubID", "CarryDistance", "DispersionWidth",
        "DispersionDepth", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'ProfileID')::UUID, (v_row->>'ClubID')::UUID,
        (v_row->>'CarryDistance')::DECIMAL,
        (v_row->>'DispersionWidth')::DECIMAL,
        (v_row->>'DispersionDepth')::DECIMAL,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ProfileID") DO UPDATE SET
        "CarryDistance" = EXCLUDED."CarryDistance",
        "DispersionWidth" = EXCLUDED."DispersionWidth",
        "DispersionDepth" = EXCLUDED."DispersionDepth",
        "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === UserSkillAreaClubMapping ===
  IF changes ? 'UserSkillAreaClubMapping' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserSkillAreaClubMapping')
    LOOP
      INSERT INTO "UserSkillAreaClubMapping" (
        "MappingID", "UserID", "SkillArea", "ClubID", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'MappingID')::UUID, v_user_id,
        (v_row->>'SkillArea')::skill_area,
        (v_row->>'ClubID')::UUID,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MappingID") DO UPDATE SET
        "SkillArea" = EXCLUDED."SkillArea",
        "ClubID" = EXCLUDED."ClubID",
        "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === UserDrillAdoption ===
  IF changes ? 'UserDrillAdoption' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserDrillAdoption')
    LOOP
      INSERT INTO "UserDrillAdoption" (
        "AdoptionID", "UserID", "DrillID", "AdoptedAt", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'AdoptionID')::UUID, v_user_id,
        (v_row->>'DrillID')::UUID,
        COALESCE((v_row->>'AdoptedAt')::TIMESTAMPTZ, v_server_ts),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("UserID", "DrillID") DO UPDATE SET
        "AdoptionID" = EXCLUDED."AdoptionID",
        "AdoptedAt" = EXCLUDED."AdoptedAt",
        "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === Routine ===
  IF changes ? 'Routine' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Routine')
    LOOP
      INSERT INTO "Routine" ("RoutineID", "UserID", "Name", "Slots", "IsDeleted", "CreatedAt")
      VALUES (
        (v_row->>'RoutineID')::UUID, v_user_id, v_row->>'Name',
        COALESCE(v_row->'Slots', '[]'::JSONB),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("RoutineID") DO UPDATE SET
        "Name" = EXCLUDED."Name", "Slots" = EXCLUDED."Slots", "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === Schedule ===
  IF changes ? 'Schedule' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Schedule')
    LOOP
      INSERT INTO "Schedule" ("ScheduleID", "UserID", "Name", "DayAssignments", "IsDeleted", "CreatedAt")
      VALUES (
        (v_row->>'ScheduleID')::UUID, v_user_id, v_row->>'Name',
        COALESCE(v_row->'DayAssignments', '{}'::JSONB),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ScheduleID") DO UPDATE SET
        "Name" = EXCLUDED."Name", "DayAssignments" = EXCLUDED."DayAssignments", "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === CalendarDay ===
  IF changes ? 'CalendarDay' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'CalendarDay')
    LOOP
      INSERT INTO "CalendarDay" ("CalendarDayID", "UserID", "Date", "SlotCapacityPattern", "CreatedAt")
      VALUES (
        (v_row->>'CalendarDayID')::UUID, v_user_id,
        (v_row->>'Date')::DATE,
        COALESCE(v_row->'SlotCapacityPattern', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("CalendarDayID") DO UPDATE SET
        "Date" = EXCLUDED."Date", "SlotCapacityPattern" = EXCLUDED."SlotCapacityPattern";
      v_upload_count := v_upload_count + 1;
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
        v_user_id,
        (v_row->>'CalendarDayDate')::DATE,
        COALESCE(v_row->'OwnedSlots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("RoutineInstanceID") DO UPDATE SET
        "RoutineID" = EXCLUDED."RoutineID",
        "OwnedSlots" = EXCLUDED."OwnedSlots";
      v_upload_count := v_upload_count + 1;
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
        v_user_id,
        (v_row->>'StartDate')::DATE, (v_row->>'EndDate')::DATE,
        COALESCE(v_row->'OwnedSlots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ScheduleInstanceID") DO UPDATE SET
        "ScheduleID" = EXCLUDED."ScheduleID",
        "StartDate" = EXCLUDED."StartDate", "EndDate" = EXCLUDED."EndDate",
        "OwnedSlots" = EXCLUDED."OwnedSlots";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === PracticeBlock ===
  IF changes ? 'PracticeBlock' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'PracticeBlock')
    LOOP
      INSERT INTO "PracticeBlock" (
        "PracticeBlockID", "UserID", "EnvironmentType", "SurfaceType",
        "StartTimestamp", "EndTimestamp", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'PracticeBlockID')::UUID, v_user_id,
        (v_row->>'EnvironmentType')::environment_type,
        CASE WHEN v_row->>'SurfaceType' IS NULL THEN NULL ELSE (v_row->>'SurfaceType')::surface_type END,
        (v_row->>'StartTimestamp')::TIMESTAMPTZ,
        CASE WHEN v_row->>'EndTimestamp' IS NULL THEN NULL ELSE (v_row->>'EndTimestamp')::TIMESTAMPTZ END,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("PracticeBlockID") DO UPDATE SET
        "EnvironmentType" = EXCLUDED."EnvironmentType",
        "SurfaceType" = EXCLUDED."SurfaceType",
        "EndTimestamp" = EXCLUDED."EndTimestamp",
        "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === Session ===
  IF changes ? 'Session' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Session')
    LOOP
      INSERT INTO "Session" (
        "SessionID", "PracticeBlockID", "DrillID",
        "CompletionTimestamp", "SessionDuration", "SessionScore",
        "SourceRoutineID", "SourceRoutineInstanceID",
        "SurfaceType",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'SessionID')::UUID, (v_row->>'PracticeBlockID')::UUID,
        (v_row->>'DrillID')::UUID,
        CASE WHEN v_row->>'CompletionTimestamp' IS NULL THEN NULL ELSE (v_row->>'CompletionTimestamp')::TIMESTAMPTZ END,
        (v_row->>'SessionDuration')::INTEGER,
        (v_row->>'SessionScore')::DECIMAL,
        CASE WHEN v_row->>'SourceRoutineID' IS NULL THEN NULL ELSE (v_row->>'SourceRoutineID')::UUID END,
        CASE WHEN v_row->>'SourceRoutineInstanceID' IS NULL THEN NULL ELSE (v_row->>'SourceRoutineInstanceID')::UUID END,
        CASE WHEN v_row->>'SurfaceType' IS NULL THEN NULL ELSE (v_row->>'SurfaceType')::surface_type END,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SessionID") DO UPDATE SET
        "CompletionTimestamp" = EXCLUDED."CompletionTimestamp",
        "SessionDuration" = EXCLUDED."SessionDuration",
        "SessionScore" = EXCLUDED."SessionScore",
        "SourceRoutineID" = EXCLUDED."SourceRoutineID",
        "SourceRoutineInstanceID" = EXCLUDED."SourceRoutineInstanceID",
        "SurfaceType" = EXCLUDED."SurfaceType",
        "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === Set ===
  IF changes ? 'Set' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Set')
    LOOP
      INSERT INTO "Set" (
        "SetID", "SessionID", "SetIndex", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'SetID')::UUID, (v_row->>'SessionID')::UUID,
        (v_row->>'SetIndex')::INTEGER,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SetID") DO UPDATE SET
        "SetIndex" = EXCLUDED."SetIndex", "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Instance (with ShotShape + ShotEffort + Flight) ===
  IF changes ? 'Instance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Instance')
    LOOP
      INSERT INTO "Instance" (
        "InstanceID", "SetID", "SelectedClub", "RawMetrics", "Timestamp",
        "ResolvedTargetDistance", "ResolvedTargetWidth", "ResolvedTargetDepth",
        "ShotShape", "ShotEffort", "Flight",
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
        (v_row->>'Flight')::INTEGER,
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
        "Flight" = EXCLUDED."Flight",
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
        "SessionID" = EXCLUDED."SessionID",
        "EntryType" = EXCLUDED."EntryType",
        "PositionIndex" = EXCLUDED."PositionIndex";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === EventLog ===
  IF changes ? 'EventLog' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'EventLog')
    LOOP
      INSERT INTO "EventLog" (
        "EventLogID", "UserID", "EventTypeID", "EntityID",
        "OldValue", "NewValue", "CreatedAt"
      ) VALUES (
        (v_row->>'EventLogID')::UUID, v_user_id,
        v_row->>'EventTypeID',
        (v_row->>'EntityID')::UUID,
        v_row->'OldValue', v_row->'NewValue',
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("EventLogID") DO NOTHING;
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  -- === UserTrainingItem ===
  IF changes ? 'UserTrainingItem' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserTrainingItem')
    LOOP
      INSERT INTO "UserTrainingItem" (
        "ItemID", "UserID", "Name", "Category", "Colour", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'ItemID')::UUID, v_user_id,
        v_row->>'Name', v_row->>'Category',
        v_row->>'Colour',
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ItemID") DO UPDATE SET
        "Name" = EXCLUDED."Name",
        "Category" = EXCLUDED."Category",
        "Colour" = EXCLUDED."Colour",
        "IsDeleted" = EXCLUDED."IsDeleted";
      v_upload_count := v_upload_count + 1;
    END LOOP;
  END IF;

  RETURN jsonb_build_object('uploaded', v_upload_count, 'server_ts', v_server_ts);
END;
$$;

-- ============================================================
-- 2. SYNC DOWNLOAD (server → client)
-- ============================================================
CREATE OR REPLACE FUNCTION sync_download(last_sync_timestamp TIMESTAMPTZ DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_changes JSONB := '{}'::JSONB;
  v_rows JSONB;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- === User ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "User" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('User', v_rows); END IF;

  -- === UserDevice ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "UserDevice" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserDevice', v_rows); END IF;

  -- === UserClub ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "UserClub" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserClub', v_rows); END IF;

  -- === ClubPerformanceProfile ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT cp.* FROM "ClubPerformanceProfile" cp
    JOIN "UserClub" uc ON uc."ClubID" = cp."ClubID"
    WHERE uc."UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR cp."UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('ClubPerformanceProfile', v_rows); END IF;

  -- === UserSkillAreaClubMapping ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "UserSkillAreaClubMapping" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserSkillAreaClubMapping', v_rows); END IF;

  -- === Drill (server-authoritative) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "Drill" WHERE "UserID" IS NULL AND "Status" = 'Active' AND "IsDeleted" = false
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Drill', v_rows); END IF;

  -- === UserDrillAdoption ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "UserDrillAdoption" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserDrillAdoption', v_rows); END IF;

  -- === Routine ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "Routine" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Routine', v_rows); END IF;

  -- === Schedule ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "Schedule" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Schedule', v_rows); END IF;

  -- === CalendarDay ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "CalendarDay" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('CalendarDay', v_rows); END IF;

  -- === RoutineInstance ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "RoutineInstance" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('RoutineInstance', v_rows); END IF;

  -- === ScheduleInstance ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "ScheduleInstance" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('ScheduleInstance', v_rows); END IF;

  -- === PracticeBlock ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "PracticeBlock" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('PracticeBlock', v_rows); END IF;

  -- === Session ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT s."SessionID", s."PracticeBlockID", s."DrillID",
           s."CompletionTimestamp", s."SessionDuration", s."SessionScore",
           s."SourceRoutineID", s."SourceRoutineInstanceID",
           s."SurfaceType",
           s."IsDeleted", s."CreatedAt", s."UpdatedAt"
    FROM "Session" s JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE pb."UserID" = v_user_id AND (last_sync_timestamp IS NULL OR s."UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Session', v_rows); END IF;

  -- === Set ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT st."SetID", st."SessionID", st."SetIndex", st."IsDeleted", st."CreatedAt", st."UpdatedAt"
    FROM "Set" st JOIN "Session" s ON s."SessionID" = st."SessionID"
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE pb."UserID" = v_user_id AND (last_sync_timestamp IS NULL OR st."UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Set', v_rows); END IF;

  -- === Instance (with ShotShape + ShotEffort + Flight) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT i."InstanceID", i."SetID", i."SelectedClub", i."RawMetrics", i."Timestamp",
           i."ResolvedTargetDistance", i."ResolvedTargetWidth", i."ResolvedTargetDepth",
           i."ShotShape", i."ShotEffort", i."Flight",
           i."IsDeleted", i."CreatedAt", i."UpdatedAt"
    FROM "Instance" i JOIN "Set" st ON st."SetID" = i."SetID"
    JOIN "Session" s ON s."SessionID" = st."SessionID"
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE pb."UserID" = v_user_id AND (last_sync_timestamp IS NULL OR i."UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Instance', v_rows); END IF;

  -- === PracticeEntry ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT pe.* FROM "PracticeEntry" pe
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = pe."PracticeBlockID"
    WHERE pb."UserID" = v_user_id AND (last_sync_timestamp IS NULL OR pe."UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('PracticeEntry', v_rows); END IF;

  -- === EventLog ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "EventLog" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "CreatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('EventLog', v_rows); END IF;

  -- === UserTrainingItem ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (SELECT * FROM "UserTrainingItem" WHERE "UserID" = v_user_id
    AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserTrainingItem', v_rows); END IF;

  RETURN v_changes;
END;
$$;
