-- Seed three Woods Transition drills + one Driving Transition drill.
-- UserLed club, ClubCarry distance, 3x5, anchors 10/60/90.
-- Target size uses PercentageOfTargetDistance (club-tier banded).

-- Woods Transition Full Grid: MultiOutput, maps to direction + distance.
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
  'a0000000-0000-4000-8000-00000000000b',
  NULL,
  'Woods Transition Full Grid',
  'Woods',
  'Transition',
  'MultiOutput',
  'GridCell',
  'grid_3x3_multioutput',
  'ThreeByThree',
  '["woods_direction_control", "woods_distance_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five woods shots into a 3x3 grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Woods Transition Left/Right: Shared, maps to direction control.
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
  'a0000000-0000-4000-8000-00000000000c',
  NULL,
  'Woods Transition Left/Right',
  'Woods',
  'Transition',
  'Shared',
  'GridCell',
  'grid_1x3_direction',
  'OneByThree',
  '["woods_direction_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five woods shots into a 1x3 direction grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Woods Transition Long/Short: Shared, maps to distance control.
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
  'a0000000-0000-4000-8000-00000000000d',
  NULL,
  'Woods Transition Long/Short',
  'Woods',
  'Transition',
  'Shared',
  'GridCell',
  'grid_3x1_distance',
  'ThreeByOne',
  '["woods_distance_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five woods shots into a 3x1 distance grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Driving Transition Left/Right: Shared, maps to direction control.
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
  'a0000000-0000-4000-8000-00000000000e',
  NULL,
  'Driving Transition Left/Right',
  'Driving',
  'Transition',
  'Shared',
  'GridCell',
  'grid_1x3_direction',
  'OneByThree',
  '["driving_direction_control"]'::JSONB,
  'UserLed',
  'ClubCarry',
  NULL,
  'PercentageOfTargetDistance',
  NULL, NULL,
  3, 5,
  '{"driving_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Hit three sets of five driving shots into a 1x3 direction grid at club carry distance. Club and target can be changed between shots.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB,
  '[]'::JSONB,
  NULL,
  'System', 'Active', false, NOW(), NOW()
);
