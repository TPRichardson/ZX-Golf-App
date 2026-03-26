-- Update chipping scoring game for dynamic par system.
-- Instance strokes now stores plus/minus par (positive = over par).
-- MetricSchema par set to 0 since strokes is already relative.
-- Anchors: Pro = 0 (even par), Scratch = -2 (+2 over), Min = -12 (+12 over).

-- 1. Update MetricSchema par to 0.
UPDATE "MetricSchema"
SET "ValidationRules" = '{"par": 0, "holes": 18, "distanceUnit": "yards", "resultUnit": "feet", "categories": [{"name": "Short", "minDistance": 5, "maxDistance": 8, "holeCount": 6}, {"name": "Medium", "minDistance": 9, "maxDistance": 14, "holeCount": 6}, {"name": "Long", "minDistance": 15, "maxDistance": 20, "holeCount": 6}], "gameVariant": "chipping", "notPuttablePenalty": 2.5}'::JSONB
WHERE "MetricSchemaID" = 'chipping_game_strokes';

-- 2. Update drill anchors.
UPDATE "Drill"
SET "Anchors" = '{"chipping_distance_control": {"Min": -12, "Scratch": -2, "Pro": 0}, "chipping_direction_control": {"Min": -12, "Scratch": -2, "Pro": 0}}'::JSONB,
    "UpdatedAt" = NOW()
WHERE "DrillID" = 'a1b2c3d4-5678-4abc-9def-0123456789ab';
