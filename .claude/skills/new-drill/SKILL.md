---
name: new-drill
description: Create a new standard (system) drill via SQL migration. Use when the user says "new drill", "add a drill", or "create a drill".
allowed-tools: Read, Glob, Grep, Write, AskUserQuestion, Bash
---

# New Standard Drill

Create a new server-authoritative standard drill by generating a Supabase SQL migration.

## Step 1 — Gather drill parameters

Use AskUserQuestion to collect all required fields. Ask in 2 rounds maximum.

### Round 1 — Core identity

Ask these 4 questions in a single AskUserQuestion call:

1. **Drill name** — free text (offer 3 suggestions based on any context the user provided)
2. **Skill area** — options: Driving, Approach, Putting, Pitching, Chipping, Woods, Bunkers
3. **Drill type** — options: TechniqueBlock, Transition, Pressure, Benchmark
4. **Grid / input type** — options:
   - 3×3 Grid (GridCell, ThreeByThree, grid_3x3_multioutput, MultiOutput)
   - 1×3 Direction Grid (GridCell, OneByThree, grid_1x3_direction, Shared)
   - 3×1 Distance Grid (GridCell, ThreeByOne, grid_3x1_distance, Shared)
   - Binary Hit/Miss (BinaryHitMiss, null grid, binary_hit_miss, Shared)
   - Raw Data Entry (RawDataEntry, null grid, varies, null scoring mode)

### Round 2 — Parameters

Ask these 4 questions in a single AskUserQuestion call:

1. **Subskills** — Show valid subskills for the chosen skill area:
   - Driving: driving_distance_maximum, driving_direction_control, driving_shape_control
   - Approach: approach_distance_control, approach_direction_control, approach_shape_control
   - Putting: putting_distance_control, putting_direction_control
   - Pitching: pitching_distance_control, pitching_direction_control, pitching_flight_control
   - Chipping: chipping_distance_control, chipping_direction_control, chipping_flight_control
   - Woods: woods_distance_control, woods_direction_control, woods_shape_control
   - Bunkers: bunkers_distance_control, bunkers_direction_control

2. **Target distance** — options: Fixed (ask value + unit), ClubCarry, PercentageOfClubCarry (ask %), RandomRange (ask min + max — stored as Target=min, TargetDistanceValue=max)

3. **Sets × Attempts** — free text, e.g. "3×5" or "2 sets of 9"

4. **Target size, anchors, equipment, club selection** — options:
   - Offer a sensible default based on grid type (e.g., "15% width, no depth, Min 30/Scratch 70/Pro 90, no equipment, UserLed")
   - Custom — user provides values

If the user provided any of these upfront (e.g., in the initial `/new-drill` invocation), skip those questions and confirm the values.

## Step 2 — Auto-infer fields

From the answers, automatically determine:

| Answer | Inferred fields |
|--------|----------------|
| 3×3 Grid | inputMode=GridCell, gridType=ThreeByThree, metricSchemaId=grid_3x3_multioutput, scoringMode=MultiOutput |
| 1×3 Grid | inputMode=GridCell, gridType=OneByThree, metricSchemaId=grid_1x3_direction, scoringMode=Shared |
| 3×1 Grid | inputMode=GridCell, gridType=ThreeByOne, metricSchemaId=grid_3x1_distance, scoringMode=Shared |
| Binary | inputMode=BinaryHitMiss, gridType=NULL, metricSchemaId=binary_hit_miss, scoringMode=Shared |
| Raw Data | inputMode=RawDataEntry, gridType=NULL, metricSchemaId=context-dependent, scoringMode=NULL |
| Multiple subskills + grid | scoringMode=MultiOutput |
| Single subskill | scoringMode=Shared |

## Step 3 — Determine migration number and UUID

1. Glob `supabase/migrations/*.sql` and find the highest numbered prefix.
2. Next migration = highest + 1, zero-padded to 3 digits.
3. Generate a random UUID v4 for each drill. Do NOT use sequential UUIDs — they cause collisions.

## Step 4 — Generate the SQL migration

Write the file to `supabase/migrations/{NNN}_seed_{drill_name_snake_case}.sql` using this exact template:

```sql
-- Seed standard drill: {Drill Name}
-- {Brief description of the drill}.

INSERT INTO "Drill" (
  "DrillID",
  "UserID",
  "Name",
  "SkillArea",
  "DrillType",
  "ScoringMode",
  "InputMode",
  "MetricSchemaID",
  "GridType",
  "SubskillMapping",
  "ClubSelectionMode",
  "TargetDistanceMode",
  "TargetDistanceValue",
  "TargetSizeMode",
  "TargetSizeWidth",
  "TargetSizeDepth",
  "RequiredSetCount",
  "RequiredAttemptsPerSet",
  "Anchors",
  "Target",
  "Description",
  "TargetDistanceUnit",
  "TargetSizeUnit",
  "RequiredEquipment",
  "RecommendedEquipment",
  "WindowCap",
  "Origin",
  "Status",
  "IsDeleted",
  "CreatedAt",
  "UpdatedAt"
) VALUES (
  '{uuid}',
  NULL,
  '{name}',
  '{skillArea}',
  '{drillType}',
  '{scoringMode or NULL}',
  '{inputMode}',
  '{metricSchemaId}',
  {gridType — quoted string or NULL},
  '{subskillMapping}'::JSONB,
  '{clubSelectionMode}',
  '{targetDistanceMode}',
  {targetDistanceValue — number or NULL},
  '{targetSizeMode}',
  {targetSizeWidth — number or NULL},
  {targetSizeDepth — number or NULL},
  {requiredSetCount},
  {requiredAttemptsPerSet — number or NULL},
  '{anchors json}'::JSONB,
  NULL,
  '{description}',
  {targetDistanceUnit — quoted string or NULL},
  {targetSizeUnit — quoted string or NULL},
  '{requiredEquipment}'::JSONB,
  '{recommendedEquipment}'::JSONB,
  {windowCap — integer or NULL},
  'System',
  'Active',
  false,
  NOW(),
  NOW()
);
```

## Step 5 — Present summary

Show a table summarising all drill fields and the migration file path. Remind the user to run the migration against Supabase. No Dart changes are needed — standard drills are fetched at runtime.

## Important rules

- Origin is always `'System'` for standard drills.
- UserID is always `NULL` for standard drills.
- All JSON fields use `::JSONB` cast.
- Anchor keys must exactly match the subskill IDs in SubskillMapping.
- Do NOT modify any Dart files — standard drills are 100% server-authoritative.
- Description should be auto-generated if the user doesn't provide one: summarise sets, attempts, target, and scoring method in one sentence.
