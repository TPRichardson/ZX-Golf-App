-- Rename SkillArea 'Irons' → 'Approach' and subskill IDs 'irons_*' → 'approach_*'.

-- Step 1: Rename the Postgres ENUM value.
ALTER TYPE skill_area RENAME VALUE 'Irons' TO 'Approach';

-- Step 2: SkillArea columns already reference the enum, so all existing 'Irons'
-- values are now automatically 'Approach'. No UPDATE needed for SkillArea columns.

-- Step 3: Rename subskill IDs (TEXT columns, not enums).
UPDATE "SubskillRef" SET "SubskillID" = 'approach_distance_control' WHERE "SubskillID" = 'irons_distance_control';
UPDATE "SubskillRef" SET "SubskillID" = 'approach_direction_control' WHERE "SubskillID" = 'irons_direction_control';
UPDATE "SubskillRef" SET "SubskillID" = 'approach_shape_control' WHERE "SubskillID" = 'irons_shape_control';

-- Step 4: Update Subskill foreign keys in materialised tables.
UPDATE "MaterialisedSubskillScore" SET "Subskill" = REPLACE("Subskill", 'irons_', 'approach_') WHERE "Subskill" LIKE 'irons_%';
UPDATE "MaterialisedWindowState" SET "Subskill" = REPLACE("Subskill", 'irons_', 'approach_') WHERE "Subskill" LIKE 'irons_%';

-- Step 5: Update SubskillMapping JSON in Drill table (JSONB → cast to TEXT for REPLACE).
UPDATE "Drill" SET "SubskillMapping" = REPLACE("SubskillMapping"::TEXT, 'irons_', 'approach_')::JSONB WHERE "SubskillMapping"::TEXT LIKE '%irons_%';
