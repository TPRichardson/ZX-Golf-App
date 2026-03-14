-- Add RequiredEquipment column to Drill table.
-- JSON array of EquipmentType strings (e.g. '["LaunchMonitor"]').
-- Empty array means no equipment prerequisites for adoption.

ALTER TABLE "Drill" ADD COLUMN "RequiredEquipment" JSONB NOT NULL DEFAULT '[]'::JSONB;
