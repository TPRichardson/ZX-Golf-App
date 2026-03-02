import 'package:zx_golf_app/data/enums.dart';

// S08 §8.13.2 — Slot data class for CalendarDay slot container.
// Slots are stored as JSON in the CalendarDay.Slots TEXT column.

class Slot {
  final String? drillId;
  final SlotOwnerType ownerType;
  final String? ownerId;
  final CompletionState completionState;
  final String? completingSessionId;
  final bool planned;
  // Phase 7B — Per-slot timestamp for LWW merge of CalendarDay slots.
  final DateTime? updatedAt;

  const Slot({
    this.drillId,
    this.ownerType = SlotOwnerType.manual,
    this.ownerId,
    this.completionState = CompletionState.incomplete,
    this.completingSessionId,
    this.planned = true,
    this.updatedAt,
  });

  /// S08 §8.13.2 — Empty slot (no drill assigned).
  bool get isEmpty => drillId == null;

  /// S08 §8.13.2 — Slot has a drill assigned.
  bool get isFilled => drillId != null;

  /// TD-04 §2.6 — Slot is in a completed state.
  bool get isCompleted =>
      completionState == CompletionState.completedLinked ||
      completionState == CompletionState.completedManual;

  Slot copyWith({
    String? Function()? drillId,
    SlotOwnerType? ownerType,
    String? Function()? ownerId,
    CompletionState? completionState,
    String? Function()? completingSessionId,
    bool? planned,
    DateTime? Function()? updatedAt,
  }) {
    return Slot(
      drillId: drillId != null ? drillId() : this.drillId,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId != null ? ownerId() : this.ownerId,
      completionState: completionState ?? this.completionState,
      completingSessionId: completingSessionId != null
          ? completingSessionId()
          : this.completingSessionId,
      planned: planned ?? this.planned,
      updatedAt: updatedAt != null ? updatedAt() : this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'drillId': drillId,
        'ownerType': ownerType.dbValue,
        'ownerId': ownerId,
        'completionState': completionState.dbValue,
        'completingSessionId': completingSessionId,
        'planned': planned,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        drillId: json['drillId'] as String?,
        ownerType: json['ownerType'] != null
            ? SlotOwnerType.fromString(json['ownerType'] as String)
            : SlotOwnerType.manual,
        ownerId: json['ownerId'] as String?,
        completionState: json['completionState'] != null
            ? CompletionState.fromString(json['completionState'] as String)
            : CompletionState.incomplete,
        completingSessionId: json['completingSessionId'] as String?,
        planned: json['planned'] as bool? ?? true,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Slot &&
          drillId == other.drillId &&
          ownerType == other.ownerType &&
          ownerId == other.ownerId &&
          completionState == other.completionState &&
          completingSessionId == other.completingSessionId &&
          planned == other.planned &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
      drillId, ownerType, ownerId, completionState, completingSessionId,
      planned, updatedAt);

  @override
  String toString() =>
      'Slot(drillId: $drillId, ownerType: $ownerType, ownerId: $ownerId, '
      'completionState: $completionState, completingSessionId: $completingSessionId, '
      'planned: $planned, updatedAt: $updatedAt)';
}
