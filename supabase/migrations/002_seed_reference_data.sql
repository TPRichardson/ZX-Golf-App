-- ============================================================
-- ZX Golf App — Seed Data
-- Migration: 002_seed_reference_data.sql
-- Version: TD-02v.a5
-- ============================================================
-- Seeds all reference tables and the V1 System Drill Library.
-- Harmonised with: Section 2 (2v.f1), Section 4 (4v.g9),
-- Section 7 (7v.b9), Section 9 (9v.a2), Section 14 (14v.a4).
-- ============================================================

-- ============================================================
-- 1. EventTypeRef (Section 7, §7.9 — canonical enumeration + TD-03/TD-04 additions)
-- ============================================================

INSERT INTO "EventTypeRef" ("EventTypeID", "Name", "Description") VALUES
  ('AnchorEdit',                'Anchor Edit',                  'User Custom Drill anchor change'),
  ('InstanceEdit',              'Instance Edit',                'Instance value edited post-close'),
  ('InstanceDeletion',          'Instance Deletion',            'Instance deleted from unstructured drill post-close'),
  ('SessionDeletion',           'Session Deletion',             'Session deleted'),
  ('SessionAutoDiscarded',      'Session Auto-Discarded',       'Session auto-discarded when last Instance deleted'),
  ('PracticeBlockDeletion',     'PracticeBlock Deletion',       'PracticeBlock deleted'),
  ('DrillDeletion',             'Drill Deletion',               'Drill and all child data deleted'),
  ('SystemParameterChange',     'System Parameter Change',      'Central structural parameter updated'),
  ('ReflowFailed',              'Reflow Failed',                'Reflow failed after all retry attempts'),
  ('ReflowReverted',            'Reflow Reverted',              'Scoring state reverted to previous valid state after failure'),
  ('IntegrityFlagRaised',       'Integrity Flag Raised',        'Instance saved with raw metric outside schema plausibility bounds'),
  ('IntegrityFlagCleared',      'Integrity Flag Cleared',       'User manually cleared an active integrity flag'),
  ('IntegrityFlagAutoResolved', 'Integrity Flag Auto-Resolved', 'All Instances returned to valid bounds following edit'),
  ('ReflowComplete',            'Reflow Complete',              'Reflow completed successfully (TD-03 §4.2 Step 9, TD-04 Step 9)'),
  ('SessionCompletion',         'Session Completion',           'Session closed and scored (TD-03 §4.4, TD-04 §2.2.2)'),
  ('RebuildStorageFailure',     'Rebuild Storage Failure',      'Reflow rebuild results could not be written to materialised tables (TD-03 §4.5, TD-04 §3.4.2)')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 2. SubskillRef (Section 2, §2.3 — canonical subskill tree)
-- ============================================================

INSERT INTO "SubskillRef" ("SubskillID", "SkillArea", "Name", "Allocation") VALUES
  -- Irons (360 total)
  ('irons_distance_control',    'Irons',    'Distance Control',   150),
  ('irons_direction_control',   'Irons',    'Direction Control',  150),
  ('irons_shape_control',       'Irons',    'Shape Control',       60),
  -- Driving (240 total)
  ('driving_distance_maximum',  'Driving',  'Distance Maximum',   100),
  ('driving_direction_control', 'Driving',  'Direction Control',  100),
  ('driving_shape_control',     'Driving',  'Shape Control',       40),
  -- Putting (240 total)
  ('putting_distance_control',  'Putting',  'Distance Control',   120),
  ('putting_direction_control', 'Putting',  'Direction Control',  120),
  -- Pitching (60 total)
  ('pitching_distance_control', 'Pitching', 'Distance Control',    25),
  ('pitching_direction_control','Pitching', 'Direction Control',   25),
  ('pitching_flight_control',   'Pitching', 'Flight Control',      10),
  -- Chipping (60 total)
  ('chipping_distance_control', 'Chipping', 'Distance Control',    25),
  ('chipping_direction_control','Chipping', 'Direction Control',   25),
  ('chipping_flight_control',   'Chipping', 'Flight Control',      10),
  -- Woods (20 total)
  ('woods_distance_control',    'Woods',    'Distance Control',     8),
  ('woods_direction_control',   'Woods',    'Direction Control',    8),
  ('woods_shape_control',       'Woods',    'Shape Control',        4),
  -- Bunkers (20 total)
  ('bunkers_distance_control',  'Bunkers',  'Distance Control',    10),
  ('bunkers_direction_control', 'Bunkers',  'Direction Control',   10)
ON CONFLICT ("SubskillID") DO UPDATE SET "Allocation" = EXCLUDED."Allocation";

