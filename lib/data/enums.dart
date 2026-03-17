// TD-02 §6.1 — All application enums as Dart enums with TEXT serialisation.
// SQLite stores these as TEXT (no Postgres ENUM in SQLite per TD-02 §8).

/// S02 §2.1 — Seven canonical skill areas.
enum SkillArea {
  driving('Driving'),
  approach('Approach'),
  putting('Putting'),
  pitching('Pitching'),
  chipping('Chipping'),
  woods('Woods'),
  bunkers('Bunkers');

  const SkillArea(this.dbValue);
  final String dbValue;

  static SkillArea fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid SkillArea: $value'));
}

/// S04 §4.2 — Drill practice type categories.
enum DrillType {
  techniqueBlock('TechniqueBlock'),
  transition('Transition'),
  pressure('Pressure'),
  benchmark('Benchmark');

  const DrillType(this.dbValue);
  final String dbValue;

  static DrillType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid DrillType: $value'));
}

/// S04 §4.3 — How scored outputs map to subskills.
enum ScoringMode {
  shared('Shared'),
  multiOutput('MultiOutput');

  const ScoringMode(this.dbValue);
  final String dbValue;

  static ScoringMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ScoringMode: $value'));
}

/// S04 §4.3 — How raw metrics are captured.
enum InputMode {
  gridCell('GridCell'),
  continuousMeasurement('ContinuousMeasurement'),
  rawDataEntry('RawDataEntry'),
  binaryHitMiss('BinaryHitMiss');

  const InputMode(this.dbValue);
  final String dbValue;

  static InputMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid InputMode: $value'));
}

/// S04 §4.3 — Grid layout types for GridCell input mode.
enum GridType {
  threeByThree('ThreeByThree'),
  oneByThree('OneByThree'),
  threeByOne('ThreeByOne');

  const GridType(this.dbValue);
  final String dbValue;

  static GridType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid GridType: $value'));
}

/// S09 §9.1 — 36 club type values.
enum ClubType {
  driver('Driver'),
  w1('W1'),
  w2('W2'),
  w3('W3'),
  w4('W4'),
  w5('W5'),
  w6('W6'),
  w7('W7'),
  w8('W8'),
  w9('W9'),
  h1('H1'),
  h2('H2'),
  h3('H3'),
  h4('H4'),
  h5('H5'),
  h6('H6'),
  h7('H7'),
  h8('H8'),
  h9('H9'),
  i1('i1'),
  i2('i2'),
  i3('i3'),
  i4('i4'),
  i5('i5'),
  i6('i6'),
  i7('i7'),
  i8('i8'),
  i9('i9'),
  pw('PW'),
  aw('AW'),
  gw('GW'),
  sw('SW'),
  uw('UW'),
  lw('LW'),
  chipper('Chipper'),
  putter('Putter'),
  trainingClub('TrainingClub');

  const ClubType(this.dbValue);
  final String dbValue;

  static ClubType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ClubType: $value'));
}

/// TD-02 §6.1 — Origin of a drill definition.
enum DrillOrigin {
  standard('System'),
  custom('UserCustom');

  const DrillOrigin(this.dbValue);
  final String dbValue;

  static DrillOrigin fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid DrillOrigin: $value'));
}

/// TD-02 §6.1 — Lifecycle status of a drill.
enum DrillStatus {
  active('Active'),
  retired('Retired'),
  deleted('Deleted');

  const DrillStatus(this.dbValue);
  final String dbValue;

  static DrillStatus fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid DrillStatus: $value'));
}

/// TD-02 §6.1 — Session lifecycle status.
enum SessionStatus {
  active('Active'),
  closed('Closed'),
  discarded('Discarded');

  const SessionStatus(this.dbValue);
  final String dbValue;

  static SessionStatus fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid SessionStatus: $value'));
}

/// S04 §4.7 — How clubs are selected for drill instances.
enum ClubSelectionMode {
  random('Random'),
  guided('Guided'),
  userLed('UserLed');

  const ClubSelectionMode(this.dbValue);
  final String dbValue;

  static ClubSelectionMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ClubSelectionMode: $value'));
}

/// S04 §4.5 — How target distance is determined.
enum TargetDistanceMode {
  fixed('Fixed'),
  clubCarry('ClubCarry'),
  percentageOfClubCarry('PercentageOfClubCarry'),
  randomRange('RandomRange');

  const TargetDistanceMode(this.dbValue);
  final String dbValue;

  static TargetDistanceMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid TargetDistanceMode: $value'));
}

/// S04 §4.5 — How target size is determined.
enum TargetSizeMode {
  fixed('Fixed'),
  percentageOfTargetDistance('PercentageOfTargetDistance');

  const TargetSizeMode(this.dbValue);
  final String dbValue;

  static TargetSizeMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid TargetSizeMode: $value'));
}

/// S13 §13.3 — Completion state of a practice entry.
enum CompletionState {
  incomplete('Incomplete'),
  completedLinked('CompletedLinked'),
  completedManual('CompletedManual');

  const CompletionState(this.dbValue);
  final String dbValue;

  static CompletionState fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid CompletionState: $value'));
}

/// S08 §8.13 — Who owns a calendar day slot.
enum SlotOwnerType {
  manual('Manual'),
  routineInstance('RoutineInstance'),
  scheduleInstance('ScheduleInstance');

  const SlotOwnerType(this.dbValue);
  final String dbValue;

  static SlotOwnerType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid SlotOwnerType: $value'));
}

/// S13 §13.5 — How a practice block was closed.
enum ClosureType {
  manual('Manual'),
  autoClosed('AutoClosed');

  const ClosureType(this.dbValue);
  final String dbValue;

