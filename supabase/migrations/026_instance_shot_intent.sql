-- Add shot intent columns to Instance table.
-- ShotShape: Fade/Draw/Straight (nullable, player-declared intent).
-- ShotEffort: 100/90/75 (nullable, player-declared effort percentage).

ALTER TABLE "Instance" ADD COLUMN "ShotShape" TEXT;
ALTER TABLE "Instance" ADD COLUMN "ShotEffort" INTEGER;
