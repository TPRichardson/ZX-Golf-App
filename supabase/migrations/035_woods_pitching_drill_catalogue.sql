-- Woods + Pitching drill catalogue expansion.
-- 9 new Woods drills, 8 new Pitching drills.
-- Retire duplicate Pitch Precision (003) — same as Free Practice Full Control (00f).
-- Rename existing drills for consistency.

-- ============================================================
-- Rename existing drills for consistent naming
-- ============================================================

-- Pitch Precision → retire (duplicate of Free Practice Full Control)
UPDATE "Drill" SET "IsDeleted" = true, "Status" = 'Retired'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000003';

-- Pitch Variable Target → Mixed Target Practice Distance Control
UPDATE "Drill" SET "Name" = 'Mixed Target Practice Distance Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000012';

-- Iron Pressure → Mixed Club Practice Direction Control
UPDATE "Drill" SET "Name" = 'Mixed Club Practice Direction Control'
WHERE "DrillID" = 'a0000000-0000-4000-8000-000000000002';

-- ============================================================
-- WOODS: 9 new drills
-- ============================================================

-- Woods Fixed Target Block (Transition, RandomDistancePerSet, UserLed)
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
) VALUES
(
  '78ce14bf-309a-4a2d-a0c3-ba3dbf9b8f4b', NULL,
  'Fixed Target Block Full Control',
  'Woods', 'Transition', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["woods_direction_control", "woods_distance_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five woods shots. Target distance fixed per set from random club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  'fb0e949b-6955-4a87-87dd-2aefaf6b77bd', NULL,
  'Fixed Target Block Direction Control',
  'Woods', 'Transition', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["woods_direction_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five woods shots. Target distance fixed per set from random club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '3e1123e8-7252-4d1a-a5b2-1c5d10f9e6a6', NULL,
  'Fixed Target Block Distance Control',
  'Woods', 'Transition', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["woods_distance_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five woods shots. Target distance fixed per set from random club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Woods Mixed Club Practice (Pressure, ClubCarry, Random)
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
) VALUES
(
  'ea958eb0-4db9-430f-911a-7592cdbf67b1', NULL,
  'Mixed Club Practice Full Control',
  'Woods', 'Pressure', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["woods_direction_control", "woods_distance_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five woods shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '04cbb036-c929-43aa-bc70-dbe331ade887', NULL,
  'Mixed Club Practice Direction Control',
  'Woods', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["woods_direction_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five woods shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '975d6cc5-74e6-4aa8-bba9-98110cead79c', NULL,
  'Mixed Club Practice Distance Control',
  'Woods', 'Pressure', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["woods_distance_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five woods shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Woods Mixed Target Practice (Pressure, RandomRange, UserLed)
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
) VALUES
(
  '817cc6b4-13a4-43fb-9b84-1c3f84c1052a', NULL,
  'Mixed Target Practice Full Control',
  'Woods', 'Pressure', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["woods_direction_control", "woods_distance_control"]'::JSONB,
  'UserLed', 'RandomRange', 280,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  180,
  'Three sets of five woods shots. Target distance randomly varies 180-280 yards per shot. Club suggested but changeable.',
  'yards', NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  'e57ce402-537c-475a-85e9-02a272fff35f', NULL,
  'Mixed Target Practice Direction Control',
  'Woods', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["woods_direction_control"]'::JSONB,
  'UserLed', 'RandomRange', 280,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  180,
  'Three sets of five woods shots. Target distance randomly varies 180-280 yards per shot. Club suggested but changeable.',
  'yards', NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '7462a9dc-07ed-4233-9635-d2a185bd8106', NULL,
  'Mixed Target Practice Distance Control',
  'Woods', 'Pressure', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["woods_distance_control"]'::JSONB,
  'UserLed', 'RandomRange', 280,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"woods_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  180,
  'Three sets of five woods shots. Target distance randomly varies 180-280 yards per shot. Club suggested but changeable.',
  'yards', NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- ============================================================
-- PITCHING: 8 new drills
-- ============================================================

-- Pitching Fixed Target Block (Transition, RandomDistancePerSet, UserLed)
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
) VALUES
(
  'a8737c1a-0da7-4324-af4b-f7963ca4cc9d', NULL,
  'Fixed Target Block Full Control',
  'Pitching', 'Transition', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["pitching_direction_control", "pitching_distance_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "pitching_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five pitching shots. Target distance fixed per set from random club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '10fbee29-7bde-434f-87f1-73bd283f9851', NULL,
  'Fixed Target Block Direction Control',
  'Pitching', 'Transition', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["pitching_direction_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five pitching shots. Target distance fixed per set from random club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  'f647db4f-ca64-4815-8d5c-ae845a5a8535', NULL,
  'Fixed Target Block Distance Control',
  'Pitching', 'Transition', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["pitching_distance_control"]'::JSONB,
  'UserLed', 'RandomDistancePerSet', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five pitching shots. Target distance fixed per set from random club carry. Club suggested but changeable.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Pitching Mixed Club Practice (Pressure, ClubCarry, Random)
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
) VALUES
(
  'caa7cca4-16a8-461d-ba71-4b46fa5b9d20', NULL,
  'Mixed Club Practice Full Control',
  'Pitching', 'Pressure', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["pitching_direction_control", "pitching_distance_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "pitching_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five pitching shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '1607e9eb-871f-4602-8574-55dc56bd6d81', NULL,
  'Mixed Club Practice Direction Control',
  'Pitching', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["pitching_direction_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five pitching shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  '10f2e703-375d-41e0-b12c-b14c0dbdbbb9', NULL,
  'Mixed Club Practice Distance Control',
  'Pitching', 'Pressure', 'Shared', 'GridCell',
  'grid_3x1_distance', 'ThreeByOne',
  '["pitching_distance_control"]'::JSONB,
  'Random', 'ClubCarry', NULL,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  NULL, 'Three sets of five pitching shots. Club randomly assigned per shot. Target adjusts to club carry.',
  NULL, NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);

-- Pitching Mixed Target Practice (Pressure, RandomRange, UserLed)
-- Distance Control variant already exists (012). Need Full Control + Direction Control.
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
) VALUES
(
  'cc4fa58e-7dcc-4330-a70b-c03c225a4fc7', NULL,
  'Mixed Target Practice Full Control',
  'Pitching', 'Pressure', 'MultiOutput', 'GridCell',
  'grid_3x3_multioutput', 'ThreeByThree',
  '["pitching_direction_control", "pitching_distance_control"]'::JSONB,
  'UserLed', 'RandomRange', 120,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}, "pitching_distance_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  30,
  'Three sets of five pitching shots. Target distance randomly varies 30-120 yards per shot. Club suggested but changeable.',
  'yards', NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
),
(
  'bf38cad6-d6d1-45e0-997b-15f27a51e0d9', NULL,
  'Mixed Target Practice Direction Control',
  'Pitching', 'Pressure', 'Shared', 'GridCell',
  'grid_1x3_direction', 'OneByThree',
  '["pitching_direction_control"]'::JSONB,
  'UserLed', 'RandomRange', 120,
  'PercentageOfTargetDistance', NULL, NULL, 3, 5,
  '{"pitching_direction_control": {"Min": 10, "Scratch": 60, "Pro": 90}}'::JSONB,
  30,
  'Three sets of five pitching shots. Target distance randomly varies 30-120 yards per shot. Club suggested but changeable.',
  'yards', NULL, '["LaunchMonitor"]'::JSONB, '[]'::JSONB, NULL,
  'System', 'Active', false, NOW(), NOW()
);
