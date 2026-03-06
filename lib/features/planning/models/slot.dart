import 'dart:convert';

import 'package:zx_golf_app/data/enums.dart';

// S08 §8.13.2 — Slot data class for CalendarDay slot container.
// Slots are stored as JSON in the CalendarDay.Slots TEXT column.

/// Parse CalendarDay.Slots JSON string to a list of [Slot].
/// Shared utility used by calendar, planning, review, and home dashboard.
List<Slot> parseSlotsFromJson(String slotsJson) {
  if (slotsJson.isEmpty || slotsJson == '[]') return [];
  final List<dynamic> list = jsonDecode(slotsJson) as List<dynamic>;
  return list.map((e) => Slot.fromJson(e as Map<String, dynamic>)).toList();
}

class Slot {
  final String? drillId;
  final SlotOwnerType ownerType;
  final String? ownerId;
  final CompletionState completionState;
  final String? completingSessionId;
  final bool planned;
  // Phase 7B — Per-slot timestamp for LWW merge of CalendarDay slots.
  final DateTime? updatedAt;
  // Matrix §8.6.1 — Matrix slot fields.
  final String? matrixRunId;
  final MatrixType? matrixType;

  const Slot({
    this.drillId,
    this.ownerType = SlotOwnerType.manual,
    this.ownerId,
    this.completionState = CompletionState.incomplete,
    this.completingSessionId,
    this.planned = true,
    this.updatedAt,
    this.matrixRunId,
    this.matrixType,
  });

  /// S08 §8.13.2 — Empty slot (no drill or matrix assigned).
  bool get isEmpty => drillId == null && matrixType == null;

  /// S08 §8.13.2 — Slot has a drill assigned.
  bool get isFilled => drillId != null;

  /// Matrix §8.6.1 — Slot is a matrix slot.
  bool get isMatrixSlot => matrixType != null;

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
    String? Function()? matrixRunId,
    MatrixType? Function()? matrixType,
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
      matrixRunId:
          matrixRunId != null ? matrixRunId() : this.matrixRunId,
      matrixType:
          matrixType != null ? matrixType() : this.matrixType,
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
        'matrixRunId': matrixRunId,
        'matrixType': matrixType?.dbValue,
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
        matrixRunId: json['matrixRunId'] as String?,
        matrixType: json['matrixType'] != null
            ? MatrixType.fromString(json['matrixType'] as String)
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
          updatedAt == other.updatedAt &&
          matrixRunId == other.matrixRunId &&
          matrixType == other.matrixType;

  @override
  int get hashCode => Object.hash(
      drillId, ownerType, ownerId, completionState, completingSessionId,
      planned, updatedAt, matrixRunId, matrixType);

  @override
  String toString() =>
      'Slot(drillId: $drillId, ownerType: $ownerType, ownerId: $ownerId, '
      'completionState: $completionState, completingSessionId: $completingSessionId, '
      'planned: $planned, updatedAt: $updatedAt, '
      'matrixRunId: $matrixRunId, matrixType: $matrixType)';
}
