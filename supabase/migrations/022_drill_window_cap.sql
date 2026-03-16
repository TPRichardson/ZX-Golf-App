-- Add WindowCap column to Drill table for per-drill window capacity limits.
-- NULL means no cap (existing behavior).

ALTER TABLE "Drill" ADD COLUMN IF NOT EXISTS "WindowCap" INTEGER;

-- Seed total distance MetricSchema.
INSERT INTO "MetricSchema" ("MetricSchemaID", "Name", "InputMode", "HardMinInput", "HardMaxInput", "ValidationRules", "ScoringAdapterBinding")
VALUES ('raw_total_distance', 'Total Distance (yards)', 'RawDataEntry', 0, 500, '{"unit": "yards"}', 'LinearInterpolation')
ON CONFLICT DO NOTHING;
