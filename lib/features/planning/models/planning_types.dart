import 'package:zx_golf_app/data/enums.dart';

// S08 §8.1.2 — Routine entry types for template definitions.
// Stored as JSON in the Routine.Entries TEXT column.

/// S08 §8.7 — Generation mode for criterion-based entries.
enum GenerationMode {
  weakest('Weakest'),
  strength('Strength'),
  novelty('Novelty'),
  random('Random');

  const GenerationMode(this.dbValue);
  final String dbValue;

  static GenerationMode fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid GenerationMode: $value'));
}

/// S08 §8.1.2 — Entry type discriminator.
enum RoutineEntryType {
  fixed('Fixed'),
  criterion('Criterion');

  const RoutineEntryType(this.dbValue);
  final String dbValue;

  static RoutineEntryType fromString(String value) =>
      values.firstWhere((e) => e.dbValue == value,
          orElse: () => throw ArgumentError('Invalid RoutineEntryType: $value'));
}

/// S08 §8.7.4 — Criterion for generated drill selection.
class GenerationCriterion {
  final SkillArea? skillArea;
  final List<DrillType> drillTypes;
  final String? subskillId;
  final GenerationMode mode;

  const GenerationCriterion({
    this.skillArea,
    this.drillTypes = const [],
    this.subskillId,
    this.mode = GenerationMode.weakest,
  });

  Map<String, dynamic> toJson() => {
        'skillArea': skillArea?.dbValue,
        'drillTypes': drillTypes.map((e) => e.dbValue).toList(),
        'subskillId': subskillId,
        'mode': mode.dbValue,
      };

  factory GenerationCriterion.fromJson(Map<String, dynamic> json) =>
      GenerationCriterion(
        skillArea: json['skillArea'] != null
            ? SkillArea.fromString(json['skillArea'] as String)
            : null,
        drillTypes: (json['drillTypes'] as List<dynamic>?)
                ?.map((e) => DrillType.fromString(e as String))
                .toList() ??
            [],
        subskillId: json['subskillId'] as String?,
        mode: json['mode'] != null
            ? GenerationMode.fromString(json['mode'] as String)
            : GenerationMode.weakest,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationCriterion &&
          skillArea == other.skillArea &&
          subskillId == other.subskillId &&
          mode == other.mode &&
          _listEquals(drillTypes, other.drillTypes);

  @override
  int get hashCode => Object.hash(skillArea, subskillId, mode,
      Object.hashAll(drillTypes));
}

/// S08 §8.1.2 — Single entry in a Routine template.
class RoutineEntry {
  final RoutineEntryType type;
  final String? drillId;
  final GenerationCriterion? criterion;

  const RoutineEntry({
    required this.type,
    this.drillId,
    this.criterion,
  });

  /// S08 §8.1.2 — Fixed entry references a specific drill.
  const RoutineEntry.fixed(this.drillId)
      : type = RoutineEntryType.fixed,
        criterion = null;

  /// S08 §8.1.2 — Criterion entry uses WeaknessDetectionEngine to resolve.
  const RoutineEntry.criterion(this.criterion)
      : type = RoutineEntryType.criterion,
        drillId = null;

  Map<String, dynamic> toJson() => {
        'type': type.dbValue,
        'drillId': drillId,
        'criterion': criterion?.toJson(),
      };

  factory RoutineEntry.fromJson(Map<String, dynamic> json) => RoutineEntry(
        type: RoutineEntryType.fromString(json['type'] as String),
        drillId: json['drillId'] as String?,
        criterion: json['criterion'] != null
            ? GenerationCriterion.fromJson(
                json['criterion'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineEntry &&
          type == other.type &&
          drillId == other.drillId &&
          criterion == other.criterion;

  @override
  int get hashCode => Object.hash(type, drillId, criterion);
}

/// S08 §8.1.3 — Template day for DayPlanning mode schedules.
class TemplateDay {
  final List<RoutineEntry> entries;

  const TemplateDay({required this.entries});

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory TemplateDay.fromJson(Map<String, dynamic> json) => TemplateDay(
        entries: (json['entries'] as List<dynamic>)
            .map((e) => RoutineEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// Simple list equality without importing foundation.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
