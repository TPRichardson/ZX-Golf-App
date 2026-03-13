-- 013_drill_schema_additions.sql
-- Add Description, TargetDistanceUnit, TargetSizeUnit columns to Drill table.

ALTER TABLE "Drill" ADD COLUMN "Description" TEXT;
ALTER TABLE "Drill" ADD COLUMN "TargetDistanceUnit" TEXT;
ALTER TABLE "Drill" ADD COLUMN "TargetSizeUnit" TEXT;
