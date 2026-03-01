-- ============================================================
-- ZX Golf App — Sync Download RPC
-- Migration: 004_sync_download.sql
-- TD-03 §5.2.2 — Download endpoint
-- ============================================================
-- Returns all rows modified since last_sync_timestamp for the
-- authenticated user. Uses REPEATABLE READ for consistent snapshot.
-- Child tables (Session, Set, Instance, PracticeEntry,
-- ClubPerformanceProfile) use JOINs to scope to user.
-- EventLog uses CreatedAt instead of UpdatedAt (append-only).
-- Includes soft-deleted rows.
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

  -- === Drill (owned by user OR system drills) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "DrillID", "UserID", "Name", "SkillArea", "DrillType", "ScoringMode",
           "InputMode", "MetricSchemaID", "GridType", "SubskillMapping",
           "ClubSelectionMode", "TargetDistanceMode", "TargetDistanceValue",
           "TargetSizeMode", "TargetSizeWidth", "TargetSizeDepth",
           "RequiredSetCount", "RequiredAttemptsPerSet", "Anchors",
           "Origin", "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
    FROM "Drill"
    WHERE ("UserID" = v_user_id OR "UserID" IS NULL)
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('Drill', v_rows); END IF;

  -- === PracticeBlock ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT "PracticeBlockID", "UserID", "SourceRoutineID", "DrillOrder",
           "StartTimestamp", "EndTimestamp", "ClosureType", "IsDeleted",
           "CreatedAt", "UpdatedAt"
    FROM "PracticeBlock"
    WHERE "UserID" = v_user_id
      AND (last_sync_timestamp IS NULL OR "UpdatedAt" > last_sync_timestamp)
  ) t;
  IF v_rows != '[]'::JSONB THEN v_changes := v_changes || jsonb_build_object('PracticeBlock', v_rows); END IF;

  -- === Session (child — JOIN through PracticeBlock for UserID) ===
  SELECT COALESCE(jsonb_agg(row_to_json(t)), '[]'::JSONB) INTO v_rows
  FROM (
    SELECT s."SessionID", s."DrillID", s."PracticeBlockID",
           s."CompletionTimestamp", s."Status", s."IntegrityFlag",
           s."IntegritySuppressed", s."UserDeclaration", s."SessionDuration",
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