  static ClosureType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ClosureType: $value'));
}

/// TD-02 §6.1 — Adoption status for user drill adoptions.
enum AdoptionStatus {
  active('Active'),
  retired('Retired');

  const AdoptionStatus(this.dbValue);
  final String dbValue;

  static AdoptionStatus fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid AdoptionStatus: $value'));
}

/// S08 §8.1.3 — Schedule application mode.
enum ScheduleAppMode {
  list('List'),
  dayPlanning('DayPlanning');

  const ScheduleAppMode(this.dbValue);
  final String dbValue;

  static ScheduleAppMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ScheduleAppMode: $value'));
}

/// S13 §13.3 — Type of entry in the practice entry list.
enum PracticeEntryType {
  pendingDrill('PendingDrill'),
  activeSession('ActiveSession'),
  completedSession('CompletedSession');

  const PracticeEntryType(this.dbValue);
  final String dbValue;

  static PracticeEntryType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid PracticeEntryType: $value'));
}

/// S09 §9.11.1 — Club lifecycle status.
enum UserClubStatus {
  active('Active'),
  retired('Retired');

  const UserClubStatus(this.dbValue);
  final String dbValue;

  static UserClubStatus fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid UserClubStatus: $value'));
}

/// S08 §8.1.2 — Routine lifecycle status.
enum RoutineStatus {
  active('Active'),
  retired('Retired'),
  deleted('Deleted');

  const RoutineStatus(this.dbValue);
  final String dbValue;

  static RoutineStatus fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid RoutineStatus: $value'));
}

/// S08 §8.1.3 — Schedule lifecycle status.
enum ScheduleStatus {
  active('Active'),
  retired('Retired'),
  deleted('Deleted');

  const ScheduleStatus(this.dbValue);
  final String dbValue;

  static ScheduleStatus fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ScheduleStatus: $value'));
}

/// S10 §10.6 — Distance measurement unit preference.
enum DistanceUnit {
  yards('Yards'),
  metres('Metres');

  const DistanceUnit(this.dbValue);
  final String dbValue;

  static DistanceUnit fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid DistanceUnit: $value'));
}

/// S10 §10.6 — Small length measurement unit preference.
enum SmallLengthUnit {
  inches('Inches'),
  centimetres('Centimetres');

  const SmallLengthUnit(this.dbValue);
  final String dbValue;

  static SmallLengthUnit fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid SmallLengthUnit: $value'));
}

/// Drill-identity length unit. Governs target distance/size display on drill definition.
/// Separate from user-preference enums (DistanceUnit, SmallLengthUnit) which govern display.
enum DrillLengthUnit {
  mm('mm'),
  cm('cm'),
  m('m'),
  inches('inches'),
  feet('feet'),
  yards('yards');

  const DrillLengthUnit(this.dbValue);
  final String dbValue;

  static DrillLengthUnit fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid DrillLengthUnit: $value'));
}

/// Training Kit equipment categories (replaces EquipmentType).
enum EquipmentCategory {
  specialistTrainingClub('SpecialistTrainingClub'),
  launchMonitor('LaunchMonitor'),
  puttingGate('PuttingGate'),
  alignmentAid('AlignmentAid'),
  impactTrainer('ImpactTrainer'),
  tempoTrainer('TempoTrainer'),
  puttingStrokeTrainer('PuttingStrokeTrainer'),
  shortGameTarget('ShortGameTarget');

  const EquipmentCategory(this.dbValue);
  final String dbValue;

  static EquipmentCategory fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid EquipmentCategory: $value'));
}

/// Matrix §8.2.1 — Three matrix workflow types.
enum MatrixType {
  gappingChart('GappingChart'),
  wedgeMatrix('WedgeMatrix'),
  chippingMatrix('ChippingMatrix');

  const MatrixType(this.dbValue);
  final String dbValue;

  static MatrixType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid MatrixType: $value'));
}

/// Matrix §8.3.1 — Matrix run lifecycle states.
enum RunState {
  inProgress('InProgress'),
  completed('Completed');

  const RunState(this.dbValue);
  final String dbValue;

  static RunState fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid RunState: $value'));
}

/// Matrix §3.8, §8.3.1 — Shot ordering within a matrix run.
enum ShotOrderMode {
  topToBottom('TopToBottom'),
  bottomToTop('BottomToTop'),
  random('Random');

  const ShotOrderMode(this.dbValue);
  final String dbValue;

  static ShotOrderMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid ShotOrderMode: $value'));
}

/// Matrix §8.3.2 — Axis dimension types.
enum AxisType {
  club('Club'),
  effort('Effort'),
  flight('Flight'),
  carryDistance('CarryDistance'),
  custom('Custom');

  const AxisType(this.dbValue);
  final String dbValue;

  static AxisType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid AxisType: $value'));
}

/// Matrix §3.5.2, §8.3.1 — Practice environment type.
enum EnvironmentType {
  indoor('Indoor'),
  outdoor('Outdoor');

  const EnvironmentType(this.dbValue);
  final String dbValue;

  static EnvironmentType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid EnvironmentType: $value'));
}

/// Matrix §3.5.3, §8.3.1 — Practice surface type.
enum SurfaceType {
  grass('Grass'),
  mat('Mat');

  const SurfaceType(this.dbValue);
  final String dbValue;

  static SurfaceType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid SurfaceType: $value'));
}

/// Matrix §5.5, §8.3.1 — Green firmness for chipping matrix.
enum GreenFirmness {
  soft('Soft'),
  medium('Medium'),
  firm('Firm');

  const GreenFirmness(this.dbValue);
  final String dbValue;

  static GreenFirmness fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid GreenFirmness: $value'));
}
