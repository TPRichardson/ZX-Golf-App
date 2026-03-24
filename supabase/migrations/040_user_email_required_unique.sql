-- Make Email mandatory and unique on User table.
-- Backfill any NULL emails before adding the constraint.
UPDATE "User" SET "Email" = "UserID" || '@placeholder.local' WHERE "Email" IS NULL;

ALTER TABLE "User" ALTER COLUMN "Email" SET NOT NULL;
ALTER TABLE "User" ADD CONSTRAINT user_email_unique UNIQUE ("Email");
