-- Instance.Flight: player-declared flight rating (1=low/bump, 2=medium, 3=high/lob).
-- Nullable integer column. Used by chipping scoring game.
ALTER TABLE "Instance" ADD COLUMN "Flight" INTEGER;
