-- ============================================================
-- ZX Golf App — Surface Type on PracticeBlock and Session
-- Migration: 008_surface_type.sql
-- Adds SurfaceType column to PracticeBlock and Session tables.
-- Reuses existing surface_type enum from 006_matrix_schema.sql.
-- ============================================================

ALTER TABLE "PracticeBlock" ADD COLUMN "SurfaceType" surface_type;
ALTER TABLE "Session" ADD COLUMN "SurfaceType" surface_type;
