-- Chipping Scoring Game: metric schema and 18-hole chipping drill.
-- Reuses ScoringGame input mode (037) and ScoringGameInterpolation adapter.
-- Distance unit is yards (chip distance), result entry in feet (proximity).

-- 1. Insert MetricSchema for chipping scoring game.
INSERT INTO "MetricSchema" (
  "MetricSchemaID", "Name", "InputMode",
  "HardMinInput", "HardMaxInput",
  "ValidationRules", "ScoringAdapterBinding"
) VALUES (
  'chipping_game_strokes',
  'Chipping Game Strokes Per Hole',
  'ScoringGame',
  1, 10,
  '{"par": 2, "holes": 18, "distanceUnit": "yards", "resultUnit": "feet", "categories": [{"name": "Short", "minDistance": 5, "maxDistance": 8, "holeCount": 6}, {"name": "Medium", "minDistance": 9, "maxDistance": 14, "holeCount": 6}, {"name": "Long", "minDistance": 15, "maxDistance": 20, "holeCount": 6}], "gameVariant": "chipping", "notPuttablePenalty": 2.5}'::JSONB,
  'ScoringGameInterpolation'
) ON CONFLICT ("MetricSchemaID") DO NOTHING;

-- 2. Insert 18-Hole Chipping Scoring Game drill.
-- Pressure type, MultiOutput scoring (0.5 to each chipping subskill).
-- Anchors: Min=-3 (+3 over par), Scratch=3 (-3 under), Pro=5 (-5 under).
INSERT INTO "Drill" (
  "DrillID", "UserID", "Name", "SkillArea", "DrillType", "ScoringMode",
  "InputMode", "MetricSchemaID", "GridType",
  "SubskillMapping", "ClubSelectionMode",
  "TargetDistanceMode", "TargetDistanceValue",
  "TargetSizeMode", "TargetSizeWidth", "TargetSizeDepth",
  "RequiredSetCount", "RequiredAttemptsPerSet",
  "Anchors", "Target", "Description",
  "TargetDistanceUnit", "TargetSizeUnit",
  "RequiredEquipment", "RecommendedEquipment", "WindowCap",
  "Origin", "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
) VALUES (
  'a1b2c3d4-5678-4abc-9def-0123456789ab',
  NULL,
  '18-Hole Chipping Challenge',
  'Chipping',
  'Pressure',
  'MultiOutput',
  'ScoringGame',
  'chipping_game_strokes',
  NULL,
  '["chipping_distance_control", "chipping_direction_control"]'::JSONB,
  'UserLed',
  'RandomRange', NULL,
  NULL, NULL, NULL,
  1, 18,
  '{"chipping_distance_control": {"Min": -5, "Scratch": 3, "Pro": 7}, "chipping_direction_control": {"Min": -5, "Scratch": 3, "Pro": 7}}'::JSONB,
  NULL,
  'Play 18 holes of chipping at randomised distances (5-20 yards). Par 2 per hole. Chip to the green, then your remaining putt is calculated using PGA Tour strokes-gained data. 6 short (5-8y), 6 medium (9-14y), 6 long (15-20y).',
  'yards', NULL,
  '[]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);
