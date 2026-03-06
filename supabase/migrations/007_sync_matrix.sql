-- ============================================================
-- ZX Golf App — Matrix Sync RPCs
-- Migration: 007_sync_matrix.sql
-- Extends sync_upload and sync_download with matrix tables.
-- Replaces both functions to add 7 new table handlers.
-- ============================================================

-- ============================================================
-- UPLOAD — Replace to add matrix table handling
-- ============================================================

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
  -- TD-03 §5.2 — Schema version gate.
  IF schema_version != '1' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SCHEMA_VERSION_MISMATCH',
      'error_message', format('Server expects schema version 1, got %s', schema_version),
      'server_timestamp', v_server_ts
    );
  END IF;

  -- Extract authenticated user ID.
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
        v_user_id,
        v_row->>'DisplayName',
        v_row->>'Email',
        COALESCE(v_row->>'Timezone', 'UTC'),
        COALESCE((v_row->>'WeekStartDay')::INTEGER, 1),
        COALESCE(v_row->'UnitPreferences', '{}'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("UserID") DO UPDATE SET
        "DisplayName" = EXCLUDED."DisplayName",
        "Email" = EXCLUDED."Email",
        "Timezone" = EXCLUDED."Timezone",
        "WeekStartDay" = EXCLUDED."WeekStartDay",
        "UnitPreferences" = EXCLUDED."UnitPreferences";
    END LOOP;
  END IF;

  -- === Drill (immutable after creation — TD-03 §5.2.4) ===
  IF changes ? 'Drill' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Drill')
    LOOP
      SELECT * INTO v_existing FROM "Drill" WHERE "DrillID" = (v_row->>'DrillID')::UUID;
      IF v_existing IS NOT NULL THEN
        IF v_existing."Origin" = 'System' THEN
          v_rejected := v_rejected || jsonb_build_object('table', 'Drill', 'id', v_row->>'DrillID', 'reason', 'System drill is immutable');
          CONTINUE;
        END IF;
      END IF;

      INSERT INTO "Drill" (
        "DrillID", "UserID", "Name", "SkillArea", "DrillType", "InputMode", "Origin",
        "StructuredSetCount", "StructuredRepCount", "MinAnchor", "ScratchAnchor", "ProAnchor",
        "MappedSubskills", "ClubSelectionMode", "ScoringDirection",
        "TargetDistanceMeters", "TargetWidthMeters", "TargetDepthMeters", "TargetSizeMode",
        "Status", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'DrillID')::UUID, v_user_id,
        v_row->>'Name',
        (v_row->>'SkillArea')::skill_area,
        (v_row->>'DrillType')::drill_type,
        (v_row->>'InputMode')::input_mode,
        COALESCE((v_row->>'Origin')::drill_origin, 'UserCustom'),
        (v_row->>'StructuredSetCount')::INTEGER,
        (v_row->>'StructuredRepCount')::INTEGER,
        (v_row->>'MinAnchor')::DECIMAL,
        (v_row->>'ScratchAnchor')::DECIMAL,
        (v_row->>'ProAnchor')::DECIMAL,
        COALESCE(v_row->'MappedSubskills', '[]'::JSONB),
        COALESCE((v_row->>'ClubSelectionMode')::club_selection_mode, 'None'),
        COALESCE((v_row->>'ScoringDirection')::scoring_direction, 'HigherIsBetter'),
        (v_row->>'TargetDistanceMeters')::DECIMAL,
        (v_row->>'TargetWidthMeters')::DECIMAL,
        (v_row->>'TargetDepthMeters')::DECIMAL,
        (v_row->>'TargetSizeMode')::target_size_mode,
        COALESCE((v_row->>'Status')::drill_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("DrillID") DO UPDATE SET
        "Name" = EXCLUDED."Name",
        "MinAnchor" = EXCLUDED."MinAnchor",
        "ScratchAnchor" = EXCLUDED."ScratchAnchor",
        "ProAnchor" = EXCLUDED."ProAnchor",
        "MappedSubskills" = EXCLUDED."MappedSubskills",
        "TargetDistanceMeters" = EXCLUDED."TargetDistanceMeters",
        "TargetWidthMeters" = EXCLUDED."TargetWidthMeters",
        "TargetDepthMeters" = EXCLUDED."TargetDepthMeters",
        "Status" = EXCLUDED."Status",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === PracticeBlock ===
  IF changes ? 'PracticeBlock' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'PracticeBlock')
    LOOP
      INSERT INTO "PracticeBlock" (
        "PracticeBlockID", "UserID", "Status", "StartTimestamp", "EndTimestamp",
        "ClosureType", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'PracticeBlockID')::UUID, v_user_id,
        COALESCE((v_row->>'Status')::practice_block_status, 'Active'),
        COALESCE((v_row->>'StartTimestamp')::TIMESTAMPTZ, v_server_ts),
        (v_row->>'EndTimestamp')::TIMESTAMPTZ,
        (v_row->>'ClosureType')::closure_type,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("PracticeBlockID") DO UPDATE SET
        "Status" = EXCLUDED."Status",
        "EndTimestamp" = EXCLUDED."EndTimestamp",
        "ClosureType" = EXCLUDED."ClosureType",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Session ===
  IF changes ? 'Session' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Session')
    LOOP
      INSERT INTO "Session" (
        "SessionID", "PracticeBlockID", "DrillID", "CompletionTimestamp",
        "SessionScore", "InstanceCount", "Status", "IntegrityFlag",
        "IntegritySuppressed", "UserDeclaration", "SessionDuration",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'SessionID')::UUID, (v_row->>'PracticeBlockID')::UUID,
        (v_row->>'DrillID')::UUID,
        (v_row->>'CompletionTimestamp')::TIMESTAMPTZ,
        (v_row->>'SessionScore')::DECIMAL,
        (v_row->>'InstanceCount')::INTEGER,
        COALESCE((v_row->>'Status')::session_status, 'InProgress'),
        COALESCE((v_row->>'IntegrityFlag')::integrity_flag, 'Clean'),
        COALESCE((v_row->>'IntegritySuppressed')::BOOLEAN, false),
        v_row->>'UserDeclaration',
        (v_row->>'SessionDuration')::INTEGER,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SessionID") DO UPDATE SET
        "CompletionTimestamp" = EXCLUDED."CompletionTimestamp",
        "SessionScore" = EXCLUDED."SessionScore",
        "InstanceCount" = EXCLUDED."InstanceCount",
        "Status" = EXCLUDED."Status",
        "IntegrityFlag" = EXCLUDED."IntegrityFlag",
        "IntegritySuppressed" = EXCLUDED."IntegritySuppressed",
        "UserDeclaration" = EXCLUDED."UserDeclaration",
        "SessionDuration" = EXCLUDED."SessionDuration",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Set (child) ===
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
        "SetIndex" = EXCLUDED."SetIndex",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Instance (child) ===
  IF changes ? 'Instance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Instance')
    LOOP
      INSERT INTO "Instance" (
        "InstanceID", "SetID", "SelectedClub", "RawMetrics", "Timestamp",
        "ResolvedTargetDistance", "ResolvedTargetWidth", "ResolvedTargetDepth",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'InstanceID')::UUID, (v_row->>'SetID')::UUID,
        (v_row->>'SelectedClub')::UUID,
        COALESCE(v_row->'RawMetrics', '{}'::JSONB),
        (v_row->>'Timestamp')::TIMESTAMPTZ,
        (v_row->>'ResolvedTargetDistance')::DECIMAL,
        (v_row->>'ResolvedTargetWidth')::DECIMAL,
        (v_row->>'ResolvedTargetDepth')::DECIMAL,
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
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === PracticeEntry (child) ===
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
        "DrillID" = EXCLUDED."DrillID",
        "SessionID" = EXCLUDED."SessionID",
        "EntryType" = EXCLUDED."EntryType",
        "PositionIndex" = EXCLUDED."PositionIndex";
    END LOOP;
  END IF;

  -- === UserDrillAdoption ===
  IF changes ? 'UserDrillAdoption' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserDrillAdoption')
    LOOP
      INSERT INTO "UserDrillAdoption" (
        "UserDrillAdoptionID", "UserID", "DrillID", "Status", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'UserDrillAdoptionID')::UUID, v_user_id,
        (v_row->>'DrillID')::UUID,
        COALESCE((v_row->>'Status')::adoption_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("UserDrillAdoptionID") DO UPDATE SET
        "Status" = EXCLUDED."Status",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === UserClub ===
  IF changes ? 'UserClub' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserClub')
    LOOP
      INSERT INTO "UserClub" (
        "ClubID", "UserID", "ClubType", "Make", "Model", "Loft", "Status", "CreatedAt"
      ) VALUES (
        (v_row->>'ClubID')::UUID, v_user_id,
        (v_row->>'ClubType')::club_type,
        v_row->>'Make', v_row->>'Model',
        (v_row->>'Loft')::DECIMAL,
        COALESCE((v_row->>'Status')::user_club_status, 'Active'),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ClubID") DO UPDATE SET
        "ClubType" = EXCLUDED."ClubType",
        "Make" = EXCLUDED."Make",
        "Model" = EXCLUDED."Model",
        "Loft" = EXCLUDED."Loft",
        "Status" = EXCLUDED."Status";
    END LOOP;
  END IF;

  -- === ClubPerformanceProfile (child of UserClub) ===
  IF changes ? 'ClubPerformanceProfile' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'ClubPerformanceProfile')
    LOOP
      INSERT INTO "ClubPerformanceProfile" (
        "ProfileID", "ClubID", "EffectiveFromDate",
        "CarryDistance", "DispersionLeft", "DispersionRight",
        "DispersionShort", "DispersionLong", "CreatedAt"
      ) VALUES (
        (v_row->>'ProfileID')::UUID, (v_row->>'ClubID')::UUID,
        (v_row->>'EffectiveFromDate')::DATE,
        (v_row->>'CarryDistance')::DECIMAL,
        (v_row->>'DispersionLeft')::DECIMAL,
        (v_row->>'DispersionRight')::DECIMAL,
        (v_row->>'DispersionShort')::DECIMAL,
        (v_row->>'DispersionLong')::DECIMAL,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ProfileID") DO UPDATE SET
        "EffectiveFromDate" = EXCLUDED."EffectiveFromDate",
        "CarryDistance" = EXCLUDED."CarryDistance",
        "DispersionLeft" = EXCLUDED."DispersionLeft",
        "DispersionRight" = EXCLUDED."DispersionRight",
        "DispersionShort" = EXCLUDED."DispersionShort",
        "DispersionLong" = EXCLUDED."DispersionLong";
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
        (v_row->>'ClubType')::club_type,
        (v_row->>'SkillArea')::skill_area,
        COALESCE((v_row->>'IsMandatory')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MappingID") DO UPDATE SET
        "ClubType" = EXCLUDED."ClubType",
        "SkillArea" = EXCLUDED."SkillArea",
        "IsMandatory" = EXCLUDED."IsMandatory";
    END LOOP;
  END IF;

  -- === Routine ===
  IF changes ? 'Routine' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Routine')
    LOOP
      INSERT INTO "Routine" (
        "RoutineID", "UserID", "Name", "Entries", "Status", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'RoutineID')::UUID, v_user_id,
        v_row->>'Name',
        COALESCE(v_row->'Entries', '[]'::JSONB),
        COALESCE((v_row->>'Status')::routine_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("RoutineID") DO UPDATE SET
        "Name" = EXCLUDED."Name",
        "Entries" = EXCLUDED."Entries",
        "Status" = EXCLUDED."Status",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === Schedule ===
  IF changes ? 'Schedule' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'Schedule')
    LOOP
      INSERT INTO "Schedule" (
        "ScheduleID", "UserID", "Name", "ApplicationMode", "Entries",
        "Status", "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'ScheduleID')::UUID, v_user_id,
        v_row->>'Name',
        (v_row->>'ApplicationMode')::schedule_app_mode,
        COALESCE(v_row->'Entries', '[]'::JSONB),
        COALESCE((v_row->>'Status')::schedule_status, 'Active'),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ScheduleID") DO UPDATE SET
        "Name" = EXCLUDED."Name",
        "ApplicationMode" = EXCLUDED."ApplicationMode",
        "Entries" = EXCLUDED."Entries",
        "Status" = EXCLUDED."Status",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === CalendarDay ===
  IF changes ? 'CalendarDay' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'CalendarDay')
    LOOP
      INSERT INTO "CalendarDay" (
        "CalendarDayID", "UserID", "Date", "SlotCapacity", "Slots", "CreatedAt"
      ) VALUES (
        (v_row->>'CalendarDayID')::UUID, v_user_id,
        (v_row->>'Date')::DATE,
        COALESCE((v_row->>'SlotCapacity')::INTEGER, 0),
        COALESCE(v_row->'Slots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("CalendarDayID") DO UPDATE SET
        "Date" = EXCLUDED."Date",
        "SlotCapacity" = EXCLUDED."SlotCapacity",
        "Slots" = EXCLUDED."Slots";
    END LOOP;
  END IF;

  -- === RoutineInstance ===
  IF changes ? 'RoutineInstance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'RoutineInstance')
    LOOP
      INSERT INTO "RoutineInstance" (
        "RoutineInstanceID", "RoutineID", "UserID", "CalendarDayDate",
        "OwnedSlots", "CreatedAt"
      ) VALUES (
        (v_row->>'RoutineInstanceID')::UUID,
        CASE WHEN v_row->>'RoutineID' IS NULL THEN NULL ELSE (v_row->>'RoutineID')::UUID END,
        v_user_id,
        (v_row->>'CalendarDayDate')::DATE,
        COALESCE(v_row->'OwnedSlots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("RoutineInstanceID") DO UPDATE SET
        "RoutineID" = EXCLUDED."RoutineID",
        "CalendarDayDate" = EXCLUDED."CalendarDayDate",
        "OwnedSlots" = EXCLUDED."OwnedSlots";
    END LOOP;
  END IF;

  -- === ScheduleInstance ===
  IF changes ? 'ScheduleInstance' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'ScheduleInstance')
    LOOP
      INSERT INTO "ScheduleInstance" (
        "ScheduleInstanceID", "ScheduleID", "UserID",
        "StartDate", "EndDate", "OwnedSlots", "CreatedAt"
      ) VALUES (
        (v_row->>'ScheduleInstanceID')::UUID,
        CASE WHEN v_row->>'ScheduleID' IS NULL THEN NULL ELSE (v_row->>'ScheduleID')::UUID END,
        v_user_id,
        (v_row->>'StartDate')::DATE,
        (v_row->>'EndDate')::DATE,
        COALESCE(v_row->'OwnedSlots', '[]'::JSONB),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("ScheduleInstanceID") DO UPDATE SET
        "ScheduleID" = EXCLUDED."ScheduleID",
        "StartDate" = EXCLUDED."StartDate",
        "EndDate" = EXCLUDED."EndDate",
        "OwnedSlots" = EXCLUDED."OwnedSlots";
    END LOOP;
  END IF;

  -- === EventLog (append-only — INSERT only, no UPDATE) ===
  IF changes ? 'EventLog' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'EventLog')
    LOOP
      INSERT INTO "EventLog" (
        "EventLogID", "UserID", "DeviceID", "EventTypeID",
        "Timestamp", "AffectedEntityIDs", "AffectedSubskills",
        "Metadata", "CreatedAt"
      ) VALUES (
        (v_row->>'EventLogID')::UUID, v_user_id,
        v_row->>'DeviceID',
        v_row->>'EventTypeID',
        (v_row->>'Timestamp')::TIMESTAMPTZ,
        v_row->'AffectedEntityIDs',
        v_row->'AffectedSubskills',
        v_row->'Metadata',
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("EventLogID") DO NOTHING;
    END LOOP;
  END IF;

  -- === UserDevice ===
  IF changes ? 'UserDevice' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'UserDevice')
    LOOP
      INSERT INTO "UserDevice" (
        "DeviceID", "UserID", "DeviceLabel", "RegisteredAt",
        "LastSyncAt", "IsDeleted"
      ) VALUES (
        (v_row->>'DeviceID')::UUID, v_user_id,
        v_row->>'DeviceLabel',
        COALESCE((v_row->>'RegisteredAt')::TIMESTAMPTZ, v_server_ts),
        (v_row->>'LastSyncAt')::TIMESTAMPTZ,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false)
      )
      ON CONFLICT ("DeviceID") DO UPDATE SET
        "DeviceLabel" = EXCLUDED."DeviceLabel",
        "LastSyncAt" = EXCLUDED."LastSyncAt",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- ============================================================
  -- MATRIX TABLES (Migration 007)
  -- ============================================================

  -- === MatrixRun ===
  IF changes ? 'MatrixRun' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'MatrixRun')
    LOOP
      INSERT INTO "MatrixRun" (
        "MatrixRunID", "UserID", "MatrixType", "RunNumber", "RunState",
        "StartTimestamp", "EndTimestamp", "SessionShotTarget", "ShotOrderMode",
        "DispersionCaptureEnabled", "MeasurementDevice", "EnvironmentType",
        "SurfaceType", "GreenSpeed", "GreenFirmness",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'MatrixRunID')::UUID, v_user_id,
        (v_row->>'MatrixType')::matrix_type,
        (v_row->>'RunNumber')::INTEGER,
        COALESCE((v_row->>'RunState')::run_state, 'InProgress'),
        COALESCE((v_row->>'StartTimestamp')::TIMESTAMPTZ, v_server_ts),
        (v_row->>'EndTimestamp')::TIMESTAMPTZ,
        (v_row->>'SessionShotTarget')::INTEGER,
        (v_row->>'ShotOrderMode')::shot_order_mode,
        COALESCE((v_row->>'DispersionCaptureEnabled')::BOOLEAN, false),
        v_row->>'MeasurementDevice',
        (v_row->>'EnvironmentType')::environment_type,
        (v_row->>'SurfaceType')::surface_type,
        (v_row->>'GreenSpeed')::DECIMAL,
        (v_row->>'GreenFirmness')::green_firmness,
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MatrixRunID") DO UPDATE SET
        "RunState" = EXCLUDED."RunState",
        "EndTimestamp" = EXCLUDED."EndTimestamp",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === MatrixAxis (child of MatrixRun) ===
  IF changes ? 'MatrixAxis' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'MatrixAxis')
    LOOP
      INSERT INTO "MatrixAxis" (
        "MatrixAxisID", "MatrixRunID", "AxisType", "AxisName", "AxisOrder", "CreatedAt"
      ) VALUES (
        (v_row->>'MatrixAxisID')::UUID, (v_row->>'MatrixRunID')::UUID,
        (v_row->>'AxisType')::axis_type,
        v_row->>'AxisName',
        (v_row->>'AxisOrder')::INTEGER,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MatrixAxisID") DO UPDATE SET
        "AxisType" = EXCLUDED."AxisType",
        "AxisName" = EXCLUDED."AxisName",
        "AxisOrder" = EXCLUDED."AxisOrder";
    END LOOP;
  END IF;

  -- === MatrixAxisValue (child of MatrixAxis) ===
  IF changes ? 'MatrixAxisValue' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'MatrixAxisValue')
    LOOP
      INSERT INTO "MatrixAxisValue" (
        "AxisValueID", "MatrixAxisID", "Label", "SortOrder", "CreatedAt"
      ) VALUES (
        (v_row->>'AxisValueID')::UUID, (v_row->>'MatrixAxisID')::UUID,
        v_row->>'Label',
        (v_row->>'SortOrder')::INTEGER,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("AxisValueID") DO UPDATE SET
        "Label" = EXCLUDED."Label",
        "SortOrder" = EXCLUDED."SortOrder";
    END LOOP;
  END IF;

  -- === MatrixCell (child of MatrixRun) ===
  IF changes ? 'MatrixCell' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'MatrixCell')
    LOOP
      INSERT INTO "MatrixCell" (
        "MatrixCellID", "MatrixRunID", "AxisValueIDs", "ExcludedFromRun", "CreatedAt"
      ) VALUES (
        (v_row->>'MatrixCellID')::UUID, (v_row->>'MatrixRunID')::UUID,
        COALESCE(v_row->'AxisValueIDs', '[]'::JSONB),
        COALESCE((v_row->>'ExcludedFromRun')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MatrixCellID") DO UPDATE SET
        "AxisValueIDs" = EXCLUDED."AxisValueIDs",
        "ExcludedFromRun" = EXCLUDED."ExcludedFromRun";
    END LOOP;
  END IF;

  -- === MatrixAttempt (child of MatrixCell) ===
  IF changes ? 'MatrixAttempt' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'MatrixAttempt')
    LOOP
      INSERT INTO "MatrixAttempt" (
        "MatrixAttemptID", "MatrixCellID", "AttemptTimestamp",
        "CarryDistanceMeters", "TotalDistanceMeters",
        "LeftDeviationMeters", "RightDeviationMeters",
        "RolloutDistanceMeters", "CreatedAt"
      ) VALUES (
        (v_row->>'MatrixAttemptID')::UUID, (v_row->>'MatrixCellID')::UUID,
        COALESCE((v_row->>'AttemptTimestamp')::TIMESTAMPTZ, v_server_ts),
        (v_row->>'CarryDistanceMeters')::DECIMAL,
        (v_row->>'TotalDistanceMeters')::DECIMAL,
        (v_row->>'LeftDeviationMeters')::DECIMAL,
        (v_row->>'RightDeviationMeters')::DECIMAL,
        (v_row->>'RolloutDistanceMeters')::DECIMAL,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("MatrixAttemptID") DO UPDATE SET
        "AttemptTimestamp" = EXCLUDED."AttemptTimestamp",
        "CarryDistanceMeters" = EXCLUDED."CarryDistanceMeters",
        "TotalDistanceMeters" = EXCLUDED."TotalDistanceMeters",
        "LeftDeviationMeters" = EXCLUDED."LeftDeviationMeters",
        "RightDeviationMeters" = EXCLUDED."RightDeviationMeters",
        "RolloutDistanceMeters" = EXCLUDED."RolloutDistanceMeters";
    END LOOP;
  END IF;

  -- === PerformanceSnapshot ===
  IF changes ? 'PerformanceSnapshot' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'PerformanceSnapshot')
    LOOP
      INSERT INTO "PerformanceSnapshot" (
        "SnapshotID", "UserID", "MatrixRunID", "MatrixType",
        "IsPrimary", "Label", "SnapshotTimestamp",
        "IsDeleted", "CreatedAt"
      ) VALUES (
        (v_row->>'SnapshotID')::UUID, v_user_id,
        CASE WHEN v_row->>'MatrixRunID' IS NULL THEN NULL ELSE (v_row->>'MatrixRunID')::UUID END,
        (v_row->>'MatrixType')::matrix_type,
        COALESCE((v_row->>'IsPrimary')::BOOLEAN, false),
        v_row->>'Label',
        COALESCE((v_row->>'SnapshotTimestamp')::TIMESTAMPTZ, v_server_ts),
        COALESCE((v_row->>'IsDeleted')::BOOLEAN, false),
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SnapshotID") DO UPDATE SET
        "MatrixType" = EXCLUDED."MatrixType",
        "IsPrimary" = EXCLUDED."IsPrimary",
        "Label" = EXCLUDED."Label",
        "IsDeleted" = EXCLUDED."IsDeleted";
    END LOOP;
  END IF;

  -- === SnapshotClub (child of PerformanceSnapshot) ===
  IF changes ? 'SnapshotClub' THEN
    FOR v_row IN SELECT * FROM jsonb_array_elements(changes->'SnapshotClub')
    LOOP
      INSERT INTO "SnapshotClub" (
        "SnapshotClubID", "SnapshotID", "ClubID",
        "CarryDistanceMeters", "TotalDistanceMeters",
        "DispersionLeftMeters", "DispersionRightMeters",
        "RolloutDistanceMeters", "CreatedAt"
      ) VALUES (
        (v_row->>'SnapshotClubID')::UUID, (v_row->>'SnapshotID')::UUID,
        (v_row->>'ClubID')::UUID,
        (v_row->>'CarryDistanceMeters')::DECIMAL,
        (v_row->>'TotalDistanceMeters')::DECIMAL,
        (v_row->>'DispersionLeftMeters')::DECIMAL,
        (v_row->>'DispersionRightMeters')::DECIMAL,
        (v_row->>'RolloutDistanceMeters')::DECIMAL,
        COALESCE((v_row->>'CreatedAt')::TIMESTAMPTZ, v_server_ts)
      )
      ON CONFLICT ("SnapshotClubID") DO UPDATE SET
        "CarryDistanceMeters" = EXCLUDED."CarryDistanceMeters",
        "TotalDistanceMeters" = EXCLUDED."TotalDistanceMeters",
        "DispersionLeftMeters" = EXCLUDED."DispersionLeftMeters",
        "DispersionRightMeters" = EXCLUDED."DispersionRightMeters",
        "RolloutDistanceMeters" = EXCLUDED."RolloutDistanceMeters";
    END LOOP;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'server_timestamp', v_server_ts,
    'rejected_rows', v_rejected
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'SERVER_ERROR',
    'error_message', SQLERRM,
    'server_timestamp', NOW()
  );
END;
$$;


-- ============================================================
-- DOWNLOAD — Replace to add matrix table handling
-- ============================================================

CREATE OR REPLACE FUNCTION sync_download(
  schema_version TEXT,
  last_sync_timestamp TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_server_ts TIMESTAMPTZ := NOW();
  v_changes JSONB := '{}'::JSONB;
  v_rows JSONB;
BEGIN
  -- TD-03 §5.2 — Schema version gate.
  IF schema_version != '1' THEN
    RETURN jsonb_build_object(
      'success', false,
      'error_code', 'SCHEMA_VERSION_MISMATCH',
      'error_message', format('Server expects schema version 1, got %s', schema_version),
      'server_timestamp', v_server_ts
    );
  END IF;

  -- Extract authenticated user ID.
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
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "UserID", "DisplayName", "Email", "Timezone", "WeekStartDay",
           "UnitPreferences", "CreatedAt", "UpdatedAt"
    FROM "User"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('User', v_rows); END IF;

  -- === Drill ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "DrillID", "UserID", "Name", "SkillArea", "DrillType", "InputMode", "Origin",
           "StructuredSetCount", "StructuredRepCount", "MinAnchor", "ScratchAnchor", "ProAnchor",
           "MappedSubskills", "ClubSelectionMode", "ScoringDirection",
           "TargetDistanceMeters", "TargetWidthMeters", "TargetDepthMeters", "TargetSizeMode",
           "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "Drill"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Drill', v_rows); END IF;

  -- === PracticeBlock ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "PracticeBlockID", "UserID", "Status", "StartTimestamp", "EndTimestamp",
           "ClosureType", "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "PracticeBlock"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('PracticeBlock', v_rows); END IF;

  -- === Session (child — JOIN through PracticeBlock) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT s."SessionID", s."PracticeBlockID", s."DrillID",
           s."CompletionTimestamp", s."SessionScore", s."InstanceCount",
           s."Status", s."IntegrityFlag", s."IntegritySuppressed",
           s."UserDeclaration", s."SessionDuration",
           s."IsDeleted", s."CreatedAt", s."UpdatedAt"
    FROM "Session" s
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE pb."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR s."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Session', v_rows); END IF;

  -- === Set (child — JOIN through Session → PracticeBlock) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT st."SetID", st."SessionID", st."SetIndex",
           st."IsDeleted", st."CreatedAt", st."UpdatedAt"
    FROM "Set" st
    JOIN "Session" s ON s."SessionID" = st."SessionID"
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE pb."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR st."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Set', v_rows); END IF;

  -- === Instance (child — JOIN through Set → Session → PracticeBlock) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT i."InstanceID", i."SetID", i."SelectedClub", i."RawMetrics",
           i."Timestamp", i."ResolvedTargetDistance", i."ResolvedTargetWidth",
           i."ResolvedTargetDepth", i."IsDeleted", i."CreatedAt", i."UpdatedAt"
    FROM "Instance" i
    JOIN "Set" st ON st."SetID" = i."SetID"
    JOIN "Session" s ON s."SessionID" = st."SessionID"
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = s."PracticeBlockID"
    WHERE pb."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR i."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Instance', v_rows); END IF;

  -- === PracticeEntry (child — JOIN through PracticeBlock) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT pe."PracticeEntryID", pe."PracticeBlockID", pe."DrillID",
           pe."SessionID", pe."EntryType", pe."PositionIndex",
           pe."CreatedAt", pe."UpdatedAt"
    FROM "PracticeEntry" pe
    JOIN "PracticeBlock" pb ON pb."PracticeBlockID" = pe."PracticeBlockID"
    WHERE pb."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR pe."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('PracticeEntry', v_rows); END IF;

  -- === UserDrillAdoption ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "UserDrillAdoptionID", "UserID", "DrillID", "Status",
           "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "UserDrillAdoption"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserDrillAdoption', v_rows); END IF;

  -- === UserClub ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "ClubID", "UserID", "ClubType", "Make", "Model", "Loft",
           "Status", "CreatedAt", "UpdatedAt"
    FROM "UserClub"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserClub', v_rows); END IF;

  -- === ClubPerformanceProfile (child — JOIN through UserClub) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT cpp."ProfileID", cpp."ClubID", cpp."EffectiveFromDate",
           cpp."CarryDistance", cpp."DispersionLeft", cpp."DispersionRight",
           cpp."DispersionShort", cpp."DispersionLong",
           cpp."CreatedAt", cpp."UpdatedAt"
    FROM "ClubPerformanceProfile" cpp
    JOIN "UserClub" uc ON uc."ClubID" = cpp."ClubID"
    WHERE uc."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR cpp."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('ClubPerformanceProfile', v_rows); END IF;

  -- === UserSkillAreaClubMapping ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "MappingID", "UserID", "ClubType", "SkillArea", "IsMandatory",
           "CreatedAt", "UpdatedAt"
    FROM "UserSkillAreaClubMapping"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserSkillAreaClubMapping', v_rows); END IF;

  -- === Routine ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "RoutineID", "UserID", "Name", "Entries", "Status",
           "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "Routine"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Routine', v_rows); END IF;

  -- === Schedule ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "ScheduleID", "UserID", "Name", "ApplicationMode", "Entries",
           "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "Schedule"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Schedule', v_rows); END IF;

  -- === CalendarDay ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "CalendarDayID", "UserID", "Date", "SlotCapacity", "Slots",
           "CreatedAt", "UpdatedAt"
    FROM "CalendarDay"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('CalendarDay', v_rows); END IF;

  -- === RoutineInstance ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "RoutineInstanceID", "RoutineID", "UserID", "CalendarDayDate",
           "OwnedSlots", "CreatedAt", "UpdatedAt"
    FROM "RoutineInstance"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('RoutineInstance', v_rows); END IF;

  -- === ScheduleInstance ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "ScheduleInstanceID", "ScheduleID", "UserID",
           "StartDate", "EndDate", "OwnedSlots",
           "CreatedAt", "UpdatedAt"
    FROM "ScheduleInstance"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('ScheduleInstance', v_rows); END IF;

  -- === EventLog (uses CreatedAt, not UpdatedAt — append-only) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "EventLogID", "UserID", "DeviceID", "EventTypeID",
           "Timestamp", "AffectedEntityIDs", "AffectedSubskills",
           "Metadata", "CreatedAt"
    FROM "EventLog"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "CreatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('EventLog', v_rows); END IF;

  -- === UserDevice ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "DeviceID", "UserID", "DeviceLabel", "RegisteredAt",
           "LastSyncAt", "IsDeleted", "UpdatedAt"
    FROM "UserDevice"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('UserDevice', v_rows); END IF;

  -- ============================================================
  -- MATRIX TABLES (Migration 007)
  -- ============================================================

  -- === MatrixRun ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "MatrixRunID", "UserID", "MatrixType", "RunNumber", "RunState",
           "StartTimestamp", "EndTimestamp", "SessionShotTarget", "ShotOrderMode",
           "DispersionCaptureEnabled", "MeasurementDevice", "EnvironmentType",
           "SurfaceType", "GreenSpeed", "GreenFirmness",
           "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "MatrixRun"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('MatrixRun', v_rows); END IF;

  -- === MatrixAxis (child — JOIN through MatrixRun) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT ma."MatrixAxisID", ma."MatrixRunID", ma."AxisType",
           ma."AxisName", ma."AxisOrder", ma."CreatedAt", ma."UpdatedAt"
    FROM "MatrixAxis" ma
    JOIN "MatrixRun" mr ON mr."MatrixRunID" = ma."MatrixRunID"
    WHERE mr."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR ma."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('MatrixAxis', v_rows); END IF;

  -- === MatrixAxisValue (child — JOIN through MatrixAxis → MatrixRun) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT mav."AxisValueID", mav."MatrixAxisID", mav."Label",
           mav."SortOrder", mav."CreatedAt", mav."UpdatedAt"
    FROM "MatrixAxisValue" mav
    JOIN "MatrixAxis" ma ON ma."MatrixAxisID" = mav."MatrixAxisID"
    JOIN "MatrixRun" mr ON mr."MatrixRunID" = ma."MatrixRunID"
    WHERE mr."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR mav."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('MatrixAxisValue', v_rows); END IF;

  -- === MatrixCell (child — JOIN through MatrixRun) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT mc."MatrixCellID", mc."MatrixRunID", mc."AxisValueIDs",
           mc."ExcludedFromRun", mc."CreatedAt", mc."UpdatedAt"
    FROM "MatrixCell" mc
    JOIN "MatrixRun" mr ON mr."MatrixRunID" = mc."MatrixRunID"
    WHERE mr."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR mc."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('MatrixCell', v_rows); END IF;

  -- === MatrixAttempt (child — JOIN through MatrixCell → MatrixRun) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT mat."MatrixAttemptID", mat."MatrixCellID", mat."AttemptTimestamp",
           mat."CarryDistanceMeters", mat."TotalDistanceMeters",
           mat."LeftDeviationMeters", mat."RightDeviationMeters",
           mat."RolloutDistanceMeters", mat."CreatedAt", mat."UpdatedAt"
    FROM "MatrixAttempt" mat
    JOIN "MatrixCell" mc ON mc."MatrixCellID" = mat."MatrixCellID"
    JOIN "MatrixRun" mr ON mr."MatrixRunID" = mc."MatrixRunID"
    WHERE mr."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR mat."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('MatrixAttempt', v_rows); END IF;

  -- === PerformanceSnapshot ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "SnapshotID", "UserID", "MatrixRunID", "MatrixType",
           "IsPrimary", "Label", "SnapshotTimestamp",
           "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "PerformanceSnapshot"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('PerformanceSnapshot', v_rows); END IF;

  -- === SnapshotClub (child — JOIN through PerformanceSnapshot) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT sc."SnapshotClubID", sc."SnapshotID", sc."ClubID",
           sc."CarryDistanceMeters", sc."TotalDistanceMeters",
           sc."DispersionLeftMeters", sc."DispersionRightMeters",
           sc."RolloutDistanceMeters", sc."CreatedAt", sc."UpdatedAt"
    FROM "SnapshotClub" sc
    JOIN "PerformanceSnapshot" ps ON ps."SnapshotID" = sc."SnapshotID"
    WHERE ps."UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR sc."UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('SnapshotClub', v_rows); END IF;

  RETURN jsonb_build_object(
    'success', true,
    'server_timestamp', v_server_ts,
    'changes', v_changes
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'success', false,
    'error_code', 'SERVER_ERROR',
    'error_message', SQLERRM,
    'server_timestamp', NOW()
  );
END;
$$;