-- ============================================================
-- 3. MetricSchema (Section 4, §4.3 / Section 14)
-- ============================================================
-- Each schema defines: input mode, plausibility bounds, and
-- scoring adapter binding.

INSERT INTO "MetricSchema" ("MetricSchemaID", "Name", "InputMode", "HardMinInput", "HardMaxInput", "ValidationRules", "ScoringAdapterBinding") VALUES
  -- Grid schemas (no HardMin/HardMax — discrete cell input)
  ('grid_1x3_direction',  '1×3 Direction Grid',       'GridCell',         NULL, NULL, '{"gridType": "OneByThree"}',   'HitRateInterpolation'),
  ('grid_3x1_distance',   '3×1 Distance Grid',        'GridCell',         NULL, NULL, '{"gridType": "ThreeByOne"}',   'HitRateInterpolation'),
  ('grid_3x3_multioutput','3×3 Multi-Output Grid',     'GridCell',         NULL, NULL, '{"gridType": "ThreeByThree"}', 'HitRateInterpolation'),

  -- Binary Hit/Miss schema (no HardMin/HardMax — discrete binary input)
  ('binary_hit_miss',     'Binary Hit/Miss',           'BinaryHitMiss',    NULL, NULL, '{}',                           'HitRateInterpolation'),

  -- Raw Data Entry schemas (numeric with plausibility bounds)
  ('raw_carry_distance',  'Carry Distance (yards)',    'RawDataEntry',     0,    500,  '{"unit": "yards"}',            'LinearInterpolation'),
  ('raw_ball_speed',      'Ball Speed (mph)',          'RawDataEntry',     0,    250,  '{"unit": "mph"}',              'LinearInterpolation'),
  ('raw_club_head_speed', 'Club Head Speed (mph)',     'RawDataEntry',     0,    200,  '{"unit": "mph"}',              'LinearInterpolation'),

  -- Technique Block schema (duration — timer-based)
  ('technique_duration',  'Technique Block Duration',  'RawDataEntry',     0,    43200,'{"unit": "seconds"}',          'None')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 4. System Drills — placeholder
-- ============================================================
-- No system drills seeded. Real drill catalogue will be populated
-- in a future migration when the V1 drill library is finalised.

-- ============================================================
-- 5. Post-Seed Invariant Validation
-- Fails the migration if allocation invariants are violated.
-- ============================================================

-- Invariant 1: Global allocation must sum to exactly 1000
DO $$
DECLARE
  total INTEGER;
BEGIN
  SELECT SUM("Allocation") INTO total FROM "SubskillRef";
  IF total != 1000 THEN
    RAISE EXCEPTION 'SubskillRef allocation invariant violated: global sum = %, expected 1000', total;
  END IF;
END $$;

-- Invariant 2: Per-Skill-Area allocations must match canonical totals
DO $$
DECLARE
  r RECORD;
  expected JSONB := '{"Irons": 280, "Driving": 240, "Putting": 200, "Pitching": 100, "Chipping": 100, "Woods": 50, "Bunkers": 30}'::jsonb;
  expected_val INTEGER;
BEGIN
  FOR r IN SELECT "SkillArea"::text AS sa, SUM("Allocation") AS total FROM "SubskillRef" GROUP BY "SkillArea"
  LOOP
    expected_val := (expected ->> r.sa)::INTEGER;
    IF r.total != expected_val THEN
      RAISE EXCEPTION 'SubskillRef allocation invariant violated: % sum = %, expected %', r.sa, r.total, expected_val;
    END IF;
  END LOOP;
END $$;

-- Invariant 3: Exactly 19 subskills seeded
DO $$
DECLARE
  cnt INTEGER;
BEGIN
  SELECT COUNT(*) INTO cnt FROM "SubskillRef";
  IF cnt != 19 THEN
    RAISE EXCEPTION 'SubskillRef count invariant violated: % rows, expected 19', cnt;
  END IF;
END $$;

-- Invariant 4: No system drills seeded (real drills added in future migration)
-- Invariant 5: Subskill mapping validation deferred until drills are populated

-- ============================================================
-- SEED: SystemMaintenanceLock single row (Section 16, §16.4.4)
-- ============================================================
INSERT INTO "SystemMaintenanceLock" ("LockID", "IsActive", "Reason")
SELECT gen_random_uuid(), FALSE, NULL
WHERE NOT EXISTS (SELECT 1 FROM "SystemMaintenanceLock");

-- ============================================================
-- Record this migration
-- ============================================================
INSERT INTO "MigrationLog" ("SequenceNumber", "Filename")
VALUES (2, '002_seed_reference_data.sql')
ON CONFLICT ("SequenceNumber") DO NOTHING;
