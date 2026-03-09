-- 010: Add WindowSize column to SubskillRef for per-subskill window capacity.
-- Accumulation scoring model: each drill contributes fixed points up to window capacity.

ALTER TABLE "SubskillRef" ADD COLUMN "WindowSize" INTEGER NOT NULL DEFAULT 25;

-- Set per-subskill window sizes.
UPDATE "SubskillRef" SET "WindowSize" = 25 WHERE "SubskillID" = 'irons_distance_control';
UPDATE "SubskillRef" SET "WindowSize" = 25 WHERE "SubskillID" = 'irons_direction_control';
UPDATE "SubskillRef" SET "WindowSize" = 15 WHERE "SubskillID" = 'irons_shape_control';
UPDATE "SubskillRef" SET "WindowSize" = 20 WHERE "SubskillID" = 'driving_distance_maximum';
UPDATE "SubskillRef" SET "WindowSize" = 20 WHERE "SubskillID" = 'driving_direction_control';
UPDATE "SubskillRef" SET "WindowSize" = 10 WHERE "SubskillID" = 'driving_shape_control';
UPDATE "SubskillRef" SET "WindowSize" = 25 WHERE "SubskillID" = 'putting_distance_control';
UPDATE "SubskillRef" SET "WindowSize" = 25 WHERE "SubskillID" = 'putting_direction_control';
UPDATE "SubskillRef" SET "WindowSize" = 10 WHERE "SubskillID" = 'pitching_distance_control';
UPDATE "SubskillRef" SET "WindowSize" = 10 WHERE "SubskillID" = 'pitching_direction_control';
UPDATE "SubskillRef" SET "WindowSize" = 3  WHERE "SubskillID" = 'pitching_flight_control';
UPDATE "SubskillRef" SET "WindowSize" = 10 WHERE "SubskillID" = 'chipping_distance_control';
UPDATE "SubskillRef" SET "WindowSize" = 10 WHERE "SubskillID" = 'chipping_direction_control';
UPDATE "SubskillRef" SET "WindowSize" = 3  WHERE "SubskillID" = 'chipping_flight_control';
UPDATE "SubskillRef" SET "WindowSize" = 3  WHERE "SubskillID" = 'woods_distance_control';
UPDATE "SubskillRef" SET "WindowSize" = 3  WHERE "SubskillID" = 'woods_direction_control';
UPDATE "SubskillRef" SET "WindowSize" = 2  WHERE "SubskillID" = 'woods_shape_control';
UPDATE "SubskillRef" SET "WindowSize" = 3  WHERE "SubskillID" = 'bunkers_distance_control';
UPDATE "SubskillRef" SET "WindowSize" = 3  WHERE "SubskillID" = 'bunkers_direction_control';
