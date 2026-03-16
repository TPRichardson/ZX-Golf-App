-- Seed three Driver Power drills mapping to driving_distance_maximum.
-- Per-drill window caps (3/5/12) naturally weight the subskill score.

-- Driver Club Speed: 3 sets × 3 shots, cap 3, anchors 70/100/125 mph.
INSERT INTO "Drill" (
  "DrillID", "UserID", "Name", "SkillArea", "DrillType", "ScoringMode",
  "InputMode", "MetricSchemaID", "GridType",
  "SubskillMapping", "ClubSelectionMode",
  "TargetDistanceMode", "TargetDistanceValue",
  "TargetSizeMode", "TargetSizeWidth", "TargetSizeDepth",
  "RequiredSetCount", "RequiredAttemptsPerSet",
  "Anchors", "Target", "Description",
  "TargetDistanceUnit", "TargetSizeUnit",
  "RequiredEquipment", "RecommendedEquipment",
  "WindowCap",
  "Origin", "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
) VALUES (
  'a0000000-0000-4000-8000-000000000004',
  NULL,
  'Driver Club Speed',
  'Driving',
  'Transition',
  'Shared',
  'RawDataEntry',
  'raw_club_head_speed',
  NULL,
  '["driving_distance_maximum"]'::JSONB,
  NULL,
  NULL, NULL,
  NULL, NULL, NULL,
  3, 3,
  '{"driving_distance_maximum": {"Min": 70, "Scratch": 100, "Pro": 125}}'::JSONB,
  NULL,
  'Record your driver club head speed (mph) over 3 sets of 3 swings. Requires a launch monitor.',
  NULL, NULL,
  '["launchMonitor"]'::JSONB,
  '[]'::JSONB,
  3,
  'System', 'Active', false, NOW(), NOW()
);

-- Driver Ball Speed: 3 sets × 3 shots, cap 5, anchors 100/165/180 mph.
INSERT INTO "Drill" (
  "DrillID", "UserID", "Name", "SkillArea", "DrillType", "ScoringMode",
  "InputMode", "MetricSchemaID", "GridType",
  "SubskillMapping", "ClubSelectionMode",
  "TargetDistanceMode", "TargetDistanceValue",
  "TargetSizeMode", "TargetSizeWidth", "TargetSizeDepth",
  "RequiredSetCount", "RequiredAttemptsPerSet",
  "Anchors", "Target", "Description",
  "TargetDistanceUnit", "TargetSizeUnit",
  "RequiredEquipment", "RecommendedEquipment",
  "WindowCap",
  "Origin", "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
) VALUES (
  'a0000000-0000-4000-8000-000000000005',
  NULL,
  'Driver Ball Speed',
  'Driving',
  'Transition',
  'Shared',
  'RawDataEntry',
  'raw_ball_speed',
  NULL,
  '["driving_distance_maximum"]'::JSONB,
  NULL,
  NULL, NULL,
  NULL, NULL, NULL,
  3, 3,
  '{"driving_distance_maximum": {"Min": 100, "Scratch": 165, "Pro": 180}}'::JSONB,
  NULL,
  'Record your driver ball speed (mph) over 3 sets of 3 swings. Requires a launch monitor.',
  NULL, NULL,
  '["launchMonitor"]'::JSONB,
  '[]'::JSONB,
  5,
  'System', 'Active', false, NOW(), NOW()
);

-- Driver Total Distance: 3 sets × 3 shots, cap 12, anchors 170/260/310 yards.
INSERT INTO "Drill" (
  "DrillID", "UserID", "Name", "SkillArea", "DrillType", "ScoringMode",
  "InputMode", "MetricSchemaID", "GridType",
  "SubskillMapping", "ClubSelectionMode",
  "TargetDistanceMode", "TargetDistanceValue",
  "TargetSizeMode", "TargetSizeWidth", "TargetSizeDepth",
  "RequiredSetCount", "RequiredAttemptsPerSet",
  "Anchors", "Target", "Description",
  "TargetDistanceUnit", "TargetSizeUnit",
  "RequiredEquipment", "RecommendedEquipment",
  "WindowCap",
  "Origin", "Status", "IsDeleted", "CreatedAt", "UpdatedAt"
) VALUES (
  'a0000000-0000-4000-8000-000000000006',
  NULL,
  'Driver Total Distance',
  'Driving',
  'Transition',
  'Shared',
  'RawDataEntry',
  'raw_total_distance',
  NULL,
  '["driving_distance_maximum"]'::JSONB,
  NULL,
  NULL, NULL,
  NULL, NULL, NULL,
  3, 3,
  '{"driving_distance_maximum": {"Min": 170, "Scratch": 260, "Pro": 310}}'::JSONB,
  NULL,
  'Record your driver total distance (yards) over 3 sets of 3 shots. Can be estimated or measured with a launch monitor.',
  NULL, NULL,
  '[]'::JSONB,
  '[]'::JSONB,
  12,
  'System', 'Active', false, NOW(), NOW()
);
