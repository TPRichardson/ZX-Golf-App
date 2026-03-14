-- Fix Iron Pressure drill: change from 3x1 distance grid to 1x3 direction grid.

UPDATE "Drill"
SET "MetricSchemaID" = 'grid_1x3_direction',
    "GridType" = 'OneByThree',
    "UpdatedAt" = NOW()
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000002';
