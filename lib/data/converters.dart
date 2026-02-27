// TD-02 §8 — Drift type converters for enum TEXT serialisation.
// SQLite stores enums as TEXT. Converters validate on read.

import 'package:drift/drift.dart';
import 'enums.dart';

class SkillAreaConverter extends TypeConverter<SkillArea, String> {
  const SkillAreaConverter();
  @override
  SkillArea fromSql(String fromDb) => SkillArea.fromString(fromDb);
  @override
  String toSql(SkillArea value) => value.dbValue;
}

class DrillTypeConverter extends TypeConverter<DrillType, String> {
  const DrillTypeConverter();
  @override
  DrillType fromSql(String fromDb) => DrillType.fromString(fromDb);
  @override
  String toSql(DrillType value) => value.dbValue;
}

class ScoringModeConverter extends TypeConverter<ScoringMode, String> {
  const ScoringModeConverter();
  @override
  ScoringMode fromSql(String fromDb) => ScoringMode.fromString(fromDb);
  @override
  String toSql(ScoringMode value) => value.dbValue;
}

class InputModeConverter extends TypeConverter<InputMode, String> {
  const InputModeConverter();
  @override
  InputMode fromSql(String fromDb) => InputMode.fromString(fromDb);
  @override
  String toSql(InputMode value) => value.dbValue;
}

class GridTypeConverter extends TypeConverter<GridType, String> {
  const GridTypeConverter();
  @override
  GridType fromSql(String fromDb) => GridType.fromString(fromDb);
  @override
  String toSql(GridType value) => value.dbValue;
}

class ClubTypeConverter extends TypeConverter<ClubType, String> {
  const ClubTypeConverter();
  @override
  ClubType fromSql(String fromDb) => ClubType.fromString(fromDb);
  @override
  String toSql(ClubType value) => value.dbValue;
}

class DrillOriginConverter extends TypeConverter<DrillOrigin, String> {
  const DrillOriginConverter();
  @override
  DrillOrigin fromSql(String fromDb) => DrillOrigin.fromString(fromDb);
  @override
  String toSql(DrillOrigin value) => value.dbValue;
}

class DrillStatusConverter extends TypeConverter<DrillStatus, String> {
  const DrillStatusConverter();
  @override
  DrillStatus fromSql(String fromDb) => DrillStatus.fromString(fromDb);
  @override
  String toSql(DrillStatus value) => value.dbValue;
}

class SessionStatusConverter extends TypeConverter<SessionStatus, String> {
  const SessionStatusConverter();
  @override
  SessionStatus fromSql(String fromDb) => SessionStatus.fromString(fromDb);
  @override
  String toSql(SessionStatus value) => value.dbValue;
}

class ClubSelectionModeConverter
    extends TypeConverter<ClubSelectionMode, String> {
  const ClubSelectionModeConverter();
  @override
  ClubSelectionMode fromSql(String fromDb) =>
      ClubSelectionMode.fromString(fromDb);
  @override
  String toSql(ClubSelectionMode value) => value.dbValue;
}

class TargetDistanceModeConverter
    extends TypeConverter<TargetDistanceMode, String> {
  const TargetDistanceModeConverter();
  @override
  TargetDistanceMode fromSql(String fromDb) =>
      TargetDistanceMode.fromString(fromDb);
  @override
  String toSql(TargetDistanceMode value) => value.dbValue;
}

class TargetSizeModeConverter extends TypeConverter<TargetSizeMode, String> {
  const TargetSizeModeConverter();
  @override
  TargetSizeMode fromSql(String fromDb) => TargetSizeMode.fromString(fromDb);
  @override
  String toSql(TargetSizeMode value) => value.dbValue;
}

class CompletionStateConverter extends TypeConverter<CompletionState, String> {
  const CompletionStateConverter();
  @override
  CompletionState fromSql(String fromDb) =>
      CompletionState.fromString(fromDb);
  @override
  String toSql(CompletionState value) => value.dbValue;
}

class SlotOwnerTypeConverter extends TypeConverter<SlotOwnerType, String> {
  const SlotOwnerTypeConverter();
  @override
  SlotOwnerType fromSql(String fromDb) => SlotOwnerType.fromString(fromDb);
  @override
  String toSql(SlotOwnerType value) => value.dbValue;
}

class ClosureTypeConverter extends TypeConverter<ClosureType, String> {
  const ClosureTypeConverter();
  @override
  ClosureType fromSql(String fromDb) => ClosureType.fromString(fromDb);
  @override
  String toSql(ClosureType value) => value.dbValue;
}

class AdoptionStatusConverter extends TypeConverter<AdoptionStatus, String> {
  const AdoptionStatusConverter();
  @override
  AdoptionStatus fromSql(String fromDb) => AdoptionStatus.fromString(fromDb);
  @override
  String toSql(AdoptionStatus value) => value.dbValue;
}

class ScheduleAppModeConverter extends TypeConverter<ScheduleAppMode, String> {
  const ScheduleAppModeConverter();
  @override
  ScheduleAppMode fromSql(String fromDb) =>
      ScheduleAppMode.fromString(fromDb);
  @override
  String toSql(ScheduleAppMode value) => value.dbValue;
}

class PracticeEntryTypeConverter
    extends TypeConverter<PracticeEntryType, String> {
  const PracticeEntryTypeConverter();
  @override
  PracticeEntryType fromSql(String fromDb) =>
      PracticeEntryType.fromString(fromDb);
  @override
  String toSql(PracticeEntryType value) => value.dbValue;
}

class UserClubStatusConverter extends TypeConverter<UserClubStatus, String> {
  const UserClubStatusConverter();
  @override
  UserClubStatus fromSql(String fromDb) => UserClubStatus.fromString(fromDb);
  @override
  String toSql(UserClubStatus value) => value.dbValue;
}

class RoutineStatusConverter extends TypeConverter<RoutineStatus, String> {
  const RoutineStatusConverter();
  @override
  RoutineStatus fromSql(String fromDb) => RoutineStatus.fromString(fromDb);
  @override
  String toSql(RoutineStatus value) => value.dbValue;
}

class ScheduleStatusConverter extends TypeConverter<ScheduleStatus, String> {
  const ScheduleStatusConverter();
  @override
  ScheduleStatus fromSql(String fromDb) => ScheduleStatus.fromString(fromDb);
  @override
  String toSql(ScheduleStatus value) => value.dbValue;
}
