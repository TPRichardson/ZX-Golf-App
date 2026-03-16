-- Add WindowCap column to Drill table for per-drill window capacity limits.
-- NULL means no cap (existing behavior).

ALTER TABLE "Drill" ADD COLUMN IF NOT EXISTS "WindowCap" INTEGER;

-- Seed MetricSchemas for driver power drills.
INSERT INTO "MetricSchema" ("MetricSchemaID", "Name", "InputMode", "HardMinInput", "HardMaxInput", "ValidationRules", "ScoringAdapterBinding")
VALUES
  ('raw_total_distance', 'Total Distance (yards)', 'RawDataEntry', 0, 500, '{"unit": "yards"}', 'LinearInterpolation'),
  ('driver_club_speed', 'Driver Club Speed (mph)', 'RawDataEntry', 50, 150, '{"unit": "mph"}', 'BestOfSetLinearInterpolation'),
  ('driver_ball_speed', 'Driver Ball Speed (mph)', 'RawDataEntry', 80, 200, '{"unit": "mph"}', 'BestOfSetLinearInterpolation'),
  ('driver_total_distance', 'Driver Total Distance (yds)', 'RawDataEntry', 100, 400, '{"unit": "yards"}', 'BestOfSetLinearInterpolation')
ON CONFLICT DO NOTHING;
