-- ============================================================
-- ZX Golf App — Drill Target Column
-- Migration: 009_drill_target.sql
-- Adds optional Target column to Drill table for custom drill
-- personal targets (no impact on scoring).
-- ============================================================

ALTER TABLE "Drill" ADD COLUMN "Target" DOUBLE PRECISION;
