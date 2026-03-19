-- Seed standard drill: Pitch Variable Target
-- 3×3 grid pitching drill with random target distance 35-100 yards.
-- Scores distance and direction control. Target size as % of target distance
-- (6% lateral, 5% carry). 3 sets of 5 shots. Requires launch monitor.

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
  'a0000000-0000-4000-8000-000000000012',
  NULL,
  'Pitch Variable Target',
  'Pitching',
  'Pressure',
  'MultiOutput',
  'GridCell',
  'grid_3x3_multioutput',
  'ThreeByThree',
  '["pitching_distance_control", "pitching_direction_control"]'::JSONB,
  'UserLed',
  'RandomRange',
  100,
  'PercentageOfTargetDistance',
  6.0,
  5.0,
  3,
  5,
  '{"pitching_distance_control": {"Min": 10, "Scratch": 70, "Pro": 90}, "pitching_direction_control": {"Min": 10, "Scratch": 70, "Pro": 90}}'::JSONB,
  35,
  'Pitch three sets of five shots at random distances between 35-100 yards. Score distance and direction control on a 3x3 grid. Target size scales with distance (6% lateral, 5% carry). Requires a launch monitor.',
  'yards',
  NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);
