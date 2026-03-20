-- Driving: 3 new direction-only drills (1x3).
-- Driving only tests direction control — no 3x3 or 3x1 variants.

-- Fixed Target Block Direction Control (Transition, RandomDistancePerSet, UserLed)
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
  'e874e384-c513-4c62-a389-e08396c8c936', NULL,
  'Fixed Target Block Direction Control',
  'Driving', 'Transition', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["driving_direction_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"driving_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five driving shots. Target distance fixed per set from club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Mixed Club Practice Direction Control (Pressure, ClubCarry, Random)
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
  '584fee76-7617-4555-b509-dbcba694d6e2', NULL,
  'Mixed Club Practice Direction Control',
  'Driving', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["driving_direction_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"driving_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five driving shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Mixed Target Practice Direction Control (Pressure, RandomRange, UserLed)
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
  'b2d126b0-02b0-4af9-9d8f-0f41956cc9fa', NULL,
  'Mixed Target Practice Direction Control',
  'Driving', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["driving_direction_control"]'::JSONB,
  'UserLed', 'RandomRange', 320,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"driving_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  220,
  'Three sets of five driving shots. Target distance randomly varies 220-320 yards per shot. Club suggested but changeable.',
  'yards', NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);
