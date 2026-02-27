import 'package:drift/drift.dart';
import 'package:zx_golf_app/core/error_types.dart';
import 'package:zx_golf_app/data/database.dart';

// TD-03 §3.2 — Practice planning repository.
// Manages: Routine, RoutineInstance, Schedule, ScheduleInstance, CalendarDay.
// Spec: S08 — Practice Planning Layer.
class PlanningRepository {
  final AppDatabase _db;

  PlanningRepository(this._db);

  // ---------------------------------------------------------------------------
  // Routine CRUD
  // ---------------------------------------------------------------------------

  // Spec: S08 §8.1.2 — Create routine definition.
  Future<Routine> createRoutine(RoutinesCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.routines).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create routine',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve routine by primary key. Filters IsDeleted = false.
  Future<Routine?> getRoutineById(String id) {
    return (_db.select(_db.routines)
          ..where((t) => t.routineId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of non-deleted routines for a user.
  Stream<List<Routine>> watchRoutinesByUser(String userId) {
    return (_db.select(_db.routines)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update routine fields.
  // Spec: TD-03 §2.1.1 — SyncWriteGate compatible: writes through transaction.
  Future<Routine> updateRoutine(String id, RoutinesCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.routines)
              ..where((t) => t.routineId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine not found after update',
            context: {'routineId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update routine',
        context: {'routineId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete routine.
  Future<void> softDeleteRoutine(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.routines)
              ..where((t) => t.routineId.equals(id)))
            .write(const RoutinesCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine not found for soft delete',
            context: {'routineId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete routine',
        context: {'routineId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RoutineInstance CRUD
  // ---------------------------------------------------------------------------

  // Spec: S08 §8.2.4 — Create routine instance applied to a calendar day.
  Future<RoutineInstance> createRoutineInstance(
      RoutineInstancesCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.routineInstances).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create routine instance',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve routine instance by primary key.
  Future<RoutineInstance?> getRoutineInstanceById(String id) {
    return (_db.select(_db.routineInstances)
          ..where((t) => t.routineInstanceId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Routine instances for a user.
  Stream<List<RoutineInstance>> watchRoutineInstancesByUser(String userId) {
    return (_db.select(_db.routineInstances)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.2 — Update routine instance fields.
  Future<RoutineInstance> updateRoutineInstance(
      String id, RoutineInstancesCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.routineInstances)
              ..where((t) => t.routineInstanceId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine instance not found after update',
            context: {'routineInstanceId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update routine instance',
        context: {'routineInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete routine instance.
  Future<void> hardDeleteRoutineInstance(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.routineInstances)
              ..where((t) => t.routineInstanceId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Routine instance not found for hard delete',
            context: {'routineInstanceId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete routine instance',
        context: {'routineInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Schedule CRUD
  // ---------------------------------------------------------------------------

  // Spec: S08 §8.1.3 — Create schedule definition.
  Future<Schedule> createSchedule(SchedulesCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.schedules).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create schedule',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve schedule by primary key. Filters IsDeleted = false.
  Future<Schedule?> getScheduleById(String id) {
    return (_db.select(_db.schedules)
          ..where((t) => t.scheduleId.equals(id))
          ..where((t) => t.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Reactive stream of non-deleted schedules for a user.
  Stream<List<Schedule>> watchSchedulesByUser(String userId) {
    return (_db.select(_db.schedules)
          ..where((t) => t.userId.equals(userId))
          ..where((t) => t.isDeleted.equals(false)))
        .watch();
  }

  // TD-03 §3.2 — Update schedule fields.
  Future<Schedule> updateSchedule(String id, SchedulesCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.schedules)
              ..where((t) => t.scheduleId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule not found after update',
            context: {'scheduleId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update schedule',
        context: {'scheduleId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Soft delete schedule.
  Future<void> softDeleteSchedule(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.update(_db.schedules)
              ..where((t) => t.scheduleId.equals(id)))
            .write(const SchedulesCompanion(isDeleted: Value(true)));
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule not found for soft delete',
            context: {'scheduleId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to soft delete schedule',
        context: {'scheduleId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ScheduleInstance CRUD
  // ---------------------------------------------------------------------------

  // Spec: S08 §8.2.5 — Create schedule instance applied to a date range.
  Future<ScheduleInstance> createScheduleInstance(
      ScheduleInstancesCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.scheduleInstances).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create schedule instance',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve schedule instance by primary key.
  Future<ScheduleInstance?> getScheduleInstanceById(String id) {
    return (_db.select(_db.scheduleInstances)
          ..where((t) => t.scheduleInstanceId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Schedule instances for a user.
  Stream<List<ScheduleInstance>> watchScheduleInstancesByUser(String userId) {
    return (_db.select(_db.scheduleInstances)
          ..where((t) => t.userId.equals(userId)))
        .watch();
  }

  // TD-03 §3.2 — Update schedule instance fields.
  Future<ScheduleInstance> updateScheduleInstance(
      String id, ScheduleInstancesCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.scheduleInstances)
              ..where((t) => t.scheduleInstanceId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule instance not found after update',
            context: {'scheduleInstanceId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update schedule instance',
        context: {'scheduleInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete schedule instance.
  Future<void> hardDeleteScheduleInstance(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.scheduleInstances)
              ..where((t) => t.scheduleInstanceId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Schedule instance not found for hard delete',
            context: {'scheduleInstanceId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete schedule instance',
        context: {'scheduleInstanceId': id, 'error': e.toString()},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CalendarDay CRUD
  // ---------------------------------------------------------------------------

  // Spec: S08 §8.13.1 — Create calendar day slot container.
  Future<CalendarDay> createCalendarDay(CalendarDaysCompanion data) async {
    try {
      return await _db.transaction(() async {
        return await _db.into(_db.calendarDays).insertReturning(data);
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to create calendar day',
        context: {'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Retrieve calendar day by primary key.
  Future<CalendarDay?> getCalendarDayById(String id) {
    return (_db.select(_db.calendarDays)
          ..where((t) => t.calendarDayId.equals(id)))
        .getSingleOrNull();
  }

  // TD-03 §3.2 — Calendar days for a user within a date range.
  Stream<List<CalendarDay>> watchCalendarDaysByUser(
    String userId, {
    DateTime? from,
    DateTime? to,
  }) {
    final query = _db.select(_db.calendarDays)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.asc(t.date)]);
    if (from != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.date.isSmallerOrEqualValue(to));
    }
    return query.watch();
  }

  // TD-03 §3.2 — Update calendar day fields.
  Future<CalendarDay> updateCalendarDay(
      String id, CalendarDaysCompanion data) async {
    try {
      return await _db.transaction(() async {
        final rows = await (_db.update(_db.calendarDays)
              ..where((t) => t.calendarDayId.equals(id)))
            .writeReturning(data);
        if (rows.isEmpty) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found after update',
            context: {'calendarDayId': id},
          );
        }
        return rows.first;
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to update calendar day',
        context: {'calendarDayId': id, 'error': e.toString()},
      );
    }
  }

  // TD-03 §3.2 — Hard delete calendar day.
  Future<void> hardDeleteCalendarDay(String id) async {
    try {
      await _db.transaction(() async {
        final count = await (_db.delete(_db.calendarDays)
              ..where((t) => t.calendarDayId.equals(id)))
            .go();
        if (count == 0) {
          throw ValidationException(
            code: ValidationException.requiredField,
            message: 'Calendar day not found for hard delete',
            context: {'calendarDayId': id},
          );
        }
      });
    } on ZxGolfAppException {
      rethrow;
    } on Exception catch (e) {
      throw SystemException(
        code: SystemException.referentialIntegrity,
        message: 'Failed to hard delete calendar day',
        context: {'calendarDayId': id, 'error': e.toString()},
      );
    }
  }
}
