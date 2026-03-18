-- Seed three Approach Transition drills: 3x3, 1x3, 3x1.
-- UserLed club, ClubCarry distance, 3x5, anchors 10/60/90.
-- Target size uses PercentageOfTargetDistance (club-tier banded).

-- Approach Transition Full Grid: MultiOutput, maps to direction + distance.
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
  'a0000000-0000-4000-8000-000000000008',
  NULL,
  'Approach Transition Full Grid',
  'Approach',
  'Transition',
  'MultiOutput',
  'GridCell',
  'grid_3x3_multioutput',
  'ThreeByThree',
  '["approach_direction_control", "approach_distance_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five approach shots into a 3x3 grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Approach Transition Left/Right: Shared, maps to direction control.
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
  'a0000000-0000-4000-8000-000000000009',
  NULL,
  'Approach Transition Left/Right',
  'Approach',
  'Transition',
  'Shared',
  'GridCell',
  'grid_1x3_direction',
  'OneByThree',
  '["approach_direction_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five approach shots into a 1x3 direction grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Approach Transition Long/Short: Shared, maps to distance control.
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
  'a0000000-0000-4000-8000-00000000000a',
  NULL,
  'Approach Transition Long/Short',
  'Approach',
  'Transition',
  'Shared',
  'GridCell',
  'grid_3x1_distance',
  'ThreeByOne',
  '["approach_distance_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five approach shots into a 3x1 distance grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);
