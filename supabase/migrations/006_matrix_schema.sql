-- ============================================================
-- ZX Golf App — Matrix & Gapping System Schema
-- Migration: 006_matrix_schema.sql
-- Matrix §8.3 — 7 tables for matrix runs, axes, cells, attempts,
-- performance snapshots, and snapshot club data.
-- ============================================================

-- ============================================================
-- ENUM TYPES (Matrix §8.2)
-- ============================================================

CREATE TYPE matrix_type AS ENUM ('GappingChart', 'WedgeMatrix', 'ChippingMatrix');
CREATE TYPE run_state AS ENUM ('InProgress', 'Completed');
CREATE TYPE shot_order_mode AS ENUM ('TopToBottom', 'BottomToTop', 'Random');
CREATE TYPE axis_type AS ENUM ('Club', 'Effort', 'Flight', 'CarryDistance', 'Custom');
CREATE TYPE environment_type AS ENUM ('Indoor', 'Outdoor');
CREATE TYPE surface_type AS ENUM ('Grass', 'Mat');
CREATE TYPE green_firmness AS ENUM ('Soft', 'Medium', 'Firm');

-- ============================================================
-- TABLE: MatrixRun (Matrix §8.3.1)
-- One complete or in-progress matrix session.
-- ============================================================

CREATE TABLE "MatrixRun" (
  "MatrixRunID"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"                   UUID NOT NULL REFERENCES "User"("UserID"),
  "MatrixType"               matrix_type NOT NULL,
  "RunNumber"                INTEGER NOT NULL,
  "RunState"                 run_state NOT NULL DEFAULT 'InProgress',
  "StartTimestamp"           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "EndTimestamp"             TIMESTAMPTZ,
  "SessionShotTarget"        INTEGER NOT NULL,
  "ShotOrderMode"            shot_order_mode NOT NULL,
  "DispersionCaptureEnabled" BOOLEAN NOT NULL DEFAULT false,
  "MeasurementDevice"        TEXT,
  "EnvironmentType"          environment_type,
  "SurfaceType"              surface_type,
  "GreenSpeed"               DECIMAL,
  "GreenFirmness"            green_firmness,
  "IsDeleted"                BOOLEAN NOT NULL DEFAULT false,
  "CreatedAt"                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_matrix_run_updated_at
  BEFORE UPDATE ON "MatrixRun"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_matrix_run_user ON "MatrixRun" ("UserID") WHERE "IsDeleted" = false;

-- ============================================================
-- TABLE: MatrixAxis (Matrix §8.3.2)
-- One dimension of a matrix run.
-- ============================================================

CREATE TABLE "MatrixAxis" (
  "MatrixAxisID"  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "MatrixRunID"   UUID NOT NULL REFERENCES "MatrixRun"("MatrixRunID"),
  "AxisType"      axis_type NOT NULL,
  "AxisName"      TEXT NOT NULL,
  "AxisOrder"     INTEGER NOT NULL,
  "CreatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_matrix_axis_updated_at
  BEFORE UPDATE ON "MatrixAxis"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TABLE: MatrixAxisValue (Matrix §8.3.3)
-- One value within an axis.
-- ============================================================

CREATE TABLE "MatrixAxisValue" (
  "AxisValueID"   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "MatrixAxisID"  UUID NOT NULL REFERENCES "MatrixAxis"("MatrixAxisID"),
  "Label"         TEXT NOT NULL,
  "SortOrder"     INTEGER NOT NULL,
  "CreatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_matrix_axis_value_updated_at
  BEFORE UPDATE ON "MatrixAxisValue"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TABLE: MatrixCell (Matrix §8.3.4)
-- One unique combination of axis values.
-- ============================================================

CREATE TABLE "MatrixCell" (
  "MatrixCellID"    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "MatrixRunID"     UUID NOT NULL REFERENCES "MatrixRun"("MatrixRunID"),
  "AxisValueIDs"    JSONB NOT NULL DEFAULT '[]',
  "ExcludedFromRun" BOOLEAN NOT NULL DEFAULT false,
  "CreatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_matrix_cell_updated_at
  BEFORE UPDATE ON "MatrixCell"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TABLE: MatrixAttempt (Matrix §8.3.5)
-- Single recorded shot within a cell.
-- ============================================================

CREATE TABLE "MatrixAttempt" (
  "MatrixAttemptID"       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "MatrixCellID"          UUID NOT NULL REFERENCES "MatrixCell"("MatrixCellID"),
  "AttemptTimestamp"      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "CarryDistanceMeters"   DECIMAL,
  "TotalDistanceMeters"   DECIMAL,
  "LeftDeviationMeters"   DECIMAL,
  "RightDeviationMeters"  DECIMAL,
  "RolloutDistanceMeters" DECIMAL,
  "CreatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_matrix_attempt_updated_at
  BEFORE UPDATE ON "MatrixAttempt"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- TABLE: PerformanceSnapshot (Matrix §1.9)
-- Point-in-time club distance calibration.
-- ============================================================

CREATE TABLE "PerformanceSnapshot" (
  "SnapshotID"         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "UserID"             UUID NOT NULL REFERENCES "User"("UserID"),
  "MatrixRunID"        UUID REFERENCES "MatrixRun"("MatrixRunID"),
  "MatrixType"         matrix_type,
  "IsPrimary"          BOOLEAN NOT NULL DEFAULT false,
  "Label"              TEXT,
  "SnapshotTimestamp"  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "IsDeleted"          BOOLEAN NOT NULL DEFAULT false,
  "CreatedAt"          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_performance_snapshot_updated_at
  BEFORE UPDATE ON "PerformanceSnapshot"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_performance_snapshot_user ON "PerformanceSnapshot" ("UserID") WHERE "IsDeleted" = false;

-- ============================================================
-- TABLE: SnapshotClub (Matrix §1.9)
-- Per-club distance data within a snapshot.
-- ============================================================

CREATE TABLE "SnapshotClub" (
  "SnapshotClubID"        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "SnapshotID"            UUID NOT NULL REFERENCES "PerformanceSnapshot"("SnapshotID"),
  "ClubID"                UUID NOT NULL REFERENCES "UserClub"("ClubID"),
  "CarryDistanceMeters"   DECIMAL,
  "TotalDistanceMeters"   DECIMAL,
  "DispersionLeftMeters"  DECIMAL,
  "DispersionRightMeters" DECIMAL,
  "RolloutDistanceMeters" DECIMAL,
  "CreatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "UpdatedAt"             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER set_snapshot_club_updated_at
  BEFORE UPDATE ON "SnapshotClub"
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ============================================================
-- RLS POLICIES
-- ============================================================

ALTER TABLE "MatrixRun" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MatrixAxis" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MatrixAxisValue" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MatrixCell" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "MatrixAttempt" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "PerformanceSnapshot" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "SnapshotClub" ENABLE ROW LEVEL SECURITY;

-- MatrixRun: user owns directly.
CREATE POLICY matrix_run_user_policy ON "MatrixRun"
  USING ("UserID" = auth.uid());

-- MatrixAxis: user owns via MatrixRun.
CREATE POLICY matrix_axis_user_policy ON "MatrixAxis"
  USING ("MatrixRunID" IN (SELECT "MatrixRunID" FROM "MatrixRun" WHERE "UserID" = auth.uid()));

-- MatrixAxisValue: user owns via MatrixAxis → MatrixRun.
CREATE POLICY matrix_axis_value_user_policy ON "MatrixAxisValue"
  USING ("MatrixAxisID" IN (
    SELECT ma."MatrixAxisID" FROM "MatrixAxis" ma
    JOIN "MatrixRun" mr ON mr."MatrixRunID" = ma."MatrixRunID"
    WHERE mr."UserID" = auth.uid()
  ));

-- MatrixCell: user owns via MatrixRun.
CREATE POLICY matrix_cell_user_policy ON "MatrixCell"
  USING ("MatrixRunID" IN (SELECT "MatrixRunID" FROM "MatrixRun" WHERE "UserID" = auth.uid()));

-- MatrixAttempt: user owns via MatrixCell → MatrixRun.
CREATE POLICY matrix_attempt_user_policy ON "MatrixAttempt"
  USING ("MatrixCellID" IN (
    SELECT mc."MatrixCellID" FROM "MatrixCell" mc
    JOIN "MatrixRun" mr ON mr."MatrixRunID" = mc."MatrixRunID"
    WHERE mr."UserID" = auth.uid()
  ));

-- PerformanceSnapshot: user owns directly.
CREATE POLICY performance_snapshot_user_policy ON "PerformanceSnapshot"
  USING ("UserID" = auth.uid());

-- SnapshotClub: user owns via PerformanceSnapshot.
CREATE POLICY snapshot_club_user_policy ON "SnapshotClub"
  USING ("SnapshotID" IN (SELECT "SnapshotID" FROM "PerformanceSnapshot" WHERE "UserID" = auth.uid()));
