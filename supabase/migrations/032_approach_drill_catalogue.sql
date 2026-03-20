-- Add RandomDistancePerSet to target_distance_mode enum.
ALTER TYPE target_distance_mode ADD VALUE 'RandomDistancePerSet';

-- Rename existing Approach Transition drills to "Free Practice".
UPDATE "Drill" SET "Name" = 'Approach Free Practice Full Grid'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000008';
UPDATE "Drill" SET "Name" = 'Approach Free Practice Left/Right'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000009';
UPDATE "Drill" SET "Name" = 'Approach Free Practice Long/Short'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000a';
