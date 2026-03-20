-- Approach Fixed Target Block (Transition, RandomDistancePerSet target, UserLed club)
-- 3 variants: Full Grid, Left/Right, Long/Short

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
  'Approach Fixed Target Block Full Grid',
  'Approach', 'Transition', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["approach_direction_control", "approach_distance_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Three sets of five approach shots into a 3x3 grid. Target distance is fixed per set from a random club carry. Club is suggested but can be changed.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

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
  'a0000000-0000-4000-8000-000000000013',
  NULL,
  'Approach Fixed Target Block Left/Right',
  'Approach', 'Transition', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["approach_direction_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Three sets of five approach shots into a 1x3 direction grid. Target distance is fixed per set from a random club carry. Club is suggested but can be changed.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

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
  'a0000000-0000-4000-8000-000000000014',
  NULL,
  'Approach Fixed Target Block Long/Short',
  'Approach', 'Transition', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["approach_distance_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Three sets of five approach shots into a 3x1 distance grid. Target distance is fixed per set from a random club carry. Club is suggested but can be changed.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Approach Mixed Club Practice (Pressure, ClubCarry target, Random club)
-- 3 variants: Full Grid, Left/Right, Long/Short

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
  'a0000000-0000-4000-8000-000000000015',
  NULL,
  'Approach Mixed Club Practice Full Grid',
  'Approach', 'Pressure', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["approach_direction_control", "approach_distance_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Three sets of five approach shots into a 3x3 grid. Club is randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

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
  'a0000000-0000-4000-8000-000000000016',
  NULL,
  'Approach Mixed Club Practice Left/Right',
  'Approach', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["approach_direction_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Three sets of five approach shots into a 1x3 direction grid. Club is randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

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
  'a0000000-0000-4000-8000-000000000017',
  NULL,
  'Approach Mixed Club Practice Long/Short',
  'Approach', 'Pressure', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["approach_distance_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL,
  'Three sets of five approach shots into a 3x1 distance grid. Club is randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Approach Mixed Target Practice (Pressure, RandomRange target, UserLed club)
-- Full Grid and Left/Right variants (Long/Short already exists as Approach Variable Target)

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
  'a0000000-0000-4000-8000-000000000018',
  NULL,
  'Approach Mixed Target Practice Full Grid',
  'Approach', 'Pressure', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["approach_direction_control", "approach_distance_control"]'::JSONB,
  'UserLed', 'RandomRange', 220,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "approach_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  110,
  'Three sets of five approach shots into a 3x3 grid. Target distance randomly varies between 110-220 yards per shot. Club is suggested but can be changed.',
  'yards', NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

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
  'a0000000-0000-4000-8000-000000000019',
  NULL,
  'Approach Mixed Target Practice Left/Right',
  'Approach', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["approach_direction_control"]'::JSONB,
  'UserLed', 'RandomRange', 220,
  'PercentageOfTargetDistance', NULL, NULL,
  3, 5,
  '{"approach_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  110,
  'Three sets of five approach shots into a 1x3 direction grid. Target distance randomly varies between 110-220 yards per shot. Club is suggested but can be changed.',
  'yards', NULL,
  '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Also rename the existing Approach Variable Target to match the naming pattern.
UPDATE "Drill" SET "Name" = 'Approach Mixed Target Practice Long/Short'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000007';
