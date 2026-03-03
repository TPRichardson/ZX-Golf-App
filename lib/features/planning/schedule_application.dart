import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';
import 'package:zx_golf_app/data/enums.dart';
import 'package:zx_golf_app/data/repositories/planning_repository.dart';
import 'package:zx_golf_app/features/planning/models/slot.dart';

// S08 §8.2.3 — Schedule application: apply a Schedule across a date range.

/// Map of date → list of resolved drill IDs for that day.
typedef SchedulePreview = Map<DateTime, List<String>>;

class ScheduleApplicator {
  final PlanningRepository _planningRepo;

  static const _uuid = Uuid();

  ScheduleApplicator(this._planningRepo);

  /// S08 §8.10.3 — Preview List mode application.
  /// Sequential fill across days; wrap on exhaustion; skip capacity=0 days.
  SchedulePreview previewListMode(
    List<String> resolvedDrillIds,
    List<DateTime> dates,
    Map<DateTime, int> capacityPerDay,
  ) {
    final preview = <DateTime, List<String>>{};
    if (resolvedDrillIds.isEmpty) return preview;

    var drillIndex = 0;

    for (final date in dates) {
      final capacity = capacityPerDay[date] ?? 0;
      if (capacity == 0) continue;

      final dayDrills = <String>[];
      for (var i = 0; i < capacity && dayDrills.length < capacity; i++) {
        if (drillIndex >= resolvedDrillIds.length) {
          drillIndex = 0; // Wrap.
        }
        dayDrills.add(resolvedDrillIds[drillIndex]);
        drillIndex++;
      }

      if (dayDrills.isNotEmpty) {
        preview[date] = dayDrills;
      }
    }

    return preview;
  }

  /// S08 §8.10.3 — Preview DayPlanning mode application.
  /// Template day N → CalendarDay N; cycle after last template;
  /// capacity=0 days consume a template position.
  SchedulePreview previewDayPlanningMode(
    List<List<String>> templateDays,
    List<DateTime> dates,
    Map<DateTime, int> capacityPerDay,
  ) {
    final preview = <DateTime, List<String>>{};
    if (templateDays.isEmpty) return preview;

    var templateIndex = 0;

    for (final date in dates) {
      final capacity = capacityPerDay[date] ?? 0;
      final template = templateDays[templateIndex % templateDays.length];

      if (capacity > 0 && template.isNotEmpty) {
        final drills = template.take(capacity).toList();
        if (drills.isNotEmpty) {
          preview[date] = drills;
        }
      }

      // S08 §8.10.3 — Capacity=0 days consume a template position.
      templateIndex++;
    }

    return preview;
  }

  /// S08 §8.2.3 — Confirm application across a date range.
  Future<ScheduleInstance> confirmApplication(
    String userId,
    String scheduleId,
    DateTime startDate,
    DateTime endDate,
    SchedulePreview resolvedMap,
  ) async {
    // S09 §9.3 — Bag gate: validate all resolved drills have eligible clubs.
    final checkedDrills = <String>{};
    for (final drillIds in resolvedMap.values) {
      for (final drillId in drillIds) {
        if (checkedDrills.add(drillId)) {
          await _planningRepo.validateDrillClubEligibility(userId, drillId);
        }
      }
    }

    final instanceId = _uuid.v4();
    final ownedSlotsMap = <String, List<int>>{};

    for (final entry in resolvedMap.entries) {
      final date = entry.key;
      final drillIds = entry.value;

      final day = await _planningRepo.getOrCreateCalendarDay(userId, date);
      final slots = _planningRepo.parseSlots(day.slots);

      final ownedIndices = <int>[];

      var drillIndex = 0;
      for (var i = 0; i < slots.length && drillIndex < drillIds.length; i++) {
        if (slots[i].isEmpty) {
          slots[i] = Slot(
            drillId: drillIds[drillIndex],
            ownerType: SlotOwnerType.scheduleInstance,
            ownerId: instanceId,
            completionState: CompletionState.incomplete,
            planned: true,
          );
          ownedIndices.add(i);
          drillIndex++;
        }
      }

      await _planningRepo.updateSlots(day.calendarDayId, slots);
      ownedSlotsMap[date.toIso8601String()] = ownedIndices;
    }

    final dateOnly =
        DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    return _planningRepo.createScheduleInstance(ScheduleInstancesCompanion(
      scheduleInstanceId: Value(instanceId),
      scheduleId: Value(scheduleId),
      userId: Value(userId),
      startDate: Value(dateOnly),
      endDate: Value(endOnly),
      ownedSlots: Value(jsonEncode(ownedSlotsMap)),
    ));
  }

  /// S08 §8.2.3 — Unapply a schedule instance: clear owned slots across days, delete instance.
  Future<void> unapplyScheduleInstance(String scheduleInstanceId) async {
    final instance =
        await _planningRepo.getScheduleInstanceById(scheduleInstanceId);
    if (instance == null) {
      throw ValidationException(
        code: ValidationException.requiredField,
        message: 'Schedule instance not found',
        context: {'scheduleInstanceId': scheduleInstanceId},
      );
    }

    final ownedSlotsMap =
        jsonDecode(instance.ownedSlots) as Map<String, dynamic>;

    for (final entry in ownedSlotsMap.entries) {
      final date = DateTime.parse(entry.key);
      final indices = (entry.value as List<dynamic>).cast<int>();

      final day = await _planningRepo.getCalendarDayByDate(
        instance.userId,
        date,
      );
      if (day == null) continue;

      final slots = _planningRepo.parseSlots(day.slots);
      for (final slotIndex in indices) {
        if (slotIndex < slots.length &&
            slots[slotIndex].ownerId == scheduleInstanceId) {
          slots[slotIndex] = const Slot();
        }
      }

      await _planningRepo.updateSlots(day.calendarDayId, slots);
    }

    await _planningRepo.hardDeleteScheduleInstance(scheduleInstanceId);
  }
}
