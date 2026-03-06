import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// Phase M1 — Matrix data layer tests: tables, enums, Slot model.

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('Matrix tables exist in schema', () {
    test('MatrixRun table is queryable', () async {
      final rows = await db.select(db.matrixRuns).get();
      expect(rows, isEmpty);
    });

    test('MatrixAxis table is queryable', () async {
      final rows = await db.select(db.matrixAxes).get();
      expect(rows, isEmpty);
    });

    test('MatrixAxisValue table is queryable', () async {
      final rows = await db.select(db.matrixAxisValues).get();
      expect(rows, isEmpty);
    });

    test('MatrixCell table is queryable', () async {
      final rows = await db.select(db.matrixCells).get();
      expect(rows, isEmpty);
    });

    test('MatrixAttempt table is queryable', () async {
      final rows = await db.select(db.matrixAttempts).get();
      expect(rows, isEmpty);
    });

    test('PerformanceSnapshot table is queryable', () async {
      final rows = await db.select(db.performanceSnapshots).get();
      expect(rows, isEmpty);
    });

    test('SnapshotClub table is queryable', () async {
      final rows = await db.select(db.snapshotClubs).get();
      expect(rows, isEmpty);
    });
  });

  group('Matrix enum serialisation round-trips', () {
    test('MatrixType round-trips', () {
      for (final v in MatrixType.values) {
        expect(MatrixType.fromString(v.dbValue), v);
      }
      expect(MatrixType.gappingChart.dbValue, 'GappingChart');
      expect(MatrixType.wedgeMatrix.dbValue, 'WedgeMatrix');
      expect(MatrixType.chippingMatrix.dbValue, 'ChippingMatrix');
    });

    test('RunState round-trips', () {
      for (final v in RunState.values) {
        expect(RunState.fromString(v.dbValue), v);
      }
      expect(RunState.inProgress.dbValue, 'InProgress');
      expect(RunState.completed.dbValue, 'Completed');
    });

    test('ShotOrderMode round-trips', () {
      for (final v in ShotOrderMode.values) {
        expect(ShotOrderMode.fromString(v.dbValue), v);
      }
    });

    test('AxisType round-trips', () {
      for (final v in AxisType.values) {
        expect(AxisType.fromString(v.dbValue), v);
      }
      expect(AxisType.values.length, 5);
    });

    test('EnvironmentType round-trips', () {
      for (final v in EnvironmentType.values) {
        expect(EnvironmentType.fromString(v.dbValue), v);
      }
    });

    test('SurfaceType round-trips', () {
      for (final v in SurfaceType.values) {
        expect(SurfaceType.fromString(v.dbValue), v);
      }
    });

    test('GreenFirmness round-trips', () {
      for (final v in GreenFirmness.values) {
        expect(GreenFirmness.fromString(v.dbValue), v);
      }
      expect(GreenFirmness.values.length, 3);
    });

    test('invalid enum value throws ArgumentError', () {
      expect(() => MatrixType.fromString('BadValue'), throwsArgumentError);
      expect(() => RunState.fromString('BadValue'), throwsArgumentError);
      expect(() => ShotOrderMode.fromString('BadValue'), throwsArgumentError);
      expect(() => AxisType.fromString('BadValue'), throwsArgumentError);
      expect(() => EnvironmentType.fromString('BadValue'), throwsArgumentError);
      expect(() => SurfaceType.fromString('BadValue'), throwsArgumentError);
      expect(() => GreenFirmness.fromString('BadValue'), throwsArgumentError);
    });
  });

  group('MatrixRun CRUD via Drift', () {
    test('insert and retrieve MatrixRun', () async {
      await db.into(db.matrixRuns).insert(MatrixRunsCompanion.insert(
            matrixRunId: 'run-1',
            userId: 'user-1',
            matrixType: MatrixType.gappingChart,
            runNumber: 1,
            runState: RunState.inProgress,
            sessionShotTarget: 5,
            shotOrderMode: ShotOrderMode.topToBottom,
          ));

      final runs = await db.select(db.matrixRuns).get();
      expect(runs.length, 1);
      expect(runs.first.matrixRunId, 'run-1');
      expect(runs.first.matrixType, MatrixType.gappingChart);
      expect(runs.first.runState, RunState.inProgress);
      expect(runs.first.sessionShotTarget, 5);
      expect(runs.first.shotOrderMode, ShotOrderMode.topToBottom);
      expect(runs.first.dispersionCaptureEnabled, false);
      expect(runs.first.isDeleted, false);
      expect(runs.first.endTimestamp, isNull);
      expect(runs.first.greenSpeed, isNull);
      expect(runs.first.greenFirmness, isNull);
    });

    test('chipping matrix stores green conditions', () async {
      await db.into(db.matrixRuns).insert(MatrixRunsCompanion.insert(
            matrixRunId: 'run-c1',
            userId: 'user-1',
            matrixType: MatrixType.chippingMatrix,
            runNumber: 1,
            runState: RunState.inProgress,
            sessionShotTarget: 3,
            shotOrderMode: ShotOrderMode.random,
            greenSpeed: const Value(10.5),
            greenFirmness: const Value(GreenFirmness.firm),
          ));

      final run = await (db.select(db.matrixRuns)
            ..where((r) => r.matrixRunId.equals('run-c1')))
          .getSingle();
      expect(run.greenSpeed, 10.5);
      expect(run.greenFirmness, GreenFirmness.firm);
    });
  });

  group('Matrix entity relationships', () {
    test('axis → axis values → cells → attempts chain', () async {
      // Insert parent run.
      await db.into(db.matrixRuns).insert(MatrixRunsCompanion.insert(
            matrixRunId: 'run-1',
            userId: 'user-1',
            matrixType: MatrixType.wedgeMatrix,
            runNumber: 1,
            runState: RunState.inProgress,
            sessionShotTarget: 3,
            shotOrderMode: ShotOrderMode.topToBottom,
          ));

      // Insert axis.
      await db.into(db.matrixAxes).insert(MatrixAxesCompanion.insert(
            matrixAxisId: 'axis-1',
            matrixRunId: 'run-1',
            axisType: AxisType.club,
            axisName: 'Club',
            axisOrder: 1,
          ));

      // Insert axis value.
      await db
          .into(db.matrixAxisValues)
          .insert(MatrixAxisValuesCompanion.insert(
            axisValueId: 'av-1',
            matrixAxisId: 'axis-1',
            label: '56°',
            sortOrder: 1,
          ));

      // Insert cell referencing axis value.
      await db.into(db.matrixCells).insert(MatrixCellsCompanion.insert(
            matrixCellId: 'cell-1',
            matrixRunId: 'run-1',
            axisValueIds: const Value('["av-1"]'),
          ));

      // Insert attempt in cell.
      await db.into(db.matrixAttempts).insert(MatrixAttemptsCompanion.insert(
            matrixAttemptId: 'att-1',
            matrixCellId: 'cell-1',
            carryDistanceMeters: const Value(62.5),
            totalDistanceMeters: const Value(70.0),
          ));

      // Verify chain.
      final axes = await db.select(db.matrixAxes).get();
      expect(axes.length, 1);
      expect(axes.first.matrixRunId, 'run-1');

      final values = await db.select(db.matrixAxisValues).get();
      expect(values.length, 1);
      expect(values.first.matrixAxisId, 'axis-1');

      final cells = await db.select(db.matrixCells).get();
      expect(cells.length, 1);
      expect(cells.first.axisValueIds, '["av-1"]');
      expect(cells.first.excludedFromRun, false);

      final attempts = await db.select(db.matrixAttempts).get();
      expect(attempts.length, 1);
      expect(attempts.first.carryDistanceMeters, 62.5);
      expect(attempts.first.totalDistanceMeters, 70.0);
      expect(attempts.first.leftDeviationMeters, isNull);
      expect(attempts.first.rolloutDistanceMeters, isNull);
    });
  });

  group('PerformanceSnapshot + SnapshotClub', () {
    test('insert snapshot with clubs', () async {
      await db
          .into(db.performanceSnapshots)
          .insert(PerformanceSnapshotsCompanion.insert(
            snapshotId: 'snap-1',
            userId: 'user-1',
            matrixRunId: const Value('run-1'),
            matrixType: const Value(MatrixType.gappingChart),
            label: const Value('March gapping'),
          ));

      await db.into(db.snapshotClubs).insert(SnapshotClubsCompanion.insert(
            snapshotClubId: 'sc-1',
            snapshotId: 'snap-1',
            clubId: 'club-7i',
            carryDistanceMeters: const Value(155.0),
            totalDistanceMeters: const Value(165.0),
            dispersionLeftMeters: const Value(3.2),
            dispersionRightMeters: const Value(2.8),
          ));

      final snapshots = await db.select(db.performanceSnapshots).get();
      expect(snapshots.length, 1);
      expect(snapshots.first.isPrimary, false);
      expect(snapshots.first.matrixType, MatrixType.gappingChart);
      expect(snapshots.first.label, 'March gapping');

      final clubs = await db.select(db.snapshotClubs).get();
      expect(clubs.length, 1);
      expect(clubs.first.carryDistanceMeters, 155.0);
      expect(clubs.first.rolloutDistanceMeters, isNull);
    });

    test('chipping snapshot stores rollout', () async {
      await db
          .into(db.performanceSnapshots)
          .insert(PerformanceSnapshotsCompanion.insert(
            snapshotId: 'snap-c1',
            userId: 'user-1',
            matrixType: const Value(MatrixType.chippingMatrix),
          ));

      await db.into(db.snapshotClubs).insert(SnapshotClubsCompanion.insert(
            snapshotClubId: 'sc-c1',
            snapshotId: 'snap-c1',
            clubId: 'club-sw',
            carryDistanceMeters: const Value(9.1),
            rolloutDistanceMeters: const Value(3.8),
            totalDistanceMeters: const Value(12.9),
          ));

      final club = await (db.select(db.snapshotClubs)
            ..where((c) => c.snapshotClubId.equals('sc-c1')))
          .getSingle();
      expect(club.rolloutDistanceMeters, 3.8);
    });
  });

  group('Slot model matrix fields', () {
    test('default Slot has null matrix fields', () {
      const slot = Slot();
      expect(slot.matrixRunId, isNull);
      expect(slot.matrixType, isNull);
      expect(slot.isMatrixSlot, false);
      expect(slot.isEmpty, true);
    });

    test('matrix slot with matrixType is recognised', () {
      const slot = Slot(matrixType: MatrixType.wedgeMatrix);
      expect(slot.isMatrixSlot, true);
      expect(slot.isEmpty, false);
      expect(slot.isFilled, false); // no drillId
    });

    test('Slot JSON round-trip with matrix fields', () {
      final original = Slot(
        matrixRunId: 'run-1',
        matrixType: MatrixType.gappingChart,
        ownerType: SlotOwnerType.manual,
        updatedAt: DateTime.utc(2026, 3, 6),
      );

      final json = original.toJson();
      expect(json['matrixRunId'], 'run-1');
      expect(json['matrixType'], 'GappingChart');

      final restored = Slot.fromJson(json);
      expect(restored.matrixRunId, 'run-1');
      expect(restored.matrixType, MatrixType.gappingChart);
      expect(restored, original);
    });

    test('Slot JSON round-trip without matrix fields (backwards compat)', () {
      final json = {
        'drillId': 'drill-1',
        'ownerType': 'Manual',
        'completionState': 'Incomplete',
        'planned': true,
      };

      final slot = Slot.fromJson(json);
      expect(slot.matrixRunId, isNull);
      expect(slot.matrixType, isNull);
      expect(slot.isMatrixSlot, false);
      expect(slot.drillId, 'drill-1');
    });

    test('Slot copyWith updates matrix fields', () {
      const original = Slot(matrixType: MatrixType.gappingChart);
      final updated = original.copyWith(
        matrixRunId: () => 'run-99',
        matrixType: () => MatrixType.chippingMatrix,
      );
      expect(updated.matrixRunId, 'run-99');
      expect(updated.matrixType, MatrixType.chippingMatrix);
    });

    test('Slot copyWith clears matrix fields to null', () {
      const original = Slot(
        matrixRunId: 'run-1',
        matrixType: MatrixType.wedgeMatrix,
      );
      final cleared = original.copyWith(
        matrixRunId: () => null,
        matrixType: () => null,
      );
      expect(cleared.matrixRunId, isNull);
      expect(cleared.matrixType, isNull);
    });

    test('Slot equality includes matrix fields', () {
      const a = Slot(matrixType: MatrixType.gappingChart, matrixRunId: 'r1');
      const b = Slot(matrixType: MatrixType.gappingChart, matrixRunId: 'r1');
      const c = Slot(matrixType: MatrixType.wedgeMatrix, matrixRunId: 'r1');
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });

    test('parseSlotsFromJson handles matrix slots', () {
      final json =
          '[{"drillId":null,"ownerType":"Manual","completionState":"Incomplete",'
          '"planned":true,"matrixRunId":"run-1","matrixType":"WedgeMatrix"}]';
      final slots = parseSlotsFromJson(json);
      expect(slots.length, 1);
      expect(slots.first.isMatrixSlot, true);
      expect(slots.first.matrixType, MatrixType.wedgeMatrix);
    });
  });
}
