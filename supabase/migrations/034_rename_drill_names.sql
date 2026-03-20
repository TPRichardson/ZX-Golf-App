-- Rename drills: remove "Approach" prefix, rename grid types.
-- Left/Right → Direction Control, Long/Short → Distance Control, Full Grid → Full Control

-- Approach Free Practice (originally Approach Transition)
UPDATE "Drill" SET "Name" = 'Free Practice Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000008';
UPDATE "Drill" SET "Name" = 'Free Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000009';
UPDATE "Drill" SET "Name" = 'Free Practice Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000a';

-- Approach Fixed Target Block
UPDATE "Drill" SET "Name" = 'Fixed Target Block Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000012';
UPDATE "Drill" SET "Name" = 'Fixed Target Block Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000013';
UPDATE "Drill" SET "Name" = 'Fixed Target Block Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000014';

-- Approach Mixed Club Practice
UPDATE "Drill" SET "Name" = 'Mixed Club Practice Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000015';
UPDATE "Drill" SET "Name" = 'Mixed Club Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000016';
UPDATE "Drill" SET "Name" = 'Mixed Club Practice Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000017';

-- Approach Mixed Target Practice
UPDATE "Drill" SET "Name" = 'Mixed Target Practice Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000018';
UPDATE "Drill" SET "Name" = 'Mixed Target Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000019';

-- Approach Variable Target (already renamed to Mixed Target Practice Long/Short)
UPDATE "Drill" SET "Name" = 'Mixed Target Practice Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000007';

-- Iron Pressure
UPDATE "Drill" SET "Name" = 'Iron Pressure Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000002';

-- Pitch Precision Grid
UPDATE "Drill" SET "Name" = 'Pitch Precision Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000003';

-- Pitch Variable Target
UPDATE "Drill" SET "Name" = 'Pitch Variable Target Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000012';

-- Woods Transition drills
UPDATE "Drill" SET "Name" = 'Free Practice Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000b';
UPDATE "Drill" SET "Name" = 'Free Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000c';
UPDATE "Drill" SET "Name" = 'Free Practice Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000d';

-- Driving Transition
UPDATE "Drill" SET "Name" = 'Free Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000e';

-- Pitching Transition drills
UPDATE "Drill" SET "Name" = 'Free Practice Full Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-00000000000f';
UPDATE "Drill" SET "Name" = 'Free Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000010';
UPDATE "Drill" SET "Name" = 'Free Practice Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000011';
