-- Scoring Game: metric schema and 18-hole putting drill.
-- Depends on 037 having committed the ScoringGame enum value.

-- 1. Insert MetricSchema for scoring game.
INSERT INTO "MetricSchema" (
  "MetricSchemaID", "Name", "InputMode",
  "HardMinInput", "HardMaxInput",
  "ValidationRules", "ScoringAdapterBinding"
) VALUES (
  'scoring_game_strokes',
  'Scoring Game Strokes Per Hole',
  'ScoringGame',
  1, 10,
  '{"par": 2, "holes": 18, "distanceUnit": "feet", "categories": [{"name": "Short", "minDistance": 6, "maxDistance": 10, "holeCount": 6}, {"name": "Medium", "minDistance": 11, "maxDistance": 20, "holeCount": 6}, {"name": "Long", "minDistance": 21, "maxDistance": 40, "holeCount": 6}]}'::JSONB,
  'ScoringGameInterpolation'
) ON CONFLICT ("MetricSchemaID") DO NOTHING;

-- 2. Insert 18-Hole Putting Scoring Game drill.
-- Pressure type, MultiOutput scoring (0.5 to each putting subskill).
-- Anchors (negated +/- par for interpolation): Min=-3 (+3 over), Scratch=3 (-3 under), Pro=5 (-5 under).
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
  '030eee51-3228-4fbb-9927-926bd4f58f24',
  NULL,
  '18-Hole Putting Challenge',
  'Putting',
  'Pressure',
  'MultiOutput',
  'ScoringGame',
  'scoring_game_strokes',
  NULL,
  '["putting_distance_control", "putting_direction_control"]'::JSONB,
  'UserLed',
  'RandomRange', NULL,
  NULL, NULL, NULL,
  1, 18,
  '{"putting_distance_control": {"Min": -3, "Scratch": 3, "Pro": 5}, "putting_direction_control": {"Min": -3, "Scratch": 3, "Pro": 5}}'::JSONB,
  NULL,
  'Play 18 holes of putting at randomised distances (6-40 feet). Par 2 per hole. 6 short (6-10ft), 6 medium (11-20ft), 6 long (21-40ft). Score is total +/- par.',
  'feet', NULL,
  '[]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);
