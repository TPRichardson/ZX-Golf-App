import 'dart:convert';

// TD-03 §5 — LWW merge algorithm for sync conflict resolution.
// Phase 7B: Pure logic class with no DB or Supabase dependency.
// Takes local row + remote row as Map<String, dynamic>, returns the winner.

class MergeAlgorithm {
  /// Tables that have IsDeleted column (soft-delete entities).
  static const softDeleteTables = {
    'User',
    'Drill',
    'PracticeBlock',
    'Session',
    'Set',
    'Instance',
    'PracticeEntry',
    'UserDrillAdoption',
    'UserClub',
    'ClubPerformanceProfile',
    'UserSkillAreaClubMapping',
    'Routine',
    'Schedule',
    'RoutineInstance',
    'ScheduleInstance',
    'UserDevice',
  };

  /// Tables that are append-only (no merge needed, insert if missing).
  static const appendOnlyTables = {'EventLog'};

  /// Tables with special merge (slot-level).
  static const slotMergeTables = {'CalendarDay'};

  /// TD-03 §5 — Row-level LWW merge.
  /// Returns the winning row (remote if remote.updatedAt > local.updatedAt,
  /// local otherwise). Delete-always-wins: if either isDeleted=true, result
  /// is the deleted version with the latest timestamp.
  static Map<String, dynamic> mergeRow(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localDeleted = local['isDeleted'] == true;
    final remoteDeleted = remote['isDeleted'] == true;

    // Delete-always-wins: if either side is deleted, result is deleted.
    if (localDeleted || remoteDeleted) {
      final localTs = _parseTimestamp(local['updatedAt']);
      final remoteTs = _parseTimestamp(remote['updatedAt']);
      // Use the version with the latest timestamp, but force isDeleted=true.
      final winner = (remoteTs != null &&
              (localTs == null || remoteTs.isAfter(localTs)))
          ? Map<String, dynamic>.from(remote)
          : Map<String, dynamic>.from(local);
      winner['isDeleted'] = true;
      return winner;
    }

    // Standard LWW: remote wins if strictly newer.
    final localTs = _parseTimestamp(local['updatedAt']);
    final remoteTs = _parseTimestamp(remote['updatedAt']);

    if (remoteTs != null && (localTs == null || remoteTs.isAfter(localTs))) {
      return Map<String, dynamic>.from(remote);
    }
    return Map<String, dynamic>.from(local);
  }

  /// TD-03 §5 — CalendarDay slot-level merge.
  /// Merges slots array position-by-position using per-slot updatedAt.
  /// Row-level UpdatedAt determines the "base" (slot array length/capacity).
  static Map<String, dynamic> mergeCalendarDay(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final localTs = _parseTimestamp(local['updatedAt']);
    final remoteTs = _parseTimestamp(remote['updatedAt']);

    // Determine the base (row-level winner provides structure).
    final remoteIsNewer = remoteTs != null &&
        (localTs == null || remoteTs.isAfter(localTs));
    final base = remoteIsNewer
        ? Map<String, dynamic>.from(remote)
        : Map<String, dynamic>.from(local);

    // Parse slot arrays from both sides.
    final localSlots = _parseSlots(local['slots']);
    final remoteSlots = _parseSlots(remote['slots']);

    if (localSlots == null && remoteSlots == null) return base;
    if (localSlots == null) {
      base['slots'] = remote['slots'];
      return base;
    }
    if (remoteSlots == null) {
      base['slots'] = local['slots'];
      return base;
    }

    // Merge position-by-position.
    final maxLen = localSlots.length > remoteSlots.length
        ? localSlots.length
        : remoteSlots.length;
    final mergedSlots = <Map<String, dynamic>>[];

    for (var i = 0; i < maxLen; i++) {
      final localSlot = i < localSlots.length ? localSlots[i] : null;
      final remoteSlot = i < remoteSlots.length ? remoteSlots[i] : null;

      if (localSlot == null) {
        mergedSlots.add(remoteSlot!);
      } else if (remoteSlot == null) {
        mergedSlots.add(localSlot);
      } else {
        // Both sides have a slot at this position — per-slot LWW.
        final localSlotTs = _parseTimestamp(localSlot['updatedAt']);
        final remoteSlotTs = _parseTimestamp(remoteSlot['updatedAt']);

        if (localSlotTs == null && remoteSlotTs == null) {
          // Neither has updatedAt — fall back to row-level winner.
          mergedSlots.add(remoteIsNewer ? remoteSlot : localSlot);
        } else if (remoteSlotTs != null &&
            (localSlotTs == null || remoteSlotTs.isAfter(localSlotTs))) {
          mergedSlots.add(remoteSlot);
        } else {
          mergedSlots.add(localSlot);
        }
      }
    }

    base['slots'] = jsonEncode(mergedSlots);
    // Use the later row-level updatedAt.
    if (remoteTs != null && localTs != null) {
      base['updatedAt'] = (remoteTs.isAfter(localTs)
              ? remoteTs
              : localTs)
          .toIso8601String();
    }

    return base;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Parse slots from a CalendarDay row's 'slots' field.
  /// The field may be a JSON string or already a List.
  static List<Map<String, dynamic>>? _parseSlots(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value) as List<dynamic>;
        return decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
