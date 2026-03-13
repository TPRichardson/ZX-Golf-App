-- Server-authoritative standard drills migration.
-- HasUnseenUpdate tracks when a server drill update affects an adopted drill.

ALTER TABLE "UserDrillAdoption" ADD COLUMN "HasUnseenUpdate" BOOLEAN NOT NULL DEFAULT false;

-- RLS policy: allow authenticated users to read standard drills directly.
CREATE POLICY "read_standard_drills" ON "Drill"
  FOR SELECT
  USING ("Origin" = 'System');
