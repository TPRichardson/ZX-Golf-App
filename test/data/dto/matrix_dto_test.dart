import 'package:flutter_test/flutter_test.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/dto/matrix_run_dto.dart';
import 'package:zx_golf_app/data/dto/matrix_axis_dto.dart';
import 'package:zx_golf_app/data/dto/matrix_axis_value_dto.dart';
import 'package:zx_golf_app/data/dto/matrix_cell_dto.dart';
import 'package:zx_golf_app/data/dto/matrix_attempt_dto.dart';
import 'package:zx_golf_app/data/dto/performance_snapshot_dto.dart';
import 'package:zx_golf_app/data/dto/snapshot_club_dto.dart';
import '../../fixtures/dto_fixtures.dart';

// Phase M3 — Matrix DTO round-trip tests.

void main() {
  group('MatrixRun DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final run = makeMatrixRun();
      final json = run.toSyncDto();
      final companion = matrixRunFromSyncDto(json);

      expect(companion.matrixRunId.value, run.matrixRunId);
      expect(companion.userId.value, run.userId);
      expect(companion.matrixType.value, MatrixType.gappingChart);
      expect(companion.runNumber.value, 1);
      expect(companion.runState.value, RunState.inProgress);
      expect(companion.sessionShotTarget.value, 5);
      expect(companion.shotOrderMode.value, ShotOrderMode.topToBottom);
      expect(companion.dispersionCaptureEnabled.value, false);
      expect(companion.measurementDevice.value, 'Trackman');
      expect(companion.environmentType.value, EnvironmentType.outdoor);
      expect(companion.surfaceType.value, SurfaceType.grass);
      expect(companion.isDeleted.value, false);
    });

    test('nullable fields handle null', () {
      final json = makeMatrixRun().toSyncDto();
      json['EndTimestamp'] = null;
      json['MeasurementDevice'] = null;
      json['EnvironmentType'] = null;
      json['SurfaceType'] = null;
      json['GreenSpeed'] = null;
      json['GreenFirmness'] = null;
      final companion = matrixRunFromSyncDto(json);
      expect(companion.endTimestamp.value, isNull);
      expect(companion.measurementDevice.value, isNull);
      expect(companion.environmentType.value, isNull);
      expect(companion.surfaceType.value, isNull);
      expect(companion.greenSpeed.value, isNull);
      expect(companion.greenFirmness.value, isNull);
    });

    test('green conditions for chipping matrix', () {
      final json = makeMatrixRun().toSyncDto();
      json['MatrixType'] = 'ChippingMatrix';
      json['GreenSpeed'] = 10.5;
      json['GreenFirmness'] = 'Firm';
      final companion = matrixRunFromSyncDto(json);
      expect(companion.matrixType.value, MatrixType.chippingMatrix);
      expect(companion.greenSpeed.value, 10.5);
      expect(companion.greenFirmness.value, GreenFirmness.firm);
    });
  });

  group('MatrixAxis DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final axis = makeMatrixAxis();
      final json = axis.toSyncDto();
      final companion = matrixAxisFromSyncDto(json);

      expect(companion.matrixAxisId.value, axis.matrixAxisId);
      expect(companion.matrixRunId.value, axis.matrixRunId);
      expect(companion.axisType.value, AxisType.club);
      expect(companion.axisName.value, 'Club');
      expect(companion.axisOrder.value, 1);
    });
  });

  group('MatrixAxisValue DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final value = makeMatrixAxisValue();
      final json = value.toSyncDto();
      final companion = matrixAxisValueFromSyncDto(json);

      expect(companion.axisValueId.value, value.axisValueId);
      expect(companion.matrixAxisId.value, value.matrixAxisId);
      expect(companion.label.value, '7-Iron');
      expect(companion.sortOrder.value, 1);
    });
  });

  group('MatrixCell DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final cell = makeMatrixCell();
      final json = cell.toSyncDto();
      final companion = matrixCellFromSyncDto(json);

      expect(companion.matrixCellId.value, cell.matrixCellId);
      expect(companion.matrixRunId.value, cell.matrixRunId);
      expect(companion.excludedFromRun.value, false);
    });

    test('AxisValueIDs round-trips as JSON array', () {
      final cell = makeMatrixCell();
      final json = cell.toSyncDto();

      // toSyncDto decodes AxisValueIDs to a List.
      expect(json['AxisValueIDs'], isA<List>());
      expect((json['AxisValueIDs'] as List).first, 'av-001');

      // fromSyncDto re-encodes it.
      final companion = matrixCellFromSyncDto(json);
      expect(companion.axisValueIds.value, '["av-001"]');
    });

    test('AxisValueIDs handles string input', () {
      final json = makeMatrixCell().toSyncDto();
      json['AxisValueIDs'] = '["av-001","av-002"]';
      final companion = matrixCellFromSyncDto(json);
      expect(companion.axisValueIds.value, '["av-001","av-002"]');
    });
  });

  group('MatrixAttempt DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final attempt = makeMatrixAttempt();
      final json = attempt.toSyncDto();
      final companion = matrixAttemptFromSyncDto(json);

      expect(companion.matrixAttemptId.value, attempt.matrixAttemptId);
      expect(companion.matrixCellId.value, attempt.matrixCellId);
      expect(companion.carryDistanceMeters.value, 145.5);
      expect(companion.totalDistanceMeters.value, 155.0);
      expect(companion.leftDeviationMeters.value, 2.5);
      expect(companion.rightDeviationMeters.value, 1.8);
    });

    test('nullable distance fields handle null', () {
      final json = makeMatrixAttempt().toSyncDto();
      json['CarryDistanceMeters'] = null;
      json['TotalDistanceMeters'] = null;
      json['LeftDeviationMeters'] = null;
      json['RightDeviationMeters'] = null;
      json['RolloutDistanceMeters'] = null;
      final companion = matrixAttemptFromSyncDto(json);
      expect(companion.carryDistanceMeters.value, isNull);
      expect(companion.totalDistanceMeters.value, isNull);
      expect(companion.leftDeviationMeters.value, isNull);
      expect(companion.rightDeviationMeters.value, isNull);
      expect(companion.rolloutDistanceMeters.value, isNull);
    });
  });

  group('PerformanceSnapshot DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final snapshot = makePerformanceSnapshot();
      final json = snapshot.toSyncDto();
      final companion = performanceSnapshotFromSyncDto(json);

      expect(companion.snapshotId.value, snapshot.snapshotId);
      expect(companion.userId.value, snapshot.userId);
      expect(companion.matrixRunId.value, 'mr-001');
      expect(companion.matrixType.value, MatrixType.gappingChart);
      expect(companion.isPrimary.value, true);
      expect(companion.label.value, 'March gapping');
      expect(companion.isDeleted.value, false);
    });

    test('nullable fields handle null', () {
      final json = makePerformanceSnapshot().toSyncDto();
      json['MatrixRunID'] = null;
      json['MatrixType'] = null;
      json['Label'] = null;
      final companion = performanceSnapshotFromSyncDto(json);
      expect(companion.matrixRunId.value, isNull);
      expect(companion.matrixType.value, isNull);
      expect(companion.label.value, isNull);
    });
  });

  group('SnapshotClub DTO round-trip', () {
    test('full entity serialises and deserialises', () {
      final club = makeSnapshotClub();
      final json = club.toSyncDto();
      final companion = snapshotClubFromSyncDto(json);

      expect(companion.snapshotClubId.value, club.snapshotClubId);
      expect(companion.snapshotId.value, club.snapshotId);
      expect(companion.clubId.value, '7-Iron');
      expect(companion.carryDistanceMeters.value, 155.0);
      expect(companion.totalDistanceMeters.value, 165.0);
      expect(companion.dispersionLeftMeters.value, 3.2);
      expect(companion.dispersionRightMeters.value, 2.8);
    });

    test('nullable distance fields handle null', () {
      final json = makeSnapshotClub().toSyncDto();
      json['CarryDistanceMeters'] = null;
      json['TotalDistanceMeters'] = null;
      json['DispersionLeftMeters'] = null;
      json['DispersionRightMeters'] = null;
      json['RolloutDistanceMeters'] = null;
      final companion = snapshotClubFromSyncDto(json);
      expect(companion.carryDistanceMeters.value, isNull);
      expect(companion.totalDistanceMeters.value, isNull);
      expect(companion.dispersionLeftMeters.value, isNull);
      expect(companion.dispersionRightMeters.value, isNull);
      expect(companion.rolloutDistanceMeters.value, isNull);
    });

    test('rollout for chipping snapshot', () {
      final json = makeSnapshotClub().toSyncDto();
      json['RolloutDistanceMeters'] = 4.2;
      final companion = snapshotClubFromSyncDto(json);
      expect(companion.rolloutDistanceMeters.value, 4.2);
    });
  });
}
