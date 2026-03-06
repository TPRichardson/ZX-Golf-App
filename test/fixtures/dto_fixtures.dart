import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';

// TD-03 §5.2.5 — Test fixtures for DTO round-trip tests.
// Each factory creates a fully-populated entity instance.

final _ts = DateTime.utc(2026, 3, 1, 12, 0, 0);
final _ts2 = DateTime.utc(2026, 3, 1, 13, 0, 0);

User makeUser({String? userId}) => User(
      userId: userId ?? 'u-001',
      displayName: 'Test User',
      email: 'test@example.com',
      timezone: 'America/New_York',
      weekStartDay: 1,
      unitPreferences: '{"distance":"yards","temperature":"fahrenheit"}',
      createdAt: _ts,
      updatedAt: _ts,
    );

Drill makeDrill({String? drillId, String? userId}) => Drill(
      drillId: drillId ?? 'd-001',
      userId: userId,
      name: 'Irons Direction',
      skillArea: SkillArea.irons,
      drillType: DrillType.transition,
      scoringMode: ScoringMode.shared,
      inputMode: InputMode.gridCell,
      metricSchemaId: 'grid_1x3_direction',
      gridType: GridType.oneByThree,
      subskillMapping: '["irons_direction_control"]',
      clubSelectionMode: ClubSelectionMode.userLed,
      targetDistanceMode: TargetDistanceMode.clubCarry,
      targetDistanceValue: null,
      targetSizeMode: TargetSizeMode.percentageOfTargetDistance,
      targetSizeWidth: 7.0,
      targetSizeDepth: null,
      requiredSetCount: 1,
      requiredAttemptsPerSet: 10,
      anchors:
          '{"irons_direction_control":{"Min":30,"Scratch":70,"Pro":90}}',
      origin: DrillOrigin.system,
      status: DrillStatus.active,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

Drill makeDrillMinimal() => Drill(
      drillId: 'd-min',
      userId: null,
      name: 'Driving Technique',
      skillArea: SkillArea.driving,
      drillType: DrillType.techniqueBlock,
      scoringMode: null,
      inputMode: InputMode.rawDataEntry,
      metricSchemaId: 'technique_duration',
      gridType: null,
      subskillMapping: '[]',
      clubSelectionMode: null,
      targetDistanceMode: null,
      targetDistanceValue: null,
      targetSizeMode: null,
      targetSizeWidth: null,
      targetSizeDepth: null,
      requiredSetCount: 1,
      requiredAttemptsPerSet: null,
      anchors: '{}',
      origin: DrillOrigin.system,
      status: DrillStatus.active,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

PracticeBlock makePracticeBlock() => PracticeBlock(
      practiceBlockId: 'pb-001',
      userId: 'u-001',
      sourceRoutineId: 'r-001',
      drillOrder: '["d-001","d-002"]',
      startTimestamp: _ts,
      endTimestamp: _ts2,
      closureType: ClosureType.manual,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

PracticeBlock makePracticeBlockMinimal() => PracticeBlock(
      practiceBlockId: 'pb-min',
      userId: 'u-001',
      sourceRoutineId: null,
      drillOrder: '[]',
      startTimestamp: _ts,
      endTimestamp: null,
      closureType: null,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

Session makeSession() => Session(
      sessionId: 's-001',
      drillId: 'd-001',
      practiceBlockId: 'pb-001',
      completionTimestamp: _ts2,
      status: SessionStatus.closed,
      integrityFlag: false,
      integritySuppressed: false,
      userDeclaration: null,
      sessionDuration: 300,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

PracticeSet makePracticeSet() => PracticeSet(
      setId: 'set-001',
      sessionId: 's-001',
      setIndex: 0,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

Instance makeInstance() => Instance(
      instanceId: 'i-001',
      setId: 'set-001',
      selectedClub: 'i7',
      rawMetrics: '{"cellIndex":1}',
      timestamp: _ts,
      resolvedTargetDistance: 150.0,
      resolvedTargetWidth: 10.5,
      resolvedTargetDepth: null,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

PracticeEntry makePracticeEntry() => PracticeEntry(
      practiceEntryId: 'pe-001',
      practiceBlockId: 'pb-001',
      drillId: 'd-001',
      sessionId: 's-001',
      entryType: PracticeEntryType.completedSession,
      positionIndex: 0,
      createdAt: _ts,
      updatedAt: _ts,
    );

UserDrillAdoption makeUserDrillAdoption() => UserDrillAdoption(
      userDrillAdoptionId: 'uda-001',
      userId: 'u-001',
      drillId: 'd-001',
      status: AdoptionStatus.active,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

UserClub makeUserClub() => UserClub(
      clubId: 'uc-001',
      userId: 'u-001',
      clubType: ClubType.i7,
      make: 'Titleist',
      model: 'T200',
      loft: 34.0,
      status: UserClubStatus.active,
      createdAt: _ts,
      updatedAt: _ts,
    );

ClubPerformanceProfile makeClubPerformanceProfile() =>
    ClubPerformanceProfile(
      profileId: 'cpp-001',
      clubId: 'uc-001',
      effectiveFromDate: DateTime.utc(2026, 1, 15),
      carryDistance: 165.0,
      dispersionLeft: 5.0,
      dispersionRight: 5.0,
      dispersionShort: 3.0,
      dispersionLong: 4.0,
      createdAt: _ts,
      updatedAt: _ts,
    );

UserSkillAreaClubMapping makeUserSkillAreaClubMapping() =>
    UserSkillAreaClubMapping(
      mappingId: 'map-001',
      userId: 'u-001',
      clubType: ClubType.i7,
      skillArea: SkillArea.irons,
      isMandatory: true,
      createdAt: _ts,
      updatedAt: _ts,
    );

Routine makeRoutine() => Routine(
      routineId: 'r-001',
      userId: 'u-001',
      name: 'Morning Practice',
      entries: '[{"drillId":"d-001","sets":1}]',
      status: RoutineStatus.active,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

Schedule makeSchedule() => Schedule(
      scheduleId: 'sch-001',
      userId: 'u-001',
      name: 'Weekly Plan',
      applicationMode: ScheduleAppMode.dayPlanning,
      entries: '[{"day":1,"routineId":"r-001"}]',
      status: ScheduleStatus.active,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

CalendarDay makeCalendarDay() => CalendarDay(
      calendarDayId: 'cd-001',
      userId: 'u-001',
      date: DateTime.utc(2026, 3, 1),
      slotCapacity: 3,
      slots: '[{"index":0,"ownerType":"Manual"}]',
      createdAt: _ts,
      updatedAt: _ts,
    );

RoutineInstance makeRoutineInstance() => RoutineInstance(
      routineInstanceId: 'ri-001',
      routineId: 'r-001',
      userId: 'u-001',
      calendarDayDate: DateTime.utc(2026, 3, 1),
      ownedSlots: '[0,1]',
      createdAt: _ts,
      updatedAt: _ts,
    );

ScheduleInstance makeScheduleInstance() => ScheduleInstance(
      scheduleInstanceId: 'si-001',
      scheduleId: 'sch-001',
      userId: 'u-001',
      startDate: DateTime.utc(2026, 3, 1),
      endDate: DateTime.utc(2026, 3, 7),
      ownedSlots: '[2]',
      createdAt: _ts,
      updatedAt: _ts,
    );

EventLog makeEventLog() => EventLog(
      eventLogId: 'el-001',
      userId: 'u-001',
      deviceId: 'dev-001',
      eventTypeId: 'SessionCompletion',
      timestamp: _ts,
      affectedEntityIds: '["s-001"]',
      affectedSubskills: '["irons_direction_control"]',
      metadata: '{"score":3.5}',
      createdAt: _ts,
    );

EventLog makeEventLogMinimal() => EventLog(
      eventLogId: 'el-min',
      userId: 'u-001',
      deviceId: null,
      eventTypeId: 'AnchorEdit',
      timestamp: _ts,
      affectedEntityIds: null,
      affectedSubskills: null,
      metadata: null,
      createdAt: _ts,
    );

// Phase M3 — Matrix entity fixtures.

MatrixRun makeMatrixRun() => MatrixRun(
      matrixRunId: 'mr-001',
      userId: 'u-001',
      matrixType: MatrixType.gappingChart,
      runNumber: 1,
      runState: RunState.inProgress,
      startTimestamp: _ts,
      endTimestamp: null,
      sessionShotTarget: 5,
      shotOrderMode: ShotOrderMode.topToBottom,
      dispersionCaptureEnabled: false,
      measurementDevice: 'Trackman',
      environmentType: EnvironmentType.outdoor,
      surfaceType: SurfaceType.grass,
      greenSpeed: null,
      greenFirmness: null,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

MatrixAxis makeMatrixAxis() => MatrixAxis(
      matrixAxisId: 'ma-001',
      matrixRunId: 'mr-001',
      axisType: AxisType.club,
      axisName: 'Club',
      axisOrder: 1,
      createdAt: _ts,
      updatedAt: _ts,
    );

MatrixAxisValue makeMatrixAxisValue() => MatrixAxisValue(
      axisValueId: 'av-001',
      matrixAxisId: 'ma-001',
      label: '7-Iron',
      sortOrder: 1,
      createdAt: _ts,
      updatedAt: _ts,
    );

MatrixCell makeMatrixCell() => MatrixCell(
      matrixCellId: 'mc-001',
      matrixRunId: 'mr-001',
      axisValueIds: '["av-001"]',
      excludedFromRun: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

MatrixAttempt makeMatrixAttempt() => MatrixAttempt(
      matrixAttemptId: 'matt-001',
      matrixCellId: 'mc-001',
      attemptTimestamp: _ts,
      carryDistanceMeters: 145.5,
      totalDistanceMeters: 155.0,
      leftDeviationMeters: 2.5,
      rightDeviationMeters: 1.8,
      rolloutDistanceMeters: null,
      createdAt: _ts,
      updatedAt: _ts,
    );

PerformanceSnapshot makePerformanceSnapshot() => PerformanceSnapshot(
      snapshotId: 'ps-001',
      userId: 'u-001',
      matrixRunId: 'mr-001',
      matrixType: MatrixType.gappingChart,
      isPrimary: true,
      label: 'March gapping',
      snapshotTimestamp: _ts,
      isDeleted: false,
      createdAt: _ts,
      updatedAt: _ts,
    );

SnapshotClub makeSnapshotClub() => SnapshotClub(
      snapshotClubId: 'sc-001',
      snapshotId: 'ps-001',
      clubId: '7-Iron',
      carryDistanceMeters: 155.0,
      totalDistanceMeters: 165.0,
      dispersionLeftMeters: 3.2,
      dispersionRightMeters: 2.8,
      rolloutDistanceMeters: null,
      createdAt: _ts,
      updatedAt: _ts,
    );

UserDevice makeUserDevice() => UserDevice(
      deviceId: 'dev-001',
      userId: 'u-001',
      deviceLabel: 'Pixel 8',
      registeredAt: _ts,
      lastSyncAt: _ts2,
      isDeleted: false,
      updatedAt: _ts,
    );
