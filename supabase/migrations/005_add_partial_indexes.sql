-- 8A — Partial indexes on IsDeleted=false for high-traffic query paths.
-- These cover the most common filtered queries in repositories.

CREATE INDEX IF NOT EXISTS idx_drills_active
  ON "Drills" ("UserID", "SkillArea") WHERE "IsDeleted" = false;

CREATE INDEX IF NOT EXISTS idx_sessions_active
  ON "Sessions" ("DrillID", "CompletionTimestamp") WHERE "IsDeleted" = false;

CREATE INDEX IF NOT EXISTS idx_instances_active
  ON "Instances" ("SetID") WHERE "IsDeleted" = false;

CREATE INDEX IF NOT EXISTS idx_practice_blocks_active
  ON "PracticeBlocks" ("UserID") WHERE "IsDeleted" = false;

-- UserClubs excluded: uses Status column, not IsDeleted.
